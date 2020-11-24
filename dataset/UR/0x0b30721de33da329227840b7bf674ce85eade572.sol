 

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
 
contract ERC20 is IERC20 {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  uint256 private _totalSupply;
   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
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
     value = value.mul(1 finney);
    _transfer(msg.sender, to, value);
    return true;
  }
   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    value = value.mul(1 finney);
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
     value = value.mul(1 finney);
    require(value <= _allowed[from][msg.sender]);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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
    addedValue = addedValue.mul(1 finney);
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
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
    subtractedValue = subtractedValue.mul(1 finney);
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
   
  function _transfer(address from, address to, uint256 value) internal {
   
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }
   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
   
  function _burn(address account, uint256 value) internal {
    
    require(account != 0);
    require(value <= _balances[account]);
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
   
  function _burnFrom(address account, uint256 value) internal {
  
    require(value <= _allowed[account][msg.sender]);
     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
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
 
contract ERC20Mintable is ERC20, MinterRole, ERC20Pausable {
   
  function mint(address to, uint256 value) internal whenNotPaused returns (bool)
  {
    _mint(to, value);
    return true;
  }
   function MinterFunc(address to, uint256 value) internal onlyMinter whenNotPaused returns (bool)
  {
    _mint(to, value);
    return true;
  }
}
 
contract ERC20Capped is ERC20Mintable {
  uint256 private _cap;
  constructor(uint256 cap)
    public
  {
    require(cap > 0);
    _cap = cap;
  }
   
  function cap() public view returns(uint256) {
    return _cap;
  }
  function Mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super.mint(account, value);
  }
  function MinterFunction(address account, uint256 value) public {
    value = value.mul(1 finney);
    require(totalSupply().add(value) <= _cap);
    super.MinterFunc(account, value);
  }
}
 
contract ERC20Burnable is ERC20, ERC20Pausable {
   
  function burn(uint256 value) public whenNotPaused {
    value = value.mul(1 finney);
    _burn(msg.sender, value);
  }
   
  function burnFrom(address from, uint256 value) public whenNotPaused {
    value = value.mul(1 finney);
    _burnFrom(from, value);
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
    require(isOwner());
    _;
  }
   
  function isOwner() private view returns(bool) {
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
 
contract ReentrancyGuard {
   
  uint256 private _guardCounter;
  constructor() internal {
     
     
    _guardCounter = 1;
  }
   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }
}
contract DncToken is ERC20, ERC20Detailed , ERC20Pausable, ERC20Capped , ERC20Burnable, Ownable , ReentrancyGuard {
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _cap) 
        ERC20Detailed(_name, _symbol, _decimals)
        ERC20Capped (_cap * 1 finney)
        public {
    }
    uint256 public _rate=100;
    uint256 private _weiRaised;
    address private _wallet = 0x6Dbea03201fF3c0143f22a8E629A36F2DFF82687;
    event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
    );
    function () external payable {
        buyTokens(msg.sender);
    }
    function ChangeRate(uint256 newRate) public onlyOwner whenNotPaused{
        _rate = newRate;
    }
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
         
        uint256 tokens = _getTokenAmount(weiAmount);
         
        _weiRaised = _weiRaised.add(weiAmount);
        _preValidatePurchase(beneficiary, weiAmount);
        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );
     
        _forwardFunds();
    
    }
    function _preValidatePurchase (
        address beneficiary,
        uint256 weiAmount
    )
    internal 
    pure 
    
    {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount
    )
    internal
    {
        _deliverTokens(beneficiary, tokenAmount);
    }
    function _deliverTokens (
        address beneficiary,
        uint256 tokenAmount
    )
    internal
    {
        Mint(beneficiary, tokenAmount);
    }
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}