 

pragma solidity ^0.4.19;

contract EthereumHole {
    using SafeMath for uint256;


    event NewLeader(
        uint _timestamp,
        address _address,
        uint _newPot,
        uint _newDeadline
    );


    event Winner(
        uint _timestamp,
        address _address,
        uint _earnings,
        uint _deadline
    );


     
    uint public constant BASE_DURATION = 600000 minutes;

     
    uint public constant DURATION_DECREASE_PER_ETHER = 5 minutes;

     
    uint public constant MINIMUM_DURATION = 5 minutes;
    
      
    uint public constant min_bid = 10000000000000 wei;

     
    uint public pot;

     
    address public leader;

     
    uint public deadline;
    
     
    bool public gameIsOver;

    function EthereumHole() public payable {
        require(msg.value > 0);
        gameIsOver = false;
        pot = msg.value;
        leader = msg.sender;
        deadline = computeDeadline();
        NewLeader(now, leader, pot, deadline);
    }

    function computeDeadline() internal view returns (uint) {
        uint _durationDecrease = DURATION_DECREASE_PER_ETHER.mul(pot.div(1 ether));
        uint _duration;
        if (MINIMUM_DURATION.add(_durationDecrease) > BASE_DURATION) {
            _duration = MINIMUM_DURATION;
        } else {
            _duration = BASE_DURATION.sub(_durationDecrease);
        }
        return now.add(_duration);
    }

    modifier endGameIfNeeded {
        if (now > deadline && !gameIsOver) {
            Winner(now, leader, pot, deadline);
            leader.transfer(pot);
            gameIsOver = true;
        }
        _;
    }

    function bid() public payable endGameIfNeeded {
        if (msg.value > 0 && !gameIsOver) {
            pot = pot.add(msg.value);
            if (msg.value >= min_bid) {
                leader = msg.sender;
                deadline = computeDeadline();
                NewLeader(now, leader, pot, deadline);
            }
        }
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