 

pragma solidity ^0.4.18;

contract FullERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  uint256 public totalSupply;
  uint8 public decimals;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract BalanceHistoryToken is FullERC20 {
  function balanceOfAtBlock(address who, uint256 blockNumber) public view returns (uint256);
}

library Math {
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

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract ProfitSharingV2 is Ownable, Destructible, Pausable {
    using SafeMath for uint256;

    struct Period {
        uint128 endTime;
        uint128 block;
        uint128 balance;
    }

     
    BalanceHistoryToken public token;
    uint256 public periodDuration;
    Period public currentPeriod;
    mapping(address => mapping(uint => bool)) public payments;

     

     
    event PaymentCompleted(address indexed requester, uint indexed paymentPeriodBlock, uint amount);
    event PeriodReset(uint block, uint endTime, uint balance, uint totalSupply);

     
    function ProfitSharingV2(address _tokenAddress) public {
        periodDuration = 4 weeks;
        resetPeriod();
        token = BalanceHistoryToken(_tokenAddress);
    }

     
    function () public payable {
    }

     
    function withdraw() public whenNotPaused {
        withdrawFor(msg.sender);
    }

     
     
    function withdrawFor(address tokenOwner) public whenNotPaused {
         
        require(!payments[tokenOwner][currentPeriod.block]);
        
         
        resetPeriod();

         
        uint payment = getPaymentTotal(tokenOwner);
        require(payment > 0);
        assert(this.balance >= payment);

        payments[tokenOwner][currentPeriod.block] = true;
        PaymentCompleted(tokenOwner, currentPeriod.block, payment);
        tokenOwner.transfer(payment);
    }

     
    function resetPeriod() public {
        uint nowTime = getNow();
        if (currentPeriod.endTime < nowTime) {
            currentPeriod.endTime = uint128(nowTime.add(periodDuration)); 
            currentPeriod.block = uint128(block.number);
            currentPeriod.balance = uint128(this.balance);
            if (token != address(0x0)) {
                PeriodReset(block.number, nowTime.add(periodDuration), this.balance, token.totalSupply());
            }
        }
    }

     
    function getPaymentTotal(address tokenOwner) public constant returns (uint256) {
        if (payments[tokenOwner][currentPeriod.block]) {
            return 0;
        }

        uint nowTime = getNow();
        uint tokenOwnerBalance = currentPeriod.endTime < nowTime ?  
             
             
             
            token.balanceOfAtBlock(tokenOwner, block.number) :
             
            token.balanceOfAtBlock(tokenOwner, currentPeriod.block);
            
         
        return calculatePayment(tokenOwnerBalance);
    }

    function isPaymentCompleted(address tokenOwner) public constant returns (bool) {
        return payments[tokenOwner][currentPeriod.block];
    }

     
    function updateToken(address tokenAddress) public onlyOwner {
        token = BalanceHistoryToken(tokenAddress);
    }

     
    function calculatePayment(uint tokenOwnerBalance) public constant returns(uint) {
        return tokenOwnerBalance.mul(currentPeriod.balance).div(token.totalSupply());
    }

     
    function getNow() internal view returns (uint256) {
        return now;
    }

     
    function updatePeriodDuration(uint newPeriodDuration) public onlyOwner {
        require(newPeriodDuration > 0);
        periodDuration = newPeriodDuration;
    }

     
    function forceResetPeriod() public onlyOwner {
        uint nowTime = getNow();
        currentPeriod.endTime = uint128(nowTime.add(periodDuration)); 
        currentPeriod.block = uint128(block.number);
        currentPeriod.balance = uint128(this.balance);
        if (token != address(0x0)) {
            PeriodReset(block.number, nowTime.add(periodDuration), this.balance, token.totalSupply());
        }
    }
}