 

pragma solidity 0.4.25;

library Math {
    function min(uint a, uint b) internal pure returns(uint) {
        if (a > b) {
            return b;
    }
        return a;
    }
}


library Zero {
    function requireNotZero(address addr) internal pure {
        require(addr != address(0), "require not zero address");
    }

    function requireNotZero(uint val) internal pure {
        require(val != 0, "require not zero value");
    }

    function notZero(address addr) internal pure returns(bool) {
        return !(addr == address(0));
    }

    function isZero(address addr) internal pure returns(bool) {
        return addr == address(0);
    }

    function isZero(uint a) internal pure returns(bool) {
        return a == 0;
    }

    function notZero(uint a) internal pure returns(bool) {
        return a != 0;
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
      if (b >= a) {
        return 0;
      }
      return a - b;
    }

    function add(percent storage p, uint a) internal view returns (uint) {
      return a + mul(p, a);
    }

    function toMemory(percent storage p) internal view returns (Percent.percent memory) {
      return Percent.percent(p.num, p.den);
    }

     
    function mmul(percent memory p, uint a) internal pure returns (uint) {
      if (a == 0) {
        return 0;
      }
      return a*p.num/p.den;
    }

    function mdiv(percent memory p, uint a) internal pure returns (uint) {
      return a/p.num*p.den;
    }

    function msub(percent memory p, uint a) internal pure returns (uint) {
      uint b = mmul(p, a);
      if (b >= a) {
        return 0;
      }
      return a - b;
    }

    function madd(percent memory p, uint a) internal pure returns (uint) {
      return a + mmul(p, a);
    }
}


library Address {
    function toAddress(bytes source) internal pure returns(address addr) {
      assembly { addr := mload(add(source,0x14)) }
      return addr;
    }

    function isNotContract(address addr) internal view returns(bool) {
      uint length;
      assembly { length := extcodesize(addr) }
      return length == 0;
    }
}


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
       
       
       
        if (_a == 0) {
          return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
      uint256 c = _a + _b;
      require(c >= _a);

      return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract Accessibility {
    address private owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    constructor() public {
      owner = msg.sender;
    }

    function disown() internal {
      delete owner;
    }
}

contract InvestorsStorage is Accessibility {
    using SafeMath for uint;
    struct Investor {
        uint investment;
        uint paymentTime;
        uint maxPayout; 
        bool exit;
    }

    uint public size;

    mapping (address => Investor) private investors;

    function isInvestor(address addr) public view returns (bool) {
      return investors[addr]. investment > 0;
    }

    function investorInfo(address addr) public view returns(uint investment, uint paymentTime,uint maxPayout,bool exit) {
        investment = investors[addr].investment;
        paymentTime = investors[addr].paymentTime;
        maxPayout = investors[addr].maxPayout;
        exit = investors[addr].exit;
    }

    function newInvestor(address addr, uint investment, uint paymentTime) public onlyOwner returns (bool) {
         
        Investor storage inv = investors[addr];
        if (inv.investment != 0 || investment == 0) {
            return false;
        }
        inv.exit = false;
        inv.investment = investment; 
        inv.maxPayout = investment.mul(2); 
        inv.paymentTime = paymentTime;
        size++;
        return true;
    }

    function addInvestment(address addr, uint investment,uint dividends) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].investment += investment;

         
        investors[addr].maxPayout += (investment-dividends).mul(2);
        return true;
    }

    function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
        if(investors[addr].exit){
            return true;
        }
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].paymentTime = paymentTime;
        return true;
    }
    function investorExit(address addr)  public onlyOwner returns (bool){
        investors[addr].exit = true;
        investors[addr].maxPayout = 0;
        investors[addr].investment = 0;
    }
    function payout(address addr, uint dividend) public onlyOwner returns (uint) {
        uint dividendToPay = 0;
        if(investors[addr].maxPayout <= dividend){
            dividendToPay = investors[addr].maxPayout;
            investorExit(addr);
        } else{
            dividendToPay = dividend;
            investors[addr].maxPayout -= dividend;
      }
        return dividendToPay;
    }
}


library RapidGrowthProtection {
  using RapidGrowthProtection for rapidGrowthProtection;

  struct rapidGrowthProtection {
    uint startTimestamp;
    uint maxDailyTotalInvestment;
    uint8 activityDays;
    mapping(uint8 => uint) dailyTotalInvestment;
  }

  function maxInvestmentAtNow(rapidGrowthProtection storage rgp) internal view returns(uint) {
    uint day = rgp.currDay();
    if (day == 0 || day > rgp.activityDays) {
      return 0;
    }
    if (rgp.dailyTotalInvestment[uint8(day)] >= rgp.maxDailyTotalInvestment) {
      return 0;
    }
    return rgp.maxDailyTotalInvestment - rgp.dailyTotalInvestment[uint8(day)];
  }

    function isActive(rapidGrowthProtection storage rgp) internal view returns(bool) {
        uint day = rgp.currDay();
        return day != 0 && day <= rgp.activityDays;
    }

  function saveInvestment(rapidGrowthProtection storage rgp, uint investment) internal returns(bool) {
    uint day = rgp.currDay();
    if (day == 0 || day > rgp.activityDays) {
      return false;
    }
    if (rgp.dailyTotalInvestment[uint8(day)] + investment > rgp.maxDailyTotalInvestment) {
      return false;
    }
    rgp.dailyTotalInvestment[uint8(day)] += investment;
    return true;
  }

  function startAt(rapidGrowthProtection storage rgp, uint timestamp) internal {
    rgp.startTimestamp = timestamp;

     
    for (uint8 i = 1; i <= rgp.activityDays; i++) {
      if (rgp.dailyTotalInvestment[i] != 0) {
        delete rgp.dailyTotalInvestment[i];
      }
    }
  }

  function currDay(rapidGrowthProtection storage rgp) internal view returns(uint day) {
    if (rgp.startTimestamp > now) {
      return 0;
    }
    day = (now - rgp.startTimestamp) / 24 hours + 1;  
  }
}


library BonusPool {
    using BonusPool for bonusPool;
    struct bonusLevel {
        uint bonusAmount;
        bool triggered;
        uint triggeredTimestamp; 
        bool bonusSet;
    }

    struct bonusPool {
        uint8 nextLevelToTrigger;
        mapping(uint8 => bonusLevel) bonusLevels;
    }

    function setBonus(bonusPool storage self,uint8 level,uint amount) internal {
        require(!self.bonusLevels[level].bonusSet,"Bonus already set");
        self.bonusLevels[level].bonusAmount = amount;
        self.bonusLevels[level].bonusSet = true;
        self.bonusLevels[level].triggered = false;
    }
    
    function hasMetBonusTriggerLevel(bonusPool storage self) internal returns(bool){
        bonusLevel storage nextBonusLevel = self.bonusLevels[self.nextLevelToTrigger];
        if(address(this).balance >= nextBonusLevel.bonusAmount){
            if(nextBonusLevel.triggered){
                self.goToNextLevel();
                return false;
            }
            return true;
        }
        return false;
    }

    function prizeToPool(bonusPool storage self) internal returns(uint){
        return self.bonusLevels[self.nextLevelToTrigger].bonusAmount;
    }

    function goToNextLevel(bonusPool storage self) internal {
        self.bonusLevels[self.nextLevelToTrigger].triggered = true;
        self.nextLevelToTrigger += 1;
    }
}





contract Myethsss is Accessibility {
    using RapidGrowthProtection for RapidGrowthProtection.rapidGrowthProtection;
    using BonusPool for BonusPool.bonusPool;
    using Percent for Percent.percent;
    using SafeMath for uint;
    using Math for uint;

     
    using Address for *;
    using Zero for *;

    RapidGrowthProtection.rapidGrowthProtection private m_rgp;
    BonusPool.bonusPool private m_bonusPool;
    mapping(address => bool) private m_referrals;
    InvestorsStorage private m_investors;
    uint totalRealBalance;
     
    uint public constant minInvesment = 0.1 ether;  
    uint public constant maxBalance = 366e5 ether;  
    address public advertisingAddress;
    address public adminsAddress;
    address public riskAddress;
    address public bonusAddress;
    uint public investmentsNumber;
    uint public waveStartup;

   
    Percent.percent private m_1_percent = Percent.percent(1, 100);            
    Percent.percent private m_1_66_percent = Percent.percent(166, 10000);            
    Percent.percent private m_2_66_percent = Percent.percent(266, 10000);     
    Percent.percent private m_6_66_percent = Percent.percent(666, 10000);     
    Percent.percent private m_adminsPercent = Percent.percent(5, 100);        
    Percent.percent private m_advertisingPercent = Percent.percent(5, 100);  
    Percent.percent private m_riskPercent = Percent.percent(5, 100);  
    Percent.percent private m_bonusPercent = Percent.percent(666, 10000);            

    modifier balanceChanged {
        _;
    }

    modifier notFromContract() {
        require(msg.sender.isNotContract(), "only externally accounts");
        _;
    }

    constructor() public {
        adminsAddress = msg.sender;
        advertisingAddress = msg.sender;
        riskAddress=msg.sender;
        bonusAddress = msg.sender;
        nextWave();
    }

    function() public payable {
        if (msg.value.isZero()) {
            getMyDividends();
            return;
        }
        doInvest(msg.data.toAddress());
    }

    function doDisown() public onlyOwner {
        disown();
    }
 
    function init() public onlyOwner {
        m_rgp.startTimestamp = now + 1;
        m_rgp.maxDailyTotalInvestment = 5000 ether;
        m_rgp.activityDays = 21;
         
        m_bonusPool.setBonus(0,3000 ether);
        m_bonusPool.setBonus(1,6000 ether);
        m_bonusPool.setBonus(2,10000 ether);
        m_bonusPool.setBonus(3,15000 ether);
        m_bonusPool.setBonus(4,20000 ether);
        m_bonusPool.setBonus(5,25000 ether);
        m_bonusPool.setBonus(6,30000 ether);
        m_bonusPool.setBonus(7,35000 ether);
        m_bonusPool.setBonus(8,40000 ether);
        m_bonusPool.setBonus(9,45000 ether);
        m_bonusPool.setBonus(10,50000 ether);
        m_bonusPool.setBonus(11,60000 ether);
        m_bonusPool.setBonus(12,70000 ether);
        m_bonusPool.setBonus(13,80000 ether);
        m_bonusPool.setBonus(14,90000 ether);
        m_bonusPool.setBonus(15,100000 ether);
        m_bonusPool.setBonus(16,150000 ether);
        m_bonusPool.setBonus(17,200000 ether);
        m_bonusPool.setBonus(18,500000 ether);
        m_bonusPool.setBonus(19,1000000 ether);




    }

    function getBonusAmount(uint8 level) public view returns(uint){
        return m_bonusPool.bonusLevels[level].bonusAmount;
        
    }
    function doBonusPooling() public onlyOwner {
        require(m_bonusPool.hasMetBonusTriggerLevel(),"Has not met next bonus requirement");
        bonusAddress.transfer(m_bonusPercent.mul(m_bonusPool.prizeToPool()));
        m_bonusPool.goToNextLevel();
    }

    function setAdvertisingAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        advertisingAddress = addr;
    }

    function setAdminsAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        adminsAddress = addr;
    }

    function setRiskAddress(address addr) public onlyOwner{
        addr.requireNotZero();
        riskAddress=addr;
    }

    function setBonusAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        bonusAddress = addr;
    }


    function rapidGrowthProtectionmMaxInvestmentAtNow() public view returns(uint investment) {
        investment = m_rgp.maxInvestmentAtNow();
    }

    function investorsNumber() public view returns(uint) {
        return m_investors.size();
    }

    function balanceETH() public view returns(uint) {
        return address(this).balance;
    }

    function percent1() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_percent.num, m_1_percent.den);
    }

    function percent2() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_66_percent.num, m_1_66_percent.den);
    }

    function percent3_33() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_2_66_percent.num, m_2_66_percent.den);
    }

    function advertisingPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_advertisingPercent.num, m_advertisingPercent.den);
    }

    function adminsPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
    }
    function riskPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_riskPercent.num, m_riskPercent.den);
    }

    function investorInfo(address investorAddr) public view returns(uint investment, uint paymentTime,uint maxPayout,bool exit, bool isReferral) {
        (investment, paymentTime,maxPayout,exit) = m_investors.investorInfo(investorAddr);
        isReferral = m_referrals[investorAddr];
    }

    function investorDividendsAtNow(address investorAddr) public view returns(uint dividends) {
        dividends = calcDividends(investorAddr);
    }

    function dailyPercentAtNow() public view returns(uint numerator, uint denominator) {
        Percent.percent memory p = dailyPercent();
        (numerator, denominator) = (p.num, p.den);
    }

    function refBonusPercentAtNow() public view returns(uint numerator, uint denominator) {
        Percent.percent memory p = refBonusPercent();
        (numerator, denominator) = (p.num, p.den);
    }

    function getMyDividends() public notFromContract balanceChanged {
       
        uint dividends = calcDividends(msg.sender);
        require (dividends.notZero(), "cannot pay zero dividends");
         
        dividends = m_investors.payout(msg.sender,dividends);
             
        assert(m_investors.setPaymentTime(msg.sender, now));
       
        if (address(this).balance <= dividends) {
                 
            dividends = address(this).balance;
        }

       
        msg.sender.transfer(dividends);
    }

    function doInvest(address referrerAddr) public payable notFromContract balanceChanged {
        uint investment = msg.value;
        uint receivedEther = msg.value;
        require(investment >= minInvesment, "investment must be >= minInvesment");
        require(address(this).balance <= maxBalance, "the contract eth balance limit");

        if (m_rgp.isActive()) {
         
            uint rpgMaxInvest = m_rgp.maxInvestmentAtNow();
            rpgMaxInvest.requireNotZero();
            investment = Math.min(investment, rpgMaxInvest);
            assert(m_rgp.saveInvestment(investment));

      } 

       
        if (receivedEther > investment) {
            uint excess = receivedEther - investment;
            msg.sender.transfer(excess);
            receivedEther = investment;
      }

       
        advertisingAddress.transfer(m_advertisingPercent.mul(receivedEther));
        adminsAddress.transfer(m_adminsPercent.mul(receivedEther));
        riskAddress.transfer(m_riskPercent.mul(receivedEther));

        bool senderIsInvestor = m_investors.isInvestor(msg.sender);

       
        if (referrerAddr.notZero() && !senderIsInvestor && !m_referrals[msg.sender] &&
            referrerAddr != msg.sender && m_investors.isInvestor(referrerAddr)) {

            m_referrals[msg.sender] = true;
             
            uint refBonus = refBonusPercent().mmul(investment);
             
            uint refBonuss = refBonusPercentt().mmul(investment);
             
            investment += refBonuss;
             
            referrerAddr.transfer(refBonus);                                    
             
        }

       
        uint dividends = calcDividends(msg.sender);
        if (senderIsInvestor && dividends.notZero()) {
            investment += dividends;
        }

        if (senderIsInvestor) {
                 
            assert(m_investors.addInvestment(msg.sender, investment, dividends));
            assert(m_investors.setPaymentTime(msg.sender, now));
        } else {
             
            assert(m_investors.newInvestor(msg.sender, investment, now));
        }

        investmentsNumber++;
    }

    function getMemInvestor(address investorAddr) internal view returns(InvestorsStorage.Investor memory) {
        (uint investment, uint paymentTime,uint maxPayout,bool exit) = m_investors.investorInfo(investorAddr);
        return InvestorsStorage.Investor(investment, paymentTime,maxPayout,exit);
    }

    function calcDividends(address investorAddr) internal view returns(uint dividends) {
        InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

       
        if (investor.investment.isZero()
         
        ) {
            return 0;
        }

         
         

         
         

         
        Percent.percent memory p = dailyPercent();
         
        dividends = ((now - investor.paymentTime) / 10 minutes) * (p.mmul(investor.investment) / 144);
       
    }

    function dailyPercent() internal view returns(Percent.percent memory p) {
        uint balance = address(this).balance;

       
    
       

        if (balance < 50000 ether) {
            p = m_1_66_percent.toMemory();     
        } else {
            p = m_1_percent.toMemory();     
        }
    }

    function refBonusPercent() internal view returns(Percent.percent memory p) {
       
      p = m_6_66_percent.toMemory();
    }

function refBonusPercentt() internal view returns(Percent.percent memory p) {
       
      p = m_2_66_percent.toMemory();
    }

    function nextWave() private {
        m_investors = new InvestorsStorage();
        investmentsNumber = 0;
        waveStartup = now;
        m_rgp.startAt(now);
    }
}