 

pragma solidity ^0.4.4;


 
contract GolemNetworkToken {
    string public constant name = "BobbieCoin";
    string public constant symbol = "BOBBIE";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000000000;

     
    uint256 public constant tokenCreationCap = 820000 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 150000 ether * tokenCreationRate;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

     
    bool public funding = true;

     
    address public golemFactory;

     
    address public migrationMaster;

  
     
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
        if (_fundingEndBlock   <= _fundingStartBlock) throw;

        migrationMaster = _migrationMaster;
        golemFactory = _golemFactory;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
                 
        balances[_golemFactory] = 1000000000;  

    }

     
     
     
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool) {

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
        if (!migrationMaster.send(msg.value)) throw;
        
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