 

pragma solidity ^0.4.15;

contract Owned {
    address public owner;

    function Owned() { owner = msg.sender; }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Bounty0xPresale is Owned {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    bool private saleHasEnded = false;

     
    bool private isWhitelistingActive = true;

     
    uint256 public totalFunding;

     
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT =   0.1 ether;
    uint256 public MAXIMUM_PARTICIPATION_AMOUNT = 3.53 ether;

     
    uint256 public constant PRESALE_MINIMUM_FUNDING =  1 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 705 ether;

     
     

     
     
     
    uint256 public constant PRESALE_START_DATE = 1511186400;
    uint256 public constant PRESALE_END_DATE = PRESALE_START_DATE + 2 weeks;

     
     
     
     
    uint256 public constant OWNER_CLAWBACK_DATE = 1512306000;

     
     
     
     
    mapping (address => uint256) public balanceOf;

     
    mapping (address => bool) public earlyParticipantWhitelist;

     
     
     
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);
    
    function Bounty0xPresale () payable {
         
         
         
         
         
    }

     
     
     
     
     
     
     
     
    function () payable {
        require(!saleHasEnded);
         
        require(now > PRESALE_START_DATE);
         
        require(now < PRESALE_END_DATE);
         
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);
         
        require(msg.value <= MAXIMUM_PARTICIPATION_AMOUNT);
         
        if (isWhitelistingActive) {
            require(earlyParticipantWhitelist[msg.sender]);
        }
         
        require(safeIncrement(totalFunding, msg.value) <= PRESALE_MAXIMUM_FUNDING);
         
        addBalance(msg.sender, msg.value);    
    }
    
     
     
    function ownerWithdraw(uint256 value) external onlyOwner {
        if (totalFunding >= PRESALE_MAXIMUM_FUNDING) {
            owner.transfer(value);
            saleHasEnded = true;
        } else {
         
        require(now >= PRESALE_END_DATE);
         
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);
         
        owner.transfer(value);
    }
    }

     
     
    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {
         
        require(now >= PRESALE_END_DATE);
         
        require(totalFunding <= PRESALE_MINIMUM_FUNDING);
         
        assert(balanceOf[msg.sender] < value);
         
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], value);
         
        msg.sender.transfer(value);
    }

     
     
     
    function ownerClawback() external onlyOwner {
         
        require(now >= OWNER_CLAWBACK_DATE);
         
        owner.transfer(this.balance);
    }

     
    function setEarlyParicipantWhitelist(address addr, bool status) external onlyOwner {
        earlyParticipantWhitelist[addr] = status;
    }

     
    function whitelistFilteringSwitch() external onlyOwner {
        if (isWhitelistingActive) {
            isWhitelistingActive = false;
            MAXIMUM_PARTICIPATION_AMOUNT = 30000 ether;
        } else {
            revert();
        }
    }

     
    function addBalance(address participant, uint256 value) private {
         
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);
         
        totalFunding = safeIncrement(totalFunding, value);
         
        LogParticipation(participant, value, now);
    }

     
    function assertEquals(uint256 expectedValue, uint256 actualValue) private constant {
        assert(expectedValue == actualValue);
    }

     
     
    function safeIncrement(uint256 base, uint256 increment) private constant returns (uint256) {
        assert(increment >= base);
        return base + increment;
    }

     
     
    function safeDecrement(uint256 base, uint256 decrement) private constant returns (uint256) {
        assert(decrement <= base);
        return base - decrement;
    }
}