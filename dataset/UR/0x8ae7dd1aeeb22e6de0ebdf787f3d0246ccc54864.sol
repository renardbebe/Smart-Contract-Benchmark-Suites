 

pragma solidity ^0.4.19;

 

 

 


contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract MXLPresale is Owned {
     
     
     
     
     
     
     
     
     
     
     
     

     
    uint256 public totalFunding;

     
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 0.009 ether; 
    uint256 public constant MAXIMUM_PARTICIPATION_AMOUNT = 90 ether;

     
	 
    uint256 public constant PRESALE_MINIMUM_FUNDING = 486 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 720 ether;
	

     
     

     
	 
    uint256 public constant PRESALE_START_DATE = 1514937600;
	
	 
    uint256 public constant PRESALE_END_DATE = 1522173600;
	
	 
	 
	 
	 
	

     
     
     
     
    uint256 public constant OWNER_CLAWBACK_DATE = 1524787200; 

     
     
     
     
    mapping (address => uint256) public balanceOf;

     
     
     
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

    function MXLPresale () public payable {
		 
         
         
         
         
         
         
    }

     
     
     
     
     
     
     
     
    function () public payable {
         
        if (now < PRESALE_START_DATE) revert();
         
        if (now > PRESALE_END_DATE) revert();
         
        if (msg.value < MINIMUM_PARTICIPATION_AMOUNT) revert();
         
        if (msg.value > MAXIMUM_PARTICIPATION_AMOUNT) revert();
         
         
        if (safeIncrement(totalFunding, msg.value) > PRESALE_MAXIMUM_FUNDING) revert();
         
        addBalance(msg.sender, msg.value);
    }

     
     
    function ownerWithdraw(uint256 _value) external onlyOwner {
         
        if (totalFunding < PRESALE_MINIMUM_FUNDING) revert();
         
        if (!owner.send(_value)) revert();
    }

     
     
    function participantWithdrawIfMinimumFundingNotReached(uint256 _value) external {
         
        if (now <= PRESALE_END_DATE) revert();
         
        if (totalFunding >= PRESALE_MINIMUM_FUNDING) revert();
         
        if (balanceOf[msg.sender] < _value) revert();
         
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], _value);
         
        if (!msg.sender.send(_value)) revert();
    }

     
     
     
    function ownerClawback() external onlyOwner {
         
        if (now < OWNER_CLAWBACK_DATE) revert();
         
        if (!owner.send(this.balance)) revert();
    }

     
    function addBalance(address participant, uint256 value) private {
         
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);
         
        totalFunding = safeIncrement(totalFunding, value);
         
        LogParticipation(participant, value, now);
    }

     
    function assertEquals(uint256 expectedValue, uint256 actualValue) private pure {
        if (expectedValue != actualValue) revert();
    }

     
     
    function safeIncrement(uint256 base, uint256 increment) private pure returns (uint256) {
        uint256 result = base + increment;
        if (result < base) revert();
        return result;
    }

     
     
    function safeDecrement(uint256 base, uint256 increment) private pure returns (uint256) {
        uint256 result = base - increment;
        if (result > base) revert();
        return result;
    }
}