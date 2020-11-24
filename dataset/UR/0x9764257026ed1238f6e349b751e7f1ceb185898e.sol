 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


 
contract ERC20 {
  uint256 public totalSupply;

   
  function balanceOf(address _owner) public constant returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
	 
	function add(
		uint256 a,
		uint256 b
	)
		internal pure returns (uint256 c)
	{
		c = a + b;
		assert(c >= a);
		return c;
	}

	 
	function sub(
		uint256 a,
		uint256 b
	)
		internal pure returns (uint256)
	{
		assert(b <= a);
		return a - b;
	}


	 
	function mul(
		uint256 a,
		uint256 b
	)
		internal pure returns (uint256 c)
	{
		if (a == 0) {
				return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(
		uint256 a,
		uint256 b
	)
		internal pure returns (uint256)
	{
		 
		 
		 
		return a / b;
	}
}

contract F2KToken is ERC20, Ownable {
	 
	using SafeMath for uint256;

	 
	mapping(address => uint256) balances;

	 
	mapping(address => mapping(address => uint256)) allowed;

	 
	mapping(address => bool) public freezeBypassing;

	 
	mapping(address => uint256) public lockupExpirations;

	 
	string public constant symbol = "F2K";

	 
	string public constant name = "Farm2Kitchen Token";

	 
	uint8 public constant decimals = 2;

	 
	bool public tradingLive;

	 
	uint256 public totalSupply;

    constructor() public {
        totalSupply = 280000000 * (10 ** uint256(decimals));
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

	 
	event LockupApplied(
		address indexed owner,
		uint256 until
	);
	
	 
	function distribute(
			address to,
			uint256 tokenAmount
	)
			public onlyOwner
	{
			require(tokenAmount > 0);
			require(tokenAmount <= balances[msg.sender]);

			balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
			balances[to] = balances[to].add(tokenAmount);

			emit Transfer(owner, to, tokenAmount);
	}

	 
	function lockup(
			address wallet,
			uint256 duration
	)
			public onlyOwner
	{
			uint256 lockupExpiration = duration.add(now);
			lockupExpirations[wallet] = lockupExpiration;
			emit LockupApplied(wallet, lockupExpiration);
	}

	 
	function setBypassStatus(
			address to,
			bool status
	)
			public onlyOwner
	{
			freezeBypassing[to] = status;
	}

	 
	function setTrading(
			bool status
	) 
		public onlyOwner 
	{
			tradingLive = status;
	}

	 
	modifier tradable(address from) {
			require(
					(tradingLive || freezeBypassing[from]) &&  
					(lockupExpirations[from] <= now)
			);
			_;
	}

	 
	function totalSupply() public view returns (uint256 supply) {
			return totalSupply;
	}

	 
	function balanceOf(
			address owner
	)
			public view returns (uint256 balance)
	{
			return balances[owner];
	}

	 
	function transfer(
			address to,
			uint256 tokenAmount
	)
			public tradable(msg.sender) returns (bool success)
	{
			require(tokenAmount > 0);
			require(tokenAmount <= balances[msg.sender]);

			balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
			balances[to] = balances[to].add(tokenAmount);
			emit Transfer(msg.sender, to, tokenAmount);
			return true;
	}

	 
	function transferFrom(
			address from,
			address to,
			uint256 tokenAmount
	)
			public tradable(from) returns (bool success)
	{
			require(tokenAmount > 0);
			require(tokenAmount <= balances[from]);
			require(tokenAmount <= allowed[from][msg.sender]);
			
			balances[from] = balances[from].sub(tokenAmount);
			allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokenAmount);
			balances[to] = balances[to].add(tokenAmount);
			
			emit Transfer(from, to, tokenAmount);
			return true;
	}
	
	 
	function approve(
			address spender,
			uint256 tokenAmount
	)
			public returns (bool success)
	{
			allowed[msg.sender][spender] = tokenAmount;
			emit Approval(msg.sender, spender, tokenAmount);
			return true;
	}

	 
	function increaseApproval(
			address spender,
			uint tokenAmount
	)
			public returns (bool)
	{
			allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(tokenAmount));
			emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
			
			return true;
	}

	 
	function decreaseApproval(
			address spender,
			uint tokenAmount
	)
			public returns (bool)
	{
			uint oldValue = allowed[msg.sender][spender];
			if (tokenAmount > oldValue) {
				allowed[msg.sender][spender] = 0;
			} else {
				allowed[msg.sender][spender] = oldValue.sub(tokenAmount);
			}
			emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
			
			return true;
	}
	
	 
	function allowance(
			address tokenOwner,
			address spender
	)
			public view returns (uint256 remaining)
	{
			return allowed[tokenOwner][spender];
	}

	function burn(
			uint tokenAmount
	) 
			public onlyOwner returns (bool)
	{
		require(balances[msg.sender] >= tokenAmount);
		balances[msg.sender] = balances[msg.sender].sub(tokenAmount);
		totalSupply = totalSupply.sub(tokenAmount);
		return true;
	}

	 
	function withdrawERC20Token(
			address tokenAddress,
			uint256 tokenAmount
	)
			public onlyOwner returns (bool success)
	{
			return ERC20(tokenAddress).transfer(owner, tokenAmount);
	}

}