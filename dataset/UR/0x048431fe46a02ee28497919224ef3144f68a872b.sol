 

pragma solidity ^0.4.19;

library SafeMath {
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ContractReceiver {
   
   
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract WBDToken {
	using SafeMath for uint256;
	
	uint256 public totalSupply;
    string  public name;
    string  public symbol;
    uint8   public constant decimals = 8;

    address public owner;
	
    mapping(address => uint256) balances;  

    function WBDToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        owner           =   msg.sender;
		totalSupply     =   initialSupply * 10 ** uint256(decimals);
		name            =   tokenName;
		symbol          =   tokenSymbol;
        balances[owner] =   totalSupply;
    }

	event Transfer(address indexed from, address indexed to, uint256 value);   
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);  
	event Burn(address indexed from, uint256 amount, uint256 currentSupply, bytes data);


	 
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
		transfer(_to, _value, empty);
    }

	 
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        uint codeLength;

        assembly {
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
		
		Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
    }
	
	 
    function burn(uint256 _value, bytes _data) public returns (bool success) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value, totalSupply, _data);
        return true;
    }
	
	 
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }
}