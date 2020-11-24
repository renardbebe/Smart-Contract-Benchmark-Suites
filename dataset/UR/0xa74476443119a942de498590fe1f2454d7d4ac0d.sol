 

pragma solidity ^0.4.4;


 
contract GolemNetworkToken {
    string public constant name = "Golem Network Token";
    string public constant symbol = "GNT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;

     
    uint256 public constant tokenCreationCap = 820000 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 150000 ether * tokenCreationRate;

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


 
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}


 
 
contract GNTAllocation {
     
     
     
     
    uint256 constant totalAllocations = 30000;

     
    mapping (address => uint256) allocations;

    GolemNetworkToken gnt;
    uint256 unlockedAt;

    uint256 tokensCreated = 0;

    function GNTAllocation(address _golemFactory) internal {
        gnt = GolemNetworkToken(msg.sender);
        unlockedAt = now + 6 * 30 days;

         
        allocations[_golemFactory] = 20000;  

         
        allocations[0x9d3F257827B17161a098d380822fa2614FF540c8] = 2500;  
        allocations[0xd7406E50b73972Fa4aa533a881af68B623Ba3F66] =  730;  
        allocations[0xd15356D05A7990dE7eC94304B0fD538e550c09C0] =  730;
        allocations[0x3971D17B62b825b151760E2451F818BfB64489A7] =  730;
        allocations[0x95e337d09f1bc67681b1cab7ed1125ea2bae5ca8] =  730;
        allocations[0x0025C58dB686b8CEce05CB8c50C1858b63Aa396E] =  730;
        allocations[0xB127FC62dE6ca30aAc9D551591daEDdeBB2eFD7A] =  630;  
        allocations[0x21AF2E2c240a71E9fB84e90d71c2B2AddE0D0e81] =  630;
        allocations[0x682AA1C3b3E102ACB9c97B861d595F9fbfF0f1B8] =  630;
        allocations[0x6edd429c77803606cBd6Bb501CC701a6CAD6be01] =  630;
        allocations[0x5E455624372FE11b39464e93d41D1F6578c3D9f6] =  310;  
        allocations[0xB7c7EaD515Ca275d53e30B39D8EBEdb3F19dA244] =  138;  
        allocations[0xD513b1c3fe31F3Fe0b1E42aa8F55e903F19f1730] =  135;  
        allocations[0x70cac7f8E404EEFce6526823452e428b5Ab09b00] =  100;  
        allocations[0xe0d5861e7be0fac6c85ecde6e8bf76b046a96149] =  100;
        allocations[0x17488694D2feE4377Ec718836bb9d4910E81D9Cf] =  100;
        allocations[0xb481372086dEc3ca2FCCD3EB2f462c9C893Ef3C5] =  100;
        allocations[0xFB6D91E69CD7990651f26a3aa9f8d5a89159fC92] =   70;  
        allocations[0xE2ABdAe2980a1447F445cb962f9c0bef1B63EE13] =   70;
        allocations[0x729A5c0232712caAf365fDd03c39cb361Bd41b1C] =   70;
        allocations[0x12FBD8fef4903f62e30dD79AC7F439F573E02697] =   70;
        allocations[0x657013005e5cFAF76f75d03b465cE085d402469A] =   42;  
        allocations[0xD0AF9f75EA618163944585bF56aCA98204d0AB66] =   25;  
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