 

pragma solidity ^0.4.24;

 

 
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

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
  }
}

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
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

 

 
library SafeERC20 {

  using SafeMath for uint256;

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
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private admins;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return admins.has(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        admins.remove(account);
        emit AdminRemoved(account);
    }
}

 

contract SpenderRole {
    using Roles for Roles.Role;

    event SpenderAdded(address indexed account);
    event SpenderRemoved(address indexed account);

    Roles.Role private spenders;

    modifier onlySpender() {
        require(isSpender(msg.sender));
        _;
    }

    function isSpender(address account) public view returns (bool) {
        return spenders.has(account);
    }

    function renounceSpender() public {
        _removeSpender(msg.sender);
    }

    function _addSpender(address account) internal {
        spenders.add(account);
        emit SpenderAdded(account);
    }

    function _removeSpender(address account) internal {
        spenders.remove(account);
        emit SpenderRemoved(account);
    }
}

 

contract RecipientRole {
    using Roles for Roles.Role;

    event RecipientAdded(address indexed account);
    event RecipientRemoved(address indexed account);

    Roles.Role private recipients;

    modifier onlyRecipient() {
        require(isRecipient(msg.sender));
        _;
    }

    function isRecipient(address account) public view returns (bool) {
        return recipients.has(account);
    }

    function renounceRecipient() public {
        _removeRecipient(msg.sender);
    }

    function _addRecipient(address account) internal {
        recipients.add(account);
        emit RecipientAdded(account);
    }

    function _removeRecipient(address account) internal {
        recipients.remove(account);
        emit RecipientRemoved(account);
    }
}

 

contract Fider is ERC20Detailed, ERC20Burnable, ERC20Capped, ERC20Pausable, AdminRole, SpenderRole, RecipientRole {
    using SafeERC20 for IERC20;

    address private root;

    modifier onlyRoot() {
        require(msg.sender == root, "This operation can only be performed by root account");
        _;
    }

    constructor(string name, string symbol, uint8 decimals, uint256 cap)
    ERC20Detailed(name, symbol, decimals) ERC20Capped(cap) ERC20Mintable()  ERC20() public {
         
         
        _removeMinter(msg.sender);

         
         
        _removePauser(msg.sender);

        root = msg.sender;
    }

     

     
    function transferRoot(address _newRoot) external onlyRoot {
        require(_newRoot != address(0));
        root = _newRoot;
    }

     
    function addMinter(address account) public onlyRoot {
        _addMinter(account);
    }

     
    function removeMinter(address account) external onlyRoot {
        _removeMinter(account);
    }

     
    function addPauser(address account) public onlyRoot {
        _addPauser(account);
    }

     
    function removePauser(address account) external onlyRoot {
        _removePauser(account);
    }

     
    function addAdmin(address account) external onlyRoot {
        _addAdmin(account);
    }

     
    function removeAdmin(address account) external onlyRoot {
        _removeAdmin(account);
    }

     
    function addSpender(address account) external onlyAdmin {
        _addSpender(account);
    }

     
    function removeSpender(address account) external onlyAdmin {
        _removeSpender(account);
    }

     
    function addRecipient(address account) external onlyAdmin {
        _addRecipient(account);
    }

     
    function removeRecipient(address account) external onlyAdmin {
        _removeRecipient(account);
    }

     

     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        require(isSpender(to), "To must be an authorized spender");
        return super.mint(to, value);
    }

     

     
    function burnFrom(address from, uint256 value) public onlyMinter {
        _burnFrom(from, value);
    }

     

     
    function transfer(address to, uint256 value) public onlySpender returns (bool) {
        require(isRecipient(to), "To must be an authorized recipient");
        return super.transfer(to, value);
    }

     
    function approve(address spender, uint256 value) public onlySpender returns (bool) {
        require(isSpender(spender) || isMinter(spender), "Spender must be an authorized spender or a minter");
        return super.approve(spender, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public onlySpender returns (bool) {
        require(isSpender(from), "From must be an authorized spender");
        require(isRecipient(to), "To must be an authorized recipient");
        return super.transferFrom(from, to, value);
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public onlySpender returns (bool) {
        require(isSpender(spender) || isMinter(spender), "Spender must be an authorized spender or a minter");
        return super.increaseAllowance(spender, addedValue);
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public onlySpender returns (bool) {
        require(isSpender(spender) || isMinter(spender), "Spender must be an authorized spender or a minter");
        return super.decreaseAllowance(spender, subtractedValue);
    }

     

     
    function() external {
    }

     
    function reclaimEther() external onlyRoot {
        root.transfer(address(this).balance);
    }

     
    function reclaimERC20Token(IERC20 _token) external onlyRoot {
        uint256 balance = _token.balanceOf(this);
        _token.safeTransfer(root, balance);
    }
}