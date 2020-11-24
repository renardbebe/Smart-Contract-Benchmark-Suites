 

 

 

pragma solidity ^0.4.0;

contract EscrowGoods {

    struct EscrowInfo {

        address buyer;
        uint lockedFunds;
        uint frozenFunds;
        uint64 frozenTime;
        uint16 count;
        bool buyerNo;
        bool sellerNo;
    }

     
    uint16 constant internal None = 0;
    uint16 constant internal Available = 1;
    uint16 constant internal Canceled = 2;

     
    uint16 constant internal Buy = 1;
    uint16 constant internal Accept = 2;
    uint16 constant internal Reject = 3;
    uint16 constant internal Cancel = 4;
    uint16 constant internal Description = 10;
    uint16 constant internal Unlock = 11;
    uint16 constant internal Freeze = 12;
    uint16 constant internal Resolved = 13;

     

    uint constant arbitrationPeriod = 30 days;
    uint constant safeGas = 25000;

     
    address public seller;

     
    uint public contentCount = 0;
    uint public logsCount = 0;

     

    address public arbiter;

    uint public freezePeriod;
     
    uint public feePromille;
     
    uint public rewardPromille;

    uint public feeFunds;
    uint public totalEscrows;

    mapping (uint => EscrowInfo) public escrows;

     

     
    uint16 public status;
     
    uint16 public count;

    uint16 public availableCount;
    uint16 public pendingCount;

     
    uint public price;

    mapping (address => bool) public buyers;

    bool private atomicLock;

     

    event LogDebug(string message);
    event LogEvent(uint indexed lockId, string dataInfo, uint indexed version, uint16 eventType, address indexed sender, uint count, uint payment);

    modifier onlyOwner {
        if (msg.sender != seller)
          throw;
        _;
    }

    modifier onlyArbiter {
        if (msg.sender != arbiter)
          throw;
        _;
    }

     

    function EscrowGoods(address _arbiter, uint _freezePeriod, uint _feePromille, uint _rewardPromille,
                          uint16 _count, uint _price) {

        seller = msg.sender;

         

         

        arbiter = _arbiter;
        freezePeriod = _freezePeriod;
        feePromille = _feePromille;
        rewardPromille = _rewardPromille;

         

        status = Available;
        count = _count;
        price = _price;

        availableCount = count;
    }

     
    function logDebug(string message) internal {
        logsCount++;
        LogDebug(message);
    }

    function logEvent(uint lockId, string dataInfo, uint version, uint16 eventType,
                                address sender, uint count, uint payment) internal {
        contentCount++;
        LogEvent(lockId, dataInfo, version, eventType, sender, count, payment);
    }

    function kill() onlyOwner {

         
        if(totalEscrows > 0) {
            logDebug("totalEscrows > 0");
            return;
        }
         
        if(feeFunds > 0) {
            logDebug("feeFunds > 0");
            return;
        }
        suicide(msg.sender);
    }

    function safeSend(address addr, uint value) internal {

        if(atomicLock) throw;
        atomicLock = true;
        if (!(addr.call.gas(safeGas).value(value)())) {
            atomicLock = false;
            throw;
        }
        atomicLock = false;
    }

     

     
    function yes(uint _lockId, string _dataInfo, uint _version) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug("info.lockedFunds == 0");
            return;
        }
        if(msg.sender != info.buyer && msg.sender != seller) {
            logDebug("msg.sender != info.buyer && msg.sender != seller");
            return;
        }

        uint payment = info.lockedFunds;
        if(payment > this.balance) {
             
            logDebug("payment > this.balance");
            return;
        }

        if(msg.sender == info.buyer) {

             
            safeSend(seller, payment);
        } else if(msg.sender == seller) {

             
            safeSend(info.buyer, payment);
        } else {
             
            logDebug("unknown msg.sender");
            return;
        }

         
        if(totalEscrows > 0) totalEscrows -= 1;
        info.lockedFunds = 0;

        logEvent(_lockId, _dataInfo, _version, Unlock, msg.sender, info.count, payment);
    }

     
    function no(uint _lockId, string _dataInfo, uint _version) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug("info.lockedFunds == 0");
            return;
        }
        if(msg.sender != info.buyer && msg.sender != seller) {
            logDebug("msg.sender != info.buyer && msg.sender != seller");
            return;
        }

         
         
        if(info.frozenFunds == 0) {
            info.frozenFunds = info.lockedFunds;
            info.frozenTime = uint64(now);
        }

        if(msg.sender == info.buyer) {
            info.buyerNo = true;
        }
        else if(msg.sender == seller) {
            info.sellerNo = true;
        } else {
             
            logDebug("unknown msg.sender");
            return;
        }

        logEvent(_lockId, _dataInfo, _version, Freeze, msg.sender, info.count, info.lockedFunds);
    }

     
     
     
    function arbYes(uint _lockId, address _who, uint _payment, string _dataInfo, uint _version) onlyArbiter {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug("info.lockedFunds == 0");
            return;
        }
        if(info.frozenFunds == 0) {
            logDebug("info.frozenFunds == 0");
            return;
        }

        if(_who != seller && _who != info.buyer) {
            logDebug("_who != seller && _who != info.buyer");
            return;
        }
         
        if(!info.buyerNo || !info.sellerNo) {
            logDebug("!info.buyerNo || !info.sellerNo");
            return;
        }

        if(_payment > info.lockedFunds) {
            logDebug("_payment > info.lockedFunds");
            return;
        }
        if(_payment > this.balance) {
             
            logDebug("_payment > this.balance");
            return;
        }

         
        uint reward = (info.lockedFunds * rewardPromille) / 1000;
        if(reward > (info.lockedFunds - _payment)) {
            logDebug("reward > (info.lockedFunds - _payment)");
            return;
        }

         
        safeSend(_who, _payment);

         
        info.lockedFunds -= _payment;
        feeFunds += info.lockedFunds;
        info.lockedFunds = 0;

        logEvent(_lockId, _dataInfo, _version, Resolved, msg.sender, info.count, _payment);
    }

     
    function getFees() onlyArbiter {

        if(feeFunds > this.balance) {
             
            logDebug("feeFunds > this.balance");
            return;
        }
        
        safeSend(arbiter, feeFunds);

        feeFunds = 0;
    }

     
     
     
    function getMoney(uint _lockId) {

        EscrowInfo info = escrows[_lockId];

        if(info.lockedFunds == 0) {
            logDebug("info.lockedFunds == 0");
            return;
        }
         
        if(info.frozenFunds == 0) {
            logDebug("info.frozenFunds == 0");
            return;
        }

         
        if(now < (info.frozenTime + freezePeriod)) {
            logDebug("now < (info.frozenTime + freezePeriod)");
            return;
        }

        uint payment = info.lockedFunds;
        if(payment > this.balance) {
             
            logDebug("payment > this.balance");
            return;
        }

         
        if(info.buyerNo && info.sellerNo) {

             
            if(now < (info.frozenTime + freezePeriod + arbitrationPeriod)) {
                logDebug("now < (info.frozenTime + freezePeriod + arbitrationPeriod)");
                return;
            }

             
            safeSend(info.buyer, payment);

            info.lockedFunds = 0;
            return;
        }

        if(info.buyerNo) {

            safeSend(info.buyer, payment);

            info.lockedFunds = 0;
            return;
        }
        if(info.sellerNo) {

            safeSend(seller, payment);

            info.lockedFunds = 0;
            return;
        }
    }

     

     
    function addDescription(string _dataInfo, uint _version) onlyOwner {

         
        logEvent(0, _dataInfo, _version, Description, msg.sender, 0, 0);
    }

     
    function buy(uint _lockId, string _dataInfo, uint _version, uint16 _count) payable {

         

        if(status != Available) throw;
        if(msg.value < (price * _count)) throw;
        if(_count > availableCount) throw;
        if(_count == 0) throw;
        if(feePromille > 1000) throw;
        if(rewardPromille > 1000) throw;
        if((feePromille + rewardPromille) > 1000) throw;

         
        EscrowInfo info = escrows[_lockId];

         
        if(info.lockedFunds > 0) throw;

         

        uint fee = (msg.value * feePromille) / 1000;
         
        if(fee > msg.value) throw;

        uint funds = (msg.value - fee);
        feeFunds += fee;
        totalEscrows += 1;

        info.buyer = msg.sender;
        info.lockedFunds = funds;
        info.frozenFunds = 0;
        info.buyerNo = false;
        info.sellerNo = false;
        info.count = _count;

        pendingCount += _count;
        buyers[msg.sender] = true;

         
        logEvent(_lockId, _dataInfo, _version, Buy, msg.sender, _count, msg.value);
    }

    function accept(uint _lockId, string _dataInfo, uint _version) onlyOwner {

        EscrowInfo info = escrows[_lockId];
        
        if(info.count > availableCount) {
            logDebug("info.count > availableCount");
            return;
        }
        if(info.count > pendingCount) {
            logDebug("info.count > pendingCount");
            return;
        }

        pendingCount -= info.count;
        availableCount -= info.count;

         
        logEvent(_lockId, _dataInfo, _version, Accept, msg.sender, info.count, info.lockedFunds);
    }

    function reject(uint _lockId, string _dataInfo, uint _version) onlyOwner {
        
        EscrowInfo info = escrows[_lockId];

        if(info.count > pendingCount) {
            logDebug("info.count > pendingCount");
            return;
        }

        pendingCount -= info.count;

         
        yes(_lockId, _dataInfo, _version);

         
         
        logEvent(_lockId, _dataInfo, _version, Reject, msg.sender, info.count, info.lockedFunds);
    }

    function cancel(string _dataInfo, uint _version) onlyOwner {

         
        status = Canceled;

         
        logEvent(0, _dataInfo, _version, Cancel, msg.sender, availableCount, 0);
    }

     
    function unbuy() {

        buyers[msg.sender] = false;
    }

    function () {
        throw;
    }
}