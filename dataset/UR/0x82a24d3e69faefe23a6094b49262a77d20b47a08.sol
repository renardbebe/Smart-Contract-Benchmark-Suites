 

pragma solidity 0.5.10;

 


interface Erc20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256);

}

contract AssetAdapter {

    uint16 public ASSET_TYPE;

    constructor(
        uint16 assetType
    ) internal {
        ASSET_TYPE = assetType;
    }

     
    function rawSendAsset(
        bytes memory assetData,
        uint256 _amount,
        address payable _to
    ) internal returns (bool success);   
     

     
    function rawLockAsset(
        uint256 amount,
        address payable _from
    ) internal returns (bool success) {
        return RampInstantPoolInterface(_from).sendFundsToSwap(amount);
    }

    function getAmount(bytes memory assetData) internal pure returns (uint256);

     
    modifier checkAssetTypeAndData(bytes memory assetData, address _pool) {
        uint16 assetType;
         
        assembly {
            assetType := and(
                mload(add(assetData, 2)),
                0xffff
            )
        }
        require(assetType == ASSET_TYPE, "invalid asset type");
        checkAssetData(assetData, _pool);
        _;
    }

    function checkAssetData(bytes memory assetData, address _pool) internal view;

    function () external payable {
        revert("this contract cannot receive ether");
    }

}

contract RampInstantPoolInterface {

    uint16 public ASSET_TYPE;

    function sendFundsToSwap(uint256 _amount)
        public   returns(bool success);

}

contract RampInstantTokenPoolInterface is RampInstantPoolInterface {

    address public token;

}

contract Ownable {

    address public owner;

    event OwnerChanged(address oldOwner, address newOwner);

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can call this");
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(msg.sender, _newOwner);
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

    modifier onlyOracleOrPool(address _pool, address _oracle) {
        require(
            msg.sender == _pool || (msg.sender == _oracle && oracles[msg.sender]),
            "only the oracle or the pool can call this"
        );
        _;
    }

}

contract WithSwapsCreator is Ownable {

    address internal swapCreator;

    event SwapCreatorChanged(address _oldCreator, address _newCreator);

    constructor() internal {
        swapCreator = msg.sender;
    }

    function changeSwapCreator(address _newCreator) public onlyOwner {
        swapCreator = _newCreator;
        emit SwapCreatorChanged(msg.sender, _newCreator);
    }

    modifier onlySwapCreator() {
        require(msg.sender == swapCreator, "only the swap creator can call this");
        _;
    }

}

contract AssetAdapterWithFees is Ownable, AssetAdapter {

    uint16 public feeThousandthsPercent;
    uint256 public minFeeAmount;

    constructor(uint16 _feeThousandthsPercent, uint256 _minFeeAmount) public {
        require(_feeThousandthsPercent < (1 << 16), "fee % too high");
        require(_minFeeAmount <= (1 << 255), "minFeeAmount too high");
        feeThousandthsPercent = _feeThousandthsPercent;
        minFeeAmount = _minFeeAmount;
    }

    function rawAccumulateFee(bytes memory assetData, uint256 _amount) internal;

    function accumulateFee(bytes memory assetData) internal {
        rawAccumulateFee(assetData, getFee(getAmount(assetData)));
    }

    function withdrawFees(
        bytes calldata assetData,
        address payable _to
    ) external   returns (bool success);   

    function getFee(uint256 _amount) internal view returns (uint256) {
        uint256 fee = _amount * feeThousandthsPercent / 100000;
        return fee < minFeeAmount
            ? minFeeAmount
            : fee;
    }

    function getAmountWithFee(bytes memory assetData) internal view returns (uint256) {
        uint256 baseAmount = getAmount(assetData);
        return baseAmount + getFee(baseAmount);
    }

    function lockAssetWithFee(
        bytes memory assetData,
        address payable _from
    ) internal returns (bool success) {
        return rawLockAsset(getAmountWithFee(assetData), _from);
    }

    function sendAssetWithFee(
        bytes memory assetData,
        address payable _to
    ) internal returns (bool success) {
        return rawSendAsset(assetData, getAmountWithFee(assetData), _to);
    }

    function sendAssetKeepingFee(
        bytes memory assetData,
        address payable _to
    ) internal returns (bool success) {
        bool result = rawSendAsset(assetData, getAmount(assetData), _to);
        if (result) accumulateFee(assetData);
        return result;
    }

}

contract RampInstantEscrows
is Ownable, WithStatus, WithOracles, WithSwapsCreator, AssetAdapterWithFees {

     
    string public constant VERSION = "0.5.0";

    uint32 internal constant MIN_ACTUAL_TIMESTAMP = 1000000000;

     
    uint32 internal constant MIN_SWAP_LOCK_TIME_S = 24 hours;
    uint32 internal constant MAX_SWAP_LOCK_TIME_S = 30 days;

    event Created(bytes32 indexed swapHash);
    event Released(bytes32 indexed swapHash);
    event PoolReleased(bytes32 indexed swapHash);
    event Returned(bytes32 indexed swapHash);
    event PoolReturned(bytes32 indexed swapHash);

     
    mapping (bytes32 => uint32) internal swaps;

     
    function create(
        address payable _pool,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash,
        uint32 lockTimeS
    )
        external
        statusAtLeast(Status.ACTIVE)
        onlySwapCreator()
        isOracle(_oracle)
        checkAssetTypeAndData(_assetData, _pool)
        returns
        (bool success)
    {
        require(
            lockTimeS >= MIN_SWAP_LOCK_TIME_S && lockTimeS <= MAX_SWAP_LOCK_TIME_S,
            "lock time outside limits"
        );
        bytes32 swapHash = getSwapHash(
            _pool, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapNotExists(swapHash);
         
         
         
         
         
        swaps[swapHash] = uint32(block.timestamp) + lockTimeS;
        require(
            lockAssetWithFee(_assetData, _pool),
            "escrow lock failed"
        );
        emit Created(swapHash);
        return true;
    }

     
    function release(
        address _pool,
        address payable _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external statusAtLeast(Status.FINALIZE_ONLY) onlyOracleOrPool(_pool, _oracle) {
        bytes32 swapHash = getSwapHash(
            _pool, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapCreated(swapHash);
         
        swaps[swapHash] = 0;
        require(
            sendAssetKeepingFee(_assetData, _receiver),
            "asset release failed"
        );
        if (msg.sender == _pool) {
            emit PoolReleased(swapHash);
        } else {
            emit Released(swapHash);
        }
    }

     
    function returnFunds(
        address payable _pool,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external statusAtLeast(Status.RETURN_ONLY) onlyOracleOrPool(_pool, _oracle) {
        bytes32 swapHash = getSwapHash(
            _pool, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        requireSwapExpired(swapHash);
         
        swaps[swapHash] = 0;
        require(
            sendAssetWithFee(_assetData, _pool),
            "asset return failed"
        );
        if (msg.sender == _pool) {
            emit PoolReturned(swapHash);
        } else {
            emit Returned(swapHash);
        }
    }

     
    function getSwapStatus(
        address _pool,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external view returns (uint32 status) {
        bytes32 swapHash = getSwapHash(
            _pool, _receiver, _oracle, keccak256(_assetData), _paymentDetailsHash
        );
        return swaps[swapHash];
    }

     
    function getSwapHash(
        address _pool,
        address _receiver,
        address _oracle,
        bytes32 assetHash,
        bytes32 _paymentDetailsHash
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _pool, _receiver, _oracle, assetHash, _paymentDetailsHash
            )
        );
    }

    function requireSwapNotExists(bytes32 swapHash) internal view {
        require(
            swaps[swapHash] == 0,
            "swap already exists"
        );
    }

    function requireSwapCreated(bytes32 swapHash) internal view {
        require(
            swaps[swapHash] > MIN_ACTUAL_TIMESTAMP,
            "swap invalid"
        );
    }

    function requireSwapExpired(bytes32 swapHash) internal view {
        require(
             
            swaps[swapHash] > MIN_ACTUAL_TIMESTAMP && block.timestamp > swaps[swapHash],
            "swap not expired or invalid"
        );
    }

}

contract TokenAdapter is AssetAdapterWithFees {

    uint16 internal constant TOKEN_TYPE_ID = 2;
    uint16 internal constant TOKEN_ASSET_DATA_LENGTH = 54;
    mapping (address => uint256) internal accumulatedFees;

    constructor() internal AssetAdapter(TOKEN_TYPE_ID) {}

     
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

    function rawSendAsset(
        bytes memory assetData,
        uint256 _amount,
        address payable _to
    ) internal returns (bool success) {
        Erc20Token token = Erc20Token(getTokenAddress(assetData));
        return token.transfer(_to, _amount);
    }

    function rawAccumulateFee(bytes memory assetData, uint256 _amount) internal {
        accumulatedFees[getTokenAddress(assetData)] += _amount;
    }

    function withdrawFees(
        bytes calldata assetData,
        address payable _to
    ) external onlyOwner returns (bool success) {
        address token = getTokenAddress(assetData);
        uint256 fees = accumulatedFees[token];
        accumulatedFees[token] = 0;
        require(Erc20Token(token).transfer(_to, fees), "fees transfer failed");
        return true;
    }

    function checkAssetData(bytes memory assetData, address _pool) internal view {
        require(assetData.length == TOKEN_ASSET_DATA_LENGTH, "invalid asset data length");
        require(
            RampInstantTokenPoolInterface(_pool).token() == getTokenAddress(assetData),
            "invalid pool token address"
        );
    }

}

contract RampInstantTokenEscrows is RampInstantEscrows, TokenAdapter {

    constructor(
        uint16 _feeThousandthsPercent,
        uint256 _minFeeAmount
    ) public AssetAdapterWithFees(_feeThousandthsPercent, _minFeeAmount) {}

}