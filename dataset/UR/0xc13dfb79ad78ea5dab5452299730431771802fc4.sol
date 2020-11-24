 

 

pragma solidity 0.4.23;

 
 
 
 
 


 
contract AbstractToken {
	function balanceOf(address owner) public view returns (uint256 balance);
	function transfer(address to, uint256 value) public returns (bool success);
	function transferFrom(address from, address to, uint256 value) public returns (bool success);
	function approve(address spender, uint256 value) public returns (bool success);
	function allowance(address owner, address spender) public view returns (uint256 remaining);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {

	address public owner = msg.sender;
	address public potentialOwner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier onlyPotentialOwner {
		require(msg.sender == potentialOwner);
		_;
	}

	event NewOwner(address old, address current);
	event NewPotentialOwner(address old, address potential);

	function setOwner(address _new)
		public
		onlyOwner
	{
		emit NewPotentialOwner(owner, _new);
		potentialOwner = _new;
	}

	function confirmOwnership()
		public
		onlyPotentialOwner
	{
		emit NewOwner(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
}

 
 
contract SafeMath {
	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	 
	function pow(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a ** b;
		assert(c >= a);
		return c;
	}
}

 
contract StandardToken is AbstractToken, Owned, SafeMath {

	 
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;
	uint256 public totalSupply;

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}

	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(allowed[_from][msg.sender] >= _value);
		allowed[_from][msg.sender] -= _value;

		return _transfer(_from, _to, _value);
	}

	 
	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	 
	 
	 
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	 
	function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
		require(_to != address(0));
		require(balances[_from] >= _value);
		balances[_from] -= _value;
		balances[_to] = add(balances[_to], _value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}

 
 
contract Token is StandardToken {

	 
	uint256 public creationTime;

	function Token() public {
		 
		creationTime = now;
	}

	 
	function transferERC20Token(AbstractToken _token, address _to, uint256 _value)
		public
		onlyOwner
		returns (bool success)
	{
		require(_token.balanceOf(address(this)) >= _value);
		uint256 receiverBalance = _token.balanceOf(_to);
		require(_token.transfer(_to, _value));

		uint256 receiverNewBalance = _token.balanceOf(_to);
		assert(receiverNewBalance == add(receiverBalance, _value));

		return true;
	}

	 
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _value);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_value > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = sub(oldValue, _value);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

 
 
contract GenesisCryptoTechnology is Token {

	 
	string constant public name = 'GenesisCryptoTechnology';
	string constant public symbol = 'GCT';
	uint8  constant public decimals = 8;
 uint256 public exchangeRate = 5880; 

	 
	 


	 

	 
	 

	address public investorsAllocation = address(0x55f6074046b1fA3210E350CF520033F629f686d1);
	uint256 public investorsTotal = 60000000e8;


	 

	 
	 
	 
	 

	address public overdraftAllocation = address(0x93F233fdF9d0Ea73c87AA0EDB3e4FB417Fb50145);
	uint256 public overdraftTotal = 20000000e8;
	uint256 public overdraftPeriodAmount = 41666666e8;
	uint256 public overdraftUnvested = 4e8;
	uint256 public overdraftCliff = 5 * 30 days;
	uint256 public overdraftPeriodLength = 810 days;
	uint8   public overdraftPeriodsNumber = 6;


	 

	 
	 
	 

	address public teamAllocation  = address(0x1258c8C124dCAdf8122117EbF1968FFC54bFBFa6);
	uint256 public teamTotal = 15000000e8;
	uint256 public teamPeriodAmount = 7031250e8;
	uint256 public teamUnvested = 0;
	uint256 public teamCliff = 0;
	uint256 public teamPeriodLength = 3 * 810 days;
	uint8   public teamPeriodsNumber = 16;



	 

	 
	 
	 
	 


	address public communityAllocation  = address(0xa4d82eb18d2Bca1A3A2443324F0Beea0A0DC23C8);
	uint256 public communityTotal = 4000000e8;
	uint256 public communityPeriodAmount = 8333333e8;
	uint256 public communityUnvested = 10000002e8;
	uint256 public communityCliff = 0;
	uint256 public communityPeriodLength = 3 * 810 days;
	uint8   public communityPeriodsNumber = 6;



	 

	 
	 
	 
	 

	address public advisersAllocation  = address(0xa020d6Ca8738B18727dEFbe49fC22e3eF7110163);
	uint256 public advisersTotal = 1000000e8;
	uint256 public advisersPeriodAmount = 2291666e8;
	uint256 public advisersUnvested = 25000008e8;
	uint256 public advisersCliff = 0;
	uint256 public advisersPeriodLength = 1 days;
	uint8   public advisersPeriodsNumber = 12;


	 

	function GenesisCryptoTechnology() public {
		 
		totalSupply = 100000000e8;

		balances[investorsAllocation] = investorsTotal;
		balances[overdraftAllocation] = overdraftTotal;
		balances[teamAllocation] = teamTotal;
		balances[communityAllocation] = communityTotal;
		balances[advisersAllocation] = advisersTotal;

		 
		allowed[investorsAllocation][msg.sender] = investorsTotal;
		allowed[overdraftAllocation][msg.sender] = overdraftUnvested;
		allowed[communityAllocation][msg.sender] = communityUnvested;
		allowed[advisersAllocation][msg.sender] = advisersUnvested;
	}

	 

	function distributeInvestorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(investorsAllocation, _to, _amountWithDecimals));
	}

	 

	function withdrawOverdraftTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		allowed[overdraftAllocation][msg.sender] = allowance(overdraftAllocation, msg.sender);
		require(transferFrom(overdraftAllocation, _to, _amountWithDecimals));
	}

	function withdrawTeamTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[teamAllocation][msg.sender] = allowance(teamAllocation, msg.sender);
		require(transferFrom(teamAllocation, _to, _amountWithDecimals));
	}

	function withdrawCommunityTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[communityAllocation][msg.sender] = allowance(communityAllocation, msg.sender);
		require(transferFrom(communityAllocation, _to, _amountWithDecimals));
	}

	function withdrawAdvisersTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[advisersAllocation][msg.sender] = allowance(advisersAllocation, msg.sender);
		require(transferFrom(advisersAllocation, _to, _amountWithDecimals));
	}

	 
	function allowance(address _owner, address _spender)
		public
		view
		returns (uint256 remaining)
	{   
		if (_spender != owner) {
			return allowed[_owner][_spender];
		}

		uint256 unlockedTokens;
		uint256 spentTokens;

		if (_owner == overdraftAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				overdraftCliff,
				overdraftPeriodLength,
				overdraftPeriodAmount,
				overdraftPeriodsNumber,
				overdraftUnvested
			);
			spentTokens = sub(overdraftTotal, balanceOf(overdraftAllocation));
		} else if (_owner == teamAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				teamCliff,
				teamPeriodLength,
				teamPeriodAmount,
				teamPeriodsNumber,
				teamUnvested
			);
			spentTokens = sub(teamTotal, balanceOf(teamAllocation));
		} else if (_owner == communityAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				communityCliff,
				communityPeriodLength,
				communityPeriodAmount,
				communityPeriodsNumber,
				communityUnvested
			);
			spentTokens = sub(communityTotal, balanceOf(communityAllocation));
		} else if (_owner == advisersAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				advisersCliff,
				advisersPeriodLength,
				advisersPeriodAmount,
				advisersPeriodsNumber,
				advisersUnvested
			);
			spentTokens = sub(advisersTotal, balanceOf(advisersAllocation));
		} else {
			return allowed[_owner][_spender];
		}

		return sub(unlockedTokens, spentTokens);
	}

	 
	function confirmOwnership()
		public
		onlyPotentialOwner
	{   
		 
		allowed[investorsAllocation][owner] = 0;

		 
		allowed[investorsAllocation][msg.sender] = balanceOf(investorsAllocation);

		 
		allowed[overdraftAllocation][owner] = 0;
		allowed[teamAllocation][owner] = 0;
		allowed[communityAllocation][owner] = 0;
		allowed[advisersAllocation][owner] = 0;

		super.confirmOwnership();
	}

	function _calculateUnlockedTokens(
		uint256 _cliff,
		uint256 _periodLength,
		uint256 _periodAmount,
		uint8 _periodsNumber,
		uint256 _unvestedAmount
	)
		private
		view
		returns (uint256) 
	{
		 
		if (now < add(creationTime, _cliff)) {
			return _unvestedAmount;
		}
		 
		uint256 periods = div(sub(now, add(creationTime, _cliff)), _periodLength);
		periods = periods > _periodsNumber ? _periodsNumber : periods;
		return add(_unvestedAmount, mul(periods, _periodAmount));
	}
}