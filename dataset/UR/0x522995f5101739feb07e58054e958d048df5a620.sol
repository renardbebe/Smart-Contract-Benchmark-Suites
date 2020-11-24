 

pragma solidity 0.4.19;

 
contract EggGiveaway {

     
    uint256 constant START_DATE = 1517572800;
    uint256 constant END_DATE = 1518177600;

     
    uint16 constant SLOT_DURATION_IN_SECONDS = 21600;

     
    mapping (uint8 => uint8) remainingFreeEggs;

     
    mapping (address => bool) eggOwners;

     
    event LogEggAcquisition(address indexed _acquirer, uint256 indexed _date);

     
    function EggGiveaway() public {
        uint256 secondsInGiveawayPeriod = END_DATE - START_DATE;
        uint8 timeSlotCount = uint8(
            secondsInGiveawayPeriod / SLOT_DURATION_IN_SECONDS
        );

        for (uint8 i = 0; i < timeSlotCount; i++) {
            remainingFreeEggs[i] = 30;
        }
    }

     
    function acquireFreeEgg() payable external {
        require(msg.value == 0);
        require(START_DATE <= now && now < END_DATE);
        require(eggOwners[msg.sender] == false);

        uint8 currentTimeSlot = getTimeSlot(now);

        require(remainingFreeEggs[currentTimeSlot] > 0);

        remainingFreeEggs[currentTimeSlot] -= 1;
        eggOwners[msg.sender] = true;

        LogEggAcquisition(msg.sender, now);
    }

     
    function () payable external {
        revert();
    }

     
    function getTimeSlot(uint256 _timestamp) private pure returns (uint8) {
        uint256 secondsSinceGiveawayStart = _timestamp - START_DATE;
        
        return uint8(secondsSinceGiveawayStart / SLOT_DURATION_IN_SECONDS);
    }
}