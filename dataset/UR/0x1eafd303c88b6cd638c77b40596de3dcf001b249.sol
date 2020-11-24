 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}






 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


library Attribute {
  enum AttributeType {
    ROLE_MANAGER,                    
    ROLE_OPERATOR,                   
    IS_BLACKLISTED,                  
    HAS_PASSED_KYC_AML,              
    NO_FEES,                         
     
    USER_DEFINED
  }

  function toUint256(AttributeType _type) internal pure returns (uint256) {
    return uint256(_type);
  }
}



 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


library BitManipulation {
  uint256 constant internal ONE = uint256(1);

  function setBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num | (ONE << _pos);
  }

  function clearBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num & ~(ONE << _pos);
  }

  function toggleBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num ^ (ONE << _pos);
  }

  function checkBit(uint256 _num, uint256 _pos) internal pure returns (bool) {
    return (_num >> _pos & ONE == ONE);
  }
}








 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}










 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



 
contract ClaimableEx is Claimable {
   
  function cancelOwnershipTransfer() onlyOwner public {
    pendingOwner = owner;
  }
}










 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}










 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}



 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}






 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}



 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}



 
contract NoOwnerEx is NoOwner {
  function reclaimEther(address _to) external onlyOwner {
    _to.transfer(address(this).balance);
  }

  function reclaimToken(ERC20Basic token, address _to) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(_to, balance);
  }
}











 
contract AddressSet is Ownable {
  mapping(address => bool) exist;
  address[] elements;

   
  function add(address _addr) onlyOwner public returns (bool) {
    if (contains(_addr)) {
      return false;
    }

    exist[_addr] = true;
    elements.push(_addr);
    return true;
  }

   
  function contains(address _addr) public view returns (bool) {
    return exist[_addr];
  }

   
  function elementAt(uint256 _index) onlyOwner public view returns (address) {
    require(_index < elements.length);

    return elements[_index];
  }

   
  function getTheNumberOfElements() onlyOwner public view returns (uint256) {
    return elements.length;
  }
}



 
contract BalanceSheet is ClaimableEx {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  AddressSet private holderSet;

  constructor() public {
    holderSet = new AddressSet();
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function addBalance(address _addr, uint256 _value) public onlyOwner {
    balances[_addr] = balances[_addr].add(_value);

    _checkHolderSet(_addr);
  }

  function subBalance(address _addr, uint256 _value) public onlyOwner {
    balances[_addr] = balances[_addr].sub(_value);
  }

  function setBalance(address _addr, uint256 _value) public onlyOwner {
    balances[_addr] = _value;

    _checkHolderSet(_addr);
  }

  function setBalanceBatch(
    address[] _addrs,
    uint256[] _values
  )
    public
    onlyOwner
  {
    uint256 _count = _addrs.length;
    require(_count == _values.length);

    for(uint256 _i = 0; _i < _count; _i++) {
      setBalance(_addrs[_i], _values[_i]);
    }
  }

  function getTheNumberOfHolders() public view returns (uint256) {
    return holderSet.getTheNumberOfElements();
  }

  function getHolder(uint256 _index) public view returns (address) {
    return holderSet.elementAt(_index);
  }

  function _checkHolderSet(address _addr) internal {
    if (!holderSet.contains(_addr)) {
      holderSet.add(_addr);
    }
  }
}



 
contract StandardToken is ClaimableEx, NoOwnerEx, ERC20 {
  using SafeMath for uint256;

  uint256 totalSupply_;

  BalanceSheet private balances;
  event BalanceSheetSet(address indexed sheet);

  mapping (address => mapping (address => uint256)) private allowed;

  constructor() public {
    totalSupply_ = 0;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances.balanceOf(_owner);
  }

   
  function setBalanceSheet(address _sheet) public onlyOwner returns (bool) {
    balances = BalanceSheet(_sheet);
    balances.claimOwnership();
    emit BalanceSheetSet(_sheet);
    return true;
  }

  function getTheNumberOfHolders() public view returns (uint256) {
    return balances.getTheNumberOfHolders();
  }

  function getHolder(uint256 _index) public view returns (address) {
    return balances.getHolder(_index);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    _transferFrom(_from, _to, _value, msg.sender);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    _approve(_spender, _value, msg.sender);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
  )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    _increaseApproval(_spender, _addedValue, msg.sender);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    _decreaseApproval(_spender, _subtractedValue, msg.sender);
    return true;
  }

  function _approve(
    address _spender,
    uint256 _value,
    address _tokenHolder
  )
    internal
  {
    allowed[_tokenHolder][_spender] = _value;

    emit Approval(_tokenHolder, _spender, _value);
  }

   
  function _burn(address _burner, uint256 _value) internal {
    require(_burner != 0);
    require(_value <= balanceOf(_burner), "not enough balance to burn");

     
     
    balances.subBalance(_burner, _value);
    totalSupply_ = totalSupply_.sub(_value);

    emit Transfer(_burner, address(0), _value);
  }

  function _decreaseApproval(
    address _spender,
    uint256 _subtractedValue,
    address _tokenHolder
  )
    internal
  {
    uint256 _oldValue = allowed[_tokenHolder][_spender];
    if (_subtractedValue >= _oldValue) {
      allowed[_tokenHolder][_spender] = 0;
    } else {
      allowed[_tokenHolder][_spender] = _oldValue.sub(_subtractedValue);
    }

    emit Approval(_tokenHolder, _spender, allowed[_tokenHolder][_spender]);
  }

  function _increaseApproval(
    address _spender,
    uint256 _addedValue,
    address _tokenHolder
  )
    internal
  {
    allowed[_tokenHolder][_spender] = (
      allowed[_tokenHolder][_spender].add(_addedValue));

    emit Approval(_tokenHolder, _spender, allowed[_tokenHolder][_spender]);
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);

    totalSupply_ = totalSupply_.add(_amount);
    balances.addBalance(_account, _amount);

    emit Transfer(address(0), _account, _amount);
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0), "to address cannot be 0x0");
    require(_from != address(0),"from address cannot be 0x0");
    require(_value <= balanceOf(_from), "not enough balance to transfer");

     
    balances.subBalance(_from, _value);
    balances.addBalance(_to, _value);

    emit Transfer(_from, _to, _value);
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _spender
  )
    internal
  {
    uint256 _allowed = allowed[_from][_spender];
    require(_value <= _allowed, "not enough allowance to transfer");

    allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
    _transfer(_from, _to, _value);
  }
}





 
contract BurnableToken is StandardToken {
  event Burn(address indexed burner, uint256 value, string note);

   
  function burn(uint256 _value, string _note) public returns (bool) {
    _burn(msg.sender, _value, _note);

    return true;
  }

   
  function _burn(
    address _burner,
    uint256 _value,
    string _note
  )
    internal
  {
    _burn(_burner, _value);

    emit Burn(_burner, _value, _note);
  }
}




















 
contract RegistryAccessManager {
   
   
  function confirmWrite(
    address _who,
    Attribute.AttributeType _attribute,
    address _admin
  )
    public returns (bool);
}



contract DefaultRegistryAccessManager is RegistryAccessManager {
  function confirmWrite(
    address  ,
    Attribute.AttributeType _attribute,
    address _operator
  )
    public
    returns (bool)
  {
    Registry _client = Registry(msg.sender);
    if (_operator == _client.owner()) {
      return true;
    } else if (_client.hasAttribute(_operator, Attribute.AttributeType.ROLE_MANAGER)) {
      return (_attribute == Attribute.AttributeType.ROLE_OPERATOR);
    } else if (_client.hasAttribute(_operator, Attribute.AttributeType.ROLE_OPERATOR)) {
      return (_attribute != Attribute.AttributeType.ROLE_OPERATOR &&
              _attribute != Attribute.AttributeType.ROLE_MANAGER);
    }
  }
}




contract Registry is ClaimableEx {
  using BitManipulation for uint256;

  struct AttributeData {
    uint256 value;
  }

   
   
   
   
   
   
  mapping(address => AttributeData) private attributes;

   
   
  RegistryAccessManager public accessManager;

  event SetAttribute(
    address indexed who,
    Attribute.AttributeType attribute,
    bool enable,
    string notes,
    address indexed adminAddr
  );

  event SetManager(
    address indexed oldManager,
    address indexed newManager
  );

  constructor() public {
    accessManager = new DefaultRegistryAccessManager();
  }

   
  function setAttribute(
    address _who,
    Attribute.AttributeType _attribute,
    string _notes
  )
    public
  {
    bool _canWrite = accessManager.confirmWrite(
      _who,
      _attribute,
      msg.sender
    );
    require(_canWrite);

     
    uint256 _tempVal = attributes[_who].value;

    attributes[_who] = AttributeData(
      _tempVal.setBit(Attribute.toUint256(_attribute))
    );

    emit SetAttribute(_who, _attribute, true, _notes, msg.sender);
  }

  function clearAttribute(
    address _who,
    Attribute.AttributeType _attribute,
    string _notes
  )
    public
  {
    bool _canWrite = accessManager.confirmWrite(
      _who,
      _attribute,
      msg.sender
    );
    require(_canWrite);

     
    uint256 _tempVal = attributes[_who].value;

    attributes[_who] = AttributeData(
      _tempVal.clearBit(Attribute.toUint256(_attribute))
    );

    emit SetAttribute(_who, _attribute, false, _notes, msg.sender);
  }

   
  function hasAttribute(
    address _who,
    Attribute.AttributeType _attribute
  )
    public
    view
    returns (bool)
  {
    return attributes[_who].value.checkBit(Attribute.toUint256(_attribute));
  }

   
  function getAttributes(
    address _who
  )
    public
    view
    returns (uint256)
  {
    AttributeData memory _data = attributes[_who];
    return _data.value;
  }

  function setManager(RegistryAccessManager _accessManager) public onlyOwner {
    emit SetManager(accessManager, _accessManager);
    accessManager = _accessManager;
  }
}



 
contract HasRegistry is Ownable {
  Registry public registry;

  event SetRegistry(address indexed registry);

  function setRegistry(Registry _registry) public onlyOwner {
    registry = _registry;
    emit SetRegistry(registry);
  }
}



 
contract Manageable is HasRegistry {
   
  modifier onlyManager() {
    require(
      registry.hasAttribute(
        msg.sender,
        Attribute.AttributeType.ROLE_MANAGER
      )
    );
    _;
  }

   
  function isManager(address _operator) public view returns (bool) {
    return registry.hasAttribute(
      _operator,
      Attribute.AttributeType.ROLE_MANAGER
    );
  }
}



 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract DelegateBurnable {
  function delegateTotalSupply() public view returns (uint256);

  function delegateBalanceOf(address _who) public view returns (uint256);

  function delegateTransfer(address _to, uint256 _value, address _origSender)
    public returns (bool);

  function delegateAllowance(address _owner, address _spender)
    public view returns (uint256);

  function delegateTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _origSender
  )
    public returns (bool);

  function delegateApprove(
    address _spender,
    uint256 _value,
    address _origSender
  )
    public returns (bool);

  function delegateIncreaseApproval(
    address _spender,
    uint256 _addedValue,
    address _origSender
  )
    public returns (bool);

  function delegateDecreaseApproval(
    address _spender,
    uint256 _subtractedValue,
    address _origSender
  )
    public returns (bool);

  function delegateBurn(
    address _origSender,
    uint256 _value,
    string _note
  )
    public;

  function delegateGetTheNumberOfHolders() public view returns (uint256);

  function delegateGetHolder(uint256 _index) public view returns (address);
}







 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}










 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}





 
contract PausableToken is StandardToken, Pausable {

  function _transfer(
    address _from,
    address _to,
    uint256 _value
  )
    internal
    whenNotPaused
  {
    super._transfer(_from, _to, _value);
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _spender
  )
    internal
    whenNotPaused
  {
    super._transferFrom(_from, _to, _value, _spender);
  }

  function _approve(
    address _spender,
    uint256 _value,
    address _tokenHolder
  )
    internal
    whenNotPaused
  {
    super._approve(_spender, _value, _tokenHolder);
  }

  function _increaseApproval(
    address _spender,
    uint256 _addedValue,
    address _tokenHolder
  )
    internal
    whenNotPaused
  {
    super._increaseApproval(_spender, _addedValue, _tokenHolder);
  }

  function _decreaseApproval(
    address _spender,
    uint256 _subtractedValue,
    address _tokenHolder
  )
    internal
    whenNotPaused
  {
    super._decreaseApproval(_spender, _subtractedValue, _tokenHolder);
  }

  function _burn(
    address _burner,
    uint256 _value
  )
    internal
    whenNotPaused
  {
    super._burn(_burner, _value);
  }
}







 
contract CanDelegateToken is BurnableToken {
   
   
  DelegateBurnable public delegate;

  event DelegateToNewContract(address indexed newContract);

   
  function delegateToNewContract(
    DelegateBurnable _newContract
  )
    public
    onlyOwner
  {
    delegate = _newContract;
    emit DelegateToNewContract(delegate);
  }

   
  function _transfer(address _from, address _to, uint256 _value) internal {
    if (!_hasDelegate()) {
      super._transfer(_from, _to, _value);
    } else {
      require(delegate.delegateTransfer(_to, _value, _from));
    }
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _spender
  )
    internal
  {
    if (!_hasDelegate()) {
      super._transferFrom(_from, _to, _value, _spender);
    } else {
      require(delegate.delegateTransferFrom(_from, _to, _value, _spender));
    }
  }

  function totalSupply() public view returns (uint256) {
    if (!_hasDelegate()) {
      return super.totalSupply();
    } else {
      return delegate.delegateTotalSupply();
    }
  }

  function balanceOf(address _who) public view returns (uint256) {
    if (!_hasDelegate()) {
      return super.balanceOf(_who);
    } else {
      return delegate.delegateBalanceOf(_who);
    }
  }

  function getTheNumberOfHolders() public view returns (uint256) {
    if (!_hasDelegate()) {
      return super.getTheNumberOfHolders();
    } else {
      return delegate.delegateGetTheNumberOfHolders();
    }
  }

  function getHolder(uint256 _index) public view returns (address) {
    if (!_hasDelegate()) {
      return super.getHolder(_index);
    } else {
      return delegate.delegateGetHolder(_index);
    }
  }

  function _approve(
    address _spender,
    uint256 _value,
    address _tokenHolder
  )
    internal
  {
    if (!_hasDelegate()) {
      super._approve(_spender, _value, _tokenHolder);
    } else {
      require(delegate.delegateApprove(_spender, _value, _tokenHolder));
    }
  }

  function allowance(
    address _owner,
    address _spender
  )
    public
    view
    returns (uint256)
  {
    if (!_hasDelegate()) {
      return super.allowance(_owner, _spender);
    } else {
      return delegate.delegateAllowance(_owner, _spender);
    }
  }

  function _increaseApproval(
    address _spender,
    uint256 _addedValue,
    address _tokenHolder
  )
    internal
  {
    if (!_hasDelegate()) {
      super._increaseApproval(_spender, _addedValue, _tokenHolder);
    } else {
      require(
        delegate.delegateIncreaseApproval(_spender, _addedValue, _tokenHolder)
      );
    }
  }

  function _decreaseApproval(
    address _spender,
    uint256 _subtractedValue,
    address _tokenHolder
  )
    internal
  {
    if (!_hasDelegate()) {
      super._decreaseApproval(_spender, _subtractedValue, _tokenHolder);
    } else {
      require(
        delegate.delegateDecreaseApproval(
          _spender,
          _subtractedValue,
          _tokenHolder)
      );
    }
  }

  function _burn(address _burner, uint256 _value, string _note) internal {
    if (!_hasDelegate()) {
      super._burn(_burner, _value, _note);
    } else {
      delegate.delegateBurn(_burner, _value , _note);
    }
  }

  function _hasDelegate() internal view returns (bool) {
    return !(delegate == address(0));
  }
}







 
 
 
contract DelegateToken is DelegateBurnable, BurnableToken {
  address public delegatedFrom;

  event DelegatedFromSet(address addr);

   
  modifier onlyMandator() {
    require(msg.sender == delegatedFrom);
    _;
  }

  function setDelegatedFrom(address _addr) public onlyOwner {
    delegatedFrom = _addr;
    emit DelegatedFromSet(_addr);
  }

   
  function delegateTotalSupply(
  )
    public
    onlyMandator
    view
    returns (uint256)
  {
    return totalSupply();
  }

  function delegateBalanceOf(
    address _who
  )
    public
    onlyMandator
    view
    returns (uint256)
  {
    return balanceOf(_who);
  }

  function delegateTransfer(
    address _to,
    uint256 _value,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    _transfer(_origSender, _to, _value);
    return true;
  }

  function delegateAllowance(
    address _owner,
    address _spender
  )
    public
    onlyMandator
    view
    returns (uint256)
  {
    return allowance(_owner, _spender);
  }

  function delegateTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    _transferFrom(_from, _to, _value, _origSender);
    return true;
  }

  function delegateApprove(
    address _spender,
    uint256 _value,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    _approve(_spender, _value, _origSender);
    return true;
  }

  function delegateIncreaseApproval(
    address _spender,
    uint256 _addedValue,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    _increaseApproval(_spender, _addedValue, _origSender);
    return true;
  }

  function delegateDecreaseApproval(
    address _spender,
    uint256 _subtractedValue,
    address _origSender
  )
    public
    onlyMandator
    returns (bool)
  {
    _decreaseApproval(_spender, _subtractedValue, _origSender);
    return true;
  }

  function delegateBurn(
    address _origSender,
    uint256 _value,
    string _note
  )
    public
    onlyMandator
  {
    _burn(_origSender, _value , _note);
  }

  function delegateGetTheNumberOfHolders() public view returns (uint256) {
    return getTheNumberOfHolders();
  }

  function delegateGetHolder(uint256 _index) public view returns (address) {
    return getHolder(_index);
  }
}






 
contract AssetInfo is Manageable {
  string public publicDocument;

   
  event UpdateDocument(
    string newLink
  );

   
  constructor(string _publicDocument) public {
    publicDocument = _publicDocument;
  }

   
  function setPublicDocument(string _link) public onlyManager {
    publicDocument = _link;

    emit UpdateDocument(publicDocument);
  }
}







 
contract BurnableExToken is Manageable, BurnableToken {

   
  function burnAll(string _note) external onlyManager {
    uint256 _holdersCount = getTheNumberOfHolders();
    for (uint256 _i = 0; _i < _holdersCount; ++_i) {
      address _holder = getHolder(_i);
      uint256 _balance = balanceOf(_holder);
      if (_balance == 0) continue;

      _burn(_holder, _balance, _note);
    }
  }
}








 
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 value);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _value
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    _mint(_to, _value);

    emit Mint(_to, _value);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}




contract CompliantToken is HasRegistry, MintableToken {
   
   
   

  modifier onlyIfNotBlacklisted(address _addr) {
    require(
      !registry.hasAttribute(
        _addr,
        Attribute.AttributeType.IS_BLACKLISTED
      )
    );
    _;
  }

  modifier onlyIfBlacklisted(address _addr) {
    require(
      registry.hasAttribute(
        _addr,
        Attribute.AttributeType.IS_BLACKLISTED
      )
    );
    _;
  }

  modifier onlyIfPassedKYC_AML(address _addr) {
    require(
      registry.hasAttribute(
        _addr,
        Attribute.AttributeType.HAS_PASSED_KYC_AML
      )
    );
    _;
  }

  function _mint(
    address _to,
    uint256 _value
  )
    internal
    onlyIfPassedKYC_AML(_to)
    onlyIfNotBlacklisted(_to)
  {
    super._mint(_to, _value);
  }

   
  function _transfer(
    address _from,
    address _to,
    uint256 _value
  )
    internal
    onlyIfNotBlacklisted(_from)
    onlyIfNotBlacklisted(_to)
    onlyIfPassedKYC_AML(_to)
  {
    super._transfer(_from, _to, _value);
  }
}







 
contract TokenWithFees is Manageable, StandardToken {
  uint8 public transferFeeNumerator = 0;
  uint8 public transferFeeDenominator = 100;
   
  address public beneficiary;

  event ChangeWallet(address indexed addr);
  event ChangeFees(uint8 transferFeeNumerator,
                   uint8 transferFeeDenominator);

  constructor(address _wallet) public {
    beneficiary = _wallet;
  }

   
   
   
  function _transfer(address _from, address _to, uint256 _value) internal {
    uint256 _fee = _payFee(_from, _value, _to);
    uint256 _remaining = _value.sub(_fee);
    super._transfer(_from, _to, _remaining);
  }

  function _payFee(
    address _payer,
    uint256 _value,
    address _otherParticipant
  )
    internal
    returns (uint256)
  {
     
    bool _shouldBeFree = (
      registry.hasAttribute(_payer, Attribute.AttributeType.NO_FEES) ||
      registry.hasAttribute(_otherParticipant, Attribute.AttributeType.NO_FEES)
    );
    if (_shouldBeFree) {
      return 0;
    }

    uint256 _fee = _value.mul(transferFeeNumerator).div(transferFeeDenominator);
    if (_fee > 0) {
      super._transfer(_payer, beneficiary, _fee);
    }
    return _fee;
  }

  function checkTransferFee(uint256 _value) public view returns (uint256) {
    return _value.mul(transferFeeNumerator).div(transferFeeDenominator);
  }

  function changeFees(
    uint8 _transferFeeNumerator,
    uint8 _transferFeeDenominator
  )
    public
    onlyManager
  {
    require(_transferFeeNumerator < _transferFeeDenominator);
    transferFeeNumerator = _transferFeeNumerator;
    transferFeeDenominator = _transferFeeDenominator;

    emit ChangeFees(transferFeeNumerator, transferFeeDenominator);
  }

   
  function changeWallet(address _beneficiary) public onlyManager {
    require(_beneficiary != address(0), "new wallet cannot be 0x0");
    beneficiary = _beneficiary;

    emit ChangeWallet(_beneficiary);
  }
}






 
 
 
contract WithdrawalToken is BurnableToken {
  address public constant redeemAddress = 0xfacecafe01facecafe02facecafe03facecafe04;

  function _transfer(address _from, address _to, uint256 _value) internal {
    if (_to == redeemAddress) {
      burn(_value, '');
    } else {
      super._transfer(_from, _to, _value);
    }
  }

   
   
   
  function _transferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _spender
  ) internal {
    require(_to != redeemAddress, "_to is redeem address");

    super._transferFrom(_from, _to, _value, _spender);
  }
}



 
contract PATToken is Contactable, AssetInfo, BurnableExToken, CanDelegateToken, DelegateToken, TokenWithFees, CompliantToken, WithdrawalToken, PausableToken {
  string public name = "RAX Mt.Fuji";
  string public symbol = "FUJI";
  uint8 public constant decimals = 18;

  event ChangeTokenName(string newName, string newSymbol);

   
  constructor(
    string _name,
    string _symbol,
    string _publicDocument,
    address _wallet
  )
    public
    AssetInfo(_publicDocument)
    TokenWithFees(_wallet)
  {
    name = _name;
    symbol = _symbol;
    contactInformation = 'https: 
  }

  function changeTokenName(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;
    emit ChangeTokenName(_name, _symbol);
  }

   
  function transferOwnership(address _newOwner) onlyOwner public {
     
    require(_newOwner != address(this));
    super.transferOwnership(_newOwner);
  }
}