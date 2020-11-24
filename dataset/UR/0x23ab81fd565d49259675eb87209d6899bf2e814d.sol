 

pragma solidity ^0.4.21;


 
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

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
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
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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
		emit Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

contract NomToken is StandardToken {
	event Mint(address indexed to, uint256 amount);

	address public owner;
	
	string public constant name = "NOM Token"; 
	string public constant symbol = "NOM";
	uint8 public constant decimals = 18;	
	
	uint256 public constant totalTokens = 5650000000 * (10 ** uint256(decimals));
	
	uint256 public initialIssueMinting = totalTokens.mul(60).div(100);	 
	uint public constant initialIssueMintingDate = 1524873600;			 
	bool public initialIssueMinted = false;
		
	uint256 public firstStageMinting = totalTokens.mul(10).div(100);	 
	uint public constant firstStageMintingDate = 1532736000;			 
	bool public firstStageMinted = false;
		
	uint256 public secondStageMinting = totalTokens.mul(10).div(100);	 
	uint public constant secondStageMintingDate = 1540684800;			 
	bool public secondStageMinted = false;
	
	uint256 public thirdStageMinting = totalTokens.mul(10).div(100);	 
	uint public constant thirdStageMintingDate = 1548633600;			 
	bool public thirdStageMinted = false;
	
	uint256 public fourthStageMinting = totalTokens.mul(10).div(100);	 
	uint public constant fourthStageMintingDate = 1556409600;			 
	bool public fourthStageMinted = false;
		
	function NomToken() public {
		owner = msg.sender;
	}
	
	  
	function mint() public returns (bool) {
		require(msg.sender == owner);
		
		uint256 tokensToMint = 0;
		if (now > initialIssueMintingDate && !initialIssueMinted) {
				tokensToMint = tokensToMint.add(initialIssueMinting);
				initialIssueMinted = true;
		}
		if (now > firstStageMintingDate && !firstStageMinted) {
				tokensToMint = tokensToMint.add(firstStageMinting);
				firstStageMinted = true;
		}
		if (now > secondStageMintingDate && !secondStageMinted) {
				tokensToMint = tokensToMint.add(secondStageMinting);
				secondStageMinted = true;
		}
		if (now > thirdStageMintingDate && !thirdStageMinted) {
				tokensToMint = tokensToMint.add(thirdStageMinting);
				thirdStageMinted = true;
		}
		if (now > fourthStageMintingDate && !fourthStageMinted) {
				tokensToMint = tokensToMint.add(fourthStageMinting);
				fourthStageMinted = true;
		}
		require(tokensToMint > 0);
		uint256 newTotalSupply = totalSupply_.add(tokensToMint);
		require(newTotalSupply <= totalTokens);
		
		totalSupply_ = totalSupply_.add(tokensToMint);
		balances[owner] = balances[owner].add(tokensToMint);
		emit Mint(owner, tokensToMint);
		emit Transfer(0x0, owner, tokensToMint);
		return true;
	}
}