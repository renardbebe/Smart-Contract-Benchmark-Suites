 

 

pragma solidity ^0.4.11;


contract FlightDelayAccessControllerInterface {

    function setPermissionById(uint8 _perm, bytes32 _id) public;

    function setPermissionById(uint8 _perm, bytes32 _id, bool _access) public;

    function setPermissionByAddress(uint8 _perm, address _addr) public;

    function setPermissionByAddress(uint8 _perm, address _addr, bool _access) public;

    function checkPermission(uint8 _perm, address _addr) public returns (bool _success);
}

 

 

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




contract FlightDelayDatabaseInterface is FlightDelayDatabaseModel {

    uint public MIN_DEPARTURE_LIM;

    uint public MAX_DEPARTURE_LIM;

    bytes32[] public validOrigins;

    bytes32[] public validDestinations;

    function countOrigins() public constant returns (uint256 _length);

    function getOriginByIndex(uint256 _i) public constant returns (bytes32 _origin);

    function countDestinations() public constant returns (uint256 _length);

    function getDestinationByIndex(uint256 _i) public constant returns (bytes32 _destination);

    function setAccessControl(address _contract, address _caller, uint8 _perm) public;

    function setAccessControl(
        address _contract,
        address _caller,
        uint8 _perm,
        bool _access
    ) public;

    function getAccessControl(address _contract, address _caller, uint8 _perm) public returns (bool _allowed) ;

    function setLedger(uint8 _index, int _value) public;

    function getLedger(uint8 _index) public returns (int _value) ;

    function getCustomerPremium(uint _policyId) public returns (address _customer, uint _premium) ;

    function getPolicyData(uint _policyId) public returns (address _customer, uint _premium, uint _weight) ;

    function getPolicyState(uint _policyId) public returns (policyState _state) ;

    function getRiskId(uint _policyId) public returns (bytes32 _riskId);

    function createPolicy(address _customer, uint _premium, Currency _currency, bytes32 _customerExternalId, bytes32 _riskId) public returns (uint _policyId) ;

    function setState(
        uint _policyId,
        policyState _state,
        uint _stateTime,
        bytes32 _stateMessage
    ) public;

    function setWeight(uint _policyId, uint _weight, bytes _proof) public;

    function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) public;

    function setDelay(uint _policyId, uint8 _delay, uint _delayInMinutes) public;

    function getRiskParameters(bytes32 _riskId)
        public returns (bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime) ;

    function getPremiumFactors(bytes32 _riskId)
        public returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier);

    function createUpdateRisk(bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime)
        public returns (bytes32 _riskId);

    function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) public;

    function getOraclizeCallback(bytes32 _queryId)
        public returns (uint _policyId, uint _oraclizeTime) ;

    function getOraclizePolicyId(bytes32 _queryId)
        public returns (uint _policyId) ;

    function createOraclizeCallback(
        bytes32 _queryId,
        uint _policyId,
        oraclizeState _oraclizeState,
        uint _oraclizeTime
    ) public;

    function checkTime(bytes32 _queryId, bytes32 _riskId, uint _offset)
        public returns (bool _result) ;
}

 

 

pragma solidity ^0.4.11;







contract FlightDelayDatabase is FlightDelayControlledContract, FlightDelayDatabaseInterface, FlightDelayConstants {

    uint public MIN_DEPARTURE_LIM;

    uint public MAX_DEPARTURE_LIM;

    bytes32[] public validOrigins;
    bytes32[] public validDestinations;

     
    Policy[] public policies;

    mapping (bytes32 => uint[]) public extCustomerPolicies;

    mapping (address => Customer) public customers;

     
    mapping (address => uint[]) public customerPolicies;

     
    mapping (bytes32 => OraclizeCallback) public oraclizeCallbacks;

     
    mapping (bytes32 => Risk) public risks;

     
    mapping(address => mapping(address => mapping(uint8 => bool))) public accessControl;

     
    int[6] public ledger;

    FlightDelayAccessControllerInterface FD_AC;

    function FlightDelayDatabase (address _controller) public {
        setController(_controller);
    }

    function setContracts() public onlyController {
        FD_AC = FlightDelayAccessControllerInterface(getContract("FD.AccessController"));

        FD_AC.setPermissionById(101, "FD.NewPolicy");
        FD_AC.setPermissionById(101, "FD.Underwrite");

        FD_AC.setPermissionById(101, "FD.Payout");
        FD_AC.setPermissionById(101, "FD.Ledger");

        FD_AC.setPermissionById(102, "FD.Owner");
    }

    function setMinDepartureLim(uint _timestamp) returns (bool _success) {
        require(FD_AC.checkPermission(102, msg.sender));

        MIN_DEPARTURE_LIM = _timestamp;
        _success = true;
    }

    function setMaxDepartureLim(uint _timestamp) returns (bool _success) {
        require(FD_AC.checkPermission(102, msg.sender));

        MAX_DEPARTURE_LIM = _timestamp;
        _success = true;
    }

    function addOrigin(bytes32 _origin) returns (uint256 _index) {
        require(FD_AC.checkPermission(102, msg.sender));

        validOrigins.push(_origin);
        _index = validOrigins.length - 1;
    }

    function removeOriginByIndex(uint256 _index) returns (bool _success) {
        require(FD_AC.checkPermission(102, msg.sender));

        if (validOrigins.length == 0) {
            return false;
        } else {
            bytes32 lastElement = validOrigins[validOrigins.length - 1];
            validOrigins[_index] = lastElement;
            validOrigins.length--;
            return true;
        }
    }

    function countOrigins() public constant returns (uint256 _length) {
        _length = validOrigins.length;
    }

    function getOriginByIndex(uint256 _i) public constant returns (bytes32 _origin) {
        _origin = validOrigins[_i];
    }

    function addDestination(bytes32 _origin) returns (uint256 _index) {
        require(FD_AC.checkPermission(102, msg.sender));

        validDestinations.push(_origin);
        _index = validDestinations.length - 1;
    }

    function removeDestinationByIndex(uint256 _index) returns (bool _success) {
        require(FD_AC.checkPermission(102, msg.sender));

        if (validDestinations.length == 0) {
            return false;
        } else {
            bytes32 lastElement = validDestinations[validDestinations.length - 1];
            validDestinations[_index] = lastElement;
            validDestinations.length--;
            return true;
        }
    }

    function countDestinations() public constant returns (uint256 _length) {
        _length = validDestinations.length;
    }

    function getDestinationByIndex(uint256 _i) public constant returns (bytes32 _destination) {
        _destination = validDestinations[_i];
    }


     
    function setAccessControl (
        address _contract,
        address _caller,
        uint8 _perm,
        bool _access
    ) public {
         
        require(msg.sender == FD_CI.getContract("FD.AccessController"));
        accessControl[_contract][_caller][_perm] = _access;
    }

 
 
 
 
 
 
 
 
 
 

    function setAccessControl(address _contract, address _caller, uint8 _perm) public {
        setAccessControl(
            _contract,
            _caller,
            _perm,
            true
        );
    }

    function getAccessControl(address _contract, address _caller, uint8 _perm) public returns (bool _allowed) {
        _allowed = accessControl[_contract][_caller][_perm];
    }

     
    function setLedger(uint8 _index, int _value) public {
        require(FD_AC.checkPermission(101, msg.sender));

        int previous = ledger[_index];
        ledger[_index] += _value;

 
 
 
 
 

         
        if (_value < 0) {
            assert(ledger[_index] < previous);
        } else if (_value > 0) {
            assert(ledger[_index] > previous);
        }
    }

    function getLedger(uint8 _index) public returns (int _value) {
        _value = ledger[_index];
    }

     
    function getCustomerPremium(uint _policyId) public returns (address _customer, uint _premium) {
        Policy storage p = policies[_policyId];
        _customer = p.customer;
        _premium = p.premium;
    }

    function getPolicyData(uint _policyId) public returns (address _customer, uint _weight, uint _premium) {
        Policy storage p = policies[_policyId];
        _customer = p.customer;
        _weight = p.weight;
        _premium = p.premium;
    }

    function getPolicyState(uint _policyId) public returns (policyState _state) {
        Policy storage p = policies[_policyId];
        _state = p.state;
    }

    function getRiskId(uint _policyId) public returns (bytes32 _riskId) {
        Policy storage p = policies[_policyId];
        _riskId = p.riskId;
    }

    function createPolicy(address _customer, uint _premium, Currency _currency, bytes32 _customerExternalId, bytes32 _riskId) public returns (uint _policyId) {
        require(FD_AC.checkPermission(101, msg.sender));

        _policyId = policies.length++;

         

 
 
 

        customerPolicies[_customer].push(_policyId);
        extCustomerPolicies[_customerExternalId].push(_policyId);

        Policy storage p = policies[_policyId];

        p.customer = _customer;
        p.currency = _currency;
        p.customerExternalId = _customerExternalId;
        p.premium = _premium;
        p.riskId = _riskId;
    }

    function setState(
        uint _policyId,
        policyState _state,
        uint _stateTime,
        bytes32 _stateMessage
    ) public {
        require(FD_AC.checkPermission(101, msg.sender));

        LogSetState(
            _policyId,
            uint8(_state),
            _stateTime,
            _stateMessage
        );

        Policy storage p = policies[_policyId];

        p.state = _state;
        p.stateTime = _stateTime;
        p.stateMessage = _stateMessage;
    }

    function setWeight(uint _policyId, uint _weight, bytes _proof) public {
        require(FD_AC.checkPermission(101, msg.sender));

        Policy storage p = policies[_policyId];

        p.weight = _weight;
        p.proof = _proof;
    }

    function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) public {
        require(FD_AC.checkPermission(101, msg.sender));

        Policy storage p = policies[_policyId];

        p.calculatedPayout = _calculatedPayout;
        p.actualPayout = _actualPayout;
    }

    function setDelay(uint _policyId, uint8 _delay, uint _delayInMinutes) public {
        require(FD_AC.checkPermission(101, msg.sender));

        Risk storage r = risks[policies[_policyId].riskId];

        r.delay = _delay;
        r.delayInMinutes = _delayInMinutes;
    }

     
    function getRiskParameters(bytes32 _riskId) public returns (bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime) {
        Risk storage r = risks[_riskId];
        _carrierFlightNumber = r.carrierFlightNumber;
        _departureYearMonthDay = r.departureYearMonthDay;
        _arrivalTime = r.arrivalTime;
    }

    function getPremiumFactors(bytes32 _riskId) public returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier) {
        Risk storage r = risks[_riskId];
        _cumulatedWeightedPremium = r.cumulatedWeightedPremium;
        _premiumMultiplier = r.premiumMultiplier;
    }

    function createUpdateRisk(bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime) returns (bytes32 _riskId) {
        require(FD_AC.checkPermission(101, msg.sender));

        _riskId = sha3(
            _carrierFlightNumber,
            _departureYearMonthDay,
            _arrivalTime
        );

 
 
 

        Risk storage r = risks[_riskId];

        if (r.premiumMultiplier == 0) {
            r.carrierFlightNumber = _carrierFlightNumber;
            r.departureYearMonthDay = _departureYearMonthDay;
            r.arrivalTime = _arrivalTime;
        }
    }

    function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) public {
        require(FD_AC.checkPermission(101, msg.sender));

        Risk storage r = risks[_riskId];
        r.cumulatedWeightedPremium = _cumulatedWeightedPremium;
        r.premiumMultiplier = _premiumMultiplier;
    }

     
    function getOraclizeCallback(bytes32 _queryId) public returns (uint _policyId, uint _oraclizeTime) {
        OraclizeCallback storage o = oraclizeCallbacks[_queryId];
        _policyId = o.policyId;
        _oraclizeTime = o.oraclizeTime;
    }

    function getOraclizePolicyId(bytes32 _queryId) public returns (uint _policyId) {
        OraclizeCallback storage o = oraclizeCallbacks[_queryId];
        _policyId = o.policyId;
    }

    function createOraclizeCallback(
        bytes32 _queryId,
        uint _policyId,
        oraclizeState _oraclizeState,
        uint _oraclizeTime) public {

        require(FD_AC.checkPermission(101, msg.sender));

        oraclizeCallbacks[_queryId] = OraclizeCallback(_policyId, _oraclizeState, _oraclizeTime);
    }

     
    function checkTime(bytes32 _queryId, bytes32 _riskId, uint _offset) public returns (bool _result) {
        OraclizeCallback storage o = oraclizeCallbacks[_queryId];
        Risk storage r = risks[_riskId];

        _result = o.oraclizeTime > r.arrivalTime + _offset;
    }
}