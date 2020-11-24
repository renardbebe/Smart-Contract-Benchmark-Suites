 

pragma solidity ^0.5.0;

 
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

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract OwnableWhitelistAdminRole is Ownable, WhitelistAdminRole {
    function addWhitelistAdmin(address account) public onlyOwner {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }
}

contract Whitelist {
    event WhitelistCreated(address account);
    event WhitelistChange(address indexed account, bool allowed);

    constructor() public {
        emit WhitelistCreated(address(this));
    }

    function isWhitelisted(address account) public view returns (bool);
}

contract WhitelistImpl is Ownable, OwnableWhitelistAdminRole, Whitelist {
    mapping(address => bool) public whitelist;

    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }

    function addToWhitelist(address[] memory accounts) public onlyWhitelistAdmin {
        for(uint i = 0; i < accounts.length; i++) {
            _setWhitelisted(accounts[i], true);
        }
    }

    function removeFromWhitelist(address[] memory accounts) public onlyWhitelistAdmin {
        for(uint i = 0; i < accounts.length; i++) {
            _setWhitelisted(accounts[i], false);
        }
    }

    function setWhitelisted(address account, bool whitelisted) public onlyWhitelistAdmin {
        _setWhitelisted(account, whitelisted);
    }

    function _setWhitelisted(address account, bool whitelisted) internal {
        whitelist[account] = whitelisted;
        emit WhitelistChange(account, whitelisted);
    }
}

contract TransitSale is Ownable, WhitelistImpl {
    using SafeMath for uint256;

    struct PoolDescription {
         
        uint maxAmount;
         
        uint releasedAmount;
         
        uint releaseTime;
         
        ReleaseType releaseType;
    }

    enum ReleaseType { Fixed, Floating, Direct }

    event PoolCreatedEvent(string name, uint maxAmount, uint releaseTime, uint vestingInterval, uint value, ReleaseType releaseType);
    event TokenHolderCreatedEvent(string name, address holder, address beneficiary, uint amount);
    event ReleasedEvent(address beneficiary, uint amount);

    uint private constant DAY = 86400;
    uint private constant INTERVAL = 30 * DAY;
    uint private constant DEFAULT_EXCHANGE_LISTING_TIME = 1559347200; 

    ERC20Mintable public token;
    uint private exchangeListingTime;
    mapping(string => PoolDescription) private pools;
    mapping(address => uint) public released;
    mapping(address => uint) public totals;

    constructor(ERC20Mintable _token) public {
        token = _token;

        registerPool("Private", 516666650 * 10 ** 18, ReleaseType.Fixed);
        registerPool("IEO", 200000000 * 10 ** 18, ReleaseType.Direct);
        registerPool("Incentives", 108333350 * 10 ** 18, ReleaseType.Direct);
        registerPool("Team", 300000000 * 10 ** 18, ReleaseType.Fixed);
        registerPool("Reserve", 375000000 * 10 ** 18, ReleaseType.Fixed);
    }

    function registerPool(string memory _name, uint _maxAmount, ReleaseType _releaseType) internal {
        require(_maxAmount > 0, "maxAmount should be greater than 0");
        require(_releaseType != ReleaseType.Floating, "ReleaseType.Floating is not supported. use Pools instead");
        pools[_name] = PoolDescription(_maxAmount, 0, 0, _releaseType);
        emit PoolCreatedEvent(_name, _maxAmount, 0, INTERVAL, 20, _releaseType);
    }

    function createHolder(string memory _name, address _beneficiary, uint _amount) onlyOwner public {
        require(isWhitelisted(_beneficiary), "not whitelisted");

        PoolDescription storage pool = pools[_name];
        require(pool.maxAmount != 0, "pool is not defined");
        uint newReleasedAmount = _amount.add(pool.releasedAmount);
        require(newReleasedAmount <= pool.maxAmount, "pool is depleted");
        pool.releasedAmount = newReleasedAmount;
        if (pool.releaseType == ReleaseType.Direct) {
            require(token.mint(_beneficiary, _amount));
        } else {
            require(token.mint(address(this), _amount));
            totals[_beneficiary] = totals[_beneficiary].add(_amount);
            emit TokenHolderCreatedEvent(_name, address(this), _beneficiary, _amount);
        }
    }

    function getVestedAmountForAddress(address _beneficiary) view public returns (uint) {
        uint releaseTime = releaseTime();
        if (now < releaseTime) {
            return 0;
        }
        uint total = totals[_beneficiary];
        uint diff = now.sub(releaseTime);
        uint interval = 1 + diff / INTERVAL;
        if (interval >= 5) {
            return total;
        }
        return interval.mul(total).div(5);
    }

    function getVestedAmount() view public returns (uint) {
        return getVestedAmountForAddress(msg.sender);
    }

    function getTotalAmount() view public returns (uint) {
        return totals[msg.sender];
    }

    function getReleasedAmount() view public returns (uint) {
        return released[msg.sender];
    }

    function release() public {
        uint vested = getVestedAmountForAddress(msg.sender);
        uint amount = vested.sub(released[msg.sender]);
        require(amount > 0);
        released[msg.sender] = vested;
        require(token.transfer(msg.sender, amount));
        emit ReleasedEvent(msg.sender, amount);
    }

    function getTokensLeft(string memory _name) view public returns (uint) {
        PoolDescription storage pool = pools[_name];
        require(pool.maxAmount != 0, "pool is not defined");
        return pool.maxAmount.sub(pool.releasedAmount);
    }

    function setExchangeListingTime(uint _exchangeListingTime) onlyOwner public {
        require(exchangeListingTime == 0);
        exchangeListingTime = _exchangeListingTime;
    }

    function releaseTime() view public returns (uint) {
        uint listingTime;
        if (exchangeListingTime == 0) {
            listingTime = DEFAULT_EXCHANGE_LISTING_TIME;
        } else {
            listingTime = exchangeListingTime;
        }
        return listingTime.add(90 * DAY);
    }
}