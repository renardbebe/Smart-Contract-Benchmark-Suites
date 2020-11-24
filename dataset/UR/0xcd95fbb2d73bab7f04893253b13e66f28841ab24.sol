 

pragma solidity ^0.4.15;

contract owned 
{
	address public owner;

	function owned() public
	{
		owner = msg.sender;
	}

	function changeOwner(address newOwner) public onlyOwner 
	{
		owner = newOwner;
	}

	modifier onlyOwner 
	{
		require(msg.sender == owner);
		_;
	}
}

contract ERC20 {
	function totalSupply() public constant returns (uint totalTokenCount);
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract GamblicaCoin is ERC20, owned 
{
	string public constant symbol = "GMBC";
	string public constant name = "Gamblica Coin";
	uint8 public constant decimals = 18;

	uint256 _totalSupply = 0;
	
	event Burned(address backer, uint _value);
 
	 
	mapping(address => uint256) balances;
 
	 
	mapping(address => mapping (address => uint256)) allowed;

	address public crowdsale;

	function changeCrowdsale(address newCrowdsale) public onlyOwner 
	{
		crowdsale = newCrowdsale;
	}

	modifier onlyOwnerOrCrowdsale 
	{
		require(msg.sender == owner || msg.sender == crowdsale);
		_;
	}

	function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) 
	{
		uint256 z = _x + _y;
		assert(z >= _x);
		return z;
	}

	function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) 
	{
		assert(_x >= _y);
		return _x - _y;
	}
	
	function totalSupply() public constant returns (uint256 totalTokenCount) 
	{
		return _totalSupply;
	}
 
	 
	function balanceOf(address _owner) public constant returns (uint256 balance) 
	{
		return balances[_owner];
	}

 
	 
	function transfer(address _to, uint256 _amount) public returns (bool success) 
	{
		if (balances[msg.sender] >= _amount 
			&& _amount > 0
			&& balances[_to] + _amount > balances[_to]
			) 
		{
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
		} else {
			revert();
		}
	}
 
	 
	 
	 
	 
	 
	 
	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) public returns (bool success) 
	{
		if (balances[_from] >= _amount
			&& allowed[_from][msg.sender] >= _amount
			&& _amount > 0
			&& balances[_to] + _amount > balances[_to] 
			)
		{
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(_from, _to, _amount);
			return true;
		} else {
			revert();
		}
	}
 
	 
	 
	function approve(address _spender, uint256 _amount) public returns (bool success) 
	{
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}
 
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
	{
		return allowed[_owner][_spender];
	}

	function send(address target, uint256 mintedAmount) public onlyOwnerOrCrowdsale 
	{
		require(mintedAmount > 0);

		balances[target] = safeAdd(balances[target], mintedAmount);
		_totalSupply = safeAdd(_totalSupply, mintedAmount);
		Transfer(msg.sender, target, mintedAmount);
	}

	function burn(address target, uint256 burnedAmount) public onlyOwnerOrCrowdsale
	{
		require(burnedAmount > 0);

		if (balances[target] >= burnedAmount)
		{
			balances[target] -= burnedAmount;
		}
		else
		{
			burnedAmount = balances[target];
			balances[target] = 0;
		}

		_totalSupply = safeSub(_totalSupply, burnedAmount);
		Burned(target, burnedAmount);
	}
}