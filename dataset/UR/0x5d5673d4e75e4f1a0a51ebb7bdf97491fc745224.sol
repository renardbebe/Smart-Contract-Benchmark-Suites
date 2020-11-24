 

pragma solidity ^0.4.24;

 
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

 
 
 
contract BBOHoldingContract {
    using SafeMath for uint;
    using Math for uint;
   
     
    uint public constant DEPOSIT_PERIOD             = 60 days;  

     
     
    uint public constant WITHDRAWAL_DELAY           = 360 days;  

     
     
    uint public constant WITHDRAWAL_SCALE           = 1E7;  

     
    uint public constant DRAIN_DELAY                = 720 days;  
    
    address public bboTokenAddress  = 0x0;
    address public owner            = 0x0;

    uint public bboDeposited        = 0;
    uint public depositStartTime    = 0;
    uint public depositStopTime     = 0;

    struct Record {
        uint bboAmount;
        uint timestamp;
    }

    mapping (address => Record) records;
    
     

     
    event Started(uint _time);

     
    event Drained(uint _bboAmount);

     
    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _bboAmount);

     
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _bboAmount);

     
     
    constructor (address _bboTokenAddress, address _owner) public {
        require(_bboTokenAddress != address(0));
        require(_owner != address(0));

        bboTokenAddress = _bboTokenAddress;
        owner = _owner;
    }

     

     
    function start() public {
        require(msg.sender == owner);
        require(depositStartTime == 0);

        depositStartTime = now;
        depositStopTime  = depositStartTime + DEPOSIT_PERIOD;

        emit Started(depositStartTime);
    }


     
    function drain() public {
        require(msg.sender == owner);
        require(depositStartTime > 0 && now >= depositStartTime + DRAIN_DELAY);

        uint balance = bboBalance();
        require(balance > 0);

        require(ERC20(bboTokenAddress).transfer(owner, balance));

        emit Drained(balance);
    }

    function () payable {
        require(depositStartTime > 0);

        if (now >= depositStartTime && now <= depositStopTime) {
            depositBBO();
        } else if (now > depositStopTime){
            withdrawBBO();
        } else {
            revert();
        }
    }

     
    function bboBalance() public constant returns (uint) {
        return ERC20(bboTokenAddress).balanceOf(address(this));
    }
    function holdBalance() public constant returns (uint) {
        return records[msg.sender].bboAmount;
    }
    function lastDeposit() public constant returns (uint) {
        return records[msg.sender].timestamp;
    }
     
    function depositBBO() payable {
        require(depositStartTime > 0);
        require(msg.value == 0);
        require(now >= depositStartTime && now <= depositStopTime);
        
        ERC20 bboToken = ERC20(bboTokenAddress);
        uint bboAmount = bboToken
            .balanceOf(msg.sender)
            .min256(bboToken.allowance(msg.sender, address(this)));

        if(bboAmount > 0){
            require(bboToken.transferFrom(msg.sender, address(this), bboAmount));
            Record storage record = records[msg.sender];
            record.bboAmount = record.bboAmount.add(bboAmount);
            record.timestamp = now;
            records[msg.sender] = record;

            bboDeposited = bboDeposited.add(bboAmount);
            emit Deposit(depositId++, msg.sender, bboAmount);
        }
    }

     
    function withdrawBBO() payable {
        require(depositStartTime > 0);
        require(bboDeposited > 0);

        Record storage record = records[msg.sender];
        require(now >= record.timestamp + WITHDRAWAL_DELAY);
        require(record.bboAmount > 0);

        uint bboWithdrawalBase = record.bboAmount;
        if (msg.value > 0) {
            bboWithdrawalBase = bboWithdrawalBase
                .min256(msg.value.mul(WITHDRAWAL_SCALE));
        }

        uint bboBonus = getBonus(bboWithdrawalBase);
        uint balance = bboBalance();
        uint bboAmount = balance.min256(bboWithdrawalBase + bboBonus);
        
        bboDeposited = bboDeposited.sub(bboWithdrawalBase);
        record.bboAmount = record.bboAmount.sub(bboWithdrawalBase);

        if (record.bboAmount == 0) {
            delete records[msg.sender];
        } else {
            records[msg.sender] = record;
        }

        emit Withdrawal(withdrawId++, msg.sender, bboAmount);

        require(ERC20(bboTokenAddress).transfer(msg.sender, bboAmount));
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }

    function getBonus(uint _bboWithdrawalBase) constant returns (uint) {
        return internalCalculateBonus(bboBalance() - bboDeposited,bboDeposited, _bboWithdrawalBase);
    }

    function internalCalculateBonus(uint _totalBonusRemaining, uint _bboDeposited, uint _bboWithdrawalBase) constant returns (uint) {
        require(_bboDeposited > 0);
        require(_totalBonusRemaining >= 0);

         
         
        return _totalBonusRemaining
            .mul(_bboWithdrawalBase.mul(sqrt(sqrt(sqrt(sqrt(_bboWithdrawalBase))))))
            .div(_bboDeposited.mul(sqrt(sqrt(sqrt(sqrt(_bboDeposited))))));
    }

    function sqrt(uint x) internal constant returns (uint) {
        uint y = x;
        while (true) {
            uint z = (y + (x / y)) / 2;
            uint w = (z + (x / z)) / 2;
            if (w == y) {
                if (w < y) return w;
                else return y;
            }
            y = w;
        }
    }
}