 

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

 

pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";



 
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


 
interface IDataSource {

    function read(
        TimeSeriesStateLibrary.State calldata _timeSeriesState
    )
        external
        view
        returns (uint256);

}

 

 

pragma solidity 0.5.7;







 
contract TimeSeriesFeed is
    ReentrancyGuard
{
    using SafeMath for uint256;
    using LinkedListLibraryV2 for LinkedListLibraryV2.LinkedList;

     
    uint256 public updateInterval;
    uint256 public maxDataPoints;
     
    uint256 public nextEarliestUpdate;
    string public dataDescription;
    IDataSource public dataSourceInstance;

    LinkedListLibraryV2.LinkedList private timeSeriesData;

     

     
    constructor(
        uint256 _updateInterval,
        uint256 _maxDataPoints,
        IDataSource _dataSourceAddress,
        string memory _dataDescription,
        uint256[] memory _seededValues
    )
        public
    {
         
        updateInterval = _updateInterval;
        maxDataPoints = _maxDataPoints;
        dataDescription = _dataDescription;
        dataSourceInstance = _dataSourceAddress;

        require(
            _seededValues.length > 0,
            "TimeSeriesFeed.constructor: Must include at least one seeded value."
        );

         
        timeSeriesData.initialize(_maxDataPoints, _seededValues[0]);

         
         
        for (uint256 i = 1; i < _seededValues.length; i++) {
            timeSeriesData.editList(_seededValues[i]);
        }

         
        nextEarliestUpdate = block.timestamp.add(updateInterval);
    }

     

     
    function poke()
        external
        nonReentrant
    {
         
        require(
            block.timestamp >= nextEarliestUpdate,
            "TimeSeriesFeed.poke: Not enough time elapsed since last update"
        );

        TimeSeriesStateLibrary.State memory timeSeriesState = getTimeSeriesFeedState();

         
        uint256 newValue = dataSourceInstance.read(timeSeriesState);

         
        nextEarliestUpdate = nextEarliestUpdate.add(updateInterval);

         
        timeSeriesData.editList(newValue);
    }

     
    function read(
        uint256 _numDataPoints
    )
        external
        view
        returns (uint256[] memory)
    {
        return timeSeriesData.readList(_numDataPoints);
    }

     

     
    function getTimeSeriesFeedState()
        public
        view
        returns (TimeSeriesStateLibrary.State memory)
    {
        return TimeSeriesStateLibrary.State({
            nextEarliestUpdate: nextEarliestUpdate,
            updateInterval: updateInterval,
            timeSeriesData: timeSeriesData
        });
    }
}