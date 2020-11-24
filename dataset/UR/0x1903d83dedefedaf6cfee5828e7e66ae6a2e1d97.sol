 

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


   
  function Ownable() public {
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

contract BatCave is Pausable {
     
    uint256 public EGGS_TO_HATCH_1BAT = 86400;
     
    uint256 public STARTING_BAT = 300;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    address public batman;
    address public superman;
    address public aquaman;
    mapping(address => uint256) public hatcheryBat;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    mapping (address => uint256) realRef;


     
    uint256 public marketEggs;

    function BatCave() public{
        paused = false;
    }

    modifier onlyDCFamily() {
      require(batman!=address(0) && superman!=address(0) && aquaman!=address(0));
      require(msg.sender == owner || msg.sender == batman || msg.sender == superman || msg.sender == aquaman);
      _;
    }

    function setBatman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      batman = _bat;
    }

    function setSuperman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      superman = _bat;
    }

    function setAquaman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      aquaman = _bat;
    }

    function setRealRef(address _ref,uint256 _isReal) public onlyOwner{
        require(_ref!=address(0));
        require(_isReal==0 || _isReal==1);
        realRef[_ref] = _isReal;
    }

    function withdraw(uint256 _percent) public onlyDCFamily {
        require(_percent>0&&_percent<=100);
        uint256 val = SafeMath.div(SafeMath.mul(address(this).balance,_percent), 300);
        if (val>0){
          batman.transfer(val);
          superman.transfer(val);
          aquaman.transfer(val);
        }
    }

     
    function hatchEggs(address ref) public whenNotPaused {
         
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
             
            if (realRef[ref] == 1){
                referrals[msg.sender] = ref;
            }else{
                referrals[msg.sender] = owner;
            }

        }
        uint256 eggsUsed = getMyEggs();
        uint256 newBat = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1BAT);
        hatcheryBat[msg.sender] = SafeMath.add(hatcheryBat[msg.sender], newBat);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

         
         
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 3));

         
         
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
        owner.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    function buyEggs() public payable whenNotPaused {
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        owner.transfer(devFee(msg.value));
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
        require(msg.value == 0.001 ether);
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