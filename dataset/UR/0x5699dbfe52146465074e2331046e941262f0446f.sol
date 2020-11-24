 

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
    _transfer(msg.sender, to, value);
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

contract ReserveRightsToken is ERC20Pausable {
  string public name = "Reserve Rights";
  string public symbol = "RSR";
  uint8 public decimals = 18;

   
  mapping (address => bool) public reserveTeamMemberOrEarlyInvestor;
  event AccountLocked(address indexed lockedAccount);

   
  address[] previousAddresses = [
    0x8ad9c8ebe26eadab9251b8fc36cd06a1ec399a7f,
    0xb268c230720d16c69a61cbee24731e3b2a3330a1,
    0x082705fabf49bd30de8f0222821f6d940713b89d,
    0xc3aa4ced5dea58a3d1ca76e507515c79ca1e4436,
    0x66f25f036eb4463d8a45c6594a325f9e89baa6db,
    0x9e454fe7d8e087fcac4ec8c40562de781004477e,
    0x4fcc7ca22680aed155f981eeb13089383d624aa9,
    0x5a66650e5345d76eb8136ea1490cbcce1c08072e,
    0x698a10b5d0972bffea306ba5950bd74d2af3c7ca,
    0xdf437625216cca3d7148e18d09f4aab0d47c763b,
    0x24b4a6847ccb32972de40170c02fda121ddc6a30,
    0x8d29a24f91df381feb4ee7f05405d3fb888c643e,
    0x5a7350d95b9e644dcab4bc642707f43a361bf628,
    0xfc2e9a5cd1bb9b3953ffa7e6ddf0c0447eb95f11,
    0x3ac7a6c3a2ff08613b611485f795d07e785cbb95,
    0x47fc47cbcc5217740905e16c4c953b2f247369d2,
    0xd282337950ac6e936d0f0ebaaff1ffc3de79f3d5,
    0xde59cd3aa43a2bf863723662b31906660c7d12b6,
    0x5f84660cabb98f7b7764cd1ae2553442da91984e,
    0xefbaaf73fc22f70785515c1e2be3d5ba2fb8e9b0,
    0x63c5ffb388d83477a15eb940cfa23991ca0b30f0,
    0x14f018cce044f9d3fb1e1644db6f2fab70f6e3cb,
    0xbe30069d27a250f90c2ee5507bcaca5f868265f7,
    0xcfef27288bedcd587a1ed6e86a996c8c5b01d7c1,
    0x5f57bbccc7ffa4c46864b5ed999a271bc36bb0ce,
    0xbae85de9858375706dde5907c8c9c6ee22b19212,
    0x5cf4bbb0ff093f3c725abec32fba8f34e4e98af1,
    0xcb2d434bf72d3cd43d0c368493971183640ffe99,
    0x02fc8e99401b970c265480140721b28bb3af85ab,
    0xe7ad11517d7254f6a0758cee932bffa328002dd0,
    0x6b39195c164d693d3b6518b70d99877d4f7c87ef,
    0xc59119d8e4d129890036a108aed9d9fe94db1ba9,
    0xd28661e4c75d177d9c1f3c8b821902c1abd103a6,
    0xba385610025b1ea8091ae3e4a2e98913e2691ff7,
    0xcd74834b8f3f71d2e82c6240ae0291c563785356,
    0x657a127639b9e0ccccfbe795a8e394d5ca158526
  ];

  constructor() public {
    IERC20 previousToken = IERC20(0xc2646eda7c2d4bf131561141c1d5696c4f01eb53);

    address reservePrimaryWallet = 0xfa3bd0b2ac6e63f16d16d7e449418837a8a3ae27;
    _mint(reservePrimaryWallet, previousToken.balanceOf(reservePrimaryWallet));

    for (uint i = 0; i < previousAddresses.length; i++) {
      reserveTeamMemberOrEarlyInvestor[previousAddresses[i]] = true;
      _mint(previousAddresses[i], previousToken.balanceOf(previousAddresses[i]));
      emit AccountLocked(previousAddresses[i]);
    }
  }

  function transfer(address to, uint256 value) public returns (bool) {
     
    require(!reserveTeamMemberOrEarlyInvestor[msg.sender]);
    super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
     
    require(!reserveTeamMemberOrEarlyInvestor[from]);
    super.transferFrom(from, to, value);
  }

   
   
   
   
   
   
   
   
  function lockMyTokensForever(string consent) public returns (bool) {
    require(keccak256(abi.encodePacked(consent)) == keccak256(abi.encodePacked(
      "I understand that I am locking my account forever, or at least until the next token upgrade."
    )));
    reserveTeamMemberOrEarlyInvestor[msg.sender] = true;
    emit AccountLocked(msg.sender);
  }
}