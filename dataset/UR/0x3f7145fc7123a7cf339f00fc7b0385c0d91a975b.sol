 

 

pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

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

 

pragma solidity ^0.4.24;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

     
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
}

 

pragma solidity ^0.4.24;

 
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

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.4.24;


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage _role, address _addr) internal {
        _role.bearer[_addr] = true;
    }

     
    function remove(Role storage _role, address _addr) internal {
        _role.bearer[_addr] = false;
    }

     
    function check(Role storage _role, address _addr) internal view {
        require(has(_role, _addr));
    }

     
    function has(Role storage _role, address _addr) internal view returns (bool) {
        return _role.bearer[_addr];
    }
}

 

pragma solidity ^0.4.24;



 
contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

     
    function checkRole(address _operator, string _role)
        public
        view
    {
        roles[_role].check(_operator);
    }

     
    function hasRole(address _operator, string _role)
        public
        view
        returns (bool)
    {
        return roles[_role].has(_operator);
    }

     
    function addRole(address _operator, string _role) internal {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

     
    function removeRole(address _operator, string _role) internal {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

     
    modifier onlyRole(string _role) {
        checkRole(msg.sender, _role);
        _;
    }

}

 

pragma solidity ^0.4.24;



 
contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

     
    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

     
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

     
    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

     
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

     
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

     
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }
}

 

pragma solidity ^0.4.24;



contract Xcoin is ERC20Pausable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping (address => bool) private _frozenAccounts;

    Whitelist private _whitelistForBurn;
    Pausable private _pauseForAll;

    event FrozenFunds(address indexed target, bool frozen);
    event WhitelistForBurnChanged(address indexed oldAddress, address indexed newAddress);
    event TransferWithMessage(address from, address to, uint256 value, bytes message);

     
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint256 initialSupply,
        address tokenHolder,
        address owner,
        address whitelistForBurn,
        address pauseForAll
    )
    public
    {
        _transferOwnership(owner);

        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _whitelistForBurn = Whitelist(whitelistForBurn);
        _pauseForAll = Pausable(pauseForAll);

        uint256 initialSupplyWithDecimals = initialSupply.mul(10 ** uint256(_decimals));
        _mint(tokenHolder, initialSupplyWithDecimals);
    }

     
    modifier whenNotPausedForAll() {
        require(!_pauseForAll.paused(), "pausedForAll is paused");
        _;
    }

     
     
    function name() public view returns (string) {
        return _name;
    }

     
     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
     
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     
     
    function frozenAccounts(address target) public view returns (bool) {
        return _frozenAccounts[target];
    }

     
     
    function whitelistForBurn() public view returns (address) {
        return _whitelistForBurn;
    }

     
     
    function pauseForAll() public view returns (address) {
        return _pauseForAll;
    }

     
     
     
    function changeWhitelistForBurn(address newWhitelistForBurn) public onlyOwner {
        address oldWhitelist = _whitelistForBurn;
        _whitelistForBurn = Whitelist(newWhitelistForBurn);
        emit WhitelistForBurnChanged(oldWhitelist, newWhitelistForBurn);
    }

     
     
    function freeze(address[] targets) public onlyOwner {
        require(targets.length > 0, "the length of targets is 0");

        for (uint i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "targets has zero address.");
            _frozenAccounts[targets[i]] = true;
            emit FrozenFunds(targets[i], true);
        }
    }

     
     
    function unfreeze(address[] targets) public onlyOwner {
        require(targets.length > 0, "the length of targets is 0");

        for (uint i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "targets has zero address.");
            _frozenAccounts[targets[i]] = false;
            emit FrozenFunds(targets[i], false);
        }
    }

     
     
     
     
    function transfer(address to, uint256 value) public whenNotPaused whenNotPausedForAll returns (bool) {
        require(!frozenAccounts(msg.sender), "msg.sender address is frozen.");
        return super.transfer(to, value);
    }

     
     
     
     
     
    function transferWithMessage(
        address to,
        uint256 value,
        bytes message
    )
    public
    whenNotPaused
    whenNotPausedForAll
    returns (bool)
    {
        require(!_frozenAccounts[msg.sender], "msg.sender is frozen");
        emit TransferWithMessage(msg.sender, to, value, message);
        return super.transfer(to, value);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused whenNotPausedForAll returns (bool) {
        require(!frozenAccounts(from), "from address is frozen.");
        return super.transferFrom(from, to, value);
    }

     
     
     
     
     
     
     
    function approve(address spender, uint256 value) public whenNotPaused whenNotPausedForAll returns (bool) {
        return super.approve(spender, value);
    }

     
     
     
     
     
     
     
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused whenNotPausedForAll returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

     
     
     
     
     
     
     
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused whenNotPausedForAll returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

     
     
     
     
     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        super._mint(to, value);
        return true;
    }

     
    function burn(uint256 _value) public whenNotPaused whenNotPausedForAll {
        require(_whitelistForBurn.whitelist(msg.sender), "msg.sender is not added on whitelist");
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= _balances[_who]);
         
         

        _balances[_who] = _balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Transfer(_who, address(0), _value);
    }
}