 

 
pragma solidity 0.5.7;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) view public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
 
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
     
    constructor()
        public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

     
     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

     
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0x0);
    }
}


 
 
 
contract NewLRCLongTermHoldingContract is Claimable {
    using SafeMath for uint;
    using Math for uint;

     
    uint public constant DEPOSIT_PERIOD             = 60 days;  

     
     
    uint public constant WITHDRAWAL_DELAY           = 540 days;  

     
     
    uint public constant WITHDRAWAL_SCALE           = 1E7;  

     
    uint public constant DRAIN_DELAY                = 1080 days;  

    address public lrcTokenAddress;

    uint public lrcDeposited        = 0;
    uint public depositStartTime    = 1504076273;
    uint public depositStopTime     = 1509260273;

    struct Record {
        uint lrcAmount;
        uint timestamp;
    }

    mapping (address => Record) public records;

     

     
    event Started(uint _time);

     
    event Drained(uint _lrcAmount);

     
    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _lrcAmount);

     
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _lrcAmount);

     
     
    constructor(address _lrcTokenAddress) public {
        require(_lrcTokenAddress != address(0));
        lrcTokenAddress = _lrcTokenAddress;
    }

     

     
     

     
     

     
     


     
    function drain() onlyOwner public {
        require(depositStartTime > 0 && now >= depositStartTime + DRAIN_DELAY);

        uint balance = lrcBalance();
        require(balance > 0);

        require(Token(lrcTokenAddress).transfer(owner, balance));

        emit Drained(balance);
    }

    function () payable external {
        require(depositStartTime > 0);

        if (now >= depositStartTime && now <= depositStopTime) {
            depositLRC();
        } else if (now > depositStopTime){
            withdrawLRC();
        } else {
            revert();
        }
    }

     
    function lrcBalance() public view returns (uint) {
        return Token(lrcTokenAddress).balanceOf(address(this));
    }

    function batchAddDepositRecordsByOwner(address[] calldata users, uint[] calldata lrcAmounts, uint[] calldata timestamps) external onlyOwner {
        require(users.length == lrcAmounts.length);
        require(users.length == timestamps.length);
        for (uint i = 0; i < users.length; i++) {
            require(users[i] != address(0));
            require(timestamps[i] >= depositStartTime && timestamps[i] <= depositStopTime);
            Record memory record = Record(lrcAmounts[i], timestamps[i]);
            records[users[i]] = record;

            lrcDeposited += lrcAmounts[i];

            emit Deposit(depositId++, users[i], lrcAmounts[i]);
        }
    }

     
    function depositLRC() payable public {
        require(depositStartTime > 0, "program not started");
        require(msg.value == 0, "no ether should be sent");
        require(now >= depositStartTime && now <= depositStopTime, "beyond deposit time period");

        Token lrcToken = Token(lrcTokenAddress);
        uint lrcAmount = lrcToken
            .balanceOf(msg.sender)
            .min256(lrcToken.allowance(msg.sender, address(this)));

        require(lrcAmount > 0, "lrc allowance is zero");

        Record memory record = records[msg.sender];
        record.lrcAmount += lrcAmount;
        record.timestamp = now;
        records[msg.sender] = record;

        lrcDeposited += lrcAmount;

        emit Deposit(depositId++, msg.sender, lrcAmount);

        require(lrcToken.transferFrom(msg.sender, address(this), lrcAmount), "lrc transfer failed");
    }

     
    function withdrawLRC() payable public {
        require(depositStartTime > 0);
        require(lrcDeposited > 0);

        Record memory record = records[msg.sender];
        require(now >= record.timestamp + WITHDRAWAL_DELAY);
        require(record.lrcAmount > 0);

        uint lrcWithdrawalBase = record.lrcAmount;
        if (msg.value > 0) {
            lrcWithdrawalBase = lrcWithdrawalBase
                .min256(msg.value.mul(WITHDRAWAL_SCALE));
        }

        uint lrcBonus = getBonus(lrcWithdrawalBase);
        uint balance = lrcBalance();
        uint lrcAmount = balance.min256(lrcWithdrawalBase + lrcBonus);

        lrcDeposited -= lrcWithdrawalBase;
        record.lrcAmount -= lrcWithdrawalBase;

        if (record.lrcAmount == 0) {
            delete records[msg.sender];
        } else {
            records[msg.sender] = record;
        }

        emit Withdrawal(withdrawId++, msg.sender, lrcAmount);

        require(Token(lrcTokenAddress).transfer(msg.sender, lrcAmount));
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }

    function getBonus(uint _lrcWithdrawalBase) view public returns (uint) {
        return internalCalculateBonus(lrcBalance() - lrcDeposited,lrcDeposited, _lrcWithdrawalBase);
    }

    function internalCalculateBonus(uint _totalBonusRemaining, uint _lrcDeposited, uint _lrcWithdrawalBase) internal pure returns (uint) {
        require(_lrcDeposited > 0);
        require(_totalBonusRemaining >= 0);

         
         
        return _totalBonusRemaining
            .mul(_lrcWithdrawalBase.mul(sqrt(sqrt(sqrt(sqrt(_lrcWithdrawalBase))))))
            .div(_lrcDeposited.mul(sqrt(sqrt(sqrt(sqrt(_lrcDeposited))))));
    }

    function sqrt(uint x) internal pure returns (uint) {
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