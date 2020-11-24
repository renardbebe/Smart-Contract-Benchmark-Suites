 

contract Ethstick {
    
 
 
 
 
    
    address private pig;
    
     
    uint private balance = 0;
    uint private maxDeposit = 5;
    uint private fee = 0;
    uint private multiplier = 120;
    uint private payoutOrder = 0;
    uint private donkeysInvested = 0;
    uint private investmentRecord = 0;
    uint private carrots = 0;
    uint private eligibleForFees = 5;
    address private donkeyKing = 0x0;
    
    mapping (address => Donkey) private donkeys;
    Entry[] private entries;
    
    Donkey[] private ranking;
    
    event NewKing(address ass);
    
     
    function Ethstick() {
        pig = msg.sender;
        ranking.length = 10;
    }

    modifier onlypig { if (msg.sender == pig) _ }
    
    struct Donkey {
        address addr;
        string nickname;
        uint invested;
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
         
        if (msg.value < 100 finney) {
            msg.sender.send(msg.value);
            return;
        }
        
        chase();
    }
    
     
    function chase() private {
        
         
        uint dValue = 100 finney;
        if (msg.value > maxDeposit * 1 ether) {
            
        	msg.sender.send(msg.value - maxDeposit * 1 ether);	
        	dValue = maxDeposit * 1 ether;
        }
        else { dValue = msg.value; }

         
        addNewDonkey(msg.sender);
        
         
        entries.push(Entry(msg.sender, dValue, (dValue * (multiplier) / 100), false));
           
         
        balance += (dValue * (100 - fee)) / 100;
        donkeysInvested += dValue;
        donkeys[msg.sender].invested += dValue;
        
        
         
        uint index = ranking.length - 1;
        uint newEntry = donkeys[msg.sender].invested;
        bool done = false;
        bool samePosition = false;
        uint existingAt = ranking.length - 1;

        while (ranking[index].invested < newEntry && !done)
        {
            if (index > 0)
            {
                done = donkeys[ranking[index - 1].addr].invested > newEntry;
                
                if (ranking[index].addr == msg.sender)
                    existingAt = index;
                
                if (done)
                {
                    if (ranking[index].addr == msg.sender)
                    { 
                        ranking[index] = donkeys[msg.sender];
                        samePosition = true;
                    }
                }
              
                if (!done) index--;
            }
            else
            {
                done = true;
                index = 0;
                if (ranking[index].addr == msg.sender || ranking[index].addr == address(0x0))
                {
                    ranking[index] = donkeys[msg.sender];
                    samePosition = true;
                }
            }
            
        }
        
        if (!samePosition)
        {
            rankDown(index, existingAt);
            ranking[index] = donkeys[msg.sender];
        }
        
        
         
        while (balance > entries[payoutOrder].payout) {
            
            uint payout = entries[payoutOrder].payout;
            
            entries[payoutOrder].entryAddress.send(payout);
            entries[payoutOrder].paid = true;

            balance -= payout;
            
            carrots++;
            payoutOrder++;
        }
        
         
        uint fees = this.balance - balance;
        if (fees > 0)
        {
            if (entries.length >= 50 && entries.length % 5 == 0)
            {
                fees = dValue * fee / 100;
                uint luckyDonkey = rand(eligibleForFees) - 1;
                
                if (ranking[luckyDonkey].addr != address(0x0))
                    ranking[luckyDonkey].addr.send(fees);
                else
                    donkeyKing.send(fees);
            }
            else
                pig.send(fees);
        }        
        
         
        if (donkeys[msg.sender].invested > investmentRecord)
        {
            donkeyKing = msg.sender;
            NewKing(msg.sender);
            investmentRecord = donkeys[msg.sender].invested;
            
        }
        
        if (ranking[0].addr != donkeys[donkeyKing].addr && ranking[0].addr != address(0x0))
        {
            ranking[1] = donkeys[ranking[0].addr];
            ranking[0] = donkeys[donkeyKing];
        }
        
    }
    
    function rankDown(uint index, uint offset) private
    {
        for (uint i = offset; i > index; i--)
        {
            ranking[i] = donkeys[ranking[i-1].addr];
        }
    }
    
    function addNewDonkey(address Address) private
    {
        if (donkeys[Address].addr == address(0))
        {
            donkeys[Address].addr = Address;
            donkeys[Address].nickname = 'GullibleDonkey';
            donkeys[Address].invested = 0;
        }
    }
    
     
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max + 1;
    }
    

     
    function changePig(address newPig) onlypig {
        pig = newPig;
    }
    
    
    function changeMultiplier(uint multi) onlypig {
        if (multi < 110 || multi > 130) 
            throw;
        
        multiplier = multi;
    }
    
    function changeFee(uint newFee) onlypig {
        if (newFee > 5) 
            throw;
        
        fee = newFee;
    }
    
    function changeMaxDeposit(uint max) onlypig {
        if (max < 1 || max > 10)
            throw;
            
        maxDeposit = max;
    }
    
    function changeRankingSize(uint size) onlypig {
        if (size < 5 || size > 100)
            throw;
            
        ranking.length = size;
    }
    
    function changeEligibleDonkeys(uint number) onlypig {
        if (number < 5 || number > 15)
            throw;
            
        eligibleForFees = number;
    }
    
    
     
    function setNickname(string name) {
        addNewDonkey(msg.sender);
        
        if (bytes(name).length >= 2 && bytes(name).length <= 16)
            donkeys[msg.sender].nickname = name;
    }
    
    function carrotsCaught() constant returns (uint amount, string info) {
        amount = carrots;
        info = 'The number of payouts sent to participants.';
    }
    
    function currentBalance() constant returns (uint theBalance, string info) {
        theBalance = balance / 1 finney;
        info = 'The balance of the contract in Finneys.';
    }
    
    function theDonkeyKing() constant returns (address king, string nickname, uint totalInvested, string info) {
        king = donkeyKing;  
        nickname = donkeys[donkeyKing].nickname;
        totalInvested = donkeys[donkeyKing].invested / 1 ether;
        info = 'The greediest of all donkeys. You go, ass!';
    }
    
    function donkeyName(address Address) constant returns (string nickname) {
        nickname = donkeys[Address].nickname;
    }
    
    function currentMultiplier() constant returns (uint theMultiplier, string info) {
        theMultiplier = multiplier;
        info = 'The multiplier applied to all deposits (x100). It determines the amount of money you will get when you catch the carrot.';
    }
    
    function generousFee() constant returns (uint feePercentage, string info) {
        feePercentage = fee;
        info = 'The generously modest fee percentage applied to all deposits. It can change to lure more donkeys (max 5%).';
    }
    
    function nextPayoutGoal() constant returns (uint finneys, string info) {
        finneys = (entries[payoutOrder].payout - balance) / 1 finney;
        info = 'The amount of Finneys (Ethers * 1000) that need to be deposited for the next donkey to catch his carrot.';
    }
    
    function totalEntries() constant returns (uint count, string info) {
        count = entries.length;
        info = 'The number of times the carrot was chased by gullible donkeys.';
    }
    
    function entryDetails(uint index) constant returns (address donkey, string nickName, uint deposit, uint payout, bool paid, string info)
    {
        if (index < entries.length || index == 0 && entries.length > 0) {
            donkey = entries[index].entryAddress;
            nickName = donkeys[entries[index].entryAddress].nickname;
            deposit = entries[index].deposit / 1 finney;
            payout = entries[index].payout / 1 finney;
            paid = entries[index].paid;
            info = 'Entry info: donkey address, name, deposit, expected payout in Finneys, payout status.';
        }
    }
    
    function donkeyRanking(uint index) constant returns(address donkey, string nickname, uint totalInvested, string info)
    {
        if (index < ranking.length)
        {
            donkey = ranking[index].addr;
            nickname = donkeys[ranking[index].addr].nickname;
            totalInvested = donkeys[ranking[index].addr].invested / 1 ether;
            info = 'Top donkey stats: address, name, ethers deposited. Lower index number means higher rank.';
        }
    }
    
    function donkeyInvested(address donkey) constant returns(uint invested, string info) {
        invested = donkeys[donkey].addr != address(0x0) ? donkeys[donkey].invested / 1 ether : 0;
        info = 'The amount of Ethers the donkey has chased carrots with.';
    }
    
    function totalInvested() constant returns(uint invested, string info) {
        invested = donkeysInvested / 1 ether;
        info = 'The combined investments of all donkeys in Ethers.';
    }
    
    function currentDepositLimit() constant returns(uint ethers, string info) {
        ethers = maxDeposit;
        info = 'The current maximum number of Ethers you may deposit at once.';
    }
    
    function donkeysEligibleForFees() constant returns(uint top, string info) {
        top = eligibleForFees;
        info = 'The number of donkeys in the ranking that are eligible to receive fees.';
    }
    
}