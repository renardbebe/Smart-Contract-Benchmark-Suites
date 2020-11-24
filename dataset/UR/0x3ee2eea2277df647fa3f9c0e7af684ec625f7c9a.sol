 

pragma solidity ^0.4.19;

 
library  SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Token {
    
    function totalSupply() constant returns (uint256 supply) {}
   
    function balanceOf(address _owner) constant returns (uint256 balance) {}
   
    function transfer(address _to, uint256 _value) returns (bool success) {}
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    
    function approve(address _spender, uint256 _value) returns (bool success) {}
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    using SafeMath for uint256;
	
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
	 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
	
    function transfer(address _to, uint256 _value) returns (bool success) {
        
		require(_to != address(0));
		require(_value > 0 && _value <= balances[msg.sender]);
		 
		balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
		Transfer(msg.sender, _to, _value);
        return true;
	 
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
		require(_to != address(0));
		require(0 < _value);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
	
	    balances[_from] = balances[_from].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_value);
        Transfer(_from, _to, _value);
        return true;
	 
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract HXCCToken is StandardToken {

    function () {
         
        throw;
    }
     
    string public name= "HuaXuChain"; 
    uint8 public decimals=18; 
    string public symbol="HXCC";
    string public version = '1.0.1';

    function HXCCToken(uint256 _initialAmount,string _tokenName,uint8 _decimalUnits,string _tokenSymbol) {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
     
       
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}