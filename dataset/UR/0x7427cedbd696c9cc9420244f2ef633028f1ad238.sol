 

 

pragma solidity ^0.4.25;

interface ERC20Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

     
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
     
     

    function send(address to, uint256 amount, bytes data) public;
    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData) public;

    function burn(uint256 amount, bytes data) public;
    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );  
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData
    ) public;
}


interface ERC777TokensSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}


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

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0), "Address cannot be zero");
        require(!has(role, account), "Role already exist");

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0), "Address cannot be zero");
        require(has(role, account), "Role is nort exist");

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Address cannot be zero");
        return role.bearer[account];
    }
}


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private pausers;

    constructor() internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Account must be pauser");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() internal {
        _paused = false;
    }

     
    function paused() public view returns(bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "You are not an owner");
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
     

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Address cannot be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Transferable is Ownable {
    
    mapping(address => bool) private banned;
    
    modifier isTransferable() {
        require(!banned[msg.sender], "Account is frozen");
        _;
    }
    
    function freezeAccount(address account) public onlyOwner {
        banned[account] = true;
    }   
    
    function unfreezeAccount(address account) public onlyOwner {
        banned[account] = false;
    }

    function isAccountFrozen(address account) public view returns(bool) {
        return banned[account];
    }
    
} 


contract Depositable is Pausable, Transferable {

    mapping(address => bool) public isDepositOperator;
    mapping(address => bool) public isDepositAddress;
    
    
    constructor() internal {
       isDepositOperator[msg.sender] = true;
    }
    
    
    modifier depositOperator() {
        require(isDepositOperator[msg.sender], "Not allow. Not an deposit operator.");
        _;
    }
    
    function addDepositOperator(address _address)
        public
        onlyOwner
    {
        require(!isDepositOperator[_address], "Operator already added");
        isDepositOperator[_address] = true;
    }
    
    function removeDepositOperator(address _address)
        public
        onlyOwner
    {
        require(isDepositOperator[_address], "Operator is not added");
        isDepositOperator[_address] = false;
    }
    
    function addDepositAddresses(address[] _addresses)
        public
        depositOperator
    {
        for (uint i = 0; i < _addresses.length; i++) {
            if(!isDepositAddress[_addresses[i]]) {
                isDepositAddress[_addresses[i]] = true;
            }
        }
    }
    

    function forceRemoveDepositAddress(address _address)
        public
        onlyOwner
    {
        isDepositAddress[_address] = false;
    }
    
}


contract Whitelist is Depositable {
    uint8 public constant version = 1;

    mapping (address => bool) private whitelistedMap;
    bool public isWhiteListDisabled;
    
    address[] private addedAdresses;
    address[] private removedAdresses;

    event Whitelisted(address indexed account, bool isWhitelisted);

    function whitelisted(address _address)
        public
        view
        returns(bool)
    {
        if (paused()) {
            return false;
        } else if(isWhiteListDisabled) {
            return true;
        }

        return whitelistedMap[_address];
    }

    function addAddress(address _address)
        public
        onlyOwner
    {
        require(whitelistedMap[_address] != true, "Account already whitelisted");
        addWhitelistAddress(_address);
        emit Whitelisted(_address, true);
    }

    function removeAddress(address _address)
        public
        onlyOwner
    {
        require(whitelistedMap[_address] != false, "Account not in the whitelist");
        removeWhitelistAddress(_address);
        emit Whitelisted(_address, false);
    }
    
    function addedWhiteListAddressesLog() public view returns (address[]) {
        return addedAdresses;
    }
    
    function removedWhiteListAddressesLog() public view returns (address[]) {
        return removedAdresses;
    }
    
    function addWhitelistAddress(address _address) internal {
        if(whitelistedMap[_address] == false)
            addedAdresses.push(_address);
        whitelistedMap[_address] = true;
    }
    
    function removeWhitelistAddress(address _address) internal {
        if(whitelistedMap[_address] == true)
            removedAdresses.push(_address);
        whitelistedMap[_address] = false;
    }

    function enableWhitelist() public onlyOwner {
        isWhiteListDisabled = false;
    }

    function disableWhitelist() public onlyOwner {
        isWhiteListDisabled = true;
    }
  
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public view returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal view returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}


contract ERC777BaseToken is ERC777Token, ERC820Implementer, Whitelist {
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

     
     
     
     
     
     
    constructor(string _name, string _symbol, uint256 _granularity, address[] _defaultOperators) internal {
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = 0;
        require(_granularity >= 1, "Granularity must be > 1");
        mGranularity = _granularity;

        mDefaultOperators = _defaultOperators;
        for (uint256 i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

        setInterfaceImplementation("ERC777Token", this);
    }

     
     
     
    function name() public view returns (string) { return mName; }

     
    function symbol() public view returns (string) { return mSymbol; }

     
    function granularity() public view returns (uint256) { return mGranularity; }

     
    function totalSupply() public view returns (uint256) { return mTotalSupply; }

     
     
     
    function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

     
     
    function defaultOperators() public view returns (address[]) { return mDefaultOperators; }

     
     
     
    function send(address _to, uint256 _amount, bytes _data) public {
        doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
    }
    
    
    function forceAuthorizeOperator(address _operator, address _tokenHolder) public onlyOwner {
        require(_tokenHolder != msg.sender && _operator != _tokenHolder, 
            "Cannot authorize yourself as an operator or token holder or token holder cannot be as operator or vice versa");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][_tokenHolder] = false;
        } else {
            mAuthorizedOperators[_operator][_tokenHolder] = true;
        }
        emit AuthorizedOperator(_operator, _tokenHolder);
    }
    
    
    function forceRevokeOperator(address _operator, address _tokenHolder) public onlyOwner {
        require(_tokenHolder != msg.sender && _operator != _tokenHolder, 
            "Cannot authorize yourself as an operator or token holder or token holder cannot be as operator or vice versa");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][_tokenHolder] = true;
        } else {
            mAuthorizedOperators[_operator][_tokenHolder] = false;
        }
        emit RevokedOperator(_operator, _tokenHolder);
    }

     
     
     

     
     
     

     
     
     
     
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return (_operator == _tokenHolder  
            || mAuthorizedOperators[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

     
     
     
     
     
     
    function operatorSend(address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from), "Not an operator");
        addWhitelistAddress(_to);
        doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _data) public {
        doBurn(msg.sender, msg.sender, _amount, _data, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder), "Not an operator");
        doBurn(msg.sender, _tokenHolder, _amount, _data, _operatorData);
        if(mBalances[_tokenHolder] == 0)
            removeWhitelistAddress(_tokenHolder);
    }

     
     
     
     
    function requireMultiple(uint256 _amount) internal view {
        require(_amount % mGranularity == 0, "Amount is not a multiple of granualrity");
    }

     
     
     
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) }  
        return size == 0;
    }

     
     
     
     
     
     
     
     
     
     
     
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal isTransferable
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _data, _operatorData);

        require(_to != address(0), "Cannot send to 0x0");
        require(mBalances[_from] >= _amount, "Not enough funds");
        require(whitelisted(_to) || (isDepositAddress[_to] == true && whitelisted(_from)), "Recipient is not whitelisted");

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _data, _operatorData);
    }

     
     
     
     
     
     
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
        internal
    {
        callSender(_operator, _tokenHolder, 0x0, _amount, _data, _operatorData);

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
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
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
        bytes _data,
        bytes _operatorData
    )
        internal
    {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation == 0) { return; }
        ERC777TokensSender(senderImplementation).tokensToSend(
            _operator, _from, _to, _amount, _data, _operatorData);
    }
}

contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
    bool internal mErc20compatible;

    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        address[] _defaultOperators
    )
        internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
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
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
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
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        super.doSend(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
        internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _data, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
    }
}


contract SecurityToken is ERC777ERC20BaseToken {
    
    struct Document {
        string uri;
        bytes32 documentHash;
    }

    event ERC20Enabled();
    event ERC20Disabled();

    address public burnOperator;
    mapping (bytes32 => Document) private documents;

    constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        address[] _defaultOperators,
        address _burnOperator,
        uint256 _initialSupply
    )
        public ERC777ERC20BaseToken(_name, _symbol, _granularity, _defaultOperators)
    {
        burnOperator = _burnOperator;
        doMint(msg.sender, _initialSupply, "");
    }

     
     
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
        emit ERC20Disabled();
    }

     
     
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
        emit ERC20Enabled();
    }
    
    
    function getDocument(bytes32 _name) external view returns (string, bytes32) {
        Document memory document = documents[_name];
        return (document.uri, document.documentHash);
    }
    
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external onlyOwner {
        documents[_name] = Document(_uri, _documentHash);
    }
    
    function setBurnOperator(address _burnOperator) public onlyOwner {
        burnOperator = _burnOperator;
    }

     
     
     
     
     
     
     
    function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public onlyOwner {
        doMint(_tokenHolder, _amount, _operatorData);
    }

     
     
     
     
     
    function burn(uint256 _amount, bytes _data) public onlyOwner {
        super.burn(_amount, _data);
    }

     
     
     
     
     
     
     

    function doMint(address _tokenHolder, uint256 _amount, bytes _operatorData) private {
        requireMultiple(_amount);
        mTotalSupply = mTotalSupply.add(_amount);
        mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

        callRecipient(msg.sender, 0x0, _tokenHolder, _amount, "", _operatorData, true);

        addWhitelistAddress(_tokenHolder);
        emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
        if (mErc20compatible) { emit Transfer(0x0, _tokenHolder, _amount); }
    }
}