 

pragma solidity 0.4.15;

contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _recipient, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _recipient, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20 {

	uint256 public totalSupply;
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    modifier when_can_transfer(address _from, uint256 _value) {
        if (balances[_from] >= _value) _;
    }

    modifier when_can_receive(address _recipient, uint256 _value) {
        if (balances[_recipient] + _value > balances[_recipient]) _;
    }

    modifier when_is_allowed(address _from, address _delegate, uint256 _value) {
        if (allowed[_from][_delegate] >= _value) _;
    }

    function transfer(address _recipient, uint256 _value)
        when_can_transfer(msg.sender, _value)
        when_can_receive(_recipient, _value)
        returns (bool o_success)
    {
        balances[msg.sender] -= _value;
        balances[_recipient] += _value;
        Transfer(msg.sender, _recipient, _value);
        return true;
    }

    function transferFrom(address _from, address _recipient, uint256 _value)
        when_can_transfer(_from, _value)
        when_can_receive(_recipient, _value)
        when_is_allowed(_from, msg.sender, _value)
        returns (bool o_success)
    {
        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_recipient] += _value;
        Transfer(_from, _recipient, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool o_success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 o_remaining) {
        return allowed[_owner][_spender];
    }
}

contract BECToken is StandardToken {

	string public name = "BECoin";
    string public symbol = "BEC";
    uint public decimals = 3;

	function BECToken (address _bank, uint _totalSupply) {
		balances[_bank] += _totalSupply;
		totalSupply += _totalSupply;
	}

	 
	function transfer(address _recipient, uint _amount)
		returns (bool o_success)
	{
		return super.transfer(_recipient, _amount);
	}

	 
	function transferFrom(address _from, address _recipient, uint _amount)
		returns (bool o_success)
	{
		return super.transferFrom(_from, _recipient, _amount);
	}
}