 

 

pragma solidity 0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
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
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    assert(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract ForecasterReward is Haltable {

  using SafeMath for uint;

   
  uint private startsAt;

   
  uint private endsAt;

   
  uint private weiRaised = 0;

   
  uint private investorCount = 0;
  
   
  uint private totalInvestments = 0;
  
   
  address private multisig;
 

   
  mapping (address => uint256) public investedAmountOf;

  
   
  enum State{PreFunding, Funding, Closed}

   
  event Invested(uint index, address indexed investor, uint weiAmount);

   
  event Transfer(address indexed receiver, uint weiAmount);

   
  event EndsAtChanged(uint endTimestamp);

  function ForecasterReward() public
  {

    owner = 0xed4C73Ad76D90715d648797Acd29A8529ED511A0;
    multisig = 0x177B63c7CaF85A360074bcB095952Aa8E929aE03;
    
    startsAt = 1515600000;
    endsAt = 1516118400;
  }

   
  function() nonZero payable public{
    buy(msg.sender);
  }

   
  function buy(address receiver) stopInEmergency inState(State.Funding) nonZero public payable{
    require(receiver != 0x00);
    
    uint weiAmount = msg.value;
   
    if(investedAmountOf[receiver] == 0) {
       
      investorCount++;
    }

     
    totalInvestments++;

     
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    
     
    weiRaised = weiRaised.add(weiAmount);
    
     
    if(!distributeFunds()) revert();
    
     
    Invested(totalInvestments, receiver, weiAmount);
  }

 
   
  function multisigAddress() public constant returns(address){
      return multisig;
  }
  
   
  function fundingStartAt() public constant returns(uint ){
      return startsAt;
  }
  
   
  function fundingEndsAt() public constant returns(uint){
      return endsAt;
  }
  
   
  function distinctInvestors() public constant returns(uint){
      return investorCount;
  }
  
   
  function investments() public constant returns(uint){
      return totalInvestments;
  }
  
  
   
  function distributeFunds() private returns(bool){
        
    Transfer(multisig,this.balance);
    
    if(!multisig.send(this.balance)){
      return false;
    }
    
    return true;
  }
  
   
  function setEndsAt(uint _endsAt) public onlyOwner {
    
     
    require(_endsAt > now);

    endsAt = _endsAt;
    EndsAtChanged(_endsAt);
  }

   
  function fundingRaised() public constant returns (uint){
    return weiRaised;
  }
  
  
   
  function getState() public constant returns (State) {
    if (now < startsAt) return State.PreFunding;
    else if (now <= endsAt) return State.Funding;
    else if (now > endsAt) return State.Closed;
  }

   
  function isCrowdsale() public pure returns (bool) {
    return true;
  }

   
   
   
   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

   
  modifier nonZero(){
    require(msg.value > 0);
    _;
  }
}