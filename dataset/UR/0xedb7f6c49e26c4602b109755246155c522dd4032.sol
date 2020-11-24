 

pragma solidity ^0.4.18;

 

 
 
 


contract Owned {
  address public owner;

  function Owned() internal{
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
}

 
 
 
 
 
contract IAMEPrivateSale is Owned {
   
   
   
   
   
   
   
   

   
  uint256 public totalFunding;

   
  uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 1 ether;

   
  uint256 public PRIVATESALE_START_DATE;
  uint256 public PRIVATESALE_END_DATE;

   
  function IAMEPrivateSale() public{
    PRIVATESALE_START_DATE = now + 5 days;  
    PRIVATESALE_END_DATE = now + 40 days;
  }

   
   
   
   
  mapping (address => uint256) public balanceOf;

   
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


   
   
   
   
   
   
   
   
  function () public payable {
     
    if (now < PRIVATESALE_START_DATE) revert();
     
    if (now > PRIVATESALE_END_DATE) revert();
     
    if (msg.value < MINIMUM_PARTICIPATION_AMOUNT) revert();
     
    addBalance(msg.sender, msg.value);
  }

   
  function ownerWithdraw(uint256 value) external onlyOwner {
    if (!owner.send(value)) revert();
  }

   
  function addBalance(address participant, uint256 value) private {
     
    balanceOf[participant] = safeIncrement(balanceOf[participant], value);
     
    totalFunding = safeIncrement(totalFunding, value);
     
    LogParticipation(participant, value, now);
  }

   
   
  function safeIncrement(uint256 base, uint256 increment) private pure returns (uint256) {
    uint256 result = base + increment;
    if (result < base) revert();
    return result;
  }

}