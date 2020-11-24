 

pragma solidity ^0.4.23;

 


 
 
 
 
 
 
 
 
 
 
 
 
 

contract ShitCloneFarmer {

    uint256 public TIME_TO_MAKE_1_SHITCLONE = 86400;
    uint256 public STARTING_SHITCLONE = 100;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = true;
    address public ShitCloneslordAddress;
    uint256 public ShitCloneslordReq = 500000;  
    mapping (address => uint256) public ballShitClone;
    mapping (address => uint256) public claimedTime;
    mapping (address => uint256) public lastEvent;
    mapping (address => address) public referrals;
    uint256 public marketTime;

    function ShitCloneFarmer() public {
        ShitCloneslordAddress = msg.sender;
    }

    function makeShitClone(address ref) public {
        require(initialized);

        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 timeUsed = getMyTime();
        uint256 newShitClone = SafeMath.div(timeUsed, TIME_TO_MAKE_1_SHITCLONE);
        ballShitClone[msg.sender] = SafeMath.add(ballShitClone[msg.sender], newShitClone);
        claimedTime[msg.sender] = 0;
        lastEvent[msg.sender] = now;
        
         
        claimedTime[referrals[msg.sender]] = SafeMath.add(claimedTime[referrals[msg.sender]], SafeMath.div(timeUsed, 5));  
        
         
        marketTime = SafeMath.add(marketTime, SafeMath.div(timeUsed, 10));  
    }

    function sellShitClones() public {
        require(initialized);

        uint256 cellCount = getMyTime();
        uint256 cellValue = calculateCellSell(cellCount);
        uint256 fee = devFee(cellValue);
        
         
        ballShitClone[msg.sender] = SafeMath.mul(SafeMath.div(ballShitClone[msg.sender], 3), 2);  
        claimedTime[msg.sender] = 0;
        lastEvent[msg.sender] = now;

         
        marketTime = SafeMath.add(marketTime, cellCount);

         
        ShitCloneslordAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(cellValue, fee));
    }

    function buyShitClones() public payable {
        require(initialized);

        uint256 timeBought = calculateCellBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        timeBought = SafeMath.sub(timeBought, devFee(timeBought));
        claimedTime[msg.sender] = SafeMath.add(claimedTime[msg.sender], timeBought);

         
        ShitCloneslordAddress.transfer(devFee(msg.value));
    }

     
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
         
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateCellSell(uint256 time) public view returns(uint256) {
        return calculateTrade(time, marketTime, this.balance);
    }

    function calculateCellBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketTime);
    }

    function calculateCellBuySimple(uint256 eth) public view returns(uint256) {
        return calculateCellBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);  
    }

    function seedMarket(uint256 time) public payable {
        require(marketTime == 0);
        require(ShitCloneslordAddress == msg.sender);
        marketTime = time;
    }

    function getFreeShitClone() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);  
        ShitCloneslordAddress.transfer(msg.value);  

        require(ballShitClone[msg.sender] == 0);
        lastEvent[msg.sender] = now;
        ballShitClone[msg.sender] = STARTING_SHITCLONE;
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

    function getMyShitClone() public view returns(uint256) {
        return ballShitClone[msg.sender];
    }

    function becomeShitClonelord() public {
        require(initialized);
        require(msg.sender != ShitCloneslordAddress);
        require(ballShitClone[msg.sender] >= ShitCloneslordReq);

        ballShitClone[msg.sender] = SafeMath.sub(ballShitClone[msg.sender], ShitCloneslordReq);
        ShitCloneslordReq = ballShitClone[msg.sender];  
        ShitCloneslordAddress = msg.sender;
    }

    function getShitClonelordReq() public view returns(uint256) {
        return ShitCloneslordReq;
    }

    function getMyTime() public view returns(uint256) {
        return SafeMath.add(claimedTime[msg.sender], getTimeSinceLastEvent(msg.sender));
    }

    function getTimeSinceLastEvent(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_MAKE_1_SHITCLONE, SafeMath.sub(now, lastEvent[adr]));
        return SafeMath.mul(secondsPassed, ballShitClone[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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