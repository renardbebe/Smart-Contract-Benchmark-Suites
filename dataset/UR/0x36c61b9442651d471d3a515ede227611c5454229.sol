 

pragma solidity ^0.4.18;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
  address public owner;


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    return true;
  }
}

contract LionCup is Pausable {
     
    uint256 public EGGS_TO_HATCH_1BAT = 86400;
     
    uint256 public STARTING_BAT = 500;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    mapping(address => uint256) public hatcheryBat;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public batlordReq = 500000;  
    address public batlordAddress;
    

     
    uint256 public marketEggs;
    
    constructor() public{
        paused = false;
        batlordAddress = msg.sender;
    }

    function becomeBatlord() public whenNotPaused {
        require(msg.sender != batlordAddress);
        require(hatcheryBat[msg.sender] >= batlordReq);

        hatcheryBat[msg.sender] = SafeMath.sub(hatcheryBat[msg.sender], batlordReq);
        batlordReq = hatcheryBat[msg.sender];  
        batlordAddress = msg.sender;
    }

    function getBatlordReq() public view returns(uint256) {
        return batlordReq;
    } 

    function withdraw(uint256 _percent) public onlyOwner {
        require(_percent>0&&_percent<=100);
        uint256 val = SafeMath.div(SafeMath.mul(address(this).balance,_percent), 100);
        if (val>0){
          owner.transfer(val);
        }
    }

     
    function hatchEggs(address ref) public whenNotPaused {
         
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newBat = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1BAT);
        hatcheryBat[msg.sender] = SafeMath.add(hatcheryBat[msg.sender], newBat);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

         
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 5));

         
         
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
    }

     
    function sellEggs() public whenNotPaused {
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
         
        hatcheryBat[msg.sender] = SafeMath.mul(SafeMath.div(hatcheryBat[msg.sender], 3), 2);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        batlordAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    function buyEggs() public payable whenNotPaused {
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        batlordAddress.transfer(devFee(msg.value));
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
    }
     
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
         
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

     
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

     
    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

     
     
    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        marketEggs = eggs;
    }

    function getFreeBat() public payable whenNotPaused {
        require(msg.value == 0.01 ether);
        require(hatcheryBat[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryBat[msg.sender] = STARTING_BAT;
        owner.transfer(msg.value);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMyBat() public view returns(uint256) {
        return hatcheryBat[msg.sender];
    }

    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1BAT, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryBat[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns(uint256) {
        return a < b ? a : b;
    }
}