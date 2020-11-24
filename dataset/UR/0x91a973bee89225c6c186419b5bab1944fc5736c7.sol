 

 
pragma solidity ^0.4.15;


 
 
 
 
 
 
 
 
 
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

 
pragma solidity ^0.4.15;


 
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

 
pragma solidity ^0.4.15;
 





 
 
 
 
 
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

     
     
     
     
    function isTokenEscapable(address _token) constant public returns (bool) {
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

 
pragma solidity ^0.4.11;

 

 
 

 
 
 
 
 
 


 
 
contract LiquidPledging {
    function confirmPayment(uint64 idPledge, uint amount) public;
    function cancelPayment(uint64 idPledge, uint amount) public;
}


 
 
contract LPVault is Escapable {

    LiquidPledging public liquidPledging;  
    bool public autoPay;  

    enum PaymentStatus {
        Pending,  
        Paid,     
        Canceled  
    }
     
     
     
    struct Payment {
        PaymentStatus state;  
        bytes32 ref;  
        address dest;  
        uint amount;  
    }

     
    Payment[] public payments;

    function LPVault(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
    }

     
     
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }

     
     
    function () public payable {}

     
     
     
     
    function setLiquidPledging(address _newLiquidPledging) public onlyOwner {
        require(address(liquidPledging) == 0x0);
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

     
     
     
     
     
    function setAutopay(bool _automatic) public onlyOwner {
        autoPay = _automatic;
        AutoPaySet();
    }

     
     
     
     
     
     
     
     
    function authorizePayment(
        bytes32 _ref,
        address _dest,
        uint _amount
    ) public onlyLiquidPledging returns (uint)
    {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentStatus.Pending;
        payments[idPayment].ref = _ref;
        payments[idPayment].dest = _dest;
        payments[idPayment].amount = _amount;

        AuthorizePayment(idPayment, _ref, _dest, _amount);

        if (autoPay) {
            doConfirmPayment(idPayment);
        }

        return idPayment;
    }

     
     
     
     
     
    function confirmPayment(uint _idPayment) public onlyOwner {
        doConfirmPayment(_idPayment);
    }

     
     
     
    function doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        p.dest.transfer(p.amount);   

        ConfirmPayment(_idPayment, p.ref);
    }

     
     
     
    function cancelPayment(uint _idPayment) public onlyOwner {
        doCancelPayment(_idPayment);
    }

     
     
    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment, p.ref);

    }

     
     
    function multiConfirm(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doConfirmPayment(_idPayments[i]);
        }
    }

     
     
    function multiCancel(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doCancelPayment(_idPayments[i]);
        }
    }

     
    function nPayments() constant public returns (uint) {
        return payments.length;
    }

     
     
     
     
     
    function escapeFunds(address _token, uint _amount) public onlyOwner {
         
        if (_token == 0x0) {
            require(this.balance >= _amount);
            escapeHatchDestination.transfer(_amount);
            EscapeHatchCalled(_token, _amount);
            return;
        }
         
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        require(balance >= _amount);
        require(token.transfer(escapeHatchDestination, _amount));
        EscapeFundsCalled(_token, _amount);
    }

    event AutoPaySet();
    event EscapeFundsCalled(address token, uint amount);
    event ConfirmPayment(uint indexed idPayment, bytes32 indexed ref);
    event CancelPayment(uint indexed idPayment, bytes32 indexed ref);
    event AuthorizePayment(
        uint indexed idPayment,
        bytes32 indexed ref,
        address indexed dest,
        uint amount
        );
}