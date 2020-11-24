 

pragma solidity ^0.4.8;
 
contract ProspectorsObligationToken {
    string public constant name = "Prospectors Obligation Token";
    string public constant symbol = "OBG";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;

     
    uint256 public constant tokenCreationCap = 1 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 0.5 ether * tokenCreationRate;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

     
    bool public funding = true;

     
    address public prospectors_team;

     
    address public migrationMaster;

    OBGAllocation lockedAllocation;

     
    uint256 totalTokens;

    mapping (address => uint256) balances;

    address public migrationAgent;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function ProspectorsObligationToken() {

         
         
         
         

         
         
         
         
         
        
        prospectors_team = 0xCCe6DA2086DD9348010a2813be49E58530852b46;
        migrationMaster = 0xCCe6DA2086DD9348010a2813be49E58530852b46;
        fundingStartBlock = block.number + 10;
        fundingEndBlock = block.number + 30;
        lockedAllocation = new OBGAllocation(prospectors_team);
        
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

     

     
     
     
    function () payable external {
         
         
         
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

         
        if (!prospectors_team.send(this.balance)) throw;
    }

     
     
     
    function refund() external {
         
        if (!funding) throw;
        if (block.number <= fundingEndBlock) throw;
        if (totalTokens >= tokenCreationMin) throw;

        var obgValue = balances[msg.sender];
        if (obgValue == 0) throw;
        balances[msg.sender] = 0;
        totalTokens -= obgValue;

        var ethValue = obgValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }
	
	function kill()
	{
	    lockedAllocation.kill();
		suicide(prospectors_team);
	}
}


 
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}


 
 
contract OBGAllocation {
     
     
     
     
    uint256 constant totalAllocations = 30000;

     
    mapping (address => uint256) allocations;

    ProspectorsObligationToken obg;
    uint256 unlockedAt;

    uint256 tokensCreated = 0;

    function OBGAllocation(address _prospectors_team) internal {
        obg = ProspectorsObligationToken(msg.sender);
        unlockedAt = now + 6 * 30 days;

         
        allocations[_prospectors_team] = 30000;  
    }

     
     
    function unlock() external {
        if (now < unlockedAt) throw;

         
        if (tokensCreated == 0)
            tokensCreated = obg.balanceOf(this);

        var allocation = allocations[msg.sender];
        allocations[msg.sender] = 0;
        var toTransfer = tokensCreated * allocation / totalAllocations;

         
        if (!obg.transfer(msg.sender, toTransfer)) throw;
    }
	function kill()
	{
		suicide(0);
	}
}