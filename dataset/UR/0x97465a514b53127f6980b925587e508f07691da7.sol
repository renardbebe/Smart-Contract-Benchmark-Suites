 

pragma solidity ^0.4.11;

 
contract Owned {
     
    address public contractOwner;

     
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

     
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

     
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 
contract Object is Owned {
     
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}


 
contract MultiEventsHistoryAdapter {

     
    function _self() constant internal returns (address) {
        return msg.sender;
    }
}

contract DelayedPaymentsEmitter is MultiEventsHistoryAdapter {
    event Error(bytes32 message);

    function emitError(bytes32 _message) {
        Error(_message);
    }
}

contract DelayedPayments is Object {
   
    uint constant DELAYED_PAYMENTS_SCOPE = 52000;
    uint constant DELAYED_PAYMENTS_INVALID_INVOCATION = DELAYED_PAYMENTS_SCOPE + 17;

     
     
     
    struct Payment {
        address spender;         
        uint earliestPayTime;    
        bool canceled;          
        bool paid;               
        address recipient;       
        uint amount;             
        uint securityGuardDelay; 
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;

     
    address public eventsHistory;

     
     
    mapping (address => bool) public allowedSpenders;

     
     
    modifier onlySecurityGuard { if (msg.sender != securityGuard) throw; _; }

     
    event PaymentAuthorized(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentExecuted(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentCanceled(uint indexed idPayment);
    event EtherReceived(address indexed from, uint amount);
    event SpenderAuthorization(address indexed spender, bool authorized);

 
 
 

     
     
     
     
     
     
     
     
    function DelayedPayments(
        uint _absoluteMinTimeLock,
        uint _timeLock,
        uint _maxSecurityGuardDelay) 
    {
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = msg.sender;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

     
    function _error(uint _errorCode, bytes32 _message) internal returns(uint) {
        DelayedPaymentsEmitter(eventsHistory).emitError(_message);
        return _errorCode;
    }

     
    function setupEventsHistory(address _eventsHistory) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }
        if (eventsHistory != 0x0 && eventsHistory != _eventsHistory) {
            return DELAYED_PAYMENTS_INVALID_INVOCATION;
        }
        eventsHistory = _eventsHistory;
        return OK;
    }

 
 
 

     
     
    function numberOfAuthorizedPayments() constant returns (uint) {
        return authorizedPayments.length;
    }

 
 
 

     
     
    function receiveEther() payable {
        EtherReceived(msg.sender, msg.value);
    }

     
     
    function () payable {
        receiveEther();
    }

 
 
 

     
     
     
     
     
     
    function authorizePayment(
        address _recipient,
        uint _amount,
        uint _paymentDelay
    ) returns(uint) {

         
        if (!allowedSpenders[msg.sender]) throw;
        uint idPayment = authorizedPayments.length;        
        authorizedPayments.length++;

         
        Payment p = authorizedPayments[idPayment];
        p.spender = msg.sender;

         
        if (_paymentDelay > 10**18) throw;

         
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                now + _paymentDelay :
                                now + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        PaymentAuthorized(idPayment, p.recipient, p.amount);
        return idPayment;
    }

     
     
     
     
    function collectAuthorizedPayment(uint _idPayment) {

         
        if (_idPayment >= authorizedPayments.length) return;

        Payment p = authorizedPayments[_idPayment];

         
        if (msg.sender != p.recipient) return;
        if (now < p.earliestPayTime) return;
        if (p.canceled) return;
        if (p.paid) return;
        if (this.balance < p.amount) return;

        p.paid = true;  
        if (!p.recipient.send(p.amount)) {   
            return;
        }
        PaymentExecuted(_idPayment, p.recipient, p.amount);
     }

 
 
 

     
     
     
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard {
        if (_idPayment >= authorizedPayments.length) throw;

         
        if (_delay > 10**18) throw;

        Payment p = authorizedPayments[_idPayment];

        if ((p.securityGuardDelay + _delay > maxSecurityGuardDelay) ||
            (p.paid) ||
            (p.canceled))
            throw;

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

 
 
 

     
     
    function cancelPayment(uint _idPayment) onlyContractOwner {
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];


        if (p.canceled) throw;
        if (p.paid) throw;

        p.canceled = true;
        PaymentCanceled(_idPayment);
    }

     
     
     
    function authorizeSpender(address _spender, bool _authorize) onlyContractOwner {
        allowedSpenders[_spender] = _authorize;
        SpenderAuthorization(_spender, _authorize);
    }

     
     
    function setSecurityGuard(address _newSecurityGuard) onlyContractOwner {
        securityGuard = _newSecurityGuard;
    }

     
     
     
     
    function setTimelock(uint _newTimeLock) onlyContractOwner {
        if (_newTimeLock < absoluteMinTimeLock) throw;
        timeLock = _newTimeLock;
    }

     
     
     
     
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyContractOwner {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }
}