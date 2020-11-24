 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 

contract ERC20Standard {
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	 
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) onlyPayloadSize(2*32) {
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_recipient] += _value;
	    Transfer(msg.sender, _recipient, _value);        
    }

	function transferFrom(address _from, address _to, uint _value) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

	function approve(address _spender, uint _value) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) constant returns (uint balance) {
		return allowed[_owner][_spender];
	}

	 
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	 
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);

}

 
 
 
 

contract FAMEToken is ERC20Standard {

	function FAMEToken() {
		totalSupply = 2100000 szabo;			 
		name = "Fame";							 
		decimals = 12;							 
		symbol = "FAM";							 
		version = "FAME1.0";					 
		balances[msg.sender] = totalSupply;		 
	}

	 
	 
	function burn(uint _value) {
		require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
	}

	 
	event Burn(
		address indexed _owner,
		uint _value
		);

}

 
 
 
 
 
 
 
 
 
 

contract BattleDromeICO {
	uint public constant ratio = 100 szabo;				 
	uint public constant minimumPurchase = 1 finney;	 
	uint public constant startBlock = 3960000;			 
	uint public constant duration = 190000;				 
	uint public constant fundingGoal = 500 ether;		 
	uint public constant fundingMax = 20000 ether;		 
	uint public constant devRatio = 20;					 
	address public constant tokenAddress 	= 0x190e569bE071F40c704e15825F285481CB74B6cC;	 
	address public constant escrow 			= 0x50115D25322B638A5B8896178F7C107CFfc08144;	 

	FAMEToken public Token;
	address public creator;
	uint public savedBalance;
	bool public creatorPaid = false;			 

	mapping(address => uint) balances;			 
	mapping(address => uint) savedBalances;		 

	 
	function BattleDromeICO() {
		Token = FAMEToken(tokenAddress);				 
		creator = msg.sender;							 
	}

	 
	 
	 
	function () payable {
		contribute();
	}

	 
	function contribute() payable {
		require(isStarted());								 
		require(this.balance<=fundingMax); 					 
		require(msg.value >= minimumPurchase);               
		require(!isComplete()); 							 
		balances[msg.sender] += msg.value;					 
		savedBalances[msg.sender] += msg.value;		    	 
		savedBalance += msg.value;							 
		Contribution(msg.sender,msg.value,now);              
	}

	 
	function tokenBalance() constant returns(uint balance) {
		return Token.balanceOf(address(this));
	}

	 
	function isStarted() constant returns(bool) {
		return block.number >= startBlock;
	}

	 
	function isComplete() constant returns(bool) {
		return (savedBalance >= fundingMax) || (block.number > (startBlock + duration));
	}

	 
	function isSuccessful() constant returns(bool) {
		return (savedBalance >= fundingGoal);
	}

	 
	function checkEthBalance(address _contributor) constant returns(uint balance) {
		return balances[_contributor];
	}

	 
	function checkSavedEthBalance(address _contributor) constant returns(uint balance) {
		return savedBalances[_contributor];
	}

	 
	function checkTokBalance(address _contributor) constant returns(uint balance) {
		return (balances[_contributor] * ratio) / 1 ether;
	}

	 
	function checkTokSold() constant returns(uint total) {
		return (savedBalance * ratio) / 1 ether;
	}

	 
	function checkTokDev() constant returns(uint total) {
		return checkTokSold() / devRatio;
	}

	 
	function checkTokTotal() constant returns(uint total) {
		return checkTokSold() + checkTokDev();
	}

	 
	function percentOfGoal() constant returns(uint16 goalPercent) {
		return uint16((savedBalance*100)/fundingGoal);
	}

	 
	function payMe() {
		require(isComplete());  
		if(isSuccessful()) {
			payTokens();
		}else{
			payBack();
		}
	}

	 
	function payBack() internal {
		require(balances[msg.sender]>0);						 
		balances[msg.sender] = 0;								 
		msg.sender.transfer(savedBalances[msg.sender]);			 
		PayEther(msg.sender,savedBalances[msg.sender],now); 	 
	}

	 
	function payTokens() internal {
		require(balances[msg.sender]>0);					 
		uint tokenAmount = checkTokBalance(msg.sender);		 
		balances[msg.sender] = 0;							 
		Token.transfer(msg.sender,tokenAmount);				 
		PayTokens(msg.sender,tokenAmount,now);          	 
	}

	 
	function payCreator() {
		require(isComplete());										 
		require(!creatorPaid);										 
		creatorPaid = true;											 
		if(isSuccessful()){
			uint tokensToBurn = tokenBalance() - checkTokTotal();	 
			PayEther(escrow,this.balance,now);      				 
			escrow.transfer(this.balance);							 
			PayTokens(creator,checkTokDev(),now);       			 
			Token.transfer(creator,checkTokDev());					 
			Token.burn(tokensToBurn);								 
			BurnTokens(tokensToBurn,now);        					 
		}else{
			PayTokens(creator,tokenBalance(),now);       			 
			Token.transfer(creator,tokenBalance());					 
		}
	}
	
	 
	event Contribution(
	    address indexed _contributor,
	    uint indexed _value,
	    uint indexed _timestamp
	    );
	    
	 
	event PayTokens(
	    address indexed _receiver,
	    uint indexed _value,
	    uint indexed _timestamp
	    );

	 
	event PayEther(
	    address indexed _receiver,
	    uint indexed _value,
	    uint indexed _timestamp
	    );
	    
	 
	event BurnTokens(
	    uint indexed _value,
	    uint indexed _timestamp
	    );

}