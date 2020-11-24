 

 

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


 
interface IMedian {

     
    function read()
        external
        view
        returns (bytes32);

     
    function peek()
        external
        view
        returns (bytes32, bool);
}

 

 

pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";



 
contract LinkedListLibrary {

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






 
contract HistoricalPriceFeed is
    Ownable,
    LinkedListLibrary
{
    using SafeMath for uint256;

     
    uint256 constant DAYS_IN_DATASET = 200;

     
    uint256 public updateFrequency;
    uint256 public lastUpdatedAt;
    string public dataDescription;
    IMedian public medianizerInstance;

    LinkedList public historicalPriceData;

     

     
    constructor(
        uint256 _updateFrequency,
        address _medianizerAddress,
        string memory _dataDescription,
        uint256[] memory _seededValues
    )
        public
    {
         
        updateFrequency = _updateFrequency;
        dataDescription = _dataDescription;
        medianizerInstance = IMedian(_medianizerAddress);

         
        uint256[] memory initialValues = createInitialValues(_seededValues);

         
        initialize(
            historicalPriceData,
            DAYS_IN_DATASET,
            initialValues[0]
        );

         
         
        for (uint256 i = 1; i < initialValues.length; i++) {
            editList(
                historicalPriceData,
                initialValues[i]
            );
        }

         
        lastUpdatedAt = block.timestamp;
    }

     

     
    function poke()
        external
    {
         
        require(
            block.timestamp >= lastUpdatedAt.add(updateFrequency),
            "HistoricalPriceFeed: Not enough time passed between updates"
        );

         
        lastUpdatedAt = block.timestamp;

         
        uint256 newValue = uint256(medianizerInstance.read());

         
        editList(
            historicalPriceData,
            newValue
        );
    }

     
    function read(
        uint256 _dataDays
    )
        external
        view
        returns (uint256[] memory)
    {
        return readList(
            historicalPriceData,
            _dataDays
        );
    }

     
    function changeMedianizer(
        address _newMedianizerAddress
    )
        external
        onlyOwner
    {
        medianizerInstance = IMedian(_newMedianizerAddress);
    }


     

     
    function createInitialValues(
        uint256[] memory _seededValues
    )
        private
        returns (uint256[] memory)
    {
         
        uint256 currentValue = uint256(medianizerInstance.read());

         
        uint256 seededValuesLength = _seededValues.length;
        uint256[] memory outputArray = new uint256[](seededValuesLength.add(1));

         
        for (uint256 i = 0; i < _seededValues.length; i++) {
            outputArray[i] = _seededValues[i];
        }

         
        outputArray[seededValuesLength] = currentValue;

        return outputArray;
    }
}