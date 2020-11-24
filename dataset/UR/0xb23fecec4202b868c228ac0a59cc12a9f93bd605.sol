 

pragma solidity ^0.4.11;
contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract SafeMath {
    
     
    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }
    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }
    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
     
    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }
    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }
    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }
    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }
    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }
     
    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }
     
    uint128 constant WAD = 10 ** 18;
    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }
    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }
    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }
    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }
    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }
     
    uint128 constant RAY = 10 ** 27;
    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }
    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }
    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }
    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }
    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        z = n % 2 != 0 ? x : RAY;
        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);
            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }
    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
}
contract Owned {
     
     
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }
    address public owner;
     
    function Owned() {
        owner = msg.sender;
    }
    address public newOwner;
     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}
contract StandardToken is ERC20Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
         
         
         
         
        if ((_value!=0) && (allowed[msg.sender][_spender] !=0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
}
contract ATMToken is StandardToken, Owned {
     
    string public constant name = "Attention Token of Media";
    string public constant symbol = "ATM";
    string public version = "1.0";
    uint256 public constant decimals = 8;
    bool public disabled;
    mapping(address => bool) public isATMHolder;
    address[] public ATMHolders;
     
    function ATMToken(uint256 _amount) {
        totalSupply = _amount;  
        balances[msg.sender] = _amount;
    }
    function getATMTotalSupply() external constant returns(uint256) {
        return totalSupply;
    }
    function getATMHoldersNumber() external constant returns(uint256) {
        return ATMHolders.length;
    }
     
    function setDisabled(bool flag) external onlyOwner {
        disabled = flag;
    }
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        if(isATMHolder[_to] == false){
            isATMHolder[_to] = true;
            ATMHolders.push(_to);
        }
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        if(isATMHolder[_to] == false){
            isATMHolder[_to] = true;
            ATMHolders.push(_to);
        }
        return super.transferFrom(_from, _to, _value);
    }
    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}
contract Contribution is SafeMath, Owned {
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_END_DAY = 7;
    uint256 public dayCycle = 24 hours;
    uint256 public fundingStartTime = 0;
    address public ethFundDeposit = 0;
    address public investorDeposit = 0;
    bool public isFinalize = false;
    bool public isPause = false;
    mapping (uint => uint) public dailyTotals;  
    mapping (uint => mapping (address => uint)) public userBuys;  
    uint256 public totalContributedETH = 0;  
     
    event LogBuy (uint window, address user, uint amount);
    event LogCreate (address ethFundDeposit, address investorDeposit, uint fundingStartTime, uint dayCycle);
    event LogFinalize (uint finalizeTime);
    event LogPause (uint finalizeTime, bool pause);
    function Contribution (address _ethFundDeposit, address _investorDeposit, uint256 _fundingStartTime, uint256 _dayCycle)  {
        require( now < _fundingStartTime );
        require( _ethFundDeposit != address(0) );
        fundingStartTime = _fundingStartTime;
        dayCycle = _dayCycle;
        ethFundDeposit = _ethFundDeposit;
        investorDeposit = _investorDeposit;
        LogCreate(_ethFundDeposit, _investorDeposit, _fundingStartTime,_dayCycle);
    }
     
    function () payable {  
        require(!isPause);
        require(!isFinalize);
        require( msg.value >= MIN_FUND );  
        ethFundDeposit.transfer(msg.value);
        buy(today(), msg.sender, msg.value);
    }
    function importExchangeSale(uint256 day, address _exchangeAddr, uint _amount) onlyOwner {
        buy(day, _exchangeAddr, _amount);
    }
    function buy(uint256 day, address _addr, uint256 _amount) internal {
        require( day >= CRAWDSALE_START_DAY && day <= CRAWDSALE_END_DAY ); 
         
        userBuys[day][_addr] += _amount;
        dailyTotals[day] += _amount;
        totalContributedETH += _amount;
        LogBuy(day, _addr, _amount);
    }
    function kill() onlyOwner {
        selfdestruct(owner);
    }
    function pause(bool _isPause) onlyOwner {
        isPause = _isPause;
        LogPause(now,_isPause);
    }
    function finalize() onlyOwner {
        isFinalize = true;
        LogFinalize(now);
    }
    function today() constant returns (uint) {
        return sub(now, fundingStartTime) / dayCycle + 1;
    }
}
contract ATMint is SafeMath, Owned {
    ATMToken public atmToken;  
    Contribution public contribution;  
    uint128 public fundingStartTime = 0;
    uint256 public lockStartTime = 0;
    
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_EARLYBIRD_END_DAY = 3;
    uint256 public constant CRAWDSALE_END_DAY = 7;
    uint256 public constant THAW_CYCLE_USER = 6 ;
    uint256 public constant THAW_CYCLE_FUNDER = 6 ;
    uint256 public constant THAW_CYCLE_LENGTH = 30;
    uint256 public constant decimals = 8;  
    uint256 public constant MILLION = (10**6 * 10**decimals);
    uint256 public constant tokenTotal = 10000 * MILLION;   
    uint256 public constant tokenToFounder = 800 * MILLION;   
    uint256 public constant tokenToReserve = 5000 * MILLION;   
    uint256 public constant tokenToContributor = 4000 * MILLION;  
    uint256[] public tokenToReward = [0, (120 * MILLION), (50 * MILLION), (30 * MILLION), 0, 0, 0, 0];  
    bool doOnce = false;
    
    mapping (address => bool) public collected;
    mapping (address => uint) public contributedToken;
    mapping (address => uint) public unClaimedToken;
     
    event LogRegister (address contributionAddr, address ATMTokenAddr);
    event LogCollect (address user, uint spendETHAmount, uint getATMAmount);
    event LogMigrate (address user, uint balance);
    event LogClaim (address user, uint claimNumberNow, uint unclaimedTotal, uint totalContributed);
    event LogClaimReward (address user, uint claimNumber);
     
    function initialize (address _contribution) onlyOwner {
        require( _contribution != address(0) );
        contribution = Contribution(_contribution);
        atmToken = new ATMToken(tokenTotal);
         
        setLockStartTime(now);
         
        lockToken(contribution.ethFundDeposit(), tokenToReserve);
        lockToken(contribution.investorDeposit(), tokenToFounder);
         
        claimUserToken(contribution.investorDeposit());
        claimFoundationToken();
        
        LogRegister(_contribution, atmToken);
    }
     
    function collect(address _user) {
        require(!collected[_user]);
        
        uint128 dailyContributedETH = 0;
        uint128 userContributedETH = 0;
        uint128 userTotalContributedETH = 0;
        uint128 reward = 0;
        uint128 rate = 0;
        uint128 totalATMToken = 0;
        uint128 rewardRate = 0;
        collected[_user] = true;
        for (uint day = CRAWDSALE_START_DAY; day <= CRAWDSALE_END_DAY; day++) {
            dailyContributedETH = cast( contribution.dailyTotals(day) );
            userContributedETH = cast( contribution.userBuys(day,_user) );
            if (dailyContributedETH > 0 && userContributedETH > 0) {
                 
                rewardRate = wdiv(cast(tokenToReward[day]), dailyContributedETH);
                reward += wmul(userContributedETH, rewardRate);
                 
                userTotalContributedETH += userContributedETH;
            }
        }
        rate = wdiv(cast(tokenToContributor), cast(contribution.totalContributedETH()));
        totalATMToken = wmul(rate, userTotalContributedETH);
        totalATMToken += reward;
         
        lockToken(_user, totalATMToken);
         
        claimUserToken(_user);
        LogCollect(_user, userTotalContributedETH, totalATMToken);
    }
    function lockToken(
        address _user,
        uint256 _amount
    ) internal {
        require(_user != address(0));
        contributedToken[_user] += _amount;
        unClaimedToken[_user] += _amount;
    }
    function setLockStartTime(uint256 _time) internal {
        lockStartTime = _time;
    }
    function cast(uint256 _x) constant internal returns (uint128 z) {
        require((z = uint128(_x)) == _x);
    }
     
    function claimReward(address _founder) onlyOwner {
        require(_founder != address(0));
        require(lockStartTime != 0);
        require(doOnce == false);
        uint256 rewards = 0;
        for (uint day = CRAWDSALE_START_DAY; day <= CRAWDSALE_EARLYBIRD_END_DAY; day++) {
            if(contribution.dailyTotals(day) == 0){
                rewards += tokenToReward[day];
            }
        }
        atmToken.transfer(_founder, rewards);
        doOnce = true;
        LogClaimReward(_founder, rewards);
    }
    
    function claimFoundationToken() {
        require(msg.sender == owner || msg.sender == contribution.ethFundDeposit());
        claimToken(contribution.ethFundDeposit(),THAW_CYCLE_FUNDER);
    }
    function claimUserToken(address _user) {
        claimToken(_user,THAW_CYCLE_USER);
    }
    function claimToken(address _user, uint256 _stages) internal {
        if (unClaimedToken[_user] == 0) {
            return;
        }
        uint256 currentStage = sub(now, lockStartTime) / (60*60  ) +1;
        if (currentStage == 0) {
            return;
        } else if (currentStage > _stages) {
            currentStage = _stages;
        }
        uint256 lockStages = _stages - currentStage;
        uint256 unClaimed = (contributedToken[_user] * lockStages) / _stages;
        if (unClaimedToken[_user] <= unClaimed) {
            return;
        }
        uint256 tmp = unClaimedToken[_user] - unClaimed;
        unClaimedToken[_user] = unClaimed;
        atmToken.transfer(_user, tmp);
        LogClaim(_user, tmp, unClaimed,contributedToken[_user]);
    }
     
    function disableATMExchange() onlyOwner {
        atmToken.setDisabled(true);
    }
    function enableATMExchange() onlyOwner {
        atmToken.setDisabled(false);
    }
    function migrateUserData() onlyOwner {
        for (var i=0; i< atmToken.getATMHoldersNumber(); i++){
            LogMigrate(atmToken.ATMHolders(i), atmToken.balances(atmToken.ATMHolders(i)));
        }
    }
    function kill() onlyOwner {
        atmToken.kill();
        selfdestruct(owner);
    }
}