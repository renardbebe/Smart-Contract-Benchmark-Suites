 

pragma solidity ^0.4.8;
contract KeberuntunganAcak {
 
 
 
 
 
 
 
 
 
 
 
 


    address private owner;
    
     
    uint private balance = 0;
    uint private fee = 2;
    uint private multiplier = 125;

    mapping (address => User) private users;
    Entry[] private entries;
    uint[] private unpaidEntries;
    
     
    function KeberuntunganAcak() {
        owner = msg.sender;
    }

    modifier onlyowner { if (msg.sender == owner) _ ;}
    
    struct User {
        address id;
        uint deposits;
        uint payoutsReceived;
    }
    
    struct Entry {
        address entryAddress;
        uint deposit;
        uint payout;
        bool paid;
    }

     
    function() {
        init();
    }
    
    function init() private{
        
        if (msg.value < 50 finney) {
             (msg.sender.send(msg.value));
            return;
        }
        
        join();
    }
    
    function join() public payable {
        
         
        uint dValue = 50 finney;
        
        if (msg.value > 50 finney) {
            
        	(msg.sender.send(msg.value - 50 finney));	
        	dValue = 50 finney;
        }
      
         
        if (users[msg.sender].id == address(0))
        {
            users[msg.sender].id = msg.sender;
            users[msg.sender].deposits = 0;
            users[msg.sender].payoutsReceived = 0;
        }
        
         
        entries.push(Entry(msg.sender, dValue, (dValue * (multiplier) / 100), false));
        users[msg.sender].deposits++;
        unpaidEntries.push(entries.length -1);
        
         
        balance += (dValue * (100 - fee)) / 100;
        
        uint index = unpaidEntries.length > 1 ? rand(unpaidEntries.length) : 0;
        Entry theEntry = entries[unpaidEntries[index]];
        
         
        if (balance > theEntry.payout) {
            
            uint payout = theEntry.payout;
            
            (theEntry.entryAddress.send(payout));
            theEntry.paid = true;
            users[theEntry.entryAddress].payoutsReceived++;

            balance -= payout;
            
            if (index < unpaidEntries.length - 1)
                unpaidEntries[index] = unpaidEntries[unpaidEntries.length - 1];
           
            unpaidEntries.length--;
            
        }
        
         
        uint fees = this.balance - balance;
        if (fees > 0)
        {
                (owner.send(fees));
        }      
       
    }
    
     
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max;
    }
    
    
     
    function changeOwner(address newOwner) onlyowner private {
        owner = newOwner;
    }
    
    function changeMultiplier(uint multi) onlyowner private {
        if (multi < 110 || multi > 150) throw;
        
        multiplier = multi;
    }
    
    function changeFee(uint newFee) onlyowner private {
        if (fee > 2) 
            throw;
        fee = newFee;
    }
    
    
     
    function multiplierFactor() constant returns (uint factor, string info) {
        factor = multiplier;
        info = 'multipliyer ialah 125%'; 
    }
    
    function currentFee() constant returns (uint feePercentage, string info) {
        feePercentage = fee;
        info = 'fee ialah 2%.';
    }
    
    function totalEntries() constant returns (uint count, string info) {
        count = entries.length;
        info = 'seberapa banyak deposit';
    }
    
    function userStats(address user) constant returns (uint deposits, uint payouts, string info)
    {
        if (users[user].id != address(0x0))
        {
            deposits = users[user].deposits;
            payouts = users[user].payoutsReceived;
            info = 'Users stats: total deposits, payouts diterima.';
        }
    }
    
    function entryDetails(uint index) constant returns (address user, uint payout, bool paid, string info)
    {
        if (index < entries.length) {
            user = entries[index].entryAddress;
            payout = entries[index].payout / 1 finney;
            paid = entries[index].paid;
            info = 'Entry info: user address, expected payout in Finneys, payout status.';
        }
    }
    
    
}