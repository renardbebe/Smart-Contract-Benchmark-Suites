 

pragma solidity ^0.4.11;

 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract NewToken {
	function NewToken() {
		totalSupply = 1000000000000000000;
		name = "Paymon Token";
		decimals = 9;
		symbol = "PMNT";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}

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
		return 1000000000000000000000;
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

    function sendFromContract(address _from, address[] _to,
            uint _value) returns (bool) {
            for (uint i = 0; i < _to.length; i++) {
                Transfer(_from, _to[i], _value);
            }
    }

}