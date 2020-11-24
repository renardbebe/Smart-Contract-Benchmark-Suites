 

pragma solidity ^0.4.2;

 
 
contract GNTAllocation {
     
     
     
     
    uint256 constant totalAllocations = 30000;

     
    mapping (address => uint256) allocations;

    GolemNetworkToken gnt;
    uint256 unlockedAt;

    uint256 tokensCreated = 0;

    function GNTAllocation(address _golemFactory) internal {
        gnt = GolemNetworkToken(msg.sender);
        unlockedAt = now + 30 minutes;

         
        allocations[_golemFactory] = 20000;  

         
        allocations[0x3F4e79023273E82EfcD8B204fF1778e09df1a597] = 2500;  
        allocations[0x1A5218B6E5C49c290745552481bb0335be2fB0F4] =  730;  
        allocations[0x00eA32D8DAe74c01eBe293C74921DB27a6398D57] =  730;
        allocations[0xde03] =  730;
        allocations[0xde04] =  730;
        allocations[0xde05] =  730;
        allocations[0xde06] =  630;  
        allocations[0xde07] =  630;
        allocations[0xde08] =  630;
        allocations[0xde09] =  630;
        allocations[0xde10] =  310;  
        allocations[0xde11] =  153;  
        allocations[0xde12] =  150;  
        allocations[0xde13] =  100;  
        allocations[0xde14] =  100;
        allocations[0xde15] =  100;
        allocations[0xde16] =   70;  
        allocations[0xde17] =   70;
        allocations[0xde18] =   70;
        allocations[0xde19] =   70;
        allocations[0xde20] =   70;
        allocations[0xde21] =   42;  
        allocations[0xde22] =   25;  
    }

     
     
    function unlock() external {
        if (now < unlockedAt) throw;

         
        if (tokensCreated == 0)
            tokensCreated = gnt.balanceOf(this);

        var allocation = allocations[msg.sender];
        allocations[msg.sender] = 0;
        var toTransfer = tokensCreated * allocation / totalAllocations;

         
        if (!gnt.transfer(msg.sender, toTransfer)) throw;
    }
}

 
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

 
contract GolemNetworkToken {
    string public constant name = "Test Network Token";
    string public constant symbol = "TNT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;

     
    uint256 public constant tokenCreationCap = 3 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 1 ether * tokenCreationRate;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

     
    bool public funding = true;

     
    address public golemFactory;

     
    address public migrationMaster;

    GNTAllocation lockedAllocation;

     
    uint256 totalTokens;

    mapping (address => uint256) balances;

    address public migrationAgent;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function GolemNetworkToken(address _golemFactory,
                               address _migrationMaster,
                               uint256 _fundingStartBlock,
                               uint256 _fundingEndBlock) {

        if (_golemFactory == 0) throw;
        if (_migrationMaster == 0) throw;
        if (_fundingStartBlock <= block.number) throw;
        if (_fundingEndBlock   <= _fundingStartBlock) throw;

        lockedAllocation = new GNTAllocation(_golemFactory);
        migrationMaster = _migrationMaster;
        golemFactory = _golemFactory;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }

     
     
     
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool) {
         
        if (funding) throw;

        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

     

     
     
     
    function migrate(uint256 _value) external {
         
        if (funding) throw;
        if (migrationAgent == 0) throw;

         
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

     
	 
     
     
     
    function setMigrationAgent(address _agent) external {
         
        if (funding) throw;
        if (migrationAgent != 0) throw;
        if (msg.sender != migrationMaster) throw;
        migrationAgent = _agent;
    }

    function setMigrationMaster(address _master) external {
        if (msg.sender != migrationMaster) throw;
        if (_master == 0) throw;
        migrationMaster = _master;
    }

     

     
     
     
    function create() payable external {
         
         
         
        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;

         
        if (msg.value == 0) throw;
        if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
            throw;

        var numTokens = msg.value * tokenCreationRate;
        totalTokens += numTokens;

         
        balances[msg.sender] += numTokens;

         
        Transfer(0, msg.sender, numTokens);
    }

     
     
     
     
     
     
    function finalize() external {
         
        if (!funding) throw;
        if ((block.number <= fundingEndBlock ||
             totalTokens < tokenCreationMin) &&
            totalTokens < tokenCreationCap) throw;

         
        funding = false;

         
         
         
         
        uint256 percentOfTotal = 18;
        uint256 additionalTokens =
            totalTokens * percentOfTotal / (100 - percentOfTotal);
        totalTokens += additionalTokens;
        balances[lockedAllocation] += additionalTokens;
        Transfer(0, lockedAllocation, additionalTokens);

         
        if (!golemFactory.send(this.balance)) throw;
    }

     
     
     
    function refund() external {
         
        if (!funding) throw;
        if (block.number <= fundingEndBlock) throw;
        if (totalTokens >= tokenCreationMin) throw;

        var gntValue = balances[msg.sender];
        if (gntValue == 0) throw;
        balances[msg.sender] = 0;
        totalTokens -= gntValue;

        var ethValue = gntValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }
}