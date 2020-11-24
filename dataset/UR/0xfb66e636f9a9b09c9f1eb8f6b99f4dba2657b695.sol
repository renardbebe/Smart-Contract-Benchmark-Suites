 

pragma solidity ^0.4.25;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
    require(_b > 0);
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

 

 
contract Ownable {

   
  address private _owner;

   
  event OwnershipTransferred(address previousOwner, address newOwner);

   
  constructor() public {
    setOwner(msg.sender);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

 

 
contract Blacklistable is Ownable {

  address public blacklister;
  mapping(address => bool) internal blacklisted;

  event Blacklisted(address indexed _account);
  event UnBlacklisted(address indexed _account);
  event BlacklisterChanged(address indexed newBlacklister);

   
  modifier onlyBlacklister() {
    require(msg.sender == blacklister);
    _;
  }

   
  modifier notBlacklisted(address _account) {
    require(blacklisted[_account] == false);
    _;
  }

   
  function isBlacklisted(address _account) public view returns (bool) {
    return blacklisted[_account];
  }

   
  function blacklist(address _account) public onlyBlacklister {
    blacklisted[_account] = true;
    emit Blacklisted(_account);
  }

   
  function unBlacklist(address _account) public onlyBlacklister {
    blacklisted[_account] = false;
    emit UnBlacklisted(_account);
  }

  function updateBlacklister(address _newBlacklister) public onlyOwner {
    require(_newBlacklister != address(0));
    blacklister = _newBlacklister;
    emit BlacklisterChanged(blacklister);
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauserChanged(address indexed newAddress);


  address public pauser;
  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier onlyPauser() {
    require(msg.sender == pauser);
    _;
  }

   
  function pause() public onlyPauser {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyPauser {
    paused = false;
    emit Unpause();
  }

   
  function updatePauser(address _newPauser) public onlyOwner {
    require(_newPauser != address(0));
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

 

contract DelegateContract is Ownable {
  address delegate_;

  event LogicContractChanged(address indexed newAddress);

   
  modifier onlyFromAccept() {
    require(msg.sender == delegate_);
    _;
  }

  function setLogicContractAddress(address _addr) public onlyOwner {
    delegate_ = _addr;
    emit LogicContractChanged(_addr);
  }

  function isDelegate(address _addr) public view returns(bool) {
    return _addr == delegate_;
  }
}

 

 
contract AllowanceSheet is DelegateContract {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowanceOf;

  function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccept {
    allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
  }

  function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccept {
    allowanceOf[_tokenHolder][_spender] = _value;
  }
}

 

 
contract BalanceSheet is DelegateContract, AllowanceSheet {
  using SafeMath for uint256;

  uint256 internal totalSupply_ = 0;

  mapping (address => uint256) public balanceOf;

  function addBalance(address _addr, uint256 _value) public onlyFromAccept {
    balanceOf[_addr] = balanceOf[_addr].add(_value);
  }

  function subBalance(address _addr, uint256 _value) public onlyFromAccept {
    balanceOf[_addr] = balanceOf[_addr].sub(_value);
  }

  function increaseSupply(uint256 _amount) public onlyFromAccept {
    totalSupply_ = totalSupply_.add(_amount);
  }

  function decreaseSupply(uint256 _amount) public onlyFromAccept {
    totalSupply_ = totalSupply_.sub(_amount);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
}

 

 
contract MarsTokenV1 is Ownable, ERC20, Pausable, Blacklistable {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  string public currency;
  address public masterMinter;

   
   
   
  mapping(address => bool) internal minters;
  mapping(address => uint256) internal minterAllowed;

  event Mint(address indexed minter, address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 amount);
  event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
  event MinterRemoved(address indexed oldMinter);
  event MasterMinterChanged(address indexed newMasterMinter);
  event DestroyedBlackFunds(address indexed _account, uint256 _balance);

  BalanceSheet public balances;
  event BalanceSheetSet(address indexed sheet);

   
  function setBalanceSheet(address _sheet) public onlyOwner returns (bool) {
    balances = BalanceSheet(_sheet);
    emit BalanceSheetSet(_sheet);
    return true;
  }

  constructor(
    string _name,
    string _symbol,
    string _currency,
    uint8 _decimals,
    address _masterMinter,
    address _pauser,
    address _blacklister
  ) public {
    require(_masterMinter != address(0));
    require(_pauser != address(0));
    require(_blacklister != address(0));

    name = _name;
    symbol = _symbol;
    currency = _currency;
    decimals = _decimals;
    masterMinter = _masterMinter;
    pauser = _pauser;
    blacklister = _blacklister;
    setOwner(msg.sender);
  }

   
  modifier onlyMinters() {
    require(minters[msg.sender] == true);
    _;
  }

   
  function mint(address _to, uint256 _amount) public whenNotPaused onlyMinters notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
    require(_to != address(0));
    require(_amount > 0);

    uint256 mintingAllowedAmount = minterAllowed[msg.sender];
    require(_amount <= mintingAllowedAmount);

     
    balances.increaseSupply(_amount);
     
    balances.addBalance(_to, _amount);
    minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
    emit Mint(msg.sender, _to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

   
  modifier onlyMasterMinter() {
    require(msg.sender == masterMinter);
    _;
  }

   
  function minterAllowance(address minter) public view returns (uint256) {
    return minterAllowed[minter];
  }

   
  function isMinter(address account) public view returns (bool) {
    return minters[account];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
     
    return balances.allowanceOf(owner,spender);
  }

   
  function totalSupply() public view returns (uint256) {
    return balances.totalSupply();
  }

   
  function balanceOf(address account) public view returns (uint256) {
     
    return balances.balanceOf(account);
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool) {
    require(_spender != address(0));
     
    balances.setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notBlacklisted(_to) notBlacklisted(msg.sender) notBlacklisted(_from) returns (bool) {
    require(_to != address(0));
    require(_value <= balances.balanceOf(_from));
    require(_value <= balances.allowanceOf(_from, msg.sender));

     
    balances.subAllowance(_from, msg.sender, _value);
     
    balances.subBalance(_from, _value);
     
    balances.addBalance(_to, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
    require(_to != address(0));
    require(_value <= balances.balanceOf(msg.sender));

     
    balances.subBalance(msg.sender, _value);
     
    balances.addBalance(_to, _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function configureMinter(address minter, uint256 minterAllowedAmount) public whenNotPaused onlyMasterMinter notBlacklisted(minter) returns (bool) {
    minters[minter] = true;
    minterAllowed[minter] = minterAllowedAmount;
    emit MinterConfigured(minter, minterAllowedAmount);
    return true;
  }

   
  function removeMinter(address minter) public onlyMasterMinter returns (bool) {
    minters[minter] = false;
    minterAllowed[minter] = 0;
    emit MinterRemoved(minter);
    return true;
  }

   
  function burn(uint256 _amount) public whenNotPaused onlyMinters notBlacklisted(msg.sender) {
    uint256 balance = balances.balanceOf(msg.sender);
    require(_amount > 0);
    require(balance >= _amount);

     
    balances.decreaseSupply(_amount);
     
    balances.subBalance(msg.sender, _amount);
    emit Burn(msg.sender, _amount);
    emit Transfer(msg.sender, address(0), _amount);
  }

  function updateMasterMinter(address _newMasterMinter) public onlyOwner {
    require(_newMasterMinter != address(0));
    masterMinter = _newMasterMinter;
    emit MasterMinterChanged(masterMinter);
  }

   
  function destroyBlackFunds(address _account) public onlyOwner {
    require(blacklisted[_account]);
    uint256 _balance = balances.balanceOf(_account);
    balances.subBalance(_account, _balance);
    balances.decreaseSupply(_balance);
    emit DestroyedBlackFunds(_account, _balance);
    emit Transfer(_account, address(0), _balance);
  }

}