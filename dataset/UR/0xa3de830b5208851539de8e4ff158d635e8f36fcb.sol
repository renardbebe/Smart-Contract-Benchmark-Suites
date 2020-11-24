 

 


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
        require(_owner != address(0), "Owner must not be the zero address");
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
    }

     
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be the zero address");
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
        require(selfDestructInitiated, "Self destruct has not yet been initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < now, "Self destruct delay has not yet elapsed");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
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

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call this function");
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "This action can only be performed by the owner");
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
        require(to != address(this), "Cannot transfer to the underlying contract");
        require(to != address(proxy), "Cannot transfer to the proxy contract");

         
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


 


 

contract ExchangeRates is SelfDestructible {


    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    mapping(bytes4 => uint) public rates;

     
    mapping(bytes4 => uint) public lastRateUpdateTimes;

     
    address public oracle;

     
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

     
    uint public rateStalePeriod = 3 hours;

     
     
     
    bytes4[5] public xdrParticipants;

     
    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozen;
    }
    mapping(bytes4 => InversePricing) public inversePricing;
    bytes4[] public invertedKeys;

     
     

     
    constructor(
         
        address _owner,

         
        address _oracle,
        bytes4[] _currencyKeys,
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
            bytes4("sUSD"),
            bytes4("sAUD"),
            bytes4("sCHF"),
            bytes4("sEUR"),
            bytes4("sGBP")
        ];

        internalUpdateRates(_currencyKeys, _newRates, now);
    }

     

     
    function updateRates(bytes4[] currencyKeys, uint[] newRates, uint timeSent)
        external
        onlyOracle
        returns(bool)
    {
        return internalUpdateRates(currencyKeys, newRates, timeSent);
    }

     
    function internalUpdateRates(bytes4[] currencyKeys, uint[] newRates, uint timeSent)
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

        return true;
    }

     
    function rateOrInverted(bytes4 currencyKey, uint rate) internal returns (uint) {
         
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

         
         
        bytes4[] memory eventCurrencyCode = new bytes4[](1);
        eventCurrencyCode[0] = "XDR";

        uint[] memory eventRate = new uint[](1);
        eventRate[0] = rates["XDR"];

        emit RatesUpdated(eventCurrencyCode, eventRate);
    }

     
    function deleteRate(bytes4 currencyKey)
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

     
    function setInversePricing(bytes4 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit)
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

     
    function removeInversePricing(bytes4 currencyKey) external onlyOwner {
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
     

     
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey)
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

     
    function rateForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return rates[currencyKey];
    }

     
    function ratesForCurrencies(bytes4[] currencyKeys)
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

     
    function lastRateUpdateTimeForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return lastRateUpdateTimes[currencyKey];
    }

     
    function lastRateUpdateTimesForCurrencies(bytes4[] currencyKeys)
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

     
    function rateIsStale(bytes4 currencyKey)
        public
        view
        returns (bool)
    {
         
        if (currencyKey == "sUSD") return false;

        return lastRateUpdateTimes[currencyKey].add(rateStalePeriod) < now;
    }

     
    function rateIsFrozen(bytes4 currencyKey)
        external
        view
        returns (bool)
    {
        return inversePricing[currencyKey].frozen;
    }


     
    function anyRateIsStale(bytes4[] currencyKeys)
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

     

    modifier rateNotStale(bytes4 currencyKey) {
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
    event RatesUpdated(bytes4[] currencyKeys, uint[] newRates);
    event RateDeleted(bytes4 currencyKey);
    event InversePriceConfigured(bytes4 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit);
    event InversePriceFrozen(bytes4 currencyKey);
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


 


 
contract SynthetixState is ISynthetixState, State, LimitedSetup {


    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
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
    function amountReceivedFromExchange(uint value) external view returns (uint);
    function amountReceivedFromTransfer(uint value) external view returns (uint);
    function feePaid(bytes4 currencyKey, uint amount) external;
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex) external;
    function rewardsMinted(uint amount) external;
    function transferFeeIncurred(uint value) public view returns (uint);
}


 


contract Synth is ExternStateToken {

     

    IFeePool public feePool;
    Synthetix public synthetix;

     
    bytes4 public currencyKey;

    uint8 constant DECIMALS = 18;

     

    constructor(address _proxy, TokenState _tokenState, Synthetix _synthetix, IFeePool _feePool,
        string _tokenName, string _tokenSymbol, address _owner, bytes4 _currencyKey
    )
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, 0, DECIMALS, _owner)
        public
    {
        require(_proxy != 0, "_proxy cannot be 0");
        require(address(_synthetix) != 0, "_synthetix cannot be 0");
        require(address(_feePool) != 0, "_feePool cannot be 0");
        require(_owner != 0, "_owner cannot be 0");
        require(_synthetix.synths(_currencyKey) == Synth(0), "Currency key is already in use");

        feePool = _feePool;
        synthetix = _synthetix;
        currencyKey = _currencyKey;
    }

     

    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        synthetix = _synthetix;
        emitSynthetixUpdated(_synthetix);
    }

    function setFeePool(IFeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
        emitFeePoolUpdated(_feePool);
    }

     

     
    function transfer(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

         
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

         
        bytes memory empty;
        return _internalTransfer(messageSender, to, amountReceived, empty);
    }

     
    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

         
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

         
        return _internalTransfer(messageSender, to, amountReceived, data);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
         
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

         
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, amountReceived, empty);
    }

     
    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
         
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value.sub(amountReceived);

         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));

         
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, amountReceived, data);
    }

     
    function transferSenderPaysFee(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

         
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

         
        bytes memory empty;
        return _internalTransfer(messageSender, to, value, empty);
    }

     
    function transferSenderPaysFee(address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

         
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

         
        return _internalTransfer(messageSender, to, value, data);
    }

     
    function transferFromSenderPaysFee(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value.add(fee)));

         
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, value, empty);
    }

     
    function transferFromSenderPaysFee(address from, address to, uint value, bytes data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

         
         
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value.add(fee)));

         
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, value, data);
    }

     
    function _internalTransfer(address from, address to, uint value, bytes data)
        internal
        returns (bool)
    {
        bytes4 preferredCurrencyKey = synthetix.synthetixState().preferredCurrency(to);

         
        if (preferredCurrencyKey != 0 && preferredCurrencyKey != currencyKey) {
            return synthetix.synthInitiatedExchange(from, currencyKey, value, preferredCurrencyKey, to);
        } else {
             
            return super._internalTransfer(from, to, value, data);
        }
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
        bool isSynthetix = msg.sender == address(synthetix);
        bool isFeePool = msg.sender == address(feePool);

        require(isSynthetix || isFeePool, "Only the Synthetix or FeePool contracts can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Cannot perform this action with the fee address");
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


 
interface ISynthetixEscrow {
    function balanceOf(address account) public view returns (uint);
    function appendVestingEntry(address account, uint quantity) public;
}


 


 
contract Synthetix is ExternStateToken {

     

     
    Synth[] public availableSynths;
    mapping(bytes4 => Synth) public synths;

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ExchangeRates public exchangeRates;
    SynthetixState public synthetixState;
    SupplySchedule public supplySchedule;

    uint constant SYNTHETIX_SUPPLY = 1e8 * SafeDecimalMath.unit();
    string constant TOKEN_NAME = "Synthetix Network Token";
    string constant TOKEN_SYMBOL = "SNX";
    uint8 constant DECIMALS = 18;
     

     
    constructor(address _proxy, TokenState _tokenState, SynthetixState _synthetixState,
        address _owner, ExchangeRates _exchangeRates, IFeePool _feePool, SupplySchedule _supplySchedule,
        ISynthetixEscrow _rewardEscrow, ISynthetixEscrow _escrow
    )
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, SYNTHETIX_SUPPLY, DECIMALS, _owner)
        public
    {
        synthetixState = _synthetixState;
        exchangeRates = _exchangeRates;
        feePool = _feePool;
        supplySchedule = _supplySchedule;
        rewardEscrow = _rewardEscrow;
        escrow = _escrow;
    }
     

     
    function addSynth(Synth synth)
        external
        optionalProxy_onlyOwner
    {
        bytes4 currencyKey = synth.currencyKey();

        require(synths[currencyKey] == Synth(0), "Synth already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;

         
    }

     
    function removeSynth(bytes4 currencyKey)
        external
        optionalProxy_onlyOwner
    {
        require(synths[currencyKey] != address(0), "Synth does not exist");
        require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
        require(currencyKey != "XDR", "Cannot remove XDR synth");

         
        address synthToRemove = synths[currencyKey];

         
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == synthToRemove) {
                delete availableSynths[i];

                 
                 
                 
                availableSynths[i] = availableSynths[availableSynths.length - 1];

                 
                availableSynths.length--;

                break;
            }
        }

         
        delete synths[currencyKey];

         
         
         
    }

     

     
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey)
        public
        view
        rateNotStale(sourceCurrencyKey)
        rateNotStale(destinationCurrencyKey)
        returns (uint)
    {
         
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

         
        return sourceAmount.multiplyDecimalRound(exchangeRates.rateForCurrency(sourceCurrencyKey))
            .divideDecimalRound(exchangeRates.rateForCurrency(destinationCurrencyKey));
    }

     
    function totalIssuedSynths(bytes4 currencyKey)
        public
        view
        rateNotStale(currencyKey)
        returns (uint)
    {
        uint total = 0;
        uint currencyRate = exchangeRates.rateForCurrency(currencyKey);

        require(!exchangeRates.anyRateIsStale(availableCurrencyKeys()), "Rates are stale");

        for (uint8 i = 0; i < availableSynths.length; i++) {
             
             
             
             
            uint synthValue = availableSynths[i].totalSupply()
                .multiplyDecimalRound(exchangeRates.rateForCurrency(availableSynths[i].currencyKey()))
                .divideDecimalRound(currencyRate);
            total = total.add(synthValue);
        }

        return total;
    }

     
    function availableCurrencyKeys()
        internal
        view
        returns (bytes4[])
    {
        bytes4[] memory availableCurrencyKeys = new bytes4[](availableSynths.length);

        for (uint8 i = 0; i < availableSynths.length; i++) {
            availableCurrencyKeys[i] = availableSynths[i].currencyKey();
        }

        return availableCurrencyKeys;
    }

     
    function availableSynthCount()
        public
        view
        returns (uint)
    {
        return availableSynths.length;
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

     
    function exchange(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey, address destinationAddress)
        external
        optionalProxy
         
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Exchange must use different synths");
        require(sourceAmount > 0, "Zero amount");

         
        return _internalExchange(
            messageSender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress == address(0) ? messageSender : destinationAddress,
            true  
        );
    }

     
    function synthInitiatedExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress
    )
        external
        onlySynth
        returns (bool)
    {
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

     
    function synthInitiatedFeePayment(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount
    )
        external
        onlySynth
        returns (bool)
    {
         
        if (sourceAmount == 0) {
            return true;
        }

        require(sourceAmount > 0, "Source can't be 0");

         
        bool result = _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            "XDR",
            feePool.FEE_ADDRESS(),
            false  
        );

         
        feePool.feePaid(sourceCurrencyKey, sourceAmount);

        return result;
    }

     
    function _internalExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress,
        bool chargeFee
    )
        internal
        notFeeAddress(from)
        returns (bool)
    {
        require(destinationAddress != address(0), "Zero destination");
        require(destinationAddress != address(this), "Synthetix is invalid destination");
        require(destinationAddress != address(proxy), "Proxy is invalid destination");

         
         

         
        synths[sourceCurrencyKey].burn(from, sourceAmount);

         
        uint destinationAmount = effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

         
        uint amountReceived = destinationAmount;
        uint fee = 0;

        if (chargeFee) {
            amountReceived = feePool.amountReceivedFromExchange(destinationAmount);
            fee = destinationAmount.sub(amountReceived);
        }

         
        synths[destinationCurrencyKey].issue(destinationAddress, amountReceived);

         
        if (fee > 0) {
            uint xdrFeeAmount = effectiveValue(destinationCurrencyKey, fee, "XDR");
            synths["XDR"].issue(feePool.FEE_ADDRESS(), xdrFeeAmount);
             
            feePool.feePaid("XDR", xdrFeeAmount);
        }

         

         
        synths[destinationCurrencyKey].triggerTokenFallbackIfNeeded(from, destinationAddress, amountReceived);

         
        emitSynthExchange(from, sourceCurrencyKey, sourceAmount, destinationCurrencyKey, amountReceived, destinationAddress);

        return true;
    }

     
    function _addToDebtRegister(bytes4 currencyKey, uint amount)
        internal
        optionalProxy
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

         
        if (!synthetixState.hasIssued(messageSender)) {
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

     
    function issueSynths(bytes4 currencyKey, uint amount)
        public
        optionalProxy
         
    {
        require(amount <= remainingIssuableSynths(messageSender, currencyKey), "Amount too large");

         
        _addToDebtRegister(currencyKey, amount);

         
        synths[currencyKey].issue(messageSender, amount);

         
        _appendAccountIssuanceRecord();
    }

     
    function issueMaxSynths(bytes4 currencyKey)
        external
        optionalProxy
    {
         
        uint maxIssuable = remainingIssuableSynths(messageSender, currencyKey);

         
        issueSynths(currencyKey, maxIssuable);
    }

     
    function burnSynths(bytes4 currencyKey, uint amount)
        external
        optionalProxy
         
    {
         
        uint debtToRemove = effectiveValue(currencyKey, amount, "XDR");
        uint debt = debtBalanceOf(messageSender, "XDR");
        uint debtInCurrencyKey = debtBalanceOf(messageSender, currencyKey);

        require(debt > 0, "No debt to forgive");

         
         
        uint amountToRemove = debt < debtToRemove ? debt : debtToRemove;

         
        _removeFromDebtRegister(amountToRemove);

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

     
    function _removeFromDebtRegister(uint amount)
        internal
    {
        uint debtToRemove = amount;

         
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

         
        uint totalDebtIssued = totalIssuedSynths("XDR");

         
        uint newTotalDebtIssued = totalDebtIssued.sub(debtToRemove);

        uint delta;

         
         
        if (newTotalDebtIssued > 0) {

             
            uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(newTotalDebtIssued);

             
             
             
            delta = SafeDecimalMath.preciseUnit().add(debtPercentage);
        } else {
            delta = 0;
        }

         
        if (debtToRemove == existingDebt) {
            synthetixState.clearIssuanceData(messageSender);
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

     

     
    function maxIssuableSynths(address issuer, bytes4 currencyKey)
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

     
    function debtBalanceOf(address issuer, bytes4 currencyKey)
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

     
    function remainingIssuableSynths(address issuer, bytes4 currencyKey)
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
        require(rewardEscrow != address(0), "Reward Escrow destination missing");

        uint supplyToMint = supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        supplySchedule.updateMintValues();

         
         
        uint minterReward = supplySchedule.minterReward();

        tokenState.setBalanceOf(rewardEscrow, tokenState.balanceOf(rewardEscrow).add(supplyToMint.sub(minterReward)));
        emitTransfer(this, rewardEscrow, supplyToMint.sub(minterReward));

         
        feePool.rewardsMinted(supplyToMint.sub(minterReward));

         
        tokenState.setBalanceOf(msg.sender, tokenState.balanceOf(msg.sender).add(minterReward));
        emitTransfer(this, msg.sender, minterReward);

        totalSupply = totalSupply.add(supplyToMint);
    }

     

    modifier rateNotStale(bytes4 currencyKey) {
        require(!exchangeRates.rateIsStale(currencyKey), "Rate stale or nonexistant currency");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Fee address not allowed");
        _;
    }

    modifier onlySynth() {
        bool isSynth = false;

         
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == msg.sender) {
                isSynth = true;
                break;
            }
        }

        require(isSynth, "Only synth allowed");
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0, "Amount needs to be larger than 0");
        _;
    }

     
     
    event SynthExchange(address indexed account, bytes4 fromCurrencyKey, uint256 fromAmount, bytes4 toCurrencyKey,  uint256 toAmount, address toAddress);
    bytes32 constant SYNTHEXCHANGE_SIG = keccak256("SynthExchange(address,bytes4,uint256,bytes4,uint256,address)");
    function emitSynthExchange(address account, bytes4 fromCurrencyKey, uint256 fromAmount, bytes4 toCurrencyKey, uint256 toAmount, address toAddress) internal {
        proxy._emit(abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress), 2, SYNTHEXCHANGE_SIG, bytes32(account), 0, 0);
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