 

pragma solidity ^0.4.16;

 
 
contract TokenERC20 {
     
     
    uint256 public totalSupply;

	 
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

	 
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

	 
     
     
     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

	 
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
	
	
	 
     
     
	function balanceOf(address _owner) constant returns (uint256 balance);
	
	  
     
     
     
     
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


interface TokenNotifier {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StandardToken is TokenERC20, SafeMath {

	 
    mapping (address => uint256) balances;
     
	mapping (address => mapping (address => uint256)) allowed;
  

	   
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
		balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

 	  
      
      
      
      
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

	 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

	 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }	
}

 
contract COGNXToken is StandardToken {
    uint8 public constant decimals = 18;
    string public constant name = 'COGNX';
    string public constant symbol = 'COGNX';
    string public constant version = '1.0.0';
    uint256 public totalSupply = 15000000 * 10 ** uint256(decimals);
		
	 
    function COGNXToken() public {
        balances[msg.sender] = totalSupply;
    }

	  
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}