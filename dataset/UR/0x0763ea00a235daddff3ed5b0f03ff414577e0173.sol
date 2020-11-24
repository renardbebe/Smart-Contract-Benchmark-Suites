 

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
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
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

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		bytes memory empty;
		Transfer(msg.sender, _to, _value, empty);
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

		bytes memory empty;
		Transfer(_from, _to, _value, empty);
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

	 
	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

 
contract ERC223Receiver {
	 
	struct TokenStruct {
		address sender;
		uint256 value;
		bytes data;
		bytes4 sig;
	}
	
	 
	function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
		TokenStruct memory tkn;
		tkn.sender = _from;
		tkn.value = _value;
		tkn.data = _data;
		 
		 
	  
		 
	}
}

 
contract ERC223 {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

 

contract ERC223Token is ERC223, StandardToken {
	using SafeMath for uint256;

	 
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		 
		if(isContract(_to)) {
			 
			require(_to != address(0));
			require(_value <= balances[msg.sender]);

			 
			balances[msg.sender] = balances[msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
	
			 
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			 
			return transferToAddress(_to, _value, _data);
		}
	}
  

	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		 
		if(isContract(_to)) {
			 
			return transferToContract(_to, _value, _data);
		}
		else {
			 
			return transferToAddress(_to, _value, _data);
		}
	}
  
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		 
		 
		bytes memory empty;

		 
		if(isContract(_to)) {
			 
			return transferToContract(_to, _value, empty);
		}
		else {
			 
			return transferToAddress(_to, _value, empty);
		}
	}

	 
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	 
	function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
		 
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
  
	 
	function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
		 
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		 
		ERC223Receiver receiver = ERC223Receiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		
		 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
}

 
contract PalestinoToken is ERC223Token, Ownable {

	string public constant name = "Palestino";
	string public constant symbol = "PALE";
	uint256 public constant decimals = 3;

	uint256 constant INITIAL_SUPPLY = 10000000 * 1E3;
	
	 
	function PalestinoToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	 
	function () public {
		revert();
	}
}

 
contract PalestinoTokenSale is Ownable, ERC223Receiver {
	using SafeMath for uint256;

	 
	PalestinoToken public token;

	 
	uint256 public startingTimestamp = 1515974400;

	 
	uint256 public maxTokenForSale = 10000000 * 1E3;

	 
	uint256 public totalTokenSold;

	 
	uint256 public totalEtherRaised;

	 
	mapping(address => uint256) public etherRaisedPerWallet;

	 
	address public wallet;

	 
	bool internal isClose = false;

	struct RoundStruct {
		uint256 number;
		uint256 fromAmount;
		uint256 toAmount;
		uint256 price;
	}

	RoundStruct[9] public rounds;

	 
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	 
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	 
	function PalestinoTokenSale(address _token, address _wallet) public {
		 
		token = PalestinoToken(_token);

		 
		wallet = _wallet;

		 
		rounds[0] = RoundStruct(0, 0	    ,  2500000E3, 0.01 ether);
		rounds[1] = RoundStruct(1, 2500000E3,  3000000E3, 0.02 ether);
		rounds[2] = RoundStruct(2, 3000000E3,  3500000E3, 0.03 ether);
		rounds[3] = RoundStruct(3, 3500000E3,  4000000E3, 0.06 ether);
		rounds[4] = RoundStruct(4, 4000000E3,  4500000E3, 0.10 ether);
		rounds[5] = RoundStruct(5, 4500000E3,  5000000E3, 0.18 ether);
		rounds[6] = RoundStruct(6, 5000000E3,  5500000E3, 0.32 ether);
		rounds[7] = RoundStruct(7, 5500000E3,  6000000E3, 0.57 ether);
		rounds[8] = RoundStruct(8, 6000000E3, 10000000E3, 1.01 ether);
	}

	 
	function isValidPurchase(uint256 value, uint256 amount) internal constant returns (bool) {
		 
		bool validTimestamp = startingTimestamp <= block.timestamp;

		 
		bool validValue = value != 0;

		 
		bool validAmount = maxTokenForSale.sub(totalTokenSold) >= amount && amount > 0;

		 
		return validTimestamp && validValue && validAmount && !isClose;
	}

	 
	function getCurrentRound() public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if(rounds[i].fromAmount <= totalTokenSold && totalTokenSold < rounds[i].toAmount) {
				return rounds[i];
			}
		}
	}

	 
	function getEstimatedRound(uint256 amount) public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if(rounds[i].fromAmount > (totalTokenSold + amount)) {
				return rounds[i - 1];
			}
		}

		return rounds[rounds.length - 1];
	}

	 
	function getMaximumRound(uint256 amount) public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if((totalTokenSold + amount) <= rounds[i].toAmount) {
				return rounds[i];
			}
		}
	}

	 
	function getTokenAmount(uint256 value) public constant returns (uint256 , uint256) {
		 
		uint256 totalAmount = 0;

		 
		while(value > 0) {
			
			 
			RoundStruct memory estimatedRound = getEstimatedRound(totalAmount);
			 
			uint256 tokensLeft = estimatedRound.toAmount.sub(totalTokenSold.add(totalAmount));

			 
			uint256 tokensBuys = value.mul(1E3).div(estimatedRound.price);

			 
			if(estimatedRound.number == rounds[rounds.length - 1].number) {
				 

				 
				if(tokensLeft == 0 && value > 0) {
					return (totalAmount , value);
				}
			}

			 
			if(tokensLeft >= tokensBuys) {
				totalAmount = totalAmount.add(tokensBuys);
				value = 0;
				return (totalAmount , value);
			} else {
				uint256 tokensLeftValue = tokensLeft.mul(estimatedRound.price).div(1E3);
				totalAmount = totalAmount.add(tokensLeft);
				value = value.sub(tokensLeftValue);
			}
		}

		return (0 , value);
	}
	
	 
	function() public payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));

		 
		uint256 value = msg.value;

		 
		var (amount, leftValue) = getTokenAmount(value);

		 
		if(leftValue > 0) {
			value = value.sub(leftValue);
			msg.sender.transfer(leftValue);
		}

		 
		require(isValidPurchase(value , amount));

		 
		totalTokenSold = totalTokenSold.add(amount);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		 
		bytes memory empty;
		token.transfer(beneficiary, amount, empty);
		
		 
		TokenPurchase(msg.sender, beneficiary, value, amount, now);
	}

	 
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		 
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	 
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
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