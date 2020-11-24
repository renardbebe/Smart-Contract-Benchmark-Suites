 

pragma solidity ^0.4.18;

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
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
}

 
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	 
	function Ownable() public {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}


 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;


	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

 
contract SebastianToken is StandardToken, Ownable {
	using SafeMath for uint256;

	string public name = "Sebastian";
	string public symbol = "SEB";
	uint256 public decimals = 5;

	uint256 public totalSupply = 1000000000 * (10 ** uint256(decimals));

	 
	function SebastianToken(string _name, string _symbol, uint256 _decimals, uint256 _totalSupply) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;

		totalSupply_ = _totalSupply;
		balances[msg.sender] = totalSupply;
	}

	 
	function () public payable {
		revert();
	}
}

 
contract SebastianTokenSale is Ownable {

	using SafeMath for uint256;

	 
	SebastianToken public token;

	 
	uint256 public startingTimestamp = 1518696000;

	 
	uint256 public endingTimestamp = 1521115200;

	 
	uint256 public tokenPriceInEth = 0.0001 ether;

	 
	uint256 public tokensForSale = 400000000 * 1E5;

	 
	uint256 public totalTokenSold;

	 
	uint256 public totalEtherRaised;

	 
	mapping(address => uint256) public etherRaisedPerWallet;

	 
	address public wallet;

	 
	bool internal isClose = false;

	 
	event WalletChange(address _wallet, uint256 _timestamp);

	 
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	 
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	 
	function SebastianTokenSale(address _token, uint256 _startingTimestamp, uint256 _endingTimestamp, uint256 _tokensPerEth, uint256 _tokensForSale, address _wallet) public {
		 
		token = SebastianToken(_token);

		startingTimestamp = _startingTimestamp;
		endingTimestamp = _endingTimestamp;
		tokenPriceInEth =  1E18 / _tokensPerEth;  
		tokensForSale = _tokensForSale;

		 
		wallet = _wallet;
	}

	 
	function isValidPurchase(uint256 value, uint256 amount) internal constant returns (bool) {
		 
		bool validTimestamp = startingTimestamp <= block.timestamp && endingTimestamp >= block.timestamp;

		 
		bool validValue = value != 0;

		 
		bool validRate = tokenPriceInEth > 0;

		 
		bool validAmount = tokensForSale.sub(totalTokenSold) >= amount && amount > 0;

		 
		return validTimestamp && validValue && validRate && validAmount && !isClose;
	}

	
	 
	function calculate(uint256 value) public constant returns (uint256) {
		uint256 tokenDecimals = token.decimals();
		uint256 tokens = value.mul(10 ** tokenDecimals).div(tokenPriceInEth);
		return tokens;
	}
	
	 
	function() public payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));

		 
		uint256 value = msg.value;

		 
		uint256 tokens = calculate(value);

		 
		require(isValidPurchase(value , tokens));

		 
		totalTokenSold = totalTokenSold.add(tokens);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		 
		token.transfer(beneficiary, tokens);
		
		 
		TokenPurchase(msg.sender, beneficiary, value, tokens, now);
	}

	 
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		 
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	 	
	function setWallet(address _wallet) onlyOwner public returns(bool) {
		 
		wallet = _wallet;
		WalletChange(_wallet , now);
		return true;
	}

	 
	function withdraw() onlyOwner public {
		wallet.transfer(this.balance);
	}

	 	
	function close() onlyOwner public {
		 
		uint256 tokens = token.balanceOf(this); 
		token.transfer(owner , tokens);

		 
		withdraw();

		 
		isClose = true;
	}
}