 

pragma solidity ^0.4.23;

 



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

contract BankOfEth {
    
    using SafeMath for uint256;
    using Percent for Percent.percent;
    using Zero for *;
    using ToAddress for *;

     
    event LogPayDividendsOutOfFunds(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    event LogPayDividendsSuccess(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    event LogInvestmentWithdrawn(address sender, uint256 total_value, uint256 timestamp);
    event LogReceiveExternalProfits(address sender, uint256 total_value, uint256 timestamp);
    event LogInsertInvestor(address sender, uint256 keyIndex, uint256 init_value, uint256 timestamp);
    event LogInvestment(address sender, uint256 total_value, uint256 value_after, uint16 profitDay, address referer, uint256 timestamp);
    event LogPayDividendsReInvested(address sender, uint256 total_value, uint256 total_refBonus, uint256 timestamp);
    
    
    address owner;
    address devAddress;
    
     
    Percent.percent private m_devPercent = Percent.percent(15, 100);  
    Percent.percent private m_investorFundPercent = Percent.percent(5, 100);  
    Percent.percent private m_refPercent = Percent.percent(3, 100);  
    Percent.percent private m_devPercent_out = Percent.percent(15, 100);  
    Percent.percent private m_investorFundPercent_out = Percent.percent(5, 100);  
    
    uint256 public minInvestment = 10 finney;  
    uint256 public maxInvestment = 2000 ether; 
    uint256 public gameDuration = (24 hours);
    bool public gamePaused = false;
    
     
    struct investor {
        uint256 keyIndex;
        uint256 value;
        uint256 refBonus;
        uint16 startDay;
        uint16 lastDividendDay;
        uint16 investmentsMade;
    }
    struct iteratorMap {
        mapping(address => investor) data;
        address[] keys;
    }
    iteratorMap private investorMapping;
    
    mapping(address => bool) private m_referrals;  
    
     
    struct profitDay {
        uint256 dailyProfit;
        uint256 dailyInvestments;  
        uint256 dayStartTs;
        uint16 day;
    }
    
     
    profitDay[] public profitDays;
    uint16 public currentProfitDay;

    uint256 public dailyInvestments;
    uint256 public totalInvestments;
    uint256 public totalInvestmentFund;
    uint256 public totalProfits;
    uint256 public latestKeyIndex;
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notOnPause() {
        require(gamePaused == false, "Game Paused");
        _;
    }
    
    modifier checkDayRollover() {
        
        if(now.sub(profitDays[currentProfitDay].dayStartTs).div(gameDuration) > 0) {
            currentProfitDay++;
            dailyInvestments = 0;
            profitDays.push(profitDay(0,0,now,currentProfitDay));
        }
        _;
    }

    
    constructor() public {

        owner = msg.sender;
        devAddress = msg.sender;
        investorMapping.keys.length++;
        profitDays.push(profitDay(0,0,now,0));
        currentProfitDay = 0;
        dailyInvestments = 0;
        totalInvestments = 0;
        totalInvestmentFund = 0;
        totalProfits = 0;
        latestKeyIndex = 1;
    }
    
    function() public payable {

        if (msg.value == 0)
            withdrawDividends();
        else 
        {
            address a = msg.data.toAddr();
            address refs;
            if (a.notZero()) {
                refs = a;
                invest(refs); 
            } else {
                invest(refs);
            }
        }
    }
    
    function reinvestDividends() public {
        require(investor_contains(msg.sender));

        uint total_value;
        uint total_refBonus;
        
        (total_value, total_refBonus) = getDividends(false, msg.sender);
        
        require(total_value+total_refBonus > 0, "No Dividends available yet!");
        
        investorMapping.data[msg.sender].value = investorMapping.data[msg.sender].value.add(total_value + total_refBonus);
        
        
        
        investorMapping.data[msg.sender].lastDividendDay = currentProfitDay;
        investor_clearRefBonus(msg.sender);
        emit LogPayDividendsReInvested(msg.sender, total_value, total_refBonus, now);
        
    }
    
    
    function withdrawDividends() public {
        require(investor_contains(msg.sender));

        uint total_value;
        uint total_refBonus;
        
        (total_value, total_refBonus) = getDividends(false, msg.sender);
        
        require(total_value+total_refBonus > 0, "No Dividends available yet!");
        
        uint16 _origLastDividendDay = investorMapping.data[msg.sender].lastDividendDay;
        
        investorMapping.data[msg.sender].lastDividendDay = currentProfitDay;
        investor_clearRefBonus(msg.sender);
        
        if(total_refBonus > 0) {
            investorMapping.data[msg.sender].refBonus = 0;
            if (msg.sender.send(total_value+total_refBonus)) {
                emit LogPayDividendsSuccess(msg.sender, total_value, total_refBonus, now);
            } else {
                investorMapping.data[msg.sender].lastDividendDay = _origLastDividendDay;
                investor_addRefBonus(msg.sender, total_refBonus);
            }
        } else {
            if (msg.sender.send(total_value)) {
                emit LogPayDividendsSuccess(msg.sender, total_value, 0, now);
            } else {
                investorMapping.data[msg.sender].lastDividendDay = _origLastDividendDay;
                investor_addRefBonus(msg.sender, total_refBonus);
            }
        }
    }
    
    function showLiveDividends() public view returns(uint256 total_value, uint256 total_refBonus) {
        require(investor_contains(msg.sender));
        return getDividends(true, msg.sender);
    }
    
    function showDividendsAvailable() public view returns(uint256 total_value, uint256 total_refBonus) {
        require(investor_contains(msg.sender));
        return getDividends(false, msg.sender);
    }


    function invest(address _referer) public payable notOnPause checkDayRollover {
        require(msg.value >= minInvestment);
        require(msg.value <= maxInvestment);
        
        uint256 devAmount = m_devPercent.mul(msg.value);
        
        
         
         
         

         
        if(!m_referrals[msg.sender]) {
            if(notZeroAndNotSender(_referer) && investor_contains(_referer)) {
                 
                 
                uint256 _reward = m_refPercent.mul(msg.value);
                devAmount.sub(_reward);
                assert(investor_addRefBonus(_referer, _reward));
                m_referrals[msg.sender] = true;

                
            }
        }
        
         
        
        devAddress.transfer(devAmount);
        uint256 _profit = m_investorFundPercent.mul(msg.value);
        profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(_profit);
        
        totalProfits = totalProfits.add(_profit);

        uint256 _investorVal = msg.value;
        _investorVal = _investorVal.sub(m_devPercent.mul(msg.value));
        _investorVal = _investorVal.sub(m_investorFundPercent.mul(msg.value));
        
        if(investor_contains(msg.sender)) {
            investorMapping.data[msg.sender].value += _investorVal;
            investorMapping.data[msg.sender].investmentsMade ++;
        } else {
            assert(investor_insert(msg.sender, _investorVal));
        }
        totalInvestmentFund = totalInvestmentFund.add(_investorVal);
        profitDays[currentProfitDay].dailyInvestments = profitDays[currentProfitDay].dailyInvestments.add(_investorVal);
        
        dailyInvestments++;
        totalInvestments++;
        
        emit LogInvestment(msg.sender, msg.value, _investorVal, currentProfitDay, _referer, now);
        
    }
    
     
    function withdrawInvestment() public {
        require(investor_contains(msg.sender));
        require(investorMapping.data[msg.sender].value > 0);
        
        uint256 _origValue = investorMapping.data[msg.sender].value;
        investorMapping.data[msg.sender].value = 0;
        
         
        uint256 _amountToSend = _origValue.sub(m_devPercent_out.mul(_origValue));
        uint256 _profit = m_investorFundPercent_out.mul(_origValue);
        _amountToSend = _amountToSend.sub(m_investorFundPercent_out.mul(_profit));
        
        
        totalInvestmentFund = totalInvestmentFund.sub(_origValue);
        
        if(!msg.sender.send(_amountToSend)) {
            investorMapping.data[msg.sender].value = _origValue;
            totalInvestmentFund = totalInvestmentFund.add(_origValue);
        } else {
            
            devAddress.transfer(m_devPercent_out.mul(_origValue));
            profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(_profit);
            totalProfits = totalProfits.add(_profit);
            
            emit LogInvestmentWithdrawn(msg.sender, _origValue, now);
        }
    }
    
    
     
    function receiveExternalProfits() public payable checkDayRollover {
         
        
        profitDays[currentProfitDay].dailyProfit = profitDays[currentProfitDay].dailyProfit.add(msg.value);
        profitDays[currentProfitDay].dailyInvestments = profitDays[currentProfitDay].dailyInvestments.add(msg.value);
        emit LogReceiveExternalProfits(msg.sender, msg.value, now);
    }
    
    

     
    
    function investor_insert(address addr, uint value) internal returns (bool) {
        uint keyIndex = investorMapping.data[addr].keyIndex;
        if (keyIndex != 0) return false;  
        investorMapping.data[addr].value = value;
        keyIndex = investorMapping.keys.length++;
        investorMapping.data[addr].keyIndex = keyIndex;
        investorMapping.data[addr].startDay = currentProfitDay;
        investorMapping.data[addr].lastDividendDay = currentProfitDay;
        investorMapping.data[addr].investmentsMade = 1;
        investorMapping.keys[keyIndex] = addr;
        emit LogInsertInvestor(addr, keyIndex, value, now);
        return true;
    }
    function investor_addRefBonus(address addr, uint refBonus) internal returns (bool) {
        if (investorMapping.data[addr].keyIndex == 0) return false;
        investorMapping.data[addr].refBonus += refBonus;
        return true;
    }
    function investor_clearRefBonus(address addr) internal returns (bool) {
        if (investorMapping.data[addr].keyIndex == 0) return false;
        investorMapping.data[addr].refBonus = 0;
        return true;
    }
    function investor_contains(address addr) public view returns (bool) {
        return investorMapping.data[addr].keyIndex > 0;
    }
    function investor_getShortInfo(address addr) public view returns(uint, uint) {
        return (
          investorMapping.data[addr].value,
          investorMapping.data[addr].refBonus
        );
    }
    function investor_getMediumInfo(address addr) public view returns(uint, uint, uint16) {
        return (
          investorMapping.data[addr].value,
          investorMapping.data[addr].refBonus,
          investorMapping.data[addr].investmentsMade
        );
    }
    
     
    

    

    function p_setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    function p_setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    function p_setDevPercent(uint num, uint dem) public onlyOwner {
        m_devPercent = Percent.percent(num, dem);
    }
    function p_setInvestorFundPercent(uint num, uint dem) public onlyOwner {
        m_investorFundPercent = Percent.percent(num, dem);
    }
    function p_setDevPercent_out(uint num, uint dem) public onlyOwner {
        m_devPercent_out = Percent.percent(num, dem);
    }
    function p_setInvestorFundPercent_out(uint num, uint dem) public onlyOwner {
        m_investorFundPercent_out = Percent.percent(num, dem);
    }
    function p_setRefPercent(uint num, uint dem) public onlyOwner {
        m_refPercent = Percent.percent(num, dem);
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
    function p_setGameDuration(uint256 _gameDuration) public onlyOwner {
        gameDuration = _gameDuration;
    }

     
    function notZeroAndNotSender(address addr) internal view returns(bool) {
        return addr.notZero() && addr != msg.sender;
    }
    
    
    function getDividends(bool _includeCurrentDay, address _investor) internal view returns(uint256, uint256) {
        require(investor_contains(_investor));
        uint16 i = investorMapping.data[_investor].lastDividendDay;
        uint total_value;
        uint total_refBonus;
        total_value = 0;
        total_refBonus = 0;
        
        uint16 _option = 0;
        if(_includeCurrentDay)
            _option++;

        uint _value;
        (_value, total_refBonus) = investor_getShortInfo(_investor);

        uint256 _profitPercentageEminus7Multi = (_value*10000000 / totalInvestmentFund * 10000000) / 10000000;

        for(i; i< currentProfitDay+_option; i++) {

            if(profitDays[i].dailyProfit > 0){
                total_value = total_value.add(
                        (profitDays[i].dailyProfit / 10000000 * _profitPercentageEminus7Multi)
                    );
            }
        
        }
            
        return (total_value, total_refBonus);
    }
    uint256 a=0;
    function gameOp() public {
        a++;
    }

}