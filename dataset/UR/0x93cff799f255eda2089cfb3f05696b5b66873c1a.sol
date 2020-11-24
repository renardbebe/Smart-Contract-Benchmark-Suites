 

 


pragma solidity ^0.4.24;

 
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


 


 

contract ExchangeRates is SelfDestructible {


    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    mapping(bytes32 => uint) public rates;

     
    mapping(bytes32 => uint) public lastRateUpdateTimes;

     
    address public oracle;

     
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

     
    uint public rateStalePeriod = 3 hours;

     
    bool public priceUpdateLock = false;

     
     
     
    bytes32[5] public xdrParticipants;

     
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

         
        rates["sUSD"] = SafeDecimalMath.unit();
        lastRateUpdateTimes["sUSD"] = now;

         
         
         
         
         
         
         
        xdrParticipants = [
            bytes32("sUSD"),
            bytes32("sAUD"),
            bytes32("sCHF"),
            bytes32("sEUR"),
            bytes32("sGBP")
        ];

        internalUpdateRates(_currencyKeys, _newRates, now);
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

         
        for (uint i = 0; i < currencyKeys.length; i++) {
             
             
             
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            require(currencyKeys[i] != "sUSD", "Rate of sUSD cannot be updated, it's always UNIT.");

             
            if (timeSent < lastRateUpdateTimes[currencyKeys[i]]) {
                continue;
            }

            newRates[i] = rateOrInverted(currencyKeys[i], newRates[i]);

             
            rates[currencyKeys[i]] = newRates[i];
            lastRateUpdateTimes[currencyKeys[i]] = timeSent;
        }

        emit RatesUpdated(currencyKeys, newRates);

         
        updateXDRRate(timeSent);

         
        if (priceUpdateLock) {
            priceUpdateLock = false;
        }

        return true;
    }

     
    function rateOrInverted(bytes32 currencyKey, uint rate) internal returns (uint) {
         
        InversePricing storage inverse = inversePricing[currencyKey];
        if (inverse.entryPoint <= 0) {
            return rate;
        }

         
        uint newInverseRate = rates[currencyKey];

         
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
            total = rates[xdrParticipants[i]].add(total);
        }

         
        rates["XDR"] = total;

         
        lastRateUpdateTimes["XDR"] = timeSent;

         
         
        bytes32[] memory eventCurrencyCode = new bytes32[](1);
        eventCurrencyCode[0] = "XDR";

        uint[] memory eventRate = new uint[](1);
        eventRate[0] = rates["XDR"];

        emit RatesUpdated(eventCurrencyCode, eventRate);
    }

     
    function deleteRate(bytes32 currencyKey)
        external
        onlyOracle
    {
        require(rates[currencyKey] > 0, "Rate is zero");

        delete rates[currencyKey];
        delete lastRateUpdateTimes[currencyKey];

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

     
    function setPriceUpdateLock(bool _priceUpdateLock)
        external
        onlyOracle
    {
        priceUpdateLock = _priceUpdateLock;
    }

     
    function setInversePricing(bytes32 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit)
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
        inversePricing[currencyKey].frozen = false;

        emit InversePriceConfigured(currencyKey, entryPoint, upperLimit, lowerLimit);
    }

     
    function removeInversePricing(bytes32 currencyKey) external onlyOwner {
        inversePricing[currencyKey].entryPoint = 0;
        inversePricing[currencyKey].upperLimit = 0;
        inversePricing[currencyKey].lowerLimit = 0;
        inversePricing[currencyKey].frozen = false;

         
        for (uint8 i = 0; i < invertedKeys.length; i++) {
            if (invertedKeys[i] == currencyKey) {
                delete invertedKeys[i];

                 
                 
                 
                invertedKeys[i] = invertedKeys[invertedKeys.length - 1];

                 
                invertedKeys.length--;

                break;
            }
        }

        emit InversePriceConfigured(currencyKey, 0, 0, 0);
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
        return rates[currencyKey];
    }

     
    function ratesForCurrencies(bytes32[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory _rates = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            _rates[i] = rates[currencyKeys[i]];
        }

        return _rates;
    }

     
    function lastRateUpdateTimeForCurrency(bytes32 currencyKey)
        public
        view
        returns (uint)
    {
        return lastRateUpdateTimes[currencyKey];
    }

     
    function lastRateUpdateTimesForCurrencies(bytes32[] currencyKeys)
        public
        view
        returns (uint[])
    {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = lastRateUpdateTimes[currencyKeys[i]];
        }

        return lastUpdateTimes;
    }

     
    function rateIsStale(bytes32 currencyKey)
        public
        view
        returns (bool)
    {
         
        if (currencyKey == "sUSD") return false;

        return lastRateUpdateTimes[currencyKey].add(rateStalePeriod) < now;
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
             
            if (currencyKeys[i] != "sUSD" && lastRateUpdateTimes[currencyKeys[i]].add(rateStalePeriod) < now) {
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

     
    address messageSender;

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
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}


 


contract ReentrancyPreventer {
     
    bool isInFunctionBody = false;

    modifier preventReentrancy {
        require(!isInFunctionBody, "Reverted to prevent reentrancy");
        isInFunctionBody = true;
        _;
        isInFunctionBody = false;
    }
}

 


contract TokenFallbackCaller is ReentrancyPreventer {
    function callTokenFallbackIfNeeded(address sender, address recipient, uint amount, bytes data)
        internal
        preventReentrancy
    {
         

         
        uint length;

         
        assembly {
             
            length := extcodesize(recipient)
        }

         
        if (length > 0) {
             
             

             
            recipient.call(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", sender, amount, data));

             
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

         
         
         
        callTokenFallbackIfNeeded(from, to, value, data);
        
         
        emitTransfer(from, to, value);

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


 
contract IFeePool {
    address public FEE_ADDRESS;
    uint public exchangeFeeRate;
    function amountReceivedFromExchange(uint value) external view returns (uint);
    function amountReceivedFromTransfer(uint value) external view returns (uint);
    function feePaid(bytes32 currencyKey, uint amount) external;
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
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) public view returns (uint);

    function rateForCurrency(bytes32 currencyKey) public view returns (uint);

    function anyRateIsStale(bytes32[] currencyKeys) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);
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
        bytes32 destinationCurrencyKey,
        address destinationAddress) external returns (bool);
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
        _notFeeAddress(messageSender);
        bytes memory empty;
        return super._internalTransfer(messageSender, to, value, empty);
    }

     
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
        _notFeeAddress(messageSender);
         
        return super._internalTransfer(messageSender, to, value, data);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        _notFeeAddress(from);
         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

        bytes memory empty;
        return super._internalTransfer(from, to, value, empty);
    }

     
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {
        _notFeeAddress(from);
         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

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


    function _notFeeAddress(address account)
        internal
        view
    {
        require(account != IFeePool(feePoolProxy).FEE_ADDRESS(), "The fee address is not allowed");
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


 


contract PurgeableSynth is Synth {

    using SafeDecimalMath for uint;

     
    uint public maxSupplyToPurgeInUSD = 100000 * SafeDecimalMath.unit();  

     
    ExchangeRates public exchangeRates;

     

    constructor(address _proxy, TokenState _tokenState, address _synthetixProxy, IFeePool _feePool,
        string _tokenName, string _tokenSymbol, address _owner, bytes32 _currencyKey, ExchangeRates _exchangeRates, uint _totalSupply
    )
        Synth(_proxy, _tokenState, _synthetixProxy, _feePool, _tokenName, _tokenSymbol, _owner, _currencyKey, _totalSupply)
        public
    {
        exchangeRates = _exchangeRates;
    }

     

     
    function purge(address[] addresses)
        external
        optionalProxy_onlyOwner
    {
        uint maxSupplyToPurge = exchangeRates.effectiveValue("sUSD", maxSupplyToPurgeInUSD, currencyKey);

         
        require(
            totalSupply <= maxSupplyToPurge || exchangeRates.rateIsFrozen(currencyKey),
            "Cannot purge as total supply is above threshold and rate is not frozen."
        );

        for (uint8 i = 0; i < addresses.length; i++) {
            address holder = addresses[i];

            uint amountHeld = balanceOf(holder);

            if (amountHeld > 0) {
                ISynthetix(synthetixProxy).synthInitiatedExchange(holder, currencyKey, amountHeld, "sUSD", holder);
                emitPurged(holder, amountHeld);
            }

        }

    }

     

    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
    }

     

    event Purged(address indexed account, uint value);
    bytes32 constant PURGED_SIG = keccak256("Purged(address,uint256)");
    function emitPurged(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, PURGED_SIG, bytes32(account), 0, 0);
    }
}