 

pragma solidity ^0.4.25;
 
contract Storage {
 
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
        uint strg;
        uint invested;
    }
  
    struct Data {
        mapping(uint => recordStats) stats;
        mapping(address => investor) investors;
        address[] keys;
        bestAddress bestInvestor;
        bestAddress bestPromoter;
    }

    Data private d;

     
    event LogBestInvestorChanged(address indexed addr, uint when, uint invested);
    event LogBestPromoterChanged(address indexed addr, uint when, uint refs);

     
    constructor() public {
        d.keys.length++;
    }
     
    function insert(address addr, uint value) public  returns (bool) {
        uint keyIndex = d.investors[addr].keyIndex;
        if (keyIndex != 0) return false;
        d.investors[addr].value = value;
        keyIndex = d.keys.length++;
        d.investors[addr].keyIndex = keyIndex;
        d.keys[keyIndex] = addr;
        updateBestInvestor(addr, d.investors[addr].value);
    
        return true;
    }
     
    function investorFullInfo(address addr) public view returns(uint, uint, uint, uint, uint) {
        return (
        d.investors[addr].keyIndex,
        d.investors[addr].value,
        d.investors[addr].paymentTime,
        d.investors[addr].refs,
        d.investors[addr].refBonus
        );
    }
     
    function investorBaseInfo(address addr) public view returns(uint, uint, uint, uint) {
        return (
        d.investors[addr].value,
        d.investors[addr].paymentTime,
        d.investors[addr].refs,
        d.investors[addr].refBonus
        );
    }
     
    function investorShortInfo(address addr) public view returns(uint, uint) {
        return (
        d.investors[addr].value,
        d.investors[addr].refBonus
        );
    }
     
    function getBestInvestor() public view returns(uint, address) {
        return (
        d.bestInvestor.value,
        d.bestInvestor.addr
        );
    }

     
    function getBestPromoter() public view returns(uint, address) {
        return (
        d.bestPromoter.value,
        d.bestPromoter.addr
        );
    }

     
    function addRefBonus(address addr, uint refBonus) public  returns (bool) {
        if (d.investors[addr].keyIndex == 0) return false;
        d.investors[addr].refBonus += refBonus;
        return true;
    }

     
    function addRefBonusWithRefs(address addr, uint refBonus) public  returns (bool) {
        if (d.investors[addr].keyIndex == 0) return false;
        d.investors[addr].refBonus += refBonus;
        d.investors[addr].refs++;
        updateBestPromoter(addr, d.investors[addr].refs);
        return true;
    }

     
    function addValue(address addr, uint value) public  returns (bool) {
        if (d.investors[addr].keyIndex == 0) return false;
        d.investors[addr].value += value;
        updateBestInvestor(addr, d.investors[addr].value);
        return true;
    }

     
    function updateStats(uint dt, uint invested, uint strg) public {
        d.stats[dt].invested += invested;
        d.stats[dt].strg += strg;
    }

     
    function stats(uint dt) public view returns (uint invested, uint strg) {
        return ( 
        d.stats[dt].invested,
        d.stats[dt].strg
        );
    }

     
    function updateBestInvestor(address addr, uint investorValue) internal {
        if(investorValue > d.bestInvestor.value){
            d.bestInvestor.value = investorValue;
            d.bestInvestor.addr = addr;
            emit LogBestInvestorChanged(addr, now, d.bestInvestor.value);
        }      
    }

     
    function updateBestPromoter(address addr, uint investorRefs) internal {
        if(investorRefs > d.bestPromoter.value){
            d.bestPromoter.value = investorRefs;
            d.bestPromoter.addr = addr;
            emit LogBestPromoterChanged(addr, now, d.bestPromoter.value);
        }      
    }

     
    function setPaymentTime(address addr, uint paymentTime) public  returns (bool) {
        if (d.investors[addr].keyIndex == 0) return false;
        d.investors[addr].paymentTime = paymentTime;
        return true;
    }

     
    function setRefBonus(address addr, uint refBonus) public  returns (bool) {
        if (d.investors[addr].keyIndex == 0) return false;
        d.investors[addr].refBonus = refBonus;
        return true;
    }

     
    function contains(address addr) public view returns (bool) {
        return d.investors[addr].keyIndex > 0;
    }

     
    function size() public view returns (uint) {
        return d.keys.length;
    }
}
 
contract Accessibility {

    address public owner;
     
    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }
     
    constructor() public {
        owner = msg.sender;
    }
     
    function waiver() internal {
        delete owner;
    }
}

 
contract Two4ever is Accessibility  {
     
    using Helper for *;
    using Math for *;
     
    struct percent {
        uint val;
        uint den;
    }
   
    string public  name;
   
    Storage private strg;
   
    mapping(address => address) private referrals;
   
    address public adminAddr;
   
    address public advertiseAddr;
   
    uint public waveStartup;

    uint public totalInvestors;
    uint public totalInvested;
   
   
    uint public constant minInvesment = 10 finney;  
   
    uint public constant maxBalance = 100000 ether; 
   
    uint public constant dividendsPeriod = 24 hours;  

   
     
    percent private dividends;
     
    percent private adminInterest ;
    
    percent private ref1Bonus ;
    
    percent private ref2Bonus ;
    
    percent private advertisePersent ;
     
    event LogBalanceChanged(uint when, uint balance);

   
    modifier balanceChanged {
        _;
        emit LogBalanceChanged(now, address(this).balance);
    }
     
     
    constructor()  public {
        name = "two4ever.club";
       
        adminAddr = msg.sender;
        advertiseAddr = msg.sender;
     
        dividends = percent(2, 100);  
        adminInterest = percent(5, 100);  
        ref1Bonus = percent(3, 100);  
        ref2Bonus = percent(2, 100);  
        advertisePersent = percent(7, 100);  
     
        startNewWave();
    }
     
    function setAdvertisingAddress(address addr) public onlyOwner {
        if(addr.notEmptyAddr())
        {
            advertiseAddr = addr;
        }
    }
     
    function setAdminsAddress(address addr) public onlyOwner {
        if(addr.notEmptyAddr())
        {
            adminAddr = addr;
        }
    }
     
    function doWaiver() public onlyOwner {
        waiver();
    }

     
    function() public payable {
     
        if (msg.value == 0) {
            getDividends();
            return;
        }

     
        address a = msg.data.toAddr();
     
        invest(a);
    }
     
    function _getMydividends(bool withoutThrow) private {
     
        Storage.investor memory investor = getMemInvestor(msg.sender);
     
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
            revert("the latest payment was earlier than dividends period");
        }
        assert(strg.setPaymentTime(msg.sender, now));

     
        uint value = Math.div(Math.mul(dividends.val,investor.value),dividends.den) * daysAfter;
     
        uint divid = value+ investor.refBonus; 
     
        if (address(this).balance < divid) {
            startNewWave();
            return;
        }
  
     
        if (investor.refBonus > 0) {
            assert(strg.setRefBonus(msg.sender, 0));
     
            msg.sender.transfer(value+investor.refBonus);
        } else {
     
            msg.sender.transfer(value);
        }      
    }
     
    function getDividends() public balanceChanged {
        _getMydividends(false);
    }
     
    function invest(address ref) public payable balanceChanged {
     
        require(msg.value >= minInvesment, "msg.value must be >= minInvesment");
        require(address(this).balance <= maxBalance, "the contract eth balance limit");
     
        uint value = msg.value;
     
        if (!referrals[msg.sender].notEmptyAddr()) {
       
            if (notZeroNotSender(ref) && strg.contains(ref)) {
           
                uint reward = Math.div(Math.mul(ref1Bonus.val,value),ref1Bonus.den);
                assert(strg.addRefBonusWithRefs(ref, reward));  
                referrals[msg.sender] = ref;

         
                if (notZeroNotSender(referrals[ref]) && strg.contains(referrals[ref]) && ref != referrals[ref]) { 
          
                    reward = Math.div(Math.mul(ref2Bonus.val, value),ref2Bonus.den);
                    assert(strg.addRefBonus(referrals[ref], reward));  
                }
                }else{
          
                Storage.bestAddress memory bestInvestor = getMemBestInvestor();
         
                Storage.bestAddress memory bestPromoter = getMemBestPromoter();

                if(notZeroNotSender(bestInvestor.addr)){
                    assert(strg.addRefBonus(bestInvestor.addr, Math.div(Math.mul(ref1Bonus.val, value),ref1Bonus.den)));  
                    referrals[msg.sender] = bestInvestor.addr;
                }
                if(notZeroNotSender(bestPromoter.addr)){
                    assert(strg.addRefBonus(bestPromoter.addr, Math.div(Math.mul(ref2Bonus.val, value),ref2Bonus.den)));  
                    referrals[msg.sender] = bestPromoter.addr;
                }
            }
    }

        _getMydividends(true);

     
        adminAddr.transfer(Math.div(Math.mul(adminInterest.val, msg.value),adminInterest.den));
     
        advertiseAddr.transfer(Math.div(Math.mul(advertisePersent.val, msg.value),advertisePersent.den));
    
     
        if (strg.contains(msg.sender)) {
            assert(strg.addValue(msg.sender, value));
            strg.updateStats(now, value, 0);
        } else {
            assert(strg.insert(msg.sender, value));
            strg.updateStats(now, value, 1);
        }
    
        assert(strg.setPaymentTime(msg.sender, now));
     
        totalInvestors++;
     
        totalInvested += msg.value;
    }
 
     
    function investorsNumber() public view returns(uint) {
        return strg.size()-1;
     
    }
     
    function balanceETH() public view returns(uint) {
        return address(this).balance;
    }
     
    function DividendsPercent() public view returns(uint) {
        return dividends.val;
    }
     
    function AdminPercent() public view returns(uint) {
        return adminInterest.val;
    }
      
    function AdvertisePersent() public view returns(uint) {
        return advertisePersent.val;
    }
     
    function FirstLevelReferrerPercent() public view returns(uint) {
        return ref1Bonus.val; 
    }
     
    function SecondLevelReferrerPercent() public view returns(uint) {
        return ref2Bonus.val;
    }
     
    function statistic(uint date) public view returns(uint amount, uint user) {
        (amount, user) = strg.stats(date);
    }
     
    function investorInfo(address addr) public view returns(uint value, uint paymentTime, uint refsCount, uint refBonus, bool isReferral) {
        (value, paymentTime, refsCount, refBonus) = strg.investorBaseInfo(addr);
        isReferral = referrals[addr].notEmptyAddr();
    }
   
    function bestInvestor() public view returns(uint invested, address addr) {
        (invested, addr) = strg.getBestInvestor();
    }
   
    function bestPromoter() public view returns(uint refs, address addr) {
        (refs, addr) = strg.getBestPromoter();
    }
   
    function getMemInvestor(address addr) internal view returns(Storage.investor) {
        (uint a, uint b, uint c, uint d, uint e) = strg.investorFullInfo(addr);
        return Storage.investor(a, b, c, d, e);
    }
   
    function getMemBestInvestor() internal view returns(Storage.bestAddress) {
        (uint value, address addr) = strg.getBestInvestor();
        return Storage.bestAddress(value, addr);
    }
   
    function getMemBestPromoter() internal view returns(Storage.bestAddress) {
        (uint value, address addr) = strg.getBestPromoter();
        return Storage.bestAddress(value, addr);
    }
     
    function notZeroNotSender(address addr) internal view returns(bool) {
        return addr.notEmptyAddr() && addr != msg.sender;
    }

 
 
    function startNewWave() private {
        strg = new Storage();
        totalInvestors = 0;
        waveStartup = now;
    }
}

 
library Math {
     
    function mul(uint256 num1, uint256 num2) internal pure returns (uint256) {
        return  num1 * num2;
        if (num1 == 0) {
            return 0;
        }
        return num1 * num2;   
    }
     
    function div(uint256 num1, uint256 num2) internal pure returns (uint256) {
        uint256 result = 0;
        require(num2 > 0); 
        result = num1 / num2;
        return result;
    }
     
    function sub(uint256 num1, uint256 num2) internal pure returns (uint256) {
        require(num2 <= num1);
        uint256 result = 0;
        result = num1 - num2;
        return result;
    }
     
    function add(uint256 num1, uint256 num2) internal pure returns (uint256) {
        uint256 result = num1 + num2;
        require(result >= num1);

        return result;
    }
     
    function mod(uint256 num1, uint256 num2) internal pure returns (uint256) {
        require(num2 != 0);
        return num1 % num2;
    } 
}
 
library Helper{
     
    function notEmptyAddr(address addr) internal pure returns(bool) {
        return !(addr == address(0));
    }
      
    function isEmptyAddr(address addr) internal pure returns(bool) {
        return addr == address(0);
    }
     
    function toAddr(uint source) internal pure returns(address) {
        return address(source);
    }
     
    function toAddr(bytes source) internal pure returns(address addr) {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }
}