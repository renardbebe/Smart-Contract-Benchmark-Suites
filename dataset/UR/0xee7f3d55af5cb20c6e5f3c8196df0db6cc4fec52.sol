 

 

pragma solidity ^0.4.19;


 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


 

pragma solidity ^0.4.19;


 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    function Owned() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 


 

pragma solidity ^0.4.19;
 





 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}


 

pragma solidity ^0.4.21;



 
contract Pausable is Owned {
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

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 

pragma solidity ^0.4.21;

 

 
 
 
 
 
 
 




 
 
contract Vault is Escapable, Pausable {

     
     
     
    struct Payment {
        string name;               
        bytes32 reference;         
        address spender;           
        uint earliestPayTime;      
        bool canceled;             
        bool paid;                 
        address recipient;         
        address token;             
        uint amount;               
        uint securityGuardDelay;   
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;
    bool public allowDisbursePaymentWhenPaused;

     
     
    mapping (address => bool) public allowedSpenders;

     
    event PaymentAuthorized(uint indexed idPayment, address indexed recipient, uint amount, address token, bytes32 reference);
    event PaymentExecuted(uint indexed idPayment, address indexed recipient, uint amount, address token);
    event PaymentCanceled(uint indexed idPayment);
    event SpenderAuthorization(address indexed spender, bool authorized);

     
     
    modifier onlySecurityGuard { 
        require(msg.sender == securityGuard);
        _;
    }

     
     
     
    modifier disbursementsAllowed {
        require(!paused || allowDisbursePaymentWhenPaused);
        _;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function Vault(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = _securityGuard;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

 
 
 

     
     
    function numberOfAuthorizedPayments() public view returns (uint) {
        return authorizedPayments.length;
    }

 
 
 

     
     
     
     
     
     
     
     
    function authorizePayment(
        string _name,
        bytes32 _reference,
        address _recipient,
        address _token,
        uint _amount,
        uint _paymentDelay
    ) whenNotPaused external returns(uint) {

         
        require(allowedSpenders[msg.sender]);
        uint idPayment = authorizedPayments.length;        
        authorizedPayments.length++;

         
        Payment storage p = authorizedPayments[idPayment];
        p.spender = msg.sender;

         
        require(_paymentDelay <= 10**18);

         
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                _getTime() + _paymentDelay :
                                _getTime() + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        p.name = _name;
        p.reference = _reference;
        p.token = _token;
        emit PaymentAuthorized(idPayment, p.recipient, p.amount, p.token, p.reference);
        return idPayment;
    }

     
     
     
    function disburseAuthorizedPayment(uint _idPayment) disbursementsAllowed public {
         
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];

         
        require(allowedSpenders[p.spender]);
        require(_getTime() >= p.earliestPayTime);
        require(!p.canceled);
        require(!p.paid);

        p.paid = true;  

         
        if (p.token == 0) {
            p.recipient.transfer(p.amount);
        } else {
            require(ERC20(p.token).transfer(p.recipient, p.amount));
        }

        emit PaymentExecuted(_idPayment, p.recipient, p.amount, p.token);
    }

     
    function disburseAuthorizedPayments(uint[] _idPayments) public {
        for (uint i = 0; i < _idPayments.length; i++) {
            uint _idPayment = _idPayments[i];
            disburseAuthorizedPayment(_idPayment);
        }
    }

 
 
 

     
     
     
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard external {
        require(_idPayment < authorizedPayments.length);

         
        require(_delay <= 10**18);

        Payment storage p = authorizedPayments[_idPayment];

        require(p.securityGuardDelay + _delay <= maxSecurityGuardDelay);
        require(!p.paid);
        require(!p.canceled);

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

 
 
 

     
     
    function cancelPayment(uint _idPayment) onlyOwner external {
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];

        require(!p.canceled);
        require(!p.paid);

        p.canceled = true;
        emit PaymentCanceled(_idPayment);
    }

     
     
     
    function authorizeSpender(address _spender, bool _authorize) onlyOwner external {
        allowedSpenders[_spender] = _authorize;
        emit SpenderAuthorization(_spender, _authorize);
    }

     
     
    function setSecurityGuard(address _newSecurityGuard) onlyOwner external {
        securityGuard = _newSecurityGuard;
    }

     
     
     
     
    function setTimelock(uint _newTimeLock) onlyOwner external {
        require(_newTimeLock >= absoluteMinTimeLock);
        timeLock = _newTimeLock;
    }

     
     
     
     
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyOwner external {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

     
     
    function pause() onlyOwner whenNotPaused public {
        allowDisbursePaymentWhenPaused = false;
        super.pause();
    }

     
     
     
     
    function setAllowDisbursePaymentWhenPaused(bool allowed) onlyOwner whenPaused public {
        allowDisbursePaymentWhenPaused = allowed;
    }

     
    function _getTime() internal view returns (uint) {
        return now;
    }

}

 

pragma solidity ^0.4.21;

 



 
contract FailClosedVault is Vault {
    uint public securityGuardLastCheckin;

     
    function FailClosedVault(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) Vault(
        _escapeHatchCaller,
        _escapeHatchDestination, 
        _absoluteMinTimeLock,
        _timeLock,
        _securityGuard,
        _maxSecurityGuardDelay
    ) public {
    }

 
 
 

     
    function disburseAuthorizedPayment(uint _idPayment) disbursementsAllowed public {
         
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];
         
         
         
         
         
        require(securityGuardLastCheckin >= p.earliestPayTime - timeLock + 30 minutes);

        super.disburseAuthorizedPayment(_idPayment);
    }

 
 
 

     
    function checkIn() onlySecurityGuard external {
        securityGuardLastCheckin = _getTime();
    }
}

 

pragma solidity ^0.4.21;

 





 
contract GivethBridge is FailClosedVault {

    mapping(address => bool) tokenWhitelist;

    event Donate(uint64 giverId, uint64 receiverId, address token, uint amount);
    event DonateAndCreateGiver(address giver, uint64 receiverId, address token, uint amount);
    event EscapeFundsCalled(address token, uint amount);

     

     
    function GivethBridge(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) FailClosedVault(
        _escapeHatchCaller,
        _escapeHatchDestination,
        _absoluteMinTimeLock,
        _timeLock,
        _securityGuard,
        _maxSecurityGuardDelay
    ) public
    {
        tokenWhitelist[0] = true;  
    }

     

     
    function donateAndCreateGiver(address giver, uint64 receiverId) payable external {
        donateAndCreateGiver(giver, receiverId, 0, 0);
    }

     
    function donateAndCreateGiver(address giver, uint64 receiverId, address token, uint _amount) whenNotPaused payable public {
        require(giver != 0);
        require(receiverId != 0);
        uint amount = _receiveDonation(token, _amount);
        emit DonateAndCreateGiver(giver, receiverId, token, amount);
    }

     
    function donate(uint64 giverId, uint64 receiverId) payable external {
        donate(giverId, receiverId, 0, 0);
    }

     
    function donate(uint64 giverId, uint64 receiverId, address token, uint _amount) whenNotPaused payable public {
        require(giverId != 0);
        require(receiverId != 0);
        uint amount = _receiveDonation(token, _amount);
        emit Donate(giverId, receiverId, token, amount);
    }

     
    function whitelistToken(address token, bool accepted) whenNotPaused onlyOwner external {
        tokenWhitelist[token] = accepted;
    }

     
    function escapeFunds(address _token, uint _amount) external onlyEscapeHatchCallerOrOwner {
         
        if (_token == 0) {
            escapeHatchDestination.transfer(_amount);
         
        } else {
            ERC20 token = ERC20(_token);
            require(token.transfer(escapeHatchDestination, _amount));
        }
        emit EscapeFundsCalled(_token, _amount);
    }

     

     
    function _receiveDonation(address token, uint _amount) internal returns(uint amount) {
        require(tokenWhitelist[token]);
        amount = _amount;

         
        if (token == 0) {
            amount = msg.value;
        }

        require(amount > 0);

        if (token != 0) {
            require(ERC20(token).transferFrom(msg.sender, this, amount));
        }
    }
}