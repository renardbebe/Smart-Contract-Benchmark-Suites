 

pragma solidity ^0.5.3;


 


 
contract AssetAdapter {

    uint16 public ASSET_TYPE;
    bytes32 internal EIP712_SWAP_TYPEHASH;
    bytes32 internal EIP712_ASSET_TYPEHASH;

    constructor(
        uint16 assetType,
        bytes32 swapTypehash,
        bytes32 assetTypehash
    ) internal {
        ASSET_TYPE = assetType;
        EIP712_SWAP_TYPEHASH = swapTypehash;
        EIP712_ASSET_TYPEHASH = assetTypehash;
    }

     
    function sendAssetTo(bytes memory assetData, address payable _to) internal returns (bool success);

     
    function lockAssetFrom(bytes memory assetData, address _from) internal returns (bool success);

     
    function getAssetTypedHash(bytes memory data) internal view returns (bytes32);

     
    modifier checkAssetType(bytes memory assetData) {
        uint16 assetType;
         
        assembly {
            assetType := and(
                mload(add(assetData, 2)),
                0xffff
            )
        }
        require(assetType == ASSET_TYPE, "invalid asset type");
        _;
    }

    modifier noEther() {
        require(msg.value == 0, "this asset doesn't accept ether");
        _;
    }

}


 
interface Erc20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


 
contract TokenAdapter is AssetAdapter {

    uint16 internal constant TOKEN_TYPE_ID = 2;
    
     
    constructor() internal AssetAdapter(
        TOKEN_TYPE_ID,
        0xacdf4bfc42db1ef8f283505784fc4d04c30ee19cc3ff6ae81e0a8e522ddcc950,
        0x36cb415f6a5e783824a0cf6e4d040975f6b49a9b971f3362c7a48e4ebe338f28
    ) {}

     
    function getAmount(bytes memory assetData) internal pure returns (uint256 amount) {
         
        assembly {
            amount := mload(add(assetData, 34))
        }
    }

     
    function getTokenAddress(bytes memory assetData) internal pure returns (address tokenAddress) {
         
        assembly {
            tokenAddress := and(
                mload(add(assetData, 54)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    }

    function sendAssetTo(
        bytes memory assetData, address payable _to
    ) internal returns (bool success) {
        Erc20Token token = Erc20Token(getTokenAddress(assetData));
        return token.transfer(_to, getAmount(assetData));
    }

    function lockAssetFrom(
        bytes memory assetData, address _from
    ) internal noEther returns (bool success) {
        Erc20Token token = Erc20Token(getTokenAddress(assetData));
        return token.transferFrom(_from, address(this), getAmount(assetData));
    }

     
    function getAssetTypedHash(bytes memory data) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712_ASSET_TYPEHASH,
                getAmount(data),
                getTokenAddress(data)
            )
        );
    }
}


contract Ownable {

    address public owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can call this");
        _;
    }

}


 
contract WithStatus is Ownable {

    enum Status {
        STOPPED,
        RETURN_ONLY,
        FINALIZE_ONLY,
        ACTIVE
    }

    event StatusChanged(Status oldStatus, Status newStatus);

    Status public status = Status.ACTIVE;

    constructor() internal {}

    function setStatus(Status _status) external onlyOwner {
        emit StatusChanged(status, _status);
        status = _status;
    }

    modifier statusAtLeast(Status _status) {
        require(status >= _status, "invalid contract status");
        _;
    }

}


 
contract WithOracles is Ownable {

    mapping (address => bool) oracles;

     
    constructor() internal {
        oracles[msg.sender] = true;
    }

    function approveOracle(address _oracle) external onlyOwner {
        oracles[_oracle] = true;
    }

    function revokeOracle(address _oracle) external onlyOwner {
        oracles[_oracle] = false;
    }

    modifier isOracle(address _oracle) {
        require(oracles[_oracle], "invalid oracle address");
        _;
    }

    modifier onlyOracle(address _oracle) {
        require(
            msg.sender == _oracle && oracles[msg.sender],
            "only the oracle can call this"
        );
        _;
    }

    modifier onlyOracleOrSender(address _sender, address _oracle) {
        require(
            msg.sender == _sender || (msg.sender == _oracle && oracles[msg.sender]),
            "only the oracle or the sender can call this"
        );
        _;
    }

    modifier onlySender(address _sender) {
        require(msg.sender == _sender, "only the sender can call this");
        _;
    }

}


 
contract AbstractRampSwaps is Ownable, WithStatus, WithOracles, AssetAdapter {

     
    string public constant VERSION = "0.3.1";

     
    uint32 internal constant SWAP_UNCLAIMED = 1;
    uint32 internal constant MIN_ACTUAL_TIMESTAMP = 1000000000;

     
    uint32 internal constant SWAP_LOCK_TIME_S = 3600 * 24 * 7;

    event Created(bytes32 indexed swapHash);
    event BuyerSet(bytes32 indexed oldSwapHash, bytes32 indexed newSwapHash);
    event Claimed(bytes32 indexed oldSwapHash, bytes32 indexed newSwapHash);
    event Released(bytes32 indexed swapHash);
    event SenderReleased(bytes32 indexed swapHash);
    event Returned(bytes32 indexed swapHash);
    event SenderReturned(bytes32 indexed swapHash);

     
    mapping (bytes32 => uint32) internal swaps;

     
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 internal EIP712_DOMAIN_HASH;

    constructor(uint256 _chainId) internal {
        EIP712_DOMAIN_HASH = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("RampSwaps")),
                keccak256(bytes(VERSION)),
                _chainId,
                address(this)
            )
        );
    }

     
    function create(
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        payable
        statusAtLeast(Status.ACTIVE)
        isOracle(_oracle)
        checkAssetType(_assetData)
        returns
        (bool success)
    {
        bytes32 swapHash = getSwapHash(
            msg.sender, address(0), _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapNotExists(swapHash);
        require(ecrecover(swapHash, v, r, s) == _oracle, "invalid swap oracle signature");
         
         
         
         
        swaps[swapHash] = SWAP_UNCLAIMED;
        require(
            lockAssetFrom(_assetData, msg.sender),
            "failed to lock asset on escrow"
        );
        emit Created(swapHash);
        return true;
    }

     
    function claim(
        address _sender,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external statusAtLeast(Status.ACTIVE) onlyOracle(_oracle) {
         
        bytes32 claimTypedHash = getClaimTypedHash(
            _sender,
            _receiver,
            _assetData,
            _paymentDetailsHash
        );
        require(ecrecover(claimTypedHash, v, r, s) == _receiver, "invalid claim receiver signature");
         
        bytes32 oldSwapHash = getSwapHash(
            _sender, address(0), _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        bytes32 newSwapHash = getSwapHash(
            _sender, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        bytes32 claimFromHash;
         
         
        if (swaps[oldSwapHash] == 0) {
            claimFromHash = newSwapHash;
            requireSwapUnclaimed(newSwapHash);
        } else {
            claimFromHash = oldSwapHash;
            requireSwapUnclaimed(oldSwapHash);
            requireSwapNotExists(newSwapHash);
            swaps[oldSwapHash] = 0;
        }
         
         
         
        swaps[newSwapHash] = uint32(block.timestamp) + SWAP_LOCK_TIME_S;
        emit Claimed(claimFromHash, newSwapHash);
    }

     
    function release(
        address _sender,
        address payable _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external statusAtLeast(Status.FINALIZE_ONLY) onlyOracleOrSender(_sender, _oracle) {
        bytes32 swapHash = getSwapHash(
            _sender, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapClaimed(swapHash);
         
        swaps[swapHash] = 0;
        require(
            sendAssetTo(_assetData, _receiver),
            "failed to send asset to receiver"
        );
        if (msg.sender == _sender) {
            emit SenderReleased(swapHash);
        } else {
            emit Released(swapHash);
        }
    }

     
    function returnFunds(
        address payable _sender,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external statusAtLeast(Status.RETURN_ONLY) onlyOracleOrSender(_sender, _oracle) {
        bytes32 swapHash = getSwapHash(
            _sender, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapUnclaimedOrExpired(swapHash);
         
        swaps[swapHash] = 0;
        require(
            sendAssetTo(_assetData, _sender),
            "failed to send asset to sender"
        );
        if (msg.sender == _sender) {
            emit SenderReturned(swapHash);
        } else {
            emit Returned(swapHash);
        }
    }

     
    function setBuyer(
        address _sender,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external statusAtLeast(Status.ACTIVE) onlySender(_sender) {
        bytes32 assetHash = keccak256(_assetData);
        bytes32 oldSwapHash = getSwapHash(
            _sender, address(0), _oracle, assetHash, _paymentDetailsHash
        );
        requireSwapUnclaimed(oldSwapHash);
        bytes32 newSwapHash = getSwapHash(
            _sender, _receiver, _oracle, assetHash, _paymentDetailsHash
        );
        requireSwapNotExists(newSwapHash);
        swaps[oldSwapHash] = 0;
        swaps[newSwapHash] = SWAP_UNCLAIMED;
        emit BuyerSet(oldSwapHash, newSwapHash);
    }

     
    function getSwapStatus(
        address _sender,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external view returns (uint32 status) {
        bytes32 swapHash = getSwapHash(
            _sender, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        return swaps[swapHash];
    }

     
    function getSwapHash(
        address _sender,
        address _receiver,
        address _oracle,
        bytes32 assetHash,
        bytes32 _paymentDetailsHash
    ) internal pure returns (bytes32 hash) {
        return keccak256(
            abi.encodePacked(
                _sender, _receiver, _oracle, assetHash, _paymentDetailsHash
            )
        );
    }

     
    function getClaimTypedHash(
        address _sender,
        address _receiver,
        bytes memory _assetData,
        bytes32 _paymentDetailsHash
    ) internal view returns(bytes32 msgHash) {
        bytes32 dataHash = keccak256(
            abi.encode(
                EIP712_SWAP_TYPEHASH,
                bytes32("claim this swap"),
                _sender,
                _receiver,
                getAssetTypedHash(_assetData),
                _paymentDetailsHash
            )
        );
        return keccak256(abi.encodePacked(bytes2(0x1901), EIP712_DOMAIN_HASH, dataHash));
    }

    function requireSwapNotExists(bytes32 swapHash) internal view {
        require(swaps[swapHash] == 0, "swap already exists");
    }

    function requireSwapUnclaimed(bytes32 swapHash) internal view {
        require(swaps[swapHash] == SWAP_UNCLAIMED, "swap already claimed or invalid");
    }

    function requireSwapClaimed(bytes32 swapHash) internal view {
        require(swaps[swapHash] > MIN_ACTUAL_TIMESTAMP, "swap unclaimed or invalid");
    }

    function requireSwapUnclaimedOrExpired(bytes32 swapHash) internal view {
        require(
             
            (swaps[swapHash] > MIN_ACTUAL_TIMESTAMP && block.timestamp > swaps[swapHash]) ||
                swaps[swapHash] == SWAP_UNCLAIMED,
            "swap not expired or invalid"
        );
    }

}


 
contract TokenRampSwaps is AbstractRampSwaps, TokenAdapter {
    constructor(uint256 _chainId) public AbstractRampSwaps(_chainId) {}
}