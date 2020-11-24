 

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
		assert(b > 0);
		uint256 c = a / b;
		assert(a == b * c + a % b);
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

 
contract ERC20Basic {
	
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	
}

 
contract BasicToken is ERC20Basic {
	
	using SafeMath for uint256;
	mapping(address => uint256) balances;

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

 
 
contract ERC20 is ERC20Basic {
	
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
}

 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) allowed;

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		
		var _allowance = allowed[_from][msg.sender];
		require (_value <= _allowance);
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;

	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {

		 
		 
		 
		 
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
}

 
 
contract Ownable {
	
	address public owner;

	 
	function Ownable() public {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}

}

 
contract Pausable is Ownable {
	
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused {
		require(paused);
		_;
	}

	function pause() public onlyOwner whenNotPaused returns (bool) {
		paused = true;
		Pause();
		return true;
	}

	function unpause() public onlyOwner whenPaused returns (bool) {
		paused = false;
		Unpause();
		return true;
	}
	
}

 
contract EVPToken is StandardToken, Pausable {
	
	uint256 public totalSupply = 22000000 * 1 ether;
	string public name = "Evolution+ Token"; 
    uint8 public decimals = 18; 
    string public symbol = "EVP";
	
	 
	function EVPToken() public {
        balances[msg.sender] = totalSupply;
    }
	
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

}