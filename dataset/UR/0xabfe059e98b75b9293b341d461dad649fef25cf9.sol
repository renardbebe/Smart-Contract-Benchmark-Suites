 

pragma solidity ^0.5.7;

 
contract PasswordProtected {
    bytes32 private passwordHash;

     
    constructor (string memory password) internal {
        _setNewPassword(password);
    }

    function _setNewPassword(string memory password) private {
        passwordHash = keccak256(bytes(password));
    }

    function _isValidPassword(string memory password) internal view returns (bool ok) {
        return (bytes32(keccak256(bytes(password))) == passwordHash);
    }

     
    modifier onlyValidPassword(string memory password) {
        require(_isValidPassword(password), "access denied");
        _;
    }

     
    function _changePassword(string memory oldPassword, string memory newPassword) onlyValidPassword(oldPassword) internal returns (bool ok) {
        _setNewPassword(newPassword);
        return true;
    }
}


pragma solidity ^0.5.7;

contract Identity {
    mapping(address => string) private _names;

     
    function iAm(string memory shortName) public {
        _names[msg.sender] = shortName;
    }

     
    function whereAmI() public view returns (address yourAddress) {
        address myself = msg.sender;
        return myself;
    }

     
    function whoAmI() public view returns (string memory yourName) {
        return (_names[msg.sender]);
    }
}


pragma solidity ^0.5.2;

 
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


pragma solidity ^0.5.2;

 
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


pragma solidity ^0.5.2;


 
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


pragma solidity ^0.5.2;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


pragma solidity ^0.5.2;


 
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


pragma solidity ^0.5.2;

 
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


pragma solidity ^0.5.7;


 
contract PauserRole is Ownable {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "onlyPauser");
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

    function _addPauser(address account) private {
        require(account != address(0));
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) private {
        require(account != address(0));
        _pausers.remove(account);
        emit PauserRemoved(account);
    }


     
     
     

     
    function renounceOwnership() public onlyOwner {
        require(false, "forbidden");
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _removePauser(msg.sender);
        super.transferOwnership(newOwner);
        _addPauser(newOwner);
    }
}


pragma solidity ^0.5.2;


 
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


pragma solidity ^0.5.2;


 
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


pragma solidity ^0.5.7;


contract VerifiedAccount is ERC20, Ownable {

    mapping(address => bool) private _isRegistered;

    constructor () internal {
         
        registerAccount();
    }

    event AccountRegistered(address indexed account);

     
    function registerAccount() public returns (bool ok) {
        _isRegistered[msg.sender] = true;
        emit AccountRegistered(msg.sender);
        return true;
    }

    function isRegistered(address account) public view returns (bool ok) {
        return _isRegistered[account];
    }

    function _accountExists(address account) internal view returns (bool exists) {
        return account == msg.sender || _isRegistered[account];
    }

    modifier onlySafeAccount(address account) {
        require(_accountExists(account), "account not registered");
        _;
    }


     
     
     

    function safeTransfer(address to, uint256 value) public onlySafeAccount(to) returns (bool ok) {
        transfer(to, value);
        return true;
    }

    function safeApprove(address spender, uint256 value) public onlySafeAccount(spender) returns (bool ok) {
        approve(spender, value);
        return true;
    }

    function safeTransferFrom(address from, address to, uint256 value) public onlySafeAccount(to) returns (bool ok) {
        transferFrom(from, to, value);
        return true;
    }


     
     
     

     
    function transferOwnership(address newOwner) public onlySafeAccount(newOwner) onlyOwner {
        super.transferOwnership(newOwner);
    }
}


pragma solidity ^0.5.7;


 
contract GrantorRole is Ownable {
    bool private constant OWNER_UNIFORM_GRANTOR_FLAG = false;

    using Roles for Roles.Role;

    event GrantorAdded(address indexed account);
    event GrantorRemoved(address indexed account);

    Roles.Role private _grantors;
    mapping(address => bool) private _isUniformGrantor;

    constructor () internal {
        _addGrantor(msg.sender, OWNER_UNIFORM_GRANTOR_FLAG);
    }

    modifier onlyGrantor() {
        require(isGrantor(msg.sender), "onlyGrantor");
        _;
    }

    modifier onlyGrantorOrSelf(address account) {
        require(isGrantor(msg.sender) || msg.sender == account, "onlyGrantorOrSelf");
        _;
    }

    function isGrantor(address account) public view returns (bool) {
        return _grantors.has(account);
    }

    function addGrantor(address account, bool isUniformGrantor) public onlyOwner {
        _addGrantor(account, isUniformGrantor);
    }

    function removeGrantor(address account) public onlyOwner {
        _removeGrantor(account);
    }

    function _addGrantor(address account, bool isUniformGrantor) private {
        require(account != address(0));
        _grantors.add(account);
        _isUniformGrantor[account] = isUniformGrantor;
        emit GrantorAdded(account);
    }

    function _removeGrantor(address account) private {
        require(account != address(0));
        _grantors.remove(account);
        emit GrantorRemoved(account);
    }

    function isUniformGrantor(address account) public view returns (bool) {
        return isGrantor(account) && _isUniformGrantor[account];
    }

    modifier onlyUniformGrantor() {
        require(isUniformGrantor(msg.sender), "Only uniform grantor role can do this.");
         
        _;
    }


     
     
     

     
    function renounceOwnership() public onlyOwner {
        require(false, "forbidden");
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _removeGrantor(msg.sender);
        super.transferOwnership(newOwner);
        _addGrantor(newOwner, OWNER_UNIFORM_GRANTOR_FLAG);
    }
}


pragma solidity ^0.5.7;


interface IERC20Vestable {
    function getIntrinsicVestingSchedule(address grantHolder)
    external
    view
    returns (
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays
    );

    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) external returns (bool ok);

    function today() external view returns (uint32 dayNumber);

    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onDayOrToday
    )
    external
    view
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    );

    function vestingAsOf(uint32 onDayOrToday) external view returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    );

    function revokeGrant(address grantHolder, uint32 onDay) external returns (bool);


    event VestingScheduleCreated(
        address indexed vestingLocation,
        uint32 cliffDuration, uint32 indexed duration, uint32 interval,
        bool indexed isRevocable);

    event VestingTokensGranted(
        address indexed beneficiary,
        uint256 indexed vestingAmount,
        uint32 startDay,
        address vestingLocation,
        address indexed grantor);

    event GrantRevoked(address indexed grantHolder, uint32 indexed onDay);
}


pragma solidity ^0.5.7;


 
contract ERC20Vestable is ERC20, VerifiedAccount, GrantorRole, IERC20Vestable {
    using SafeMath for uint256;

     
     
    uint32 private constant THOUSAND_YEARS_DAYS = 365243;                    
    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;                  
    uint32 private constant JAN_1_2000_SECONDS = 946684800;                  
        bool isRevocable;            
        uint32 cliffDuration;        
        uint32 duration;             
        uint32 interval;             
    }

    struct tokenGrant {
        bool isActive;               
        bool wasRevoked;             
        uint32 startDay;             
        uint256 amount;              
        address vestingLocation;     
        address grantor;             
    }

    mapping(address => vestingSchedule) private _vestingSchedules;
    mapping(address => tokenGrant) private _tokenGrants;


     
     
     

     
    function _setVestingSchedule(
        address vestingLocation,
        uint32 cliffDuration, uint32 duration, uint32 interval,
        bool isRevocable) internal returns (bool ok) {

         
        require(
            duration > 0 && duration <= TEN_YEARS_DAYS
            && cliffDuration < duration
            && interval >= 1,
            "invalid vesting schedule"
        );

         
        require(
            duration % interval == 0 && cliffDuration % interval == 0,
            "invalid cliff/duration for interval"
        );

         
        _vestingSchedules[vestingLocation] = vestingSchedule(
            true ,
            isRevocable,
            cliffDuration, duration, interval
        );

         
        emit VestingScheduleCreated(
            vestingLocation,
            cliffDuration, duration, interval,
            isRevocable);
        return true;
    }

    function _hasVestingSchedule(address account) internal view returns (bool ok) {
        return _vestingSchedules[account].isValid;
    }

     
    function getIntrinsicVestingSchedule(address grantHolder)
    public
    view
    onlyGrantorOrSelf(grantHolder)
    returns (
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays
    )
    {
        return (
        _vestingSchedules[grantHolder].duration,
        _vestingSchedules[grantHolder].cliffDuration,
        _vestingSchedules[grantHolder].interval
        );
    }


     
     
     
     

     
    function _grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        address vestingLocation,
        address grantor
    )
    internal returns (bool ok)
    {
         
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

         
        require(
            vestingAmount <= totalAmount && vestingAmount > 0
            && startDay >= JAN_1_2000_DAYS && startDay < JAN_1_3000_DAYS,
            "invalid vesting params");

         
        require(_hasVestingSchedule(vestingLocation), "no such vesting schedule");

         
        _transfer(grantor, beneficiary, totalAmount);
         

         
        _tokenGrants[beneficiary] = tokenGrant(
            true ,
            false ,
            startDay,
            vestingAmount,
            vestingLocation,  
            grantor              
        );

         
        emit VestingTokensGranted(beneficiary, vestingAmount, startDay, vestingLocation, grantor);
        return true;
    }

     
    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) public onlyGrantor returns (bool ok) {
         
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

         
        _setVestingSchedule(beneficiary, cliffDuration, duration, interval, isRevocable);

         
        _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, beneficiary, msg.sender);

        return true;
    }

     
    function safeGrantVestingTokens(
        address beneficiary, uint256 totalAmount, uint256 vestingAmount,
        uint32 startDay, uint32 duration, uint32 cliffDuration, uint32 interval,
        bool isRevocable) public onlyGrantor onlySafeAccount(beneficiary) returns (bool ok) {

        return grantVestingTokens(
            beneficiary, totalAmount, vestingAmount,
            startDay, duration, cliffDuration, interval,
            isRevocable);
    }


     
     
     

     
    function today() public view returns (uint32 dayNumber) {
        return uint32(block.timestamp / SECONDS_PER_DAY);
    }

    function _effectiveDay(uint32 onDayOrToday) internal view returns (uint32 dayNumber) {
        return onDayOrToday == 0 ? today() : onDayOrToday;
    }

     
    function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday) internal view returns (uint256 amountNotVested) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint32 onDay = _effectiveDay(onDayOrToday);

         
        if (!grant.isActive || onDay < grant.startDay + vesting.cliffDuration)
        {
             
            return grant.amount;
        }
         
        else if (onDay >= grant.startDay + vesting.duration)
        {
             
            return uint256(0);
        }
         
        else
        {
             
            uint32 daysVested = onDay - grant.startDay;
             
            uint32 effectiveDaysVested = (daysVested / vesting.interval) * vesting.interval;

             
             
             
             
             
            uint256 vested = grant.amount.mul(effectiveDaysVested).div(vesting.duration);
            return grant.amount.sub(vested);
        }
    }

     
    function _getAvailableAmount(address grantHolder, uint32 onDay) internal view returns (uint256 amountAvailable) {
        uint256 totalTokens = balanceOf(grantHolder);
        uint256 vested = totalTokens.sub(_getNotVestedAmount(grantHolder, onDay));
        return vested;
    }

     
    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onDayOrToday
    )
    public
    view
    onlyGrantorOrSelf(grantHolder)
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    )
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onDayOrToday);
        uint256 grantAmount = grant.amount;

        return (
        grantAmount.sub(notVestedAmount),
        notVestedAmount,
        grantAmount,
        grant.startDay,
        vesting.duration,
        vesting.cliffDuration,
        vesting.interval,
        grant.isActive,
        grant.wasRevoked
        );
    }

     
    function vestingAsOf(uint32 onDayOrToday) public view returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    )
    {
        return vestingForAccountAsOf(msg.sender, onDayOrToday);
    }

     
    function _fundsAreAvailableOn(address account, uint256 amount, uint32 onDay) internal view returns (bool ok) {
        return (amount <= _getAvailableAmount(account, onDay));
    }

     
    modifier onlyIfFundsAvailableNow(address account, uint256 amount) {
         
        require(_fundsAreAvailableOn(account, amount, today()),
            balanceOf(account) < amount ? "insufficient funds" : "insufficient vested funds");
        _;
    }


     
     
     

     
    function revokeGrant(address grantHolder, uint32 onDay) public onlyGrantor returns (bool ok) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
        uint256 notVestedAmount;

         
        require(msg.sender == owner() || msg.sender == grant.grantor, "not allowed");
         
        require(grant.isActive, "no active vesting schedule");
         
        require(vesting.isRevocable, "irrevocable");
         
        require(onDay <= grant.startDay + vesting.duration, "no effect");
         
        require(onDay >= today(), "cannot revoke vested holdings");

        notVestedAmount = _getNotVestedAmount(grantHolder, onDay);

         
        _approve(grantHolder, grant.grantor, notVestedAmount);
         
        transferFrom(grantHolder, grant.grantor, notVestedAmount);
         

         
        _tokenGrants[grantHolder].wasRevoked = true;
        _tokenGrants[grantHolder].isActive = false;

        emit GrantRevoked(grantHolder, onDay);
         
        return true;
    }


     
     
     

     
    function transfer(address to, uint256 value) public onlyIfFundsAvailableNow(msg.sender, value) returns (bool ok) {
        return super.transfer(to, value);
    }

     
    function approve(address spender, uint256 value) public onlyIfFundsAvailableNow(msg.sender, value) returns (bool ok) {
        return super.approve(spender, value);
    }
}


pragma solidity ^0.5.7;


 
contract UniformTokenGrantor is ERC20Vestable {

    struct restrictions {
        bool isValid;
        uint32 minStartDay;         
        uint32 maxStartDay;         
        uint32 expirationDay;        
    }

    mapping(address => restrictions) private _restrictions;


     
     
     
     

    event GrantorRestrictionsSet(
        address indexed grantor,
        uint32 minStartDay,
        uint32 maxStartDay,
        uint32 expirationDay);

     
    function setRestrictions(
        address grantor,
        uint32 minStartDay,
        uint32 maxStartDay,
        uint32 expirationDay
    )
    public
    onlyOwner
    onlySafeAccount(grantor)
    returns (bool ok)
    {
        require(
            isUniformGrantor(grantor)
         && maxStartDay > minStartDay
         && expirationDay > today(), "invalid params");

         
        _restrictions[grantor] = restrictions(
            true ,
            minStartDay,
            maxStartDay,
            expirationDay
        );

         
        emit GrantorRestrictionsSet(grantor, minStartDay, maxStartDay, expirationDay);
        return true;
    }

     
    function setGrantorVestingSchedule(
        address grantor,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    )
    public
    onlyOwner
    onlySafeAccount(grantor)
    returns (bool ok)
    {
         
        require(isUniformGrantor(grantor), "uniform grantor only");
         
        require(!_hasVestingSchedule(grantor), "schedule already exists");

         
         
        _setVestingSchedule(grantor, cliffDuration, duration, interval, isRevocable);

        return true;
    }


     
     
     
     

    function isUniformGrantorWithSchedule(address account) internal view returns (bool ok) {
         
        return isUniformGrantor(account) && _hasVestingSchedule(account);
    }

    modifier onlyUniformGrantorWithSchedule(address account) {
        require(isUniformGrantorWithSchedule(account), "grantor account not ready");
        _;
    }

    modifier whenGrantorRestrictionsMet(uint32 startDay) {
        restrictions storage restriction = _restrictions[msg.sender];
        require(restriction.isValid, "set restrictions first");

        require(
            startDay >= restriction.minStartDay
            && startDay < restriction.maxStartDay, "startDay too early");

        require(today() < restriction.expirationDay, "grantor expired");
        _;
    }

     
    function grantUniformVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay
    )
    public
    onlyUniformGrantorWithSchedule(msg.sender)
    whenGrantorRestrictionsMet(startDay)
    returns (bool ok)
    {
         
         
        return _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, msg.sender, msg.sender);
    }

     
    function safeGrantUniformVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay
    )
    public
    onlyUniformGrantorWithSchedule(msg.sender)
    whenGrantorRestrictionsMet(startDay)
    onlySafeAccount(beneficiary)
    returns (bool ok)
    {
         
         
        return _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, msg.sender, msg.sender);
    }
}


pragma solidity ^0.5.7;


 
contract ProxyToken is PasswordProtected, Identity, ERC20, ERC20Pausable, ERC20Burnable, ERC20Detailed, UniformTokenGrantor {
    uint32 public constant VERSION = 5;

    uint8 private constant DECIMALS = 18;
    uint256 private constant TOKEN_WEI = 10 ** uint256(DECIMALS);

    uint256 private constant INITIAL_WHOLE_TOKENS = uint256(5 * (10 ** 9));
    uint256 private constant INITIAL_SUPPLY = uint256(INITIAL_WHOLE_TOKENS) * uint256(TOKEN_WEI);

     
    constructor (string memory defaultPassword) ERC20Detailed("MediaRich.io Dyncoin proxy token", "DYNP", DECIMALS) PasswordProtected(defaultPassword) public {
         
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    event DepositReceived(address indexed from, uint256 value);

     
    function() payable external {
         
        emit DepositReceived(msg.sender, msg.value);
    }

     
    function burn(uint256 value) onlyIfFundsAvailableNow(msg.sender, value) public {
         
        _burn(msg.sender, value);
    }

     
    function changePassword(string memory oldPassword, string memory newPassword) onlyOwner public returns (bool ok) {
        _changePassword(oldPassword, newPassword);
        return true;
    }

     
    function kill(string memory password) whenPaused onlyPauser onlyValidPassword(password) public returns (bool itsDeadJim) {
        require(isPauser(msg.sender), "onlyPauser");
        address payable payableOwner = address(uint160(owner()));
        selfdestruct(payableOwner);
        return true;
    }
}