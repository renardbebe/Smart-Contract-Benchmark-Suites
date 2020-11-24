 

pragma solidity ^0.4.25;


 
 
 
 
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

 
 
 
 
contract Administratable is Claimable {
  struct MintStruct {
    uint256 mintedTotal;
    uint256 lastMintTimestamp;
  }

  struct BurnStruct {
    uint256 burntTotal;
    uint256 lastBurnTimestamp;
  }

  mapping(address => bool) public admins;
  mapping(address => MintStruct) public mintLimiter;
  mapping(address => BurnStruct) public burnLimiter;

  event AdminAddressAdded(address indexed addr);
  event AdminAddressRemoved(address indexed addr);


   
  modifier onlyAdmin() {
    require(admins[msg.sender] || msg.sender == owner);
    _;
  }

   
  function addAddressToAdmin(address addr) onlyOwner public returns(bool success) {
    if (!admins[addr]) {
      admins[addr] = true;
      mintLimiter[addr] = MintStruct(0, 0);
      burnLimiter[addr] = BurnStruct(0, 0);
      emit AdminAddressAdded(addr);
      success = true;
    }
  }

   
  function removeAddressFromAdmin(address addr) onlyOwner public returns(bool success) {
    if (admins[addr]) {
      admins[addr] = false;
      delete mintLimiter[addr];
      delete burnLimiter[addr];
      emit AdminAddressRemoved(addr);
      success = true;
    }
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

 
 
 
 
contract Blacklistable {
  Blacklist internal _blacklist;

  constructor(
    Blacklist _blacklistContract
  ) public {
    _blacklist = _blacklistContract;
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

  function blacklist(address addr) public view returns (bool) {
    return _blacklist.blacklist(addr);
  }
}

 
contract ControllerTest is Pausable, Administratable, Blacklistable {
  using SafeMath for uint256;
  Balance internal _balances;

  uint256 constant decimals = 18;
  uint256 constant maxBLBatch = 100;
  uint256 public dailyMintLimit = 10000 * 10 ** decimals;
  uint256 public dailyBurnLimit = 10000 * 10 ** decimals;
  uint256 constant dayInSeconds = 86400;

  constructor(
    Balance _balanceContract, Blacklist _blacklistContract
  ) Blacklistable(_blacklistContract) public {
    _balances = _balanceContract;
  }

   
  event Burn(address indexed from, uint256 value);
   
  event Mint(address indexed to, uint256 value);
   
  event LimitMint(address indexed admin, address indexed to, uint256 value);
   
  event LimitBurn(address indexed admin, address indexed from, uint256 value);

  event BlacklistedAddressAdded(address indexed addr);
  event BlacklistedAddressRemoved(address indexed addr);

   
  function _addToBlacklist(address addr) internal returns (bool success) {
    success = _blacklist.addAddressToBlacklist(addr);
    if (success) {
      emit BlacklistedAddressAdded(addr);
    }
  }

  function _removeFromBlacklist(address addr) internal returns (bool success) {
    success = _blacklist.removeAddressFromBlacklist(addr);
    if (success) {
      emit BlacklistedAddressRemoved(addr);
    }
  }

   
  function addAddressToBlacklist(address addr) onlyAdmin whenNotPaused public returns (bool) {
    return _addToBlacklist(addr);
  }

   
  function addAddressesToBlacklist(address[] addrs) onlyAdmin whenNotPaused public returns (bool success) {
    uint256 cnt = uint256(addrs.length);
    require(cnt <= maxBLBatch);
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_addToBlacklist(addrs[i])) {
        success = false;
      }
    }
  }

   
  function removeAddressFromBlacklist(address addr) onlyAdmin whenNotPaused public returns (bool) {
    return _removeFromBlacklist(addr);
  }

   
  function removeAddressesFromBlacklist(address[] addrs) onlyAdmin whenNotPaused public returns (bool success) {
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_removeFromBlacklist(addrs[i])) {
        success = false;
      }
    }
  }

   
  function burnFrom(address _from, uint256 _amount) onlyOwner whenNotPaused
  public returns (bool success) {
    require(_balances.balanceOf(_from) >= _amount);     
    _balances.subBalance(_from, _amount);               
    _balances.subTotalSupply(_amount);
    emit Burn(_from, _amount);
    return true;
  }

   
  function limitBurnFrom(address _from, uint256 _amount) onlyAdmin whenNotPaused
  public returns (bool success) {
    require(_balances.balanceOf(_from) >= _amount && _amount <= dailyBurnLimit);
    if (burnLimiter[msg.sender].lastBurnTimestamp.div(dayInSeconds) != now.div(dayInSeconds)) {
      burnLimiter[msg.sender].burntTotal = 0;
    }
    require(burnLimiter[msg.sender].burntTotal.add(_amount) <= dailyBurnLimit);
    _balances.subBalance(_from, _amount);               
    _balances.subTotalSupply(_amount);
    burnLimiter[msg.sender].lastBurnTimestamp = now;
    burnLimiter[msg.sender].burntTotal = burnLimiter[msg.sender].burntTotal.add(_amount);
    emit LimitBurn(msg.sender, _from, _amount);
    emit Burn(_from, _amount);
    return true;
  }

   
  function limitMint(address _to, uint256 _amount)
  onlyAdmin whenNotPaused onlyNotBlacklistedAddr(_to)
  public returns (bool success) {
    require(_to != msg.sender);
    require(_amount <= dailyMintLimit);
    if (mintLimiter[msg.sender].lastMintTimestamp.div(dayInSeconds) != now.div(dayInSeconds)) {
      mintLimiter[msg.sender].mintedTotal = 0;
    }
    require(mintLimiter[msg.sender].mintedTotal.add(_amount) <= dailyMintLimit);
    _balances.addBalance(_to, _amount);
    _balances.addTotalSupply(_amount);
    mintLimiter[msg.sender].lastMintTimestamp = now;
    mintLimiter[msg.sender].mintedTotal = mintLimiter[msg.sender].mintedTotal.add(_amount);
    emit LimitMint(msg.sender, _to, _amount);
    emit Mint(_to, _amount);
    return true;
  }

  function setDailyMintLimit(uint256 _limit) onlyOwner public returns (bool) {
    dailyMintLimit = _limit;
    return true;
  }

  function setDailyBurnLimit(uint256 _limit) onlyOwner public returns (bool) {
    dailyBurnLimit = _limit;
    return true;
  }

   
  function mint(address _to, uint256 _amount)
  onlyOwner whenNotPaused onlyNotBlacklistedAddr(_to)
  public returns (bool success) {
    _balances.addBalance(_to, _amount);
    _balances.addTotalSupply(_amount);
    emit Mint(_to, _amount);
    return true;
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

 
 
 
contract V_test is ContractInterface, Pausable, Blacklistable {
  using SafeMath for uint256;

   
  uint8 public constant decimals = 18;
  uint256 constant maxBatch = 100;

  string public name;
  string public symbol;

  Balance internal _balances;
  Allowance internal _allowance;

  constructor(string _tokenName, string _tokenSymbol,
    Balance _balanceContract, Allowance _allowanceContract,
    Blacklist _blacklistContract
  ) Blacklistable(_blacklistContract) public {
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
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_to)
  public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }


   
  function batchTransfer(address[] _to, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddrs(_to)
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
  whenNotPaused onlyNotBlacklistedAddr(_from) onlyNotBlacklistedAddr(_to)
  public returns (bool) {
    require(_allowance.allowanceOf(_from, msg.sender) >= _value);      
    _allowance.subAllowance(_from, msg.sender, _value);
    _transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender)
  public returns (bool) {
    _allowance.setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(address _spender, uint256 _addedValue)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender)
  public returns (bool) {
    _allowance.addAllowance(msg.sender, _spender, _addedValue);
    emit Approval(msg.sender, _spender, _allowance.allowanceOf(msg.sender, _spender));
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue)
  whenNotPaused onlyNotBlacklistedAddr(msg.sender) onlyNotBlacklistedAddr(_spender)
  public returns (bool) {
    _allowance.subAllowance(msg.sender, _spender, _subtractedValue);
    emit Approval(msg.sender, _spender, _allowance.allowanceOf(msg.sender, _spender));
    return true;
  }

   
  function burn(uint256 _value) whenNotPaused onlyNotBlacklistedAddr(msg.sender)
  public returns (bool success) {
    require(_balances.balanceOf(msg.sender) >= _value);          
    _balances.subBalance(msg.sender, _value);                    
    _balances.subTotalSupply(_value);                            
    emit Burn(msg.sender, _value);
    return true;
  }

   
  function changeName(string _name, string _symbol) onlyOwner public {
    name = _name;
    symbol = _symbol;
  }
}