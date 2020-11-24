 

pragma solidity ^0.4.10;

 
contract IToken {
  function balanceOf(address _address) constant returns (uint balance);
  function transferFromOwner(address _to, uint256 _value) returns (bool success);
}

 
contract TokenEscrow {
	 
	string public standard = 'PBKXToken 0.3';
	string public name = 'PBKXToken';
	string public symbol = 'PBKX';
	uint public decimals = 2;
    	uint public totalSupply = 300000000;
	
	IToken icoToken;
	
	event Converted(address indexed from, uint256 value);  
    	event Transfer(address indexed from, address indexed to, uint256 value);
	event Error(bytes32 error);
	
	mapping (address => uint) balanceFor;  
	
	address owner;   
	
	uint public exchangeRate;  

	 
	struct TokenSupply {
		uint limit;                  
		uint totalSupply;            
		uint tokenPriceInWei;   
	}
	
	TokenSupply[3] public tokenSupplies;

	 
	modifier owneronly { if (msg.sender == owner) _; }

	 
	function setOwner(address _owner) owneronly {
		owner = _owner;
	}
	
	function setRate(uint _exchangeRate) owneronly {
		exchangeRate = _exchangeRate;
	}
	
	function setToken(address _icoToken) owneronly {
		icoToken = IToken(_icoToken);
	}
	
	 
	function balanceOf(address _address) constant returns (uint balance) {
		return balanceFor[_address];
	}
	
	 	
	function transfer(address _to, uint _value) returns (bool success) {
		if(_to != owner) {
			if (balanceFor[msg.sender] < _value) return false;            
			if (balanceFor[_to] + _value < balanceFor[_to]) return false;  
			if (msg.sender == owner) {
				transferByOwner(_value);
			}
			balanceFor[msg.sender] -= _value;                      
			balanceFor[_to] += _value;                             
			Transfer(owner,_to,_value);
			return true;
		}
		return false;
	}
	
	function transferByOwner(uint _value) private {
		for (uint discountIndex = 0; discountIndex < tokenSupplies.length; discountIndex++) {
			TokenSupply storage tokenSupply = tokenSupplies[discountIndex];
			if(tokenSupply.totalSupply < tokenSupply.limit) {
				if (tokenSupply.totalSupply + _value > tokenSupply.limit) {
					_value -= tokenSupply.limit - tokenSupply.totalSupply;
					tokenSupply.totalSupply = tokenSupply.limit;
				} else {
					tokenSupply.totalSupply += _value;
					break;
				}
			}
		}
	}
	
	 	
	function convert() returns (bool success) {
		if (balanceFor[msg.sender] == 0) return false;             
		if (!exchangeToIco(msg.sender)) return false;  
		Converted(msg.sender, balanceFor[msg.sender]);
		balanceFor[msg.sender] = 0;                       
		return true;
	} 
	
	 
	function exchangeToIco(address owner) private returns (bool) {
	    if(icoToken != address(0)) {
		    return icoToken.transferFromOwner(owner, balanceFor[owner] * exchangeRate);
	    }
	    return false;
	}

	 
	function TokenEscrow() {
		owner = msg.sender;
		
		balanceFor[msg.sender] = 300000000;  
		
		 
		tokenSupplies[0] = TokenSupply(100000000, 0, 11428571428571);  
		tokenSupplies[1] = TokenSupply(100000000, 0, 11848341232227);  
		tokenSupplies[2] = TokenSupply(100000000, 0, 12500000000000);  
	
		 
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,875);
		transferByOwner(875);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,2150);
		transferByOwner(2150);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,975);
		transferByOwner(975);
		transferFromOwner(0xa0c6c73e09b18d96927a3427f98ff07aa39539e2,875000);
		transferByOwner(875000);
		transferFromOwner(0xa4a90f8d12ae235812a4770e0da76f5bc2fdb229,3500000);
		transferByOwner(3500000);
		transferFromOwner(0xbd08c225306f6b341ce5a896392e0f428b31799c,43750);
		transferByOwner(43750);
		transferFromOwner(0xf948fc5be2d2fd8a7ee20154a18fae145afd6905,3316981);
		transferByOwner(3316981);
		transferFromOwner(0x23f15982c111362125319fd4f35ac9e1ed2de9d6,2625);
		transferByOwner(2625);
		transferFromOwner(0x23f15982c111362125319fd4f35ac9e1ed2de9d6,5250);
		transferByOwner(5250);
		transferFromOwner(0x6ebff66a68655d88733df61b8e35fbcbd670018e,58625);
		transferByOwner(58625);
		transferFromOwner(0x1aaa29dffffc8ce0f0eb42031f466dbc3c5155ce,1043875);
		transferByOwner(1043875);
		transferFromOwner(0x5d47871df00083000811a4214c38d7609e8b1121,3300000);
		transferByOwner(3300000);
		transferFromOwner(0x30ced0c61ccecdd17246840e0d0acb342b9bd2e6,261070);
		transferByOwner(261070);
		transferFromOwner(0x1079827daefe609dc7721023f811b7bb86e365a8,2051875);
		transferByOwner(2051875);
		transferFromOwner(0x6c0b6a5ac81e07f89238da658a9f0e61be6a0076,10500000);
		transferByOwner(10500000);
		transferFromOwner(0xd16e29637a29d20d9e21b146fcfc40aca47656e5,1750);
		transferByOwner(1750);
		transferFromOwner(0x4c9ba33dcbb5876e1a83d60114f42c949da4ee22,7787500);
		transferByOwner(7787500);
		transferFromOwner(0x0d8cc80efe5b136865b9788393d828fd7ffb5887,100000000);
		transferByOwner(100000000);
	
	}
  
	 
	function() payable {
		
		uint tokenAmount;  
		uint amountToBePaid;  
		uint amountTransfered = msg.value;  
		
		if (amountTransfered <= 0) {
		      	Error('no eth was transfered');
              		msg.sender.transfer(msg.value);
		  	return;
		}

		if(balanceFor[owner] <= 0) {
		      	Error('all tokens sold');
              		msg.sender.transfer(msg.value);
		      	return;
		}
		
		 
		for (uint discountIndex = 0; discountIndex < tokenSupplies.length; discountIndex++) {
			 
			
			TokenSupply storage tokenSupply = tokenSupplies[discountIndex];
			
			if(tokenSupply.totalSupply < tokenSupply.limit) {
			
				uint tokensPossibleToBuy = amountTransfered / tokenSupply.tokenPriceInWei;

                if (tokensPossibleToBuy > balanceFor[owner]) 
                    tokensPossibleToBuy = balanceFor[owner];

				if (tokenSupply.totalSupply + tokensPossibleToBuy > tokenSupply.limit) {
					tokensPossibleToBuy = tokenSupply.limit - tokenSupply.totalSupply;
				}

				tokenSupply.totalSupply += tokensPossibleToBuy;
				tokenAmount += tokensPossibleToBuy;

				uint delta = tokensPossibleToBuy * tokenSupply.tokenPriceInWei;

				amountToBePaid += delta;
                		amountTransfered -= delta;
			
			}
		}
		
		 
		if (tokenAmount == 0) {
		    	Error('no token to buy');
            		msg.sender.transfer(msg.value);
			return;
        	}
		
		 
		transferFromOwner(msg.sender, tokenAmount);

		 
		owner.transfer(amountToBePaid);
		
		 
		msg.sender.transfer(msg.value - amountToBePaid);
	}
  
	 
	function kill() owneronly {
		suicide(msg.sender);
	}
  
	 
	function transferFromOwner(address _to, uint256 _value) private returns (bool success) {
		if (balanceFor[owner] < _value) return false;                  
		if (balanceFor[_to] + _value < balanceFor[_to]) return false;   
		balanceFor[owner] -= _value;                           
		balanceFor[_to] += _value;                             
        	Transfer(owner,_to,_value);
		return true;
	}
  
}