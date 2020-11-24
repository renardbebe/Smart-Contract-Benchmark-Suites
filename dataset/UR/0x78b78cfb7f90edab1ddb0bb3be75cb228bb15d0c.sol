 

pragma solidity ^0.4.18;

 
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

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
contract Crowdsale {
	 
	string public name;

	 
	 
	address private creator;

	 
	uint public offset;

	 
	uint public length;

	 
	uint public price;

	 
	uint public softCap;

	 
	uint public hardCap;

	 
	uint private quantum;

	 
	uint public collected;

	 
	uint public investorsCount;

	 
	uint public refunded;

	 
	uint public tokensIssued;

	 
	uint public tokensRedeemed;

	 
	uint public transactions;

	 
	uint public refunds;

	 
	DetailedERC20 private token;

	 
	uint k;

	 
	address public beneficiary;

	 
	 
	mapping(address => uint) public balances;

	 
	event InvestmentAccepted(address indexed holder, uint tokens, uint value);
	event RefundIssued(address indexed holder, uint tokens, uint value);

	 
	 
	 
	 
	 
	function Crowdsale(
		string _name,
		uint _offset,
		uint _length,
		uint _price,
		uint _softCap,
		uint _hardCap,
		uint _quantum,
		address _beneficiary,
		address _token
	) public {

		 
		 
		require(_length > 0);
		require(now < _offset + _length);  
		 
		require(_hardCap > _softCap || _hardCap == 0);
		 
		 
		require(_price > 0);
		require(_beneficiary != address(0));
		require(_token != address(0));

		name = _name;

		 
		offset = _offset;
		length = _length;
		softCap = _softCap;
		hardCap = _hardCap;
		quantum = _quantum;
		price = _price;
		creator = msg.sender;

		 
		beneficiary = _beneficiary;

		 
		__allocateTokens(_token);
	}

	 
	 
	function invest() public payable {
		 
		assert(now >= offset && now < offset + length);  
		assert(collected + price <= hardCap || hardCap == 0);  
		require(msg.value >= price);  

		 
		address investor = msg.sender;

		 
		uint tokens = msg.value / price;

		 
		uint value = tokens * price;

		 
		if (value + collected > hardCap || hardCap == 0) {
			value = hardCap - collected;
			tokens = value / price;
			value = tokens * price;
		}

		 
		collected += value;
		tokensIssued += tokens;

		 
		__issueTokens(investor, tokens);

		 
		investor.transfer(msg.value - value);

		 
		if (collected >= softCap && this.balance >= quantum) {
			 
			__beneficiaryTransfer(this.balance);
		}

		 
		InvestmentAccepted(investor, tokens, value);
	}

	 
	 
	function refund() public payable {
		 
		assert(now >= offset + length);  
		assert(collected < softCap);  

		 
		address investor = msg.sender;

		 
		uint tokens = __redeemAmount(investor);

		 
		uint refundValue = tokens * price;

		 
		require(tokens > 0);

		 
		refunded += refundValue;
		tokensRedeemed += tokens;
		refunds++;

		 
		__redeemTokens(investor, tokens);

		 
		investor.transfer(refundValue + msg.value);

		 
		RefundIssued(investor, tokens, refundValue);
	}

	 
	function withdraw() public {
		 
		assert(creator == msg.sender || beneficiary == msg.sender);  
		assert(collected >= softCap);  
		assert(this.balance > 0);  

		 
		uint value = this.balance;

		 
		__beneficiaryTransfer(value);
	}

	 
	 
	function() public payable {
		 
		require(now >= offset);

		if(now < offset + length) {
			 
			invest();
		}
		else if(collected < softCap) {
			 
			refund();
		}
		else {
			 
			 
			withdraw();
		}
	}

	 

	 
	function __allocateTokens(address _token) internal {
		 
		 
		token = DetailedERC20(_token);

		 
		k = 10 ** uint(token.decimals());
	}

	 
	function __issueTokens(address investor, uint tokens) internal {
		 
		if (balances[investor] == 0) {
			investorsCount++;
		}

		 
		balances[investor] += tokens;

		 
		token.transferFrom(creator, investor, tokens * k);
	}

	 
	function __redeemAmount(address investor) internal view returns (uint amount) {
		 
		uint allowance = token.allowance(investor, this) / k;

		 
		uint balance = balances[investor];

		 
		return balance < allowance ? balance : allowance;
	}

	 
	function __redeemTokens(address investor, uint tokens) internal {
		 
		balances[investor] -= tokens;

		 
		token.transferFrom(investor, creator, tokens * k);
	}

	 
	function __beneficiaryTransfer(uint value) internal {
		beneficiary.transfer(value);
	}

	 
}