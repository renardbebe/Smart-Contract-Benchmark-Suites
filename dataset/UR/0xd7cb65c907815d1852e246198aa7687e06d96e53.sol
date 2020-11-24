 

pragma solidity ^0.4.10;


 
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

 
contract HonestisNetworkETHpreICO {
    string public constant name = "preICO seed for Honestis.Network on ETH";
    string public constant symbol = "HNT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;
     
    uint256 public constant tokenCreationCap = 66200 ether * tokenCreationRate;
    uint256 public constant tokenCreationMinConversion = 1 ether * tokenCreationRate;
	uint256 public constant tokenSEEDcap = 2.3 * 125 * 1 ether * tokenCreationRate;
	uint256 public constant token3MstepCAP = tokenSEEDcap + 10000 * 1 ether * tokenCreationRate;
	uint256 public constant token10MstepCAP = token3MstepCAP + 22000 * 1 ether * tokenCreationRate;

   
   uint256 public constant oneweek = 36000;
   uint256 public constant oneday = 5136;
    uint256 public constant onehour = 214;
	
    uint256 public fundingStartBlock = 3962754 + 4*onehour;
	 
    uint256 public fundingEndBlock = fundingStartBlock+14*oneweek;

	
     
    bool public funding = true;
	bool public refundstate = false;
	bool public migratestate = false;
	
     
    address public honestisFort = 0xF03e8E4cbb2865fCc5a02B61cFCCf86E9aE021b5;
	address public honestisFortbackup =0x13746D9489F7e56f6d2d8676086577297FC0B492;
     
    address public migrationMaster = 0x8585D5A25b1FA2A0E6c3BcfC098195bac9789BE2;

   
     
    uint256 totalTokens;
	uint256 bonusCreationRate;
    mapping (address => uint256) balances;
    mapping (address => uint256) balancesRAW;


	address public migrationAgent=0x8585D5A25b1FA2A0E6c3BcfC098195bac9789BE2;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function HonestisNetworkETHpreICO() {

        if (honestisFort == 0) throw;
        if (migrationMaster == 0) throw;
        if (fundingEndBlock   <= fundingStartBlock) throw;

    }

     
     
     
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool) {

 
if ((msg.sender!=migrationMaster)&&(block.number < fundingEndBlock + 73000)) throw;

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

	function() payable {
    if(funding){
   createHNtokens(msg.sender);
   }
}

      

        function createHNtokens(address holder) payable {

        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;

         
        if (msg.value == 0) throw;
		 
        if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
          throw;
		
		 
		bonusCreationRate = tokenCreationRate;
		 
        if (totalTokens < tokenSEEDcap) bonusCreationRate = tokenCreationRate +500;
	
		 
		if (block.number > (fundingStartBlock + 6*oneweek +2*oneday)) {
			bonusCreationRate = tokenCreationRate - 200; 
		if	(totalTokens > token3MstepCAP){bonusCreationRate = tokenCreationRate - 300;} 
		if	(totalTokens > token10MstepCAP){bonusCreationRate = tokenCreationRate - 250;}  
		}
	 
	 
		if (block.number < (fundingStartBlock + 5*oneweek )){
		bonusCreationRate = bonusCreationRate + (fundingStartBlock+5*oneweek-block.number)/(5*oneweek)*800;
		}
		

	 var numTokensRAW = msg.value * tokenCreationRate;

        var numTokens = msg.value * bonusCreationRate;
        totalTokens += numTokens;

         
        balances[holder] += numTokens;
        balancesRAW[holder] += numTokensRAW;
         
        Transfer(0, holder, numTokens);
		
		 
        uint256 percentOfTotal = 14;
        uint256 additionalTokens = 	numTokens * percentOfTotal / (100);

        totalTokens += additionalTokens;

        balances[migrationMaster] += additionalTokens;
        Transfer(0, migrationMaster, additionalTokens);
	
	}

    function Partial23Transfer() external {
         honestisFort.transfer(this.balance - 1 ether);
    }
	
    function Partial23Send() external {
	      if (msg.sender != honestisFort) throw;
        honestisFort.send(this.balance - 1 ether);
	}
	function turnrefund() external {
	      if (msg.sender != honestisFort) throw;
	refundstate=!refundstate;
        }
    function turnmigrate() external {
	      if (msg.sender != migrationMaster) throw;
	migratestate=!migratestate;
}

     
	
function finalizebackup() external {
        if (block.number <= fundingEndBlock+oneweek) throw;
         
        funding = false;		
         
        if (!honestisFortbackup.send(this.balance)) throw;
    }
    function migrate(uint256 _value) external {
         
        if (migratestate) throw;


         
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }
	
function refundTRA() external {
         
        if (!refundstate) throw;

        var HNTokenValue = balances[msg.sender];
        var HNTokenValueRAW = balancesRAW[msg.sender];
        if (HNTokenValueRAW == 0) throw;
        balancesRAW[msg.sender] = 0;
        totalTokens -= HNTokenValue;
        var ETHValue = HNTokenValueRAW / tokenCreationRate;
        Refund(msg.sender, ETHValue);
        msg.sender.transfer(ETHValue);
}

function preICOregulations() external returns(string wow) {
	return 'Regulations of preICO are present at website  honestis.network and by using this smartcontract you commit that you accept and will follow those rules';
}
}