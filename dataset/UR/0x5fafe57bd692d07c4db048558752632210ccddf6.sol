 

pragma solidity 0.4.15;

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
}

contract ProvocoPresale is Owned {
     
    uint256 public totalFunding;

     
    uint256 public constant MIN_AMOUNT = 100 finney;
    uint256 public constant MAX_AMOUNT = 100 ether;

     
    uint256 public constant PRESALE_MINIMUM_FUNDING = 100 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 1000 ether;

     
     
     
    uint256 public constant PRESALE_START_DATE = 1519171201;
    uint256 public constant PRESALE_END_DATE = 1522670400;

     
     
     
     
    uint256 public constant OWNER_CLAWBACK_DATE = 1541030399;

     
     
     
     
    mapping (address => uint256) public balanceOf;

     
     
     
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

     
     
     
     
     
     
     
     
    function () payable {
         
        if (now < PRESALE_START_DATE) throw;
         
        if (now > PRESALE_END_DATE) throw;
         
        if (msg.value < MIN_AMOUNT) throw;
         
        if (msg.value > MAX_AMOUNT) throw;
         
         
        if (safeIncrement(totalFunding, msg.value) > PRESALE_MAXIMUM_FUNDING) throw;
         
        addBalance(msg.sender, msg.value);
    }

     
     
    function ownerWithdraw(uint256 value) external onlyOwner {
         
        if (totalFunding < PRESALE_MINIMUM_FUNDING) throw;
         
        if (!owner.send(value)) throw;
    }

     
     
    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {
         
        if (now <= PRESALE_END_DATE) throw;
         
        if (totalFunding >= PRESALE_MINIMUM_FUNDING) throw;
         
        if (balanceOf[msg.sender] < value) throw;
         
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], value);
         
        if (!msg.sender.send(value)) throw;
    }

     
     
     
    function ownerClawback() external onlyOwner {
         
        if (now < OWNER_CLAWBACK_DATE) throw;
         
        if (!owner.send(this.balance)) throw;
    }

     
    function addBalance(address participant, uint256 value) private {
         
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);
         
        totalFunding = safeIncrement(totalFunding, value);
         
        LogParticipation(participant, value, now);
    }

     
     
    function safeIncrement(uint256 base, uint256 increment) private constant returns (uint256) {
        uint256 result = base + increment;
        if (result < base) throw;
        return result;
    }

     
     
    function safeDecrement(uint256 base, uint256 increment) private constant returns (uint256) {
        uint256 result = base - increment;
        if (result > base) throw;
        return result;
    }
}