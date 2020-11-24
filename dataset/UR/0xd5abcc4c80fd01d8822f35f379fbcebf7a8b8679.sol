 

pragma solidity ^0.4.6;


 

 
 
 
 
 
 
 

 
 
contract Owned {
     
     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

     
    function Owned() { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}
 
 
 
 
contract Escapable is Owned {
    address public escapeCaller;
    address public escapeDestination;

     
     
     
     
     
     
     
     
    function Escapable(address _escapeCaller, address _escapeDestination) {
        escapeDestination = _escapeDestination;
        escapeCaller = _escapeCaller;
    }

     
     
    modifier onlyEscapeCallerOrOwner {
        if ((msg.sender != escapeCaller)&&(msg.sender != owner))
            throw;
        _;
    }

     
     
    function escapeHatch() onlyEscapeCallerOrOwner {
        uint total = this.balance;
         
        if (!escapeDestination.send(total)) {
            throw;
        }
        EscapeCalled(total);
    }
     
     
     
     
     
    function changeEscapeCaller(address _newEscapeCaller) onlyEscapeCallerOrOwner {
        escapeCaller = _newEscapeCaller;
    }

    event EscapeCalled(uint amount);
}

 
 
contract Vault is Escapable {

     
     
     
    struct Payment {
        string description;      
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

     
     
    mapping (address => bool) public allowedSpenders;

     
     
    modifier onlySecurityGuard { if (msg.sender != securityGuard) throw; _; }

     
    event PaymentAuthorized(uint idPayment, address recipient, uint amount);
    event PaymentExecuted(uint idPayment, address recipient, uint amount);
    event PaymentCanceled(uint idPayment);
    event EtherReceived(address from, uint amount);
    event SpenderAuthorization(address spender, bool authorized);

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function Vault(
        address _escapeCaller,
        address _escapeDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay) Escapable(_escapeCaller, _escapeDestination)
    {
        securityGuard = _securityGuard;
        timeLock = _timeLock;
        absoluteMinTimeLock = _absoluteMinTimeLock;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
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
        string _description,
        address _recipient,
        uint _amount,
        uint _paymentDelay
    ) returns(uint) {

         
        if (!allowedSpenders[msg.sender] ) throw;
        uint idPayment = authorizedPayments.length;        
        authorizedPayments.length++;

         
        Payment p = authorizedPayments[idPayment];
        p.spender = msg.sender;

         
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                now + _paymentDelay :
                                now + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        PaymentAuthorized(idPayment, p.recipient, p.amount);
        return idPayment;
    }

     
     
     
     
    function collectAuthorizedPayment(uint _idPayment) {

         
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];

         
        if (msg.sender != p.recipient) throw;
        if (!allowedSpenders[p.spender]) throw;
        if (now < p.earliestPayTime) throw;
        if (p.canceled) throw;
        if (p.paid) throw;
        if (this.balance < p.amount) throw;

        p.paid = true;  
        if (!p.recipient.send(p.amount)) {   
            throw;
        }
        PaymentExecuted(_idPayment, p.recipient, p.amount);
     }

 
 
 

     
     
     
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard {
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];

        if ((p.securityGuardDelay + _delay > maxSecurityGuardDelay) ||
            (p.paid) ||
            (p.canceled))
            throw;

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

 
 
 

     
     
    function cancelPayment(uint _idPayment) onlyOwner {
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];


        if (p.canceled) throw;
        if (p.paid) throw;

        p.canceled = true;
        PaymentCanceled(_idPayment);
    }

     
     
     
    function authorizeSpender(address _spender, bool _authorize) onlyOwner {
        allowedSpenders[_spender] = _authorize;
        SpenderAuthorization(_spender, _authorize);
    }

     
     
    function setSecurityGuard(address _newSecurityGuard) onlyOwner {
        securityGuard = _newSecurityGuard;
    }


     
     
     
     
    function setTimelock(uint _newTimeLock) onlyOwner {
        if (_newTimeLock < absoluteMinTimeLock) throw;
        timeLock = _newTimeLock;
    }

     
     
     
     
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyOwner {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }
}