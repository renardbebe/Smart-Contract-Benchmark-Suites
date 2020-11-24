 

 

pragma solidity ^0.5.2;
pragma experimental "ABIEncoderV2";

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 

pragma solidity 0.5.7;




 
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;

     

     
    uint256 public timeLockPeriod;

     
    mapping(bytes32 => uint256) public timeLockedUpgrades;

     

    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );

     

    modifier timeLockUpgrade() {
         
         
        if (timeLockPeriod == 0) {
            _;

            return;
        }

         
         
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];

         
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );

         
        timeLockedUpgrades[upgradeHash] = 0;

         
        _;
    }

     

     
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        external
        onlyOwner
    {
         
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

 

 

pragma solidity 0.5.7;



 
library LinkedListLibraryV2 {

    using SafeMath for uint256;

     

    struct LinkedList{
        uint256 dataSizeLimit;
        uint256 lastUpdatedIndex;
        uint256[] dataArray;
    }

     
    function initialize(
        LinkedList storage _self,
        uint256 _dataSizeLimit,
        uint256 _initialValue
    )
        internal
    {
        require(
            _self.dataArray.length == 0,
            "LinkedListLibrary: Initialized LinkedList must be empty"
        );

         
         
        _self.dataSizeLimit = _dataSizeLimit;
        _self.dataArray.push(_initialValue);
        _self.lastUpdatedIndex = 0;
    }

     
    function editList(
        LinkedList storage _self,
        uint256 _addedValue
    )
        internal
    {
         
        _self.dataArray.length < _self.dataSizeLimit ? addNode(_self, _addedValue)
            : updateNode(_self, _addedValue);
    }

     
    function addNode(
        LinkedList storage _self,
        uint256 _addedValue
    )
        internal
    {
        uint256 newNodeIndex = _self.lastUpdatedIndex.add(1);

        require(
            newNodeIndex == _self.dataArray.length,
            "LinkedListLibrary: Node must be added at next expected index in list"
        );

        require(
            newNodeIndex < _self.dataSizeLimit,
            "LinkedListLibrary: Attempting to add node that exceeds data size limit"
        );

         
        _self.dataArray.push(_addedValue);

         
        _self.lastUpdatedIndex = newNodeIndex;
    }

     
    function updateNode(
        LinkedList storage _self,
        uint256 _addedValue
    )
        internal
    {
         
        uint256 updateNodeIndex = _self.lastUpdatedIndex.add(1) % _self.dataSizeLimit;

         
        require(
            updateNodeIndex < _self.dataArray.length,
            "LinkedListLibrary: Attempting to update non-existent node"
        );

         
        _self.dataArray[updateNodeIndex] = _addedValue;
        _self.lastUpdatedIndex = updateNodeIndex;
    }

     
    function readList(
        LinkedList storage _self,
        uint256 _dataPoints
    )
        internal
        view
        returns (uint256[] memory)
    {
        LinkedList memory linkedListMemory = _self;

        return readListMemory(
            linkedListMemory,
            _dataPoints
        );
    }

    function readListMemory(
        LinkedList memory _self,
        uint256 _dataPoints
    )
        internal
        view
        returns (uint256[] memory)
    {
         
        require(
            _dataPoints <= _self.dataArray.length,
            "LinkedListLibrary: Querying more data than available"
        );

         
        uint256[] memory outputArray = new uint256[](_dataPoints);

         
        uint256 linkedListIndex = _self.lastUpdatedIndex;
        for (uint256 i = 0; i < _dataPoints; i++) {
             
            outputArray[i] = _self.dataArray[linkedListIndex];

             
            linkedListIndex = linkedListIndex == 0 ? _self.dataSizeLimit.sub(1) : linkedListIndex.sub(1);
        }

        return outputArray;
    }

}

 

 

pragma solidity 0.5.7;



 
library TimeSeriesStateLibrary {
    struct State {
        uint256 nextEarliestUpdate;
        uint256 updateInterval;
        LinkedListLibraryV2.LinkedList timeSeriesData;
    }
}

 

 

pragma solidity 0.5.7;


 
interface ITimeSeriesFeed {

     
    function read(
        uint256 _dataDays
    )
        external
        view
        returns (uint256[] memory);

    function nextEarliestUpdate()
        external
        view
        returns (uint256);

    function updateInterval()
        external
        view
        returns (uint256);

    function getTimeSeriesFeedState()
        external
        view
        returns (TimeSeriesStateLibrary.State memory);
}

 

 

pragma solidity 0.5.7;


 
interface IMetaOracleV2 {

     
    function read(
        uint256 _dataDays
    )
        external
        view
        returns (uint256);
}

 

 

pragma solidity 0.5.7;






 
contract EMAOracle is
    TimeLockUpgrade,
    IMetaOracleV2
{
    using SafeMath for uint256;

     

    event FeedAdded(
        address indexed newFeedAddress,
        uint256 indexed emaDays
    );

    event FeedRemoved(
        address indexed removedFeedAddress,
        uint256 indexed emaDays
    );

     
    string public dataDescription;

     
    mapping(uint256 => ITimeSeriesFeed) public emaTimeSeriesFeeds;

     

     
    constructor(
        ITimeSeriesFeed[] memory _timeSeriesFeeds,
        uint256[] memory _emaTimePeriods,
        string memory _dataDescription
    )
        public
    {
        dataDescription = _dataDescription;

         
        require(
            _timeSeriesFeeds.length == _emaTimePeriods.length,
            "EMAOracle.constructor: Input lengths must be equal"
        );

         
        for (uint256 i = 0; i < _timeSeriesFeeds.length; i++) {
            uint256 emaDay = _emaTimePeriods[i];
            emaTimeSeriesFeeds[emaDay] = _timeSeriesFeeds[i];
        }
    }

     
    function read(
        uint256 _emaTimePeriod
    )
        external
        view
        returns (uint256)
    {
        ITimeSeriesFeed emaFeedInstance = emaTimeSeriesFeeds[_emaTimePeriod];

         
        require(
            address(emaFeedInstance) != address(0),
            "EMAOracle.read: Feed does not exist"
        );

         
        return emaFeedInstance.read(1)[0];
    }

     
    function addFeed(
        ITimeSeriesFeed _feedAddress,
        uint256 _emaTimePeriod
    )
        external
        onlyOwner
    {
        require(
            address(emaTimeSeriesFeeds[_emaTimePeriod]) == address(0),
            "EMAOracle.addFeed: Feed has already been added"
        );

        emaTimeSeriesFeeds[_emaTimePeriod] = _feedAddress;

        emit FeedAdded(address(_feedAddress), _emaTimePeriod);
    }

     
    function removeFeed(uint256 _emaTimePeriod)
        external
        onlyOwner
        timeLockUpgrade  
    {
        address emaTimeSeriesFeed = address(emaTimeSeriesFeeds[_emaTimePeriod]);

        require(
            emaTimeSeriesFeed != address(0),
            "EMAOracle.removeFeed: Feed does not exist."
        );

        delete emaTimeSeriesFeeds[_emaTimePeriod];

        emit FeedRemoved(emaTimeSeriesFeed, _emaTimePeriod);
    }
}