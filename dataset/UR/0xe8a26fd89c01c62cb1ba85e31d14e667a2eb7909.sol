 

pragma solidity 0.5.10;

 


 
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


 
contract Stoppable is Ownable {

    bool public isActive = true;

    event IsActiveChanged(bool _isActive);

    modifier onlyActive() {
        require(isActive, "contract is stopped");
        _;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        if (_isActive == isActive) return;
        isActive = _isActive;
        emit IsActiveChanged(_isActive);
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

 
contract RampInstantEscrowsPoolInterface {

    uint16 public ASSET_TYPE;

    function release(
        address _pool,
        address payable _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    )
        external;  

    function returnFunds(
        address payable _pool,
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    )
        external;  

}

 
contract RampInstantPool is Ownable, Stoppable, RampInstantPoolInterface {

    uint256 constant private MAX_SWAP_AMOUNT_LIMIT = 1 << 240;
    uint16 public ASSET_TYPE;

    address payable public swapsContract;
    uint256 public minSwapAmount;
    uint256 public maxSwapAmount;
    bytes32 public paymentDetailsHash;

     
    event ReceivedFunds(address _from, uint256 _amount);
    event LimitsChanged(uint256 _minAmount, uint256 _maxAmount);
    event SwapsContractChanged(address _oldAddress, address _newAddress);

    constructor(
        address payable _swapsContract,
        uint256 _minSwapAmount,
        uint256 _maxSwapAmount,
        bytes32 _paymentDetailsHash,
        uint16 _assetType
    )
        public
        validateLimits(_minSwapAmount, _maxSwapAmount)
        validateSwapsContract(_swapsContract, _assetType)
    {
        swapsContract = _swapsContract;
        paymentDetailsHash = _paymentDetailsHash;
        minSwapAmount = _minSwapAmount;
        maxSwapAmount = _maxSwapAmount;
        ASSET_TYPE = _assetType;
    }

    function availableFunds() public view returns (uint256);

    function withdrawFunds(address payable _to, uint256 _amount)
        public   returns (bool success);

    function withdrawAllFunds(address payable _to) public onlyOwner returns (bool success) {
        return withdrawFunds(_to, availableFunds());
    }

    function setLimits(
        uint256 _minAmount,
        uint256 _maxAmount
    ) public onlyOwner validateLimits(_minAmount, _maxAmount) {
        minSwapAmount = _minAmount;
        maxSwapAmount = _maxAmount;
        emit LimitsChanged(_minAmount, _maxAmount);
    }

    function setSwapsContract(
        address payable _swapsContract
    ) public onlyOwner validateSwapsContract(_swapsContract, ASSET_TYPE) {
        address oldSwapsContract = swapsContract;
        swapsContract = _swapsContract;
        emit SwapsContractChanged(oldSwapsContract, _swapsContract);
    }

    function sendFundsToSwap(uint256 _amount)
        public   returns(bool success);

    function releaseSwap(
        address payable _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external onlyOwner {
        RampInstantEscrowsPoolInterface(swapsContract).release(
            address(this),
            _receiver,
            _oracle,
            _assetData,
            _paymentDetailsHash
        );
    }

    function returnSwap(
        address _receiver,
        address _oracle,
        bytes calldata _assetData,
        bytes32 _paymentDetailsHash
    ) external onlyOwner {
        RampInstantEscrowsPoolInterface(swapsContract).returnFunds(
            address(this),
            _receiver,
            _oracle,
            _assetData,
            _paymentDetailsHash
        );
    }

     
    function () external payable {
        revert("this pool cannot receive ether");
    }

    modifier onlySwapsContract() {
        require(msg.sender == swapsContract, "only the swaps contract can call this");
        _;
    }

    modifier isWithinLimits(uint256 _amount) {
        require(_amount >= minSwapAmount && _amount <= maxSwapAmount, "amount outside swap limits");
        _;
    }

    modifier validateLimits(uint256 _minAmount, uint256 _maxAmount) {
        require(_minAmount <= _maxAmount, "min limit over max limit");
        require(_maxAmount <= MAX_SWAP_AMOUNT_LIMIT, "maxAmount too high");
        _;
    }

    modifier validateSwapsContract(address payable _swapsContract, uint16 _assetType) {
        require(_swapsContract != address(0), "null swaps contract address");
        require(
            RampInstantEscrowsPoolInterface(_swapsContract).ASSET_TYPE() == _assetType,
            "pool asset type doesn't match swap contract"
        );
        _;
    }

}

 
interface Erc20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256);

}

 
contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
}


 
contract ERC777TokenRecipient {

    ERC1820Registry internal constant ERC1820REGISTRY = ERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );
    bytes32 internal constant ERC777TokenRecipientERC1820Hash = keccak256(
        abi.encodePacked("ERC777TokensRecipient")
    );
    bytes32 constant internal ERC1820_ACCEPT_MAGIC = keccak256(
        abi.encodePacked("ERC1820_ACCEPT_MAGIC")
    );

    constructor(bool _doSetErc1820Registry) internal {
        if (_doSetErc1820Registry) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                ERC777TokenRecipientERC1820Hash,
                address(this)
            );
        }
    }

    function canImplementInterfaceForAddress(
        bytes32 _interfaceHash,
        address _addr
    ) external view returns(bytes32) {
        if (_interfaceHash == ERC777TokenRecipientERC1820Hash && _addr == address(this)) {
            return ERC1820_ACCEPT_MAGIC;
        }
        return 0;
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData) external;

}

 
contract RampInstantTokenPool is RampInstantPool, ERC777TokenRecipient {

    uint16 internal constant TOKEN_TYPE_ID = 2;
    Erc20Token public token;

    constructor(
        address payable _swapsContract,
        uint256 _minSwapAmount,
        uint256 _maxSwapAmount,
        bytes32 _paymentDetailsHash,
        address _tokenAddress,
        bool _doSetErc1820Registry
    )
        public
        RampInstantPool(
            _swapsContract, _minSwapAmount, _maxSwapAmount, _paymentDetailsHash, TOKEN_TYPE_ID
        )
        ERC777TokenRecipient(_doSetErc1820Registry)
    {
        token = Erc20Token(_tokenAddress);
    }

    function availableFunds() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawFunds(
        address payable _to,
        uint256 _amount
    ) public onlyOwner returns (bool success) {
        return token.transfer(_to, _amount);
    }

    function sendFundsToSwap(
        uint256 _amount
    ) public onlyActive onlySwapsContract isWithinLimits(_amount) returns(bool success) {
        return token.transfer(swapsContract, _amount);
    }

     
    function tokenFallback(address _from, uint _value, bytes memory _data) public {
        require(_data.length == 0, "tokens with data not supported");
        if (_from != swapsContract) {
            emit ReceivedFunds(_from, _value);
        }
    }

     
    function tokensReceived(
        address  ,
        address _from,
        address  ,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata  
    ) external {
        require(_data.length == 0, "tokens with data not supported");
        if (_from != swapsContract) {
            emit ReceivedFunds(_from, _amount);
        }
    }

}