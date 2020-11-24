 

pragma solidity ^0.5.0;


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


 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}


contract Whitelisting is Ownable {
    mapping(address => bool) public isInvestorApproved;
    mapping(address => bool) public isInvestorPaymentApproved;

    event Approved(address indexed investor);
    event Disapproved(address indexed investor);

    event PaymentApproved(address indexed investor);
    event PaymentDisapproved(address indexed investor);


     
    function approveInvestor(address toApprove) public onlyOwner {
        isInvestorApproved[toApprove] = true;
        emit Approved(toApprove);
    }

    function approveInvestorsInBulk(address[] calldata toApprove) external onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorApproved[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

    function disapproveInvestor(address toDisapprove) public onlyOwner {
        delete isInvestorApproved[toDisapprove];
        emit Disapproved(toDisapprove);
    }

    function disapproveInvestorsInBulk(address[] calldata toDisapprove) external onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorApproved[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }

     
    function approveInvestorPayment(address toApprove) public onlyOwner {
        isInvestorPaymentApproved[toApprove] = true;
        emit PaymentApproved(toApprove);
    }

    function approveInvestorsPaymentInBulk(address[] calldata toApprove) external onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorPaymentApproved[toApprove[i]] = true;
            emit PaymentApproved(toApprove[i]);
        }
    }

    function disapproveInvestorapproveInvestorPayment(address toDisapprove) public onlyOwner {
        delete isInvestorPaymentApproved[toDisapprove];
        emit PaymentDisapproved(toDisapprove);
    }

    function disapproveInvestorsPaymentInBulk(address[] calldata toDisapprove) external onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorPaymentApproved[toDisapprove[i]];
            emit PaymentDisapproved(toDisapprove[i]);
        }
    }

}


contract CommunityVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    uint256 constant public MinimumHoldingPeriod = 90 days;
    uint256 constant public Interval = 90 days;
    uint256 constant public MaximumHoldingPeriod = 360 days;

    uint256 constant public CommunityCap = 14300000 ether;  

    uint256 public totalCommunityTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    event CommunityVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event CommunityVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        require(now.sub(startTime) > MinimumHoldingPeriod, "Claiming period not started yet");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 percentage = calculatePercentageToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - percentage)).div(100);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePercentageToRelease(uint256 _startTime) internal view returns (uint256 percentage) {
         
        uint periodsPassed = ((now.sub(_startTime)).div(Interval));
        percentage = periodsPassed.mul(25);  
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        totalCommunityTokensCommitted = totalCommunityTokensCommitted.add(_tokens);
        require(totalCommunityTokensCommitted <= CommunityCap);

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit CommunityVestingUpdated(
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

            emit CommunityVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }
}



contract EcosystemVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    uint256 constant public Interval = 90 days;
    uint256 constant public MaximumHoldingPeriod = 630 days;

    uint256 constant public EcosystemCap = 54100000 ether;  

    uint256 public totalEcosystemTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    event EcosystemVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event EcosystemVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 permill = calculatePermillToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(1000 - permill)).div(1000);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePermillToRelease(uint256 _startTime) internal view returns (uint256 permill) {
         
        uint periodsPassed = ((now.sub(_startTime)).div(Interval)).add(1);
        permill = periodsPassed.mul(125);  
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        totalEcosystemTokensCommitted = totalEcosystemTokensCommitted.add(_tokens);
        require(totalEcosystemTokensCommitted <= EcosystemCap);

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit EcosystemVestingUpdated(
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

            emit EcosystemVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }
}



contract SeedPrivateAdvisorVesting is Ownable {
    using SafeMath for uint256;

    enum User { Public, Seed, Private, Advisor }

    mapping (address => Holding) public holdings;

    uint256 constant public MinimumHoldingPeriod = 90 days;
    uint256 constant public Interval = 30 days;
    uint256 constant public MaximumHoldingPeriod = 180 days;

    uint256 constant public SeedCap = 28000000 ether;  
    uint256 constant public PrivateCap = 9000000 ether;  
    uint256 constant public AdvisorCap = 7400000 ether;  

    uint256 public totalSeedTokensCommitted;
    uint256 public totalPrivateTokensCommitted;
    uint256 public totalAdvisorTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
        User user;
    }

    event VestingInitialized(address _to, uint256 _tokens, uint256 _startTime, User user);
    event VestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime, User user);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        require(now.sub(startTime) > MinimumHoldingPeriod, "Claiming period not started yet");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 percentage = calculatePercentageToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - percentage)).div(100);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePercentageToRelease(uint256 _startTime) internal view returns (uint256 percentage) {
         
        uint periodsPassed = ((now.sub(_startTime.add(MinimumHoldingPeriod))).div(Interval)).add(1);
        percentage = periodsPassed.mul(25);  
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime,
        uint8 user
    )
        external
        onlyOwner
    {
        User _user;
        if (user == uint8(User.Seed)) {
            _user = User.Seed;
            totalSeedTokensCommitted = totalSeedTokensCommitted.add(_tokens);
            require(totalSeedTokensCommitted <= SeedCap);
        } else if (user == uint8(User.Private)) {
            _user = User.Private;
            totalPrivateTokensCommitted = totalPrivateTokensCommitted.add(_tokens);
            require(totalPrivateTokensCommitted <= PrivateCap);
        } else if (user == uint8(User.Advisor)) {
            _user = User.Advisor;
            totalAdvisorTokensCommitted = totalAdvisorTokensCommitted.add(_tokens);
            require(totalAdvisorTokensCommitted <= AdvisorCap);
        } else {
            revert( "incorrect category, not eligible for vesting" );
        }

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit VestingUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime,
                holdings[_beneficiary].user
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime,
                _user
            );

            emit VestingInitialized(_beneficiary, _tokens, _startTime, _user);
        }
    }
}


contract TeamVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    uint256 constant public MinimumHoldingPeriod = 180 days;
    uint256 constant public Interval = 180 days;
    uint256 constant public MaximumHoldingPeriod = 720 days;

    uint256 constant public TeamCap = 12200000 ether;  

    uint256 public totalTeamTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    event TeamVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event TeamVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        require(now.sub(startTime) > MinimumHoldingPeriod, "Claiming period not started yet");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 percentage = calculatePercentageToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - percentage)).div(100);

            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePercentageToRelease(uint256 _startTime) internal view returns (uint256 percentage) {
         
        uint periodsPassed = ((now.sub(_startTime)).div(Interval));
        percentage = periodsPassed.mul(25);  
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        totalTeamTokensCommitted = totalTeamTokensCommitted.add(_tokens);
        require(totalTeamTokensCommitted <= TeamCap);

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit TeamVestingUpdated(
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

            emit TeamVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }
}



interface TokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Vesting is Ownable {
    using SafeMath for uint256;

    enum VestingUser { Public, Seed, Private, Advisor, Team, Community, Ecosystem }

    TokenInterface public token;
    CommunityVesting public communityVesting;
    TeamVesting public teamVesting;
    EcosystemVesting public ecosystemVesting;
    SeedPrivateAdvisorVesting public seedPrivateAdvisorVesting;
    mapping (address => VestingUser) public userCategory;
    uint256 public totalAllocated;

    event TokensReleased(address _to, uint256 _tokensReleased, VestingUser user);

    constructor(address _token) public {
         
        token = TokenInterface(_token);
        communityVesting = new CommunityVesting();
        teamVesting = new TeamVesting();
        ecosystemVesting = new EcosystemVesting();
        seedPrivateAdvisorVesting = new SeedPrivateAdvisorVesting();
    }

    function claimTokens() external {
        uint8 category = uint8(userCategory[msg.sender]);

        uint256 tokensToClaim;

        if (category == 1 || category == 2 || category == 3) {
            tokensToClaim = seedPrivateAdvisorVesting.claimTokens(msg.sender);
        } else if (category == 4) {
            tokensToClaim = teamVesting.claimTokens(msg.sender);
        } else if (category == 5) {
            tokensToClaim = communityVesting.claimTokens(msg.sender);
        } else if (category == 6){
            tokensToClaim = ecosystemVesting.claimTokens(msg.sender);
        } else {
            revert( "incorrect category, maybe unknown user" );
        }

        totalAllocated = totalAllocated.sub(tokensToClaim);
        require(token.transfer(msg.sender, tokensToClaim), "Insufficient balance in vesting contract");
        emit TokensReleased(msg.sender, tokensToClaim, userCategory[msg.sender]);
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime,
        VestingUser user
    )
        external
        onlyOwner
    {
        uint8 category = uint8(user);
        require(category != 0, "Not eligible for vesting");

        require( uint8(userCategory[_beneficiary]) == 0 || userCategory[_beneficiary] == user, "cannot change user category" );
        userCategory[_beneficiary] = user;
        totalAllocated = totalAllocated.add(_tokens);

        if (category == 1 || category == 2 || category == 3) {
            seedPrivateAdvisorVesting.initializeVesting(_beneficiary, _tokens, _startTime, category);
        } else if (category == 4) {
            teamVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else if (category == 5) {
            communityVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else if (category == 6){
            ecosystemVesting.initializeVesting(_beneficiary, _tokens, _startTime);
        } else {
            revert( "incorrect category, not eligible for vesting" );
        }
    }

    function claimUnallocated( address _sendTo) external onlyOwner{
        uint256 allTokens = token.balanceOf(address(this));
        uint256 tokensUnallocated = allTokens.sub(totalAllocated);
        token.transfer(_sendTo, tokensUnallocated);
    }
}



contract MintableAndPausableToken is ERC20Pausable, Ownable {
    uint8 public constant decimals = 18;
    uint256 public maxTokenSupply = 183500000 * 10 ** uint256(decimals);

    bool public mintingFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintStarted();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier checkMaxSupply(uint256 _amount) {
        require(maxTokenSupply >= totalSupply().add(_amount));
        _;
    }

    modifier cannotMint() {
        require(mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        onlyOwner
        canMint
        checkMaxSupply (_amount)
        whenNotPaused
        returns (bool)
    {
        super._mint(_to, _amount);
        return true;
    }

    function _mint(address _to, uint256 _amount)
        internal
        canMint
        checkMaxSupply (_amount)
    {
        super._mint(_to, _amount);
    }

    function finishMinting() external onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function startMinting() external onlyOwner cannotMint returns (bool) {
        mintingFinished = false;
        emit MintStarted();
        return true;
    }
}



 
contract TokenUpgrader {
    uint public originalSupply;

     
    function isTokenUpgrader() external pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;
}



contract UpgradeableToken is MintableAndPausableToken {
     
    address public upgradeMaster;
    
     
    bool private upgradesAllowed;

     
    TokenUpgrader public tokenUpgrader;

     
    uint public totalUpgraded;

     
    enum UpgradeState { NotAllowed, Waiting, ReadyToUpgrade, Upgrading }

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event TokenUpgraderIsSet(address _newToken);

    modifier onlyUpgradeMaster {
         
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier notInUpgradingState {
         
        require(getUpgradeState() != UpgradeState.Upgrading);
        _;
    }

     
    constructor(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

     
    function setTokenUpgrader(address _newToken)
        external
        onlyUpgradeMaster
        notInUpgradingState
    {
        require(canUpgrade());
        require(_newToken != address(0));

        tokenUpgrader = TokenUpgrader(_newToken);

         
        require(tokenUpgrader.isTokenUpgrader());

         
        require(tokenUpgrader.originalSupply() == totalSupply());

        emit TokenUpgraderIsSet(address(tokenUpgrader));
    }

     
    function upgrade(uint _value) external {
        UpgradeState state = getUpgradeState();
        
         
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
         
        require(_value != 0);

         
         
         
         
        _burn(msg.sender, _value);

        totalUpgraded = totalUpgraded.add(_value);

         
        tokenUpgrader.upgradeFrom(msg.sender, _value);
        emit Upgrade(msg.sender, address(tokenUpgrader), _value);
    }

     
    function setUpgradeMaster(address _newMaster) external onlyUpgradeMaster {
        require(_newMaster != address(0));
        upgradeMaster = _newMaster;
    }

     
    function allowUpgrades() external onlyUpgradeMaster () {
        upgradesAllowed = true;
    }

     
    function rejectUpgrades() external onlyUpgradeMaster () {
        require(!(totalUpgraded > 0));
        upgradesAllowed = false;
    }

     
    function getUpgradeState() public view returns(UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(tokenUpgrader) == address(0)) return UpgradeState.Waiting;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function canUpgrade() public view returns(bool) {
        return upgradesAllowed;
    }
}



contract Token is UpgradeableToken, ERC20Burnable {
    string public name;
    string public symbol;

     
    uint256 public INITIAL_SUPPLY;
    uint256 public hodlPremiumCap;
    uint256 public hodlPremiumMinted;

     
     
     
    uint256 constant maxBonusDuration = 180 days;

    struct Bonus {
        uint256 hodlTokens;
        uint256 contributionTime;
        uint256 buybackTokens;
    }

    mapping( address => Bonus ) public hodlPremium;

    IERC20 stablecoin;
    address stablecoinPayer;

    uint256 public signupWindowStart;
    uint256 public signupWindowEnd;

    uint256 public refundWindowStart;
    uint256 public refundWindowEnd;

    event UpdatedTokenInformation(string newName, string newSymbol);
    event HodlPremiumSet(address beneficiary, uint256 tokens, uint256 contributionTime);
    event HodlPremiumCapSet(uint256 newhodlPremiumCap);
    event RegisteredForRefund( address holder, uint256 tokens );

    constructor (address _litWallet, address _upgradeMaster, uint256 _INITIAL_SUPPLY, uint256 _hodlPremiumCap)
        public
        UpgradeableToken(_upgradeMaster)
        Ownable()
    {
        require(maxTokenSupply >= _INITIAL_SUPPLY.mul(10 ** uint256(decimals)));
        INITIAL_SUPPLY = _INITIAL_SUPPLY.mul(10 ** uint256(decimals));
        setHodlPremiumCap(_hodlPremiumCap)  ;
        _mint(_litWallet, INITIAL_SUPPLY);
    }

     
    function setTokenInformation(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;

        emit UpdatedTokenInformation(name, symbol);
    }

    function setRefundSignupDetails( uint256 _startTime,  uint256 _endTime, ERC20 _stablecoin, address _payer ) public onlyOwner {
        require( _startTime < _endTime );
        stablecoin = _stablecoin;
        stablecoinPayer = _payer;
        signupWindowStart = _startTime;
        signupWindowEnd = _endTime;
        refundWindowStart = signupWindowStart + 182 days;
        refundWindowEnd = signupWindowEnd + 182 days;
        require( refundWindowStart > signupWindowEnd);
    }

    function signUpForRefund( uint256 _value ) public {
        require( hodlPremium[msg.sender].hodlTokens != 0 || hodlPremium[msg.sender].buybackTokens != 0, "You must be ICO user to sign up" );  
        require( block.timestamp >= signupWindowStart&& block.timestamp <= signupWindowEnd, "Cannot sign up at this time" );
        uint256 value = _value;
        value = value.add(hodlPremium[msg.sender].buybackTokens);

        if( value > balanceOf(msg.sender))  
            value = balanceOf(msg.sender);

        hodlPremium[ msg.sender].buybackTokens = value;
         
        if( hodlPremium[msg.sender].hodlTokens > 0 ){
            hodlPremium[msg.sender].hodlTokens = 0;
            emit HodlPremiumSet( msg.sender, 0, hodlPremium[msg.sender].contributionTime );
        }

        emit RegisteredForRefund(msg.sender, value);
    }

    function refund( uint256 _value ) public {
        require( block.timestamp >= refundWindowStart && block.timestamp <= refundWindowEnd, "cannot refund now" );
        require( hodlPremium[msg.sender].buybackTokens >= _value, "not enough tokens in refund program" );
        require( balanceOf(msg.sender) >= _value, "not enough tokens" );  
        hodlPremium[msg.sender].buybackTokens = hodlPremium[msg.sender].buybackTokens.sub(_value);
        _burn( msg.sender, _value );
        require( stablecoin.transferFrom( stablecoinPayer, msg.sender, _value.div(20) ), "transfer failed" );  
    }

    function setHodlPremiumCap(uint256 newhodlPremiumCap) public onlyOwner {
        require(newhodlPremiumCap > 0);
        hodlPremiumCap = newhodlPremiumCap;
        emit HodlPremiumCapSet(hodlPremiumCap);
    }

     
    function burn(uint256 _value) public onlyOwner {
        super.burn(_value);
    }

    function sethodlPremium(
        address beneficiary,
        uint256 value,
        uint256 contributionTime
    )
        public
        onlyOwner
        returns (bool)
    {
        require(beneficiary != address(0) && value > 0 && contributionTime > 0, "Not eligible for HODL Premium");

        if (hodlPremium[beneficiary].hodlTokens != 0) {
            hodlPremium[beneficiary].hodlTokens = hodlPremium[beneficiary].hodlTokens.add(value);
            emit HodlPremiumSet(beneficiary, hodlPremium[beneficiary].hodlTokens, hodlPremium[beneficiary].contributionTime);
        } else {
            hodlPremium[beneficiary] = Bonus(value, contributionTime, 0);
            emit HodlPremiumSet(beneficiary, value, contributionTime);
        }

        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[msg.sender].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(msg.sender, _value);
            uint256 bonus = calculateBonus(msg.sender, amountForBonusCalculation);

             
            hodlPremium[msg.sender].hodlTokens = hodlPremium[msg.sender].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                 
                _mint( msg.sender, bonus );
                 
            }
        }

        ERC20Pausable.transfer( _to, _value );
 
 
 

         
        if( balanceOf(msg.sender) < hodlPremium[msg.sender].buybackTokens )
            hodlPremium[msg.sender].buybackTokens = balanceOf(msg.sender);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(_to != address(0));

        if (hodlPremiumMinted < hodlPremiumCap && hodlPremium[_from].hodlTokens > 0) {
            uint256 amountForBonusCalculation = calculateAmountForBonus(_from, _value);
            uint256 bonus = calculateBonus(_from, amountForBonusCalculation);

             
            hodlPremium[_from].hodlTokens = hodlPremium[_from].hodlTokens.sub(amountForBonusCalculation);
            if ( bonus > 0) {
                 
                _mint( _from, bonus );
                 
            }
        }

        ERC20Pausable.transferFrom( _from, _to, _value);
        if( balanceOf(_from) < hodlPremium[_from].buybackTokens )
            hodlPremium[_from].buybackTokens = balanceOf(_from);
        return true;
    }

    function calculateBonus(address beneficiary, uint256 amount) internal returns (uint256) {
        uint256 bonusAmount;

        uint256 contributionTime = hodlPremium[beneficiary].contributionTime;
        uint256 bonusPeriod;
        if (now <= contributionTime) {
            bonusPeriod = 0;
        } else if (now.sub(contributionTime) >= maxBonusDuration) {
            bonusPeriod = maxBonusDuration;
        } else {
            bonusPeriod = now.sub(contributionTime);
        }

        if (bonusPeriod != 0) {
            bonusAmount = (((bonusPeriod.mul(amount)).div(maxBonusDuration)).mul(25)).div(100);
            if (hodlPremiumMinted.add(bonusAmount) > hodlPremiumCap) {
                bonusAmount = hodlPremiumCap.sub(hodlPremiumMinted);
                hodlPremiumMinted = hodlPremiumCap;
            } else {
                hodlPremiumMinted = hodlPremiumMinted.add(bonusAmount);
            }

            if( totalSupply().add(bonusAmount) > maxTokenSupply )
                bonusAmount = maxTokenSupply.sub(totalSupply());
        }

        return bonusAmount;
    }

    function calculateAmountForBonus(address beneficiary, uint256 _value) internal view returns (uint256) {
        uint256 amountForBonusCalculation;

        if(_value >= hodlPremium[beneficiary].hodlTokens) {
            amountForBonusCalculation = hodlPremium[beneficiary].hodlTokens;
        } else {
            amountForBonusCalculation = _value;
        }

        return amountForBonusCalculation;
    }

}


contract TestToken is ERC20{
    constructor ( uint256 _balance)public {
        _mint(msg.sender, _balance);
    }
}

contract BaseCrowdsale is Pausable, Ownable {
    using SafeMath for uint256;

    Whitelisting public whitelisting;
    Token public token;

    struct Contribution {
        address payable contributor;
        uint256 weiAmount;
        uint256 contributionTime;
        bool tokensAllocated;
    }

    mapping (uint256 => Contribution) public contributions;
    uint256 public contributionIndex;
    uint256 public startTime;
    uint256 public endTime;
    address payable public wallet;
    uint256 public weiRaised;
    uint256 public tokenRaised;

    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event RecordedContribution(
        uint256 indexed index,
        address indexed contributor,
        uint256 weiAmount,
        uint256 time
    );

    event TokenOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier allowedUpdate(uint256 time) {
        require(time > now);
        _;
    }

    modifier checkZeroAddress(address _add) {
        require(_add != address(0));
        _;
    }

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address payable _wallet,
        Token _token,
        Whitelisting _whitelisting
    )
        public
        checkZeroAddress(_wallet)
        checkZeroAddress(address(_token))
        checkZeroAddress(address(_whitelisting))
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);

        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
        token = _token;
        whitelisting = _whitelisting;
    }

    function () external payable {
        buyTokens(msg.sender);
    }
    
    

    function transferTokenOwnership(address newOwner)
        external
        onlyOwner
        checkZeroAddress(newOwner)
    {
        emit TokenOwnershipTransferred(owner(), newOwner);
        token.transferOwnership(newOwner);
    }
    
    function setWallet(address payable _wallet) 
    external 
    onlyOwner
    checkZeroAddress(_wallet)
    {
        wallet = _wallet;
    }

    function setStartTime(uint256 _newStartTime)
        external
        onlyOwner
        allowedUpdate(_newStartTime)
    {
        require(startTime > now);
        require(_newStartTime < endTime);

        startTime = _newStartTime;
    }

    function setEndTime(uint256 _newEndTime)
        external
        onlyOwner
        allowedUpdate(_newEndTime)
    {
        require(endTime > now);
        require(_newEndTime > startTime);

        endTime = _newEndTime;
    }

    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function buyTokens(address payable beneficiary)
        internal
        whenNotPaused
        checkZeroAddress(beneficiary)
    {
        require(validPurchase());
        require(whitelisting.isInvestorPaymentApproved(beneficiary));

        contributions[contributionIndex].contributor = beneficiary;
        contributions[contributionIndex].weiAmount = msg.value;
        contributions[contributionIndex].contributionTime = now;

        weiRaised = weiRaised.add(contributions[contributionIndex].weiAmount);
        emit RecordedContribution(
            contributionIndex,
            contributions[contributionIndex].contributor,
            contributions[contributionIndex].weiAmount,
            contributions[contributionIndex].contributionTime
        );

        contributionIndex++;

        forwardFunds();
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}



contract RefundVault is Ownable {
    enum State { Refunding, Closed }

    address payable public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address payable _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function deposit() public onlyOwner payable {
        require(state == State.Refunding);
    }

    function close() public onlyOwner {
        require(state == State.Refunding);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function refund(address payable investor, uint256 depositedValue) public onlyOwner {
        require(state == State.Refunding);
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}



contract TokenCapRefund is BaseCrowdsale {
    RefundVault public vault;
    uint256 public refundClosingTime;

    modifier waitingTokenAllocation(uint256 index) {
        require(!contributions[index].tokensAllocated);
        _;
    }

    modifier greaterThanZero(uint256 value) {
        require(value > 0);
        _;
    }

    constructor(uint256 _refundClosingTime) public {
        vault = new RefundVault(wallet);

        require(_refundClosingTime > endTime);
        refundClosingTime = _refundClosingTime;
    }

    function closeRefunds() external onlyOwner {
        require(now > refundClosingTime);
        vault.close();
    }

    function refundContribution(uint256 index)
        external
        onlyOwner
        waitingTokenAllocation(index)
    {
        vault.refund(contributions[index].contributor, contributions[index].weiAmount);
        weiRaised = weiRaised.sub(contributions[index].weiAmount);
        delete contributions[index];
    }

    function setRefundClosingTime(uint256 _newRefundClosingTime)
        external
        onlyOwner
        allowedUpdate(_newRefundClosingTime)
    {
        require(refundClosingTime > now);
        require(_newRefundClosingTime > endTime);

        refundClosingTime = _newRefundClosingTime;
    }

    function forwardFunds() internal {
        vault.deposit.value(msg.value)();
    }
}


contract TokenCapCrowdsale is BaseCrowdsale {
    uint256 public tokenCap;
    uint256 public individualCap;
    uint256 public totalSupply;

    modifier greaterThanZero(uint256 value) {
        require(value > 0);
        _;
    }

    constructor (uint256 _cap, uint256 _individualCap)
        public
        greaterThanZero(_cap)
        greaterThanZero(_individualCap)
    {
        syncTotalSupply();
        require(totalSupply < _cap);
        tokenCap = _cap;
        individualCap = _individualCap;
    }

    function setIndividualCap(uint256 _newIndividualCap)
        external
        onlyOwner
    {     
        individualCap = _newIndividualCap;
    }

    function setTokenCap(uint256 _newTokenCap)
        external
        onlyOwner
    {     
        tokenCap = _newTokenCap;
    }

    function hasEnded() public view returns (bool) {
        bool tokenCapReached = totalSupply >= tokenCap;
        return tokenCapReached || super.hasEnded();
    }

    function checkAndUpdateSupply(uint256 newSupply) internal returns (bool) {
        totalSupply = newSupply;
        return tokenCap >= totalSupply;
    }

    function withinIndividualCap(uint256 _tokens) internal view returns (bool) {
        return individualCap >= _tokens;
    }

    function syncTotalSupply() internal {
        totalSupply = token.totalSupply();
    }
}



contract PrivateSale is TokenCapCrowdsale, TokenCapRefund {

    Vesting public vesting;
    mapping (address => uint256) public tokensVested;
    uint256 hodlStartTime;

    constructor (
        uint256 _startTime,
        uint256 _endTime,
        address payable _wallet,
        Whitelisting _whitelisting,
        Token _token,
        Vesting _vesting,
        uint256 _refundClosingTime,
        uint256 _refundClosingTokenCap,
        uint256 _tokenCap,
        uint256 _individualCap
    )
        public
        TokenCapCrowdsale(_tokenCap, _individualCap)
        TokenCapRefund(_refundClosingTime)
        BaseCrowdsale(_startTime, _endTime, _wallet, _token, _whitelisting)
    {
        _refundClosingTokenCap;  
        require( address(_vesting) != address(0), "Invalid address");
        vesting = _vesting;
    }

    function allocateTokens(uint256 index, uint256 tokens)
        external
        onlyOwner
        waitingTokenAllocation(index)
    {
        address contributor = contributions[index].contributor;
        require(now >= endTime);
        require(whitelisting.isInvestorApproved(contributor));

        require(checkAndUpdateSupply(totalSupply.add(tokens)));

        uint256 alreadyExistingTokens = token.balanceOf(contributor);
        require(withinIndividualCap(tokens.add(alreadyExistingTokens)));

        contributions[index].tokensAllocated = true;
        tokenRaised = tokenRaised.add(tokens);
        token.mint(contributor, tokens);
        token.sethodlPremium(contributor, tokens, hodlStartTime);

        emit TokenPurchase(
            msg.sender,
            contributor,
            contributions[index].weiAmount,
            tokens
        );
    }

    function vestTokens(address[] calldata beneficiary, uint256[] calldata tokens, uint8[] calldata userType) external onlyOwner {
        require(beneficiary.length == tokens.length && tokens.length == userType.length);
        uint256 length = beneficiary.length;
        for(uint i = 0; i<length; i++) {
            require(beneficiary[i] != address(0), "Invalid address");
            require(now >= endTime);
            require(checkAndUpdateSupply(totalSupply.add(tokens[i])));

            tokensVested[beneficiary[i]] = tokensVested[beneficiary[i]].add(tokens[i]);
            require(withinIndividualCap(tokensVested[beneficiary[i]]));

            tokenRaised = tokenRaised.add(tokens[i]);

            token.mint(address(vesting), tokens[i]);
            Vesting(vesting).initializeVesting(beneficiary[i], tokens[i], now, Vesting.VestingUser(userType[i]));
        }
    }

    function ownerAssignedTokens(address beneficiary, uint256 tokens)
        external
        onlyOwner
    {
        require(now >= endTime);
        require(whitelisting.isInvestorApproved(beneficiary));

        require(checkAndUpdateSupply(totalSupply.add(tokens)));

        uint256 alreadyExistingTokens = token.balanceOf(beneficiary);
        require(withinIndividualCap(tokens.add(alreadyExistingTokens)));
        tokenRaised = tokenRaised.add(tokens);

        token.mint(beneficiary, tokens);
        token.sethodlPremium(beneficiary, tokens, hodlStartTime);

        emit TokenPurchase(
            msg.sender,
            beneficiary,
            0,
            tokens
        );
    }

    function setHodlStartTime(uint256 _hodlStartTime) onlyOwner external{
        hodlStartTime = _hodlStartTime;
    }
}