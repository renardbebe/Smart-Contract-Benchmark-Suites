 

 

 

pragma solidity ^0.4.11;


contract FlightDelayConstants {

     

 
 
 
 
 
 
 
 
 
 
 
 
 

    event LogPolicyApplied(
        uint _policyId,
        address _customer,
        bytes32 strCarrierFlightNumber,
        uint ethPremium
    );
    event LogPolicyAccepted(
        uint _policyId,
        uint _statistics0,
        uint _statistics1,
        uint _statistics2,
        uint _statistics3,
        uint _statistics4,
        uint _statistics5
    );
    event LogPolicyPaidOut(
        uint _policyId,
        uint ethAmount
    );
    event LogPolicyExpired(
        uint _policyId
    );
    event LogPolicyDeclined(
        uint _policyId,
        bytes32 strReason
    );
    event LogPolicyManualPayout(
        uint _policyId,
        bytes32 strReason
    );
    event LogSendFunds(
        address _recipient,
        uint8 _from,
        uint ethAmount
    );
    event LogReceiveFunds(
        address _sender,
        uint8 _to,
        uint ethAmount
    );
    event LogSendFail(
        uint _policyId,
        bytes32 strReason
    );
    event LogOraclizeCall(
        uint _policyId,
        bytes32 hexQueryId,
        string _oraclizeUrl,
        uint256 _oraclizeTime
    );
    event LogOraclizeCallback(
        uint _policyId,
        bytes32 hexQueryId,
        string _result,
        bytes hexProof
    );
    event LogSetState(
        uint _policyId,
        uint8 _policyState,
        uint _stateTime,
        bytes32 _stateMessage
    );
    event LogExternal(
        uint256 _policyId,
        address _address,
        bytes32 _externalId
    );

     

     
    uint constant MIN_OBSERVATIONS = 10;
     
    uint constant MIN_PREMIUM = 50 finney;
     
    uint constant MAX_PREMIUM = 1 ether;
     
    uint constant MAX_PAYOUT = 1100 finney;

    uint constant MIN_PREMIUM_EUR = 1500 wei;
    uint constant MAX_PREMIUM_EUR = 29000 wei;
    uint constant MAX_PAYOUT_EUR = 30000 wei;

    uint constant MIN_PREMIUM_USD = 1700 wei;
    uint constant MAX_PREMIUM_USD = 34000 wei;
    uint constant MAX_PAYOUT_USD = 35000 wei;

    uint constant MIN_PREMIUM_GBP = 1300 wei;
    uint constant MAX_PREMIUM_GBP = 25000 wei;
    uint constant MAX_PAYOUT_GBP = 270 wei;

     
    uint constant MAX_CUMULATED_WEIGHTED_PREMIUM = 60 ether;
     
    uint8 constant REWARD_PERCENT = 2;
     
    uint8 constant RESERVE_PERCENT = 1;
     
     
     
    uint8[6] WEIGHT_PATTERN = [
        0,
        10,
        20,
        30,
        50,
        50
    ];

 
     
     
    uint constant MIN_TIME_BEFORE_DEPARTURE	= 24 hours;  
     
    uint constant CHECK_PAYOUT_OFFSET = 15 minutes;  
 

 
 
 
 
 
 
 

     
    uint constant MAX_FLIGHT_DURATION = 2 days;
     
    uint constant CONTRACT_DEAD_LINE = 1922396399;

     
    uint constant ORACLIZE_GAS = 700000;
    uint constant ORACLIZE_GASPRICE = 4000000000;


     

 
     
    string constant ORACLIZE_RATINGS_BASE_URL =
         
        "[URL] json(https://api.flightstats.com/flex/ratings/rest/v1/json/flight/";
    string constant ORACLIZE_RATINGS_QUERY =
        "?${[decrypt] BAr6Z9QolM2PQimF/pNC6zXldOvZ2qquOSKm/qJkJWnSGgAeRw21wBGnBbXiamr/ISC5SlcJB6wEPKthdc6F+IpqM/iXavKsalRUrGNuBsGfaMXr8fRQw6gLzqk0ecOFNeCa48/yqBvC/kas+jTKHiYxA3wTJrVZCq76Y03lZI2xxLaoniRk}).ratings[0]['observations','late15','late30','late45','cancelled','diverted','arrivalAirportFsCode','departureAirportFsCode']";
    string constant ORACLIZE_STATUS_BASE_URL =
         
        "[URL] json(https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/";
    string constant ORACLIZE_STATUS_QUERY =
         
        "?${[decrypt] BJxpwRaHujYTT98qI5slQJplj/VbfV7vYkMOp/Mr5D/5+gkgJQKZb0gVSCa6aKx2Wogo/cG7yaWINR6vnuYzccQE5yVJSr7RQilRawxnAtZXt6JB70YpX4xlfvpipit4R+OmQTurJGGwb8Pgnr4LvotydCjup6wv2Bk/z3UdGA7Sl+FU5a+0}&utc=true).flightStatuses[0]['status','delays','operationalTimes']";
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
}

 

 

pragma solidity ^0.4.11;


contract FlightDelayControllerInterface {

    function isOwner(address _addr) public returns (bool _isOwner);

    function selfRegister(bytes32 _id) public returns (bool result);

    function getContract(bytes32 _id) public returns (address _addr);
}

 

 

pragma solidity ^0.4.11;


contract FlightDelayDatabaseModel {

     
    enum Acc {
        Premium,       
        RiskFund,      
        Payout,        
        Balance,       
        Reward,        
        OraclizeCosts  
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     


     
    enum policyState { Applied, Accepted, Revoked, PaidOut, Expired, Declined, SendFailed }

     
    enum oraclizeState { ForUnderwriting, ForPayout }

     
    enum Currency { ETH, EUR, USD, GBP }

     
     
    struct Policy {
         
        address customer;

         
        uint premium;
         
         
        bytes32 riskId;
         
         
         
         
         
        uint weight;
         
        uint calculatedPayout;
         
        uint actualPayout;

         
         
        policyState state;
         
        uint stateTime;
         
        bytes32 stateMessage;
         
        bytes proof;
         
        Currency currency;
         
        bytes32 customerExternalId;
    }

     
     
     
     
    struct Risk {
         
        bytes32 carrierFlightNumber;
         
        bytes32 departureYearMonthDay;
         
        uint arrivalTime;
         
        uint delayInMinutes;
         
        uint8 delay;
         
        uint cumulatedWeightedPremium;
         
        uint premiumMultiplier;
    }

     
     
     
    struct OraclizeCallback {
         
        uint policyId;
         
        oraclizeState oState;
         
        uint oraclizeTime;
    }

    struct Customer {
        bytes32 customerExternalId;
        bool identityConfirmed;
    }
}

 

 

pragma solidity ^0.4.11;





contract FlightDelayControlledContract is FlightDelayDatabaseModel {

    address public controller;
    FlightDelayControllerInterface FD_CI;

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function setController(address _controller) internal returns (bool _result) {
        controller = _controller;
        FD_CI = FlightDelayControllerInterface(_controller);
        _result = true;
    }

    function destruct() public onlyController {
        selfdestruct(controller);
    }

    function setContracts() public onlyController {}

    function getContract(bytes32 _id) internal returns (address _addr) {
        _addr = FD_CI.getContract(_id);
    }
}

 

 

pragma solidity ^0.4.11;

 
contract Owned {

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

 

 

pragma solidity ^0.4.11;





contract FlightDelayController is Owned, FlightDelayConstants {

    struct Controller {
        address addr;
        bool isControlled;
        bool isInitialized;
    }

    mapping (bytes32 => Controller) public contracts;
    bytes32[] public contractIds;

     
    function FlightDelayController() public {
        registerContract(owner, "FD.Owner", false);
        registerContract(address(this), "FD.Controller", false);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        setContract(_newOwner, "FD.Owner", false);
    }

     
    function setContract(address _addr, bytes32 _id, bool _isControlled) internal {
        contracts[_id].addr = _addr;
        contracts[_id].isControlled = _isControlled;
    }

     
    function getContract(bytes32 _id) public returns (address _addr) {
        _addr = contracts[_id].addr;
    }

     
    function registerContract(address _addr, bytes32 _id, bool _isControlled) public onlyOwner returns (bool _result) {
        setContract(_addr, _id, _isControlled);
        contractIds.push(_id);
        _result = true;
    }

     
    function deregister(bytes32 _id) public onlyOwner returns (bool _result) {
        if (getContract(_id) == 0x0) {
            return false;
        }
        setContract(0x0, _id, false);
        _result = true;
    }

     
    function setAllContracts() public onlyOwner {
        FlightDelayControlledContract controlledContract;
         
         
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                controlledContract = FlightDelayControlledContract(contracts[contractIds[i]].addr);
                controlledContract.setContracts();
            }
        }
    }

    function setOneContract(uint i) public onlyOwner {
        FlightDelayControlledContract controlledContract;
         
        controlledContract = FlightDelayControlledContract(contracts[contractIds[i]].addr);
        controlledContract.setContracts();
    }

     
    function destructOne(bytes32 _id) public onlyOwner {
        address addr = getContract(_id);
        if (addr != 0x0) {
            FlightDelayControlledContract(addr).destruct();
        }
    }

     
    function destructAll() public onlyOwner {
         
        for (uint i = 0; i < contractIds.length; i++) {
            if (contracts[contractIds[i]].isControlled == true) {
                destructOne(contractIds[i]);
            }
        }

        selfdestruct(owner);
    }
}