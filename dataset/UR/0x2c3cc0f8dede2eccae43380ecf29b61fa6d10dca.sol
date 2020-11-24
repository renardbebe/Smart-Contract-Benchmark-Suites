 

pragma solidity ^0.4.6;
 

 
 
 
 
 
 
 
 
 
 
 


 
 

 

 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.6;

contract SafeMath {

     
    function add(uint x, uint y) internal constant returns (uint z) {
        assert( (z = x + y) >= x);
    }
 
     
    function subtract(uint x, uint y) internal constant returns (uint z) {
        assert( (z = x - y) <= x);
    }

     
    function multiply(uint x, uint y) internal constant returns (uint z) {
        z = x * y;
        assert(x == 0 || z / x == y);
        return z;
    }

     
     
    function divide(uint x, uint y) internal constant returns (uint z) {
        z = x / y;
        assert(x == ( (y * z) + (x % y) ));
        return z;
    }
    
     
    function min64(uint64 x, uint64 y) internal constant returns (uint64) {
      return x < y ? x: y;
    }
    
     
    function max64(uint64 x, uint64 y) internal constant returns (uint64) {
      return x >= y ? x : y;
    }

     
    function min(uint x, uint y) internal constant returns (uint) {
        return (x <= y) ? x : y;
    }

     
    function max(uint x, uint y) internal constant returns (uint) {
        return (x >= y) ? x : y;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

}

contract Owned {
     
     
     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

     
    function Owned() { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }
    
     
     
    event NewOwner(address indexed oldOwner, address indexed newOwner);
}
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;

     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        if ((msg.sender != escapeHatchCaller)&&(msg.sender != owner))
            throw;
        _;
    }

     
     
    function escapeHatch() onlyEscapeHatchCallerOrOwner {
        uint total = this.balance;
         
        if (!escapeHatchDestination.send(total)) {
            throw;
        }
        EscapeHatchCalled(total);
    }
     
     
     
     
     
    function changeEscapeCaller(address _newEscapeHatchCaller) onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchCalled(uint amount);
}

 
 
contract Campaign {

     
     
     
    function proxyPayment(address _owner) payable returns(bool);
}

 
contract DonationDoubler is Escapable, SafeMath {
    Campaign public beneficiary;  

     
     
     
     
     
     
     
     
     
     
     
    function DonationDoubler(
            Campaign _beneficiary,
             
            address _escapeHatchCaller,
            address _escapeHatchDestination
        )
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {
        beneficiary = _beneficiary;
    }

     
    function depositETH() payable {
        DonationDeposited4Doubling(msg.sender, msg.value);
    }

     
     
     
    function () payable {
        uint amount;

         
        if (this.balance >= multiply(msg.value, 2)){
            amount = multiply(msg.value, 2);  
             
            if (!beneficiary.proxyPayment.value(amount)(msg.sender))
                throw;
            DonationDoubled(msg.sender, amount);
        } else {
            amount = this.balance;
             
            if (!beneficiary.proxyPayment.value(amount)(msg.sender))
                throw;
            DonationSentButNotDoubled(msg.sender, amount);
        }
    }

    event DonationDeposited4Doubling(address indexed sender, uint amount);
    event DonationDoubled(address indexed sender, uint amount);
    event DonationSentButNotDoubled(address indexed sender, uint amount);
}