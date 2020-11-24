 

pragma solidity ^0.4.18;


 
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
 
     
    bool public gameStarted;
    
     
    address public gameStarter;
    
     
    address public lastPlayer;
    
     
    uint256 public lastPlayTimestamp;

     
    uint256 public timeout = 120;
    
     
    uint256 public wagerIndex = 0;
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
    
     
    uint256 public gameStarterDividendPercentage = 1000;
    
     
    uint256 public price = 0.005 ether;
    
     
    uint256 public prizePool;
    
     
    uint256 public wagerPool;
    
     
     
     
     
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
    function ChronosCore(uint256 _price, uint256 _timeout) public {
        price = _price;
        timeout = _timeout;
    }
    
    event Start(address indexed starter, uint256 timestamp);
    event End(address indexed winner, uint256 timestamp, uint256 prize);
    event Play(address indexed player, uint256 timestamp, uint256 timeoutTimestamp, uint256 wagerIndex, uint256 newPrizePool);
    
     
     
    function play(bool startNewGameIfIdle) external payable {
         
        _processGameEnd();
        
         
        require(msg.value >= price);
        
        if (!gameStarted) {
             
            require(!paused);
            
             
             
            require(startNewGameIfIdle);
            
             
            gameStarted = true;
            
             
            gameStarter = msg.sender;
            
             
            Start(msg.sender, block.timestamp);
        }
        
         
        uint256 fee = price.mul(feePercentage).div(100000);
        uint256 dividend = price.mul(gameStarterDividendPercentage).div(100000);
        uint256 wagerPoolPart = price.mul(2).div(7);
        
         
        lastPlayer = msg.sender;
        lastPlayTimestamp = block.timestamp;
        prizePool = prizePool.add(price.sub(fee).sub(dividend).sub(wagerPoolPart));
        
         
        Play(msg.sender, block.timestamp, block.timestamp + timeout, wagerIndex, prizePool);
        
         
        _sendFunds(gameStarter, dividend);
        
         
        if (wagerIndex > 0 && (wagerIndex % 7) == 0) {
             
            msg.sender.transfer(wagerPool);
            
             
            wagerPool = 0;
        }
        
         
        wagerPool = wagerPool.add(wagerPoolPart);
        
         
        wagerIndex = wagerIndex.add(1);
        
         
         
         
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
     
    function endGame() external {
        require(_processGameEnd());
    }
    
     
    function _processGameEnd() internal returns(bool) {
        if (!gameStarted) {
             
            return false;
        }
    
        if (block.timestamp <= lastPlayTimestamp + timeout) {
             
            return false;
        }
        
         
        _sendFunds(lastPlayer, prizePool);
        
         
        End(lastPlayer, lastPlayTimestamp, prizePool);
        
         
        gameStarted = false;
        gameStarter = 0x0;
        lastPlayer = 0x0;
        lastPlayTimestamp = 0;
        wagerIndex = 0;
        prizePool = 0;
        wagerPool = 0;
        
         
        return true;
    }
}