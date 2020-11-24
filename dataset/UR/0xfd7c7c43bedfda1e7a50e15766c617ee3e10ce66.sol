 

pragma solidity ^0.4.18;  



contract VerifyToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    bool public activated;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract EthVerifyCore{
  mapping (address => bool) public verifiedUsers;
}
contract ShrimpFarmer is ApproveAndCallFallBack{
    using SafeMath for uint;
    address vrfAddress=0x5BD574410F3A2dA202bABBa1609330Db02aD64C2; 
    VerifyToken vrfcontract=VerifyToken(vrfAddress);

     
     
     
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400; 
    uint public VRF_EGG_COST=(1000000000000000000*300)/EGGS_TO_HATCH_1SHRIMP;
     
    uint256 PSN=100000000000000;
    uint256 PSNH=50000000000000;
    uint public POT_DRAIN_TIME=12 hours; 
    uint public HATCH_COOLDOWN=6 hours; 
    bool public initialized=false;
     

    address public ceoAddress;
    address public dev2;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => bool) public hasClaimedFree;
    uint256 public marketEggs;
    EthVerifyCore public ethVerify=EthVerifyCore(0x1c307A39511C16F74783fCd0091a921ec29A0b51); 

    uint public lastBidTime; 
    address public currentWinner;
     
    uint public totalHatcheryShrimp=0;
    uint public prizeEth=0; 

    function ShrimpFarmer() public{
        ceoAddress=msg.sender;
        dev2=address(0x95096780Efd48FA66483Bc197677e89f37Ca0CB5);
        lastBidTime=now;
        currentWinner=msg.sender;
    }
    function finalizeIfNecessary() public{
      if(lastBidTime.add(POT_DRAIN_TIME)<now){
        currentWinner.transfer(this.balance); 
        initialized=false;
         
      }
    }
    function getPotCost() public view returns(uint){
        return totalHatcheryShrimp.div(100);
    }
    function stealPot() public {
      finalizeIfNecessary();
      if(initialized){
          _hatchEggs(0);
          uint cost=getPotCost();
          hatcheryShrimp[msg.sender]=hatcheryShrimp[msg.sender].sub(cost); 
          totalHatcheryShrimp=totalHatcheryShrimp.add(cost);
          lastBidTime=now;
          currentWinner=msg.sender;
      }
    }
    function hatchEggs(address ref) public{
      require(lastHatch[msg.sender].add(HATCH_COOLDOWN)<now);
      _hatchEggs(ref);
    }
    function _hatchEggs(address ref) private{
        require(initialized);

        uint256 eggsUsed=getMyEggs();
        uint256 newShrimp=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1SHRIMP);
        hatcheryShrimp[msg.sender]=SafeMath.add(hatcheryShrimp[msg.sender],newShrimp);
        totalHatcheryShrimp=totalHatcheryShrimp.add(newShrimp);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;

         
        require(ref!=msg.sender);
        if(ref!=0){
          claimedEggs[ref]=claimedEggs[ref].add(eggsUsed.div(7));
        }
         
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,7));
    }

    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
         
        uint potfee=potFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
         
        prizeEth=prizeEth.add(potfee);
        msg.sender.transfer(eggValue.sub(potfee));
    }
    function buyEggs() public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        eggsBought=eggsBought.sub(devFee(eggsBought));
        eggsBought=eggsBought.sub(devFee2(eggsBought));
        ceoAddress.transfer(devFee(msg.value));
        dev2.transfer(devFee2(msg.value));
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
    }
     
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
         
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,this.balance.sub(prizeEth));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance.sub(prizeEth),marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,this.balance);
    }
    function potFee(uint amount) public view returns(uint){
        return SafeMath.div(SafeMath.mul(amount,20),100);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function devFee2(uint256 amount) public view returns(uint256){
        return SafeMath.div(amount,100);
    }
    function seedMarket(uint256 eggs) public payable{
        require(msg.sender==ceoAddress);
        require(!initialized);
         
        initialized=true;
        marketEggs=eggs;
        lastBidTime=now;
    }
     
    function setPreShrimp(address holder,uint shrimp){
      require(!initialized);
      require(msg.sender==ceoAddress);
      claimedEggs[holder]=shrimp*EGGS_TO_HATCH_1SHRIMP;
    }
     
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public{
        require(!initialized);
        require(msg.sender==vrfAddress);
        vrfcontract.transferFrom(from,this,tokens);
        claimedEggs[from]=claimedEggs[from].add(tokens.div(VRF_EGG_COST));
    }
     
    function () public payable {}

    function claimFreeEggs() public{
        require(ethVerify.verifiedUsers(msg.sender));
        require(initialized);
        require(!hasClaimedFree[msg.sender]);
        claimedEggs[msg.sender]=claimedEggs[msg.sender].add(getFreeEggs());
        hasClaimedFree[msg.sender]=true;
         
         
         
    }
    function getFreeEggs() public view returns(uint){
        return min(calculateEggBuySimple(this.balance.div(100)),calculateEggBuySimple(0.05 ether));
    }
    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getMyShrimp() public view returns(uint256){
        return hatcheryShrimp[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1SHRIMP,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryShrimp[adr]);
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