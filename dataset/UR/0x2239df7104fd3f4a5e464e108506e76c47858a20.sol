 

pragma solidity^0.4.24;

 



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

interface BankOfEth {
    function receiveExternalProfits() external payable;
}

contract BankOfEthVaultBreaker {
    
    using SafeMath for uint256;
    using Percent for Percent.percent;
    using Zero for *;
    using ToAddress for *;

     
    event KeysIssued(address indexed to, uint keys, uint timestamp);
    event EthDistributed(uint amount, uint timestamp);
    event ReturnsWithdrawn(address indexed by, uint amount, uint timestamp);
    event JackpotWon(address by, uint amount, uint timestamp);
    event AirdropWon(address by, uint amount, uint timestamp);
    event RoundStarted(uint indexed ID, uint hardDeadline, uint timestamp);
    
    address owner;
    address devAddress;
    address bankOfEthAddress = 0xd70c3f752Feb69Ecf8Eb31E48B20A97D979e8e5e;

    BankOfEth localBankOfEth;
    

     
    uint public constant STARTING_KEY_PRICE = 1 finney;  
    uint public constant HARD_DEADLINE_DURATION = 30 days;  
    
    uint public constant TIME_PER_KEY = 5 minutes;  
    uint public constant PRICE_INCREASE_PERIOD = 1 hours;  
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    
    Percent.percent private m_currentRoundJackpotPercent = Percent.percent(15, 100);  
    Percent.percent private m_investorsPercent = Percent.percent(65, 100);  
    Percent.percent private m_devPercent = Percent.percent(10, 100);  
    Percent.percent private m_nextRoundSeedPercent = Percent.percent(5, 100);  
    Percent.percent private m_airdropPercent = Percent.percent(2, 100);  
    Percent.percent private m_bankOfEthProfitPercent = Percent.percent(3, 100);  
    Percent.percent private m_refPercent = Percent.percent(3, 100);  
    
    struct SafeBreaker {
         
        uint lastCumulativeReturnsPoints;
        uint keys;
    }
    
    struct GameRound {
        uint totalInvested;        
        uint jackpot;
        uint airdropPot;
        uint totalKeys;
        uint cumulativeReturnsPoints;  
        uint hardDeadline;
        uint softDeadline;
        uint price;
        uint lastPriceIncreaseTime;
        address lastInvestor;
        bool finalized;
        mapping (address => SafeBreaker) safeBreakers;
    }
    
    struct Vault {
        uint totalReturns;  
        uint refReturns;  
    }

    mapping (address => Vault) vaults;

    uint public latestRoundID; 
    GameRound[] rounds;
    
    
    uint256 public minInvestment = 1 finney;  
    uint256 public maxInvestment = 2000 ether; 
    uint256 public roundDuration = (24 hours);
    uint public soft_deadline_duration = 1 days;  
    bool public gamePaused = false;
    bool public limitedReferralsMode = true;
    
    mapping(address => bool) private m_referrals;  
    
    
     
    uint public jackpotSeed; 
    
    uint public unclaimedReturns;
    uint public constant MULTIPLIER = RAY;
    
     
    uint public totalJackpotsWon;
    uint public totalKeysSold;
    uint public totalEarningsGenerated;

    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notOnPause() {
        require(gamePaused == false, "Game Paused");
        _;
    }
    
    

    
    constructor() public {

        owner = msg.sender;
        devAddress = msg.sender;
        localBankOfEth = BankOfEth(bankOfEthAddress);
        
        rounds.length++;
        GameRound storage rnd = rounds[0];
        latestRoundID = 0;

        rnd.lastInvestor = msg.sender;
        rnd.price = STARTING_KEY_PRICE;
        rnd.hardDeadline = now + HARD_DEADLINE_DURATION;
        rnd.softDeadline = now + soft_deadline_duration;
        jackpotSeed = 0; 
        rnd.jackpot = jackpotSeed;
        

        
    }
    
    function () public payable {
        buyKeys(address(0x0));
    }
    
    function investorInfo(address investor, uint roundID) external view
    returns(uint keys, uint totalReturns, uint referralReturns) 
    {
        GameRound storage rnd = rounds[roundID];
        keys = rnd.safeBreakers[investor].keys;
        (totalReturns, referralReturns) = estimateReturns(investor, roundID);
    }
    function estimateReturns(address investor, uint roundID) public view 
    returns (uint totalReturns, uint refReturns) 
    {
        GameRound storage rnd = rounds[roundID];
        uint outstanding;
        if(rounds.length > 1) {
            if(hasReturns(investor, roundID - 1)) {
                GameRound storage prevRnd = rounds[roundID - 1];
                outstanding = _outstandingReturns(investor, prevRnd);
            }
        }

        outstanding += _outstandingReturns(investor, rnd);
        
        totalReturns = vaults[investor].totalReturns + outstanding;
        refReturns = vaults[investor].refReturns;
    }
    
    function roundInfo(uint roundID) external view 
    returns(
        address leader, 
        uint price,
        uint jackpot, 
        uint airdrop, 
        uint keys, 
        uint totalInvested,
        uint distributedReturns,
        uint _hardDeadline,
        uint _softDeadline,
        bool finalized
        )
    {
        GameRound storage rnd = rounds[roundID];
        leader = rnd.lastInvestor;
        price = rnd.price;
        jackpot = rnd.jackpot;
        airdrop = rnd.airdropPot;
        keys = rnd.totalKeys;
        totalInvested = rnd.totalInvested;
        distributedReturns = m_currentRoundJackpotPercent.mul(rnd.totalInvested);
         
        _hardDeadline = rnd.hardDeadline;
        _softDeadline = rnd.softDeadline;
        finalized = rnd.finalized;
    }
    
    function totalsInfo() external view 
    returns(
        uint totalReturns,
        uint totalKeys,
        uint totalJackpots
    ) {
        GameRound storage rnd = rounds[latestRoundID];
        if(rnd.softDeadline > now) {
            totalKeys = totalKeysSold + rnd.totalKeys;
            totalReturns = totalEarningsGenerated + m_currentRoundJackpotPercent.mul(rnd.totalInvested); 
             
        } else {
            totalKeys = totalKeysSold;
            totalReturns = totalEarningsGenerated;
        }
        totalJackpots = totalJackpotsWon;
    }

    
    function reinvestReturns(uint value) public {        
        reinvestReturns(value, address(0x0));
    }

    function reinvestReturns(uint value, address ref) public {        
        GameRound storage rnd = rounds[latestRoundID];
        _updateReturns(msg.sender, rnd);        
        require(vaults[msg.sender].totalReturns >= value, "Can't spend what you don't have");        
        vaults[msg.sender].totalReturns = vaults[msg.sender].totalReturns.sub(value);
        vaults[msg.sender].refReturns = min(vaults[msg.sender].refReturns, vaults[msg.sender].totalReturns);
        unclaimedReturns = unclaimedReturns.sub(value);
        _purchase(rnd, value, ref);
    }
    function withdrawReturns() public {
        GameRound storage rnd = rounds[latestRoundID];

        if(rounds.length > 1) { 
            if(hasReturns(msg.sender, latestRoundID - 1)) {
                GameRound storage prevRnd = rounds[latestRoundID - 1];
                _updateReturns(msg.sender, prevRnd);
            }
        }
        _updateReturns(msg.sender, rnd);
        uint amount = vaults[msg.sender].totalReturns;
        require(amount > 0, "Nothing to withdraw!");
        unclaimedReturns = unclaimedReturns.sub(amount);
        vaults[msg.sender].totalReturns = 0;
        vaults[msg.sender].refReturns = 0;
        
        rnd.safeBreakers[msg.sender].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        msg.sender.transfer(amount);

        emit ReturnsWithdrawn(msg.sender, amount, now);
    }
    function hasReturns(address investor, uint roundID) public view returns (bool) {
        GameRound storage rnd = rounds[roundID];
        return rnd.cumulativeReturnsPoints > rnd.safeBreakers[investor].lastCumulativeReturnsPoints;
    }
    function updateMyReturns(uint roundID) public {
        GameRound storage rnd = rounds[roundID];
        _updateReturns(msg.sender, rnd);
    }
    
    function finalizeLastRound() public {
        GameRound storage rnd = rounds[latestRoundID];
        _finalizeRound(rnd);
    }
    function finalizeAndRestart() public payable {
        finalizeLastRound();
        startNewRound(address(0x0));
    }
    
    function finalizeAndRestart(address _referer) public payable {
        finalizeLastRound();
        startNewRound(_referer);
    }
    
    event debugLog(uint _num, string _string);
    
    function startNewRound(address _referer) public payable {
        
        require(rounds[latestRoundID].finalized, "Previous round not finalized");
        require(rounds[latestRoundID].softDeadline < now, "Previous round still running");
        
        uint _rID = rounds.length++;  
        GameRound storage rnd = rounds[_rID];
        latestRoundID = _rID;

        rnd.lastInvestor = msg.sender;
        rnd.price = STARTING_KEY_PRICE;
        rnd.hardDeadline = now + HARD_DEADLINE_DURATION;
        rnd.softDeadline = now + soft_deadline_duration;
        rnd.jackpot = jackpotSeed;
        jackpotSeed = 0; 

        _purchase(rnd, msg.value, _referer);
        emit RoundStarted(_rID, rnd.hardDeadline, now);
    }
    
    
    function buyKeys(address _referer) public payable notOnPause {
        require(msg.value >= minInvestment);
        if(rounds.length > 0) {
            GameRound storage rnd = rounds[latestRoundID];   
               
            _purchase(rnd, msg.value, _referer);            
        } else {
            revert("Not yet started");
        }
        
    }
    
    
    function _purchase(GameRound storage rnd, uint value, address referer) internal {
        require(rnd.softDeadline >= now, "After deadline!");
        require(value >= rnd.price/10, "Not enough Ether!");
        rnd.totalInvested = rnd.totalInvested.add(value);

         
        if(value >= rnd.price)
            rnd.lastInvestor = msg.sender;
        
        
        _airDrop(rnd, value);
        

        _splitRevenue(rnd, value, referer);
        
        _updateReturns(msg.sender, rnd);
        
        uint newKeys = _issueKeys(rnd, msg.sender, value);


        uint timeIncreases = newKeys/WAD; 
         
        uint newDeadline = rnd.softDeadline.add( timeIncreases.mul(TIME_PER_KEY));
        
        rnd.softDeadline = min(newDeadline, now + soft_deadline_duration);
         
        if(now > rnd.hardDeadline) {
            if(now > rnd.lastPriceIncreaseTime + PRICE_INCREASE_PERIOD) {
                rnd.price = rnd.price * 2;
                rnd.lastPriceIncreaseTime = now;
            }
        }
    }
    function _issueKeys(GameRound storage rnd, address _safeBreaker, uint value) internal returns(uint) {    
        if(rnd.safeBreakers[_safeBreaker].lastCumulativeReturnsPoints == 0) {
            rnd.safeBreakers[_safeBreaker].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
        }    
        
        uint newKeys = wdiv(value, rnd.price);
        
         
        if(value >= 100 ether) {
            newKeys = newKeys.mul(2); 
        } else if(value >= 10 ether) {
            newKeys = newKeys.add(newKeys/2); 
        } else if(value >= 1 ether) {
            newKeys = newKeys.add(newKeys/3); 
        } else if(value >= 100 finney) {
            newKeys = newKeys.add(newKeys/10); 
        }

        rnd.safeBreakers[_safeBreaker].keys = rnd.safeBreakers[_safeBreaker].keys.add(newKeys);
        rnd.totalKeys = rnd.totalKeys.add(newKeys);
        emit KeysIssued(_safeBreaker, newKeys, now);
        return newKeys;
    }    
    function _updateReturns(address _safeBreaker, GameRound storage rnd) internal {
        if(rnd.safeBreakers[_safeBreaker].keys == 0) {
            return;
        }
        
        uint outstanding = _outstandingReturns(_safeBreaker, rnd);

         
        if (outstanding > 0) {
            vaults[_safeBreaker].totalReturns = vaults[_safeBreaker].totalReturns.add(outstanding);
        }

        rnd.safeBreakers[_safeBreaker].lastCumulativeReturnsPoints = rnd.cumulativeReturnsPoints;
    }
    function _outstandingReturns(address _safeBreaker, GameRound storage rnd) internal view returns(uint) {
        if(rnd.safeBreakers[_safeBreaker].keys == 0) {
            return 0;
        }
         
        uint newReturns = rnd.cumulativeReturnsPoints.sub(
            rnd.safeBreakers[_safeBreaker].lastCumulativeReturnsPoints
            );

        uint outstanding = 0;
        if(newReturns != 0) { 
             
             
            outstanding = newReturns.mul(rnd.safeBreakers[_safeBreaker].keys) / MULTIPLIER;
        }

        return outstanding;
    }
    function _splitRevenue(GameRound storage rnd, uint value, address ref) internal {
        uint roundReturns;  
        

        if(ref != address(0x0)) {

             
            if(
                (!m_referrals[msg.sender] && limitedReferralsMode == true)
                ||
                limitedReferralsMode == false
                ) {
            
            
                uint _referralEarning = m_refPercent.mul(value);
                unclaimedReturns = unclaimedReturns.add(_referralEarning);
                vaults[ref].totalReturns = vaults[ref].totalReturns.add(_referralEarning);
                vaults[ref].refReturns = vaults[ref].refReturns.add(_referralEarning);
                
                value = value.sub(_referralEarning);
                
                m_referrals[msg.sender] = true;
                
            }
        } else {
        }
        
        roundReturns = m_investorsPercent.mul(value);  
        
        uint airdrop_value = m_airdropPercent.mul(value);
        
        uint jackpot_value = m_currentRoundJackpotPercent.mul(value);  
        
        uint dev_value = m_devPercent.mul(value);
        
        uint bankOfEth_profit = m_bankOfEthProfitPercent.mul(value);
        localBankOfEth.receiveExternalProfits.value(bankOfEth_profit)();
        
         
        if(rnd.totalKeys == 0) {
            rnd.jackpot = rnd.jackpot.add(roundReturns);
        } else {
            _disburseReturns(rnd, roundReturns);
        }
        
        rnd.airdropPot = rnd.airdropPot.add(airdrop_value);
        rnd.jackpot = rnd.jackpot.add(jackpot_value);
        
        devAddress.transfer(dev_value);
        
    }
    function _disburseReturns(GameRound storage rnd, uint value) internal {
        emit EthDistributed(value, now);
        unclaimedReturns = unclaimedReturns.add(value); 
         
         
        if(rnd.totalKeys == 0) {
             
            rnd.cumulativeReturnsPoints = value.mul(MULTIPLIER) / wdiv(value, rnd.price);
        } else {
            rnd.cumulativeReturnsPoints = rnd.cumulativeReturnsPoints.add(
                value.mul(MULTIPLIER) / rnd.totalKeys
            );
        }
    }
    function _airDrop(GameRound storage rnd, uint value) internal {
        require(msg.sender == tx.origin, "Only Humans Allowed! (or scripts that don't use smart contracts)!");
        if(value > 100 finney) {
             
            uint chance = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), now)));
            if(chance % 200 == 0) { 
                uint prize = rnd.airdropPot / 2; 
                rnd.airdropPot = rnd.airdropPot / 2;
                vaults[msg.sender].totalReturns = vaults[msg.sender].totalReturns.add(prize);
                unclaimedReturns = unclaimedReturns.add(prize);
                totalJackpotsWon += prize;
                emit AirdropWon(msg.sender, prize, now);
            }
        }
    }
    
    
    function _finalizeRound(GameRound storage rnd) internal {
        require(!rnd.finalized, "Already finalized!");
        require(rnd.softDeadline < now, "Round still running!");


         
        vaults[rnd.lastInvestor].totalReturns = vaults[rnd.lastInvestor].totalReturns.add(rnd.jackpot);
        unclaimedReturns = unclaimedReturns.add(rnd.jackpot);
        
        emit JackpotWon(rnd.lastInvestor, rnd.jackpot, now);
        totalJackpotsWon += rnd.jackpot;
         
        jackpotSeed = jackpotSeed.add( m_nextRoundSeedPercent.mul(rnd.totalInvested));
            
         
        jackpotSeed = jackpotSeed.add(rnd.airdropPot);
        
         
         
        
         
        
         
         
        totalKeysSold += rnd.totalKeys;
        totalEarningsGenerated += m_currentRoundJackpotPercent.mul(rnd.totalInvested);

        rnd.finalized = true;
    }
    
     
    function p_setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    function p_setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    function p_setCurrentRoundJackpotPercent(uint num, uint dem) public onlyOwner {
        m_currentRoundJackpotPercent = Percent.percent(num, dem);
    }
    function p_setInvestorsPercent(uint num, uint dem) public onlyOwner {
        m_investorsPercent = Percent.percent(num, dem);
    }
    function p_setDevPercent(uint num, uint dem) public onlyOwner {
        m_devPercent = Percent.percent(num, dem);
    }
    function p_setNextRoundSeedPercent(uint num, uint dem) public onlyOwner {
        m_nextRoundSeedPercent = Percent.percent(num, dem);
    }
    function p_setAirdropPercent(uint num, uint dem) public onlyOwner {
        m_airdropPercent = Percent.percent(num, dem);
    }
    function p_setBankOfEthProfitPercent(uint num, uint dem) public onlyOwner {
        m_bankOfEthProfitPercent = Percent.percent(num, dem);
    }
    function p_setMinInvestment(uint _minInvestment) public onlyOwner {
        minInvestment = _minInvestment;
    }
    function p_setMaxInvestment(uint _maxInvestment) public onlyOwner {
        maxInvestment = _maxInvestment;
    }
    function p_setGamePaused(bool _gamePaused) public onlyOwner {
        gamePaused = _gamePaused;
    }
    function p_setRoundDuration(uint256 _roundDuration) public onlyOwner {
        roundDuration = _roundDuration;
    }
    function p_setBankOfEthAddress(address _bankOfEthAddress) public onlyOwner {
        bankOfEthAddress = _bankOfEthAddress;
        localBankOfEth = BankOfEth(bankOfEthAddress);
    }
    function p_setLimitedReferralsMode(bool _limitedReferralsMode) public onlyOwner {
        limitedReferralsMode = _limitedReferralsMode;
    }
    function p_setSoft_deadline_duration(uint _soft_deadline_duration) public onlyOwner {
        soft_deadline_duration = _soft_deadline_duration;
    }
     
    function notZeroAndNotSender(address addr) internal view returns(bool) {
        return addr.notZero() && addr != msg.sender;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(y).add(WAD/2) / WAD;
         
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(y).add(RAY/2) / RAY;
         
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(WAD).add(y/2)/y;
         
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(RAY).add(y/2)/y;
         
    }
    
    uint op;
    function gameOp() public {
        op++;
    }

}