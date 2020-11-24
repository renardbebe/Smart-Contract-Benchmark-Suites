 

pragma solidity ^0.4.19;


 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract Pausable is Ownable {
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
contract ChronosAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    function ChronosAccessControl() public {
         
        cfoAddress = msg.sender;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
     
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}


 
contract ChronosBase is ChronosAccessControl {
    using SafeMath for uint256;
    
     
     
    uint256[] public activeTimesFrom;
    uint256[] public activeTimesTo;
    
     
    bool public allowStart;
    
     
    bool public gameStarted;
    
     
    address public lastPlayer;
    
     
    uint256 public lastWagerTimeoutTimestamp;

     
    uint256 public timeout;
    
     
     
    uint256 public nextTimeout;
    
     
    uint256 public finalTimeout;
    
     
     
    uint256 public nextFinalTimeout;
    
     
     
    uint256 public numberOfWagersToFinalTimeout;
    
     
     
    uint256 public nextNumberOfWagersToFinalTimeout;
    
     
    uint256 public gameIndex = 0;
    
     
    uint256 public wagerIndex = 0;
    
     
    uint256 public nthWagerPrizeN = 3;
    
     
     
    function canStart() public view returns (bool) {
         
         
         
         
         
         
        uint256 timeOfWeek = (block.timestamp - 345600) % 604800;
        
        uint256 windows = activeTimesFrom.length;
        
        if (windows == 0) {
             
            return true;
        }
        
        for (uint256 i = 0; i < windows; i++) {
            if (timeOfWeek >= activeTimesFrom[i] && timeOfWeek <= activeTimesTo[i]) {
                return true;
            }
        }
        
        return false;
    }
    
     
    function calculateTimeout() public view returns(uint256) {
        if (wagerIndex >= numberOfWagersToFinalTimeout || numberOfWagersToFinalTimeout == 0) {
            return finalTimeout;
        } else {
            if (finalTimeout <= timeout) {
                 
            
                 
                 
                uint256 difference = timeout - finalTimeout;
                
                 
                uint256 decrease = difference.mul(wagerIndex).div(numberOfWagersToFinalTimeout);
                
                 
                return (timeout - decrease);
            } else {
                 
            
                 
                 
                difference = finalTimeout - timeout;
                
                 
                uint256 increase = difference.mul(wagerIndex).div(numberOfWagersToFinalTimeout);
                
                 
                return (timeout + increase);
            }
        }
    }
}


 
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


 
contract ChronosFinance is ChronosBase, PullPayment {
     
    uint256 public feePercentage = 2500;
    
     
    uint256 public nextPoolPercentage = 7500;
    
     
    uint256 public price;
    
     
    uint256 public nextPrice;
    
     
    uint256 public prizePool;
    
     
    uint256 public nextPrizePool;
    
     
    uint256 public wagerPool;
    
     
     
    function setFeePercentage(uint256 _feePercentage) external onlyCFO {
         
        require(_feePercentage <= 4000);
        
        feePercentage = _feePercentage;
    }
    
     
     
    function setNextPoolPercentage(uint256 _nextPoolPercentage) external onlyCFO {
        nextPoolPercentage = _nextPoolPercentage;
    }
    
     
     
     
     
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
             
             
             
             
             
            asyncSend(beneficiary, amount);
        }
    }
    
     
    function withdrawFreeBalance() external onlyCFO {
         
        uint256 freeBalance = this.balance.sub(totalPayments).sub(prizePool).sub(wagerPool);
        
        cfoAddress.transfer(freeBalance);
    }
}


 
contract ChronosCore is ChronosFinance {
    
    function ChronosCore(uint256 _price, uint256 _timeout, uint256 _finalTimeout, uint256 _numberOfWagersToFinalTimeout) public {
        nextPrice = _price;
        nextTimeout = _timeout;
        nextFinalTimeout = _finalTimeout;
        nextNumberOfWagersToFinalTimeout = _numberOfWagersToFinalTimeout;
        NextGame(nextPrice, nextTimeout, nextFinalTimeout, nextNumberOfWagersToFinalTimeout);
    }
    
    event ActiveTimes(uint256[] from, uint256[] to);
    event AllowStart(bool allowStart);
    event NextGame(uint256 price, uint256 timeout, uint256 finalTimeout, uint256 numberOfWagersToFinalTimeout);
    event Start(uint256 indexed gameIndex, address indexed starter, uint256 timestamp, uint256 price, uint256 timeout, uint256 finalTimeout, uint256 numberOfWagersToFinalTimeout);
    event End(uint256 indexed gameIndex, uint256 wagerIndex, address indexed winner, uint256 timestamp, uint256 prize, uint256 nextPrizePool);
    event Play(uint256 indexed gameIndex, uint256 indexed wagerIndex, address indexed player, uint256 timestamp, uint256 timeoutTimestamp, uint256 newPrizePool, uint256 nextPrizePool);
    event SpiceUpPrizePool(uint256 indexed gameIndex, address indexed spicer, uint256 spiceAdded, string message, uint256 newPrizePool);
    
     
     
     
    function play(uint256 _gameIndex, bool startNewGameIfIdle) external payable {
         
        _processGameEnd();
        
        if (!gameStarted) {
             
            require(!paused);
            
            if (allowStart) {
                 
                allowStart = false;
            } else {
                 
                require(canStart());
            }
            
             
             
            require(startNewGameIfIdle);
            
             
            price = nextPrice;
            timeout = nextTimeout;
            finalTimeout = nextFinalTimeout;
            numberOfWagersToFinalTimeout = nextNumberOfWagersToFinalTimeout;
            
             
            gameStarted = true;
            
             
            Start(gameIndex, msg.sender, block.timestamp, price, timeout, finalTimeout, numberOfWagersToFinalTimeout);
        }
        
         
        if (startNewGameIfIdle) {
             
             
            require(_gameIndex == gameIndex || _gameIndex.add(1) == gameIndex);
        } else {
             
            require(_gameIndex == gameIndex);
        }
        
         
        require(msg.value >= price);
        
         
        uint256 fee = price.mul(feePercentage).div(100000);
        uint256 nextPool = price.mul(nextPoolPercentage).div(100000);
        uint256 wagerPoolPart;
        
        if (wagerIndex % nthWagerPrizeN == nthWagerPrizeN - 1) {
             
            
             
            uint256 wagerPrize = price.mul(2);
            
             
            wagerPoolPart = wagerPrize.sub(wagerPool);
        
             
            msg.sender.transfer(wagerPrize);
            
             
            wagerPool = 0;
        } else {
             
            
             
            wagerPoolPart = price.mul(2).div(nthWagerPrizeN);
            
             
            wagerPool = wagerPool.add(wagerPoolPart);
        }
        
         
        uint256 currentTimeout = calculateTimeout();
        
         
        lastPlayer = msg.sender;
        lastWagerTimeoutTimestamp = block.timestamp + currentTimeout;
        prizePool = prizePool.add(price.sub(fee).sub(nextPool).sub(wagerPoolPart));
        nextPrizePool = nextPrizePool.add(nextPool);
        
         
        Play(gameIndex, wagerIndex, msg.sender, block.timestamp, lastWagerTimeoutTimestamp, prizePool, nextPrizePool);
        
         
        wagerIndex++;
        
         
         
         
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
     
     
     
    function spiceUp(uint256 _gameIndex, string message) external payable {
         
        _processGameEnd();
        
         
        require(_gameIndex == gameIndex);
    
         
        require(gameStarted || !paused);
        
         
        require(msg.value > 0);
        
         
        prizePool = prizePool.add(msg.value);
        
         
        SpiceUpPrizePool(gameIndex, msg.sender, msg.value, message, prizePool);
    }
    
     
     
     
     
     
     
     
    function setNextGame(uint256 _price, uint256 _timeout, uint256 _finalTimeout, uint256 _numberOfWagersToFinalTimeout) external onlyCFO {
        nextPrice = _price;
        nextTimeout = _timeout;
        nextFinalTimeout = _finalTimeout;
        nextNumberOfWagersToFinalTimeout = _numberOfWagersToFinalTimeout;
        NextGame(nextPrice, nextTimeout, nextFinalTimeout, nextNumberOfWagersToFinalTimeout);
    } 
    
     
    function endGame() external {
        require(_processGameEnd());
    }
    
     
    function _processGameEnd() internal returns(bool) {
        if (!gameStarted) {
             
            return false;
        }
    
        if (block.timestamp <= lastWagerTimeoutTimestamp) {
             
            return false;
        }
        
         
         
        uint256 prize = prizePool.add(wagerPool);
        
         
        _sendFunds(lastPlayer, prize);
        
         
        End(gameIndex, wagerIndex, lastPlayer, lastWagerTimeoutTimestamp, prize, nextPrizePool);
        
         
        gameStarted = false;
        lastPlayer = 0x0;
        lastWagerTimeoutTimestamp = 0;
        wagerIndex = 0;
        wagerPool = 0;
        
         
        prizePool = nextPrizePool;
        nextPrizePool = 0;
        
         
        gameIndex++;
        
         
        return true;
    }
    
     
    function setActiveTimes(uint256[] _from, uint256[] _to) external onlyCFO {
        require(_from.length == _to.length);
    
        activeTimesFrom = _from;
        activeTimesTo = _to;
        
         
        ActiveTimes(_from, _to);
    }
    
     
    function setAllowStart(bool _allowStart) external onlyCFO {
        allowStart = _allowStart;
        
         
        AllowStart(_allowStart);
    }
}