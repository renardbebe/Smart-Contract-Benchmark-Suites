 

pragma solidity ^0.4.25;

 


contract InvestorsStorage {
  struct investor {
    uint keyIndex;
    uint value;
    uint paymentTime;
    uint refs;
    uint refBonus;
  }
  struct bestAddress {
      uint value;
      address addr;
  }
  struct recordStats {
    uint investors;
    uint invested;
  }
  struct itmap {
    mapping(uint => recordStats) stats;
    mapping(address => investor) data;
    address[] keys;
    bestAddress bestInvestor;
    bestAddress bestPromouter;
  }
  itmap private s;
  
  address private owner;
  
  event LogBestInvestorChanged(address indexed addr, uint when, uint invested);
  event LogBestPromouterChanged(address indexed addr, uint when, uint refs);

  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  constructor() public {
    owner = msg.sender;
    s.keys.length++;
  }

  function insert(address addr, uint value) public onlyOwner returns (bool) {
    uint keyIndex = s.data[addr].keyIndex;
    if (keyIndex != 0) return false;
    s.data[addr].value = value;
    keyIndex = s.keys.length++;
    s.data[addr].keyIndex = keyIndex;
    s.keys[keyIndex] = addr;
    updateBestInvestor(addr, s.data[addr].value);
    
    return true;
  }

  function investorFullInfo(address addr) public view returns(uint, uint, uint, uint, uint) {
    return (
      s.data[addr].keyIndex,
      s.data[addr].value,
      s.data[addr].paymentTime,
      s.data[addr].refs,
      s.data[addr].refBonus
    );
  }

  function investorBaseInfo(address addr) public view returns(uint, uint, uint, uint) {
    return (
      s.data[addr].value,
      s.data[addr].paymentTime,
      s.data[addr].refs,
      s.data[addr].refBonus
    );
  }

  function investorShortInfo(address addr) public view returns(uint, uint) {
    return (
      s.data[addr].value,
      s.data[addr].refBonus
    );
  }

  function getBestInvestor() public view returns(uint, address) {
    return (
      s.bestInvestor.value,
      s.bestInvestor.addr
    );
  }
  
  function getBestPromouter() public view returns(uint, address) {
    return (
      s.bestPromouter.value,
      s.bestPromouter.addr
    );
  }

  function addRefBonus(address addr, uint refBonus) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus += refBonus;
    return true;
  }
  
  function addRefBonusWithRefs(address addr, uint refBonus) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus += refBonus;
    s.data[addr].refs++;
    updateBestPromouter(addr, s.data[addr].refs);
    
    return true;
  }

  function addValue(address addr, uint value) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].value += value;
    updateBestInvestor(addr, s.data[addr].value);
    
    return true;
  }
  
  function updateStats(uint dt, uint invested, uint investors) public {
    s.stats[dt].invested += invested;
    s.stats[dt].investors += investors;
  }
  
  function stats(uint dt) public view returns (uint invested, uint investors) {
    return ( 
      s.stats[dt].invested,
      s.stats[dt].investors
    );
  }
  
  function updateBestInvestor(address addr, uint investorValue) internal {
    if(investorValue > s.bestInvestor.value){
        s.bestInvestor.value = investorValue;
        s.bestInvestor.addr = addr;
        emit LogBestInvestorChanged(addr, now, s.bestInvestor.value);
    }      
  }
  
  function updateBestPromouter(address addr, uint investorRefs) internal {
    if(investorRefs > s.bestPromouter.value){
        s.bestPromouter.value = investorRefs;
        s.bestPromouter.addr = addr;
        emit LogBestPromouterChanged(addr, now, s.bestPromouter.value);
    }      
  }

  function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].paymentTime = paymentTime;
    return true;
  }

  function setRefBonus(address addr, uint refBonus) public onlyOwner returns (bool) {
    if (s.data[addr].keyIndex == 0) return false;
    s.data[addr].refBonus = refBonus;
    return true;
  }

  function keyFromIndex(uint i) public view returns (address) {
    return s.keys[i];
  }

  function contains(address addr) public view returns (bool) {
    return s.data[addr].keyIndex > 0;
  }

  function size() public view returns (uint) {
    return s.keys.length;
  }

  function iterStart() public pure returns (uint) {
    return 1;
  }
}


contract DT {
        struct DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint private constant DAY_IN_SECONDS = 86400;
        uint private constant YEAR_IN_SECONDS = 31536000;
        uint private constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint private constant HOUR_IN_SECONDS = 3600;
        uint private constant MINUTE_IN_SECONDS = 60;

        uint16 private constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                 
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                 
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                 
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }
        }
        
        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                 
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

}
 
contract ERC20AdToken {
    using SafeMath for uint;
    using Zero for *;

    string public symbol;
    string public  name;
    mapping (address => uint256) private balanceOf;
    mapping(address => address) public adtransfers;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
     
     
     
    constructor(string _symbol, string _name) public {
        symbol = _symbol;
        name = _name;
        balanceOf[this] = 10000000000;
        emit Transfer(address(0), this, 10000000000);
    }

    function transfer(address to, uint tokens) public returns (bool success) {
         
         
        if(!adtransfers[to].notZero()){
            adtransfers[to] = msg.sender;
            emit Transfer(this, to, tokens);
        }
        return true;
    }
    
    function massAdvertiseTransfer(address[] addresses, uint tokens) public returns (bool success) {
        for (uint i = 0; i < addresses.length; i++) {
            if(!adtransfers[addresses[i]].notZero()){
                adtransfers[addresses[i]] = msg.sender;
                emit Transfer(this, addresses[i], tokens);
            }
        }
        
        return true;
    }

    function () public payable {
        revert();
    }

}

contract EarnEveryDay_v1_355 is ERC20AdToken, DT {
  using Percent for Percent.percent;
  using SafeMath for uint;
  using Zero for *;
  using ToAddress for *;
  using Convert for *;

   
  InvestorsStorage private m_investors;
  mapping(address => address) private m_referrals;
  bool private m_nextWave;

   
  address public adminAddr;
  uint public waveStartup;
  uint public totalInvestments;
  uint public totalInvested;
  uint public constant minInvesment = 10 finney;  
  uint public constant maxBalance = 355e5 ether;  
  uint public constant dividendsPeriod = 24 hours;  

   
  Percent.percent private m_dividendsPercent = Percent.percent(355, 10000);  
  Percent.percent private m_adminPercent = Percent.percent(5, 100);  
  Percent.percent private m_refPercent1 = Percent.percent(3, 100);  
  Percent.percent private m_refPercent2 = Percent.percent(2, 100);  
  Percent.percent private m_adBonus = Percent.percent(1, 100);  

   
  event LogNewInvestor(address indexed addr, uint when, uint value);
  event LogNewInvesment(address indexed addr, uint when, uint value);
  event LogNewReferral(address indexed addr, uint when, uint value);
  event LogPayDividends(address indexed addr, uint when, uint value);
  event LogPayReferrerBonus(address indexed addr, uint when, uint value);
  event LogBalanceChanged(uint when, uint balance);
  event LogNextWave(uint when);

  modifier balanceChanged {
    _;
    emit LogBalanceChanged(now, address(this).balance);
  }

  constructor() ERC20AdToken("Earn 3.55% Every Day. https://355eth.club", 
                            "Send your ETH to this contract and earn 3.55% every day for Live-long. https://355eth.club") public {
    adminAddr = msg.sender;

    nextWave();
  }

  function() public payable {
     
    if (msg.value == 0) {
      getMyDividends();
      return;
    }

     
    address a = msg.data.toAddr();
    doInvest(a);
  }

  function investorsNumber() public view returns(uint) {
    return m_investors.size()-1;
     
  }

  function balanceETH() public view returns(uint) {
    return address(this).balance;
  }

  function dividendsPercent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_dividendsPercent.num, m_dividendsPercent.den);
  }

  function adminPercent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_adminPercent.num, m_adminPercent.den);
  }

  function referrer1Percent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_refPercent1.num, m_refPercent1.den);
  }
  
  function referrer2Percent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_refPercent2.num, m_refPercent2.den);
  }
  
  function stats(uint date) public view returns(uint invested, uint investors) {
    (invested, investors) = m_investors.stats(date);
  }

  function investorInfo(address addr) public view returns(uint value, uint paymentTime, uint refsCount, uint refBonus, bool isReferral) {
    (value, paymentTime, refsCount, refBonus) = m_investors.investorBaseInfo(addr);
    isReferral = m_referrals[addr].notZero();
  }
  
  function bestInvestorInfo() public view returns(uint invested, address addr) {
    (invested, addr) = m_investors.getBestInvestor();
  }
  
  function bestPromouterInfo() public view returns(uint refs, address addr) {
    (refs, addr) = m_investors.getBestPromouter();
  }
  
  function _getMyDividents(bool withoutThrow) private {
     
    InvestorsStorage.investor memory investor = getMemInvestor(msg.sender);
    if(investor.keyIndex <= 0){
        if(withoutThrow){
            return;
        }
        
        revert("sender is not investor");
    }

     
    uint256 daysAfter = now.sub(investor.paymentTime).div(dividendsPeriod);
    if(daysAfter <= 0){
        if(withoutThrow){
            return;
        }
        
        revert("the latest payment was earlier than dividents period");
    }
    assert(m_investors.setPaymentTime(msg.sender, now));

     
    uint value = m_dividendsPercent.mul(investor.value) * daysAfter;
    if (address(this).balance < value + investor.refBonus) {
      nextWave();
      return;
    }

     
    if (investor.refBonus > 0) {
      assert(m_investors.setRefBonus(msg.sender, 0));
      sendDividendsWithRefBonus(msg.sender, value, investor.refBonus);
    } else {
      sendDividends(msg.sender, value);
    }      
  }
  
  function getMyDividends() public balanceChanged {
    _getMyDividents(false);
  }

  function doInvest(address ref) public payable balanceChanged {
    require(msg.value >= minInvesment, "msg.value must be >= minInvesment");
    require(address(this).balance <= maxBalance, "the contract eth balance limit");

    uint value = msg.value;
     
    if (!m_referrals[msg.sender].notZero()) {
       
      if (notZeroNotSender(ref) && m_investors.contains(ref)) {
        uint reward = m_refPercent1.mul(value);
        assert(m_investors.addRefBonusWithRefs(ref, reward));  
        m_referrals[msg.sender] = ref;
        value = m_dividendsPercent.add(value);  
        emit LogNewReferral(msg.sender, now, value); 
         
        if (notZeroNotSender(m_referrals[ref]) && m_investors.contains(m_referrals[ref]) && ref != m_referrals[ref]) { 
          reward = m_refPercent2.mul(value);
          assert(m_investors.addRefBonus(m_referrals[ref], reward));  
        }
      }else{
        InvestorsStorage.bestAddress memory bestInvestor = getMemBestInvestor();
        InvestorsStorage.bestAddress memory bestPromouter = getMemBestPromouter();
        if(notZeroNotSender(bestInvestor.addr)){
          assert(m_investors.addRefBonus(bestInvestor.addr, m_refPercent1.mul(value) ));  
          m_referrals[msg.sender] = bestInvestor.addr;
        }
        if(notZeroNotSender(bestPromouter.addr)){
          assert(m_investors.addRefBonus(bestPromouter.addr, m_refPercent2.mul(value) ));  
          m_referrals[msg.sender] = bestPromouter.addr;
        }
      }
      
      if(notZeroNotSender(adtransfers[msg.sender]) && m_investors.contains(adtransfers[msg.sender])){
          assert(m_investors.addRefBonus(adtransfers[msg.sender], m_adBonus.mul(msg.value) ));  
      }
    }

    _getMyDividents(true);

     
    adminAddr.transfer(m_adminPercent.mul(msg.value));
    
    DT.DateTime memory dt = parseTimestamp(now);
    uint today = dt.year.uintToString().strConcat((dt.month<10 ? "0":""), dt.month.uintToString(), (dt.day<10 ? "0":""), dt.day.uintToString()).stringToUint();
    
     
    if (m_investors.contains(msg.sender)) {
      assert(m_investors.addValue(msg.sender, value));
      m_investors.updateStats(today, value, 0);
    } else {
      assert(m_investors.insert(msg.sender, value));
      m_investors.updateStats(today, value, 1);
      emit LogNewInvestor(msg.sender, now, value); 
    }
    
    assert(m_investors.setPaymentTime(msg.sender, now));

    emit LogNewInvesment(msg.sender, now, value);   
    totalInvestments++;
    totalInvested += msg.value;
  }


  function getMemInvestor(address addr) internal view returns(InvestorsStorage.investor) {
    (uint a, uint b, uint c, uint d, uint e) = m_investors.investorFullInfo(addr);
    return InvestorsStorage.investor(a, b, c, d, e);
  }
  
  function getMemBestInvestor() internal view returns(InvestorsStorage.bestAddress) {
    (uint value, address addr) = m_investors.getBestInvestor();
    return InvestorsStorage.bestAddress(value, addr);
  }
  
  function getMemBestPromouter() internal view returns(InvestorsStorage.bestAddress) {
    (uint value, address addr) = m_investors.getBestPromouter();
    return InvestorsStorage.bestAddress(value, addr);
  }

  function notZeroNotSender(address addr) internal view returns(bool) {
    return addr.notZero() && addr != msg.sender;
  }

  function sendDividends(address addr, uint value) private {
    if (addr.send(value)) emit LogPayDividends(addr, now, value); 
  }

  function sendDividendsWithRefBonus(address addr, uint value,  uint refBonus) private {
    if (addr.send(value+refBonus)) {
      emit LogPayDividends(addr, now, value);
      emit LogPayReferrerBonus(addr, now, refBonus);
    }
  }

  function nextWave() private {
    m_investors = new InvestorsStorage();
    totalInvestments = 0;
    waveStartup = now;
    m_nextWave = false;
    emit LogNextWave(now);
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

library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

library Convert {
    function stringToUint(string s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {  
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48);  
            }
        }
        return result;  
    }
    
    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);  
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];  
        }
        string memory str = string(s);   
        return str;  
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    
    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    
    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }
}