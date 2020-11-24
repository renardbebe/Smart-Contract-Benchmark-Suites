 

pragma solidity ^0.4.23;

 
 
interface IRegistry {
    function owner() external view returns (address _addr);
    function addressOf(bytes32 _name) external view returns (address _addr);
}

contract UsingRegistry {
    IRegistry private registry;

    modifier fromOwner(){
        require(msg.sender == getOwner());
        _;
    }

    constructor(address _registry)
        public
    {
        require(_registry != 0);
        registry = IRegistry(_registry);
    }

    function addressOf(bytes32 _name)
        internal
        view
        returns(address _addr)
    {
        return registry.addressOf(_name);
    }

    function getOwner()
        public
        view
        returns (address _addr)
    {
        return registry.owner();
    }

    function getRegistry()
        public
        view
        returns (IRegistry _addr)
    {
        return registry;
    }
}

 
contract UsingAdmin is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromAdmin(){
        require(msg.sender == getAdmin());
        _;
    }
    
    function getAdmin()
        public
        constant
        returns (address _addr)
    {
        return addressOf("ADMIN");
    }
}

 
contract Ledger {
    uint public total;       

    struct Entry {           
        uint balance;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

     
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


     
     
     

    function add(address _address, uint _amt)
        fromOwner
        public
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

         
        if (entry.balance == 0) {
            entry.next = entries[0x0].next;
            entries[entries[0x0].next].prev = _address;
            entries[0x0].next = _address;
        }
         
        total += _amt;
        entry.balance += _amt;
    }

    function subtract(address _address, uint _amt)
        fromOwner
        public
        returns (uint _amtRemoved)
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

        uint _maxAmt = entry.balance;
        if (_maxAmt == 0) return;
        
        if (_amt >= _maxAmt) {
             
            total -= _maxAmt;
            entries[entry.prev].next = entry.next;
            entries[entry.next].prev = entry.prev;
            delete entries[_address];
            return _maxAmt;
        } else {
             
            total -= _amt;
            entry.balance -= _amt;
            return _amt;
        }
    }


     
     
     

    function size()
        public
        view
        returns (uint _size)
    {
         
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function balanceOf(address _address)
        public
        view
        returns (uint _balance)
    {
        return entries[_address].balance;
    }

    function balances()
        public
        view
        returns (address[] _addresses, uint[] _balances)
    {
         
        uint _size = size();
        _addresses = new address[](_size);
        _balances = new uint[](_size);
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _balances[_i] = entries[_curEntry.next].balance;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return (_addresses, _balances);
    }
}

 
contract Requestable is
    UsingAdmin 
{
    uint32 public constant WAITING_TIME = 60*60*24*7;    
    uint32 public constant TIMEOUT_TIME = 60*60*24*14;   
    uint32 public constant MAX_PENDING_REQUESTS = 10;

     
    enum RequestType {SendCapital, RecallCapital, RaiseCapital, DistributeCapital}
    struct Request {
         
        uint32 id;
        uint8 typeId;
        uint32 dateCreated;
        uint32 dateCancelled;
        uint32 dateExecuted;
        string createdMsg;
        string cancelledMsg;
        string executedMsg;
        bool executedSuccessfully;
         
        address target;
        uint value;
    }
    mapping (uint32 => Request) public requests;
    uint32 public curRequestId;
    uint32[] public completedRequestIds;
    uint32[] public cancelledRequestIds;
    uint32[] public pendingRequestIds;

     
    event RequestCreated(uint time, uint indexed id, uint indexed typeId, address indexed target, uint value, string msg);
    event RequestCancelled(uint time, uint indexed id, uint indexed typeId, address indexed target, string msg);
    event RequestExecuted(uint time, uint indexed id, uint indexed typeId, address indexed target, bool success, string msg);

    constructor(address _registry)
        UsingAdmin(_registry)
        public
    { }

     
     
    function createRequest(uint _typeId, address _target, uint _value, string _msg)
        public
        fromAdmin
    {
        uint32 _id = ++curRequestId;
        requests[_id].id = _id;
        requests[_id].typeId = uint8(RequestType(_typeId));
        requests[_id].dateCreated = uint32(now);
        requests[_id].createdMsg = _msg;
        requests[_id].target = _target;
        requests[_id].value = _value;
        _addPendingRequestId(_id);
        emit RequestCreated(now, _id, _typeId, _target, _value, _msg);
    }

     
     
    function cancelRequest(uint32 _id, string _msg)
        public
        fromAdmin
    {
         
        Request storage r = requests[_id];
        require(r.id != 0 && r.dateCancelled == 0 && r.dateExecuted == 0);
        r.dateCancelled = uint32(now);
        r.cancelledMsg = _msg;
        _removePendingRequestId(_id);
        cancelledRequestIds.push(_id);
        emit RequestCancelled(now, r.id, r.typeId, r.target, _msg);
    }

     
     
    function executeRequest(uint32 _id)
        public
    {
         
         
        Request storage r = requests[_id];
        require(r.id != 0 && r.dateCancelled == 0 && r.dateExecuted == 0);
        require(uint32(now) > r.dateCreated + WAITING_TIME);
        
         
        if (uint32(now) > r.dateCreated + TIMEOUT_TIME) {
            cancelRequest(_id, "Request timed out.");
            return;
        }
                
         
        r.dateExecuted = uint32(now);
        string memory _msg;
        bool _success;
        RequestType _type = RequestType(r.typeId);
        if (_type == RequestType.SendCapital) {
            (_success, _msg) = executeSendCapital(r.target, r.value);
        } else if (_type == RequestType.RecallCapital) {
            (_success, _msg) = executeRecallCapital(r.target, r.value);
        } else if (_type == RequestType.RaiseCapital) {
            (_success, _msg) = executeRaiseCapital(r.value);
        } else if (_type == RequestType.DistributeCapital) {
            (_success, _msg) = executeDistributeCapital(r.value);
        }

         
        r.executedSuccessfully = _success;
        r.executedMsg = _msg;
        _removePendingRequestId(_id);
        completedRequestIds.push(_id);
        emit RequestExecuted(now, r.id, r.typeId, r.target, _success, _msg);
    }

     
    function _addPendingRequestId(uint32 _id)
        private
    {
        require(pendingRequestIds.length != MAX_PENDING_REQUESTS);
        pendingRequestIds.push(_id);
    }

     
     
    function _removePendingRequestId(uint32 _id)
        private
    {
         
        uint _len = pendingRequestIds.length;
        uint _foundIndex = MAX_PENDING_REQUESTS;
        for (uint _i = 0; _i < _len; _i++) {
            if (pendingRequestIds[_i] == _id) {
                _foundIndex = _i;
                break;
            }
        }
        require(_foundIndex != MAX_PENDING_REQUESTS);

         
        pendingRequestIds[_foundIndex] = pendingRequestIds[_len-1];
        pendingRequestIds.length--;
    }

     
    function executeSendCapital(address _target, uint _value)
        internal returns (bool _success, string _msg);

    function executeRecallCapital(address _target, uint _value)
        internal returns (bool _success, string _msg);

    function executeRaiseCapital(uint _value)
        internal returns (bool _success, string _msg);

    function executeDistributeCapital(uint _value)
        internal returns (bool _success, string _msg);
     

     
     
    function getRequest(uint32 _requestId) public view returns (
        uint32 _id, uint8 _typeId, address _target, uint _value,
        bool _executedSuccessfully,
        uint32 _dateCreated, uint32 _dateCancelled, uint32 _dateExecuted,
        string _createdMsg, string _cancelledMsg, string _executedMsg       
    ) {
        Request memory r = requests[_requestId];
        return (
            r.id, r.typeId, r.target, r.value,
            r.executedSuccessfully,
            r.dateCreated, r.dateCancelled, r.dateExecuted,
            r.createdMsg, r.cancelledMsg, r.executedMsg
        );
    }

    function isRequestExecutable(uint32 _requestId)
        public
        view
        returns (bool _isExecutable)
    {
        Request memory r = requests[_requestId];
        _isExecutable = (r.id>0 && r.dateCancelled==0 && r.dateExecuted==0);
        _isExecutable = _isExecutable && (uint32(now) > r.dateCreated + WAITING_TIME);
        return _isExecutable;
    }

     
    function numPendingRequests() public view returns (uint _num){
        return pendingRequestIds.length;
    }
    function numCompletedRequests() public view returns (uint _num){
        return completedRequestIds.length;
    }
    function numCancelledRequests() public view returns (uint _num){
        return cancelledRequestIds.length;
    }
}

 
 
interface _ITrBankrollable {
    function removeBankroll(uint _amount, string _callbackFn) external;
    function addBankroll() external payable;
}
interface _ITrComptroller {
    function treasury() external view returns (address);
    function token() external view returns (address);
    function wasSaleEnded() external view returns (bool);
}

contract Treasury is
    Requestable
{
     
    address public owner;
     
     
    _ITrComptroller public comptroller;

     
    uint public capital;   
    uint public profits;   
    
     
    uint public capitalRaised;         
    uint public capitalRaisedTarget;   
    Ledger public capitalLedger;       

     
    uint public profitsSent;           
    uint public profitsTotal;          

     
    event Created(uint time);
     
    event ComptrollerSet(uint time, address comptroller, address token);
     
    event CapitalAdded(uint time, address indexed sender, uint amount);
    event CapitalRemoved(uint time, address indexed recipient, uint amount);
    event CapitalRaised(uint time, uint amount);
     
    event ProfitsReceived(uint time, address indexed sender, uint amount);
     
    event ExecutedSendCapital(uint time, address indexed bankrollable, uint amount);
    event ExecutedRecallCapital(uint time, address indexed bankrollable, uint amount);
    event ExecutedRaiseCapital(uint time, uint amount);
    event ExecutedDistributeCapital(uint time, uint amount);
     
    event DividendSuccess(uint time, address token, uint amount);
    event DividendFailure(uint time, string msg);

     
     
     
     
    constructor(address _registry, address _owner)
        Requestable(_registry)
        public
    {
        owner = _owner;
        capitalLedger = new Ledger(this);
        emit Created(now);
    }


     
     
     

     
    function initComptroller(_ITrComptroller _comptroller)
        public
    {
         
        require(msg.sender == owner);
         
        require(address(comptroller) == address(0));
         
        require(_comptroller.treasury() == address(this));
        comptroller = _comptroller;
        emit ComptrollerSet(now, _comptroller, comptroller.token());
    }


     
     
     

     
    function () public payable {
        profits += msg.value;
        profitsTotal += msg.value;
        emit ProfitsReceived(now, msg.sender, msg.value);
    }

     
    function issueDividend()
        public
        returns (uint _profits)
    {
         
        if (address(comptroller) == address(0)) {
            emit DividendFailure(now, "Comptroller not yet set.");
            return;
        }
         
        if (comptroller.wasSaleEnded() == false) {
            emit DividendFailure(now, "CrowdSale not yet completed.");
            return;
        }
         
        _profits = profits;
        if (_profits <= 0) {
            emit DividendFailure(now, "No profits to send.");
            return;
        }

         
        address _token = comptroller.token();
        profits = 0;
        profitsSent += _profits;
        require(_token.call.value(_profits)());
        emit DividendSuccess(now, _token, _profits);
    }


     
     
      

     
     
    function addCapital()
        public
        payable
    {
        capital += msg.value;
        if (msg.sender == address(comptroller)) {
            capitalRaised += msg.value;
            emit CapitalRaised(now, msg.value);
        }
        emit CapitalAdded(now, msg.sender, msg.value);
    }


     
     
     

     
    function executeSendCapital(address _bankrollable, uint _value)
        internal
        returns (bool _success, string _result)
    {
         
        if (_value > capital)
            return (false, "Not enough capital.");
         
        if (!_hasCorrectTreasury(_bankrollable))
            return (false, "Bankrollable does not have correct Treasury.");

         
        capital -= _value;
        capitalLedger.add(_bankrollable, _value);

         
        _ITrBankrollable(_bankrollable).addBankroll.value(_value)();
        emit CapitalRemoved(now, _bankrollable, _value);
        emit ExecutedSendCapital(now, _bankrollable, _value);
        return (true, "Sent bankroll to target.");
    }

     
    function executeRecallCapital(address _bankrollable, uint _value)
        internal
        returns (bool _success, string _result)
    {
         
        uint _prevCapital = capital;
        _ITrBankrollable(_bankrollable).removeBankroll(_value, "addCapital()");
        uint _recalled = capital - _prevCapital;
        capitalLedger.subtract(_bankrollable, _recalled);
        
         
        emit ExecutedRecallCapital(now, _bankrollable, _recalled);
        return (true, "Received bankoll back from target.");
    }

     
    function executeRaiseCapital(uint _value)
        internal
        returns (bool _success, string _result)
    {
         
        capitalRaisedTarget += _value;
        emit ExecutedRaiseCapital(now, _value);
        return (true, "Capital target raised.");
    }

     
    function executeDistributeCapital(uint _value)
        internal
        returns (bool _success, string _result)
    {
        if (_value > capital)
            return (false, "Not enough capital.");
        capital -= _value;
        profits += _value;
        profitsTotal += _value;
        emit CapitalRemoved(now, this, _value);
        emit ProfitsReceived(now, this, _value);
        emit ExecutedDistributeCapital(now, _value);
        return (true, "Capital moved to profits.");
    }


     
     
     

    function profitsTotal()
        public
        view
        returns (uint _amount)
    {
        return profitsSent + profits;
    }

    function profitsSendable()
        public
        view
        returns (uint _amount)
    {
        if (address(comptroller)==0) return 0;
        if (!comptroller.wasSaleEnded()) return 0;
        return profits;
    }

     
    function capitalNeeded()
        public
        view
        returns (uint _amount)
    {
        return capitalRaisedTarget > capitalRaised
            ? capitalRaisedTarget - capitalRaised
            : 0;
    }

     
    function capitalAllocated()
        public
        view
        returns (uint _amount)
    {
        return capitalLedger.total();
    }

     
    function capitalAllocatedTo(address _addr)
        public
        view
        returns (uint _amount)
    {
        return capitalLedger.balanceOf(_addr);
    }

     
    function capitalAllocation()
        public
        view
        returns (address[] _addresses, uint[] _amounts)
    {
        return capitalLedger.balances();
    }

     
     
     
    function _hasCorrectTreasury(address _addr)
        private
        returns (bool)
    {
        bytes32 _sig = bytes4(keccak256("getTreasury()"));
        bool _success;
        address _response;
        assembly {
            let x := mload(0x40)     
            mstore(x, _sig)          
             
            _success := call(
                10000,   
                _addr,   
                0,       
                x,       
                4,       
                x,       
                32       
            )
             
            _response := mload(x)
        }
        return _success ? _response == address(this) : false;
    }
}