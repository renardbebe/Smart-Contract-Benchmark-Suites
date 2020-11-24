 

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

contract FinToken is StandardToken {
	address public owner;
	
	string public constant name = "FIN Token"; 
	string public constant symbol = "FIN";
	uint8 public constant decimals = 18;

	uint256 public constant INITIAL_SUPPLY = 2623304 * (10 ** uint256(decimals));
	
	mapping (address => bool) internal verificatorAddresses;
	mapping (address => bool) internal verifiedAddresses;
	
	event AddVerificator(address indexed verificator);
	event RemoveVerificator(address indexed verificator);
	
	event AddVerified(address indexed verificatorAddress, address indexed verified);
	event RemoveVerified(address indexed verificatorAddress, address indexed verified);
	
	event Mint(address indexed to, uint256 amount);
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyVerificator() {
		require(isVerificator(msg.sender));
		_;
	}
	
	modifier onlyVerified(address _from, address _to) {
		require(isVerified(_from));
		require(isVerified(_to));
		_;
	}

	function FinToken() public {
		owner = msg.sender;
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}
	
	function addVerificatorAddress(address addr) public onlyOwner {
		verificatorAddresses[addr] = true;
		emit AddVerificator(addr);
	}
	
	function removeVerificatorAddress(address addr) public onlyOwner {
		delete verificatorAddresses[addr];
		emit RemoveVerificator(addr);
	}
	
	function isVerificator(address addr) public constant returns (bool) {
		return verificatorAddresses[addr];
	}
		
	function addVerifiedAddress(address addr) public onlyVerificator {
		verifiedAddresses[addr] = true;
		emit AddVerified(msg.sender, addr);
	}
	
	function removeVerifiedAddress(address addr) public onlyVerificator {
		delete verifiedAddresses[addr];
		emit RemoveVerified(msg.sender, addr);
	}
	
	function isVerified(address addr) public constant returns (bool) {
		return verifiedAddresses[addr];
	}
	
	function transfer(address _to, uint256 _value) public onlyVerified(msg.sender, _to) returns (bool) {
		super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public onlyVerified(_from, _to) returns (bool) {
	    super.transferFrom(_from, _to, _value);
	}
}