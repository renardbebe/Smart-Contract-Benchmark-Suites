 

pragma solidity ^0.4.24;


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

  
  function isOwner() public view returns(bool) {
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

contract ERC20Mintable is ERC20, MinterRole {
  
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
}

contract JupiterCoin is ERC20, ERC20Detailed, ERC20Mintable, Ownable{

  constructor(
    string name,
    string symbol,
    uint8 decimals
  )
  public
  ERC20Mintable()
  ERC20Detailed(name, symbol, decimals)
  ERC20() {
  }

  
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    
    require(totalSupply() + value <= 100000000000000000000000000, "TOTAL_SUPPLY_EXCEEDED");
    return ERC20Mintable.mint(to, value);
  }

  
  struct PledgeRecord {
    address user;
    uint256 tokens;
  }

  
  mapping(string => PledgeRecord) private orderPledge;

  
  mapping(string => bool) orderIndex;

  
  event Pledge_Succeeded(
    address pledger,
    string order,
    uint256 tokens
  );

  
  event Refund_Succeeded(
    address pledger,
    string order
  );

  
  
  
  function pledge(string order, uint256 tokens) external {
    require(!isOwner(), "INVALID_MSG_SENDER");
    require(orderIndex[order] != true, "EXISTING_ORDER");
    require(balanceOf(msg.sender) >= tokens, "NOT_ENOUGH_BALANCE");
    require(transfer(owner(), tokens), "TRANSFER_FAILED");
    emit Pledge_Succeeded(msg.sender, order, tokens);
    orderPledge[order] = PledgeRecord(msg.sender, tokens);
    orderIndex[order] = true;
  }

  
  
  
  function refund(string order, uint256 tokens) external onlyOwner {
    require(orderIndex[order] == true, "INVALID_ORDER");

    PledgeRecord memory pledgeRecord = orderPledge[order];
    address user = pledgeRecord.user;
    uint256 amount = pledgeRecord.tokens;

    require((amount + amount) >= tokens, "NOT_CORRECT_PLEDGE");
    require(balanceOf(msg.sender) >= amount, "NOT_ENOUGH_TOKENS");
    require(transfer(user, amount), "TRANSFER_FAILED");
    emit Refund_Succeeded(user, order);
    delete orderPledge[order];
    delete orderIndex[order];
  }

  
  
  function isPledged(string order) public view returns (bool) {
    return orderIndex[order];
  }

  
  
  function pledgeRecord(string order) public view 
    returns (address pledger, uint256 tokens) {
    PledgeRecord memory p = orderPledge[order];
    return (p.user, p.tokens);
  }

  
  struct TokenOrder {
    address seller;
    address buyer;
    uint256 tokens;
  }

  
  mapping(uint32 => TokenOrder) private tokenOrder;

  
  mapping(uint32 => bool) private tokenOrderIndex; 

  
  event Transfer_Succeeded(
    uint32 tokenOrderId,
    address seller,
    address buyer,
    uint256 tokens
  );

  
  event Cancel_Succeeded(
    uint32 tokenOrderId,
    address seller
  );

  
  event Sell_Succeeded(
    uint32 tokenOrderId,
    address seller,
    address buyer
  );
  
  
  
  
  
  function transferForSale(uint32 tokenOrderId, address buyer, uint256 tokens) external {
    require(!isOwner(), "INVALID_ADDRESS");
    require(tokenOrderIndex[tokenOrderId] != true, "EXISTING_TOKEN_ORDER");
    require(balanceOf(msg.sender) >= tokens, "NOT_ENOUGH_BALANCE");

    require(transfer(owner(), tokens), "TRANSFER_FAILED");
    emit Transfer_Succeeded(tokenOrderId, msg.sender, buyer, tokens);
    tokenOrder[tokenOrderId] = TokenOrder(msg.sender, buyer, tokens);
    tokenOrderIndex[tokenOrderId] = true;
  }

  
  
  function cancelForUser(uint32 tokenOrderId) external onlyOwner {
    require(tokenOrderIndex[tokenOrderId] == true, "INVALID_TOKEN_ORDER");

    TokenOrder memory order = tokenOrder[tokenOrderId];
    uint256 amount = order.tokens;
    address seller = order.seller;
    
    require(balanceOf(msg.sender) >= amount, "NOT_ENOUGH_TOKENS");
    require(transfer(seller, amount), "TRANSFER_FAILED");
    emit Cancel_Succeeded(tokenOrderId, seller);
    delete tokenOrder[tokenOrderId];
    delete tokenOrderIndex[tokenOrderId];
  }

  
  
  function sellForUser(uint32 tokenOrderId) external onlyOwner {
    require(tokenOrderIndex[tokenOrderId] == true, "INVALID_TOKEN_ORDER");

    TokenOrder memory order = tokenOrder[tokenOrderId];
    uint256 amount = order.tokens;
    address seller = order.seller;
    address buyer = order.buyer;
    
    require(balanceOf(msg.sender) >= amount, "NOT_ENOUGH_TOKENS");
    require(transfer(buyer, amount), "TRANSFER_FAILED");
    emit Sell_Succeeded(tokenOrderId, seller, buyer);
    delete tokenOrder[tokenOrderId];
    delete tokenOrderIndex[tokenOrderId];
  }

  
  
  function isTransferred(uint32 tokenOrderId) public view returns (bool) {
    return tokenOrderIndex[tokenOrderId];
  }

  
  
  function tokenOrderInfo(uint32 tokenOrderId) public view 
    returns (address seller, address buyer, uint256 tokens) {
    TokenOrder memory t = tokenOrder[tokenOrderId];
    return (t.seller, t.buyer, t.tokens);
  }

}