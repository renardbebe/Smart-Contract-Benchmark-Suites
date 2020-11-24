 
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
interface IProxy {
  function isDeployer(address _address) external view returns(bool);
}

interface IEntryPoint {
  function getProxyAddress() external view returns(address);
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
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() internal {
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

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) internal _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _allowed[from][msg.sender]);
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));
    require(value <= _balances[from]);
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }


   
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

}

contract MinterRole is Ownable {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor () internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyOwner {
    _addMinter(account);
  }

  function removeMinter(address account) public onlyOwner {
    _removeMinter(account);
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract PauserRole is Ownable {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private _pausers;

  constructor () internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return _pausers.has(account);
  }

  function addPauser(address account) public onlyOwner {
    _addPauser(account);
  }

  function removePauser(address account) public onlyOwner {
    _removePauser(account);
  }

  function _addPauser(address account) internal {
    _pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    _pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor () internal {
    _paused = false;
  }

   
  function paused() public view returns (bool) {
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
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    return super.approve(spender, value);
  }

  function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}


contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(address to, uint256 value) public onlyMinter returns (bool) {
    _mint(to, value);
    return true;
  }
}

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor (string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns (string memory) {
    return _name;
  }

   
  function symbol() public view returns (string memory) {
    return _symbol;
  }

   
  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

 
contract ERC20Capped is ERC20Mintable {
  uint256 private _cap;

  constructor (uint256 cap) public {
    require(cap > 0);
    _cap = cap;
  }

   
  function cap() public view returns (uint256) {
    return _cap;
  }

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
  }
}


 
contract AIV is ERC20Detailed, ERC20Capped, ERC20Pausable  {

  mapping(address => bool) private whiteList;
  IEntryPoint private EntryPoint;
  IProxy private Proxy;

  constructor(string memory name, string memory symbol, uint8 decimals, uint256 cap)
  ERC20Detailed(name, symbol, decimals) ERC20Capped(cap) public {}

  modifier canModifyWhiteList() {
    address proxyAddress = EntryPoint.getProxyAddress();
    Proxy = IProxy(proxyAddress);
    require(isOwner() || Proxy.isDeployer(msg.sender));
    _;
  }

  modifier onlyFromWhiteList() {
    require(whiteList[msg.sender] == true);
    _;
  }

  function setEntryPointAddress(address _EntryPointAddress) public onlyOwner {
    EntryPoint = IEntryPoint(_EntryPointAddress);
  }

  function addToWhiteList(address _address) public canModifyWhiteList {
    whiteList[_address] = true;
  }

  function removeFromWhiteList(address _address) public canModifyWhiteList {
    whiteList[_address] = false;
  }

   
  function approveFromProtocol(address sender, address spender, uint tokens) public onlyFromWhiteList returns (bool success) {
    require(balanceOf(sender) >= tokens);
    _approve(sender, spender, _allowed[sender][spender].add(tokens));
    return true;
  }


  function getTotalAmount(uint256[] memory values) internal pure returns(uint256) {
    uint256 total;
    for (uint8 i = 0; i < values.length; i++) {
      total += values[i];
    }
    return total;
  }

   
  function transferBatch(address[] memory addresses, uint256[] memory values) public {
    require((addresses.length != 0 && values.length != 0));
    require(addresses.length == values.length);
     
    require(getTotalAmount(values) <= balanceOf(msg.sender));
    for (uint8 j = 0; j < values.length; j++) {
      transfer(addresses[j], values[j]);
    }
  }
     
  function mintBatch(address[] memory addresses, uint256[] memory values) public onlyMinter {
    require((addresses.length != 0 && values.length != 0));
    require(addresses.length == values.length);
     
    uint256 value = getTotalAmount(values);
    require(totalSupply().add(value) <= cap());
    for (uint8 j = 0; j < values.length; j++) {
      mint(addresses[j], values[j]);
    }
  }
}