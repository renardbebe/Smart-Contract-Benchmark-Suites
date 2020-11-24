 

pragma solidity ^0.4.10;


 
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

 
contract HonestisNetworkETHmergedICO {
    string public constant name = "ICO token Honestis.Network on ETH";
    string public constant symbol = "HNT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;
     
    uint256 public constant tokenCreationCap = 66200 ether * tokenCreationRate;
    uint256 public constant tokenCreationMinConversion = 1 ether * tokenCreationRate;


   

  
   
  uint256 public constant oneweek = 41883;
   uint256 public constant oneday = 5983;
    uint256 public constant onehour = 248;
	 uint256 public constant onemonth = 179501;
	 uint256 public constant fourweeks= 167534;
    uint256 public fundingStartBlock = 4663338; 

	 
    uint256 public fundingEndBlock = fundingStartBlock+fourweeks;

	
     
    bool public funding = true;
	bool public migratestate = false;
	bool public finalstate = false;
	
     
    address public honestisFort = 0xF03e8E4cbb2865fCc5a02B61cFCCf86E9aE021b5;
	address public honestisFortbackup =0xC4e901b131cFBd90F563F0bB701AE2f8e83c5589;
     
    address public migrationMaster = 0x0f32f4b37684be8a1ce1b2ed765d2d893fa1b419;


     
	 
    uint256 totalTokens =61168800 ether;
	uint256 bonusCreationRate;
    mapping (address => uint256) balances;
    mapping (address => uint256) balancesRAW;


	address public migrationAgent=0x0f32f4b37684be8a1ce1b2ed765d2d893fa1b419;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function HonestisNetworkETHmergedICO() {
 
balances[0x2e7C01CBB983B99D41b9022776928383A02d4C1a]=351259197900000000000000;
 
balances[0x0F32f4b37684be8A1Ce1B2Ed765d2d893fa1b419]=2000000000000000000000000;
 
balances[0xa4B61E0c28F6d0823B5D98D3c9BB3f925a5416B1]=3468820800000000000000000;
 
balances[0x5AB6e1842B5B705835820b9ab02e38b37Fac071a]=2000000000000000000000000;
 
balances[0x40efcf00282B580c468BCD93B84B7CE125fA62Cc]=53348720000000000000000000;
 
balances[0xD00aA14f4E5D651f29cE27426559eC7c39b14B3e]=5588000000000000000000;

    }

     
     
     
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool) {

 
if ((msg.sender!=migrationMaster)&&(block.number < fundingEndBlock + oneweek)) throw;

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
 
         
        if (msg.value == 0) throw;
		 
		 
		bonusCreationRate = 250;
        if (msg.value > (tokenCreationCap - totalTokens) / bonusCreationRate)
          throw;
		
		 
		bonusCreationRate = tokenCreationRate;


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
         
	
	
		 
	 
		if (block.number < (fundingStartBlock + 2*oneday )){
		 balances[migrationMaster] = balances[migrationMaster]-  additionalTokens/2;
		  balances[holder] +=  additionalTokens/2;
        Transfer(0, holder, additionalTokens/2);
		Transfer(0, migrationMaster, additionalTokens/2);
		} else {
		
		  Transfer(0, migrationMaster, additionalTokens);
		}
		
	}
	
	    

        
    function shifter2HNtokens(address _to, uint256 _value) returns (bool) {
       if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
 
if (msg.sender!=migrationMaster) throw;
		 
         

        if (totalTokens +  _value < tokenCreationCap){
			totalTokens += _value;
            balances[_to] += _value;
            Transfer(0, _to, _value);
			
			        uint256 percentOfTotal = 14;
        uint256 additionalTokens = 	_value * percentOfTotal / (100);

        totalTokens += additionalTokens;

        balances[migrationMaster] += additionalTokens;
        Transfer(0, migrationMaster, additionalTokens);
			
            return true;
        }
        return false;
    }


     
    function part20Transfer() external {
         if (msg.sender != honestisFort) throw;
         honestisFort.transfer(this.balance - 0.1 ether);
    }
	
    function Partial20Send() external {
	      if (msg.sender != honestisFort) throw;
        honestisFort.send(this.balance - 0.1 ether);
	}
	function funding() external {
	      if (msg.sender != honestisFort) throw;
	funding=!funding;
        }
    function turnmigrate() external {
	      if (msg.sender != migrationMaster) throw;
	migratestate=!migratestate;
}

    function just10Send() external {
	      if (msg.sender != honestisFort) throw;
        honestisFort.send(10 ether);
	}

	function just50Send() external {
	      if (msg.sender != honestisFort) throw;
        honestisFort.send(50 ether);
	}
	
     
function finalize() external {
 if ((msg.sender != honestisFort)||(msg.sender != migrationMaster)) throw;
     
         
        funding = false;		
		finalstate= true;
		if (!honestisFort.send(this.balance)) throw;
 }	
function finalizebackup() external {
        if (block.number <= fundingEndBlock+oneweek) throw;
         
        funding = false;	
		finalstate= true;		
         
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
	

function HonestisnetworkICOregulations() external returns(string wow) {
	return 'Regulations of preICO and ICO are present at website  honestis.network and by using this smartcontract you commit that you accept and will follow those rules';
}

function HonestisnetworkICObalances() external returns(string balancesFORM) {
	return 'if you are contributor before merge visit honestis.network/balances.xls to find your balance which will be deployed if have some suggestions please email us <a class="__cf_email__" data-cfemail="d8abada8a8b7aaac98b0b7b6bdabacb1abf6b6bdacafb7aab3" href="/cdn-cgi/l/email-protection">[email protected]</a> and whitelist this email';
}
}