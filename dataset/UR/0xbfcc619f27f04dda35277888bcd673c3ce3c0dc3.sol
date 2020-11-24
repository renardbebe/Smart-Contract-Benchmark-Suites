 

pragma solidity ^0.4.8;
	contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public ; }

	  

	contract MetalExchangeToken {
		 
		string public standard = 'Token 0.1';
		string public name;
		string public symbol;
		address public owner;
		uint8 public decimals;
		uint256 public totalSupply;
		bool public nameLocked=false;
		bool public symbolLocked=false;
		bool public ownerLocked=false;	
		uint256 public unholdTime; 

		 
		mapping (address => uint256) public balanceOf;
		mapping (address => uint256) public holdBalanceOf;
		mapping (address => mapping (address => uint256)) public allowance;
		
		 
		mapping (address => uint256) public coordinatorAgreeForEmission;
		mapping (uint256 => address) public coordinatorAccountIndex;
		uint256 public coordinatorAccountCount;
		
		 
		uint256 public minCoordinatorCount;

		 
		event Transfer(address indexed from, address indexed to, uint256 value);
		event Emission(uint256 value);		
		
		event Hold(address indexed from, uint256 value);
		event Unhold(address indexed from, uint256 value);

		 
		event Burn(address indexed from, uint256 value);
		
		modifier canUnhold() { if (block.timestamp >= unholdTime) _; }
		modifier canHold() { if (block.timestamp < unholdTime) _; }

		 
		function MetalExchangeToken() public {
			owner=msg.sender;
			totalSupply = 40000000000;	 				     
			balanceOf[owner] = totalSupply;				 
			name = 'MetalExchangeToken';				 
			symbol = 'MET';								 
			decimals = 4;								 
			unholdTime = 0;								 
			coordinatorAccountCount = 0;
			minCoordinatorCount = 2;
		}
		
		 
		function addCoordinator(address newCoordinator) public {
			if (msg.sender!=owner) revert();
			coordinatorAccountIndex[coordinatorAccountCount]=newCoordinator;
			coordinatorAgreeForEmission[newCoordinator]=0;
			coordinatorAccountCount++;
		}
		
		 
		function removeCoordinator(address coordinator) public {
			if (msg.sender!=owner) revert();
			delete coordinatorAgreeForEmission[coordinator];
			for (uint256 i=0;i<coordinatorAccountCount;i++)
				if (coordinatorAccountIndex[i]==coordinator){
					for (uint256 j=i;j<coordinatorAccountCount-1;j++)
						coordinatorAccountIndex[j]=coordinatorAccountIndex[j+1];
						
					coordinatorAccountCount--;
					delete coordinatorAccountIndex[coordinatorAccountCount];
					i=coordinatorAccountCount;
				}
		}
		
		 
		function coordinatorSetAgreeForEmission(uint256 value_) public {
			bool found=false;
			for (uint256 i=0;i<coordinatorAccountCount;i++)
				if (coordinatorAccountIndex[i]==msg.sender){
					found=true;
					i=coordinatorAccountCount;
				}
			if (!found) revert();
			coordinatorAgreeForEmission[msg.sender]=value_;
			emit(value_);
		}
		
		 
		 
		function emit(uint256 value_) private {
			if (value_ <= 0) revert();
			
			bool found=false;
			if (msg.sender==owner) found=true;
			for (uint256 i=0;(!found)&&(i<coordinatorAccountCount);i++)
				if (coordinatorAccountIndex[i]==msg.sender){
					found=true;
					i=coordinatorAccountCount;
				}
			if (!found) revert();
			
			uint256 agree=0;
			for (i=0;i<coordinatorAccountCount;i++)
				if (coordinatorAgreeForEmission[coordinatorAccountIndex[i]]>=value_)
					agree++;
					
			if (agree<minCoordinatorCount) revert();
			
			for (i=0;i<coordinatorAccountCount;i++)
				if (coordinatorAgreeForEmission[coordinatorAccountIndex[i]]>=value_)
					coordinatorAgreeForEmission[coordinatorAccountIndex[i]]-=value_;
			
			balanceOf[owner] += value_;
			totalSupply += value_;
			Emission(value_);
		}
		
		function lockName() public {
			if (msg.sender!=owner) revert();
			if (nameLocked) revert();
			nameLocked=true;
		}
		
		function changeName(string new_name) public {
			if (msg.sender!=owner) revert();
			if (nameLocked) revert();
			name=new_name;
		}
		
		function lockSymbol() public {
			if (msg.sender!=owner) revert();
			if (symbolLocked) revert();
			symbolLocked=true;
		}
		
		function changeSymbol(string new_symbol) public {
			if (msg.sender!=owner) revert();
			if (symbolLocked) revert();
			symbol=new_symbol;
		}
		
		function lockOwner() public {
			if (msg.sender!=owner) revert();
			if (ownerLocked) revert();
			ownerLocked=true;
		}
		
		function changeOwner(address new_owner) public {
			if (msg.sender!=owner) revert();
			if (ownerLocked) revert();
			owner=new_owner;
		}
		
		 
		function hold(uint256 _value) canHold payable public {
			if (balanceOf[msg.sender] < _value) revert();		   		 
			if (holdBalanceOf[msg.sender] + _value < holdBalanceOf[msg.sender]) revert();  
				balanceOf[msg.sender] -= _value;					 
			holdBalanceOf[msg.sender] += _value;					 
			Hold(msg.sender, _value);				   				 
		}
		
		 
		function unhold(uint256 _value) canUnhold payable public {
			if (holdBalanceOf[msg.sender] < _value) revert();		   	 
			if (balanceOf[msg.sender] + _value < balanceOf[msg.sender]) revert();  
			holdBalanceOf[msg.sender] -= _value;					 
			balanceOf[msg.sender] += _value;						 
			Unhold(msg.sender, _value);				   			 	 
		}

		 
		function transfer(address _to, uint256 _value) payable public {
			if (_to == 0x0) revert();							   		 
			if (balanceOf[msg.sender] < _value) revert();		   		 
			if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 	 
			balanceOf[msg.sender] -= _value;					 	 
			balanceOf[_to] += _value;								 
			Transfer(msg.sender, _to, _value);				   		 
		}

		 
		function approve(address _spender, uint256 _value)
			public
			returns (bool success) {
			allowance[msg.sender][_spender] = _value;
			return true;
		}

		 
		function approveAndCall(address _spender, uint256 _value, bytes _extraData)
			public
			returns (bool success) {
			tokenRecipient spender = tokenRecipient(_spender);
			if (approve(_spender, _value)) {
				spender.receiveApproval(msg.sender, _value, this, _extraData);
				return true;
			}
		}		

		 
		function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
			if (_to == 0x0) revert();									 
			if (balanceOf[_from] < _value) revert();				 	 
			if (balanceOf[_to] + _value < balanceOf[_to]) revert();  	 
			if (_value > allowance[_from][msg.sender]) revert();	 	 
			balanceOf[_from] -= _value;						   		 
			balanceOf[_to] += _value;							 	 
			allowance[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);
			return true;
		}

		function burn(uint256 _value) public returns (bool success) {
			if (balanceOf[msg.sender] < _value) revert();				 
			balanceOf[msg.sender] -= _value;					  	 
			totalSupply -= _value;									 
			Burn(msg.sender, _value);								 
			return true;
		}

		function burnFrom(address _from, uint256 _value) public returns (bool success){
			if (balanceOf[_from] < _value) revert();					 
			if (_value > allowance[_from][msg.sender]) revert();		 
			balanceOf[_from] -= _value;						  		 
			totalSupply -= _value;							   		 
			Burn(_from, _value);									 
			return true;
		}
	}