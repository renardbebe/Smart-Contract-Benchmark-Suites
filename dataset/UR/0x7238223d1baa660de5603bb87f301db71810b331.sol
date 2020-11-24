 

 

pragma solidity ^0.5.0;

 
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}

 
contract Oracle is SafeMath, Owned {

    enum EventOutputType { stringarray, numeric }

    uint private eventNextId;
    uint private subcategoryNextId;



    struct Event { 
        string  title;
        bool isCancelled;
        uint256 dataCombined;
        bytes32 announcement;
    }



    struct EventOutcome {
        uint256 outcome1;
        uint256 outcome2;
        uint256 outcome3;
        uint256 outcome4;
        uint256 outcome5;
        uint256 outcome6;
    }



    struct EventOutput {
        uint256 dataCombined;
        bool isSet;
        bytes32 title;
         
         
        EventOutputType  eventOutputType;
        bytes32 announcement; 
         
    }


    struct OracleData { 
        string  name;
        string  creatorName;
        uint version;      
    } 

    struct Subcategory {
        uint id;
        uint  categoryId; 
        string name;
        string country;
        bool hidden;
    }

    OracleData public oracleData;  

     
    mapping (uint => Subcategory) public subcategories;

     
    mapping (uint => Event) public events;

     
    mapping (uint =>mapping (uint => mapping (uint => bytes32))) public eventOutputPossibleResults;  

     
    mapping (uint => mapping (uint => EventOutput)) public eventOutputs;

     
    mapping (uint => mapping (uint => uint)) public eventOutcome;

     
    mapping (uint => mapping (uint => EventOutcome)) public eventNumericOutcomes;



     
    event OracleCreated();

     
    event OraclePropertiesUpdated();    

     
    event OracleSubcategoryAdded(uint id);    

     
    event OracleSubcategoryUpdated(uint id);    
    
     
    event UpcomingEventUpdated(uint id,uint closeDateTime);



     
    constructor(string memory oracleName, string memory oracleCreatorName, uint version) public {
        oracleData.name = oracleName;
        oracleData.creatorName = oracleCreatorName;
        oracleData.version = version;
        emit OracleCreated();
    }

      
    function updateOracleNames(string memory newName, string memory newCreatorName) onlyOwner public {
        oracleData.name = newName;
        oracleData.creatorName = newCreatorName;
        emit OraclePropertiesUpdated();
    }    



     
    function setSubcategory(uint id, uint categoryId, string memory name,string memory country,bool hidden) onlyOwner public {
        if (id==0) {
            subcategoryNextId += 1;
            id = subcategoryNextId;
        }
        subcategories[id].id = id;
        subcategories[id].categoryId = categoryId;
        subcategories[id].name = name;
        subcategories[id].country = country;
        subcategories[id].hidden = hidden;
        emit OracleSubcategoryAdded(id);
    }  

     
    function hideSubcategory(uint id) onlyOwner public {
        subcategories[id].hidden = true;
        emit OracleSubcategoryUpdated(id);
    }   
  

    function setEventInternal(uint id, uint  startDateTime, uint  endDateTime, uint  subcategoryId, uint  categoryId, uint totalAvailableOutputs, uint timeStamp) private {
        events[id].dataCombined = (startDateTime & 0xFFFFFFFF) | ((endDateTime & 0xFFFFFFFF) << 32) | ((subcategoryId & 0xFFFFFFFF) << 64) | ((categoryId & 0xFFFFFFFF) << 96) | ((totalAvailableOutputs & 0xFFFFFFFF) << 128) | ((timeStamp & 0xFFFFFFFF) << 160);
    }

    function getEventInternal(uint id) public view returns (uint  startDateTime, uint  endDateTime, uint  subcategoryId, uint  categoryId, uint totalAvailableOutputs, uint timeStamp) {
        uint256 dataCombined = events[id].dataCombined;
        return (uint32(dataCombined), uint32(dataCombined >> 32), uint32(dataCombined >> 64), uint32(dataCombined >> 96), uint32(dataCombined >> 128), uint32(dataCombined >> 160));
    }

    function setEventOutputInternal(uint eventId, uint eventOutputId, uint possibleResultsCount, uint outputDateTime, uint decimals) private {
        eventOutputs[eventId][eventOutputId].dataCombined = (possibleResultsCount & 0xFFFFFFFF) | ((outputDateTime & 0xFFFFFFFF) << 32) | ((decimals & 0xFFFFFFFF) << 64);
    }

    function getEventOutputInternal(uint eventId, uint eventOutputId) public view returns (uint possibleResultsCount, uint outputDateTime, uint decimals) {
        uint256 dataCombined = eventOutputs[eventId][eventOutputId].dataCombined;
        return (uint32(dataCombined), uint32(dataCombined >> 32), uint32(dataCombined >> 64));
    }

    function setEventOutputDateTime(uint eventId, uint eventOutputId, uint outputDateTime) private {
        (uint possibleResultsCount, , uint decimals) = getEventOutputInternal(eventId, eventOutputId);
        eventOutputs[eventId][eventOutputId].dataCombined = (possibleResultsCount & 0xFFFFFFFF) | ((outputDateTime & 0xFFFFFFFF) << 32) | ((decimals & 0xFFFFFFFF) << 64);
    }

    function getEventOutputDateTime(uint eventId, uint eventOutputId) private view returns (uint outputDateTime) {
        return (uint32(eventOutputs[eventId][eventOutputId].dataCombined >> 32));
    }

     
    function addUpcomingEvent(uint id, string memory title, uint startDateTime, uint endDateTime, uint subcategoryId, uint categoryId, bytes32 outputTitle, EventOutputType eventOutputType, bytes32[] memory _possibleResults, uint decimals, bool isCancelled) onlyOwner public {        
        if (id==0) {
            eventNextId += 1;
            id = eventNextId;
        }      
        require(startDateTime > now,"Start time should be greater than now");
        events[id].title = title;
        events[id].isCancelled = isCancelled;
        eventOutputs[id][0].title = outputTitle;
        eventOutputs[id][0].eventOutputType = eventOutputType;
        setEventOutputInternal(id,0,_possibleResults.length, endDateTime, decimals);
        for (uint j = 0; j<_possibleResults.length; j++) {
            eventOutputPossibleResults[id][0][j] = _possibleResults[j];            
        }   
        setEventInternal(id, startDateTime, endDateTime, subcategoryId, categoryId, 1, now); 
        emit UpcomingEventUpdated(id,startDateTime);
    }  

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function updateUpcomingEvent(uint id, string memory title, uint startDateTime, uint endDateTime, uint subcategoryId, uint categoryId) onlyOwner public {
        if (startDateTime < now) {
            events[id].isCancelled = true;
        } else {       
            events[id].title = title;
            setEventInternal(id, startDateTime, endDateTime, subcategoryId, categoryId, 1, now); 
        }

         
        emit UpcomingEventUpdated(id,startDateTime); 
    }     

     
    function cancelUpcomingEvent(uint id) onlyOwner public {
        (uint currentStartDateTime,,,,,) = getEventInternal(id);
        events[id].isCancelled = true;
        emit UpcomingEventUpdated(id,currentStartDateTime); 
    }  


     
    function setEventOutcomeNumeric(uint eventId, uint outputId, bytes32 announcement, bool setEventAnnouncement, uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6) onlyOwner public {
        (uint currentStartDateTime,,,,,) = getEventInternal(eventId);
        require(currentStartDateTime < now,"Start time should be lower than now");
        require(!events[eventId].isCancelled,"Cancelled Event");
        require(eventOutputs[eventId][outputId].eventOutputType == EventOutputType.numeric,"Required numeric Event type");
        eventNumericOutcomes[eventId][outputId].outcome1 = outcome1;
        eventNumericOutcomes[eventId][outputId].outcome2 = outcome2;
        eventNumericOutcomes[eventId][outputId].outcome3 = outcome3;
        eventNumericOutcomes[eventId][outputId].outcome4 = outcome4;
        eventNumericOutcomes[eventId][outputId].outcome5 = outcome5;
        eventNumericOutcomes[eventId][outputId].outcome6 = outcome6;
        eventOutputs[eventId][outputId].isSet = true;
        eventOutputs[eventId][outputId].announcement = announcement;
        setEventOutputDateTime(eventId, outputId, now);
        if (setEventAnnouncement) {
            events[eventId].announcement = announcement;
        }     
        emit UpcomingEventUpdated(eventId, currentStartDateTime); 
    }  

      
    function setEventOutcome(uint eventId, uint outputId, bytes32 announcement, bool setEventAnnouncement, uint _eventOutcome ) onlyOwner public {
        (uint currentStartDateTime,,,,,) = getEventInternal(eventId);
        require(currentStartDateTime < now,"Start time should be lower than now");
        require(!events[eventId].isCancelled,"Cancelled Event");
        require(eventOutputs[eventId][outputId].eventOutputType == EventOutputType.stringarray,"Required array of options Event type");
        eventOutputs[eventId][outputId].isSet = true;
        eventOutcome[eventId][outputId] = _eventOutcome;
        setEventOutputDateTime(eventId, outputId, now);
        eventOutputs[eventId][outputId].announcement = announcement;
        if (setEventAnnouncement) {
            events[eventId].announcement = announcement;
        } 
        emit UpcomingEventUpdated(eventId, currentStartDateTime); 
    } 




     
    function getEventOutcomeNumeric(uint eventId, uint outputId) public view returns(uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6) {
        require(eventOutputs[eventId][outputId].isSet && eventOutputs[eventId][outputId].eventOutputType==EventOutputType.numeric);
        return (eventNumericOutcomes[eventId][outputId].outcome1,eventNumericOutcomes[eventId][outputId].outcome2,eventNumericOutcomes[eventId][outputId].outcome3,eventNumericOutcomes[eventId][outputId].outcome4,eventNumericOutcomes[eventId][outputId].outcome5,eventNumericOutcomes[eventId][outputId].outcome6);
    }

     
    function getEventOutcome(uint eventId, uint outputId) public view returns(uint outcome) {
        require(eventOutputs[eventId][outputId].isSet && eventOutputs[eventId][outputId].eventOutputType==EventOutputType.stringarray);
        return (eventOutcome[eventId][outputId]);
    }

      
    function getEventOutcomeIsSet(uint eventId, uint outputId) public view returns(bool isSet) {
        return (eventOutputs[eventId][outputId].isSet);
    }



     
    function getEventOutputPossibleResultsCount(uint id, uint outputId) public view returns(uint possibleResultsCount) {
        return (uint32(eventOutputs[id][outputId].dataCombined));
    }

     
    function getOracleVersion() public view returns(uint version) {
        return oracleData.version;
    }

     
    function getEventDataForHouse(uint id, uint outputId) public view returns(uint startDateTime, uint outputDateTime, bool isCancelled, uint timeStamp) {
        (uint currentStartDateTime,,,,,uint currentTimeStamp) = getEventInternal(id);
        return (currentStartDateTime, getEventOutputDateTime(id, outputId), events[id].isCancelled, currentTimeStamp);
    }


}