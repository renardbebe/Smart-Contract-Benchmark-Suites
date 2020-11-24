 

pragma solidity ^0.4.23;


 
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

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract ARPMidTermHolding {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

     
    uint256 public constant DEPOSIT_PERIOD      = 31 days;  

     
    uint256 public constant WITHDRAWAL_DELAY    = 240 days;  

     
    uint256 public constant DRAIN_DELAY         = 1080 days;  

     
    uint256 public constant BONUS_SCALE         = 5;

     
    ERC20 public arpToken;
    address public owner;
    uint256 public arpDeposited;
    uint256 public depositStartTime;
    uint256 public depositStopTime;

    struct Record {
        uint256 amount;
        uint256 timestamp;
    }

    mapping (address => Record) records;

     

     
    event Drained(uint256 _amount);

     
    uint256 public depositId = 0;
    event Deposit(uint256 _depositId, address indexed _addr, uint256 _amount, uint256 _bonus);

     
    uint256 public withdrawId = 0;
    event Withdrawal(uint256 _withdrawId, address indexed _addr, uint256 _amount);

     
    constructor(ERC20 _arpToken, uint256 _depositStartTime) public {
        arpToken = _arpToken;
        owner = msg.sender;
        depositStartTime = _depositStartTime;
        depositStopTime = _depositStartTime.add(DEPOSIT_PERIOD);
    }

     

     
    function drain() public {
        require(msg.sender == owner);
         
        require(now >= depositStartTime.add(DRAIN_DELAY));

        uint256 balance = arpToken.balanceOf(address(this));
        require(balance > 0);

        arpToken.safeTransfer(owner, balance);

        emit Drained(balance);
    }

    function() public {
         
        if (now >= depositStartTime && now < depositStopTime) {
            deposit();
         
        } else if (now > depositStopTime){
            withdraw();
        } else {
            revert();
        }
    }

     
    function balanceOf(address _owner) view public returns (uint256) {
        return records[_owner].amount;
    }

     
    function withdrawalTimeOf(address _owner) view public returns (uint256) {
        return records[_owner].timestamp.add(WITHDRAWAL_DELAY);
    }

     
    function deposit() private {
        uint256 amount = arpToken
            .balanceOf(msg.sender)
            .min256(arpToken.allowance(msg.sender, address(this)));
        require(amount > 0);

        Record storage record = records[msg.sender];
        record.amount = record.amount.add(amount);
         
        record.timestamp = now;
        records[msg.sender] = record;

        arpDeposited = arpDeposited.add(amount);

        uint256 bonus = amount.div(BONUS_SCALE);
        if (bonus > 0) {
            arpToken.safeTransferFrom(owner, msg.sender, bonus);
        }
        arpToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(depositId++, msg.sender, amount, bonus);
    }

     
    function withdraw() private {
        require(arpDeposited > 0);

        Record storage record = records[msg.sender];
        require(record.amount > 0);
         
        require(now >= record.timestamp.add(WITHDRAWAL_DELAY));
        uint256 amount = record.amount;
        delete records[msg.sender];

        arpDeposited = arpDeposited.sub(amount);

        arpToken.safeTransfer(msg.sender, amount);

        emit Withdrawal(withdrawId++, msg.sender, amount);
    }
}