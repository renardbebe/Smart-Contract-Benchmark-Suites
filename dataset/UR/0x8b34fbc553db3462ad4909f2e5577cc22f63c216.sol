 

 
pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
 
 
contract LRCMidTermHoldingContract {
    using SafeMath for uint;
    using Math for uint;

     
     
    uint public constant DEPOSIT_WINDOW                 = 60 days;

     
     
     
     
    uint public constant WITHDRAWAL_DELAY               = 180 days;
    uint public constant WITHDRAWAL_WINDOW              = 90  days;

    uint public constant MAX_LRC_DEPOSIT_PER_ADDRESS    = 150000 ether;  

     
    uint public constant RATE       = 7500;

    address public lrcTokenAddress  = 0x0;
    address public owner            = 0x0;

     
    uint public lrcReceived         = 0;
    uint public lrcSent             = 0;
    uint public ethReceived         = 0;
    uint public ethSent             = 0;

    uint public depositStartTime    = 0;
    uint public depositStopTime     = 0;

    bool public closed              = false;

    struct Record {
        uint lrcAmount;
        uint timestamp;
    }

    mapping (address => Record) records;

     
     
    event Started(uint _time);

     
    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _ethAmount, uint _lrcAmount);

     
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _ethAmount, uint _lrcAmount);

     
    event Closed(uint _ethAmount, uint _lrcAmount);

     
    event Drained(uint _ethAmount);

     
     
     
     
    function LRCMidTermHoldingContract(address _lrcTokenAddress, address _owner) {
        require(_lrcTokenAddress != address(0));
        require(_owner != address(0));

        lrcTokenAddress = _lrcTokenAddress;
        owner = _owner;
    }

     

     
     
    function drain(uint ethAmount) public payable {
        require(!closed);
        require(msg.sender == owner);

        uint amount = ethAmount.min256(this.balance);
        require(amount > 0);
        owner.transfer(amount);

        Drained(amount);
    }

     
    function start() public {
        require(msg.sender == owner);
        require(depositStartTime == 0);

        depositStartTime = now;
        depositStopTime  = now + DEPOSIT_WINDOW;

        Started(depositStartTime);
    }

     
    function close() public payable {
        require(!closed);
        require(msg.sender == owner);
        require(now > depositStopTime + WITHDRAWAL_DELAY + WITHDRAWAL_WINDOW);

        uint ethAmount = this.balance;
        if (ethAmount > 0) {
            owner.transfer(ethAmount);
        }

        var lrcToken = Token(lrcTokenAddress);
        uint lrcAmount = lrcToken.balanceOf(address(this));
        if (lrcAmount > 0) {
            require(lrcToken.transfer(owner, lrcAmount));
        }

        closed = true;
        Closed(ethAmount, lrcAmount);
    }

     
    function () payable {
        require(!closed);

        if (msg.sender != owner) {
            if (now <= depositStopTime) depositLRC();
            else withdrawLRC();
        }
    }


     
     
     
    function depositLRC() payable {
        require(!closed && msg.sender != owner);
        require(now <= depositStopTime);
        require(msg.value == 0);

        var record = records[msg.sender];
        var lrcToken = Token(lrcTokenAddress);

        uint lrcAmount = this.balance.mul(RATE)
            .min256(lrcToken.balanceOf(msg.sender))
            .min256(lrcToken.allowance(msg.sender, address(this)))
            .min256(MAX_LRC_DEPOSIT_PER_ADDRESS - record.lrcAmount);

        uint ethAmount = lrcAmount.div(RATE);
        lrcAmount = ethAmount.mul(RATE);

        require(lrcAmount > 0 && ethAmount > 0);

        record.lrcAmount += lrcAmount;
        record.timestamp = now;
        records[msg.sender] = record;

        lrcReceived += lrcAmount;
        ethSent += ethAmount;


        Deposit(
                depositId++,
                msg.sender,
                ethAmount,
                lrcAmount
                );
        require(lrcToken.transferFrom(msg.sender, address(this), lrcAmount));
        msg.sender.transfer(ethAmount);
    }

     
    function withdrawLRC() payable {
        require(!closed && msg.sender != owner);
        require(now > depositStopTime);
        require(msg.value > 0);

        var record = records[msg.sender];
        require(now >= record.timestamp + WITHDRAWAL_DELAY);
        require(now <= record.timestamp + WITHDRAWAL_DELAY + WITHDRAWAL_WINDOW);

        uint ethAmount = msg.value.min256(record.lrcAmount.div(RATE));
        uint lrcAmount = ethAmount.mul(RATE);

        record.lrcAmount -= lrcAmount;
        if (record.lrcAmount == 0) {
            delete records[msg.sender];
        } else {
            records[msg.sender] = record;
        }

        lrcSent += lrcAmount;
        ethReceived += ethAmount;

        Withdrawal(
                   withdrawId++,
                   msg.sender,
                   ethAmount,
                   lrcAmount
                   );

        require(Token(lrcTokenAddress).transfer(msg.sender, lrcAmount));

        uint ethRefund = msg.value - ethAmount;
        if (ethRefund > 0) {
            msg.sender.transfer(ethRefund);
        }
    }

    function getLRCAmount(address addr) public constant returns (uint) {
        return records[addr].lrcAmount;
    }

    function getTimestamp(address addr) public constant returns (uint) {
        return records[addr].timestamp;
    }
}