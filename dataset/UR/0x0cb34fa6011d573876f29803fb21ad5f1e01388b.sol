 

pragma solidity ^0.4.11;

 

 

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

 

 
contract StandingOrder {

    using SafeMath for uint;
    using Math for uint;

    address public owner;         
    address public payee;         
    uint public startTime;        
    uint public paymentInterval;  
    uint public paymentAmount;    
    uint public claimedFunds;     
    string public ownerLabel;     
    bool public isTerminated;     
    uint public terminationTime;  

    modifier onlyPayee() {
        require(msg.sender == payee);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    event Collect(uint amount);
     
    event Fund(uint amount);
     
    event Withdraw(uint amount);

     
    function StandingOrder(
        address _owner,
        address _payee,
        uint _paymentInterval,
        uint _paymentAmount,
        uint _startTime,
        string _label
    )
        payable
    {
         
        require(_paymentInterval > 0);
        require(_paymentAmount > 0);
         
         
        require(bytes(_label).length > 2);

         
        owner = _owner;

        payee = _payee;
        paymentInterval = _paymentInterval;
        paymentAmount = _paymentAmount;
        ownerLabel = _label;
        startTime = _startTime;
        isTerminated = false;
    }

     
    function() payable {
        if (isTerminated) {
             
            revert();
        }
         
        Fund(msg.value);
    }

     
    function getEntitledFunds() constant returns (uint) {
         
        if (now < startTime) {
             
            return 0;
        }

         
        uint entitledAmount = paymentAmount;

         
        uint endTime = isTerminated ? terminationTime : now;

         
        uint runtime = endTime.sub(startTime);
        uint completeIntervals = runtime.div(paymentInterval);  
        entitledAmount = entitledAmount.add(completeIntervals.mul(paymentAmount));

         
        return entitledAmount.sub(claimedFunds);
    }

     
    function getUnclaimedFunds() constant returns (uint) {
         
        return getEntitledFunds().min256(this.balance);
    }

     
    function getOwnerFunds() constant returns (int) {
         
         
         
         
         
         
         
        return int256(this.balance) - int256(getEntitledFunds());
    }

     
    function collectFunds() onlyPayee returns(uint) {
        uint amount = getUnclaimedFunds();
        if (amount <= 0) {
             
            revert();
        }

         
        claimedFunds = claimedFunds.add(amount);

         
        Collect(amount);

         
        payee.transfer(amount);

        return amount;
    }

     
    function WithdrawOwnerFunds(uint amount) onlyOwner {
        int intOwnerFunds = getOwnerFunds();  
        if (intOwnerFunds <= 0) {
             
            revert();
        }
         
        uint256 ownerFunds = uint256(intOwnerFunds);

        if (amount > ownerFunds) {
             
            revert();
        }

         
        Withdraw(amount);

        owner.transfer(amount);
    }

     
    function Terminate() onlyOwner {
        assert(getOwnerFunds() <= 0);
        terminationTime = now;
        isTerminated = true;
    }
}


 
contract StandingOrderFactory {
     
    mapping (address => StandingOrder[]) public standingOrdersByOwner;
     
    mapping (address => StandingOrder[]) public standingOrdersByPayee;

     
    event LogOrderCreated(
        address orderAddress,
        address indexed owner,
        address indexed payee
    );

     
    function createStandingOrder(address _payee, uint _paymentAmount, uint _paymentInterval, uint _startTime, string _label) returns (StandingOrder) {
        StandingOrder so = new StandingOrder(msg.sender, _payee, _paymentInterval, _paymentAmount, _startTime, _label);
        standingOrdersByOwner[msg.sender].push(so);
        standingOrdersByPayee[_payee].push(so);
        LogOrderCreated(so, msg.sender, _payee);
        return so;
    }

     
    function getNumOrdersByOwner() constant returns (uint) {
        return standingOrdersByOwner[msg.sender].length;
    }

     
    function getOwnOrderByIndex(uint index) constant returns (StandingOrder) {
        return standingOrdersByOwner[msg.sender][index];
    }

     
    function getNumOrdersByPayee() constant returns (uint) {
        return standingOrdersByPayee[msg.sender].length;
    }

     
    function getPaidOrderByIndex(uint index) constant returns (StandingOrder) {
        return standingOrdersByPayee[msg.sender][index];
    }
}