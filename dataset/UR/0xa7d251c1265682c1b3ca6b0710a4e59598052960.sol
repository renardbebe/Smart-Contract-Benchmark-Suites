 

 


pragma solidity ^0.4.21;
contract Token {
     
    function totalSupply() constant public returns (uint256 supply) {}
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance) {}
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {}
     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    address public owner;  
	 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 
			&& balances[_to] + _value > balances[_to]) {   
            balances[msg.sender] -= _value;
            balances[_to] += _value;
             
            emit Transfer(msg.sender, _to, _value);  
            return true;
        } else { return false; }
    }
	 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 
			&& balances[_to] + _value > balances[_to]) {   
            balances[_to] += _value;  
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
             
            emit  Transfer(_from, _to, _value);  
            return true;
        } else { return false; }
    }
     
	function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    
    function totalSupply() constant public returns (uint256 supply) {
        return _totalSupply;
    }
    
    function approve(address _spender, uint256 _value) onlyOwner public returns (bool success) {  
        allowed[msg.sender][_spender] = _value;
         
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     
	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
	}
	
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
     
	uint256  _totalSupply;
}
contract XGTToken is StandardToken {  
     
     
	string public constant name="XGT";                    
     
	uint8 public constant decimals=18;                 
    string public constant symbol="XGT";                  
    string public version = 'J1.0'; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;            

    function XGTToken() public  {
        balances[msg.sender] 	= 150000000000000000000000000;        
        _totalSupply          	= 150000000000000000000000000;               
                                               
        unitsOneEthCanBuy = 180;                             
        fundsWallet = msg.sender;   
		owner = msg.sender; 
    }
    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
         
        emit Transfer(fundsWallet, msg.sender, amount);  
         
        fundsWallet.transfer(msg.value);                               
    }
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
         
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
	
}