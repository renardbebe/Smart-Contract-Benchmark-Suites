 

 

pragma solidity 0.4.24;

 
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


 


 
contract Pausable is Owned {
    
    uint public lastPauseTime;
    bool public paused;

     
    constructor(address _owner)
        Owned(_owner)
        public
    {
         
    }

     
    function setPaused(bool _paused)
        external
        onlyOwner
    {
         
        if (_paused == paused) {
            return;
        }

         
        paused = _paused;
        
         
        if (paused) {
            lastPauseTime = now;
        }

         
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


 


 
contract SafeDecimalMath {

     
    uint8 public constant decimals = 18;

     
    uint public constant UNIT = 10 ** uint(decimals);

     
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

     
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y, "Safe add failed");
        return x + y;
    }

     
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

     
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x, "Safe sub failed");
        return x - y;
    }

     
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

     
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y, "Safe mul failed");
        return p;
    }

     
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        return safeMul(x, y) / UNIT;

    }

     
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

     
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        require(y != 0, "Denominator cannot be zero");
        return x / y;
    }

     
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        return safeDiv(safeMul(x, UNIT), y);
    }

     
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
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

    function _emit(bytes callData, uint numTopics,
                   bytes32 topic1, bytes32 topic2,
                   bytes32 topic3, bytes32 topic4)
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
        require(Proxyable(msg.sender) == target, "This action can only be performed by the proxy target");
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

 


 
contract ExternStateToken is SafeDecimalMath, SelfDestructible, Proxyable, ReentrancyPreventer {

     

     
    TokenState public tokenState;

     
    string public name;
    string public symbol;
    uint public totalSupply;

     
    constructor(address _proxy, TokenState _tokenState,
                string _name, string _symbol, uint _totalSupply,
                address _owner)
        SelfDestructible(_owner)
        Proxyable(_proxy, _owner)
        public
    {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        tokenState = _tokenState;
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
        preventReentrancy
        returns (bool)
    { 
         
        require(to != address(0), "Cannot transfer to the 0 address");
        require(to != address(this), "Cannot transfer to the underlying contract");
        require(to != address(proxy), "Cannot transfer to the proxy contract");

         
        tokenState.setBalanceOf(from, safeSub(tokenState.balanceOf(from), value));
        tokenState.setBalanceOf(to, safeAdd(tokenState.balanceOf(to), value));

         

         
        uint length;

         
        assembly {
             
            length := extcodesize(to)
        }

         
        if (length > 0) {
             
             
             
             

             
            to.call(0xcbff5d96, messageSender, value);

             
        }

         
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
         
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), value));
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


 


 
contract FeeToken is ExternStateToken {

     

     

     
    uint public transferFeeRate;
     
    uint constant MAX_TRANSFER_FEE_RATE = UNIT / 10;
     
    address public feeAuthority;
     
    address public constant FEE_ADDRESS = 0xfeefeefeefeefeefeefeefeefeefeefeefeefeef;


     

     
    constructor(address _proxy, TokenState _tokenState, string _name, string _symbol, uint _totalSupply,
                uint _transferFeeRate, address _feeAuthority, address _owner)
        ExternStateToken(_proxy, _tokenState,
                         _name, _symbol, _totalSupply,
                         _owner)
        public
    {
        feeAuthority = _feeAuthority;

         
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Constructed transfer fee rate should respect the maximum fee rate");
        transferFeeRate = _transferFeeRate;
    }

     

     
    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Transfer fee rate must be below MAX_TRANSFER_FEE_RATE");
        transferFeeRate = _transferFeeRate;
        emitTransferFeeRateUpdated(_transferFeeRate);
    }

     
    function setFeeAuthority(address _feeAuthority)
        public
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
        emitFeeAuthorityUpdated(_feeAuthority);
    }

     

     
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return safeMul_dec(value, transferFeeRate);
         
    }

     
    function transferPlusFee(uint value)
        external
        view
        returns (uint)
    {
        return safeAdd(value, transferFeeIncurred(value));
    }

     
    function amountReceived(uint value)
        public
        view
        returns (uint)
    {
        return safeDiv_dec(value, safeAdd(UNIT, transferFeeRate));
    }

     
    function feePool()
        external
        view
        returns (uint)
    {
        return tokenState.balanceOf(FEE_ADDRESS);
    }

     

     
    function _internalTransfer(address from, address to, uint amount, uint fee)
        internal
        returns (bool)
    {
         
        require(to != address(0), "Cannot transfer to the 0 address");
        require(to != address(this), "Cannot transfer to the underlying contract");
        require(to != address(proxy), "Cannot transfer to the proxy contract");

         
        tokenState.setBalanceOf(from, safeSub(tokenState.balanceOf(from), safeAdd(amount, fee)));
        tokenState.setBalanceOf(to, safeAdd(tokenState.balanceOf(to), amount));
        tokenState.setBalanceOf(FEE_ADDRESS, safeAdd(tokenState.balanceOf(FEE_ADDRESS), fee));

         
        emitTransfer(from, to, amount);
        emitTransfer(from, FEE_ADDRESS, fee);

        return true;
    }

     
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        uint received = amountReceived(value);
        uint fee = safeSub(value, received);

        return _internalTransfer(sender, to, received, fee);
    }

     
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
         
        uint received = amountReceived(value);
        uint fee = safeSub(value, received);

         
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), value));

        return _internalTransfer(from, to, received, fee);
    }

     
    function _transferSenderPaysFee_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
         
        uint fee = transferFeeIncurred(value);
        return _internalTransfer(sender, to, value, fee);
    }

     
    function _transferFromSenderPaysFee_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
         
        uint fee = transferFeeIncurred(value);
        uint total = safeAdd(value, fee);

         
        tokenState.setAllowance(from, sender, safeSub(tokenState.allowance(from, sender), total));

        return _internalTransfer(from, to, value, fee);
    }

     
    function withdrawFees(address account, uint value)
        external
        onlyFeeAuthority
        returns (bool)
    {
        require(account != address(0), "Must supply an account address to withdraw fees");

         
        if (value == 0) {
            return false;
        }

         
        tokenState.setBalanceOf(FEE_ADDRESS, safeSub(tokenState.balanceOf(FEE_ADDRESS), value));
        tokenState.setBalanceOf(account, safeAdd(tokenState.balanceOf(account), value));

        emitFeesWithdrawn(account, value);
        emitTransfer(FEE_ADDRESS, account, value);

        return true;
    }

     
    function donateToFeePool(uint n)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
         
        uint balance = tokenState.balanceOf(sender);
        require(balance != 0, "Must have a balance in order to donate to the fee pool");

         
        tokenState.setBalanceOf(sender, safeSub(balance, n));
        tokenState.setBalanceOf(FEE_ADDRESS, safeAdd(tokenState.balanceOf(FEE_ADDRESS), n));

        emitFeesDonated(sender, n);
        emitTransfer(sender, FEE_ADDRESS, n);

        return true;
    }


     

    modifier onlyFeeAuthority
    {
        require(msg.sender == feeAuthority, "Only the fee authority can do this action");
        _;
    }


     

    event TransferFeeRateUpdated(uint newFeeRate);
    bytes32 constant TRANSFERFEERATEUPDATED_SIG = keccak256("TransferFeeRateUpdated(uint256)");
    function emitTransferFeeRateUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, TRANSFERFEERATEUPDATED_SIG, 0, 0, 0);
    }

    event FeeAuthorityUpdated(address newFeeAuthority);
    bytes32 constant FEEAUTHORITYUPDATED_SIG = keccak256("FeeAuthorityUpdated(address)");
    function emitFeeAuthorityUpdated(address newFeeAuthority) internal {
        proxy._emit(abi.encode(newFeeAuthority), 1, FEEAUTHORITYUPDATED_SIG, 0, 0, 0);
    } 

    event FeesWithdrawn(address indexed account, uint value);
    bytes32 constant FEESWITHDRAWN_SIG = keccak256("FeesWithdrawn(address,uint256)");
    function emitFeesWithdrawn(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESWITHDRAWN_SIG, bytes32(account), 0, 0);
    }

    event FeesDonated(address indexed donor, uint value);
    bytes32 constant FEESDONATED_SIG = keccak256("FeesDonated(address,uint256)");
    function emitFeesDonated(address donor, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESDONATED_SIG, bytes32(donor), 0, 0);
    }
}


 


contract Nomin is FeeToken {

     

    Havven public havven;

     
    mapping(address => bool) public frozen;

     
    uint constant TRANSFER_FEE_RATE = 15 * UNIT / 10000;
    string constant TOKEN_NAME = "Nomin USD";
    string constant TOKEN_SYMBOL = "nUSD";

     

    constructor(address _proxy, TokenState _tokenState, Havven _havven,
                uint _totalSupply,
                address _owner)
        FeeToken(_proxy, _tokenState,
                 TOKEN_NAME, TOKEN_SYMBOL, _totalSupply,
                 TRANSFER_FEE_RATE,
                 _havven,  
                 _owner)
        public
    {
        require(_proxy != 0, "_proxy cannot be 0");
        require(address(_havven) != 0, "_havven cannot be 0");
        require(_owner != 0, "_owner cannot be 0");

         
        frozen[FEE_ADDRESS] = true;
        havven = _havven;
    }

     

    function setHavven(Havven _havven)
        external
        optionalProxy_onlyOwner
    {
         
         
        havven = _havven;
        setFeeAuthority(_havven);
        emitHavvenUpdated(_havven);
    }


     

     
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to], "Cannot transfer to frozen address");
        return _transfer_byProxy(messageSender, to, value);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to], "Cannot transfer to frozen address");
        return _transferFrom_byProxy(messageSender, from, to, value);
    }

    function transferSenderPaysFee(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to], "Cannot transfer to frozen address");
        return _transferSenderPaysFee_byProxy(messageSender, to, value);
    }

    function transferFromSenderPaysFee(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to], "Cannot transfer to frozen address");
        return _transferFromSenderPaysFee_byProxy(messageSender, from, to, value);
    }

     
    function unfreezeAccount(address target)
        external
        optionalProxy_onlyOwner
    {
        require(frozen[target] && target != FEE_ADDRESS, "Account must be frozen, and cannot be the fee address");
        frozen[target] = false;
        emitAccountUnfrozen(target);
    }

     
    function issue(address account, uint amount)
        external
        onlyHavven
    {
        tokenState.setBalanceOf(account, safeAdd(tokenState.balanceOf(account), amount));
        totalSupply = safeAdd(totalSupply, amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

     
    function burn(address account, uint amount)
        external
        onlyHavven
    {
        tokenState.setBalanceOf(account, safeSub(tokenState.balanceOf(account), amount));
        totalSupply = safeSub(totalSupply, amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }

     

    modifier onlyHavven() {
        require(Havven(msg.sender) == havven, "Only the Havven contract can perform this action");
        _;
    }

     

    event HavvenUpdated(address newHavven);
    bytes32 constant HAVVENUPDATED_SIG = keccak256("HavvenUpdated(address)");
    function emitHavvenUpdated(address newHavven) internal {
        proxy._emit(abi.encode(newHavven), 1, HAVVENUPDATED_SIG, 0, 0, 0);
    }

    event AccountFrozen(address indexed target, uint balance);
    bytes32 constant ACCOUNTFROZEN_SIG = keccak256("AccountFrozen(address,uint256)");
    function emitAccountFrozen(address target, uint balance) internal {
        proxy._emit(abi.encode(balance), 2, ACCOUNTFROZEN_SIG, bytes32(target), 0, 0);
    }

    event AccountUnfrozen(address indexed target);
    bytes32 constant ACCOUNTUNFROZEN_SIG = keccak256("AccountUnfrozen(address)");
    function emitAccountUnfrozen(address target) internal {
        proxy._emit(abi.encode(), 2, ACCOUNTUNFROZEN_SIG, bytes32(target), 0, 0);
    }

    event Issued(address indexed account, uint amount);
    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint amount) internal {
        proxy._emit(abi.encode(amount), 2, ISSUED_SIG, bytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint amount);
    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint amount) internal {
        proxy._emit(abi.encode(amount), 2, BURNED_SIG, bytes32(account), 0, 0);
    }
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


 


 
contract HavvenEscrow is SafeDecimalMath, Owned, LimitedSetup(8 weeks) {
     
    Havven public havven;

     
    mapping(address => uint[2][]) public vestingSchedules;

     
    mapping(address => uint) public totalVestedAccountBalance;

     
    uint public totalVestedBalance;

    uint constant TIME_INDEX = 0;
    uint constant QUANTITY_INDEX = 1;

     
    uint constant MAX_VESTING_ENTRIES = 20;


     

    constructor(address _owner, Havven _havven)
        Owned(_owner)
        public
    {
        havven = _havven;
    }


     

    function setHavven(Havven _havven)
        external
        onlyOwner
    {
        havven = _havven;
        emit HavvenUpdated(_havven);
    }


     

     
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return totalVestedAccountBalance[account];
    }

     
    function numVestingEntries(address account)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account].length;
    }

     
    function getVestingScheduleEntry(address account, uint index)
        public
        view
        returns (uint[2])
    {
        return vestingSchedules[account][index];
    }

     
    function getVestingTime(address account, uint index)
        public
        view
        returns (uint)
    {
        return getVestingScheduleEntry(account,index)[TIME_INDEX];
    }

     
    function getVestingQuantity(address account, uint index)
        public
        view
        returns (uint)
    {
        return getVestingScheduleEntry(account,index)[QUANTITY_INDEX];
    }

     
    function getNextVestingIndex(address account)
        public
        view
        returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

     
    function getNextVestingEntry(address account)
        public
        view
        returns (uint[2])
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

     
    function getNextVestingTime(address account)
        external
        view
        returns (uint)
    {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

     
    function getNextVestingQuantity(address account)
        external
        view
        returns (uint)
    {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }


     

     
    function withdrawHavvens(uint quantity)
        external
        onlyOwner
        onlyDuringSetup
    {
        havven.transfer(havven, quantity);
    }

     
    function purgeAccount(address account)
        external
        onlyOwner
        onlyDuringSetup
    {
        delete vestingSchedules[account];
        totalVestedBalance = safeSub(totalVestedBalance, totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }

     
    function appendVestingEntry(address account, uint time, uint quantity)
        public
        onlyOwner
        onlyDuringSetup
    {
         
        require(now < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

         
        totalVestedBalance = safeAdd(totalVestedBalance, quantity);
        require(totalVestedBalance <= havven.balanceOf(this), "Must be enough balance in the contract to provide for the vesting entry");

         
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
             
            require(getVestingTime(account, numVestingEntries(account) - 1) < time, "Cannot add new vested entries earlier than the last one");
            totalVestedAccountBalance[account] = safeAdd(totalVestedAccountBalance[account], quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

     
    function addVestingSchedule(address account, uint[] times, uint[] quantities)
        external
        onlyOwner
        onlyDuringSetup
    {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }

    }

     
    function vest()
        external
    {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
             
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[msg.sender][i] = [0, 0];
            total = safeAdd(total, qty);
        }

        if (total != 0) {
            totalVestedBalance = safeSub(totalVestedBalance, total);
            totalVestedAccountBalance[msg.sender] = safeSub(totalVestedAccountBalance[msg.sender], total);
            havven.transfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
        }
    }


     

    event HavvenUpdated(address newHavven);

    event Vested(address indexed beneficiary, uint time, uint value);
}


 


 
contract Havven is ExternStateToken {

     

     
    struct IssuanceData {
         
        uint currentBalanceSum;
         
        uint lastAverageBalance;
         
        uint lastModified;
    }

     
    mapping(address => IssuanceData) public issuanceData;
     
    IssuanceData public totalIssuanceData;

     
    uint public feePeriodStartTime;
     
    uint public lastFeePeriodStartTime;

     
    uint public feePeriodDuration = 4 weeks;
     
    uint constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint constant MAX_FEE_PERIOD_DURATION = 26 weeks;

     
     
    uint public lastFeesCollected;

     
    mapping(address => bool) public hasWithdrawnFees;

    Nomin public nomin;
    HavvenEscrow public escrow;

     
    address public oracle;
     
    uint public price;
     
    uint public lastPriceUpdateTime;
     
    uint public priceStalePeriod = 3 hours;

     
    uint public issuanceRatio = UNIT / 5;
     
    uint constant MAX_ISSUANCE_RATIO = UNIT;

     
    mapping(address => bool) public isIssuer;
     
    mapping(address => uint) public nominsIssued;

    uint constant HAVVEN_SUPPLY = 1e8 * UNIT;
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;
    string constant TOKEN_NAME = "Havven";
    string constant TOKEN_SYMBOL = "HAV";
    
     

     
    constructor(address _proxy, TokenState _tokenState, address _owner, address _oracle,
                uint _price, address[] _issuers, Havven _oldHavven)
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, HAVVEN_SUPPLY, _owner)
        public
    {
        oracle = _oracle;
        price = _price;
        lastPriceUpdateTime = now;

        uint i;
        if (_oldHavven == address(0)) {
            feePeriodStartTime = now;
            lastFeePeriodStartTime = now - feePeriodDuration;
            for (i = 0; i < _issuers.length; i++) {
                isIssuer[_issuers[i]] = true;
            }
        } else {
            feePeriodStartTime = _oldHavven.feePeriodStartTime();
            lastFeePeriodStartTime = _oldHavven.lastFeePeriodStartTime();

            uint cbs;
            uint lab;
            uint lm;
            (cbs, lab, lm) = _oldHavven.totalIssuanceData();
            totalIssuanceData.currentBalanceSum = cbs;
            totalIssuanceData.lastAverageBalance = lab;
            totalIssuanceData.lastModified = lm;

            for (i = 0; i < _issuers.length; i++) {
                address issuer = _issuers[i];
                isIssuer[issuer] = true;
                uint nomins = _oldHavven.nominsIssued(issuer);
                if (nomins == 0) {
                     
                     
                    continue;
                }
                (cbs, lab, lm) = _oldHavven.issuanceData(issuer);
                nominsIssued[issuer] = nomins;
                issuanceData[issuer].currentBalanceSum = cbs;
                issuanceData[issuer].lastAverageBalance = lab;
                issuanceData[issuer].lastModified = lm;
            }
        }

    }

     

     
    function setNomin(Nomin _nomin)
        external
        optionalProxy_onlyOwner
    {
        nomin = _nomin;
        emitNominUpdated(_nomin);
    }

     
    function setEscrow(HavvenEscrow _escrow)
        external
        optionalProxy_onlyOwner
    {
        escrow = _escrow;
        emitEscrowUpdated(_escrow);
    }

     
    function setFeePeriodDuration(uint duration)
        external
        optionalProxy_onlyOwner
    {
        require(MIN_FEE_PERIOD_DURATION <= duration && duration <= MAX_FEE_PERIOD_DURATION,
            "Duration must be between MIN_FEE_PERIOD_DURATION and MAX_FEE_PERIOD_DURATION");
        feePeriodDuration = duration;
        emitFeePeriodDurationUpdated(duration);
        rolloverFeePeriodIfElapsed();
    }

     
    function setOracle(address _oracle)
        external
        optionalProxy_onlyOwner
    {
        oracle = _oracle;
        emitOracleUpdated(_oracle);
    }

     
    function setPriceStalePeriod(uint time)
        external
        optionalProxy_onlyOwner
    {
        priceStalePeriod = time;
    }

     
    function setIssuanceRatio(uint _issuanceRatio)
        external
        optionalProxy_onlyOwner
    {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO, "New issuance ratio must be less than or equal to MAX_ISSUANCE_RATIO");
        issuanceRatio = _issuanceRatio;
        emitIssuanceRatioUpdated(_issuanceRatio);
    }

     
    function setIssuer(address account, bool value)
        external
        optionalProxy_onlyOwner
    {
        isIssuer[account] = value;
        emitIssuersUpdated(account, value);
    }

     

    function issuanceCurrentBalanceSum(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].currentBalanceSum;
    }

    function issuanceLastAverageBalance(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].lastAverageBalance;
    }

    function issuanceLastModified(address account)
        external
        view
        returns (uint)
    {
        return issuanceData[account].lastModified;
    }

    function totalIssuanceCurrentBalanceSum()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.currentBalanceSum;
    }

    function totalIssuanceLastAverageBalance()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.lastAverageBalance;
    }

    function totalIssuanceLastModified()
        external
        view
        returns (uint)
    {
        return totalIssuanceData.lastModified;
    }

     

     
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        require(nominsIssued[sender] == 0 || value <= transferableHavvens(sender), "Value to transfer exceeds available havvens");
         
        _transfer_byProxy(sender, to, value);

        return true;
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        require(nominsIssued[from] == 0 || value <= transferableHavvens(from), "Value to transfer exceeds available havvens");
         
        _transferFrom_byProxy(sender, from, to, value);

        return true;
    }

     
    function withdrawFees()
        external
        optionalProxy
    {
        address sender = messageSender;
        rolloverFeePeriodIfElapsed();
         
        require(!nomin.frozen(sender), "Cannot deposit fees into frozen accounts");

         
        updateIssuanceData(sender, nominsIssued[sender], nomin.totalSupply());

         
        require(!hasWithdrawnFees[sender], "Fees have already been withdrawn in this period");

        uint feesOwed;
        uint lastTotalIssued = totalIssuanceData.lastAverageBalance;

        if (lastTotalIssued > 0) {
             
            feesOwed = safeDiv_dec(
                safeMul_dec(issuanceData[sender].lastAverageBalance, lastFeesCollected),
                lastTotalIssued
            );
        }

        hasWithdrawnFees[sender] = true;

        if (feesOwed != 0) {
            nomin.withdrawFees(sender, feesOwed);
        }
        emitFeesWithdrawn(messageSender, feesOwed);
    }

     
    function updateIssuanceData(address account, uint preBalance, uint lastTotalSupply)
        internal
    {
         
        totalIssuanceData = computeIssuanceData(lastTotalSupply, totalIssuanceData);

        if (issuanceData[account].lastModified < feePeriodStartTime) {
            hasWithdrawnFees[account] = false;
        }

        issuanceData[account] = computeIssuanceData(preBalance, issuanceData[account]);
    }


     
    function computeIssuanceData(uint preBalance, IssuanceData preIssuance)
        internal
        view
        returns (IssuanceData)
    {

        uint currentBalanceSum = preIssuance.currentBalanceSum;
        uint lastAverageBalance = preIssuance.lastAverageBalance;
        uint lastModified = preIssuance.lastModified;

        if (lastModified < feePeriodStartTime) {
            if (lastModified < lastFeePeriodStartTime) {
                 
                lastAverageBalance = preBalance;
            } else {
                 
                 
                uint timeUpToRollover = feePeriodStartTime - lastModified;
                uint lastFeePeriodDuration = feePeriodStartTime - lastFeePeriodStartTime;
                uint lastBalanceSum = safeAdd(currentBalanceSum, safeMul(preBalance, timeUpToRollover));
                lastAverageBalance = lastBalanceSum / lastFeePeriodDuration;
            }
             
            currentBalanceSum = safeMul(preBalance, now - feePeriodStartTime);
        } else {
             
            currentBalanceSum = safeAdd(
                currentBalanceSum,
                safeMul(preBalance, now - lastModified)
            );
        }

        return IssuanceData(currentBalanceSum, lastAverageBalance, now);
    }

     
    function recomputeLastAverageBalance(address account)
        external
        returns (uint)
    {
        updateIssuanceData(account, nominsIssued[account], nomin.totalSupply());
        return issuanceData[account].lastAverageBalance;
    }

     
    function issueNomins(uint amount)
        public
        optionalProxy
        requireIssuer(messageSender)
         
    {
        address sender = messageSender;
        require(amount <= remainingIssuableNomins(sender), "Amount must be less than or equal to remaining issuable nomins");
        uint lastTot = nomin.totalSupply();
        uint preIssued = nominsIssued[sender];
        nomin.issue(sender, amount);
        nominsIssued[sender] = safeAdd(preIssued, amount);
        updateIssuanceData(sender, preIssued, lastTot);
    }

    function issueMaxNomins()
        external
        optionalProxy
    {
        issueNomins(remainingIssuableNomins(messageSender));
    }

     
    function burnNomins(uint amount)
         
        external
        optionalProxy
    {
        address sender = messageSender;

        uint lastTot = nomin.totalSupply();
        uint preIssued = nominsIssued[sender];
         
        nomin.burn(sender, amount);
         
        nominsIssued[sender] = safeSub(preIssued, amount);
        updateIssuanceData(sender, preIssued, lastTot);
    }

     
    function rolloverFeePeriodIfElapsed()
        public
    {
         
        if (now >= feePeriodStartTime + feePeriodDuration) {
            lastFeesCollected = nomin.feePool();
            lastFeePeriodStartTime = feePeriodStartTime;
            feePeriodStartTime = now;
            emitFeePeriodRollover(now);
        }
    }

     

     
    function maxIssuableNomins(address issuer)
        view
        public
        priceNotStale
        returns (uint)
    {
        if (!isIssuer[issuer]) {
            return 0;
        }
        if (escrow != HavvenEscrow(0)) {
            uint totalOwnedHavvens = safeAdd(tokenState.balanceOf(issuer), escrow.balanceOf(issuer));
            return safeMul_dec(HAVtoUSD(totalOwnedHavvens), issuanceRatio);
        } else {
            return safeMul_dec(HAVtoUSD(tokenState.balanceOf(issuer)), issuanceRatio);
        }
    }

     
    function remainingIssuableNomins(address issuer)
        view
        public
        returns (uint)
    {
        uint issued = nominsIssued[issuer];
        uint max = maxIssuableNomins(issuer);
        if (issued > max) {
            return 0;
        } else {
            return safeSub(max, issued);
        }
    }

     
    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint bal = tokenState.balanceOf(account);
        if (escrow != address(0)) {
            bal = safeAdd(bal, escrow.balanceOf(account));
        }
        return bal;
    }

     
    function issuanceDraft(address account)
        public
        view
        returns (uint)
    {
        uint issued = nominsIssued[account];
        if (issued == 0) {
            return 0;
        }
        return USDtoHAV(safeDiv_dec(issued, issuanceRatio));
    }

     
    function lockedCollateral(address account)
        public
        view
        returns (uint)
    {
        uint debt = issuanceDraft(account);
        uint collat = collateral(account);
        if (debt > collat) {
            return collat;
        }
        return debt;
    }

     
    function unlockedCollateral(address account)
        public
        view
        returns (uint)
    {
        uint locked = lockedCollateral(account);
        uint collat = collateral(account);
        return safeSub(collat, locked);
    }

     
    function transferableHavvens(address account)
        public
        view
        returns (uint)
    {
        uint draft = issuanceDraft(account);
        uint collat = collateral(account);
         
        if (draft > collat) {
            return 0;
        }

        uint bal = balanceOf(account);
         
         
        if (draft > safeSub(collat, bal)) {
            return safeSub(collat, draft);
        }
         
        return bal;
    }

     
    function HAVtoUSD(uint hav_dec)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeMul_dec(hav_dec, price);
    }

     
    function USDtoHAV(uint usd_dec)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeDiv_dec(usd_dec, price);
    }

     
    function updatePrice(uint newPrice, uint timeSent)
        external
        onlyOracle   
    {
         
        require(lastPriceUpdateTime < timeSent && timeSent < now + ORACLE_FUTURE_LIMIT,
            "Time sent must be bigger than the last update, and must be less than now + ORACLE_FUTURE_LIMIT");

        price = newPrice;
        lastPriceUpdateTime = timeSent;
        emitPriceUpdated(newPrice, timeSent);

         
        rolloverFeePeriodIfElapsed();
    }

     
    function priceIsStale()
        public
        view
        returns (bool)
    {
        return safeAdd(lastPriceUpdateTime, priceStalePeriod) < now;
    }

     

    modifier requireIssuer(address account)
    {
        require(isIssuer[account], "Must be issuer to perform this action");
        _;
    }

    modifier onlyOracle
    {
        require(msg.sender == oracle, "Must be oracle to perform this action");
        _;
    }

    modifier priceNotStale
    {
        require(!priceIsStale(), "Price must not be stale to perform this action");
        _;
    }

     

    event PriceUpdated(uint newPrice, uint timestamp);
    bytes32 constant PRICEUPDATED_SIG = keccak256("PriceUpdated(uint256,uint256)");
    function emitPriceUpdated(uint newPrice, uint timestamp) internal {
        proxy._emit(abi.encode(newPrice, timestamp), 1, PRICEUPDATED_SIG, 0, 0, 0);
    }

    event IssuanceRatioUpdated(uint newRatio);
    bytes32 constant ISSUANCERATIOUPDATED_SIG = keccak256("IssuanceRatioUpdated(uint256)");
    function emitIssuanceRatioUpdated(uint newRatio) internal {
        proxy._emit(abi.encode(newRatio), 1, ISSUANCERATIOUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodRollover(uint timestamp);
    bytes32 constant FEEPERIODROLLOVER_SIG = keccak256("FeePeriodRollover(uint256)");
    function emitFeePeriodRollover(uint timestamp) internal {
        proxy._emit(abi.encode(timestamp), 1, FEEPERIODROLLOVER_SIG, 0, 0, 0);
    } 

    event FeePeriodDurationUpdated(uint duration);
    bytes32 constant FEEPERIODDURATIONUPDATED_SIG = keccak256("FeePeriodDurationUpdated(uint256)");
    function emitFeePeriodDurationUpdated(uint duration) internal {
        proxy._emit(abi.encode(duration), 1, FEEPERIODDURATIONUPDATED_SIG, 0, 0, 0);
    } 

    event FeesWithdrawn(address indexed account, uint value);
    bytes32 constant FEESWITHDRAWN_SIG = keccak256("FeesWithdrawn(address,uint256)");
    function emitFeesWithdrawn(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, FEESWITHDRAWN_SIG, bytes32(account), 0, 0);
    }

    event OracleUpdated(address newOracle);
    bytes32 constant ORACLEUPDATED_SIG = keccak256("OracleUpdated(address)");
    function emitOracleUpdated(address newOracle) internal {
        proxy._emit(abi.encode(newOracle), 1, ORACLEUPDATED_SIG, 0, 0, 0);
    }

    event NominUpdated(address newNomin);
    bytes32 constant NOMINUPDATED_SIG = keccak256("NominUpdated(address)");
    function emitNominUpdated(address newNomin) internal {
        proxy._emit(abi.encode(newNomin), 1, NOMINUPDATED_SIG, 0, 0, 0);
    }

    event EscrowUpdated(address newEscrow);
    bytes32 constant ESCROWUPDATED_SIG = keccak256("EscrowUpdated(address)");
    function emitEscrowUpdated(address newEscrow) internal {
        proxy._emit(abi.encode(newEscrow), 1, ESCROWUPDATED_SIG, 0, 0, 0);
    }

    event IssuersUpdated(address indexed account, bool indexed value);
    bytes32 constant ISSUERSUPDATED_SIG = keccak256("IssuersUpdated(address,bool)");
    function emitIssuersUpdated(address account, bool value) internal {
        proxy._emit(abi.encode(), 3, ISSUERSUPDATED_SIG, bytes32(account), bytes32(value ? 1 : 0), 0);
    }

}


 


 
contract IssuanceController is SafeDecimalMath, SelfDestructible, Pausable {

     
    Havven public havven;
    Nomin public nomin;

     
    address public fundsWallet;

     
    address public oracle;
     
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

     
    uint public priceStalePeriod = 3 hours;

     
    uint public lastPriceUpdateTime;
     
    uint public usdToHavPrice;
     
    uint public usdToEthPrice;
    
     

     
    constructor(
         
        address _owner,

         
        address _fundsWallet,

         
        Havven _havven,
        Nomin _nomin,

         
        address _oracle,
        uint _usdToEthPrice,
        uint _usdToHavPrice
    )
         
        SelfDestructible(_owner)
        Pausable(_owner)
        public
    {
        fundsWallet = _fundsWallet;
        havven = _havven;
        nomin = _nomin;
        oracle = _oracle;
        usdToEthPrice = _usdToEthPrice;
        usdToHavPrice = _usdToHavPrice;
        lastPriceUpdateTime = now;
    }

     

     
    function setFundsWallet(address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
        emit FundsWalletUpdated(fundsWallet);
    }
    
     
    function setOracle(address _oracle)
        external
        onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

     
    function setNomin(Nomin _nomin)
        external
        onlyOwner
    {
        nomin = _nomin;
        emit NominUpdated(_nomin);
    }

     
    function setHavven(Havven _havven)
        external
        onlyOwner
    {
        havven = _havven;
        emit HavvenUpdated(_havven);
    }

     
    function setPriceStalePeriod(uint _time)
        external
        onlyOwner 
    {
        priceStalePeriod = _time;
        emit PriceStalePeriodUpdated(priceStalePeriod);
    }

     
     
    function updatePrices(uint newEthPrice, uint newHavvenPrice, uint timeSent)
        external
        onlyOracle
    {
         
        require(lastPriceUpdateTime < timeSent && timeSent < now + ORACLE_FUTURE_LIMIT, 
            "Time sent must be bigger than the last update, and must be less than now + ORACLE_FUTURE_LIMIT");

        usdToEthPrice = newEthPrice;
        usdToHavPrice = newHavvenPrice;
        lastPriceUpdateTime = timeSent;

        emit PricesUpdated(usdToEthPrice, usdToHavPrice, lastPriceUpdateTime);
    }

     
    function ()
        external
        payable
    {
        exchangeEtherForNomins();
    } 

     
    function exchangeEtherForNomins()
        public 
        payable
        pricesNotStale
        notPaused
        returns (uint)  
    {
         
         
        uint requestedToPurchase = safeMul_dec(msg.value, usdToEthPrice);

         
        fundsWallet.transfer(msg.value);

         
         
         
         
        nomin.transfer(msg.sender, requestedToPurchase);

        emit Exchange("ETH", msg.value, "nUSD", requestedToPurchase);

        return requestedToPurchase;
    }

     
    function exchangeEtherForNominsAtRate(uint guaranteedRate)
        public
        payable
        pricesNotStale
        notPaused
        returns (uint)  
    {
        require(guaranteedRate == usdToEthPrice);

        return exchangeEtherForNomins();
    }


     
    function exchangeEtherForHavvens()
        public 
        payable
        pricesNotStale
        notPaused
        returns (uint)  
    {
         
        uint havvensToSend = havvensReceivedForEther(msg.value);

         
        fundsWallet.transfer(msg.value);

         
        havven.transfer(msg.sender, havvensToSend);

        emit Exchange("ETH", msg.value, "HAV", havvensToSend);

        return havvensToSend;
    }

     
    function exchangeEtherForHavvensAtRate(uint guaranteedEtherRate, uint guaranteedHavvenRate)
        public
        payable
        pricesNotStale
        notPaused
        returns (uint)  
    {
        require(guaranteedEtherRate == usdToEthPrice);
        require(guaranteedHavvenRate == usdToHavPrice);

        return exchangeEtherForHavvens();
    }


     
    function exchangeNominsForHavvens(uint nominAmount)
        public 
        pricesNotStale
        notPaused
        returns (uint)  
    {
         
        uint havvensToSend = havvensReceivedForNomins(nominAmount);
        
         
        nomin.transferFrom(msg.sender, this, nominAmount);

         
        havven.transfer(msg.sender, havvensToSend);

        emit Exchange("nUSD", nominAmount, "HAV", havvensToSend);

        return havvensToSend; 
    }

     
    function exchangeNominsForHavvensAtRate(uint nominAmount, uint guaranteedRate)
        public 
        pricesNotStale
        notPaused
        returns (uint)  
    {
        require(guaranteedRate == usdToHavPrice);

        return exchangeNominsForHavvens(nominAmount);
    }
    
     
    function withdrawHavvens(uint amount)
        external
        onlyOwner
    {
        havven.transfer(owner, amount);
        
         
         
         
         
    }

     
    function withdrawNomins(uint amount)
        external
        onlyOwner
    {
        nomin.transfer(owner, amount);
        
         
         
         
         
    }

     
     
    function pricesAreStale()
        public
        view
        returns (bool)
    {
        return safeAdd(lastPriceUpdateTime, priceStalePeriod) < now;
    }

     
    function havvensReceivedForNomins(uint amount)
        public 
        view
        returns (uint)
    {
         
        uint nominsReceived = nomin.amountReceived(amount);

         
        return safeDiv_dec(nominsReceived, usdToHavPrice);
    }

     
    function havvensReceivedForEther(uint amount)
        public 
        view
        returns (uint)
    {
         
        uint valueSentInNomins = safeMul_dec(amount, usdToEthPrice); 

         
        return havvensReceivedForNomins(valueSentInNomins);
    }

     
    function nominsReceivedForEther(uint amount)
        public 
        view
        returns (uint)
    {
         
        uint nominsTransferred = safeMul_dec(amount, usdToEthPrice);

         
        return nomin.amountReceived(nominsTransferred);
    }
    
     

    modifier onlyOracle
    {
        require(msg.sender == oracle, "Must be oracle to perform this action");
        _;
    }

    modifier pricesNotStale
    {
        require(!pricesAreStale(), "Prices must not be stale to perform this action");
        _;
    }

     

    event FundsWalletUpdated(address newFundsWallet);
    event OracleUpdated(address newOracle);
    event NominUpdated(Nomin newNominContract);
    event HavvenUpdated(Havven newHavvenContract);
    event PriceStalePeriodUpdated(uint priceStalePeriod);
    event PricesUpdated(uint newEthPrice, uint newHavvenPrice, uint timeSent);
    event Exchange(string fromCurrency, uint fromAmount, string toCurrency, uint toAmount);
}