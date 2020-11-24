 

pragma solidity ^0.4.0;

 
contract History  {

     
     
    address owner;

     
    enum EventType { NewOwner, Maintenance, DamageRepair }

     
     
    mapping(address => bool) public authorizedLoggers;

     
    event EventLogged(string vin, EventType eventType, uint256 mileage, address verifier);

     
    event LoggerAuthorized(address loggerAddress);

    struct LedgerEvent {
        
        uint256 creationTime;
        uint256 mileage; 
        uint256 repairOrderNumber;
        address verifier; 
        EventType eventType;
        string description;   
    }

    mapping (bytes32 => LedgerEvent[]) events;

     
    function History() {
        
        owner = msg.sender; 
    }

     
    modifier onlyAuthorized {

        if (!authorizedLoggers[msg.sender])
            throw;
        _;
    }

     
     modifier onlyOwner {

        if (msg.sender != owner)
            throw;
        _;
    }


     
    function authorize(address newLogger) onlyOwner {

        authorizedLoggers[newLogger] = true;
        LoggerAuthorized(newLogger);
    }

     
    function isAuthorized(address logger) returns (bool) {

         return authorizedLoggers[logger];
    }

     
    function addEvent(uint256 _mileage, 
                     uint256 _repairOrderNumber,
                     EventType _eventType, 
                     string _description, 
                     string _vin) onlyAuthorized {

        events[sha3(_vin)].push(LedgerEvent({
            creationTime: now,
            mileage: _mileage,
            repairOrderNumber: _repairOrderNumber,
            verifier: msg.sender,
            eventType: _eventType,
            description: _description
        }));
        
        EventLogged(_vin, _eventType, _mileage, msg.sender);
    }
    
     
    function getEventsCount(string _vin) constant returns(uint256) {

        return events[sha3(_vin)].length;
    }
    
     
    function getEvent(string _vin, uint256 _index) constant
                returns (uint256 mileage, address verifier, 
                        EventType eventType, string description) {

        LedgerEvent memory e = events[sha3(_vin)][_index];
        mileage = e.mileage;
        verifier = e.verifier;
        eventType = e.eventType;
        description = e.description;
    }

     
    function kill() onlyOwner { 

        selfdestruct(owner); 
    }

     
    function() payable {}
}