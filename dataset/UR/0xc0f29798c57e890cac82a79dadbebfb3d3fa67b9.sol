 

pragma solidity ^0.4.11;


contract FlightDelayControllerInterface {

    function isOwner(address _addr) returns (bool _isOwner);

    function selfRegister(bytes32 _id) returns (bool result);

    function getContract(bytes32 _id) returns (address _addr);
}

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

    function destruct() onlyController {
        selfdestruct(controller);
    }

    function setContracts() onlyController {}

    function getContract(bytes32 _id) internal returns (address _addr) {
        _addr = FD_CI.getContract(_id);
    }
}

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

    uint constant MIN_DEPARTURE_LIM = 1508198400;

    uint constant MAX_DEPARTURE_LIM = 1509840000;

     
    uint constant ORACLIZE_GAS = 1000000;


     

 
     
    string constant ORACLIZE_RATINGS_BASE_URL =
         
        "[URL] json(https://api.flightstats.com/flex/ratings/rest/v1/json/flight/";
    string constant ORACLIZE_RATINGS_QUERY =
        "?${[decrypt] <!--PUT ENCRYPTED_QUERY HERE--> }).ratings[0]['observations','late15','late30','late45','cancelled','diverted','arrivalAirportFsCode']";
    string constant ORACLIZE_STATUS_BASE_URL =
         
        "[URL] json(https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/";
    string constant ORACLIZE_STATUS_QUERY =
         
        "?${[decrypt] <!--PUT ENCRYPTED_QUERY HERE--> }&utc=true).flightStatuses[0]['status','delays','operationalTimes']";
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
}

contract FlightDelayDatabaseInterface is FlightDelayDatabaseModel {

    function setAccessControl(address _contract, address _caller, uint8 _perm);

    function setAccessControl(
        address _contract,
        address _caller,
        uint8 _perm,
        bool _access
    );

    function getAccessControl(address _contract, address _caller, uint8 _perm) returns (bool _allowed);

    function setLedger(uint8 _index, int _value);

    function getLedger(uint8 _index) returns (int _value);

    function getCustomerPremium(uint _policyId) returns (address _customer, uint _premium);

    function getPolicyData(uint _policyId) returns (address _customer, uint _premium, uint _weight);

    function getPolicyState(uint _policyId) returns (policyState _state);

    function getRiskId(uint _policyId) returns (bytes32 _riskId);

    function createPolicy(address _customer, uint _premium, Currency _currency, bytes32 _customerExternalId, bytes32 _riskId) returns (uint _policyId);

    function setState(
        uint _policyId,
        policyState _state,
        uint _stateTime,
        bytes32 _stateMessage
    );

    function setWeight(uint _policyId, uint _weight, bytes _proof);

    function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout);

    function setDelay(uint _policyId, uint8 _delay, uint _delayInMinutes);

    function getRiskParameters(bytes32 _riskId)
        returns (bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime);

    function getPremiumFactors(bytes32 _riskId)
        returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier);

    function createUpdateRisk(bytes32 _carrierFlightNumber, bytes32 _departureYearMonthDay, uint _arrivalTime)
        returns (bytes32 _riskId);

    function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier);

    function getOraclizeCallback(bytes32 _queryId)
        returns (uint _policyId, uint _arrivalTime);

    function getOraclizePolicyId(bytes32 _queryId)
    returns (uint _policyId);

    function createOraclizeCallback(
        bytes32 _queryId,
        uint _policyId,
        oraclizeState _oraclizeState,
        uint _oraclizeTime
    );

    function checkTime(bytes32 _queryId, bytes32 _riskId, uint _offset)
        returns (bool _result);
}

contract FlightDelayAccessControllerInterface {

    function setPermissionById(uint8 _perm, bytes32 _id);

    function setPermissionById(uint8 _perm, bytes32 _id, bool _access);

    function setPermissionByAddress(uint8 _perm, address _addr);

    function setPermissionByAddress(uint8 _perm, address _addr, bool _access);

    function checkPermission(uint8 _perm, address _addr) returns (bool _success);
}


contract FlightDelayLedgerInterface is FlightDelayDatabaseModel {

    function receiveFunds(Acc _to) payable;

    function sendFunds(address _recipient, Acc _from, uint _amount) returns (bool _success);

    function bookkeeping(Acc _from, Acc _to, uint amount);
}

contract FlightDelayUnderwriteInterface {

    function scheduleUnderwriteOraclizeCall(uint _policyId, bytes32 _carrierFlightNumber);
}

contract ConvertLib {

     
    uint16[12] days_since = [
        11,
        42,
        70,
        101,
        131,
        162,
        192,
        223,
        254,
        284,
        315,
        345
    ];

    function b32toString(bytes32 x) internal returns (string) {
         
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;

        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);

        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }

    function b32toHexString(bytes32 x) returns (string) {
        bytes memory b = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 by = uint8(uint(x) / (2**(8*(31 - i))));
            uint8 high = by/16;
            uint8 low = by - 16*high;
            if (high > 9) {
                high += 39;
            }
            if (low > 9) {
                low += 39;
            }
            b[2*i] = byte(high+48);
            b[2*i+1] = byte(low+48);
        }

        return string(b);
    }

    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i<bresult.length; i++) {
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) {
                        break;
                    } else {
                        _b--;
                    }
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10**_b;
        }
        return mint;
    }

     
     
    function toUnixtime(bytes32 _dayMonthYear) constant returns (uint unixtime) {
         
        bytes memory bDmy = bytes(b32toString(_dayMonthYear));
        bytes memory temp2 = bytes(new string(2));
        bytes memory temp4 = bytes(new string(4));

        temp4[0] = bDmy[5];
        temp4[1] = bDmy[6];
        temp4[2] = bDmy[7];
        temp4[3] = bDmy[8];
        uint year = parseInt(string(temp4));

        temp2[0] = bDmy[10];
        temp2[1] = bDmy[11];
        uint month = parseInt(string(temp2));

        temp2[0] = bDmy[13];
        temp2[1] = bDmy[14];
        uint day = parseInt(string(temp2));

        unixtime = ((year - 1970) * 365 + days_since[month-1] + day) * 86400;
    }
}

contract FlightDelayNewPolicy is FlightDelayControlledContract, FlightDelayConstants, ConvertLib {

    FlightDelayAccessControllerInterface FD_AC;
    FlightDelayDatabaseInterface FD_DB;
    FlightDelayLedgerInterface FD_LG;
    FlightDelayUnderwriteInterface FD_UW;

    function FlightDelayNewPolicy(address _controller) {
        setController(_controller);
    }

    function setContracts() onlyController {
        FD_AC = FlightDelayAccessControllerInterface(getContract("FD.AccessController"));
        FD_DB = FlightDelayDatabaseInterface(getContract("FD.Database"));
        FD_LG = FlightDelayLedgerInterface(getContract("FD.Ledger"));
        FD_UW = FlightDelayUnderwriteInterface(getContract("FD.Underwrite"));

        FD_AC.setPermissionByAddress(101, 0x0);
        FD_AC.setPermissionById(102, "FD.Controller");
        FD_AC.setPermissionById(103, "FD.Owner");
    }

    function bookAndCalcRemainingPremium() internal returns (uint) {
        uint v = msg.value;
        uint reserve = v * RESERVE_PERCENT / 100;
        uint remain = v - reserve;
        uint reward = remain * REWARD_PERCENT / 100;

         
        FD_LG.bookkeeping(Acc.Premium, Acc.RiskFund, reserve);
        FD_LG.bookkeeping(Acc.Premium, Acc.Reward, reward);

        return (uint(remain - reward));
    }

    function maintenanceMode(bool _on) {
        if (FD_AC.checkPermission(103, msg.sender)) {
            FD_AC.setPermissionByAddress(101, 0x0, !_on);
        }
    }

     
    function newPolicy(
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint256 _departureTime,
        uint256 _arrivalTime,
        Currency _currency,
        bytes32 _customerExternalId) payable
    {
         
        require(FD_AC.checkPermission(101, 0x0));

        require(uint256(_currency) <= 3);

        uint8 paymentType = uint8(_currency);

        if (paymentType == 0) {
             
            if (msg.value < MIN_PREMIUM || msg.value > MAX_PREMIUM) {
                LogPolicyDeclined(0, "Invalid premium value");
                FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                return;
            }
        } else {
            require(msg.sender == FD_CI.getContract("FD.CustomersAdmin"));

            if (paymentType == 1) {
                 
                if (msg.value < MIN_PREMIUM_EUR || msg.value > MAX_PREMIUM_EUR) {
                    LogPolicyDeclined(0, "Invalid premium value");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }

            if (paymentType == 2) {
                 
                if (msg.value < MIN_PREMIUM_USD || msg.value > MAX_PREMIUM_USD) {
                    LogPolicyDeclined(0, "Invalid premium value");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }

            if (paymentType == 3) {
                 
                if (msg.value < MIN_PREMIUM_GBP || msg.value > MAX_PREMIUM_GBP) {
                    LogPolicyDeclined(0, "Invalid premium value");
                    FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
                    return;
                }
            }
        }

         
        FD_LG.receiveFunds.value(msg.value)(Acc.Premium);


         
         
         
        uint dmy = toUnixtime(_departureYearMonthDay);

 
 
 
 

        if (
            _arrivalTime < _departureTime ||
            _arrivalTime > _departureTime + MAX_FLIGHT_DURATION ||
            _departureTime < now + MIN_TIME_BEFORE_DEPARTURE ||
            _departureTime > CONTRACT_DEAD_LINE ||
            _departureTime < dmy ||
            _departureTime > dmy + 24 hours ||
            _departureTime < MIN_DEPARTURE_LIM ||
            _departureTime > MAX_DEPARTURE_LIM
        ) {
            LogPolicyDeclined(0, "Invalid arrival/departure time");
            FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
            return;
        }

        bytes32 riskId = FD_DB.createUpdateRisk(_carrierFlightNumber, _departureYearMonthDay, _arrivalTime);

        var (cumulatedWeightedPremium, premiumMultiplier) = FD_DB.getPremiumFactors(riskId);

         
         
         
         
        if (msg.value * premiumMultiplier + cumulatedWeightedPremium >= MAX_CUMULATED_WEIGHTED_PREMIUM) {
            LogPolicyDeclined(0, "Cluster risk");
            FD_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
            return;
        } else if (cumulatedWeightedPremium == 0) {
             
             
             
            FD_DB.setPremiumFactors(riskId, MAX_CUMULATED_WEIGHTED_PREMIUM, premiumMultiplier);
        }

        uint premium = bookAndCalcRemainingPremium();
        uint policyId = FD_DB.createPolicy(msg.sender, premium, _currency, _customerExternalId, riskId);

        if (premiumMultiplier > 0) {
            FD_DB.setPremiumFactors(
                riskId,
                cumulatedWeightedPremium + premium * premiumMultiplier,
                premiumMultiplier
            );
        }

         
        FD_DB.setState(
            policyId,
            policyState.Applied,
            now,
            "Policy applied by customer"
        );

        LogPolicyApplied(
            policyId,
            msg.sender,
            _carrierFlightNumber,
            premium
        );

        LogExternal(
            policyId,
            msg.sender,
            _customerExternalId
        );

        FD_UW.scheduleUnderwriteOraclizeCall(policyId, _carrierFlightNumber);
    }
}