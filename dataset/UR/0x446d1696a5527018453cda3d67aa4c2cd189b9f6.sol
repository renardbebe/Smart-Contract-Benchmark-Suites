 

contract GreedPit {
    
    address private owner;
    
     
    uint private balance = 0;
    uint private uniqueUsers = 0;
    uint private usersProfits = 0;
    uint private rescues = 0;
    uint private collectedFees = 0;
    uint private jumpFee = 10;
    uint private baseMultiplier = 110;
    uint private maxMultiplier = 200;
    uint private payoutOrder = 0;
    uint private rescueRecord = 0;
    uint timeOfLastDeposit = now;
    address private hero = 0x0;
    
    mapping (address => User) private users;
    Entry[] private entries;
    
    event Jump(address who, uint deposit, uint payout);
    event Rescue(address who, address saviour, uint payout);
    event NewHero(address who);
    
     
    function GreedPit() {
        owner = msg.sender;
    }

    modifier onlyowner { if (msg.sender == owner) _ }
    
    struct User {
        uint id;
        address addr;
        string nickname;
        uint rescueCount;
        uint rescueTokens;
    }
    
    struct Entry {
        address entryAddress;
        uint deposit;
        uint payout;
        uint tokens;
    }

     
    function() {
        init();
    }
    
    function init() private{
         
        if (msg.value < 100 finney) {
            return;
        }
        
        jumpIn();
        
         
        if (msg.value > 5)
            timeOfLastDeposit = now;
    }
    
     
    function jumpIn() private {
        
         
		uint dValue = 100 finney;
		if (msg.value > 50 ether) {
		     
		    if (this.balance >= balance + collectedFees + msg.value)
			    msg.sender.send(msg.value - 50 ether);	
			dValue = 50 ether;
		}
		else { dValue = msg.value; }

         
        addNewUser(msg.sender);
        
         
        uint tokensToUse = users[msg.sender].rescueTokens >= 5 ? 5 : users[msg.sender].rescueTokens;
        uint tokensUsed = 0;
        
         
        uint randMultiplier = rand(50);
        uint currentEntries = entries.length - payoutOrder;
        randMultiplier = currentEntries > 15 ? (randMultiplier / 2) : randMultiplier;
        randMultiplier = currentEntries > 25 ? 0 : randMultiplier;
         
        randMultiplier = currentEntries <= 5 && dValue <= 20 ? randMultiplier * 3 / 2 : randMultiplier;
        
         
        while (tokensToUse > 0 && (baseMultiplier + randMultiplier + tokensUsed*10) < maxMultiplier)
        {
            tokensToUse--;
            tokensUsed++;
        }
        
        uint finalMultiplier = (baseMultiplier + randMultiplier + tokensUsed*10);
        
        if (finalMultiplier > maxMultiplier)
            finalMultiplier = maxMultiplier;
            
         
        if (msg.value < 50 ether)
            entries.push(Entry(msg.sender, msg.value, (msg.value * (finalMultiplier) / 100), tokensUsed));
        else
            entries.push(Entry(msg.sender, 50 ether,((50 ether) * (finalMultiplier) / 100), tokensUsed));

         
        if (msg.value < 50 ether)
            Jump(msg.sender, msg.value, (msg.value * (finalMultiplier) / 100));
        else
            Jump(msg.sender, 50 ether, ((50 ether) * (finalMultiplier) / 100));

        users[msg.sender].rescueTokens -= tokensUsed;
        
         
        balance += (dValue * (100 - jumpFee)) / 100;
        collectedFees += (dValue * jumpFee) / 100;
        
        bool saviour = false;
        
         
        while (balance > entries[payoutOrder].payout) {
            
            saviour = false;
            
            uint entryPayout = entries[payoutOrder].payout;
            uint entryDeposit = entries[payoutOrder].deposit;
            uint profit = entryPayout - entryDeposit;
            uint saviourShare = 0;
            
             
            if (users[msg.sender].addr != entries[payoutOrder].entryAddress)
            {
                users[msg.sender].rescueCount++;
                 
                if (entryDeposit >= 1 ether) {
                    users[msg.sender].rescueTokens += dValue < 20 || currentEntries < 15 ? 1 : 2;
                    users[msg.sender].rescueTokens += dValue < 40 || currentEntries < 25 ? 0 : 1;
                }
                saviour = true;
            }
            
            bool isHero = false;
            
            isHero = entries[payoutOrder].entryAddress == hero;
            
             
            if (saviour && !isHero && profit > 20 * entryDeposit / 100 && profit > 100 finney && dValue >= 5 ether)
            {
                if (dValue < 10 ether)
                   saviourShare = 3 + rand(5);
                else if (dValue >= 10 ether && dValue < 25 ether)
                  saviourShare = 7 + rand(8);
                else if (dValue >= 25 ether && dValue < 40 ether)
                   saviourShare = 12 + rand(13);
                else if (dValue >= 40 ether)
                   saviourShare = rand(50);
                   
                saviourShare *= profit / 100;
                   
                msg.sender.send(saviourShare);
            }
            
            uint payout = entryPayout - saviourShare;
            entries[payoutOrder].entryAddress.send(payout);
            
             
            Rescue(entries[payoutOrder].entryAddress, msg.sender, payout);

            balance -= entryPayout;
            usersProfits += entryPayout;
            
            rescues++;
            payoutOrder++;
        }
        
         
        if (saviour && users[msg.sender].rescueCount > rescueRecord)
        {
            rescueRecord = users[msg.sender].rescueCount;
            hero = msg.sender;
             
            NewHero(msg.sender);
        }
    }
    
     
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max + 1;
    }
    
    function addNewUser(address Address) private
    {
        if (users[Address].addr == address(0))
        {
            users[Address].id = ++uniqueUsers;
            users[Address].addr = Address;
            users[Address].nickname = 'UnnamedPlayer';
            users[Address].rescueCount = 0;
            users[Address].rescueTokens = 0;
        }
    }
    
     
    function collectFees() onlyowner {
        if (collectedFees == 0) throw;

        owner.send(collectedFees);
        collectedFees = 0;
    }

     
    function changeOwner(address newOwner) onlyowner {
        owner = newOwner;
    }
    
    function changeBaseMultiplier(uint multi) onlyowner {
        if (multi < 110 || multi > 150) throw;
        
        baseMultiplier = multi;
    }
    
    function changeMaxMultiplier(uint multi) onlyowner {
        if (multi < 200 || multi > 300) throw;
        
        maxMultiplier = multi;
    }
    
    function changeFee(uint fee) onlyowner {
        if (fee < 0 || fee > 10) throw;
        
        jumpFee = fee;
    }
    
    
     
    function setNickname(string name) {
        addNewUser(msg.sender);
        
        if (bytes(name).length >= 2 && bytes(name).length <= 16)
            users[msg.sender].nickname = name;
    }
    
    function currentBalance() constant returns (uint pitBalance, string info) {
        pitBalance = balance / 1 finney;
        info = 'The balance of the pit in Finneys (contract balance minus fees).';
    }
    
    function heroOfThePit() constant returns (address theHero, string nickname, uint peopleSaved, string info) {
        theHero = hero;  
        nickname = users[theHero].nickname;
        peopleSaved = rescueRecord;
        info = 'The current rescue record holder. All hail!';
    }
    
    function userName(address Address) constant returns (string nickname) {
        nickname = users[Address].nickname;
    }
    
    function totalRescues() constant returns (uint rescueCount, string info) {
        rescueCount = rescues;
        info = 'The number of times that people have been rescued from the pit (aka the number of times people made a profit).';
    }
    
    function multipliers() constant returns (uint BaseMultiplier, uint MaxMultiplier, string info) {
        BaseMultiplier = baseMultiplier;
        MaxMultiplier = maxMultiplier;
        info = 'The multipliers applied to all deposits: the final multiplier is a random number between the multpliers shown divided by 100. By default x1.1~x1.5 (up to x2 if rescue tokens are used, granting +0.1 per token). It determines the amount of money you will get when rescued (a saviour share might be deducted).';
    }
    
    function pitFee() constant returns (uint feePercentage, string info) {
        feePercentage = jumpFee;
        info = 'The fee percentage applied to all deposits. It can change to speed payouts (max 10%).';
    }
    
    function nextPayoutGoal() constant returns (uint finneys, string info) {
        finneys = (entries[payoutOrder].payout - balance) / 1 finney;
        info = 'The amount of Finneys (Ethers * 1000) that need to be deposited for the next payout to be executed.';
    }
    
    function unclaimedFees() constant returns (uint ethers, string info) {
        ethers = collectedFees / 1 ether;
        info = 'The amount of Ethers obtained through fees that have not yet been collected by the owner.';
    }
    
    function totalEntries() constant returns (uint count, string info) {
        count = entries.length;
        info = 'The number of times that people have jumped into the pit.';
    }
    
    function totalUsers() constant returns (uint users, string info) {
        users = uniqueUsers;
        info = 'The number of unique users that have joined the pit.';
    }
    
    function awaitingPayout() constant returns (uint count, string info) {
        count = entries.length - payoutOrder;
        info = 'The number of people waiting to be saved.';
    }
    
    function entryDetails(uint index) constant returns (address user, string nickName, uint deposit, uint payout, uint tokensUsed, string info)
    {
        if (index <= entries.length) {
            user = entries[index].entryAddress;
            nickName = users[entries[index].entryAddress].nickname;
            deposit = entries[index].deposit / 1 finney;
            payout = entries[index].payout / 1 finney;
            tokensUsed = entries[index].tokens;
            info = 'Entry info: user address, name, expected payout in Finneys (approximate), rescue tokens used.';
        }
    }
    
    function userId(address user) constant returns (uint id, string info) {
        id = users[user].id;
        info = 'The id of the user, represents the order in which he first joined the pit.';
    }
    
    function userTokens(address user) constant returns (uint tokens, string info) {
        tokens = users[user].addr != address(0x0) ? users[user].rescueTokens : 0;
        info = 'The number of Rescue Tokens the user has. Tokens are awarded when your deposits save people, and used automatically on your next deposit. They provide a 0.1 multiplier increase per token. (+0.5 max)';
    }
    
    function userRescues(address user) constant returns(uint rescueCount, string info) {
        rescueCount = users[user].addr != address(0x0) ? users[user].rescueCount : 0;
        info = 'The number of times the user has rescued someone from the pit.';
    }
    
    function userProfits() constant returns(uint profits, string info) {
        profits = usersProfits / 1 finney;
        info = 'The combined earnings of all users in Finney.';
    }
    
     
    function recycle() onlyowner
    {
        if (now >= timeOfLastDeposit + 10 weeks) 
        { 
             
            if (balance > 0) 
            {
                entries[0].entryAddress.send(balance);
            }
            
             
            selfdestruct(owner);
        }
    }
}