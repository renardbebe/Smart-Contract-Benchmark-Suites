 

pragma solidity ^0.4.25;

library Math {
  function min(uint a, uint b) internal pure returns(uint) {
    if (a > b) {
      return b;
    }
    return a;
  }
  
  function max(uint a, uint b) internal pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }
}

library Percent {
   
  struct percent {
    uint num;
    uint den;
  }
  
   
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

    function toMemory(percent storage p) internal view returns (Percent.percent memory) {
    return Percent.percent(p.num, p.den);
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }
  
   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

}

contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

   
  function owner() public view returns(address) {
    return owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
}

 
contract distribution is Ownable {
    using SafeMath for uint;
    
    uint public currentPaymentIndex = 0;
    uint public depositorsCount;
    uint public amountForDistribution = 0;
    uint public amountRaised = 0;
    
    struct Deposite {
        address depositor;
        uint amount;
        uint depositeTime;
        uint paimentTime;
    }
    
    Deposite[] public deposites;

    mapping ( address => uint[]) public depositors;
    
    function getAllDepositesCount() public view returns (uint) ;
    
    function getLastDepositId() public view returns (uint) ;

    function getDeposit(uint _id) public view returns (address, uint, uint, uint);
}

contract FromResponsibleInvestors is Ownable {
    using Percent for Percent.percent;
    using SafeMath for uint;
    using Math for uint;
    
     
    address constant public advertisingAddress = address(0x43571AfEA3c3c6F02569bdC59325F4f95463014d);  
    address constant public adminsAddress = address(0x8008BD6FdDF2C26382B4c19d714A1BfeA317ec57);  
    
     
    Percent.percent private m_adminsPercent = Percent.percent(3, 100);        
    Percent.percent private m_advertisingPercent = Percent.percent(5, 100); 
     
    Percent.percent public MULTIPLIER = Percent.percent(120, 100);  
    
     
    bool public migrationFinished = false; 
    
    uint public amountRaised = 0;
    uint public advertAmountRaised = 0;  
     
    struct Deposit {
        address depositor;  
        uint deposit;    
        uint expects;     
        uint paymentTime;  
    }

    Deposit[] private ImportedQueue;   
    Deposit[] private Queue;   
     
    mapping(address => uint[]) public depositors;
    
    uint public depositorsCount = 0;
    
    uint public currentImportedReceiverIndex = 0;  
    uint public currentReceiverIndex = 0;  
    
    uint public minBalanceForDistribution = 24 ether;  

     
    event LogNewInvesment(address indexed addr, uint when, uint investment, uint value);
    event LogImportInvestorsPartComplete(uint when, uint howmuch, uint lastIndex);
    event LogNewInvestor(address indexed addr, uint when);

    constructor() public {
    }

     
    function () public payable {
        if(msg.value > 0){
            require(msg.value >= 0.01 ether, "investment must be >= 0.01 ether");  
            require(msg.value <= 10 ether, "investment must be <= 10 ether");  

             
            uint expect = MULTIPLIER.mul(msg.value);
            Queue.push(Deposit({depositor:msg.sender, deposit:msg.value, expects:expect, paymentTime:0}));
            amountRaised += msg.value;
            if (depositors[msg.sender].length == 0) depositorsCount += 1;
            depositors[msg.sender].push(Queue.length - 1);
            
            uint advertperc = m_advertisingPercent.mul(msg.value);
            advertisingAddress.send(advertperc);
            adminsAddress.send(m_adminsPercent.mul(msg.value));
            advertAmountRaised += advertperc;
        } 
    }

     
     
    function distribute(uint maxIterations) public {
        require(maxIterations <= 100, "no more than 100 iterations");  
        uint money = address(this).balance;
        require(money >= minBalanceForDistribution, "Not enough funds to pay"); 
        uint ImportedQueueLen = ImportedQueue.length;
        uint QueueLen = Queue.length;
        uint toSend = 0;
        maxIterations = maxIterations.max(5); 
        
        for (uint i = 0; i < maxIterations; i++) {
            if (currentImportedReceiverIndex < ImportedQueueLen){
                toSend = ImportedQueue[currentImportedReceiverIndex].expects;
                if (money >= toSend){
                    money = money.sub(toSend);
                    ImportedQueue[currentImportedReceiverIndex].paymentTime = now;
                    ImportedQueue[currentImportedReceiverIndex].depositor.send(toSend);
                    currentImportedReceiverIndex += 1;
                }
            }
            if (currentReceiverIndex < QueueLen){
                toSend = Queue[currentReceiverIndex].expects;
                if (money >= toSend){
                    money = money.sub(toSend);
                    Queue[currentReceiverIndex].paymentTime = now;
                    Queue[currentReceiverIndex].depositor.send(toSend);
                    currentReceiverIndex += 1;
                }
            }
        }
        setMinBalanceForDistribution();
    }
     
    function setMinBalanceForDistribution() private {
        uint importedExpects = 0;
        
        if (currentImportedReceiverIndex < ImportedQueue.length) {
            importedExpects = ImportedQueue[currentImportedReceiverIndex].expects;
        } 
        
        if (currentReceiverIndex < Queue.length) {
            minBalanceForDistribution = Queue[currentReceiverIndex].expects;
        } else {
            minBalanceForDistribution = 12 ether;  
        }
        
        if (importedExpects > 0){
            minBalanceForDistribution = minBalanceForDistribution.add(importedExpects);
        }
    }
    
     
    function FromMMM30Reload(address _ImportContract, uint _from, uint _to) public onlyOwner {
        require(!migrationFinished);
        distribution ImportContract = distribution(_ImportContract);
        
        address depositor;
        uint amount;
        uint depositeTime;
        uint paymentTime;
        uint c = 0;
        uint maxLen = ImportContract.getLastDepositId();
        _to = _to.min(maxLen);
        
        for (uint i = _from; i <= _to; i++) {
                (depositor, amount, depositeTime, paymentTime) = ImportContract.getDeposit(i);
                 
                if ((depositor != address(0x494A7A2D0599f2447487D7fA10BaEAfCB301c41B)) && 
                    (depositor != address(0xFd3093a4A3bd68b46dB42B7E59e2d88c6D58A99E)) && 
                    (depositor != address(0xBaa2CB97B6e28ef5c0A7b957398edf7Ab5F01A1B)) && 
                    (depositor != address(0xFDd46866C279C90f463a08518e151bC78A1a5f38)) && 
                    (depositor != address(0xdFa5662B5495E34C2aA8f06Feb358A6D90A6d62e))) {
                    ImportedQueue.push(Deposit({depositor:depositor, deposit:uint(amount), expects:uint(MULTIPLIER.mul(amount)), paymentTime:0}));
                    depositors[depositor].push(ImportedQueue.length - 1);
                    c++;
                }
        }
        emit LogImportInvestorsPartComplete(now, c, _to);
    }

     
    function finishMigration() public onlyOwner {
        migrationFinished = true;
        renounceOwnership();
    }

     
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
     
    function getAdvertisingBalance() public view returns (uint) {
        return advertisingAddress.balance;
    }
    
     
    function getDepositsCount() public view returns (uint) {
        return Queue.length.sub(currentReceiverIndex);
    }
    
     
    function getImportedDepositsCount() public view returns (uint) {
        return ImportedQueue.length.sub(currentImportedReceiverIndex);
    }
    
     
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect, uint paymentTime){
        Deposit storage dep = Queue[idx];
        return (dep.depositor, dep.deposit, dep.expects, dep.paymentTime);
    }
    
     
    function getImportedDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect, uint paymentTime){
        Deposit storage dep = ImportedQueue[idx];
        return (dep.depositor, dep.deposit, dep.expects, dep.paymentTime);
    }
    
     
    function getLastPayments(uint lastIndex) public view returns (address, uint, uint) {
        uint depositeIndex = currentReceiverIndex.sub(lastIndex).sub(1);
        return (Queue[depositeIndex].depositor, Queue[depositeIndex].paymentTime, Queue[depositeIndex].expects);
    }

     
    function getLastImportedPayments(uint lastIndex) public view returns (address, uint, uint) {
        uint depositeIndex = currentImportedReceiverIndex.sub(lastIndex).sub(1);
        return (ImportedQueue[depositeIndex].depositor, ImportedQueue[depositeIndex].paymentTime, ImportedQueue[depositeIndex].expects);
    }

     
    function getUserDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=0; i<Queue.length; ++i){
            if(Queue[i].depositor == depositor)
                c++;
        }
        return c;
    }
    
     
    function getImportedUserDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=0; i<ImportedQueue.length; ++i){
            if(ImportedQueue[i].depositor == depositor)
                c++;
        }
        return c;
    }

     
    function getUserDeposits(address depositor) public view returns (uint[] idxs, uint[] paymentTime, uint[] amount, uint[] expects) {
        uint c = getUserDepositsCount(depositor);

        idxs = new uint[](c);
        paymentTime = new uint[](c);
        expects = new uint[](c);
        amount = new uint[](c);
        uint num = 0;

        if(c > 0) {
            uint j = 0;
            for(uint i=0; i<c; ++i){
                num = depositors[depositor][i];
                Deposit storage dep = Queue[num];
                idxs[j] = i;
                paymentTime[j] = dep.paymentTime;
                amount[j] = dep.deposit;
                expects[j] = dep.expects;
                j++;
            }
        }
    }
    
     
    function getImportedUserDeposits(address depositor) public view returns (uint[] idxs, uint[] paymentTime, uint[] amount, uint[] expects) {
        uint c = getImportedUserDepositsCount(depositor);

        idxs = new uint[](c);
        paymentTime = new uint[](c);
        expects = new uint[](c);
        amount = new uint[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=0; i<ImportedQueue.length; ++i){
                Deposit storage dep = ImportedQueue[i];
                if(dep.depositor == depositor){
                    idxs[j] = i;
                    paymentTime[j] = dep.paymentTime;
                    amount[j] = dep.deposit;
                    expects[j] = dep.expects;
                    j++;
                }
            }
        }
    }
}