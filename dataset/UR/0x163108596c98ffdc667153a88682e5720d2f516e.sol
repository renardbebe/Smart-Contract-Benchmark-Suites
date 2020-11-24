 

 
pragma solidity ^0.4.21;

 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract ERC223Interface {
    function transfer(address _to, uint _value) public returns (bool);
}

 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract PhxHell is ERC223ReceivingContract {
    using SafeMath for uint;

    uint public balance;         
    uint public lastFund;        
    address public lastFunder;   
    address phxAddress;          

    uint constant public stakingRequirement = 5e17;    
    uint constant public period = 1 hours;

     
    event GameOver(address indexed winner, uint timestamp, uint value);

     
    function PhxHell(address _phxAddress)
        public {
        phxAddress = _phxAddress;
    }

     
    function payout()
        public {

         
        if (lastFunder == 0)
            return;

         
        if (now.sub(lastFund) < period)
            return;

        uint amount = balance;
        balance = 0;

         
        ERC223Interface phx = ERC223Interface(phxAddress);
        phx.transfer(lastFunder, amount);

         
        GameOver( lastFunder, now, amount );

         
        lastFunder = address(0);
    }

     
    function tokenFallback(address _from, uint _value, bytes)
    public {

         
        require(msg.sender == phxAddress);

         
        require(_value >= stakingRequirement);

         
        payout();

         
        balance = balance.add(_value);
        lastFund = now;
        lastFunder = _from;
    }
}