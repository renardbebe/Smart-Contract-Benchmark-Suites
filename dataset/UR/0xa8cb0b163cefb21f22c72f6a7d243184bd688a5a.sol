 

 


 

pragma solidity 0.4.25;

 
contract Owned {
    address public owner;
    address public nominatedOwner;

     
    constructor(address _owner)
        public
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

     
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

     
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


 


contract Proxy is Owned {

    Proxyable public target;
    bool public useDELEGATECALL;

    constructor(address _owner)
        Owned(_owner)
        public
    {}

    function setTarget(Proxyable _target)
        external
        onlyOwner
    {
        target = _target;
        emit TargetUpdated(_target);
    }

    function setUseDELEGATECALL(bool value) 
        external
        onlyOwner
    {
        useDELEGATECALL = value;
    }

    function _emit(bytes callData, uint numTopics, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4)
        external
        onlyTarget
    {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
             
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            } 
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }

    function()
        external
        payable
    {
        if (useDELEGATECALL) {
            assembly {
                 
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                 
                let result := delegatecall(gas, sload(target_slot), free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                 
                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        } else {
             
            target.setMessageSender(msg.sender);
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                 
                let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


 


 
contract Proxyable is Owned {
     
    Proxy public proxy;
    Proxy public integrationProxy;

     
    address public messageSender;

    constructor(address _proxy, address _owner)
        Owned(_owner)
        public
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address _proxy)
        external
        onlyOwner
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setIntegrationProxy(address _integrationProxy)
        external
        onlyOwner
    {
        integrationProxy = Proxy(_integrationProxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy {
        require(Proxy(msg.sender) == proxy || Proxy(msg.sender) == integrationProxy, "Only the proxy can call");
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}


 


 
contract SelfDestructible is Owned {
    
    uint public initiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

     
    constructor(address _owner)
        Owned(_owner)
        public
    {
        require(_owner != address(0), "Owner must not be zero");
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
    }

     
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be zero");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

     
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = now;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

     
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

     
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self Destruct not yet initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < now, "Self destruct delay not met");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}


 
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


 


 
library SafeDecimalMath {

    using SafeMath for uint;

     
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

     
    uint public constant UNIT = 10 ** uint(decimals);

     
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

     
    function unit()
        external
        pure
        returns (uint)
    {
        return UNIT;
    }

     
    function preciseUnit()
        external
        pure 
        returns (uint)
    {
        return PRECISE_UNIT;
    }

     
    function multiplyDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
         
        return x.mul(y) / UNIT;
    }

     
    function _multiplyDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
         
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

     
    function multiplyDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

     
    function multiplyDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

     
    function divideDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
         
        return x.mul(UNIT).div(y);
    }

     
    function _divideDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

     
    function divideDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

     
    function divideDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

     
    function decimalToPreciseDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

     
    function preciseDecimalToDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

}


 


contract State is Owned {
     
     
    address public associatedContract;


    constructor(address _owner, address _associatedContract)
        Owned(_owner)
        public
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

     

     
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

     

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

     

    event AssociatedContractUpdated(address associatedContract);
}


 


 
contract TokenState is State {

     
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

     
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {}

     

     
    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }

     
    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }
}


 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}


 


contract TokenFallbackCaller is ReentrancyGuard {
    uint constant MAX_GAS_SUB_CALL = 100000;
    function callTokenFallbackIfNeeded(address sender, address recipient, uint amount, bytes data)
        internal
        nonReentrant
    {
         

         
        uint length;

         
        assembly {
             
            length := extcodesize(recipient)
        }

         
        if (length > 0) {
             
            uint gasLimit = gasleft() < MAX_GAS_SUB_CALL ? gasleft() : MAX_GAS_SUB_CALL;
             
             
             
            recipient.call.gas(gasLimit)(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", sender, amount, data));

             
        }
    }
}


 


 
contract ExternStateToken is SelfDestructible, Proxyable, TokenFallbackCaller {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

     

     
    TokenState public tokenState;

     
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

     
    constructor(address _proxy, TokenState _tokenState,
                string _name, string _symbol, uint _totalSupply,
                uint8 _decimals, address _owner)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        public
    {
        tokenState = _tokenState;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
    }

     

     
    function allowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return tokenState.allowance(owner, spender);
    }

     
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return tokenState.balanceOf(account);
    }

     

     
    function setTokenState(TokenState _tokenState)
        external
        optionalProxy_onlyOwner
    {
        tokenState = _tokenState;
        emitTokenStateUpdated(_tokenState);
    }

    function _internalTransfer(address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
         
        require(to != address(0), "Cannot transfer to the 0 address");
        require(to != address(this), "Cannot transfer to the contract");
        require(to != address(proxy), "Cannot transfer to the proxy");

         
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

         
        emitTransfer(from, to, value);

         
         
         
        callTokenFallbackIfNeeded(from, to, value, data);
        
        return true;
    }

     
    function _transfer_byProxy(address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value, data);
    }

     
    function _transferFrom_byProxy(address sender, address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
         
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value, data);
    }

     
    function approve(address spender, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;

        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

     

    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");
    function emitTransfer(address from, address to, uint value) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, bytes32(from), bytes32(to), 0);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");
    function emitApproval(address owner, address spender, uint value) internal {
        proxy._emit(abi.encode(value), 3, APPROVAL_SIG, bytes32(owner), bytes32(spender), 0);
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");
    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}


 


 
contract SupplySchedule is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    struct ScheduleData {
         
        uint totalSupply;

         
        uint startPeriod;

         
        uint endPeriod;

         
        uint totalSupplyMinted;
    }

     
    uint public mintPeriodDuration = 1 weeks;

     
    uint public lastMintEvent;

    Synthetix public synthetix;

    uint constant SECONDS_IN_YEAR = 60 * 60 * 24 * 365;

    uint public constant START_DATE = 1520294400;  
    uint public constant YEAR_ONE = START_DATE + SECONDS_IN_YEAR.mul(1);
    uint public constant YEAR_TWO = START_DATE + SECONDS_IN_YEAR.mul(2);
    uint public constant YEAR_THREE = START_DATE + SECONDS_IN_YEAR.mul(3);
    uint public constant YEAR_FOUR = START_DATE + SECONDS_IN_YEAR.mul(4);
    uint public constant YEAR_FIVE = START_DATE + SECONDS_IN_YEAR.mul(5);
    uint public constant YEAR_SIX = START_DATE + SECONDS_IN_YEAR.mul(6);
    uint public constant YEAR_SEVEN = START_DATE + SECONDS_IN_YEAR.mul(7);

    uint8 constant public INFLATION_SCHEDULES_LENGTH = 7;
    ScheduleData[INFLATION_SCHEDULES_LENGTH] public schedules;

    uint public minterReward = 200 * SafeDecimalMath.unit();

    constructor(address _owner)
        Owned(_owner)
        public
    {
         
         
        schedules[0] = ScheduleData(1e8 * SafeDecimalMath.unit(), START_DATE, YEAR_ONE - 1, 1e8 * SafeDecimalMath.unit());
        schedules[1] = ScheduleData(75e6 * SafeDecimalMath.unit(), YEAR_ONE, YEAR_TWO - 1, 0);  
        schedules[2] = ScheduleData(37.5e6 * SafeDecimalMath.unit(), YEAR_TWO, YEAR_THREE - 1, 0);  
        schedules[3] = ScheduleData(18.75e6 * SafeDecimalMath.unit(), YEAR_THREE, YEAR_FOUR - 1, 0);  
        schedules[4] = ScheduleData(9.375e6 * SafeDecimalMath.unit(), YEAR_FOUR, YEAR_FIVE - 1, 0);  
        schedules[5] = ScheduleData(4.6875e6 * SafeDecimalMath.unit(), YEAR_FIVE, YEAR_SIX - 1, 0);  
        schedules[6] = ScheduleData(0, YEAR_SIX, YEAR_SEVEN - 1, 0);  
    }

     
    function setSynthetix(Synthetix _synthetix)
        external
        onlyOwner
    {
        synthetix = _synthetix;
    }

     
    function mintableSupply()
        public
        view
        returns (uint)
    {
        if (!isMintable()) {
            return 0;
        }

        uint index = getCurrentSchedule();

         
        uint amountPreviousPeriod = _remainingSupplyFromPreviousYear(index);

         

         
         
         
        ScheduleData memory schedule = schedules[index];

        uint weeksInPeriod = (schedule.endPeriod - schedule.startPeriod).div(mintPeriodDuration);

        uint supplyPerWeek = schedule.totalSupply.divideDecimal(weeksInPeriod);

        uint weeksToMint = lastMintEvent >= schedule.startPeriod ? _numWeeksRoundedDown(now.sub(lastMintEvent)) : _numWeeksRoundedDown(now.sub(schedule.startPeriod));
         

        uint amountInPeriod = supplyPerWeek.multiplyDecimal(weeksToMint);
        return amountInPeriod.add(amountPreviousPeriod);
    }

    function _numWeeksRoundedDown(uint _timeDiff)
        public
        view
        returns (uint)
    {
         
         
         
        return _timeDiff.div(mintPeriodDuration);
    }

    function isMintable()
        public
        view
        returns (bool)
    {
        bool mintable = false;
        if (now - lastMintEvent > mintPeriodDuration && now <= schedules[6].endPeriod)  
        {
            mintable = true;
        }
        return mintable;
    }

     
     
    function getCurrentSchedule()
        public
        view
        returns (uint)
    {
        require(now <= schedules[6].endPeriod, "Mintable periods have ended");

        for (uint i = 0; i < INFLATION_SCHEDULES_LENGTH; i++) {
            if (schedules[i].startPeriod <= now && schedules[i].endPeriod >= now) {
                return i;
            }
        }
    }

    function _remainingSupplyFromPreviousYear(uint currentSchedule)
        internal
        view
        returns (uint)
    {
         
         
        if (currentSchedule == 0 || lastMintEvent > schedules[currentSchedule - 1].endPeriod) {
            return 0;
        }

         
        uint amountInPeriod = schedules[currentSchedule - 1].totalSupply.sub(schedules[currentSchedule - 1].totalSupplyMinted);

         
        if (amountInPeriod < 0) {
            return 0;
        }

        return amountInPeriod;
    }

     
    function updateMintValues()
        external
        onlySynthetix
        returns (bool)
    {
         
        uint currentIndex = getCurrentSchedule();
        uint lastPeriodAmount = _remainingSupplyFromPreviousYear(currentIndex);
        uint currentPeriodAmount = mintableSupply().sub(lastPeriodAmount);

         
        if (lastPeriodAmount > 0) {
            schedules[currentIndex - 1].totalSupplyMinted = schedules[currentIndex - 1].totalSupplyMinted.add(lastPeriodAmount);
        }

         
        schedules[currentIndex].totalSupplyMinted = schedules[currentIndex].totalSupplyMinted.add(currentPeriodAmount);
         
        lastMintEvent = now;

        emit SupplyMinted(lastPeriodAmount, currentPeriodAmount, currentIndex, now);
        return true;
    }

    function setMinterReward(uint _amount)
        external
        onlyOwner
    {
        minterReward = _amount;
        emit MinterRewardUpdated(_amount);
    }

     

    modifier onlySynthetix() {
        require(msg.sender == address(synthetix), "Only the synthetix contract can perform this action");
        _;
    }

     

    event SupplyMinted(uint previousPeriodAmount, uint currentAmount, uint indexed schedule, uint timestamp);
    event MinterRewardUpdated(uint newRewardAmount);
}


 


 

contract ExchangeRates is SelfDestructible {


    using SafeMath for uint;
    using SafeDecimalMath for uint;

    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

     
    mapping(bytes32 => RateAndUpdatedTime) private _rates;

     
    address public oracle;

     
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

     
    uint public rateStalePeriod = 3 hours;


     
     
     
    bytes32[5] public xdrParticipants;

     
    mapping(bytes32 => bool) public isXDRParticipant;

     
    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozen;
    }
    mapping(bytes32 => InversePricing) public inversePricing;
    bytes32[] public invertedKeys;

     
     

     
    constructor(
         
        address _owner,

         
        address _oracle,
        bytes32[] _currencyKeys,
        uint[] _newRates
    )
         
        SelfDestructible(_owner)
        public
    {
        require(_currencyKeys.length == _newRates.length, "Currency key length and rate length must match.");

        oracle = _oracle;

         
        _setRate("sUSD", SafeDecimalMath.unit(), now);

         
         
         
         
         
         
         
        xdrParticipants = [
            bytes32("sUSD"),
            bytes32("sAUD"),
            bytes32("sCHF"),
            bytes32("sEUR"),
            bytes32("sGBP")
        ];

         
        isXDRParticipant[bytes32("sUSD")] = true;
        isXDRParticipant[bytes32("sAUD")] = true;
        isXDRParticipant[bytes32("sCHF")] = true;
        isXDRParticipant[bytes32("sEUR")] = true;
        isXDRParticipant[bytes32("sGBP")] = true;

        internalUpdateRates(_currencyKeys, _newRates, now);
    }

    function rates(bytes32 code) public view returns(uint256) {
        return uint256(_rates[code].rate);
    }

    function lastRateUpdateTimes(bytes32 code) public view returns(uint256) {
        return uint256(_rates[code].time);
    }

    function _setRate(bytes32 code, uint256 rate, uint256 time) internal {
        _rates[code] = RateAndUpdatedTime({
            rate: uint216(rate),
            time: uint40(time)
        });
    }

     

     
    function updateRates(bytes32[] currencyKeys, uint[] newRates, uint timeSent)
        external
        onlyOracle
        returns(bool)
    {
        return internalUpdateRates(currencyKeys, newRates, timeSent);
    }

     
    function internalUpdateRates(bytes32[] currencyKeys, uint[] newRates, uint timeSent)
        internal
        returns(bool)
    {
        require(currencyKeys.length == newRates.length, "Currency key array length must match rates array length.");
        require(timeSent < (now + ORACLE_FUTURE_LIMIT), "Time is too far into the future");

        bool recomputeXDRRate = false;

         
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];

             
             
             
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            require(currencyKey != "sUSD", "Rate of sUSD cannot be updated, it's always UNIT.");

             
            if (timeSent < lastRateUpdateTimes(currencyKey)) {
                continue;
            }

            newRates[i] = rateOrInverted(currencyKey, newRates[i]);

             
            _setRate(currencyKey, newRates[i], timeSent);

             
            if (!recomputeXDRRate && isXDRParticipant[currencyKey]) {
                recomputeXDRRate = true;
            }
        }

        emit RatesUpdated(currencyKeys, newRates);

        if (recomputeXDRRate) {
             
            updateXDRRate(timeSent);
        }

        return true;
    }

     
    function rateOrInverted(bytes32 currencyKey, uint rate) internal returns (uint) {
         
        InversePricing storage inverse = inversePricing[currencyKey];
        if (inverse.entryPoint <= 0) {
            return rate;
        }

         
        uint newInverseRate = rates(currencyKey);

         
        if (!inverse.frozen) {
            uint doubleEntryPoint = inverse.entryPoint.mul(2);
            if (doubleEntryPoint <= rate) {
                 
                 
                 
                newInverseRate = 0;
            } else {
                newInverseRate = doubleEntryPoint.sub(rate);
            }

             
            if (newInverseRate >= inverse.upperLimit) {
                newInverseRate = inverse.upperLimit;
            } else if (newInverseRate <= inverse.lowerLimit) {
                newInverseRate = inverse.lowerLimit;
            }

            if (newInverseRate == inverse.upperLimit || newInverseRate == inverse.lowerLimit) {
                inverse.frozen = true;
                emit InversePriceFrozen(currencyKey);
            }
        }

        return newInverseRate;
    }

     
    function updateXDRRate(uint timeSent)
        internal
    {
        uint total = 0;

        for (uint i = 0; i < xdrParticipants.length; i++) {
            total = rates(xdrParticipants[i]).add(total);
        }

         
        _setRate("XDR", total, timeSent);

         
         
        bytes32[] memory eventCurrencyCode = new bytes32[](1);
        eventCurrencyCode[0] = "XDR";

        uint[] memory eventRate = new uint[](1);
        eventRate[0] = rates("XDR");

        emit RatesUpdated(eventCurrencyCode, eventRate);
    }

     
    function deleteRate(bytes32 currencyKey)
        external
        onlyOracle
    {
        require(rates(currencyKey) > 0, "Rate is zero");

        delete _rates[currencyKey];

        emit RateDeleted(currencyKey);
    }

     
    function setOracle(address _oracle)
        external
        onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

     
    function setRateStalePeriod(uint _time)
        external
        onlyOwner
    {
        rateStalePeriod = _time;
        emit RateStalePeriodUpdated(rateStalePeriod);
    }

     
    function setInversePricing(bytes32 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit, bool freeze, bool freezeAtUpperLimit)
        external onlyOwner
    {
        require(entryPoint > 0, "entryPoint must be above 0");
        require(lowerLimit > 0, "lowerLimit must be above 0");
        require(upperLimit > entryPoint, "upperLimit must be above the entryPoint");
        require(upperLimit < entryPoint.mul(2), "upperLimit must be less than double entryPoint");
        require(lowerLimit < entryPoint, "lowerLimit must be below the entryPoint");

        if (inversePricing[currencyKey].entryPoint <= 0) {
             
            invertedKeys.push(currencyKey);
        }
        inversePricing[currencyKey].entryPoint = entryPoint;
        inversePricing[currencyKey].upperLimit = upperLimit;
        inversePricing[currencyKey].lowerLimit = lowerLimit;
        inversePricing[currencyKey].frozen = freeze;

        emit InversePriceConfigured(currencyKey, entryPoint, upperLimit, lowerLimit);

         
         
         
        if (freeze) {
            emit InversePriceFrozen(currencyKey);

            _setRate(currencyKey, freezeAtUpperLimit ? upperLimit : lowerLimit, now);
        }
    }

     
    function removeInversePricing(bytes32 currencyKey) external onlyOwner
    {
        require(inversePricing[currencyKey].entryPoint > 0, "No inverted price exists");

        inversePricing[currencyKey].entryPoint = 0;
        inversePricing[currencyKey].upperLimit = 0;
        inversePricing[currencyKey].lowerLimit = 0;
        inversePricing[currencyKey].frozen = false;

         
        for (uint i = 0; i < invertedKeys.length; i++) {
            if (invertedKeys[i] == currencyKey) {
                delete invertedKeys[i];

                 
                 
                 
                invertedKeys[i] = invertedKeys[invertedKeys.length - 1];

                 
                invertedKeys.length--;

                 
                emit InversePriceConfigured(currencyKey, 0, 0, 0);

                return;
            }
        }
    }
     

     
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        public
        view
        rateNotStale(sourceCurrencyKey)
        rateNotStale(destinationCurrencyKey)
        returns (uint)
    {
         
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

         
        return sourceAmount.multiplyDecimalRound(rateForCurrency(sourceCurrencyKey))
            .divideDecimalRound(rateForCurrency(destinationCurrencyKey));
    }

     
    function rateForCurrency(bytes32 currencyKey)
        public
        view
        returns (uint)
    {
        return rates(currencyKey);
    }

     
    function ratesForCurrencies(bytes32[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            _localRates[i] = rates(currencyKeys[i]);
        }

        return _localRates;
    }

     
    function ratesAndStaleForCurrencies(bytes32[] currencyKeys)
        public
        view
        returns (uint[], bool)
    {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        bool anyRateStale = false;
        uint period = rateStalePeriod;
        for (uint i = 0; i < currencyKeys.length; i++) {
            RateAndUpdatedTime memory rateAndUpdateTime = _rates[currencyKeys[i]];
            _localRates[i] = uint256(rateAndUpdateTime.rate);
            if (!anyRateStale) {
                anyRateStale = (currencyKeys[i] != "sUSD" && uint256(rateAndUpdateTime.time).add(period) < now);
            }
        }

        return (_localRates, anyRateStale);
    }

     
    function lastRateUpdateTimeForCurrency(bytes32 currencyKey)
        public
        view
        returns (uint)
    {
        return lastRateUpdateTimes(currencyKey);
    }

     
    function lastRateUpdateTimesForCurrencies(bytes32[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = lastRateUpdateTimes(currencyKeys[i]);
        }

        return lastUpdateTimes;
    }

     
    function rateIsStale(bytes32 currencyKey)
        public
        view
        returns (bool)
    {
         
        if (currencyKey == "sUSD") return false;

        return lastRateUpdateTimes(currencyKey).add(rateStalePeriod) < now;
    }

     
    function rateIsFrozen(bytes32 currencyKey)
        external
        view
        returns (bool)
    {
        return inversePricing[currencyKey].frozen;
    }


     
    function anyRateIsStale(bytes32[] currencyKeys)
        external
        view
        returns (bool)
    {
         
        uint256 i = 0;

        while (i < currencyKeys.length) {
             
            if (currencyKeys[i] != "sUSD" && lastRateUpdateTimes(currencyKeys[i]).add(rateStalePeriod) < now) {
                return true;
            }
            i += 1;
        }

        return false;
    }

     

    modifier rateNotStale(bytes32 currencyKey) {
        require(!rateIsStale(currencyKey), "Rate stale or nonexistant currency");
        _;
    }

    modifier onlyOracle
    {
        require(msg.sender == oracle, "Only the oracle can perform this action");
        _;
    }

     

    event OracleUpdated(address newOracle);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event RatesUpdated(bytes32[] currencyKeys, uint[] newRates);
    event RateDeleted(bytes32 currencyKey);
    event InversePriceConfigured(bytes32 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit);
    event InversePriceFrozen(bytes32 currencyKey);
}


 


 
contract LimitedSetup {

    uint setupExpiryTime;

     
    constructor(uint setupDuration)
        public
    {
        setupExpiryTime = now + setupDuration;
    }

    modifier onlyDuringSetup
    {
        require(now < setupExpiryTime, "Can only perform this action during setup");
        _;
    }
}


 


 
contract SynthetixState is State, LimitedSetup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    struct IssuanceData {
         
         
         
         
         
        uint initialDebtOwnership;
         
         
         
        uint debtEntryIndex;
    }

     
    mapping(address => IssuanceData) public issuanceData;

     
    uint public totalIssuerCount;

     
    uint[] public debtLedger;

     
    uint public importedXDRAmount;

     
     
    uint public issuanceRatio = SafeDecimalMath.unit() / 5;
     
    uint constant MAX_ISSUANCE_RATIO = SafeDecimalMath.unit();

     
     
    mapping(address => bytes4) public preferredCurrency;

     
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        LimitedSetup(1 weeks)
        public
    {}

     

     
    function setCurrentIssuanceData(address account, uint initialDebtOwnership)
        external
        onlyAssociatedContract
    {
        issuanceData[account].initialDebtOwnership = initialDebtOwnership;
        issuanceData[account].debtEntryIndex = debtLedger.length;
    }

     
    function clearIssuanceData(address account)
        external
        onlyAssociatedContract
    {
        delete issuanceData[account];
    }

     
    function incrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.add(1);
    }

     
    function decrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.sub(1);
    }

     
    function appendDebtLedgerValue(uint value)
        external
        onlyAssociatedContract
    {
        debtLedger.push(value);
    }

     
    function setPreferredCurrency(address account, bytes4 currencyKey)
        external
        onlyAssociatedContract
    {
        preferredCurrency[account] = currencyKey;
    }

     
    function setIssuanceRatio(uint _issuanceRatio)
        external
        onlyOwner
    {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        issuanceRatio = _issuanceRatio;
        emit IssuanceRatioUpdated(_issuanceRatio);
    }

     
    function importIssuerData(address[] accounts, uint[] sUSDAmounts)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == sUSDAmounts.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            _addToDebtRegister(accounts[i], sUSDAmounts[i]);
        }
    }

     
    function _addToDebtRegister(address account, uint amount)
        internal
    {
         
         
        Synthetix synthetix = Synthetix(associatedContract);

         
        uint xdrValue = synthetix.effectiveValue("sUSD", amount, "XDR");

         
        uint totalDebtIssued = importedXDRAmount;

         
        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);

         
        importedXDRAmount = newTotalDebtIssued;

         
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

         
         
         
         
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);

        uint existingDebt = synthetix.debtBalanceOf(account, "XDR");

         
        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

         
        if (issuanceData[account].initialDebtOwnership == 0) {
            totalIssuerCount = totalIssuerCount.add(1);
        }

         
        issuanceData[account].initialDebtOwnership = debtPercentage;
        issuanceData[account].debtEntryIndex = debtLedger.length;

         
         
        if (debtLedger.length > 0) {
            debtLedger.push(
                debtLedger[debtLedger.length - 1].multiplyDecimalRoundPrecise(delta)
            );
        } else {
            debtLedger.push(SafeDecimalMath.preciseUnit());
        }
    }

     

     
    function debtLedgerLength()
        external
        view
        returns (uint)
    {
        return debtLedger.length;
    }

     
    function lastDebtLedgerEntry()
        external
        view
        returns (uint)
    {
        return debtLedger[debtLedger.length - 1];
    }

     
    function hasIssued(address account)
        external
        view
        returns (bool)
    {
        return issuanceData[account].initialDebtOwnership > 0;
    }

    event IssuanceRatioUpdated(uint newRatio);
}


 
contract IFeePool {
    address public FEE_ADDRESS;
    uint public exchangeFeeRate;
    function amountReceivedFromExchange(uint value) external view returns (uint);
    function amountReceivedFromTransfer(uint value) external view returns (uint);
    function recordFeePaid(uint xdrAmount) external;
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex) external;
    function setRewardsToDistribute(uint amount) external;
}


 
contract ISynthetixState {
     
    struct IssuanceData {
         
         
         
         
         
        uint initialDebtOwnership;
         
         
         
        uint debtEntryIndex;
    }

    uint[] public debtLedger;
    uint public issuanceRatio;
    mapping(address => IssuanceData) public issuanceData;

    function debtLedgerLength() external view returns (uint);
    function hasIssued(address account) external view returns (bool);
    function incrementTotalIssuerCount() external;
    function decrementTotalIssuerCount() external;
    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external;
    function lastDebtLedgerEntry() external view returns (uint);
    function appendDebtLedgerValue(uint value) external;
    function clearIssuanceData(address account) external;
}


interface ISynth {
    function burn(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function transfer(address to, uint value) public returns (bool);
    function triggerTokenFallbackIfNeeded(address sender, address recipient, uint amount) external;
    function transferFrom(address from, address to, uint value) public returns (bool);
}


 
interface ISynthetixEscrow {
    function balanceOf(address account) public view returns (uint);
    function appendVestingEntry(address account, uint quantity) public;
}


 
interface IExchangeRates {
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) external view returns (uint);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);
    function ratesForCurrencies(bytes32[] currencyKeys) external view returns (uint[] memory);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);
    function anyRateIsStale(bytes32[] currencyKeys) external view returns (bool);
}


 


contract ISynthetix {

     

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ISynthetixState public synthetixState;
    IExchangeRates public exchangeRates;

    mapping(bytes32 => Synth) public synths;

     

    function balanceOf(address account) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) public view returns (uint);

    function synthInitiatedExchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress) external returns (bool);
    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey) external returns (bool);
    function collateralisationRatio(address issuer) public view returns (uint);
    function totalIssuedSynths(bytes32 currencyKey)
        public
        view
        returns (uint);
    function getSynth(bytes32 currencyKey) public view returns (ISynth);
    function debtBalanceOf(address issuer, bytes32 currencyKey) public view returns (uint);
}


 


contract Synth is ExternStateToken {

     

     
    address public feePoolProxy;
     
    address public synthetixProxy;

     
    bytes32 public currencyKey;

    uint8 constant DECIMALS = 18;

     

    constructor(address _proxy, TokenState _tokenState, address _synthetixProxy, address _feePoolProxy,
        string _tokenName, string _tokenSymbol, address _owner, bytes32 _currencyKey, uint _totalSupply
    )
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, _totalSupply, DECIMALS, _owner)
        public
    {
        require(_proxy != address(0), "_proxy cannot be 0");
        require(_synthetixProxy != address(0), "_synthetixProxy cannot be 0");
        require(_feePoolProxy != address(0), "_feePoolProxy cannot be 0");
        require(_owner != 0, "_owner cannot be 0");
        require(ISynthetix(_synthetixProxy).synths(_currencyKey) == Synth(0), "Currency key is already in use");

        feePoolProxy = _feePoolProxy;
        synthetixProxy = _synthetixProxy;
        currencyKey = _currencyKey;
    }

     

     
    function setSynthetixProxy(ISynthetix _synthetixProxy)
        external
        optionalProxy_onlyOwner
    {
        synthetixProxy = _synthetixProxy;
        emitSynthetixUpdated(_synthetixProxy);
    }

     
    function setFeePoolProxy(address _feePoolProxy)
        external
        optionalProxy_onlyOwner
    {
        feePoolProxy = _feePoolProxy;
        emitFeePoolUpdated(_feePoolProxy);
    }

     

     
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        bytes memory empty;
        return super._internalTransfer(messageSender, to, value, empty);
    }

     
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
         
        return super._internalTransfer(messageSender, to, value, data);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(from != 0xfeefeefeefeefeefeefeefeefeefeefeefeefeef, "The fee address is not allowed");
         
        if (tokenState.allowance(from, messageSender) != uint(-1)) {
             
             
            tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));
        }

        bytes memory empty;
        return super._internalTransfer(from, to, value, empty);
    }

     
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
        require(from != 0xfeefeefeefeefeefeefeefeefeefeefeefeefeef, "The fee address is not allowed");

         
        if (tokenState.allowance(from, messageSender) != uint(-1)) {
             
             
            tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));
        }

        return super._internalTransfer(from, to, value, data);
    }

     
    function issue(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

     
    function burn(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }

     
    function setTotalSupply(uint amount)
        external
        optionalProxy_onlyOwner
    {
        totalSupply = amount;
    }

     
     
    function triggerTokenFallbackIfNeeded(address sender, address recipient, uint amount)
        external
        onlySynthetixOrFeePool
    {
        bytes memory empty;
        callTokenFallbackIfNeeded(sender, recipient, amount, empty);
    }

     

    modifier onlySynthetixOrFeePool() {
        bool isSynthetix = msg.sender == address(Proxy(synthetixProxy).target());
        bool isFeePool = msg.sender == address(Proxy(feePoolProxy).target());

        require(isSynthetix || isFeePool, "Only Synthetix, FeePool allowed");
        _;
    }

     

    event SynthetixUpdated(address newSynthetix);
    bytes32 constant SYNTHETIXUPDATED_SIG = keccak256("SynthetixUpdated(address)");
    function emitSynthetixUpdated(address newSynthetix) internal {
        proxy._emit(abi.encode(newSynthetix), 1, SYNTHETIXUPDATED_SIG, 0, 0, 0);
    }

    event FeePoolUpdated(address newFeePool);
    bytes32 constant FEEPOOLUPDATED_SIG = keccak256("FeePoolUpdated(address)");
    function emitFeePoolUpdated(address newFeePool) internal {
        proxy._emit(abi.encode(newFeePool), 1, FEEPOOLUPDATED_SIG, 0, 0, 0);
    }

    event Issued(address indexed account, uint value);
    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, bytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);
    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, bytes32(account), 0, 0);
    }
}


 
interface IRewardsDistribution {
    function distributeRewards(uint amount) external;
}


 
contract Synthetix is ExternStateToken {

     

     
    Synth[] public availableSynths;
    mapping(bytes32 => Synth) public synths;
    mapping(address => bytes32) public synthsByAddress;

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ExchangeRates public exchangeRates;
    SynthetixState public synthetixState;
    SupplySchedule public supplySchedule;
    IRewardsDistribution public rewardsDistribution;

    bool private protectionCircuit = false;

    string constant TOKEN_NAME = "Synthetix Network Token";
    string constant TOKEN_SYMBOL = "SNX";
    uint8 constant DECIMALS = 18;
    bool public exchangeEnabled = true;
    uint public gasPriceLimit;

    address public gasLimitOracle;
     

     
    constructor(address _proxy, TokenState _tokenState, SynthetixState _synthetixState,
        address _owner, ExchangeRates _exchangeRates, IFeePool _feePool, SupplySchedule _supplySchedule,
        ISynthetixEscrow _rewardEscrow, ISynthetixEscrow _escrow, IRewardsDistribution _rewardsDistribution, uint _totalSupply
    )
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, _totalSupply, DECIMALS, _owner)
        public
    {
        synthetixState = _synthetixState;
        exchangeRates = _exchangeRates;
        feePool = _feePool;
        supplySchedule = _supplySchedule;
        rewardEscrow = _rewardEscrow;
        escrow = _escrow;
        rewardsDistribution = _rewardsDistribution;
    }
     

    function setFeePool(IFeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
    }

    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
    }

    function setProtectionCircuit(bool _protectionCircuitIsActivated)
        external
        onlyOracle
    {
        protectionCircuit = _protectionCircuitIsActivated;
    }

    function setExchangeEnabled(bool _exchangeEnabled)
        external
        optionalProxy_onlyOwner
    {
        exchangeEnabled = _exchangeEnabled;
    }

    function setGasLimitOracle(address _gasLimitOracle)
        external
        optionalProxy_onlyOwner
    {
        gasLimitOracle = _gasLimitOracle;
    }

    function setGasPriceLimit(uint _gasPriceLimit)
        external
    {
        require(msg.sender == gasLimitOracle, "Only gas limit oracle allowed");
        require(_gasPriceLimit > 0, "Needs to be greater than 0");
        gasPriceLimit = _gasPriceLimit;
    }

     
    function addSynth(Synth synth)
        external
        optionalProxy_onlyOwner
    {
        bytes32 currencyKey = synth.currencyKey();

        require(synths[currencyKey] == Synth(0), "Synth already exists");
        require(synthsByAddress[synth] == bytes32(0), "Synth address already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;
        synthsByAddress[synth] = currencyKey;
    }

     
    function removeSynth(bytes32 currencyKey)
        external
        optionalProxy_onlyOwner
    {
        require(synths[currencyKey] != address(0), "Synth does not exist");
        require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
        require(currencyKey != "XDR", "Cannot remove XDR synth");
        require(currencyKey != "sUSD", "Cannot remove sUSD synth");

         
        address synthToRemove = synths[currencyKey];

         
        for (uint i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == synthToRemove) {
                delete availableSynths[i];

                 
                 
                 
                availableSynths[i] = availableSynths[availableSynths.length - 1];

                 
                availableSynths.length--;

                break;
            }
        }

         
        delete synthsByAddress[synths[currencyKey]];
        delete synths[currencyKey];

         
         
         
    }

     

     
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        public
        view
        returns (uint)
    {
        return exchangeRates.effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

     
    function totalIssuedSynths(bytes32 currencyKey)
        public
        view
        returns (uint)
    {
        uint total = 0;
        uint currencyRate = exchangeRates.rateForCurrency(currencyKey);

        (uint[] memory rates, bool anyRateStale) = exchangeRates.ratesAndStaleForCurrencies(availableCurrencyKeys());
        require(!anyRateStale, "Rates are stale");

        for (uint i = 0; i < availableSynths.length; i++) {
             
             
             
             
            uint synthValue = availableSynths[i].totalSupply()
                .multiplyDecimalRound(rates[i]);
            total = total.add(synthValue);
        }

        return total.divideDecimalRound(currencyRate);
    }

     
    function availableCurrencyKeys()
        public
        view
        returns (bytes32[])
    {
        bytes32[] memory currencyKeys = new bytes32[](availableSynths.length);

        for (uint i = 0; i < availableSynths.length; i++) {
            currencyKeys[i] = synthsByAddress[availableSynths[i]];
        }

        return currencyKeys;
    }

     
    function availableSynthCount()
        public
        view
        returns (uint)
    {
        return availableSynths.length;
    }

     
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        public
        view
        returns (uint)
    {
         
        uint exchangeFeeRate = feePool.exchangeFeeRate();

        uint multiplier = 1;

         
         
        if (
            (sourceCurrencyKey[0] == 0x73 && sourceCurrencyKey != "sUSD" && destinationCurrencyKey[0] == 0x69) ||
            (sourceCurrencyKey[0] == 0x69 && destinationCurrencyKey != "sUSD" && destinationCurrencyKey[0] == 0x73)
        ) {
             
            multiplier = 2;
        }

        return exchangeFeeRate.mul(multiplier);
    }
     

     
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transfer(to, value, empty);
    }

     
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
         
        require(value <= transferableSynthetix(messageSender), "Insufficient balance");

         
        _transfer_byProxy(messageSender, to, value, data);

        return true;
    }

     
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transferFrom(from, to, value, empty);
    }

     
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
         
        require(value <= transferableSynthetix(from), "Insufficient balance");

         
         
        _transferFrom_byProxy(messageSender, from, to, value, data);

        return true;
    }

     
    function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        external
        optionalProxy
         
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Must use different synths");
        require(sourceAmount > 0, "Zero amount");

         
        validateGasPrice(tx.gasprice);

         
        if (protectionCircuit) {
            synths[sourceCurrencyKey].burn(messageSender, sourceAmount);
            return true;
        } else {
             
            return _internalExchange(
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                true  
            );
        }
    }

     
    function validateGasPrice(uint _givenGasPrice)
        public
        view
    {
        require(_givenGasPrice <= gasPriceLimit, "Gas price above limit");
    }

     
    function synthInitiatedExchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    )
        external
        optionalProxy
        returns (bool)
    {
        require(synthsByAddress[messageSender] != bytes32(0), "Only synth allowed");
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
        require(sourceAmount > 0, "Zero amount");

         
        return _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress,
            false
        );
    }

     
    function _internalExchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool chargeFee
    )
        internal
        notFeeAddress(from)
        returns (bool)
    {
        require(exchangeEnabled, "Exchanging is disabled");

         
         

         
        synths[sourceCurrencyKey].burn(from, sourceAmount);

         
        uint destinationAmount = effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

         
        uint amountReceived = destinationAmount;
        uint fee = 0;

        if (chargeFee) {
             
            uint exchangeFeeRate = feeRateForExchange(sourceCurrencyKey, destinationCurrencyKey);

            amountReceived = destinationAmount.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));

            fee = destinationAmount.sub(amountReceived);
        }

         
        synths[destinationCurrencyKey].issue(destinationAddress, amountReceived);

         
        if (fee > 0) {
            uint xdrFeeAmount = effectiveValue(destinationCurrencyKey, fee, "XDR");
            synths["XDR"].issue(feePool.FEE_ADDRESS(), xdrFeeAmount);
             
            feePool.recordFeePaid(xdrFeeAmount);
        }

         

         
        synths[destinationCurrencyKey].triggerTokenFallbackIfNeeded(from, destinationAddress, amountReceived);

         
        emitSynthExchange(from, sourceCurrencyKey, sourceAmount, destinationCurrencyKey, amountReceived, destinationAddress);

        return true;
    }

     
    function _addToDebtRegister(bytes32 currencyKey, uint amount)
        internal
    {
         
        uint xdrValue = effectiveValue(currencyKey, amount, "XDR");

         
        uint totalDebtIssued = totalIssuedSynths("XDR");

         
        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);

         
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

         
         
         
         
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);

         
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

         
        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

         
        if (existingDebt == 0) {
            synthetixState.incrementTotalIssuerCount();
        }

         
        synthetixState.setCurrentIssuanceData(messageSender, debtPercentage);

         
         
        if (synthetixState.debtLedgerLength() > 0) {
            synthetixState.appendDebtLedgerValue(
                synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
            );
        } else {
            synthetixState.appendDebtLedgerValue(SafeDecimalMath.preciseUnit());
        }
    }

     
    function issueSynths(uint amount)
        public
        optionalProxy
         
    {
        bytes32 currencyKey = "sUSD";

        require(amount <= remainingIssuableSynths(messageSender, currencyKey), "Amount too large");

         
        _addToDebtRegister(currencyKey, amount);

         
        synths[currencyKey].issue(messageSender, amount);

         
        _appendAccountIssuanceRecord();
    }

     
    function issueMaxSynths()
        external
        optionalProxy
    {
        bytes32 currencyKey = "sUSD";

         
        uint maxIssuable = remainingIssuableSynths(messageSender, currencyKey);

         
        _addToDebtRegister(currencyKey, maxIssuable);

         
        synths[currencyKey].issue(messageSender, maxIssuable);

         
        _appendAccountIssuanceRecord();
    }

     
    function burnSynths(uint amount)
        external
        optionalProxy
         
    {
        bytes32 currencyKey = "sUSD";

         
        uint debtToRemove = effectiveValue(currencyKey, amount, "XDR");
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

        uint debtInCurrencyKey = debtBalanceOf(messageSender, currencyKey);

        require(existingDebt > 0, "No debt to forgive");

         
         
        uint amountToRemove = existingDebt < debtToRemove ? existingDebt : debtToRemove;

         
        _removeFromDebtRegister(amountToRemove, existingDebt);

        uint amountToBurn = debtInCurrencyKey < amount ? debtInCurrencyKey : amount;

         
        synths[currencyKey].burn(messageSender, amountToBurn);

         
        _appendAccountIssuanceRecord();
    }

     
    function _appendAccountIssuanceRecord()
        internal
    {
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(messageSender);

        feePool.appendAccountIssuanceRecord(
            messageSender,
            initialDebtOwnership,
            debtEntryIndex
        );
    }

     
    function _removeFromDebtRegister(uint amount, uint existingDebt)
        internal
    {
        uint debtToRemove = amount;

         
        uint totalDebtIssued = totalIssuedSynths("XDR");

         
        uint newTotalDebtIssued = totalDebtIssued.sub(debtToRemove);

        uint delta = 0;

         
         
        if (newTotalDebtIssued > 0) {

             
            uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(newTotalDebtIssued);

             
             
             
            delta = SafeDecimalMath.preciseUnit().add(debtPercentage);
        }

         
        if (debtToRemove == existingDebt) {
            synthetixState.setCurrentIssuanceData(messageSender, 0);
            synthetixState.decrementTotalIssuerCount();
        } else {
             
            uint newDebt = existingDebt.sub(debtToRemove);
            uint newDebtPercentage = newDebt.divideDecimalRoundPrecise(newTotalDebtIssued);

             
            synthetixState.setCurrentIssuanceData(messageSender, newDebtPercentage);
        }

         
        synthetixState.appendDebtLedgerValue(
            synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
        );
    }

     

     
    function maxIssuableSynths(address issuer, bytes32 currencyKey)
        public
        view
         
        returns (uint)
    {
         
        uint destinationValue = effectiveValue("SNX", collateral(issuer), currencyKey);

         
        return destinationValue.multiplyDecimal(synthetixState.issuanceRatio());
    }

     
    function collateralisationRatio(address issuer)
        public
        view
        returns (uint)
    {
        uint totalOwnedSynthetix = collateral(issuer);
        if (totalOwnedSynthetix == 0) return 0;

        uint debtBalance = debtBalanceOf(issuer, "SNX");
        return debtBalance.divideDecimalRound(totalOwnedSynthetix);
    }

     
    function debtBalanceOf(address issuer, bytes32 currencyKey)
        public
        view
         
        returns (uint)
    {
         
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(issuer);

         
        if (initialDebtOwnership == 0) return 0;

         
         
        uint currentDebtOwnership = synthetixState.lastDebtLedgerEntry()
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(initialDebtOwnership);

         
        uint totalSystemValue = totalIssuedSynths(currencyKey);

         
        uint highPrecisionBalance = totalSystemValue.decimalToPreciseDecimal()
            .multiplyDecimalRoundPrecise(currentDebtOwnership);

        return highPrecisionBalance.preciseDecimalToDecimal();
    }

     
    function remainingIssuableSynths(address issuer, bytes32 currencyKey)
        public
        view
         
        returns (uint)
    {
        uint alreadyIssued = debtBalanceOf(issuer, currencyKey);
        uint max = maxIssuableSynths(issuer, currencyKey);

        if (alreadyIssued >= max) {
            return 0;
        } else {
            return max.sub(alreadyIssued);
        }
    }

     
    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint balance = tokenState.balanceOf(account);

        if (escrow != address(0)) {
            balance = balance.add(escrow.balanceOf(account));
        }

        if (rewardEscrow != address(0)) {
            balance = balance.add(rewardEscrow.balanceOf(account));
        }

        return balance;
    }

     
    function transferableSynthetix(address account)
        public
        view
        rateNotStale("SNX")  
        returns (uint)
    {
         
         
         
        uint balance = tokenState.balanceOf(account);

         
         
         
         
        uint lockedSynthetixValue = debtBalanceOf(account, "SNX").divideDecimalRound(synthetixState.issuanceRatio());

         
        if (lockedSynthetixValue >= balance) {
            return 0;
        } else {
            return balance.sub(lockedSynthetixValue);
        }
    }

     
    function mint()
        external
        returns (bool)
    {
        require(rewardsDistribution != address(0), "RewardsDistribution not set");

        uint supplyToMint = supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        supplySchedule.updateMintValues();

         
         
        uint minterReward = supplySchedule.minterReward();
         
        uint amountToDistribute = supplyToMint.sub(minterReward);

         
        tokenState.setBalanceOf(rewardsDistribution, tokenState.balanceOf(rewardsDistribution).add(amountToDistribute));
        emitTransfer(this, rewardsDistribution, amountToDistribute);

         
        rewardsDistribution.distributeRewards(amountToDistribute);

         
        tokenState.setBalanceOf(msg.sender, tokenState.balanceOf(msg.sender).add(minterReward));
        emitTransfer(this, msg.sender, minterReward);

        totalSupply = totalSupply.add(supplyToMint);

        return true;
    }

     

    modifier rateNotStale(bytes32 currencyKey) {
        require(!exchangeRates.rateIsStale(currencyKey), "Rate stale or not a synth");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Fee address not allowed");
        _;
    }

    modifier onlyOracle
    {
        require(msg.sender == exchangeRates.oracle(), "Only oracle allowed");
        _;
    }

     
     
    event SynthExchange(address indexed account, bytes32 fromCurrencyKey, uint256 fromAmount, bytes32 toCurrencyKey,  uint256 toAmount, address toAddress);
    bytes32 constant SYNTHEXCHANGE_SIG = keccak256("SynthExchange(address,bytes32,uint256,bytes32,uint256,address)");
    function emitSynthExchange(address account, bytes32 fromCurrencyKey, uint256 fromAmount, bytes32 toCurrencyKey, uint256 toAmount, address toAddress) internal {
        proxy._emit(abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress), 2, SYNTHEXCHANGE_SIG, bytes32(account), 0, 0);
    }
     
}


 


contract FeePoolState is SelfDestructible, LimitedSetup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

     

    uint8 constant public FEE_PERIOD_LENGTH = 6;

    address public feePool;

     
    struct IssuanceData {
        uint debtPercentage;
        uint debtEntryIndex;
    }

     
    mapping(address => IssuanceData[FEE_PERIOD_LENGTH]) public accountIssuanceLedger;

     
    constructor(address _owner, IFeePool _feePool)
        SelfDestructible(_owner)
        LimitedSetup(6 weeks)
        public
    {
        feePool = _feePool;
    }

     

     
    function setFeePool(IFeePool _feePool)
        external
        onlyOwner
    {
        feePool = _feePool;
    }

     

     
    function getAccountsDebtEntry(address account, uint index)
        public
        view
        returns (uint debtPercentage, uint debtEntryIndex)
    {
        require(index < FEE_PERIOD_LENGTH, "index exceeds the FEE_PERIOD_LENGTH");

        debtPercentage = accountIssuanceLedger[account][index].debtPercentage;
        debtEntryIndex = accountIssuanceLedger[account][index].debtEntryIndex;
    }

     
    function applicableIssuanceData(address account, uint closingDebtIndex)
        external
        view
        returns (uint, uint)
    {
        IssuanceData[FEE_PERIOD_LENGTH] memory issuanceData = accountIssuanceLedger[account];
        
         
         
        for (uint i = 0; i < FEE_PERIOD_LENGTH; i++) {
            if (closingDebtIndex >= issuanceData[i].debtEntryIndex) {
                return (issuanceData[i].debtPercentage, issuanceData[i].debtEntryIndex);
            }
        }
    }

     

     
    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex, uint currentPeriodStartDebtIndex)
        external
        onlyFeePool
    {
         
        if (accountIssuanceLedger[account][0].debtEntryIndex < currentPeriodStartDebtIndex) {
              
            issuanceDataIndexOrder(account);
        }
        
         
        accountIssuanceLedger[account][0].debtPercentage = debtRatio;
        accountIssuanceLedger[account][0].debtEntryIndex = debtEntryIndex;
    }

     
    function issuanceDataIndexOrder(address account)
        private
    {
        for (uint i = FEE_PERIOD_LENGTH - 2; i < FEE_PERIOD_LENGTH; i--) {
            uint next = i + 1;
            accountIssuanceLedger[account][next].debtPercentage = accountIssuanceLedger[account][i].debtPercentage;
            accountIssuanceLedger[account][next].debtEntryIndex = accountIssuanceLedger[account][i].debtEntryIndex;
        }
    }

     
    function importIssuerData(address[] accounts, uint[] ratios, uint periodToInsert, uint feePeriodCloseIndex)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == ratios.length, "Length mismatch");

        for (uint i = 0; i < accounts.length; i++) {
            accountIssuanceLedger[accounts[i]][periodToInsert].debtPercentage = ratios[i];
            accountIssuanceLedger[accounts[i]][periodToInsert].debtEntryIndex = feePeriodCloseIndex;
            emit IssuanceDebtRatioEntry(accounts[i], ratios[i], feePeriodCloseIndex);
        }
    }

     

    modifier onlyFeePool
    {
        require(msg.sender == address(feePool), "Only the FeePool contract can perform this action");
        _;
    }

     
    event IssuanceDebtRatioEntry(address indexed account, uint debtRatio, uint feePeriodCloseIndex);
}


 


 
contract EternalStorage is State {

    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {
    }

     
    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;

     
    function getUIntValue(bytes32 record) external view returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external
        onlyAssociatedContract
    {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete UIntStorage[record];
    }

     
    function getStringValue(bytes32 record) external view returns (string memory){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) external
        onlyAssociatedContract
    {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete StringStorage[record];
    }

     
    function getAddressValue(bytes32 record) external view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external
        onlyAssociatedContract
    {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete AddressStorage[record];
    }


     
    function getBytesValue(bytes32 record) external view returns
    (bytes memory){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes value) external
        onlyAssociatedContract
    {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BytesStorage[record];
    }

     
    function getBytes32Value(bytes32 record) external view returns (bytes32)
    {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external
        onlyAssociatedContract
    {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external
        onlyAssociatedContract
    {
        delete Bytes32Storage[record];
    }

     
    function getBooleanValue(bytes32 record) external view returns (bool)
    {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external
        onlyAssociatedContract
    {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BooleanStorage[record];
    }

     
    function getIntValue(bytes32 record) external view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external
        onlyAssociatedContract
    {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete IntStorage[record];
    }
}

 


contract FeePoolEternalStorage is EternalStorage, LimitedSetup {

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

     
    constructor(address _owner, address _feePool)
        EternalStorage(_owner, _feePool)
        LimitedSetup(6 weeks)
        public
    {
    }

     
    function importFeeWithdrawalData(address[] accounts, uint[] feePeriodIDs)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == feePeriodIDs.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            this.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, accounts[i])), feePeriodIDs[i]);
        }
    }
}


 


contract DelegateApprovals is State {

     
     
    mapping(address => mapping(address => bool)) public approval;

     
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {}

    function setApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        approval[authoriser][delegate] = true;
        emit Approval(authoriser, delegate);
    }

    function withdrawApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        delete approval[authoriser][delegate];
        emit WithdrawApproval(authoriser, delegate);
    }

      

    event Approval(address indexed authoriser, address delegate);
    event WithdrawApproval(address indexed authoriser, address delegate);
}


contract FeePool is Proxyable, SelfDestructible, LimitedSetup {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    Synthetix public synthetix;
    ISynthetixState public synthetixState;
    ISynthetixEscrow public rewardEscrow;
    FeePoolEternalStorage public feePoolEternalStorage;

     
    uint public exchangeFeeRate;

     
    uint constant public MAX_EXCHANGE_FEE_RATE = SafeDecimalMath.unit() / 10;

     
    address public rewardsAuthority;

     
    FeePoolState public feePoolState;

     
    DelegateApprovals public delegates;

     
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

     
    struct FeePeriod {
        uint64 feePeriodId;
        uint64 startingDebtIndex;
        uint64 startTime;
        uint feesToDistribute;
        uint feesClaimed;
        uint rewardsToDistribute;
        uint rewardsClaimed;
    }

     
     
     
     
     
     
    uint8 constant public FEE_PERIOD_LENGTH = 3;

    FeePeriod[FEE_PERIOD_LENGTH] private _recentFeePeriods;
    uint256 private _currentFeePeriod;

     
     
     
     
    uint public feePeriodDuration = 1 weeks;
     
    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;

     
    uint public targetThreshold = (10 * SafeDecimalMath.unit()) / 100;

     

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    constructor(
        address _proxy,
        address _owner,
        Synthetix _synthetix,
        FeePoolState _feePoolState,
        FeePoolEternalStorage _feePoolEternalStorage,
        ISynthetixState _synthetixState,
        ISynthetixEscrow _rewardEscrow,
        address _rewardsAuthority,
        uint _exchangeFeeRate)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        LimitedSetup(3 weeks)
        public
    {
         
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "Exchange fee rate max exceeded");

        synthetix = _synthetix;
        feePoolState = _feePoolState;
        feePoolEternalStorage = _feePoolEternalStorage;
        rewardEscrow = _rewardEscrow;
        synthetixState = _synthetixState;
        rewardsAuthority = _rewardsAuthority;
        exchangeFeeRate = _exchangeFeeRate;

         
        _recentFeePeriodsStorage(0).feePeriodId = 1;
        _recentFeePeriodsStorage(0).startTime = uint64(now);
    }

    function recentFeePeriods(uint index) external view
        returns(
            uint64 feePeriodId,
            uint64 startingDebtIndex,
            uint64 startTime,
            uint feesToDistribute,
            uint feesClaimed,
            uint rewardsToDistribute,
            uint rewardsClaimed
        )
    {
        FeePeriod memory feePeriod = _recentFeePeriodsStorage(index);
        return (
            feePeriod.feePeriodId,
            feePeriod.startingDebtIndex,
            feePeriod.startTime,
            feePeriod.feesToDistribute,
            feePeriod.feesClaimed,
            feePeriod.rewardsToDistribute,
            feePeriod.rewardsClaimed
        );
    }

    function _recentFeePeriodsStorage(uint index) internal view returns(FeePeriod storage) {
        return _recentFeePeriods[(_currentFeePeriod + index) % FEE_PERIOD_LENGTH];
    }

     
    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex)
        external
        onlySynthetix
    {
        feePoolState.appendAccountIssuanceRecord(account, debtRatio, debtEntryIndex, _recentFeePeriodsStorage(0).startingDebtIndex);

        emitIssuanceDebtRatioEntry(account, debtRatio, debtEntryIndex, _recentFeePeriodsStorage(0).startingDebtIndex);
    }

     
    function setExchangeFeeRate(uint _exchangeFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_exchangeFeeRate < MAX_EXCHANGE_FEE_RATE, "rate < MAX_EXCHANGE_FEE_RATE");
        exchangeFeeRate = _exchangeFeeRate;
    }

     
    function setRewardsAuthority(address _rewardsAuthority)
        external
        optionalProxy_onlyOwner
    {
        rewardsAuthority = _rewardsAuthority;
    }

     
    function setFeePoolState(FeePoolState _feePoolState)
        external
        optionalProxy_onlyOwner
    {
        feePoolState = _feePoolState;
    }

     
    function setDelegateApprovals(DelegateApprovals _delegates)
        external
        optionalProxy_onlyOwner
    {
        delegates = _delegates;
    }

     
    function setFeePeriodDuration(uint _feePeriodDuration)
        external
        optionalProxy_onlyOwner
    {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "value < MIN_FEE_PERIOD_DURATION");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "value > MAX_FEE_PERIOD_DURATION");

        feePeriodDuration = _feePeriodDuration;

        emitFeePeriodDurationUpdated(_feePeriodDuration);
    }

     
    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        require(address(_synthetix) != address(0), "New Synthetix must be non-zero");

        synthetix = _synthetix;
    }

    function setTargetThreshold(uint _percent)
        external
        optionalProxy_onlyOwner
    {
        require(_percent >= 0, "Threshold should be positive");
        require(_percent <= 50, "Threshold too high");
        targetThreshold = _percent.mul(SafeDecimalMath.unit()).div(100);
    }

     
    function recordFeePaid(uint xdrAmount)
        external
        onlySynthetix
    {
         
        _recentFeePeriodsStorage(0).feesToDistribute = _recentFeePeriodsStorage(0).feesToDistribute.add(xdrAmount);
    }

     
    function setRewardsToDistribute(uint amount)
        external
    {
        require(messageSender == rewardsAuthority || msg.sender == rewardsAuthority, "Caller is not rewardsAuthority");
         
        _recentFeePeriodsStorage(0).rewardsToDistribute = _recentFeePeriodsStorage(0).rewardsToDistribute.add(amount);
    }

     
    function closeCurrentFeePeriod()
        external
    {
        require(_recentFeePeriodsStorage(0).startTime <= (now - feePeriodDuration), "Too early to close fee period");

        FeePeriod storage secondLastFeePeriod = _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2);
        FeePeriod storage lastFeePeriod = _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 1);

         
         
         
         
         
        _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2).feesToDistribute = lastFeePeriod.feesToDistribute
            .sub(lastFeePeriod.feesClaimed)
            .add(secondLastFeePeriod.feesToDistribute);
        _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2).rewardsToDistribute = lastFeePeriod.rewardsToDistribute
            .sub(lastFeePeriod.rewardsClaimed)
            .add(secondLastFeePeriod.rewardsToDistribute);

         
        _currentFeePeriod = _currentFeePeriod.add(FEE_PERIOD_LENGTH).sub(1).mod(FEE_PERIOD_LENGTH);

         
        delete _recentFeePeriods[_currentFeePeriod];

         
         
        _recentFeePeriodsStorage(0).feePeriodId = uint64(uint256(_recentFeePeriodsStorage(1).feePeriodId).add(1));
        _recentFeePeriodsStorage(0).startingDebtIndex = uint64(synthetixState.debtLedgerLength());
        _recentFeePeriodsStorage(0).startTime = uint64(now);

        emitFeePeriodClosed(_recentFeePeriodsStorage(1).feePeriodId);
    }

     
    function claimFees()
        external
        optionalProxy
        returns (bool)
    {
        bytes32 currencyKey = "sUSD";

        return _claimFees(messageSender, currencyKey);
    }

     
    function claimOnBehalf(address claimingForAddress)
        external
        optionalProxy
        returns (bool)
    {
        require(delegates.approval(claimingForAddress, messageSender), "Not approved to claim on behalf");

        bytes32 currencyKey = "sUSD";

        return _claimFees(claimingForAddress, currencyKey);
    }

    function _claimFees(address claimingAddress, bytes32 currencyKey)
        internal
        returns (bool)
    {
        uint rewardsPaid = 0;
        uint feesPaid = 0;
        uint availableFees;
        uint availableRewards;

         
         
        require(isFeesClaimable(claimingAddress), "C-Ratio below penalty threshold");

         
        (availableFees, availableRewards) = feesAvailable(claimingAddress, "XDR");

        require(availableFees > 0 || availableRewards > 0, "No fees or rewards available for period, or fees already claimed");

         
        _setLastFeeWithdrawal(claimingAddress, _recentFeePeriodsStorage(1).feePeriodId);

        if (availableFees > 0) {
             
            feesPaid = _recordFeePayment(availableFees);

             
            _payFees(claimingAddress, feesPaid, currencyKey);
        }

        if (availableRewards > 0) {
             
            rewardsPaid = _recordRewardPayment(availableRewards);

             
            _payRewards(claimingAddress, rewardsPaid);
        }

        emitFeesClaimed(claimingAddress, feesPaid, rewardsPaid);

        return true;
    }

     
    function importFeePeriod(
        uint feePeriodIndex, uint feePeriodId, uint startingDebtIndex, uint startTime,
        uint feesToDistribute, uint feesClaimed, uint rewardsToDistribute, uint rewardsClaimed)
        public
        optionalProxy_onlyOwner
        onlyDuringSetup
    {
        require (startingDebtIndex <= synthetixState.debtLedgerLength(), "Cannot import bad data");

        _recentFeePeriods[_currentFeePeriod.add(feePeriodIndex).mod(FEE_PERIOD_LENGTH)] = FeePeriod({
            feePeriodId: uint64(feePeriodId),
            startingDebtIndex: uint64(startingDebtIndex),
            startTime: uint64(startTime),
            feesToDistribute: feesToDistribute,
            feesClaimed: feesClaimed,
            rewardsToDistribute: rewardsToDistribute,
            rewardsClaimed: rewardsClaimed
        });
    }

     
    function appendVestingEntry(address account, uint quantity)
        public
        optionalProxy_onlyOwner
    {
         
        synthetix.transferFrom(messageSender, rewardEscrow, quantity);

         
        rewardEscrow.appendVestingEntry(account, quantity);
    }

     
    function approveClaimOnBehalf(address account)
        public
        optionalProxy
    {
        require(account != address(0), "Can't delegate to address(0)");
        delegates.setApproval(messageSender, account);
    }

     
    function removeClaimOnBehalf(address account)
        public
        optionalProxy
    {
        delegates.withdrawApproval(messageSender, account);
    }

     
    function _recordFeePayment(uint xdrAmount)
        internal
        returns (uint)
    {
         
        uint remainingToAllocate = xdrAmount;

        uint feesPaid;
         
         
         
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint feesAlreadyClaimed = _recentFeePeriodsStorage(i).feesClaimed;
            uint delta = _recentFeePeriodsStorage(i).feesToDistribute.sub(feesAlreadyClaimed);

            if (delta > 0) {
                 
                uint amountInPeriod = delta < remainingToAllocate ? delta : remainingToAllocate;

                _recentFeePeriodsStorage(i).feesClaimed = feesAlreadyClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                feesPaid = feesPaid.add(amountInPeriod);

                 
                if (remainingToAllocate == 0) return feesPaid;

                 
                 
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }

        return feesPaid;
    }

     
    function _recordRewardPayment(uint snxAmount)
        internal
        returns (uint)
    {
         
        uint remainingToAllocate = snxAmount;

        uint rewardPaid;

         
         
         
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint toDistribute = _recentFeePeriodsStorage(i).rewardsToDistribute.sub(_recentFeePeriodsStorage(i).rewardsClaimed);

            if (toDistribute > 0) {
                 
                uint amountInPeriod = toDistribute < remainingToAllocate ? toDistribute : remainingToAllocate;

                _recentFeePeriodsStorage(i).rewardsClaimed = _recentFeePeriodsStorage(i).rewardsClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                rewardPaid = rewardPaid.add(amountInPeriod);

                 
                if (remainingToAllocate == 0) return rewardPaid;

                 
                 
                 
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }
        return rewardPaid;
    }

     
    function _payFees(address account, uint xdrAmount, bytes32 destinationCurrencyKey)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send fees to fee pool");
        require(account != address(proxy), "Can't send fees to proxy");
        require(account != address(synthetix), "Can't send fees to synthetix");

        Synth xdrSynth = synthetix.synths("XDR");  
        Synth destinationSynth = synthetix.synths(destinationCurrencyKey);

         
         

         
        xdrSynth.burn(FEE_ADDRESS, xdrAmount);

         
        uint destinationAmount = synthetix.effectiveValue("XDR", xdrAmount, destinationCurrencyKey);

         

         
        destinationSynth.issue(account, destinationAmount);

         

         
        destinationSynth.triggerTokenFallbackIfNeeded(FEE_ADDRESS, account, destinationAmount);
    }

     
    function _payRewards(address account, uint snxAmount)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send rewards to fee pool");
        require(account != address(proxy), "Can't send rewards to proxy");
        require(account != address(synthetix), "Can't send rewards to synthetix");

         
         
        rewardEscrow.appendVestingEntry(account, snxAmount);
    }

     
    function amountReceivedFromTransfer(uint value)
        external
        pure
        returns (uint)
    {
        return value;
    }

     
    function exchangeFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(exchangeFeeRate);

         
         
         
         
         
         
         
    }

     
    function amountReceivedFromExchange(uint value)
        external
        view
        returns (uint)
    {
        return value.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

     
    function totalFeesAvailable(bytes32 currencyKey)
        external
        view
        returns (uint)
    {
        uint totalFees = 0;

         
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(_recentFeePeriodsStorage(i).feesToDistribute);
            totalFees = totalFees.sub(_recentFeePeriodsStorage(i).feesClaimed);
        }

        return synthetix.effectiveValue("XDR", totalFees, currencyKey);
    }

     
    function totalRewardsAvailable()
        external
        view
        returns (uint)
    {
        uint totalRewards = 0;

         
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalRewards = totalRewards.add(_recentFeePeriodsStorage(i).rewardsToDistribute);
            totalRewards = totalRewards.sub(_recentFeePeriodsStorage(i).rewardsClaimed);
        }

        return totalRewards;
    }

     
    function feesAvailable(address account, bytes32 currencyKey)
        public
        view
        returns (uint, uint)
    {
         
        uint[2][FEE_PERIOD_LENGTH] memory userFees = feesByPeriod(account);

        uint totalFees = 0;
        uint totalRewards = 0;

         
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i][0]);
            totalRewards = totalRewards.add(userFees[i][1]);
        }

         
         
        return (
            synthetix.effectiveValue("XDR", totalFees, currencyKey),
            totalRewards
        );
    }

     
    function isFeesClaimable(address account)
        public
        view
        returns (bool)
    {
         
         
         
        uint ratio = synthetix.collateralisationRatio(account);
        uint targetRatio = synthetixState.issuanceRatio();

         
        if (ratio < targetRatio) {
            return true;
        }

         
        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(targetThreshold));

         
        if (ratio > ratio_threshold) {
            return false;
        }

        return true;
    }

     
    function feesByPeriod(address account)
        public
        view
        returns (uint[2][FEE_PERIOD_LENGTH] memory results)
    {
         
        uint userOwnershipPercentage;
        uint debtEntryIndex;
        (userOwnershipPercentage, debtEntryIndex) = feePoolState.getAccountsDebtEntry(account, 0);

         
         
         
        if (debtEntryIndex == 0 && userOwnershipPercentage == 0) return;

         
         
        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage, debtEntryIndex);

        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;

         
        uint lastFeeWithdrawal = getLastFeeWithdrawal(account);

         
         
        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint next = i - 1;
            uint nextPeriodStartingDebtIndex = _recentFeePeriodsStorage(next).startingDebtIndex;

             
            if (nextPeriodStartingDebtIndex > 0 &&
            lastFeeWithdrawal < _recentFeePeriodsStorage(i).feePeriodId) {

                 
                 
                 
                uint closingDebtIndex = uint256(nextPeriodStartingDebtIndex).sub(1);

                 
                 
                 
                (userOwnershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);

                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage, debtEntryIndex);

                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }

     
    function _feesAndRewardsFromPeriod(uint period, uint ownershipPercentage, uint debtEntryIndex)
        view
        internal
        returns (uint, uint)
    {
         
        if (ownershipPercentage == 0) return (0, 0);

        uint debtOwnershipForPeriod = ownershipPercentage;

         
        if (period > 0) {
            uint closingDebtIndex = uint256(_recentFeePeriodsStorage(period - 1).startingDebtIndex).sub(1);
            debtOwnershipForPeriod = _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
        }

         
         
        uint feesFromPeriod = _recentFeePeriodsStorage(period).feesToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        uint rewardsFromPeriod = _recentFeePeriodsStorage(period).rewardsToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        return (
            feesFromPeriod.preciseDecimalToDecimal(),
            rewardsFromPeriod.preciseDecimalToDecimal()
        );
    }

    function _effectiveDebtRatioForPeriod(uint closingDebtIndex, uint ownershipPercentage, uint debtEntryIndex)
        internal
        view
        returns (uint)
    {
         
         
        uint feePeriodDebtOwnership = synthetixState.debtLedger(closingDebtIndex)
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(ownershipPercentage);

        return feePeriodDebtOwnership;
    }

    function effectiveDebtRatioForPeriod(address account, uint period)
        external
        view
        returns (uint)
    {
        require(period != 0, "Current period is not closed yet");
        require(period < FEE_PERIOD_LENGTH, "Exceeds the FEE_PERIOD_LENGTH");

         
        if (_recentFeePeriodsStorage(period - 1).startingDebtIndex == 0) return 0;

        uint closingDebtIndex = uint256(_recentFeePeriodsStorage(period - 1).startingDebtIndex).sub(1);

        uint ownershipPercentage;
        uint debtEntryIndex;
        (ownershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);

         
        return _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
    }

     
    function getLastFeeWithdrawal(address _claimingAddress)
        public
        view
        returns (uint)
    {
        return feePoolEternalStorage.getUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)));
    }

     
    function getPenaltyThresholdRatio()
        public
        view
        returns (uint)
    {
        uint targetRatio = synthetixState.issuanceRatio();

        return targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(targetThreshold));
    }

     
    function _setLastFeeWithdrawal(address _claimingAddress, uint _feePeriodID)
        internal
    {
        feePoolEternalStorage.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)), _feePeriodID);
    }

     

    modifier onlySynthetix
    {
        require(msg.sender == address(synthetix), "Only Synthetix Authorised");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }

     

    event IssuanceDebtRatioEntry(address indexed account, uint debtRatio, uint debtEntryIndex, uint feePeriodStartingDebtIndex);
    bytes32 constant ISSUANCEDEBTRATIOENTRY_SIG = keccak256("IssuanceDebtRatioEntry(address,uint256,uint256,uint256)");
    function emitIssuanceDebtRatioEntry(address account, uint debtRatio, uint debtEntryIndex, uint feePeriodStartingDebtIndex) internal {
        proxy._emit(abi.encode(debtRatio, debtEntryIndex, feePeriodStartingDebtIndex), 2, ISSUANCEDEBTRATIOENTRY_SIG, bytes32(account), 0, 0);
    }

    event ExchangeFeeUpdated(uint newFeeRate);
    bytes32 constant EXCHANGEFEEUPDATED_SIG = keccak256("ExchangeFeeUpdated(uint256)");
    function emitExchangeFeeUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, EXCHANGEFEEUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    bytes32 constant FEEPERIODDURATIONUPDATED_SIG = keccak256("FeePeriodDurationUpdated(uint256)");
    function emitFeePeriodDurationUpdated(uint newFeePeriodDuration) internal {
        proxy._emit(abi.encode(newFeePeriodDuration), 1, FEEPERIODDURATIONUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodClosed(uint feePeriodId);
    bytes32 constant FEEPERIODCLOSED_SIG = keccak256("FeePeriodClosed(uint256)");
    function emitFeePeriodClosed(uint feePeriodId) internal {
        proxy._emit(abi.encode(feePeriodId), 1, FEEPERIODCLOSED_SIG, 0, 0, 0);
    }

    event FeesClaimed(address account, uint xdrAmount, uint snxRewards);
    bytes32 constant FEESCLAIMED_SIG = keccak256("FeesClaimed(address,uint256,uint256)");
    function emitFeesClaimed(address account, uint xdrAmount, uint snxRewards) internal {
        proxy._emit(abi.encode(account, xdrAmount, snxRewards), 1, FEESCLAIMED_SIG, 0, 0, 0);
    }
}