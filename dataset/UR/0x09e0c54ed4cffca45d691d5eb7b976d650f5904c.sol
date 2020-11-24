 

pragma solidity 0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


 
contract SchedulerInterface {
    function schedule(address _toAddress, bytes _callData, uint[8] _uintArgs)
        public payable returns (address);
    function computeEndowment(uint _bounty, uint _fee, uint _callGas, uint _callValue, uint _gasPrice)
        public view returns (uint);
}

contract TransactionRequestInterface {
    
     
    function execute() public returns (bool);
    function cancel() public returns (bool);
    function claim() public payable returns (bool);

     
    function proxy(address recipient, bytes callData) public payable returns (bool);

     
    function requestData() public view returns (address[6], bool[3], uint[15], uint8[1]);
    function callData() public view returns (bytes);

     
    function refundClaimDeposit() public returns (bool);
    function sendFee() public returns (bool);
    function sendBounty() public returns (bool);
    function sendOwnerEther() public returns (bool);
    function sendOwnerEther(address recipient) public returns (bool);
}

contract TransactionRequestCore is TransactionRequestInterface {
    using RequestLib for RequestLib.Request;
    using RequestScheduleLib for RequestScheduleLib.ExecutionWindow;

    RequestLib.Request txnRequest;
    bool private initialized = false;

     
    function initialize(
        address[4]  addressArgs,
        uint[12]    uintArgs,
        bytes       callData
    )
        public payable
    {
        require(!initialized);

        txnRequest.initialize(addressArgs, uintArgs, callData);
        initialized = true;
    }

     
    function() public payable {}

     
    function execute() public returns (bool) {
        return txnRequest.execute();
    }

    function cancel() public returns (bool) {
        return txnRequest.cancel();
    }

    function claim() public payable returns (bool) {
        return txnRequest.claim();
    }

     

     
     
    function requestData()
        public view returns (address[6], bool[3], uint[15], uint8[1])
    {
        return txnRequest.serialize();
    }

    function callData()
        public view returns (bytes data)
    {
        data = txnRequest.txnData.callData;
    }

     
    function proxy(address _to, bytes _data)
        public payable returns (bool success)
    {
        require(txnRequest.meta.owner == msg.sender && txnRequest.schedule.isAfterWindow());
        
         
        return _to.call.value(msg.value)(_data);
    }

     
    function refundClaimDeposit() public returns (bool) {
        txnRequest.refundClaimDeposit();
    }

    function sendFee() public returns (bool) {
        return txnRequest.sendFee();
    }

    function sendBounty() public returns (bool) {
        return txnRequest.sendBounty();
    }

    function sendOwnerEther() public returns (bool) {
        return txnRequest.sendOwnerEther();
    }

    function sendOwnerEther(address recipient) public returns (bool) {
        return txnRequest.sendOwnerEther(recipient);
    }

     
    event Aborted(uint8 reason);
    event Cancelled(uint rewardPayment, uint measuredGasConsumption);
    event Claimed();
    event Executed(uint bounty, uint fee, uint measuredGasConsumption);
}

contract RequestFactoryInterface {
    event RequestCreated(address request, address indexed owner, int indexed bucket, uint[12] params);

    function createRequest(address[3] addressArgs, uint[12] uintArgs, bytes callData) public payable returns (address);
    function createValidatedRequest(address[3] addressArgs, uint[12] uintArgs, bytes callData) public payable returns (address);
    function validateRequestParams(address[3] addressArgs, uint[12] uintArgs, uint endowment) public view returns (bool[6]);
    function isKnownRequest(address _address) public view returns (bool);
}

contract TransactionRecorder {
    address owner;

    bool public wasCalled;
    uint public lastCallValue;
    address public lastCaller;
    bytes public lastCallData = "";
    uint public lastCallGas;

    function TransactionRecorder()  public {
        owner = msg.sender;
    }

    function() payable  public {
        lastCallGas = gasleft();
        lastCallData = msg.data;
        lastCaller = msg.sender;
        lastCallValue = msg.value;
        wasCalled = true;
    }

    function __reset__() public {
        lastCallGas = 0;
        lastCallData = "";
        lastCaller = 0x0;
        lastCallValue = 0;
        wasCalled = false;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}

contract Proxy {
    SchedulerInterface public scheduler;
    address public receipient; 
    address public scheduledTransaction;
    address public owner;

    function Proxy(address _scheduler, address _receipient, uint _payout, uint _gasPrice, uint _delay) public payable {
        scheduler = SchedulerInterface(_scheduler);
        receipient = _receipient;
        owner = msg.sender;

        scheduledTransaction = scheduler.schedule.value(msg.value)(
            this,               
            "",                      
            [
                2000000,             
                _payout,                   
                255,                 
                block.number + _delay,         
                _gasPrice,     
                12345 wei,           
                224455 wei,          
                20000 wei            
            ]
        );
    }

    function () public payable {
        if (msg.value > 0) {
            receipient.transfer(msg.value);
        }
    }

    function sendOwnerEther(address _receipient) public {
        if (msg.sender == owner && _receipient != 0x0) {
            TransactionRequestInterface(scheduledTransaction).sendOwnerEther(_receipient);
        }   
    }
}

 
 
contract SimpleToken {

    address public owner;

    mapping(address => uint) balances;

    function SimpleToken (uint _initialSupply) public {
        owner = msg.sender;
        balances[owner] = _initialSupply;
    }

    function transfer (address _to, uint _amount)
        public returns (bool success)
    {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        success = true;
    }

    uint public constant rate = 30;

    function buyTokens()
        public payable returns (bool success)
    {
        require(msg.value > 0);
        balances[msg.sender] += msg.value * rate;
        success = true;
    }

    function balanceOf (address _who)
        public view returns (uint balance)
    {
        balance = balances[_who];
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
   
  uint256 c = a / b;
   
  return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  require(b <= a);
  return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
  uint256 c = a + b;
  require(c >= a);
  return c;
  }
}

 
contract BaseScheduler is SchedulerInterface {
     
    address public factoryAddress;

     
    RequestScheduleLib.TemporalUnit public temporalUnit;

     
    address public feeRecipient;

     
    function() public payable {}

     
    event NewRequest(address request);

      
    function schedule (
        address   _toAddress,
        bytes     _callData,
        uint[8]   _uintArgs
    )
        public payable returns (address newRequest)
    {
        RequestFactoryInterface factory = RequestFactoryInterface(factoryAddress);

        uint endowment = computeEndowment(
            _uintArgs[6],  
            _uintArgs[5],  
            _uintArgs[0],  
            _uintArgs[1],  
            _uintArgs[4]   
        );

        require(msg.value >= endowment);

        if (temporalUnit == RequestScheduleLib.TemporalUnit.Blocks) {
            newRequest = factory.createValidatedRequest.value(msg.value)(
                [
                    msg.sender,                  
                    feeRecipient,                
                    _toAddress                   
                ],
                [
                    _uintArgs[5],                
                    _uintArgs[6],                
                    255,                         
                    10,                          
                    16,                          
                    uint(temporalUnit),          
                    _uintArgs[2],                
                    _uintArgs[3],                
                    _uintArgs[0],                
                    _uintArgs[1],                
                    _uintArgs[4],                
                    _uintArgs[7]                 
                ],
                _callData
            );
        } else if (temporalUnit == RequestScheduleLib.TemporalUnit.Timestamp) {
            newRequest = factory.createValidatedRequest.value(msg.value)(
                [
                    msg.sender,                  
                    feeRecipient,                
                    _toAddress                   
                ],
                [
                    _uintArgs[5],                
                    _uintArgs[6],                
                    60 minutes,                  
                    3 minutes,                   
                    5 minutes,                   
                    uint(temporalUnit),          
                    _uintArgs[2],                
                    _uintArgs[3],                
                    _uintArgs[0],                
                    _uintArgs[1],                
                    _uintArgs[4],                
                    _uintArgs[7]                 
                ],
                _callData
            );
        } else {
             
            revert();
        }

        require(newRequest != 0x0);
        emit NewRequest(newRequest);
        return newRequest;
    }

    function computeEndowment(
        uint _bounty,
        uint _fee,
        uint _callGas,
        uint _callValue,
        uint _gasPrice
    )
        public view returns (uint)
    {
        return PaymentLib.computeEndowment(
            _bounty,
            _fee,
            _callGas,
            _callValue,
            _gasPrice,
            RequestLib.getEXECUTION_GAS_OVERHEAD()
        );
    }
}

 
contract BlockScheduler is BaseScheduler {

     
    constructor(address _factoryAddress, address _feeRecipient) public {
        require(_factoryAddress != 0x0);

         
        temporalUnit = RequestScheduleLib.TemporalUnit.Blocks;

         
        factoryAddress = _factoryAddress;

         
        feeRecipient = _feeRecipient;
    }
}

 
contract TimestampScheduler is BaseScheduler {

     
    constructor(address _factoryAddress, address _feeRecipient) public {
        require(_factoryAddress != 0x0);

         
        temporalUnit = RequestScheduleLib.TemporalUnit.Timestamp;

         
        factoryAddress = _factoryAddress;

         
        feeRecipient = _feeRecipient;
    }
}

 

contract Migrations {
    address public owner;

    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) {
            _;
        }
    }

    function Migrations()  public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) restricted  public {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) restricted  public {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}

 
library ExecutionLib {

    struct ExecutionData {
        address toAddress;                   
        bytes callData;                      
        uint callValue;                      
        uint callGas;                        
        uint gasPrice;                       
    }

     
    function sendTransaction(ExecutionData storage self)
        internal returns (bool)
    {
         
        require(self.gasPrice <= tx.gasprice);
         
        return self.toAddress.call.value(self.callValue).gas(self.callGas)(self.callData);
    }


     
    function CALL_GAS_CEILING(uint EXTRA_GAS) 
        internal view returns (uint)
    {
        return block.gaslimit - EXTRA_GAS;
    }

     
    function validateCallGas(uint callGas, uint EXTRA_GAS)
        internal view returns (bool)
    {
        return callGas < CALL_GAS_CEILING(EXTRA_GAS);
    }

     
    function validateToAddress(address toAddress)
        internal pure returns (bool)
    {
        return toAddress != 0x0;
    }
}

library MathLib {
    uint constant INT_MAX = 57896044618658097711785492504343953926634992332820282019728792003956564819967;   
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     

     
    function max(uint a, uint b) 
        public pure returns (uint)
    {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

     
    function min(uint a, uint b) 
        public pure returns (uint)
    {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

     
    function safeCastSigned(uint a) 
        public pure returns (int)
    {
        assert(a <= INT_MAX);
        return int(a);
    }
    
}

 
library RequestMetaLib {

    struct RequestMeta {
        address owner;               

        address createdBy;           

        bool isCancelled;            
        
        bool wasCalled;              

        bool wasSuccessful;          
    }

}

library RequestLib {
    using ClaimLib for ClaimLib.ClaimData;
    using ExecutionLib for ExecutionLib.ExecutionData;
    using PaymentLib for PaymentLib.PaymentData;
    using RequestMetaLib for RequestMetaLib.RequestMeta;
    using RequestScheduleLib for RequestScheduleLib.ExecutionWindow;
    using SafeMath for uint;

    struct Request {
        ExecutionLib.ExecutionData txnData;
        RequestMetaLib.RequestMeta meta;
        PaymentLib.PaymentData paymentData;
        ClaimLib.ClaimData claimData;
        RequestScheduleLib.ExecutionWindow schedule;
    }

    enum AbortReason {
        WasCancelled,        
        AlreadyCalled,       
        BeforeCallWindow,    
        AfterCallWindow,     
        ReservedForClaimer,  
        InsufficientGas,     
        TooLowGasPrice     
    }

    event Aborted(uint8 reason);
    event Cancelled(uint rewardPayment, uint measuredGasConsumption);
    event Claimed();
    event Executed(uint bounty, uint fee, uint measuredGasConsumption);

     
    function validate(
        address[4]  _addressArgs,
        uint[12]    _uintArgs,
        uint        _endowment
    ) 
        public view returns (bool[6] isValid)
    {
         
         
        isValid[0] = PaymentLib.validateEndowment(
            _endowment,
            _uintArgs[1],                
            _uintArgs[0],                
            _uintArgs[8],                
            _uintArgs[9],                
            _uintArgs[10],               
            EXECUTION_GAS_OVERHEAD
        );
        isValid[1] = RequestScheduleLib.validateReservedWindowSize(
            _uintArgs[4],                
            _uintArgs[6]                 
        );
        isValid[2] = RequestScheduleLib.validateTemporalUnit(_uintArgs[5]);
        isValid[3] = RequestScheduleLib.validateWindowStart(
            RequestScheduleLib.TemporalUnit(MathLib.min(_uintArgs[5], 2)),
            _uintArgs[3],                
            _uintArgs[7]                 
        );
        isValid[4] = ExecutionLib.validateCallGas(
            _uintArgs[8],                
            EXECUTION_GAS_OVERHEAD
        );
        isValid[5] = ExecutionLib.validateToAddress(_addressArgs[3]);

        return isValid;
    }

     
    function initialize(
        Request storage self,
        address[4]      _addressArgs,
        uint[12]        _uintArgs,
        bytes           _callData
    ) 
        public returns (bool)
    {
        address[6] memory addressValues = [
            0x0,                 
            _addressArgs[0],     
            _addressArgs[1],     
            _addressArgs[2],     
            0x0,                 
            _addressArgs[3]      
        ];

        bool[3] memory boolValues = [false, false, false];

        uint[15] memory uintValues = [
            0,                   
            _uintArgs[0],        
            0,                   
            _uintArgs[1],        
            0,                   
            _uintArgs[2],        
            _uintArgs[3],        
            _uintArgs[4],        
            _uintArgs[5],        
            _uintArgs[6],        
            _uintArgs[7],        
            _uintArgs[8],        
            _uintArgs[9],        
            _uintArgs[10],       
            _uintArgs[11]        
        ];

        uint8[1] memory uint8Values = [
            0
        ];

        require(deserialize(self, addressValues, boolValues, uintValues, uint8Values, _callData));

        return true;
    }
 
    function serialize(Request storage self)
        internal view returns(address[6], bool[3], uint[15], uint8[1])
    {
        address[6] memory addressValues = [
            self.claimData.claimedBy,
            self.meta.createdBy,
            self.meta.owner,
            self.paymentData.feeRecipient,
            self.paymentData.bountyBenefactor,
            self.txnData.toAddress
        ];

        bool[3] memory boolValues = [
            self.meta.isCancelled,
            self.meta.wasCalled,
            self.meta.wasSuccessful
        ];

        uint[15] memory uintValues = [
            self.claimData.claimDeposit,
            self.paymentData.fee,
            self.paymentData.feeOwed,
            self.paymentData.bounty,
            self.paymentData.bountyOwed,
            self.schedule.claimWindowSize,
            self.schedule.freezePeriod,
            self.schedule.reservedWindowSize,
            uint(self.schedule.temporalUnit),
            self.schedule.windowSize,
            self.schedule.windowStart,
            self.txnData.callGas,
            self.txnData.callValue,
            self.txnData.gasPrice,
            self.claimData.requiredDeposit
        ];

        uint8[1] memory uint8Values = [
            self.claimData.paymentModifier
        ];

        return (addressValues, boolValues, uintValues, uint8Values);
    }

     
    function deserialize(
        Request storage self,
        address[6]  _addressValues,
        bool[3]     _boolValues,
        uint[15]    _uintValues,
        uint8[1]    _uint8Values,
        bytes       _callData
    )
        internal returns (bool)
    {
         
        self.txnData.callData = _callData;

         
        self.claimData.claimedBy = _addressValues[0];
        self.meta.createdBy = _addressValues[1];
        self.meta.owner = _addressValues[2];
        self.paymentData.feeRecipient = _addressValues[3];
        self.paymentData.bountyBenefactor = _addressValues[4];
        self.txnData.toAddress = _addressValues[5];

         
        self.meta.isCancelled = _boolValues[0];
        self.meta.wasCalled = _boolValues[1];
        self.meta.wasSuccessful = _boolValues[2];

         
        self.claimData.claimDeposit = _uintValues[0];
        self.paymentData.fee = _uintValues[1];
        self.paymentData.feeOwed = _uintValues[2];
        self.paymentData.bounty = _uintValues[3];
        self.paymentData.bountyOwed = _uintValues[4];
        self.schedule.claimWindowSize = _uintValues[5];
        self.schedule.freezePeriod = _uintValues[6];
        self.schedule.reservedWindowSize = _uintValues[7];
        self.schedule.temporalUnit = RequestScheduleLib.TemporalUnit(_uintValues[8]);
        self.schedule.windowSize = _uintValues[9];
        self.schedule.windowStart = _uintValues[10];
        self.txnData.callGas = _uintValues[11];
        self.txnData.callValue = _uintValues[12];
        self.txnData.gasPrice = _uintValues[13];
        self.claimData.requiredDeposit = _uintValues[14];

         
        self.claimData.paymentModifier = _uint8Values[0];

        return true;
    }

    function execute(Request storage self) 
        internal returns (bool)
    {
         

         
         
        uint startGas = gasleft();

         
         
         

        if (gasleft() < requiredExecutionGas(self).sub(PRE_EXECUTION_GAS)) {
            emit Aborted(uint8(AbortReason.InsufficientGas));
            return false;
        } else if (self.meta.wasCalled) {
            emit Aborted(uint8(AbortReason.AlreadyCalled));
            return false;
        } else if (self.meta.isCancelled) {
            emit Aborted(uint8(AbortReason.WasCancelled));
            return false;
        } else if (self.schedule.isBeforeWindow()) {
            emit Aborted(uint8(AbortReason.BeforeCallWindow));
            return false;
        } else if (self.schedule.isAfterWindow()) {
            emit Aborted(uint8(AbortReason.AfterCallWindow));
            return false;
        } else if (self.claimData.isClaimed() && msg.sender != self.claimData.claimedBy && self.schedule.inReservedWindow()) {
            emit Aborted(uint8(AbortReason.ReservedForClaimer));
            return false;
        } else if (self.txnData.gasPrice > tx.gasprice) {
            emit Aborted(uint8(AbortReason.TooLowGasPrice));
            return false;
        }

         
         
         
         
         
         

         
        self.meta.wasCalled = true;

         
         
         
        self.meta.wasSuccessful = self.txnData.sendTransaction();

         
         
         
         
         
         

         
        if (self.paymentData.hasFeeRecipient()) {
            self.paymentData.feeOwed = self.paymentData.getFee()
                .add(self.paymentData.feeOwed);
        }

         
         
        uint totalFeePayment = self.paymentData.feeOwed;

         
         
        self.paymentData.sendFee();

         
        self.paymentData.bountyBenefactor = msg.sender;
        if (self.claimData.isClaimed()) {
             
             
            self.paymentData.bountyOwed = self.claimData.claimDeposit
                .add(self.paymentData.bountyOwed);
             
             
            self.claimData.claimDeposit = 0;
             
             
            self.paymentData.bountyOwed = self.paymentData.getBountyWithModifier(self.claimData.paymentModifier)
                .add(self.paymentData.bountyOwed);
        } else {
             
            self.paymentData.bountyOwed = self.paymentData.getBounty().add(self.paymentData.bountyOwed);
        }

         
        uint measuredGasConsumption = startGas.sub(gasleft()).add(EXECUTE_EXTRA_GAS);

         
         
         

         
        self.paymentData.bountyOwed = measuredGasConsumption
            .mul(self.txnData.gasPrice)
            .add(self.paymentData.bountyOwed);

         
         
        emit Executed(self.paymentData.bountyOwed, totalFeePayment, measuredGasConsumption);
    
         
        self.paymentData.sendBounty();

         
        _sendOwnerEther(self, self.meta.owner);

         
         
         
         
        return true;
    }


     
     
     
    uint public constant PRE_EXECUTION_GAS = 25000;    
    
     
    uint public constant EXECUTION_GAS_OVERHEAD = 180000;  
     
    uint public constant  EXECUTE_EXTRA_GAS = 90000;  

     
    uint public constant CANCEL_EXTRA_GAS = 85000;  

    function getEXECUTION_GAS_OVERHEAD()
        public pure returns (uint)
    {
        return EXECUTION_GAS_OVERHEAD;
    }
    
    function requiredExecutionGas(Request storage self) 
        public view returns (uint requiredGas)
    {
        requiredGas = self.txnData.callGas.add(EXECUTION_GAS_OVERHEAD);
    }

     
    function isCancellable(Request storage self) 
        public view returns (bool)
    {
        if (self.meta.isCancelled) {
             
            return false;
        } else if (!self.meta.wasCalled && self.schedule.isAfterWindow()) {
             
            return true;
        } else if (!self.claimData.isClaimed() && self.schedule.isBeforeFreeze() && msg.sender == self.meta.owner) {
             
            return true;
        } else {
             
            return false;
        }
    }

     
    function cancel(Request storage self) 
        public returns (bool)
    {
        uint startGas = gasleft();
        uint rewardPayment;
        uint measuredGasConsumption;

         
        require(isCancellable(self));

         
        self.meta.isCancelled = true;

         
        require(self.claimData.refundDeposit());

         
         
         
         
        if (msg.sender != self.meta.owner) {
             
            address rewardBenefactor = msg.sender;
             
             
            uint rewardOwed = self.paymentData.bountyOwed
                .add(self.paymentData.bounty.div(100));

             
            measuredGasConsumption = startGas
                .sub(gasleft())
                .add(CANCEL_EXTRA_GAS);
             
            rewardOwed = measuredGasConsumption
                .mul(tx.gasprice)
                .add(rewardOwed);

             
            rewardPayment = rewardOwed;

             
            if (rewardOwed > 0) {
                self.paymentData.bountyOwed = 0;
                rewardBenefactor.transfer(rewardOwed);
            }
        }

         
        emit Cancelled(rewardPayment, measuredGasConsumption);

         
        return sendOwnerEther(self);
    }

     
    function isClaimable(Request storage self) 
        internal view returns (bool)
    {
         
        require(!self.claimData.isClaimed());
        require(!self.meta.isCancelled);

         
        require(self.schedule.inClaimWindow());
        require(msg.value >= self.claimData.requiredDeposit);
        return true;
    }

     
    function claim(Request storage self) 
        internal returns (bool claimed)
    {
        require(isClaimable(self));
        
        emit Claimed();
        return self.claimData.claim(self.schedule.computePaymentModifier());
    }

     
    function refundClaimDeposit(Request storage self)
        public returns (bool)
    {
        require(self.meta.isCancelled || self.schedule.isAfterWindow());
        return self.claimData.refundDeposit();
    }

     
    function sendFee(Request storage self) 
        public returns (bool)
    {
        if (self.schedule.isAfterWindow()) {
            return self.paymentData.sendFee();
        }
        return false;
    }

     
    function sendBounty(Request storage self) 
        public returns (bool)
    {
         
        if (self.schedule.isAfterWindow()) {
            return self.paymentData.sendBounty();
        }
        return false;
    }

    function canSendOwnerEther(Request storage self) 
        public view returns(bool) 
    {
        return self.meta.isCancelled || self.schedule.isAfterWindow() || self.meta.wasCalled;
    }

     
    function sendOwnerEther(Request storage self, address recipient)
        public returns (bool)
    {
        require(recipient != 0x0);
        if(canSendOwnerEther(self) && msg.sender == self.meta.owner) {
            return _sendOwnerEther(self, recipient);
        }
        return false;
    }

     
    function sendOwnerEther(Request storage self)
        public returns (bool)
    {
        if(canSendOwnerEther(self)) {
            return _sendOwnerEther(self, self.meta.owner);
        }
        return false;
    }

    function _sendOwnerEther(Request storage self, address recipient) 
        private returns (bool)
    {
         
         
        uint ownerRefund = address(this).balance
            .sub(self.claimData.claimDeposit)
            .sub(self.paymentData.bountyOwed)
            .sub(self.paymentData.feeOwed);
         
        return recipient.send(ownerRefund);
    }
}

 
library RequestScheduleLib {
    using SafeMath for uint;

     
    enum TemporalUnit {
        Null,            
        Blocks,          
        Timestamp        
    }

    struct ExecutionWindow {

        TemporalUnit temporalUnit;       

        uint windowStart;                

        uint windowSize;                 

        uint freezePeriod;               

        uint reservedWindowSize;         

        uint claimWindowSize;            
    }

     
    function getNow(ExecutionWindow storage self) 
        public view returns (uint)
    {
        return _getNow(self.temporalUnit);
    }

     
    function _getNow(TemporalUnit _temporalUnit) 
        internal view returns (uint)
    {
        if (_temporalUnit == TemporalUnit.Timestamp) {
            return block.timestamp;
        } 
        if (_temporalUnit == TemporalUnit.Blocks) {
            return block.number;
        }
         
        revert();
    }

     
    function computePaymentModifier(ExecutionWindow storage self) 
        internal view returns (uint8)
    {        
        uint paymentModifier = (getNow(self).sub(firstClaimBlock(self)))
            .mul(100)
            .div(self.claimWindowSize); 
        assert(paymentModifier <= 100); 

        return uint8(paymentModifier);
    }

     
    function windowEnd(ExecutionWindow storage self)
        internal view returns (uint)
    {
        return self.windowStart.add(self.windowSize);
    }

     
    function reservedWindowEnd(ExecutionWindow storage self)
        internal view returns (uint)
    {
        return self.windowStart.add(self.reservedWindowSize);
    }

     
    function freezeStart(ExecutionWindow storage self) 
        internal view returns (uint)
    {
        return self.windowStart.sub(self.freezePeriod);
    }

     
    function firstClaimBlock(ExecutionWindow storage self) 
        internal view returns (uint)
    {
        return freezeStart(self).sub(self.claimWindowSize);
    }

     
    function isBeforeWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return getNow(self) < self.windowStart;
    }

     
    function isAfterWindow(ExecutionWindow storage self) 
        internal view returns (bool)
    {
        return getNow(self) > windowEnd(self);
    }

     
    function inWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return self.windowStart <= getNow(self) && getNow(self) < windowEnd(self);
    }

     
    function inReservedWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return self.windowStart <= getNow(self) && getNow(self) < reservedWindowEnd(self);
    }

     
    function inClaimWindow(ExecutionWindow storage self) 
        internal view returns (bool)
    {
         
         
        return firstClaimBlock(self) <= getNow(self) && getNow(self) < freezeStart(self);
    }

     
    function isBeforeFreeze(ExecutionWindow storage self) 
        internal view returns (bool)
    {
        return getNow(self) < freezeStart(self);
    }

     
    function isBeforeClaimWindow(ExecutionWindow storage self)
        internal view returns (bool)
    {
        return getNow(self) < firstClaimBlock(self);
    }

     
     
     

     
    function validateReservedWindowSize(uint _reservedWindowSize, uint _windowSize)
        public pure returns (bool)
    {
        return _reservedWindowSize <= _windowSize;
    }

     
    function validateWindowStart(TemporalUnit _temporalUnit, uint _freezePeriod, uint _windowStart) 
        public view returns (bool)
    {
        return _getNow(_temporalUnit).add(_freezePeriod) <= _windowStart;
    }

     
    function validateTemporalUnit(uint _temporalUnitAsUInt) 
        public pure returns (bool)
    {
        return (_temporalUnitAsUInt != uint(TemporalUnit.Null) &&
            (_temporalUnitAsUInt == uint(TemporalUnit.Blocks) ||
            _temporalUnitAsUInt == uint(TemporalUnit.Timestamp))
        );
    }
}

library ClaimLib {

    struct ClaimData {
        address claimedBy;           
        uint claimDeposit;           
        uint requiredDeposit;        
        uint8 paymentModifier;       
                                     
    }

     
    function claim(
        ClaimData storage self, 
        uint8 _paymentModifier
    ) 
        internal returns (bool)
    {
        self.claimedBy = msg.sender;
        self.claimDeposit = msg.value;
        self.paymentModifier = _paymentModifier;
        return true;
    }

     
    function isClaimed(ClaimData storage self) 
        internal view returns (bool)
    {
        return self.claimedBy != 0x0;
    }


     
    function refundDeposit(ClaimData storage self) 
        internal returns (bool)
    {
         
        if (self.claimDeposit > 0) {
            uint depositAmount;
            depositAmount = self.claimDeposit;
            self.claimDeposit = 0;
             
            return self.claimedBy.send(depositAmount);
        }
        return true;
    }
}


 
library PaymentLib {
    using SafeMath for uint;

    struct PaymentData {
        uint bounty;                 

        address bountyBenefactor;    

        uint bountyOwed;             

        uint fee;                    

        address feeRecipient;        

        uint feeOwed;                
    }

     
     
     

     
    function hasFeeRecipient(PaymentData storage self)
        internal view returns (bool)
    {
        return self.feeRecipient != 0x0;
    }

     
    function getFee(PaymentData storage self) 
        internal view returns (uint)
    {
        return self.fee;
    }

     
    function getBounty(PaymentData storage self)
        internal view returns (uint)
    {
        return self.bounty;
    }
 
     
    function getBountyWithModifier(PaymentData storage self, uint8 _paymentModifier)
        internal view returns (uint)
    {
        return getBounty(self).mul(_paymentModifier).div(100);
    }

     
     
     

     
    function sendFee(PaymentData storage self) 
        internal returns (bool)
    {
        uint feeAmount = self.feeOwed;
        if (feeAmount > 0) {
             
            self.feeOwed = 0;
             
            return self.feeRecipient.send(feeAmount);
        }
        return true;
    }

     
    function sendBounty(PaymentData storage self)
        internal returns (bool)
    {
        uint bountyAmount = self.bountyOwed;
        if (bountyAmount > 0) {
             
            self.bountyOwed = 0;
            return self.bountyBenefactor.send(bountyAmount);
        }
        return true;
    }

     
     
     

     
    function computeEndowment(
        uint _bounty,
        uint _fee,
        uint _callGas,
        uint _callValue,
        uint _gasPrice,
        uint _gasOverhead
    ) 
        public pure returns (uint)
    {
        return _bounty
            .add(_fee)
            .add(_callGas.mul(_gasPrice))
            .add(_gasOverhead.mul(_gasPrice))
            .add(_callValue);
    }

     
    function validateEndowment(uint _endowment, uint _bounty, uint _fee, uint _callGas, uint _callValue, uint _gasPrice, uint _gasOverhead)
        public pure returns (bool)
    {
        return _endowment >= computeEndowment(
            _bounty,
            _fee,
            _callGas,
            _callValue,
            _gasPrice,
            _gasOverhead
        );
    }
}

 
library IterTools {
     
    function all(bool[6] _values) 
        public pure returns (bool)
    {
        for (uint i = 0; i < _values.length; i++) {
            if (!_values[i]) {
                return false;
            }
        }
        return true;
    }
}

 
 
 

contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

 
contract DelayedPayment {

    SchedulerInterface public scheduler;
    
    address recipient;
    address owner;
    address public payment;

    uint lockedUntil;
    uint value;
    uint twentyGwei = 20000000000 wei;

    constructor(
        address _scheduler,
        uint    _numBlocks,
        address _recipient,
        uint _value
    )  public payable {
        scheduler = SchedulerInterface(_scheduler);
        lockedUntil = block.number + _numBlocks;
        recipient = _recipient;
        owner = msg.sender;
        value = _value;
   
        uint endowment = scheduler.computeEndowment(
            twentyGwei,
            twentyGwei,
            200000,
            0,
            twentyGwei
        );

        payment = scheduler.schedule.value(endowment)(  
            this,                    
            "",                      
            [
                200000,              
                0,                   
                255,                 
                lockedUntil,         
                twentyGwei,     
                twentyGwei,     
                twentyGwei,          
                twentyGwei * 2      
            ]
        );

        assert(address(this).balance >= value);
    }

    function () public payable {
        if (msg.value > 0) {  
            return;
        } else if (address(this).balance > 0) {
            payout();
        } else {
            revert();
        }
    }

    function payout()
        public returns (bool)
    {
        require(block.number >= lockedUntil);
        
        recipient.transfer(value);
        return true;
    }

    function collectRemaining()
        public returns (bool) 
    {
        owner.transfer(address(this).balance);
    }
}

 
contract RecurringPayment {
    SchedulerInterface public scheduler;
    
    uint paymentInterval;
    uint paymentValue;
    uint lockedUntil;

    address recipient;
    address public currentScheduledTransaction;

    event PaymentScheduled(address indexed scheduledTransaction, address recipient, uint value);
    event PaymentExecuted(address indexed scheduledTransaction, address recipient, uint value);

    function RecurringPayment(
        address _scheduler,
        uint _paymentInterval,
        uint _paymentValue,
        address _recipient
    )  public payable {
        scheduler = SchedulerInterface(_scheduler);
        paymentInterval = _paymentInterval;
        recipient = _recipient;
        paymentValue = _paymentValue;

        schedule();
    }

    function ()
        public payable 
    {
        if (msg.value > 0) {  
            return;
        } 
        
        process();
    }

    function process() public returns (bool) {
        payout();
        schedule();
    }

    function payout()
        private returns (bool)
    {
        require(block.number >= lockedUntil);
        require(address(this).balance >= paymentValue);
        
        recipient.transfer(paymentValue);

        emit PaymentExecuted(currentScheduledTransaction, recipient, paymentValue);
        return true;
    }

    function schedule() 
        private returns (bool)
    {
        lockedUntil = block.number + paymentInterval;

        currentScheduledTransaction = scheduler.schedule.value(0.1 ether)(  
            this,                    
            "",                      
            [
                1000000,             
                0,                   
                255,                 
                lockedUntil,         
                20000000000 wei,     
                20000000000 wei,     
                20000000000 wei,          
                30000000000 wei      
            ]
        );

        emit PaymentScheduled(currentScheduledTransaction, recipient, paymentValue);
    }
}

 
contract RequestFactory is RequestFactoryInterface, CloneFactory, Pausable {
    using IterTools for bool[6];

    TransactionRequestCore public transactionRequestCore;

    uint constant public BLOCKS_BUCKET_SIZE = 240;  
    uint constant public TIMESTAMP_BUCKET_SIZE = 3600;  

    constructor(
        address _transactionRequestCore
    ) 
        public 
    {
        require(_transactionRequestCore != 0x0);

        transactionRequestCore = TransactionRequestCore(_transactionRequestCore);
    }

     
    function createRequest(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        bytes       _callData
    )
        whenNotPaused
        public payable returns (address)
    {
         
        address transactionRequest = createClone(transactionRequestCore);

         
        TransactionRequestCore(transactionRequest).initialize.value(msg.value)(
            [
                msg.sender,        
                _addressArgs[0],   
                _addressArgs[1],   
                _addressArgs[2]    
            ],
            _uintArgs,             
            _callData
        );

         
        requests[transactionRequest] = true;

         
        emit RequestCreated(
            transactionRequest,
            _addressArgs[0],
            getBucket(_uintArgs[7], RequestScheduleLib.TemporalUnit(_uintArgs[5])),
            _uintArgs
        );

        return transactionRequest;
    }

     
    function createValidatedRequest(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        bytes       _callData
    )
        public payable returns (address)
    {
        bool[6] memory isValid = validateRequestParams(
            _addressArgs,
            _uintArgs,
            msg.value
        );

        if (!isValid.all()) {
            if (!isValid[0]) {
                emit ValidationError(uint8(Errors.InsufficientEndowment));
            }
            if (!isValid[1]) {
                emit ValidationError(uint8(Errors.ReservedWindowBiggerThanExecutionWindow));
            }
            if (!isValid[2]) {
                emit ValidationError(uint8(Errors.InvalidTemporalUnit));
            }
            if (!isValid[3]) {
                emit ValidationError(uint8(Errors.ExecutionWindowTooSoon));
            }
            if (!isValid[4]) {
                emit ValidationError(uint8(Errors.CallGasTooHigh));
            }
            if (!isValid[5]) {
                emit ValidationError(uint8(Errors.EmptyToAddress));
            }

             
            msg.sender.transfer(msg.value);
            
            return 0x0;
        }

        return createRequest(_addressArgs, _uintArgs, _callData);
    }

     
     
     

     
    enum Errors {
        InsufficientEndowment,
        ReservedWindowBiggerThanExecutionWindow,
        InvalidTemporalUnit,
        ExecutionWindowTooSoon,
        CallGasTooHigh,
        EmptyToAddress
    }

    event ValidationError(uint8 error);

     
    function validateRequestParams(
        address[3]  _addressArgs,
        uint[12]    _uintArgs,
        uint        _endowment
    )
        public view returns (bool[6])
    {
        return RequestLib.validate(
            [
                msg.sender,       
                _addressArgs[0],   
                _addressArgs[1],   
                _addressArgs[2]    
            ],
            _uintArgs,
            _endowment
        );
    }

     
    mapping (address => bool) requests;

    function isKnownRequest(address _address)
        public view returns (bool isKnown)
    {
        return requests[_address];
    }

    function getBucket(uint windowStart, RequestScheduleLib.TemporalUnit unit)
        public pure returns(int)
    {
        uint bucketSize;
         
        int sign;

        if (unit == RequestScheduleLib.TemporalUnit.Blocks) {
            bucketSize = BLOCKS_BUCKET_SIZE;
            sign = -1;
        } else if (unit == RequestScheduleLib.TemporalUnit.Timestamp) {
            bucketSize = TIMESTAMP_BUCKET_SIZE;
            sign = 1;
        } else {
            revert();
        }
        return sign * int(windowStart - (windowStart % bucketSize));
    }
}