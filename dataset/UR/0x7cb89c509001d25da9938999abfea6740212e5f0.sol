 

 
    
 


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


 


 
contract ExternStateToken is SelfDestructible, Proxyable {

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

    function _internalTransfer(address from, address to, uint value)
        internal
        returns (bool)
    {
         
        require(to != address(0) && to != address(this) && to != address(proxy), "Cannot transfer to this address");

         
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

         
        emitTransfer(from, to, value);
        
        return true;
    }

     
    function _transfer_byProxy(address from, address to, uint value)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value);
    }

     
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
         
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value);
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


library Math {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    function powDecimal(uint x, uint n)
        internal
        pure
        returns (uint)
    {
         

        uint result = SafeDecimalMath.unit();
        while (n > 0) {
            if (n % 2 != 0) {
                result = result.multiplyDecimal(x);
            }
            x = x.multiplyDecimal(x);
            n /= 2;
        }
        return result;
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


interface ISynth {
    function burn(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


 
interface ISynthetixEscrow {
    function balanceOf(address account) public view returns (uint);
    function appendVestingEntry(address account, uint quantity) public;
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


 
interface IExchangeRates {
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) external view returns (uint);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);
    function ratesForCurrencies(bytes32[] currencyKeys) external view returns (uint[] memory);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);
    function anyRateIsStale(bytes32[] currencyKeys) external view returns (bool);
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
        return super._internalTransfer(messageSender, to, value);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {        
         
        if (tokenState.allowance(from, messageSender) != uint(-1)) {
             
             
            tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));
        }
        
        return super._internalTransfer(from, to, value);
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


 


contract ISynthetix {

     

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ISynthetixState public synthetixState;
    IExchangeRates public exchangeRates;

    uint public totalSupply;
        
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


 


 
contract SupplySchedule is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using Math for uint;

     
    uint public lastMintEvent;

     
    uint public weekCounter;

     
    uint public minterReward = 200 * SafeDecimalMath.unit();

     
     
    uint public constant INITIAL_WEEKLY_SUPPLY = 1442307692307692307692307;    

     
    address public synthetixProxy;

     
    uint public constant MAX_MINTER_REWARD = 200 * SafeDecimalMath.unit();

     
    uint public constant MINT_PERIOD_DURATION = 1 weeks;

    uint public constant INFLATION_START_DATE = 1551830400;  
    uint public constant MINT_BUFFER = 1 days;
    uint8 public constant SUPPLY_DECAY_START = 40;  
    uint8 public constant SUPPLY_DECAY_END = 234;  
    
     
    uint public constant DECAY_RATE = 12500000000000000;  

     
    uint public constant TERMINAL_SUPPLY_RATE_ANNUAL = 25000000000000000;  
    
    constructor(
        address _owner,
        uint _lastMintEvent,
        uint _currentWeek)
        Owned(_owner)
        public
    {
        lastMintEvent = _lastMintEvent;
        weekCounter = _currentWeek;
    }

     
    
     
    function mintableSupply()
        external
        view
        returns (uint)
    {
        uint totalAmount;

        if (!isMintable()) {
            return totalAmount;
        }
        
        uint remainingWeeksToMint = weeksSinceLastIssuance();
          
        uint currentWeek = weekCounter;
        
         
         
        while (remainingWeeksToMint > 0) {
            currentWeek++;            
            
             
            if (currentWeek < SUPPLY_DECAY_START) {
                totalAmount = totalAmount.add(INITIAL_WEEKLY_SUPPLY);
                remainingWeeksToMint--;
            }
             
            else if (currentWeek <= SUPPLY_DECAY_END) {
                
                 
                uint decayCount = currentWeek.sub(SUPPLY_DECAY_START -1);
                
                totalAmount = totalAmount.add(tokenDecaySupplyForWeek(decayCount));
                remainingWeeksToMint--;
            } 
             
             
            else {
                uint totalSupply = ISynthetix(synthetixProxy).totalSupply();
                uint currentTotalSupply = totalSupply.add(totalAmount);

                totalAmount = totalAmount.add(terminalInflationSupply(currentTotalSupply, remainingWeeksToMint));
                remainingWeeksToMint = 0;
            }
        }
        
        return totalAmount;
    }

     
    function tokenDecaySupplyForWeek(uint counter)
        public 
        pure
        returns (uint)
    {   
         
         
        uint effectiveDecay = (SafeDecimalMath.unit().sub(DECAY_RATE)).powDecimal(counter);
        uint supplyForWeek = INITIAL_WEEKLY_SUPPLY.multiplyDecimal(effectiveDecay);

        return supplyForWeek;
    }    
    
     
    function terminalInflationSupply(uint totalSupply, uint numOfWeeks)
        public
        pure
        returns (uint)
    {   
         
        uint effectiveCompoundRate = SafeDecimalMath.unit().add(TERMINAL_SUPPLY_RATE_ANNUAL.div(52)).powDecimal(numOfWeeks);

         
        return totalSupply.multiplyDecimal(effectiveCompoundRate.sub(SafeDecimalMath.unit()));
    }

     
    function weeksSinceLastIssuance()
        public
        view
        returns (uint)
    {
         
         
        uint timeDiff = lastMintEvent > 0 ? now.sub(lastMintEvent) : now.sub(INFLATION_START_DATE);
        return timeDiff.div(MINT_PERIOD_DURATION);
    }

     
    function isMintable()
        public
        view
        returns (bool)
    {
        if (now - lastMintEvent > MINT_PERIOD_DURATION)
        {
            return true;
        }
        return false;
    }

     

     
    function recordMintEvent(uint supplyMinted)
        external
        onlySynthetix
        returns (bool)
    {
        uint numberOfWeeksIssued = weeksSinceLastIssuance();

         
        weekCounter = weekCounter.add(numberOfWeeksIssued);

         
         
        lastMintEvent = INFLATION_START_DATE.add(weekCounter.mul(MINT_PERIOD_DURATION)).add(MINT_BUFFER);

        emit SupplyMinted(supplyMinted, numberOfWeeksIssued, lastMintEvent, now);
        return true;
    }

     
    function setMinterReward(uint amount)
        external
        onlyOwner
    {
        require(amount <= MAX_MINTER_REWARD, "Reward cannot exceed max minter reward");
        minterReward = amount;
        emit MinterRewardUpdated(minterReward);
    }

     

     
    function setSynthetixProxy(ISynthetix _synthetixProxy)
        external
        onlyOwner
    {
        require(_synthetixProxy != address(0), "Address cannot be 0");
        synthetixProxy = _synthetixProxy;
        emit SynthetixProxyUpdated(synthetixProxy);
    }

     

     
    modifier onlySynthetix() {
        require(msg.sender == address(Proxy(synthetixProxy).target()), "Only the synthetix contract can perform this action");
        _;
    }

     
     
    event SupplyMinted(uint supplyMinted, uint numberOfWeeksIssued, uint lastMintEvent, uint timestamp);

     
    event MinterRewardUpdated(uint newRewardAmount);

     
    event SynthetixProxyUpdated(address newAddress);
}


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
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

     
    mapping(bytes32 => AggregatorInterface) public aggregators;

     
    bytes32[] public aggregatorKeys;

     
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

    function getRateAndUpdatedTime(bytes32 code) internal view returns (RateAndUpdatedTime) {
        if (code == "XDR") {
             
             
            uint total = 0;
            uint lastUpdated = 0;
            for (uint i = 0; i < xdrParticipants.length; i++) {
                RateAndUpdatedTime memory xdrEntry = getRateAndUpdatedTime(xdrParticipants[i]);
                total = total.add(xdrEntry.rate);
                if (xdrEntry.time > lastUpdated) {
                    lastUpdated = xdrEntry.time;
                }
            }
            return RateAndUpdatedTime({
                rate: uint216(total),
                time: uint40(lastUpdated)
            });
        } else if (aggregators[code] != address(0)) {
            return RateAndUpdatedTime({
                rate: uint216(aggregators[code].latestAnswer() * 1e10),
                time: uint40(aggregators[code].latestTimestamp())
            });
        } else {
            return _rates[code];
        }
    }
     
    function rates(bytes32 code) public view returns(uint256) {
        return getRateAndUpdatedTime(code).rate;
    }

     
    function lastRateUpdateTimes(bytes32 code) public view returns(uint256) {
        return getRateAndUpdatedTime(code).time;
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

         
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];

             
             
             
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            require(currencyKey != "sUSD", "Rate of sUSD cannot be updated, it's always UNIT.");

             
            if (timeSent < lastRateUpdateTimes(currencyKey)) {
                continue;
            }

            newRates[i] = rateOrInverted(currencyKey, newRates[i]);

             
            _setRate(currencyKey, newRates[i], timeSent);
        }

        emit RatesUpdated(currencyKeys, newRates);

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

         
        bool wasRemoved = removeFromArray(currencyKey, invertedKeys);

        if (wasRemoved) {
            emit InversePriceConfigured(currencyKey, 0, 0, 0);
        }
    }

     
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external onlyOwner {
        AggregatorInterface aggregator = AggregatorInterface(aggregatorAddress);
        require(aggregator.latestTimestamp() >= 0, "Given Aggregator is invalid");
        if (aggregators[currencyKey] == address(0)) {
            aggregatorKeys.push(currencyKey);
        }
        aggregators[currencyKey] = aggregator;
        emit AggregatorAdded(currencyKey, aggregator);
    }

     
    function removeFromArray(bytes32 entry, bytes32[] storage array) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == entry) {
                delete array[i];

                 
                 
                 
                array[i] = array[array.length - 1];

                 
                array.length--;

                return true;
            }
        }
        return false;
    }
     
    function removeAggregator(bytes32 currencyKey) external onlyOwner {
        address aggregator = aggregators[currencyKey];
        require(aggregator != address(0), "No aggregator exists for key");
        delete aggregators[currencyKey];

        bool wasRemoved = removeFromArray(currencyKey, aggregatorKeys);

        if (wasRemoved) {
            emit AggregatorRemoved(currencyKey, aggregator);
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
            RateAndUpdatedTime memory rateAndUpdateTime = getRateAndUpdatedTime(currencyKeys[i]);
            _localRates[i] = uint256(rateAndUpdateTime.rate);
            if (!anyRateStale) {
                anyRateStale = (currencyKeys[i] != "sUSD" && uint256(rateAndUpdateTime.time).add(period) < now);
            }
        }

        return (_localRates, anyRateStale);
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
    event AggregatorAdded(bytes32 currencyKey, address aggregator);
    event AggregatorRemoved(bytes32 currencyKey, address aggregator);
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
        require(currencyKey != "XDR" && currencyKey != "sUSD", "Cannot remove synth");        

         
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
        optionalProxy
        returns (bool)
    {
         
        require(value <= transferableSynthetix(messageSender), "Cannot transfer staked or escrowed SNX");

         
        _transfer_byProxy(messageSender, to, value);

        return true;
    }

      
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
         
        require(value <= transferableSynthetix(from), "Cannot transfer staked or escrowed SNX");

         
         
        return _transferFrom_byProxy(messageSender, from, to, value);         
    }

     
    function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        external
        optionalProxy
         
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
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

         
        supplySchedule.recordMintEvent(supplyToMint);

         
         
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