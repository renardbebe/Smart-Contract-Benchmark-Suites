 

pragma solidity ^0.5.0;

 


contract IReputationToken {
    function migrateOut(IReputationToken _destination, uint256 _attotokens) public returns (bool);
    function migrateIn(address _reporter, uint256 _attotokens) public returns (bool);
    function trustedReportingParticipantTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedMarketTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedDisputeWindowTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedUniverseTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getTotalMigrated() public view returns (uint256);
    function getTotalTheoreticalSupply() public view returns (uint256);
    function mintForReportingParticipant(uint256 _amountMigrated) public returns (bool);
}

contract IUniverse {
    
    function createYesNoMarket(uint256 _endTime, uint256 _feePerEthInWei, address _designatedReporterAddress, address _denominationToken, bytes32 _topic, string memory _description, string memory _extraInfo) public payable;
    
    function fork() public returns (bool);
    function getParentUniverse() public view returns (IUniverse);
    function getChildUniverse(bytes32 _parentPayoutDistributionHash) public view returns (IUniverse);
    function getForkEndTime() public view returns (uint256);
    function getForkReputationGoal() public view returns (uint256);
    function getParentPayoutDistributionHash() public view returns (bytes32);
    function getDisputeRoundDurationInSeconds() public view returns (uint256);
    function getOpenInterestInAttoEth() public view returns (uint256);
    function getRepMarketCapInAttoEth() public view returns (uint256);
    function getTargetRepMarketCapInAttoEth() public view returns (uint256);
    function getOrCacheValidityBond() public returns (uint256);
    function getOrCacheDesignatedReportStake() public returns (uint256);
    function getOrCacheDesignatedReportNoShowBond() public returns (uint256);
    function getOrCacheReportingFeeDivisor() public returns (uint256);
    function getDisputeThresholdForFork() public view returns (uint256);
    function getDisputeThresholdForDisputePacing() public view returns (uint256);
    function getInitialReportMinValue() public view returns (uint256);
    function calculateFloatingValue(uint256 _badMarkets, uint256 _totalMarkets, uint256 _targetDivisor, uint256 _previousValue, uint256 _defaultValue, uint256 _floor) public pure returns (uint256 _newValue);
    function getOrCacheMarketCreationCost() public returns (uint256);
    function isParentOf(IUniverse _shadyChild) public view returns (bool);
    function updateTentativeWinningChildUniverse(bytes32 _parentPayoutDistributionHash) public returns (bool);
    function addMarketTo() public returns (bool);
    function removeMarketFrom() public returns (bool);
    function decrementOpenInterest(uint256 _amount) public returns (bool);
    function decrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
    function incrementOpenInterest(uint256 _amount) public returns (bool);
    function incrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
    function getWinningChildUniverse() public view returns (IUniverse);
    function isForking() public view returns (bool);
}


contract AccessDelegated {

   

    mapping(address => uint256) public accessLevel;

    event AccessLevelSet(
        address accessSetFor,
        uint256 accessLevel,
        address setBy
    );
    event AccessRevoked(
        address accessRevoked,
        uint256 previousAccessLevel,
        address revokedBy
    );


     
    constructor() public {
        accessLevel[msg.sender] = 4;
    }

     

    modifier requiresNoAccessLevel () {
        require(
            accessLevel[msg.sender] >= 0,
            "Access level greater than or equal to 0 required"
        );
        _;
    }

    modifier requiresLimitedAccessLevel () {
        require(
            accessLevel[msg.sender] >= 1,
            "Access level greater than or equal to 1 required"
        );
        _;
    }

    modifier requiresPrivelegedAccessLevel () {
        require(
            accessLevel[msg.sender] >= 2,
            "Access level greater than or equal to 2 required"
        );
        _;
    }

    modifier requiresManagerAccessLevel () {
        require(
            accessLevel[msg.sender] >= 3,
            "Access level greater than or equal to 3 required"
        );
        _;
    }

    modifier requiresOwnerAccessLevel () {
        require(
            accessLevel[msg.sender] >= 4,
            "Access level greater than or equal to 4 required"
        );
        _;
    }

     

    modifier limitedAccessLevelOnly () {
        require(accessLevel[msg.sender] == 1, "Access level 1 required");
        _;
    }

    modifier privelegedAccessLevelOnly () {
        require(accessLevel[msg.sender] == 2, "Access level 2 required");
        _;
    }

    modifier managerAccessLevelOnly () {
        require(accessLevel[msg.sender] == 3, "Access level 3 required");
        _;
    }

    modifier adminAccessLevelOnly () {
        require(accessLevel[msg.sender] == 4, "Access level 4 required");
        _;
    }


     
    function setAccessLevel(
        address _user,
        uint256 _access
    )
        public
        adminAccessLevelOnly
    {
        require(
            accessLevel[_user] < 4,
            "Cannot setAccessLevel for Admin Level Access User"
        );  

        if (_access < 0 || _access > 4) {
            revert("erroneous access level");
        } else {
            accessLevel[_user] = _access;
        }

        emit AccessLevelSet(_user, _access, msg.sender);
    }

    function revokeAccess(address _user) public adminAccessLevelOnly {
         
        require(
            accessLevel[_user] < 4,
            "admin cannot revoke their own access"
        );
        uint256 currentAccessLevel = accessLevel[_user];
        accessLevel[_user] = 0;

        emit AccessRevoked(_user, currentAccessLevel, msg.sender);
    }

     
    function getAccessLevel(address _user) public view returns (uint256) {
        return accessLevel[_user];
    }

     
    function myAccessLevel() public view returns (uint256) {
        return getAccessLevel(msg.sender);
    }

}

 

 

 
 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
contract Token is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract StakeToken is Token {

    string public constant NAME = "TestTokenERC20";  
    string public constant SYMBOL = "T20";  
    uint8 public constant DECIMALS = 18;  
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(DECIMALS));

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

     
    function giveMeTokens() public {
        balances[msg.sender] += INITIAL_SUPPLY;
        totalSupply_ += INITIAL_SUPPLY;
    }
}

contract StakingContract {
    using SafeMath for *;

    event TokensStaked(address msgSender, address txOrigin, uint256 _amount);

    address public stakingTokenAddress;

     
    StakeToken stakingToken;

     
    uint256 public defaultLockInDuration;

     
     
     
     
     
    mapping (address => StakeContract) public stakeHolders;

     
     
     
     
    struct Stake {
        uint256 unlockedTimestamp;
        uint256 actualAmount;
        address stakedFor;
    }

     
     
     
     
     
    struct StakeContract {
        uint256 totalStakedFor;

        uint256 personalStakeIndex;

        Stake[] personalStakes;

        bool exists;
    }

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);


    constructor() public {

    }

    modifier canStake(address _address, uint256 _amount) {
        require(
            stakingToken.transferFrom(_address, address(this), _amount),
            "Stake required");
        _;
    }


    function initForTests(address _token) public {
        stakingTokenAddress = _token;
         
         
        stakingToken = StakeToken(stakingTokenAddress);
    }


    function stake(uint256 _amount) public returns (bool) {
        createStake(
            msg.sender,
            _amount);
        return true;
    }


    function createStake(
        address _address,
        uint256 _amount
    )
        internal
        canStake(msg.sender, _amount)
    {
        if (!stakeHolders[msg.sender].exists) {
            stakeHolders[msg.sender].exists = true;
        }

        stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);
        stakeHolders[msg.sender].personalStakes.push(
            Stake(
                block.timestamp.add(2000),
                _amount,
                _address)
            );

    }


    function withdrawStake(
        uint256 _amount
    )
        internal
    {
        Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

         
        require(
            personalStake.unlockedTimestamp <= block.timestamp,
            "The current stake hasn't unlocked yet");

        require(
            personalStake.actualAmount == _amount,
            "The unstake amount does not match the current stake");

         
         
         
        require(
            stakingToken.transfer(msg.sender, _amount),
            "Unable to withdraw stake");

        stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
            .totalStakedFor.sub(personalStake.actualAmount);

        personalStake.actualAmount = 0;
        stakeHolders[msg.sender].personalStakeIndex++;
    }


}

contract AccessDelegatedTokenStorage is AccessDelegated {

    using SafeMath for *;

 

     
    mapping(address => uint256) public userTokenBalance;

 

     
     

 

     
    uint256 public totalTokenBalance;
    uint256 public stakedTokensReceivable;
    uint256 public approvedTokensPayable;

     
     
     
    address public token;
    address public tokenStakingContractAddress;
    address public augurUniverseAddress;


 

     
    event UserBalanceChange(address indexed user, uint256 previousBalance, uint256 currentBalance);
    event TokenDeposit(address indexed user, uint256 amount);
    event TokenWithdrawal(address indexed user, uint256 amount);

 


 

    constructor () public {
         
    }

 


 

    function delegatedTotalSupply() public view returns (uint256) {
        return StakeToken(token).totalSupply();
    }

    function delegatedBalanceOf(address _balanceHolder) public view returns (uint256) {
        return StakeToken(token).balanceOf(_balanceHolder);
    }

    function delegatedAllowance(address _owner, address _spender) public view returns (uint256) {
        return StakeToken(token).allowance(_owner, _spender);
    }

    function delegatedApprove(address _spender, uint256 _value) public adminAccessLevelOnly returns (bool) {
        return StakeToken(token).approve(_spender, _value);
    }

    function delegatedTransferFrom(address _from, address _to, uint256 _value) public adminAccessLevelOnly returns (bool) {
        return StakeToken(token).transferFrom(_from, _to, _value);
    }

    function delegatedTokenTransfer(address _to, uint256 _value) public adminAccessLevelOnly returns (bool) {
        return StakeToken(token).transfer(_to, _value);
    }

    function delegatedIncreaseApproval(address _spender, uint256 _addedValue) public adminAccessLevelOnly returns (bool) {
        return StakeToken(token).increaseApproval(_spender, _addedValue);
    }

    function delegatedDecreaseApproval(address _spender, uint256 _subtractedValue) public adminAccessLevelOnly returns (bool) {
        return StakeToken(token).decreaseApproval(_spender, _subtractedValue);
    }

    function delegatedStake(uint256 _amount) public returns (bool) {
        require(StakingContract(tokenStakingContractAddress).stake(_amount), "staking must be successful");
        stakedTokensReceivable += _amount;
        approvedTokensPayable -= _amount;
    }

    function delegatedApproveSpender(address _address, uint256 _amount) public returns (bool) {
        require(StakeToken(token).approve(_address, _amount), "approval must be successful");
        approvedTokensPayable += _amount;
    }
    
    function depositEther() public payable {
        
    }
    
    function delegatedCreateYesNoMarket(
        uint256 _endTime,
        uint256 _feePerEthInWei,
        address _denominationToken,
        address _designatedReporterAddress,
        bytes32 _topic,
        string memory _description,
        string memory _extraInfo) public payable {
            IUniverse(augurUniverseAddress).createYesNoMarket(
        _endTime,
        _feePerEthInWei,
        _denominationToken,
        _designatedReporterAddress,
        _topic,
        _description,
        _extraInfo);
        }
     
     
     
     

 

     
     
     
     
    
    function setTokenContract(address _token) external {
        token = _token;
    }

    function setTokenStakingContract(address _stakingContractAddress) external {
        tokenStakingContractAddress = _stakingContractAddress;
    }
    
    function setAugurUniverse(address augurUniverse) external {
        augurUniverseAddress = address(IUniverse(augurUniverse));
    }

     
    function depositToken(address _user) public {


        uint256 allowance = StakeToken(token).allowance(_user, address(this));
        uint256 oldBalance = userTokenBalance[_user];
        uint256 newBalance = oldBalance.add(allowance);
        require(StakeToken(token).transferFrom(_user, address(this), allowance), "transfer failed");

         
        userTokenBalance[_user] = newBalance;

         
        totalTokenBalance = totalTokenBalance.add(allowance);

         

         
        emit UserBalanceChange(_user, oldBalance, newBalance);
    }
    
    function proxyDepositToken(address _user, uint256 _amount) external {
        uint256 oldBalance = userTokenBalance[_user];
        uint256 newBalance = oldBalance.add(_amount);
        
         
        userTokenBalance[_user] = newBalance;

         
        totalTokenBalance = totalTokenBalance.add(_amount);
        
        emit UserBalanceChange(_user, oldBalance, newBalance);
    }
    

    function checkTotalBalanceExternal() public view returns (uint256, uint256) {
        return (StakeToken(token).balanceOf(address(this)), StakeToken(token).balanceOf(address(this)));
    }

    function balanceChecks() public view returns (uint256, uint256, uint256, uint256) {
        return (
            stakedTokensReceivable,
            approvedTokensPayable,
            totalTokenBalance,
            StakeToken(token).balanceOf(address(tokenStakingContractAddress))
        );
    }


     
    function withdrawTokens(address _user, uint256 _amount) public returns (bool) {

         
         
        
        uint256 currentBalance = userTokenBalance[_user];

        require(_amount <= currentBalance, "Withdraw amount greater than current balance");

        uint256 newBalance = currentBalance.sub(_amount);

        require(StakeToken(token).transfer(_user, _amount), "error during token transfer");

         
        userTokenBalance[_user] = newBalance;

         
        totalTokenBalance = SafeMath.sub(totalTokenBalance, _amount);

         
        emit TokenWithdrawal(_user, _amount);
        emit UserBalanceChange(_user, currentBalance, newBalance);
    }

     
    function makeDeposit() public { 
        depositToken(msg.sender);
    }

     
    function makeWithdrawal(uint256 _amount) public { 
        withdrawTokens(msg.sender, _amount);
        emit TokenWithdrawal(msg.sender, _amount);
    }


     
    function getUserTokenBalance(address _user) public view returns (uint256 balance) {
        return userTokenBalance[_user];
    }

     
    function getTokenAddress() public view returns (address tokenContract) {
        return token;
    }

 


 

    
}