 

pragma solidity ^0.5.2;

 
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

contract PauserRole {
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

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
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

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
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

contract MinterRole {
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

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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

 
contract MigrationAgent {

    function migrateFrom(address _from, uint256 _value) public;
}

 
 
contract Locked is Ownable {

    mapping (address => bool) public lockedList;

    event AddedLock(address user);
    event RemovedLock(address user);


     
     
     
    modifier isNotLocked(address _from, address _to) {

        if (_from != owner()) {   
            require(!lockedList[_from], "User is locked");
            require(!lockedList[_to], "User is locked");
        }
        _;
    }

     
     
     
    function isLocked(address _user) public view returns (bool) {
        return lockedList[_user];
    }
    
     
     
    function addLock (address _user) public onlyOwner {
        _addLock(_user);
    }

     
     
    function removeLock (address _user) public onlyOwner {
        _removeLock(_user);
    }


     
     
    function _addLock(address _user) internal {
        lockedList[_user] = true;
        emit AddedLock(_user);
    }

     
     
    function _removeLock (address _user) internal {
        lockedList[_user] = false;
        emit RemovedLock(_user);
    }

}

 
contract Token is Pausable, ERC20Detailed, Ownable, ERC20Burnable, MinterRole, Locked {

    uint8 constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 250000000 * (10 ** uint256(DECIMALS));
    uint256 public constant ONE_YEAR_SUPPLY = 12500000 * (10 ** uint256(DECIMALS));
    address initialAllocation = 0xd15F967c36870D8dA92208235770167DDbD66b42;
    address public migrationAgent;
    uint256 public totalMigrated;
    address public mintAgent;

    uint16 constant ORIGIN_YEAR = 1970;
    uint constant YEAR_IN_SECONDS = 31557600;   
                                                

    mapping (uint => bool) public mintedYears;

    event Migrate(address indexed from, address indexed to, uint256 value);
    event MintAgentSet(address indexed mintAgent);
    event MigrationAgentSet(address indexed migrationAgent);

     
     
    modifier notSelf(address _self) {
        require(_self != address(this), "You are trying to send tokens to token contract");
        _;
    }

     
    constructor () public ERC20Detailed("Auditchain", "AUDT", DECIMALS)  {
        _mint(initialAllocation, INITIAL_SUPPLY + ONE_YEAR_SUPPLY);
        mintedYears[returnYear()] = true;
    }
     
     
     
     
    function returnYear() internal view returns (uint) {

        uint year = ORIGIN_YEAR + (block.timestamp / YEAR_IN_SECONDS);
        return year;
    }

      
      
    function mint() public onlyMinter returns (bool) {

        require(mintAgent != address(0), "Mint agent address can't be 0");
        require (!mintedYears[returnYear()], "Tokens have been already minted for this year.");

        _mint(mintAgent, ONE_YEAR_SUPPLY);
        mintedYears[returnYear()] = true;

        return true;
    }

     
     
    function setMintContract(address _mintAgent) external onlyOwner() {

        require(_mintAgent != address(0), "Mint agent address can't be 0");
        mintAgent = _mintAgent;
        emit MintAgentSet(_mintAgent);
    }

     
    function migrate() external whenNotPaused() {

        uint value = balanceOf(msg.sender);
        require(migrationAgent != address(0), "Enter migration agent address");
        require(value > 0, "Amount of tokens is required");

        _addLock(msg.sender);
        burn(balanceOf(msg.sender));
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        _removeLock(msg.sender);
        emit Migrate(msg.sender, migrationAgent, value);
    }

     
     
    function setMigrationAgent(address _agent) external onlyOwner() {

        require(_agent != address(0), "Migration agent can't be 0");
        migrationAgent = _agent;
        emit MigrationAgentSet(_agent);
    }

     
    function transfer(address to, uint256 value) public
                                                    isNotLocked(msg.sender, to)
                                                    notSelf(to)
                                                    returns (bool) {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public
                                                                    isNotLocked(from, to)
                                                                    notSelf(to)
                                                                    returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
    function approve(address spender, uint256 value) public
                                                        isNotLocked(msg.sender, spender)
                                                        notSelf(spender)
                                                        returns (bool) {
        return super.approve(spender, value);
    }

     
    function increaseAllowance(address spender, uint addedValue) public
                                                                isNotLocked(msg.sender, spender)
                                                                notSelf(spender)
                                                                returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

     
    function decreaseAllowance(address spender, uint subtractedValue) public
                                                                        isNotLocked(msg.sender, spender)
                                                                        notSelf(spender)
                                                                        returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

}