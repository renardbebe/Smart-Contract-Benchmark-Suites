 

pragma solidity ^0.4.24;


 
 
 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
 
 
 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 
contract Claimable is Ownable {
  address public pendingOwner;

  event OwnershipTransferPending(address indexed owner, address indexed pendingOwner);

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferPending(owner, pendingOwner);
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
 
 
 
contract Pausable is Claimable {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract Callable is Claimable {
  mapping(address => bool) public callers;

  event CallerAddressAdded(address indexed addr);
  event CallerAddressRemoved(address indexed addr);


   
  modifier onlyCaller() {
    require(callers[msg.sender]);
    _;
  }

   
  function addAddressToCaller(address addr) onlyOwner public returns(bool success) {
    if (!callers[addr]) {
      callers[addr] = true;
      emit CallerAddressAdded(addr);
      success = true;
    }
  }

   
  function removeAddressFromCaller(address addr) onlyOwner public returns(bool success) {
    if (callers[addr]) {
      callers[addr] = false;
      emit CallerAddressRemoved(addr);
      success = true;
    }
  }
}

 
 
 
 
contract Blacklist is Callable {
  mapping(address => bool) public blacklist;

  function addAddressToBlacklist(address addr) onlyCaller public returns (bool success) {
    if (!blacklist[addr]) {
      blacklist[addr] = true;
      success = true;
    }
  }

  function removeAddressFromBlacklist(address addr) onlyCaller public returns (bool success) {
    if (blacklist[addr]) {
      blacklist[addr] = false;
      success = true;
    }
  }
}

 
 
 
 
contract Verified is Callable {
  mapping(address => bool) public verifiedList;
  bool public shouldVerify = true;

  function verifyAddress(address addr) onlyCaller public returns (bool success) {
    if (!verifiedList[addr]) {
      verifiedList[addr] = true;
      success = true;
    }
  }

  function unverifyAddress(address addr) onlyCaller public returns (bool success) {
    if (verifiedList[addr]) {
      verifiedList[addr] = false;
      success = true;
    }
  }

  function setShouldVerify(bool value) onlyCaller public returns (bool success) {
    shouldVerify = value;
    return true;
  }
}

 
 
 
 
contract Allowance is Callable {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowanceOf;

  function addAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    allowanceOf[_holder][_spender] = allowanceOf[_holder][_spender].add(_value);
  }

  function subAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    uint256 oldValue = allowanceOf[_holder][_spender];
    if (_value > oldValue) {
      allowanceOf[_holder][_spender] = 0;
    } else {
      allowanceOf[_holder][_spender] = oldValue.sub(_value);
    }
  }

  function setAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    allowanceOf[_holder][_spender] = _value;
  }
}

 
 
 
 
contract Balance is Callable {
  using SafeMath for uint256;

  mapping (address => uint256) public balanceOf;

  uint256 public totalSupply;

  function addBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = balanceOf[_addr].add(_value);
  }

  function subBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = balanceOf[_addr].sub(_value);
  }

  function setBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = _value;
  }

  function addTotalSupply(uint256 _value) onlyCaller public {
    totalSupply = totalSupply.add(_value);
  }

  function subTotalSupply(uint256 _value) onlyCaller public {
    totalSupply = totalSupply.sub(_value);
  }
}

 
 
 
 
contract UserContract {
  Blacklist internal _blacklist;
  Verified internal _verifiedList;

  constructor(
    Blacklist _blacklistContract, Verified _verifiedListContract
  ) public {
    _blacklist = _blacklistContract;
    _verifiedList = _verifiedListContract;
  }


   
  modifier onlyNotBlacklistedAddr(address addr) {
    require(!_blacklist.blacklist(addr));
    _;
  }

   
  modifier onlyNotBlacklistedAddrs(address[] addrs) {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(!_blacklist.blacklist(addrs[i]));
    }
    _;
  }

   
  modifier onlyVerifiedAddr(address addr) {
    if (_verifiedList.shouldVerify()) {
      require(_verifiedList.verifiedList(addr));
    }
    _;
  }

   
  modifier onlyVerifiedAddrs(address[] addrs) {
    if (_verifiedList.shouldVerify()) {
      for (uint256 i = 0; i < addrs.length; i++) {
        require(_verifiedList.verifiedList(addrs[i]));
      }
    }
    _;
  }

  function blacklist(address addr) public view returns (bool) {
    return _blacklist.blacklist(addr);
  }

  function verifiedlist(address addr) public view returns (bool) {
    return _verifiedList.verifiedList(addr);
  }
}

 
 
 
contract ContractInterface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address tokenOwner) public view returns (uint256);
  function allowance(address tokenOwner, address spender) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function batchTransfer(address[] to, uint256 value) public returns (bool);
  function increaseApproval(address spender, uint256 value) public returns (bool);
  function decreaseApproval(address spender, uint256 value) public returns (bool);
  function burn(uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
   
  event Burn(address indexed from, uint256 value);
}

 
 
 
contract USDO is ContractInterface, Pausable, UserContract {
  using SafeMath for uint256;

   
  uint8 public constant decimals = 18;
  uint256 constant maxBatch = 100;

  string public name;
  string public symbol;

  Balance internal _balances;
  Allowance internal _allowance;

  constructor(string _tokenName, string _tokenSymbol,
    Balance _balanceContract, Allowance _allowanceContract,
    Blacklist _blacklistContract, Verified _verifiedListContract
  ) UserContract(_blacklistContract, _verifiedListContract) public {
    name = _tokenName;                                         
    symbol = _tokenSymbol;                                     
    _balances = _balanceContract;
    _allowance = _allowanceContract;
  }

  function totalSupply() public view returns (uint256) {
    return _balances.totalSupply();
  }

  function balanceOf(address _addr) public view returns (uint256) {
    return _balances.balanceOf(_addr);
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowance.allowanceOf(_owner, _spender);
  }

   
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_value > 0);                                                
    require(_to != 0x0);                                                
    require(_balances.balanceOf(_from) >= _value);                      
    uint256 previousBalances = _balances.balanceOf(_from).add(_balances.balanceOf(_to));  
    _balances.subBalance(_from, _value);                  
    _balances.addBalance(_to, _value);                      
    emit Transfer(_from, _to, _value);
     
    assert(_balances.balanceOf(_from) + _balances.balanceOf(_to) == previousBalances);
  }

   
  function transfer(address _to, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_to) onlyVerifiedAddr(msg.sender) onlyVerifiedAddr(_to)
  public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }


   
  function batchTransfer(address[] _to, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddrs(_to) onlyVerifiedAddr(msg.sender) onlyVerifiedAddrs(_to)
  public returns (bool) {
    uint256 cnt = uint256(_to.length);
    require(cnt > 0 && cnt <= maxBatch && _value > 0);
    uint256 amount = _value.mul(cnt);
    require(_balances.balanceOf(msg.sender) >= amount);

    for (uint256 i = 0; i < cnt; i++) {
      _transfer(msg.sender, _to[i], _value);
    }
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(_from) onlyNotBlacklistedAddr(_to) onlyVerifiedAddr(_from) onlyVerifiedAddr(_to)
  public returns (bool) {
    require(_allowance.allowanceOf(_from, msg.sender) >= _value);      
    _allowance.subAllowance(_from, msg.sender, _value);
    _transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender) onlyVerifiedAddr(msg.sender) onlyVerifiedAddr(_spender)
  public returns (bool) {
    _allowance.setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(address _spender, uint256 _addedValue)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender) onlyVerifiedAddr(msg.sender) onlyVerifiedAddr(_spender)
  public returns (bool) {
    _allowance.addAllowance(msg.sender, _spender, _addedValue);
    emit Approval(msg.sender, _spender, _allowance.allowanceOf(msg.sender, _spender));
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender) onlyVerifiedAddr(msg.sender) onlyVerifiedAddr(_spender)
  public returns (bool) {
    _allowance.subAllowance(msg.sender, _spender, _subtractedValue);
    emit Approval(msg.sender, _spender, _allowance.allowanceOf(msg.sender, _spender));
    return true;
  }

   
  function burn(uint256 _value) whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyVerifiedAddr(msg.sender)
  public returns (bool success) {
    require(_balances.balanceOf(msg.sender) >= _value);          
    _balances.subBalance(msg.sender, _value);                    
    _balances.subTotalSupply(_value);                            
    emit Burn(msg.sender, _value);
    return true;
  }

   
  function changeName(string _name, string _symbol) onlyOwner whenNotPaused public {
    name = _name;
    symbol = _symbol;
  }
}