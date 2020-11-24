 

pragma solidity ^0.5.6;

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

contract IERC20Releasable {
    function release() public;
}

contract IOwnable {
    function isOwner(address who)
        public view returns(bool);

    function _isOwner(address)
        internal view returns(bool);
}

contract SingleOwner is IOwnable {
    address public owner;

    constructor(
        address _owner
    )
        internal
    {
        require(_owner != address(0), 'owner_req');
        owner = _owner;

        emit OwnershipTransferred(address(0), owner);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier ownerOnly() {
        require(msg.sender == owner, 'owner_access');
        _;
    }

    function _isOwner(address _sender)
        internal
        view
        returns(bool)
    {
        return owner == _sender;
    }

    function isOwner(address _sender)
        public
        view
        returns(bool)
    {
        return _isOwner(_sender);
    }

    function setOwner(address _owner)
        public
        ownerOnly
    {
        address prevOwner = owner;
        owner = _owner;

        emit OwnershipTransferred(owner, prevOwner);
    }
}

contract Privileged {
     
    mapping(address => bool) privileged;

    function isPrivileged(address _addr)
        public
        view
        returns(bool)
    {
        return privileged[_addr];
    }

    function _setPrivileged(address _addr)
        internal
    {
        require(_addr != address(0), 'addr_req');

        privileged[_addr] = true;
    }

    function _setUnprivileged(address _addr)
        internal
    {
        privileged[_addr] = false;
    }
}

contract IToken is IERC20, IERC20Releasable, IOwnable {}

contract MBN is IToken, ERC20, SingleOwner, Privileged {
    string public name = 'Membrana';
    string public symbol = 'MBN';
    uint8 public decimals = 18;
    bool public isReleased;
    uint public releaseDate;

    constructor(address _owner)
        public
        SingleOwner(_owner)
    {
        super._mint(owner, 1000000000 * 10 ** 18);
    }

     
    modifier releasedOnly() {
        require(isReleased, 'released_only');
        _;
    }

    modifier notReleasedOnly() {
        require(! isReleased, 'not_released_only');
        _;
    }

    modifier releasedOrPrivilegedOnly() {
        require(isReleased || isPrivileged(msg.sender), 'released_or_privileged_only');
        _;
    }

     

    function transfer(address to, uint256 value)
        public
        releasedOrPrivilegedOnly
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        releasedOnly
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        releasedOnly
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue)
        public
        releasedOnly
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue)
        public
        releasedOnly
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function release()
        public
        ownerOnly
        notReleasedOnly
    {
        isReleased = true;
        releaseDate = now;
    }

    function setPrivileged(address _addr)
        public
        ownerOnly
    {
        _setPrivileged(_addr);
    }

    function setUnprivileged(address _addr)
        public
        ownerOnly
    {
        _setUnprivileged(_addr);
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract InvestorVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

     
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

     
    VestingStage[6] public stages;

    event InvestorVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event InvestorVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    constructor() public {
        initVestingStages();
    }

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;

        require(tokensRemaining > 0, "All tokens claimed");

        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();

        if (tokensUnlockedPercentage >= 100) {
            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];
        } else {

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - tokensUnlockedPercentage)).div(100);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;
        }

    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit InvestorVestingUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit InvestorVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }

     
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }

        return allowedPercent;
    }

     
    function initVestingStages () internal {
        stages[0].date = 1563408000;
        stages[1].date = 1566086400;
        stages[2].date = 1568764800;
        stages[3].date = 1571356800;
        stages[4].date = 1574035200;
        stages[5].date = 1576627200;

        stages[0].tokensUnlockedPercentage = 39;
        stages[1].tokensUnlockedPercentage = 51;
        stages[2].tokensUnlockedPercentage = 63;
        stages[3].tokensUnlockedPercentage = 75;
        stages[4].tokensUnlockedPercentage = 87;
        stages[5].tokensUnlockedPercentage = 100;
    }
}

contract TeamAdvisorVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

     
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

     
    VestingStage[6] public stages;

    event TeamAdvisorInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event TeamAdvisorUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    constructor() public {
        initVestingStages();
    }

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        require(tokensRemaining > 0, "All tokens claimed");

        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();

        if (tokensUnlockedPercentage >= 100) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - tokensUnlockedPercentage)).div(100);

            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }


    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit TeamAdvisorUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit TeamAdvisorInitialized(_beneficiary, _tokens, _startTime);
        }
    }

     
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }

        return allowedPercent;
    }

     
    function initVestingStages () internal {
        stages[0].date = 1576627200;
        stages[1].date = 1579305600;
        stages[2].date = 1581984000;
        stages[3].date = 1584489600;
        stages[4].date = 1587168000;
        stages[5].date = 1589760000;

        stages[0].tokensUnlockedPercentage = 17;
        stages[1].tokensUnlockedPercentage = 34;
        stages[2].tokensUnlockedPercentage = 51;
        stages[3].tokensUnlockedPercentage = 68;
        stages[4].tokensUnlockedPercentage = 84;
        stages[5].tokensUnlockedPercentage = 100;
    }
}

contract Vesting is Ownable {
    using SafeMath for uint256;

    enum VestingUser { Public, Investor, TeamAdvisor }

    MBN public mbnContract;
    InvestorVesting public investorVesting;
    TeamAdvisorVesting public teamAdvisorVesting;

    mapping (address => VestingUser) public userCategory;
    mapping (address => uint256) public tokensVested;

    uint256 public totalAllocated;
    uint private releaseDate;

    event TokensReleased(address _to, uint256 _tokensReleased, VestingUser user);

    constructor(address _token) public {
        require(_token != address(0), "Invalid address");
        mbnContract = MBN(_token);
        releaseDate = mbnContract.releaseDate();
        investorVesting = new InvestorVesting();
        teamAdvisorVesting = new TeamAdvisorVesting();
    }

     
    function claimTokens() external {
        uint8 category = uint8(userCategory[msg.sender]);

        uint256 tokensToClaim;

        if (category == 1) {
            tokensToClaim = investorVesting.claimTokens(msg.sender);
        } else if (category == 2) {
            tokensToClaim = teamAdvisorVesting.claimTokens(msg.sender);
        } else {
            revert('incorrect category, maybe unknown user');
        }

        require(tokensToClaim > 0, "No tokens to claim");

        totalAllocated = totalAllocated.sub(tokensToClaim);
        require(mbnContract.transfer(msg.sender, tokensToClaim), 'Insufficient balance in vesting contract');
        emit TokensReleased(msg.sender, tokensToClaim, userCategory[msg.sender]);
    }

     
    function vestTokens(address[] calldata beneficiary, uint256[] calldata tokens, uint8[] calldata userType) external onlyOwner {
        require(beneficiary.length == tokens.length && tokens.length == userType.length, 'data mismatch');
        uint256 length = beneficiary.length;

        for(uint i = 0; i<length; i++) {
            require(beneficiary[i] != address(0), 'Invalid address');

            tokensVested[beneficiary[i]] = tokensVested[beneficiary[i]].add(tokens[i]);
            initializeVesting(beneficiary[i], tokens[i], releaseDate, Vesting.VestingUser(userType[i]));
        }
    }

     
    function claimUnallocated( address _sendTo) external onlyOwner{
        uint256 allTokens = mbnContract.balanceOf(address(this));
        uint256 tokensUnallocated = allTokens.sub(totalAllocated);
        mbnContract.transfer(_sendTo, tokensUnallocated);
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime,
        VestingUser user
    )
        internal
    {
        uint8 category = uint8(user);
        require(category != 0, 'Not eligible for vesting');
        require(uint8(userCategory[_beneficiary]) == 0 || userCategory[_beneficiary] == user, 'cannot change user category');

        userCategory[_beneficiary] = user;
        totalAllocated = totalAllocated.add(_tokens);

        if (category == 1) {
            investorVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else if (category == 2) {
            teamAdvisorVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else {
            revert('incorrect category, not eligible for vesting');
        }
    }

}