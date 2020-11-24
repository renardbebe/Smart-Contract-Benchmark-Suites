 

 

pragma solidity 0.5.8;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns (address);
}


 
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

interface ERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

     
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface ERC777Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function granularity() external view returns (uint256);

    function defaultOperators() external view returns (address[] memory);
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;

    function send(address to, uint256 amount, bytes calldata data) external;
    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function burn(uint256 amount, bytes calldata data) external;
    function operatorBurn(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ERC777TokensSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

contract ERC777BaseToken is ERC777Token, ERC1820Client {
    using SafeMath for uint256;

    string internal mName;
    string internal mSymbol;
    uint256 internal mGranularity;
    uint256 internal mTotalSupply;


    mapping(address => uint) internal mBalances;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;
    mapping(address => mapping(address => bool)) internal mAuthorizedOperators;

     
     
     
     
     
     
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _granularity,
        address[] memory _defaultOperators
    ) internal {
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = 0;
        require(_granularity >= 1, "Granularity must be > 1");
        mGranularity = _granularity;

        mDefaultOperators = _defaultOperators;
        for (uint256 i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

        setInterfaceImplementation("ERC777Token", address(this));
    }

     
     
     
    function name() public view returns (string memory) { return mName; }

     
    function symbol() public view returns (string memory) { return mSymbol; }

     
    function granularity() public view returns (uint256) { return mGranularity; }

     
    function totalSupply() public view returns (uint256) { return mTotalSupply; }

     
     
     
    function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

     
     
    function defaultOperators() public view returns (address[] memory) { return mDefaultOperators; }

     
     
     
    function send(address _to, uint256 _amount, bytes calldata _data) external {
        doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
    }

     
     
    function authorizeOperator(address _operator) external {
        require(_operator != msg.sender, "Cannot authorize yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = true;
        }
        emit AuthorizedOperator(_operator, msg.sender);
    }

     
     
    function revokeOperator(address _operator) external {
        require(_operator != msg.sender, "Cannot revoke yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = false;
        }
        emit RevokedOperator(_operator, msg.sender);
    }

     
     
     
     
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return (_operator == _tokenHolder  
            || mAuthorizedOperators[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

     
     
     
     
     
     
    function operatorSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
    {
        require(isOperatorFor(msg.sender, _from), "Not an operator");
        doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
    }

    function burn(uint256 _amount, bytes calldata _data) external {
        doBurn(msg.sender, msg.sender, _amount, _data, "");
    }

    function operatorBurn(
        address _tokenHolder,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
    {
        require(isOperatorFor(msg.sender, _tokenHolder), "Not an operator");
        doBurn(msg.sender, _tokenHolder, _amount, _data, _operatorData);
    }

     
     
     
     
    function requireMultiple(uint256 _amount) internal view {
        require(_amount % mGranularity == 0, "Amount is not a multiple of granualrity");
    }

     
     
     
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == address(0)) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) }  
        return size == 0;
    }

     
     
     
     
     
     
     
     
     
     
     
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _preventLocking
    )
        internal
    {
         
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _data, _operatorData);

        require(_to != address(0), "Cannot send to 0x0");
        require(mBalances[_from] >= _amount, "Not enough funds");

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _data, _operatorData);
    }

     
     
     
     
     
     
    function doBurn(
        address _operator,
        address _tokenHolder,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
    {
        callSender(_operator, _tokenHolder, address(0), _amount, _data, _operatorData);

        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount, "Not enough funds");

        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        emit Burned(_operator, _tokenHolder, _amount, _data, _operatorData);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != address(0)) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _data, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to), "Cannot send to contract without ERC777TokensRecipient");
        }
    }

     
     
     
     
     
     
     
     
     
     
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
    {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation == address(0)) { return; }
        ERC777TokensSender(senderImplementation).tokensToSend(
            _operator, _from, _to, _amount, _data, _operatorData);
    }
}


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken, Ownable {
    bool internal mErc20compatible;

    mapping(address => mapping(address => uint256)) internal mAllowed;

     
     
    mapping(address => bool) public allowedAddresses;
    mapping(address => bool) public lockedAddresses;
    bool public locked = false;

    function allowAddress(address _addr, bool _isallowed) public onlyOwner {
      require(_addr != owner());
      allowedAddresses[_addr] = _isallowed;
    }

    function lockAddress(address _addr, bool _locked) public onlyOwner {
      require(_addr != owner());
      lockedAddresses[_addr] = _locked;
    }

    function setLocked(bool _locked) public onlyOwner {
      locked = _locked;
    }

    function canTransfer(address _addr) public view returns (bool) {
      if (locked) {
        if(!allowedAddresses[_addr] &&_addr != owner()) return false;
      } else if (lockedAddresses[_addr]) return false;

      return true;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _granularity,
        address[] memory _defaultOperators
    )
        internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", address(this));
    }

     
     
     
    modifier erc20 () {
        require(mErc20compatible, "ERC20 is disabled");
        _;
    }

     
     
    function decimals() public erc20 view returns (uint8) { return uint8(18); }

     
     
     
     
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender], "Not enough funds allowed");

         
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        mAllowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public erc20 returns (bool) {
        _approve(msg.sender, spender, mAllowed[msg.sender][spender].add(addedValue));
        return true;
    }

    

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public erc20 returns (bool) {
        _approve(msg.sender, spender, mAllowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _preventLocking
    )
        internal
    {
        require(canTransfer(_from), "Not allowed to transfer right now!");
        super.doSend(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(
        address _operator,
        address _tokenHolder,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _data, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, address(0), _amount); }
    }
}



contract DATACHAIN is ERC777ERC20BaseToken {
    string internal dName = "DATACHAIN";
    string internal dSymbol = "DC";
    uint256 internal dGranularity = 1;
    uint256 internal dTotalSupply = 1000000000 * (10**18);

    function dDefaultOperators() internal pure returns (address[] memory) {
        address[] memory defaultOps = new address[](1);
        
        defaultOps[0] = 0xa6903375509A5F4f740aEC4Aa677b8C18D41027b;
        
        return defaultOps;
    }

    constructor() public 
        ERC777ERC20BaseToken(
            dName, 
            dSymbol, 
            dGranularity, 
            dDefaultOperators()) 
    {
        _mint(msg.sender, dTotalSupply);
    }

    function _mint(address to, uint256 value) internal returns (bool) {

        require(to != address(0));

        requireMultiple(value);

        mTotalSupply = mTotalSupply.add(value);
        mBalances[to] = mBalances[to].add(value);

        callRecipient(msg.sender, address(0), to, value, "", "", true);


        emit Minted(msg.sender, to, value, "", "");

        emit Transfer(address(0), to, value);

        return true;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}