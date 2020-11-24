 

pragma solidity ^0.4.19;

contract Cthulooo {
    using SafeMath for uint256;
    
    
     
       
    uint public constant WIN_CUTOFF = 10;
    
     
    uint public constant MIN_BID = 0.000001 ether; 
    
     
    uint public constant DURATION = 60000 hours;
    
     
    
     
    address[] public betAddressArray;
    
     
    uint public pot;
    
    
    uint public deadline;
    
     
    uint public index;
    
     
    bool public gameIsOver;
    
    function Cthulooo() public payable {
        require(msg.value >= MIN_BID);
        betAddressArray = new address[](WIN_CUTOFF);
        index = 0;
        pot = 0;
        gameIsOver = false;
        deadline = computeDeadline();
        newBet();
       
    }

    
    function win() public {
        require(now > deadline);
        uint amount = pot.div(WIN_CUTOFF);
        address sendTo;
        for (uint i = 0; i < WIN_CUTOFF; i++) {
            sendTo = betAddressArray[i];
            sendTo.transfer(amount);
            pot = pot.sub(amount);
        }
        gameIsOver = true;
    }
    
    function newBet() public payable {
        require(msg.value >= MIN_BID && !gameIsOver && now <= deadline);
        pot = pot.add(msg.value);
        betAddressArray[index] = msg.sender;
        index = (index + 1) % WIN_CUTOFF;
        deadline = computeDeadline();
    }
    
    function computeDeadline() internal view returns (uint) {
        return now.add(DURATION);
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}