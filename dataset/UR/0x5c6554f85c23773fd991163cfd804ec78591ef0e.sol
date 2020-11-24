 

pragma solidity 0.4.19;

 
contract Owned {
     
    address owner;

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
contract OmegaEggSale is Owned {

     
    uint256 constant START_DATE = 1518436800;

     
    uint256 constant END_DATE = 1518868800;

     
    uint16 constant SLOT_DURATION_IN_SECONDS = 7200;

     
    mapping (uint8 => uint8) remainingEggs;
    
     
    mapping (address => bool) eggOwners;

     
    event LogOmegaEggSale(address indexed _acquirer, uint256 indexed _date);

     
    function OmegaEggSale() Owned() public {
        uint256 secondsInSalePeriod = END_DATE - START_DATE;
        uint8 timeSlotCount = uint8(
            secondsInSalePeriod / SLOT_DURATION_IN_SECONDS
        );

        for (uint8 i = 0; i < timeSlotCount; i++) {
            remainingEggs[i] = 10;
        }
    }

     
    function buyOmegaEgg() payable external {
        require(msg.value >= 0.09 ether);
        require(START_DATE <= now && now < END_DATE);
        require(eggOwners[msg.sender] == false);

        uint8 currentTimeSlot = getTimeSlot(now);

        require(remainingEggs[currentTimeSlot] > 0);

        remainingEggs[currentTimeSlot] -= 1;
        eggOwners[msg.sender] = true;

        LogOmegaEggSale(msg.sender, now);
        
         
        if (msg.value > 0.09 ether) {
            msg.sender.transfer(msg.value - 0.09 ether);
        }
    }

     
    function () payable external {
        revert();
    }
    
     
    function eggsInTimeSlot(uint8 _timeSlot) view external returns (uint8) {
        return remainingEggs[_timeSlot];
    }
    
     
    function hasBoughtEgg(address _buyer) view external returns (bool) {
        return eggOwners[_buyer] == true;
    }
    
     
    function withdraw() onlyOwner external {
        require(now >= END_DATE);

        owner.transfer(this.balance);
    }

     
    function getTimeSlot(uint256 _timestamp) private pure returns (uint8) {
        uint256 secondsSinceSaleStart = _timestamp - START_DATE;
        
        return uint8(secondsSinceSaleStart / SLOT_DURATION_IN_SECONDS);
    }
}