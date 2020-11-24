 

pragma solidity ^0.4.17;

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);
  function approve(address _spender, uint _value) public returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
contract StandardToken is ERC20Basic {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require((_value > 0) && (balances[msg.sender] >= _value));
	    balances[msg.sender] -= _value;
    	balances[_to] += _value;
    	Transfer(msg.sender, _to, _value);
    	return true;
    }

   
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

   
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
    }

    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

 
contract DAEXToken is StandardToken {
    string public constant name = "DAEX Token";
    string public constant symbol = "DAX";
    uint public constant decimals = 18;

    address public target;

    function DAEXToken(address _target) public {
        target = _target;
        totalSupply = 2*10**27;
        balances[target] = totalSupply;
    }
}