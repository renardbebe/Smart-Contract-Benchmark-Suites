 

pragma solidity ^0.4.8;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {

     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    using SafeMath for uint256;

    function transfer(address _to, uint256 _value) returns (bool success) {
       
         
        if (_to == 0x0) return false;
	    if (balances[msg.sender] >= _value && _value > 0) {
	     
	        balances[msg.sender] = balances[msg.sender].sub(_value);
	        balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
        
    }

    function batchTransfer(address[] _receivers, uint256 _value) public returns (bool) {
	    uint cnt = _receivers.length;
	    uint256 amount = _value.mul(uint256(cnt));
	
	    require(cnt > 0 && cnt <= 20);
	    require(_value > 0 && balances[msg.sender] >= amount);

	    balances[msg.sender] = balances[msg.sender].sub(amount);
	    for (uint i = 0; i < cnt; i++) {
		    balances[_receivers[i]] = balances[_receivers[i]].add(_value);
		    Transfer(msg.sender, _receivers[i], _value);
	    }
	    return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
         
         
        if (_to == 0x0) return false;
	    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
             
	        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract ThanosXToken is StandardToken { 
      
     
     
     
    string public   name		= "ThanosX Token";
    string public   symbol		= "TNSX";
    string public   version		= "0.1";
    uint256 public  decimals	= 8;
    uint256 public constant	MILLION		= (10**8 * 10**decimals);

    function ThanosXToken() public{

        totalSupply = 10 * MILLION;
        balances[msg.sender] = totalSupply;      
        
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}