 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
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

 
contract ERC20 is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowed;

  uint256 internal _totalSupply;

  uint256 internal _totalHolders;

  uint256 internal _totalTransfers;

  uint256 internal _initialSupply;

  function initialSupply() public view returns (uint256) {
    return _initialSupply;
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function circulatingSupply() public view returns (uint256) {
    require(_totalSupply >= _balances[owner()]);
    return _totalSupply.sub(_balances[owner()]);
  }

   
  function totalHolders() public view returns (uint256) {
    return _totalHolders;
  }

   
  function totalTransfers() public view returns (uint256) {
    return _totalTransfers;
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    if (_balances[msg.sender] == 0 && _totalHolders > 0) {
      _totalHolders = _totalHolders.sub(1);
    }
    if (_balances[to] == 0) {
      _totalHolders = _totalHolders.add(1);
    }
    _balances[to] = _balances[to].add(value);
    _totalTransfers = _totalTransfers.add(1);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

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
    if (msg.sender == from) {
      return transfer(to, value);
    }

    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    if (_balances[from] == 0 && _totalHolders > 0) {
      _totalHolders = _totalHolders.sub(1);
    }
    if (_balances[to] == 0) {
      _totalHolders = _totalHolders.add(1);
    }

    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _totalTransfers = _totalTransfers.add(1);
    emit Transfer(from, to, value);
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

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    if (_balances[account] == 0) {
      _totalHolders = _totalHolders.add(1);
    }
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    if (_balances[account] == 0 && _totalHolders > 0) {
      _totalHolders = _totalHolders.sub(1);
    }
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

contract AgentRole is Ownable {
  using Roles for Roles.Role;

  event AgentAdded(address indexed account);
  event AgentRemoved(address indexed account);

  Roles.Role private agencies;

  constructor() public {
    agencies.add(msg.sender);
  }

  modifier onlyAgent() {
    require(isOwner() || isAgent(msg.sender));
    _;
  }

  function isAgent(address account) public view returns (bool) {
    return agencies.has(account);
  }

  function addAgent(address account) public onlyAgent {
    agencies.add(account);
    emit AgentAdded(account);
  }

  function renounceAgent() public onlyAgent {
    agencies.remove(msg.sender);
  }

  function _removeAgent(address account) internal {
    agencies.remove(account);
    emit AgentRemoved(account);
  }
}

 
contract ERC20Agentable is ERC20, AgentRole {

  function removeAgent(address account) public onlyAgent {
    _removeAgent(account);
  }

  function _removeAgent(address account) internal {
    super._removeAgent(account);
  }

  function transferProxy(
    address from,
    address to,
    uint256 value
  )
    public
    onlyAgent
    returns (bool)
  {
    if (msg.sender == from) {
      return transfer(to, value);
    }

    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    if (_balances[from] == 0 && _totalHolders > 0) {
      _totalHolders = _totalHolders.sub(1);
    }
    if (_balances[to] == 0) {
      _totalHolders = _totalHolders.add(1);
    }

    _balances[to] = _balances[to].add(value);
    _totalTransfers = _totalTransfers.add(1);
    emit Transfer(from, to, value);
    return true;
  }

  function approveProxy(
    address from,
    address spender,
    uint256 value
  )
    public
    onlyAgent
    returns (bool)
  {
    require(spender != address(0));

    _allowed[from][spender] = value;
    emit Approval(from, spender, value);
    return true;
  }

  function increaseAllowanceProxy(
    address from,
    address spender,
    uint addedValue
  )
    public
    onlyAgent
    returns (bool success)
  {
    require(spender != address(0));

    _allowed[from][spender] = (
      _allowed[from][spender].add(addedValue));
    emit Approval(from, spender, _allowed[from][spender]);
    return true;
  }

  function decreaseAllowanceProxy(
    address from,
    address spender,
    uint subtractedValue
  )
    public
    onlyAgent
    returns (bool success)
  {
    require(spender != address(0));

    _allowed[from][spender] = (
      _allowed[from][spender].sub(subtractedValue));
    emit Approval(from, spender, _allowed[from][spender]);
    return true;
  }
}

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }

   
  function _burn(address who, uint256 value) internal {
    super._burn(who, value);
  }
}

contract MinterRole is Ownable {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isOwner() || isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public onlyMinter {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 
contract ERC20Mintable is ERC20, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  function removeMinter(address account) public onlyMinter {
    _removeMinter(account);
  }

  function _removeMinter(address account) internal {
    super._removeMinter(account);
  }

   
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

   
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, amount);
    return true;
  }

   
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

contract PauserRole is Ownable {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    pausers.add(msg.sender);
  }

  modifier onlyPauser() {
    require(isOwner() || isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function renouncePauser() public onlyPauser {
    pausers.remove(msg.sender);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 
contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;


   
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
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

 
contract ERC20Pausable is ERC20, Pausable {

  function removePauser(address account) public onlyPauser {
    _removePauser(account);
  }

  function _removePauser(address account) internal {
    super._removePauser(account);
  }

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



 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
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

 
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
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

contract Token is ERC20Burnable, ERC20Mintable, ERC20Pausable, ERC20Agentable {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals, uint256 initialSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _initialSupply = initialSupply;
    _totalSupply = _initialSupply;
    _balances[msg.sender] = _initialSupply;
    emit Transfer(0x0, msg.sender, _initialSupply);
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

  function meta(address account) public view returns (string, string, uint8, uint256, uint256, uint256, uint256, uint256, uint256) {
    uint256 circulating = 0;
    if (_totalSupply > _balances[owner()]) {
      circulating = _totalSupply.sub(_balances[owner()]);
    }
    uint256 balance = 0;
    if (account != address(0)) {
      balance = _balances[account];
    } else if (msg.sender != address(0)) {
      balance = _balances[msg.sender];
    }
    return (_name, _symbol, _decimals, _initialSupply, _totalSupply, _totalTransfers, _totalHolders, circulating, balance);
  }

  function batchTransfer(address[] addresses, uint256[] tokenAmount) public returns (bool) {
    require(addresses.length > 0 && addresses.length == tokenAmount.length);
    for (uint i = 0; i < addresses.length; i++) {
        address _to = addresses[i];
        uint256 _value = tokenAmount[i];
        super.transfer(_to, _value);
    }
    return true;
  }

  function batchTransferFrom(address _from, address[] addresses, uint256[] tokenAmount) public returns (bool) {
    require(addresses.length > 0 && addresses.length == tokenAmount.length);
    for (uint i = 0; i < addresses.length; i++) {
        address _to = addresses[i];
        uint256 _value = tokenAmount[i];
        super.transferFrom(_from, _to, _value);
    }
    return true;
  }


}