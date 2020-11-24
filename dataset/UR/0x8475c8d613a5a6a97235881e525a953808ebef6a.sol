 

pragma solidity ^0.4.24;
 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }
   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));
    role.bearer[account] = true;
  }
   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));
    role.bearer[account] = false;
  }
   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
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
    require(isPauser(msg.sender));
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
contract CapperRole {
  using Roles for Roles.Role;
  event CapperAdded(address indexed account);
  event CapperRemoved(address indexed account);
  Roles.Role private cappers;
  constructor() internal {
    _addCapper(msg.sender);
  }
  modifier onlyCapper() {
    require(isCapper(msg.sender));
    _;
  }
  function isCapper(address account) public view returns (bool) {
    return cappers.has(account);
  }
  function addCapper(address account) public onlyCapper {
    _addCapper(account);
  }
  function renounceCapper() public {
    _removeCapper(msg.sender);
  }
  function _addCapper(address account) internal {
    cappers.add(account);
    emit CapperAdded(account);
  }
  function _removeCapper(address account) internal {
    cappers.remove(account);
    emit CapperRemoved(account);
  }
}
contract MinterRole {
  using Roles for Roles.Role;
  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);
  Roles.Role private minters;
  constructor() internal {
    _addMinter(msg.sender);
  }
  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }
  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }
  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }
  function renounceMinter() public {
    _removeMinter(msg.sender);
  }
  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }
  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}
 
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
    external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
    external returns (bool);
  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
contract ERC20 is IERC20, MinterRole {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping(address => bool) mastercardUsers;
  mapping(address => bool) SGCUsers;
  bool public walletLock;
  bool public publicLock;
  uint256 private _totalSupply;
   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
   
  function walletLock() public view returns (bool) {
    return walletLock;
  }
   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }
   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }
   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    value = SafeMath.mul(value,1 ether);
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    value = SafeMath.mul(value, 1 ether);
    
    require(value <= _allowed[from][msg.sender]);
    require(value <= _balances[from]);
    require(to != address(0));
    require(value > 0);
    require(!mastercardUsers[from]);
    require(!walletLock);
    
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    if(publicLock){
        require(
            SGCUsers[from]
            && SGCUsers[to]
        );
        _balances[from] = _balances[from].sub(value); 
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    else{
        _balances[from] = _balances[from].sub(value); 
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    return true;
  }
   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));
    addedValue = SafeMath.mul(addedValue, 1 ether);
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));
    subtractedValue = SafeMath.mul(subtractedValue, 1 ether);
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    require(value > 0);
    require(!mastercardUsers[from]);
    if(publicLock && !walletLock){
        require(
           SGCUsers[from]
            && SGCUsers[to]
        );
    }
    if(isMinter(from)){
          _addSGCUsers(to);
          _balances[from] = _balances[from].sub(value); 
          _balances[to] = _balances[to].add(value);
          emit Transfer(from, to, value);
    }
    else{
      require(!walletLock);
      _balances[from] = _balances[from].sub(value); 
      _balances[to] = _balances[to].add(value);
      emit Transfer(from, to, value);
    }
  }
   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
   
  function _burn(address account, uint256 value) internal {
    value = SafeMath.mul(value,1 ether);
    require(account != 0);
    require(value <= _balances[account]);
    
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
   
  function _burnFrom(address account, uint256 value) internal {
    value = SafeMath.mul(value,1 ether);
    require(value <= _allowed[account][msg.sender]);
    require(account != 0);
    require(value <= _balances[account]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
       
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
  function _addSGCUsers(address newAddress) onlyMinter public {
      if(!SGCUsers[newAddress]){
        SGCUsers[newAddress] = true;
      }
  }
  function getSGCUsers(address userAddress) public view returns (bool) {
    return SGCUsers[userAddress];
  }
}
 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }
   
  function name() public view returns(string) {
    return _name;
  }
   
  function symbol() public view returns(string) {
    return _symbol;
  }
   
  function decimals() public view returns(uint8) {
    return _decimals;
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
    require(!_paused);
    _;
  }
   
  modifier whenPaused() {
    require(_paused);
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
 
contract ERC20Burnable is ERC20, Pausable {
   
  function burn(uint256 value) public whenNotPaused{
    _burn(msg.sender, value);
  }
   
  function burnFrom(address from, uint256 value) public whenNotPaused {
    _burnFrom(from, value);
  }
}
 
contract ERC20Mintable is ERC20 {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
    function addMastercardUser(
    address user
  ) 
    public 
    onlyMinter 
  {
    mastercardUsers[user] = true;
  }
  function removeMastercardUser(
    address user
  ) 
    public 
    onlyMinter  
  {
    mastercardUsers[user] = false;
  }
  function updateWalletLock(
  ) 
    public 
    onlyMinter  
  {
    if(walletLock){
      walletLock = false;
    }
    else{
      walletLock = true;
    }
  }
    function updatePublicCheck(
  ) 
    public 
    onlyMinter  
  {
    if(publicLock){
      publicLock = false;
    }
    else{
      publicLock = true;
    }
  }
}
 
contract ERC20Capped is ERC20Mintable, CapperRole {
  uint256 internal _latestCap;
  constructor(uint256 cap)
    public
  {
    require(cap > 0);
    _latestCap = cap;
  }
   
  function cap() public view returns(uint256) {
    return _latestCap;
  }
  function _updateCap (uint256 addCap) public onlyCapper {
    addCap = SafeMath.mul(addCap, 1 ether);   
    _latestCap = addCap; 
  }
  function _mint(address account, uint256 value) internal {
    value = SafeMath.mul(value, 1 ether);
    require(totalSupply().add(value) <= _latestCap);
    super._mint(account, value);
  }
}
 
contract ERC20Pausable is ERC20, Pausable {
  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }
  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }
  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }
  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}
 
contract SecuredGoldCoin is ERC20, ERC20Mintable, ERC20Detailed, ERC20Burnable, ERC20Pausable, ERC20Capped {
    string public name =  "Secured Gold Coin";
    string public symbol = "SGC";
    uint8 public decimals = 18;
    uint public intialCap = 1000000000 * 1 ether;
    constructor () public 
        ERC20Detailed(name, symbol, decimals)
        ERC20Mintable()
        ERC20Burnable()
        ERC20Pausable()
        ERC20Capped(intialCap)
        ERC20()
    {}
}