 

pragma solidity ^0.4.24;

 
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

 
library ERC20Lib {


   
   

   
  using SafeMath for uint256;
   


   
   

   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  event Approval(address indexed owner, address indexed spender, uint256 value);
   

   
   

   
  struct Token{
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;
    uint256 _totalSupply;
  }
   


   
   

   
  function totalSupply(Token storage self)
  internal
  view
  returns (uint256) {
    return self._totalSupply;
  }

   
  function balances(Token storage self, address account)
  internal
  view
  returns (uint256) {
    return self._balances[account];
  }

   
  function allowance(Token storage self, address account, address spender)
  internal
  view
  returns (uint256) {
    return self._allowed[account][spender];
  }

   
  function approve(Token storage self, address sender, address spender, uint256 value)
  internal {
    require(spender != address(0));
    self._allowed[sender][spender] = value;
    emit Approval(sender, spender, value);
  }

   
  function transferFrom(Token storage self, address sender, address from, address to, uint256 value)
  internal {
    require(value <= self._allowed[from][sender]);
    self._allowed[from][sender] = self._allowed[from][sender].sub(value);
    transfer(self,from, to, value);
  }

   
  function increaseAllowance(Token storage self, address sender, address spender, uint256 addedValue)
  internal {
    require(spender != address(0));
    self._allowed[sender][spender] = self._allowed[sender][spender].add(addedValue);
    emit Approval(sender, spender, self._allowed[sender][spender]);
  }

   
  function decreaseAllowance(Token storage self, address sender, address spender, uint256 subtractedValue)
  internal {
    require(spender != address(0));
    self._allowed[sender][spender] = self._allowed[sender][spender].sub(subtractedValue);
    emit Approval(sender, spender, self._allowed[sender][spender]);
  }

   
  function transfer(Token storage self, address sender, address to, uint256 value)
  internal {
    require(value <= self._balances[sender]);
    require(to != address(0));
    self._balances[sender] = self._balances[sender].sub(value);
    self._balances[to] = self._balances[to].add(value);
    emit Transfer(sender, to, value);
  }

   
  function mint(Token storage self, address account, uint256 value)
  internal {
    require(account != 0);
    self._totalSupply = self._totalSupply.add(value);
    self._balances[account] = self._balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function burn(Token storage self, address account, uint256 value)
  internal {
    require(account != 0);
    require(value <= self._balances[account]);
    self._totalSupply = self._totalSupply.sub(value);
    self._balances[account] = self._balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
   

}



contract HubCulture{

   
   
  using ERC20Lib for ERC20Lib.Token;
  using SafeMath for uint256;
   

   
   
  event Pending(address indexed account, uint256 indexed value, uint256 indexed nonce);
  event Deposit(address indexed account, uint256 indexed value, uint256 indexed nonce);
  event Withdraw(address indexed account, uint256 indexed value, uint256 indexed nonce);
  event Decline(address indexed account, uint256 indexed value, uint256 indexed nonce);
  event Registration(address indexed account, bytes32 indexed uuid, uint256 indexed nonce);
  event Unregistered(address indexed account, uint256 indexed nonce);
   

   
   
  mapping(address=>bool) authorities;
  mapping(address=>bool) registered;
  mapping(address=>bool) vaults;
  ERC20Lib.Token token;
  ERC20Lib.Token pending;
  uint256 eventNonce;
  address failsafe;
  address owner;
  bool paused;
   

   
   
  constructor(address _owner,address _failsafe)
  public {
    failsafe = _failsafe;
    owner = _owner;
  }
   

   
   
  modifier onlyFailsafe(){
    require(msg.sender == failsafe);
    _;
  }

  modifier onlyAdmin(){
    require(msg.sender == owner || msg.sender == failsafe);
    _;
  }

  modifier onlyAuthority(){
    require(authorities[msg.sender]);
    _;
  }

  modifier onlyVault(){
    require(vaults[msg.sender]);
    _;
  }

  modifier notPaused(){
    require(!paused);
    _;
  }
   

   
   
  function isFailsafe(address _failsafe)
  public
  view
  returns (bool){
    return (failsafe == _failsafe);
  }

  function setFailsafe(address _failsafe)
  public
  onlyFailsafe{
    failsafe = _failsafe;
  }
   

   
   
  function isOwner(address _owner)
  public
  view
  returns (bool){
    return (owner == _owner);
  }

  function setOwner(address _owner)
  public
  onlyAdmin{
    owner = _owner;
  }
   

   
   
  function isVault(address vault)
  public
  view
  returns (bool) {
    return vaults[vault];
  }

  function addVault(address vault)
  public
  onlyAdmin
  notPaused
  returns (bool) {
    vaults[vault] = true;
    return true;
  }

  function removeVault(address vault)
  public
  onlyAdmin
  returns (bool) {
    vaults[vault] = false;
    return true;
  }
   

   
   
  function isAuthority(address authority)
  public
  view
  returns (bool) {
    return authorities[authority];
  }

  function addAuthority(address authority)
  public
  onlyAdmin
  notPaused
  returns (bool) {
    authorities[authority] = true;
    return true;
  }

  function removeAuthority(address authority)
  public
  onlyAdmin
  returns (bool) {
    authorities[authority] = false;
    return true;
  }
   

   
   

   
  function isPaused()
  public
  view
  returns (bool) {
    return paused;
  }

   
  function pause()
  public
  onlyAdmin
  notPaused
  returns (bool) {
    paused = true;
    return true;
  }

   
  function unpause()
  public
  onlyFailsafe
  returns (bool) {
    paused = false;
    return true;
  }

   
  function lockForever()
  public
  onlyFailsafe
  returns (bool) {
    pause();
    setOwner(address(this));
    setFailsafe(address(this));
    return true;
  }
   

   
   

   
  function isBadDay()
  public
  view
  returns (bool) {
    return (isPaused() && (owner == failsafe));
  }
   

   
   

   
  function totalSupply()
  public
  view
  returns (uint256) {
    uint256 supply = 0;
    supply = supply.add(pending.totalSupply());
    supply = supply.add(token.totalSupply());
    return supply;
  }

  function pendingSupply()
  public
  view
  returns (uint256) {
    return pending.totalSupply();
  }

  function availableSupply()
  public
  view
  returns (uint256) {
    return token.totalSupply();
  }

  function balanceOf(address account)
  public
  view
  returns (uint256) {
    return token.balances(account);
  }

  function allowance(address account, address spender)
  public
  view
  returns (uint256) {
    return token.allowance(account,spender);
  }

  function transfer(address to, uint256 value)
  public
  notPaused
  returns (bool) {
    token.transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value)
  public
  notPaused
  returns (bool) {
    token.approve(msg.sender,spender,value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value)
  public
  notPaused
  returns (bool) {
    token.transferFrom(msg.sender,from,to,value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
  public
  notPaused
  returns (bool) {
    token.increaseAllowance(msg.sender,spender,addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
  public
  notPaused
  returns (bool) {
    token.decreaseAllowance(msg.sender,spender,subtractedValue);
    return true;
  }
   

   
   

   


   
  function deposit(address account, uint256 value)
  public
  notPaused
  onlyAuthority
  returns (bool) {
    pending.mint(account,value);
    eventNonce+=1;
    emit Pending(account,value,eventNonce);
    return true;
  }

   
  function releaseDeposit(address account, uint256 value)
  public
  notPaused
  onlyVault
  returns (bool) {
    pending.burn(account,value);
    token.mint(account,value);
    eventNonce+=1;
    emit Deposit(account,value,eventNonce);
    return true;
  }

   
  function revokeDeposit(address account, uint256 value)
  public
  notPaused
  onlyVault
  returns (bool) {
    pending.burn(account,value);
    eventNonce+=1;
    emit Decline(account,value,eventNonce);
    return true;
  }
   

   
   

   
  function withdraw(uint256 value)
  public
  notPaused
  returns (bool) {
    require(registered[msg.sender]);
    token.burn(msg.sender,value);
    eventNonce+=1;
    emit Withdraw(msg.sender,value,eventNonce);
    return true;
  }
   

   
   

   
  function isRegistered(address wallet)
  public
  view
  returns (bool) {
    return registered[wallet];
  }

   
  function register(bytes32 uuid, uint8 v, bytes32 r, bytes32 s)
  public
  notPaused
  returns (bool) {
    require(authorities[ecrecover(keccak256(abi.encodePacked(msg.sender,uuid)),v,r,s)]);
    registered[msg.sender]=true;
    eventNonce+=1;
    emit Registration(msg.sender, uuid, eventNonce);
    return true;
  }

   
  function unregister(address wallet)
  public
  notPaused
  onlyAuthority
  returns (bool) {
    registered[wallet] = false;
    eventNonce+=1;
    emit Unregistered(wallet, eventNonce);
    return true;
  }
   

}