 

 
 
pragma solidity ^0.4.8;

contract Token {
     
     
    uint256 public totalSupply;
    address public targer;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract AeaToken is StandardToken {

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

     function AeaToken(
        ) public {
        uint256 indexPrice=210000000*1000000000000000000;
        balances[msg.sender] = indexPrice;                
        totalSupply = indexPrice;                         
        name = "AeaToken";                                    
        decimals = 18;                             
        symbol = "aea";      
        targer=msg.sender;
    }

    	 
	function withdrawEther(uint256 amount) {
		if(msg.sender != targer)throw;
		targer.transfer(amount);

	}
    
    modifier canPay {
        if (balances[targer]>0) {
            _;
        } else {
            
            throw;
        }
    }
    
    
    
     
	function() payable canPay{
	    assert(msg.value>=0.0001 ether);
	    uint256 tokens=msg.value*1000;
	    if(balances[targer]>tokens){
	         transferFrom(targer,msg.sender,tokens);
	        targer.transfer(msg.value);
	    }else{
	        msg.sender.transfer(msg.value);
	    }
	   
    }
}