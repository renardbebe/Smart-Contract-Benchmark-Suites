 

pragma solidity ^0.5.7;

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
    address public owner;
    address public newOwner;
    address public crowdOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }
    
    modifier onlyCrowdOwner()
    {
        require(msg.sender == crowdOwner);
        _;
    }
    
    function isOwner(address account) public view returns (bool) {
        if( account == owner ){
            return true;
        }
        else {
            return false;
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = address(0);
    }
    
    function transferCrowdOwner(address _newCrowdOwner) onlyOwner public {
        require(_newCrowdOwner != address(0));
        crowdOwner = _newCrowdOwner;
    }
}



contract PauserRole is Ownable{
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender)|| isOwner(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }
    
    function removePauser(address account) public onlyOwner {
        _removePauser(account);
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

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
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
    
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
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

contract MinterRole is Ownable{
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender) || isOwner(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    
    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
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

contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
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
}


contract TWOPercent is ERC20Detailed, ERC20Pausable, ERC20Mintable, ERC20Burnable  {
    uint256 public INITIAL_SUPPLY = 2500000000;

    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event FrozenAll(bool stop);
    event Burn(address indexed from, uint256 value);
    event LockEvent(address from, address to, uint256 startLock, uint256 endLock, uint256 value);
    event Aborted();
    
    struct lockForAddr {
        uint256 startLock;
        uint256 endLock;
    }

    mapping(address => uint256) balances_locked;
    mapping(address => lockForAddr) lockForAddrs;
    
    
    function setLockForAddr(address _address, uint256 _startLock, uint256 _endLock) onlyOwner public {
        lockForAddrs[_address] = lockForAddr(_startLock, _endLock);
    }
    
    function getLockForAddr(address _address)  public view returns (uint, uint) {
        lockForAddr storage _lockForAddr = lockForAddrs[_address];
        return (_lockForAddr.startLock, _lockForAddr.endLock);
    }
    
    function getLockStartForAddr(address _address)  public view returns (uint) {
        lockForAddr storage _lockForAddr = lockForAddrs[_address];
        return _lockForAddr.startLock;
    }
    
    function getLockEndForAddr(address _address)  public view returns (uint) {
        lockForAddr storage _lockForAddr = lockForAddrs[_address];
        return _lockForAddr.endLock;
    }
    
    

    constructor() ERC20Detailed("TWOPercent", "TPCT", 18) public  {
        
        _mint(msg.sender, 2500000000 * (10 ** 18));
    }
    

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0x0),"Receive address is 0x0");  
        require(balanceOf(_from) >= _value,"Not enaugh balance"); 
        require(!frozenAccount[_from],"_from addresss is frozen"); 
        require(!frozenAccount[_to],"_to addresss is frozen"); 


        if(_balances[_from] >= _value) {  
            _balances[_from] = _balances[_from].sub(_value);    
        } else if (getLockStartForAddr(_from) > 0) {   
            
            uint256 kstNow = now + 32400;

            require( kstNow < getLockStartForAddr(_from) || getLockEndForAddr(_from) < kstNow, "Token is locked");

        	uint256 shortfall = _value.sub(_balances[_from]);
            
            balances_locked[_from] = balances_locked[_from].sub(shortfall);
            _balances[_from] = 0;
                
        } else {
             
            require(false,"Not enough balance");
        }
        
        if(msg.sender == crowdOwner)  balances_locked[_to] = balances_locked[_to].add(_value);
        else _balances[_to] = _balances[_to].add(_value);
        
        
        emit Transfer(_from, _to, _value);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function balanceOfDef(address _owner) public view returns(uint256 balance) {
        return _balances[_owner];
    }
     
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return _balances[_owner].add(balances_locked[_owner]);
    }
    
    function balanceOfCrowd(address _owner) public view returns(uint256 balance) {
        return balances_locked[_owner];
    }
}