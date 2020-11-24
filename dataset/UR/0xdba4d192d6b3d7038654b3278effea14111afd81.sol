 

pragma solidity 0.4.23;

 
 

 
 
 
 

 
contract RandoLotto {
    using SafeMath for uint256;
    
    event NewLeader(address newLeader, uint256 highScore);
    event BidAttempt(uint256 randomNumber, uint256 highScore);
    event NewRound(uint256 payout, uint256 highScore);
    
    address public currentWinner;
    
    uint256 public highScore;
    uint256 public lastTimestamp;
    
    address internal dev;
    
    Random randomContract;
    
    modifier GTFOSmartContractHackerz {
        require(msg.sender == tx.origin);
        _;    
    }
    
    constructor () public payable {
        dev = msg.sender;
        highScore = 0;
        currentWinner = msg.sender;
        lastTimestamp = now;
        randomContract = new Random();
    }
    
    function () public payable GTFOSmartContractHackerz {
        require(msg.value >= 0.001 ether);
        
        if (now > lastTimestamp + 1 days) { sendWinnings(); }
    
         
        uint256 randomNumber = randomContract.random(10000000000000000000);
        
        if (randomNumber > highScore) {
            highScore = randomNumber;
            currentWinner = msg.sender;
            lastTimestamp = now;
            
            emit NewLeader(msg.sender, highScore);
        }
        
        emit BidAttempt(randomNumber, highScore);
    }
    
    function sendWinnings() public {
        require(now > lastTimestamp + 1 days);
        
        uint256 toWinner;
        uint256 toDev;
        
        if (address(this).balance > 0) {
            uint256 totalPot = address(this).balance;
            
            toDev = totalPot.div(100);
            toWinner = totalPot.sub(toDev);
         
            dev.transfer(toDev);
            currentWinner.transfer(toWinner);
        }
        
        highScore = 0;
        currentWinner = msg.sender;
        lastTimestamp = now;
        
        emit NewRound(toWinner, highScore);
    }
}

contract Random {
  uint256 _seed;

   
  function bitSlice(uint256 n, uint256 bits, uint256 slot) public pure returns(uint256) {
      uint256 offset = slot * bits;
       
      uint256 mask = uint256((2**bits) - 1) << offset;
       
      return uint256((n & mask) >> offset);
  }

  function maxRandom() public returns (uint256 randomNumber) {
    _seed = uint256(keccak256(
        _seed,
        blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
    ));
    return _seed;
  }

   
  function random(uint256 upper) public returns (uint256 randomNumber) {
    return maxRandom() % upper;
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