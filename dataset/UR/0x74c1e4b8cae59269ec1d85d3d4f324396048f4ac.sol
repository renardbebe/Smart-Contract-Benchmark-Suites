 

 
contract BeerCoin {
    using Itmap for Itmap.AddressUintMap;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    struct UserAccount {
        bool exists;
        Itmap.AddressUintMap debtors;  
        mapping(address=>uint) allowances;
        uint maxCredit;  
        uint beersOwed;  
        uint beersOwing;  
    }
    uint beersOwing;
    uint defaultMaxCredit;
    
    function() {
        throw;
    }
    
    function BeerCoin(uint _defaultMaxCredit) {
        defaultMaxCredit = _defaultMaxCredit;
    }
    
    mapping(address=>UserAccount) accounts;

    function maximumCredit(address owner) constant returns (uint) {
        if(accounts[owner].exists) {
            return accounts[owner].maxCredit;
        } else {
            return defaultMaxCredit;
        }
    }

    function setMaximumCredit(uint credit) {
         
        if(credit > 655360)
            return;

        if(!accounts[msg.sender].exists)
            accounts[msg.sender].exists = true;
        accounts[msg.sender].maxCredit = credit;
    }
    
    function numDebtors(address owner) constant returns (uint) {
        return accounts[owner].debtors.size();
    }
    
    function debtor(address owner, uint idx) constant returns (address) {
        return accounts[owner].debtors.index(idx);
    }
    
    function debtors(address owner) constant returns (address[]) {
        return accounts[owner].debtors.keys;
    }

    function totalSupply() constant returns (uint256 supply) {
        return beersOwing;   
    }
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return accounts[owner].beersOwing;
    }
    
    function balanceOf(address owner, address debtor) constant returns (uint256 balance) {
        return accounts[owner].debtors.get(debtor);
    }
    
    function totalDebt(address owner) constant returns (uint256 balance) {
        return accounts[owner].beersOwed;
    }
    
    function transfer(address to, uint256 value) returns (bool success) {
        return doTransfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
        if(accounts[from].allowances[msg.sender] >= value && doTransfer(from, to, value)) {
            accounts[from].allowances[msg.sender] -= value;
            return true;
        }
        return false;
    }
    
    function doTransfer(address from, address to, uint value) internal returns (bool) {
        if(from == to)
            return false;
            
        if(!accounts[to].exists) {
            accounts[to].exists = true;
            accounts[to].maxCredit = defaultMaxCredit;
        }
        
         
        if(value > accounts[to].maxCredit + accounts[from].debtors.get(to))
            return false;
        
        Transfer(from, to, value);

        value -= reduceDebt(to, from, value);
        createDebt(from, to, value);

        return true;
    }
    
     
    function transferOther(address to, address debtor, uint value) returns (bool) {
        return doTransferOther(msg.sender, to, debtor, value);
    }

     
    function transferOtherFrom(address from, address to, address debtor, uint value) returns (bool) {
        if(accounts[from].allowances[msg.sender] >= value && doTransferOther(from, to, debtor, value)) {
            accounts[from].allowances[msg.sender] -= value;
            return true;
        }
        return false;
    }
    
    function doTransferOther(address from, address to, address debtor, uint value) internal returns (bool) {
        if(from == to || to == debtor)
            return false;
            
        if(!accounts[to].exists) {
            accounts[to].exists = true;
            accounts[to].maxCredit = defaultMaxCredit;
        }
        
        if(transferDebt(from, to, debtor, value)) {
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
     
     
     
    function createDebt(address debtor, address creditor, uint value) internal returns (bool) {
        if(value == 0)
            return true;
        
        if(value > accounts[creditor].maxCredit)
            return false;

        accounts[creditor].debtors.set(
            debtor, accounts[creditor].debtors.get(debtor) + value);
        accounts[debtor].beersOwed += value;
        accounts[creditor].beersOwing += value;
        beersOwing += value;
        
        return true;
    }
    
     
     
    function reduceDebt(address debtor, address creditor, uint value) internal returns (uint) {
        var owed = accounts[creditor].debtors.get(debtor);
        if(value >= owed) {
            value = owed;
            
            accounts[creditor].debtors.remove(debtor);
        } else {
            accounts[creditor].debtors.set(debtor, owed - value);
        }
        
        accounts[debtor].beersOwed -= value;
        accounts[creditor].beersOwing -= value;
        beersOwing -= value;
        
        return value;
    }
    
     
     
     
    function transferDebt(address oldCreditor, address newCreditor, address debtor, uint value) internal returns (bool) {
        var owedOld = accounts[oldCreditor].debtors.get(debtor);
        if(owedOld < value)
            return false;
        
        var owedNew = accounts[newCreditor].debtors.get(debtor);
        if(value + owedNew > accounts[newCreditor].maxCredit)
            return false;
        
        
        if(owedOld == value) {
            accounts[oldCreditor].debtors.remove(debtor);
        } else {
            accounts[oldCreditor].debtors.set(debtor, owedOld - value);
        }
        accounts[oldCreditor].beersOwing -= value;
        
        accounts[newCreditor].debtors.set(debtor, owedNew + value);
        accounts[newCreditor].beersOwing += value;
        
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        accounts[msg.sender].allowances[spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256) {
        return accounts[owner].allowances[spender];
    }
}


library Itmap {
    struct AddressUintMapEntry {
        uint value;
        uint idx;
    }
    
    struct AddressUintMap {
        mapping(address=>AddressUintMapEntry) entries;
        address[] keys;
    }
    
    function set(AddressUintMap storage self, address k, uint v) internal {
        var entry = self.entries[k];
        if(entry.idx == 0) {
            entry.idx = self.keys.length + 1;
            self.keys.push(k);
        }
        entry.value = v;
    }
    
    function get(AddressUintMap storage self, address k) internal returns (uint) {
        return self.entries[k].value;
    }
    
    function contains(AddressUintMap storage self, address k) internal returns (bool) {
        return self.entries[k].idx > 0;
    }
    
    function remove(AddressUintMap storage self, address k) internal {
        var entry = self.entries[k];
        if(entry.idx > 0) {
            var otherkey = self.keys[self.keys.length - 1];
            self.keys[entry.idx - 1] = otherkey;
            self.keys.length -= 1;
            
            self.entries[otherkey].idx = entry.idx;
            entry.idx = 0;
            entry.value = 0;
        }
    }
    
    function size(AddressUintMap storage self) internal returns (uint) {
        return self.keys.length;
    }
    
    function index(AddressUintMap storage self, uint idx) internal returns (address) {
        return self.keys[idx];
    }
}