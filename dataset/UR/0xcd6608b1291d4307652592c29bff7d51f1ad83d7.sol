 

pragma solidity ^0.3.5;

contract DepositHolder {
    uint constant GUARANTEE_PERIOD = 365 days;
    
    event Claim(address addr, uint amount);
    
    struct Entry {
        bytes16 next;
        uint64 deposit;
        uint64 expires;
    }

    address owner;
    address auditor;
    
    mapping(bytes16=>Entry) entries;
    bytes16 oldestHash;
    bytes16 newestHash;
    
    uint public paidOut;
    uint public totalPaidOut;
    uint public depositCount;
    
    function DepositHolder() {
        owner = msg.sender;
        auditor = owner;
    }
    
    modifier owner_only {
        if(msg.sender != owner) throw;
        _;
    }
    
    modifier auditor_only {
        if(msg.sender != auditor) throw;
        _;
    }
    
    function setOwner(address newOwner) owner_only {
        owner = newOwner;
    }
    
    function setAuditor(address newAuditor) auditor_only {
        auditor = newAuditor;
    }

     
    function deposit(bytes16[] values, uint64 deposit) owner_only {
        uint required = values.length * deposit;
        if(msg.value < required) {
            throw;
        } else if(msg.value > required) {
            if(!msg.sender.send(msg.value - required))
                throw;
        }

        extend(values, uint64(deposit));
    }

    function extend(bytes16[] values, uint64 deposit) private {
        uint64 expires = uint64(now + GUARANTEE_PERIOD);

        if(oldestHash == 0) {
            oldestHash = values[0];
            newestHash = values[0];
        } else {
            entries[newestHash].next = values[0];
        }
        
        for(uint i = 0; i < values.length - 1; i++) {
            if(entries[values[i]].expires != 0)
                throw;
            entries[values[i]] = Entry(values[i + 1], deposit, expires);
        }
        
        newestHash = values[values.length - 1];
        if(entries[newestHash].expires != 0)
            throw;
        entries[newestHash] = Entry(0, deposit, expires);
        
        depositCount += values.length;
    }

     
    function withdraw(uint max) owner_only {
        uint recovered = recover(max);
        if(!msg.sender.send(recovered))
            throw;
    }

    function recover(uint max) private returns(uint recovered) {
         
         
        bytes16 ptr = oldestHash;
        uint count;
        for(uint i = 0; i < max && ptr != 0 && entries[ptr].expires < now; i++) {
            recovered += entries[ptr].deposit;
            ptr = entries[ptr].next;
            count += 1;
        }

        oldestHash = ptr;
        if(oldestHash == 0)
            newestHash = 0;
        
         
        if(paidOut > 0) {
            if(recovered > paidOut) {
                recovered -= paidOut;
                paidOut = 0;
            } else {
                paidOut -= recovered;
                recovered = 0;
            }
        }
        
        depositCount -= count;
    }

     
    function nextWithdrawal(bytes16 hash) constant returns(uint when, uint count, uint value, bytes16 next) {
        if(hash == 0) {
            hash = oldestHash;
        }
        next = hash;
        when = entries[hash].expires;
        while(next != 0 && entries[next].expires == when) {
            count += 1;
            value += entries[next].deposit;
            next = entries[next].next;
        }
    }

     
    function check(address addr) constant returns (uint expires, uint deposit) {
        Entry storage entry = entries[bytes16(sha3(addr))];
        expires = entry.expires;
        deposit = entry.deposit;
    }
    
     
    function disburse(address addr, uint amount) auditor_only {
        paidOut += amount;
        totalPaidOut += amount;
        Claim(addr, amount);
        if(!addr.send(amount))
            throw;
    }
    
     
    function destroy() owner_only {
        if(depositCount > 0)
            throw;
        selfdestruct(msg.sender);
    }
}