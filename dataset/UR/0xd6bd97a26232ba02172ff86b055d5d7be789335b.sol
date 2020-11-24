 

contract TokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
} 

contract IERC20Token {     

	 
	function totalSupply() constant returns (uint256 totalSupply);     

	 
	 
	function balanceOf(address _owner) constant returns (uint256 balance) {}     

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) returns (bool success) {}     

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}     

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) returns (bool success) {}     

	 
	 
	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}       

	event Transfer(address indexed _from, address indexed _to, uint256 _value);     
	event Approval(address indexed _owner, address indexed _spender, uint256 _value); 
} 

contract OrmeCash is IERC20Token {         
  
	string public name = "OrmeCash";
	string public symbol = "OMC";
	uint8 public decimals = 18;
	uint256 public tokenFrozenUntilBlock;
	address public owner;
	uint public mintingCap = 2000000000 * 10**18;
   
	uint256 supply = 0;
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowances;
	mapping (address => bool) restrictedAddresses;
   
	event Mint(address indexed _to, uint256 _value);
	event Burn(address indexed _from, uint256 _value);
	event TokenFrozen(uint256 _frozenUntilBlock);

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function OrmeCash() public {
		restrictedAddresses[0x0] = true;
		restrictedAddresses[address(this)] = true;
		owner = msg.sender;
	}         
  
	function totalSupply() constant public returns (uint256 totalSupply) {         
		return supply;     
	}         

	function balanceOf(address _owner) constant public returns (uint256 balance) {         
		return balances[_owner];     
	}     
 
	function transfer(address _to, uint256 _value) public returns (bool success) {     	
		require (block.number >= tokenFrozenUntilBlock);
		require (!restrictedAddresses[_to]);
		require (balances[msg.sender] >= _value);
		require (balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);       
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {     	
		require (block.number >= tokenFrozenUntilBlock);
		allowances[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;     
	}     

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {            
		TokenRecipient spender = TokenRecipient(_spender);      
		approve(_spender, _value);
		spender.receiveApproval(msg.sender, _value, this, _extraData);    
		return true;     
	}     

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {     	
		require (block.number >= tokenFrozenUntilBlock);
		require (!restrictedAddresses[_to]);
		require (balances[_from] >= _value); 
		require (balances[_to] + _value >= balances[_to]);     
		require (_value <= allowances[_from][msg.sender]);     
		balances[_from] -= _value;
		balances[_to] += _value;    
		allowances[_from][msg.sender] -= _value; 
		Transfer(_from, _to, _value);  
		return true;
	}         

	function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {         
		return allowances[_owner][_spender];     
	}         
    
	function mintTokens(address _to, uint256 _amount) onlyOwner public {
		require (!restrictedAddresses[_to]);
		require (_amount != 0);
		require (balances[_to] + _amount > balances[_to]);
		require (mintingCap >= supply + _amount);
		supply += _amount;
		balances[_to] += _amount;
		Mint(_to, _amount);
		Transfer(0x0, _to, _amount);
	}

	function burnTokens(uint _amount) public {
		require(_amount <= balanceOf(msg.sender));
		supply -= _amount;
		balances[msg.sender] -= _amount;
		Transfer(msg.sender, 0x0, _amount);
		Burn(msg.sender, _amount);
	}

	function freezeTransfersUntil(uint256 _frozenUntilBlock) onlyOwner public {     	
		tokenFrozenUntilBlock = _frozenUntilBlock;     	
		TokenFrozen(_frozenUntilBlock);     
	}     

	function editRestrictedAddress(address _newRestrictedAddress) onlyOwner public {
		restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
	}

	function isRestrictedAddress(address _querryAddress) constant public returns (bool answer){
		return restrictedAddresses[_querryAddress];
	}

	function transferOwnership(address newOwner) onlyOwner public {
		owner = newOwner;
	}

	function killContract() onlyOwner public {
		selfdestruct(msg.sender);
	}
}