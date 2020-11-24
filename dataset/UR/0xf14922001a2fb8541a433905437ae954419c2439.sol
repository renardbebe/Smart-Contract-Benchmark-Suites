 

pragma solidity 0.4.24;


 
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


 
 
library SafeMath {
	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
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

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


 
 
contract StandardToken is AbstractToken, Owned {
	using SafeMath for uint256;

	 
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;
	uint256 public totalSupply;

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}

	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowed[_from][msg.sender]);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
		require(_value <= balances[_from]);
		require(_to != address(0));

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}


 
 
contract BurnableToken is StandardToken {

	address public burner;

	modifier onlyBurner {
		require(msg.sender == burner);
		_;
	}

	event NewBurner(address burner);

	function setBurner(address _burner)
		public
		onlyOwner
	{
		burner = _burner;
		emit NewBurner(_burner);
	}

	function burn(uint256 amount)
		public
		onlyBurner
	{
		require(balanceOf(msg.sender) >= amount);
		balances[msg.sender] = balances[msg.sender].sub(amount);
		totalSupply = totalSupply.sub(amount);
		emit Transfer(msg.sender, address(0x0000000000000000000000000000000000000000), amount);
	}
}


 
 
contract Token is BurnableToken {

	 
	uint256 public creationTime;

	constructor() public {
		 
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
		assert(receiverNewBalance == receiverBalance.add(_value));

		return true;
	}

	 
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_value > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_value);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}

 
 
contract InmediateToken is Token {

	 
	string constant public name = 'Inmediate';
	string constant public symbol = 'DIT';
	uint8  constant public decimals = 8;


	 
	 


	 

	 
	 

	address public investorsAllocation = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
	uint256 public investorsTotal = 400000000e8;


	 

	 
	 
	 
	 

	address public teamAllocation  = address(0x1111111111111111111111111111111111111111);
	uint256 public teamTotal = 100000000e8;
	uint256 public teamPeriodAmount = 10000000e8;
	uint256 public teamCliff = 6 * 30 days;
	uint256 public teamUnlockedAfterCliff = 20000000e8;
	uint256 public teamPeriodLength = 3 * 30 days;
	uint8   public teamPeriodsNumber = 8;

	 

	 
	 
	 
	 

	address public advisorsAllocation  = address(0x2222222222222222222222222222222222222222);
	uint256 public advisorsTotal = 50000000e8;
	uint256 public advisorsPeriodAmount = 10000000e8;
	uint256 public advisorsCliff = 6 * 30 days;
	uint256 public advisorsUnlockedAfterCliff = 10000000e8;
	uint256 public advisorsPeriodLength = 3 * 30 days;
	uint8   public advisorsPeriodsNumber = 4;


	 

	 
	 


	address public bountyAllocation  = address(0x3333333333333333333333333333333333333333);
	uint256 public bountyTotal = 50000000e8;


	 

	 
	 


	address public liquidityPoolAllocation  = address(0x4444444444444444444444444444444444444444);
	uint256 public liquidityPoolTotal = 150000000e8;


	 

	 
	 


	address public contributorsAllocation  = address(0x5555555555555555555555555555555555555555);
	uint256 public contributorsTotal = 250000000e8;


	 

	constructor() public {
		 
		totalSupply = 1000000000e8;

		balances[investorsAllocation] = investorsTotal;
		balances[teamAllocation] = teamTotal;
		balances[advisorsAllocation] = advisorsTotal;
		balances[bountyAllocation] = bountyTotal;
		balances[liquidityPoolAllocation] = liquidityPoolTotal;
		balances[contributorsAllocation] = contributorsTotal;
		

		 
		allowed[investorsAllocation][msg.sender] = investorsTotal;
		allowed[bountyAllocation][msg.sender] = bountyTotal;
		allowed[liquidityPoolAllocation][msg.sender] = liquidityPoolTotal;
		allowed[contributorsAllocation][msg.sender] = contributorsTotal;
	}

	 

	function distributeInvestorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(investorsAllocation, _to, _amountWithDecimals));
	}

	 

	function withdrawTeamTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[teamAllocation][msg.sender] = allowance(teamAllocation, msg.sender);
		require(transferFrom(teamAllocation, _to, _amountWithDecimals));
	}

	function withdrawAdvisorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner 
	{
		allowed[advisorsAllocation][msg.sender] = allowance(advisorsAllocation, msg.sender);
		require(transferFrom(advisorsAllocation, _to, _amountWithDecimals));
	}


	 

	function withdrawBountyTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(bountyAllocation, _to, _amountWithDecimals));
	}

	function withdrawLiquidityPoolTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(liquidityPoolAllocation, _to, _amountWithDecimals));
	}

	function withdrawContributorsTokens(address _to, uint256 _amountWithDecimals)
		public
		onlyOwner
	{
		require(transferFrom(contributorsAllocation, _to, _amountWithDecimals));
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

		if (_owner == teamAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				teamCliff, teamUnlockedAfterCliff,
				teamPeriodLength, teamPeriodAmount, teamPeriodsNumber
			);
			spentTokens = balanceOf(teamAllocation) < teamTotal ? teamTotal.sub(balanceOf(teamAllocation)) : 0;
		} else if (_owner == advisorsAllocation) {
			unlockedTokens = _calculateUnlockedTokens(
				advisorsCliff, advisorsUnlockedAfterCliff,
				advisorsPeriodLength, advisorsPeriodAmount, advisorsPeriodsNumber
			);
			spentTokens = balanceOf(advisorsAllocation) < advisorsTotal ? advisorsTotal.sub(balanceOf(advisorsAllocation)) : 0;
		} else {
			return allowed[_owner][_spender];
		}

		return unlockedTokens.sub(spentTokens);
	}

	 
	function confirmOwnership()
		public
		onlyPotentialOwner
	{   
		 
		allowed[investorsAllocation][owner] = 0;

		 
		allowed[investorsAllocation][msg.sender] = balanceOf(investorsAllocation);

		 
		allowed[teamAllocation][owner] = 0;
		allowed[advisorsAllocation][owner] = 0;
		allowed[bountyAllocation][owner] = 0;
		allowed[liquidityPoolAllocation][owner] = 0;
		allowed[contributorsAllocation][owner] = 0;

		 
		allowed[bountyAllocation][msg.sender] = balanceOf(bountyAllocation);
		allowed[liquidityPoolAllocation][msg.sender] = balanceOf(liquidityPoolAllocation);
		allowed[contributorsAllocation][msg.sender] = balanceOf(contributorsAllocation);
		
		super.confirmOwnership();
	}

	 

	function _calculateUnlockedTokens(
		uint256 _cliff,
		uint256 _unlockedAfterCliff,
		uint256 _periodLength,
		uint256 _periodAmount,
		uint8 _periodsNumber
	)
		private
		view
		returns (uint256) 
	{
		 
		if (now < creationTime.add(_cliff)) {
			return 0;
		}
		 
		uint256 periods = now.sub(creationTime.add(_cliff)).div(_periodLength);
		periods = periods > _periodsNumber ? _periodsNumber : periods;
		return _unlockedAfterCliff.add(periods.mul(_periodAmount));
	}
}