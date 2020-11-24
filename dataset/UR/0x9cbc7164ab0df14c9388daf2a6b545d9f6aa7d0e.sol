 

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




 
contract TimeLockUpgradeV2 is
    Ownable
{
    using SafeMath for uint256;

     

     
    uint256 public timeLockPeriod;

     
    mapping(bytes32 => uint256) public timeLockedUpgrades;

     

    event UpgradeRegistered(
        bytes32 indexed _upgradeHash,
        uint256 _timestamp,
        bytes _upgradeData
    );

    event RemoveRegisteredUpgrade(
        bytes32 indexed _upgradeHash
    );

     

    modifier timeLockUpgrade() {
        require(
            isOwner(),
            "TimeLockUpgradeV2: The caller must be the owner"
        );

         
         
        if (timeLockPeriod > 0) {
             
             
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
                    block.timestamp,
                    msg.data
                );

                return;
            }

            require(
                block.timestamp >= registrationTime.add(timeLockPeriod),
                "TimeLockUpgradeV2: Time lock period must have elapsed."
            );

             
            timeLockedUpgrades[upgradeHash] = 0;

        }

         
        _;
    }

     

     
    function removeRegisteredUpgrade(
        bytes32 _upgradeHash
    )
        external
        onlyOwner
    {
        require(
            timeLockedUpgrades[_upgradeHash] != 0,
            "TimeLockUpgradeV2.removeRegisteredUpgrade: Upgrade hash must be registered"
        );

         
        timeLockedUpgrades[_upgradeHash] = 0;

        emit RemoveRegisteredUpgrade(
            _upgradeHash
        );
    }

     
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        external
        onlyOwner
    {
         
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgradeV2: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

 

 

pragma solidity 0.5.7;



 
library DataSourceLinearInterpolationLibrary {
    using SafeMath for uint256;

     

     
    function interpolateDelayedPriceUpdate(
        uint256 _currentPrice,
        uint256 _updateInterval,
        uint256 _timeFromExpectedUpdate,
        uint256 _previousLoggedDataPoint
    )
        internal
        pure
        returns (uint256)
    {
         
        uint256 timeFromLastUpdate = _timeFromExpectedUpdate.add(_updateInterval);

         
         
        return _currentPrice.mul(_updateInterval)
            .add(_previousLoggedDataPoint.mul(_timeFromExpectedUpdate))
            .div(timeFromLastUpdate);
    }
}

 

 

pragma solidity 0.5.7;


 
interface IOracle {

     
    function read()
        external
        view
        returns (uint256);
}

 

 

pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";



 
library LinkedListLibraryV3 {

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
            "LinkedListLibrary.initialize: Initialized LinkedList must be empty"
        );

         
        require(
            _dataSizeLimit > 0,
            "LinkedListLibrary.initialize: dataSizeLimit must be greater than 0."
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

     
    function getLatestValue(
        LinkedList storage _self
    )
        internal
        view
        returns (uint256)
    {
        return _self.dataArray[_self.lastUpdatedIndex];
    }
}

 

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

 

 

pragma solidity 0.5.7;





 
contract TimeSeriesFeedV2 is
    ReentrancyGuard
{
    using SafeMath for uint256;
    using LinkedListLibraryV3 for LinkedListLibraryV3.LinkedList;

     
    uint256 public updateInterval;
    uint256 public maxDataPoints;
     
    uint256 public nextEarliestUpdate;

    LinkedListLibraryV3.LinkedList internal timeSeriesData;

     

     
    constructor(
        uint256 _updateInterval,
        uint256 _nextEarliestUpdate,
        uint256 _maxDataPoints,
        uint256[] memory _seededValues
    )
        public
    {

         
        require(
            _nextEarliestUpdate > block.timestamp,
            "TimeSeriesFeed.constructor: nextEarliestUpdate must be greater than current timestamp."
        );

         
        require(
            _seededValues.length > 0,
            "TimeSeriesFeed.constructor: Must include at least one seeded value."
        );

         
        require(
            _maxDataPoints > 0,
            "TimeSeriesFeed.constructor: Max data points must be greater than 0."
        );

         
        require(
            _updateInterval > 0,
            "TimeSeriesFeed.constructor: Update interval must be greater than 0."
        );

         
        updateInterval = _updateInterval;
        maxDataPoints = _maxDataPoints;

         
        timeSeriesData.initialize(_maxDataPoints, _seededValues[0]);

         
         
        for (uint256 i = 1; i < _seededValues.length; i++) {
            timeSeriesData.editList(_seededValues[i]);
        }

         
        nextEarliestUpdate = _nextEarliestUpdate;
    }

     

     
    function poke()
        external
        nonReentrant
    {
         
        require(
            block.timestamp >= nextEarliestUpdate,
            "TimeSeriesFeed.poke: Not enough time elapsed since last update"
        );

         
        uint256 newValue = calculateNextValue();

         
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


     

    function calculateNextValue()
        internal
        returns (uint256);

}

 

 

pragma solidity 0.5.7;








 
contract TwoAssetLinearizedTimeSeriesFeed is
    TimeSeriesFeedV2,
    TimeLockUpgradeV2
{
    using SafeMath for uint256;
    using LinkedListLibraryV3 for LinkedListLibraryV3.LinkedList;

     

     
    uint256 public interpolationThreshold;
    string public dataDescription;
    IOracle public baseOracleInstance;
    IOracle public quoteOracleInstance;


     

    event LogOracleUpdated(
        address indexed newOracleAddress
    );

     

     
    constructor(
        uint256 _updateInterval,
        uint256 _nextEarliestUpdate,
        uint256 _maxDataPoints,
        uint256[] memory _seededValues,
        uint256 _interpolationThreshold,
        IOracle _baseOracleAddress,
        IOracle _quoteOracleAddress,
        string memory _dataDescription
    )
        public
        TimeSeriesFeedV2(
            _updateInterval,
            _nextEarliestUpdate,
            _maxDataPoints,
            _seededValues
        )
    {
        interpolationThreshold = _interpolationThreshold;
        baseOracleInstance = _baseOracleAddress;
        quoteOracleInstance = _quoteOracleAddress;
        dataDescription = _dataDescription;
    }

     

     
    function changeBaseOracle(
        IOracle _newBaseOracleAddress
    )
        external
        timeLockUpgrade
    {
         
        require(
            address(_newBaseOracleAddress) != address(baseOracleInstance),
            "TwoAssetLinearizedTimeSeriesFeed.changeBaseOracle: Must give new base oracle address."
        );

        baseOracleInstance = _newBaseOracleAddress;

        emit LogOracleUpdated(address(_newBaseOracleAddress));
    }

     
    function changeQuoteOracle(
        IOracle _newQuoteOracleAddress
    )
        external
        timeLockUpgrade
    {
         
        require(
            address(_newQuoteOracleAddress) != address(quoteOracleInstance),
            "TwoAssetLinearizedTimeSeriesFeed.changeQuoteOracle: Must give new quote oracle address."
        );

        quoteOracleInstance = _newQuoteOracleAddress;

        emit LogOracleUpdated(address(_newQuoteOracleAddress));
    }

     

     
    function calculateNextValue()
        internal
        returns (uint256)
    {
         
        uint256 baseOracleValue = baseOracleInstance.read();

         
        uint256 quoteOracleValue = quoteOracleInstance.read();

         
        uint256 currentRatioValue = baseOracleValue.mul(10 ** 18).div(quoteOracleValue);

         
        uint256 timeFromExpectedUpdate = block.timestamp.sub(nextEarliestUpdate);

         
         
        if (timeFromExpectedUpdate < interpolationThreshold) {
            return currentRatioValue;
        } else {
             
            uint256 previousRatioValue = timeSeriesData.getLatestValue();

            return DataSourceLinearInterpolationLibrary.interpolateDelayedPriceUpdate(
                currentRatioValue,
                updateInterval,
                timeFromExpectedUpdate,
                previousRatioValue
            );
        }
    }
}