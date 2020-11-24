 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {                                                   
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));                                     
        owner = newOwner;
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

contract Coingrid is ERC20, Ownable {
	string public name;
	string public symbol;
	uint8 public decimals;

	address public crowdsale;

	bool public paused;

	using SafeMath for uint256;

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Burn(address indexed burner, uint256 value);

	uint256 totalSupply_;

	modifier canMove() {
		require(paused == false || msg.sender == crowdsale);
		_;
	}

	constructor() public {
		totalSupply_ = 100 * 1000000 * 1 ether;  
		name = "Coingrid";
		symbol = "CGT";
		decimals = 18;
		paused = true;
		balances[msg.sender] = totalSupply_;
		emit Transfer(0x0, msg.sender, totalSupply_);
	}

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public canMove returns (bool) {
		require(_value <= balances[msg.sender]);
		require(_to != address(0));

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}

	 
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		canMove
		returns (bool)
	{
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		require(_to != address(0));

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

	 
	function allowance(
		address _owner,
		address _spender
	 )
		public
		view
		returns (uint256)
	{
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(
		address _spender,
		uint256 _addedValue
	)
		public
		returns (bool)
	{
		allowed[msg.sender][_spender] = (
			allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(
		address _spender,
		uint256 _subtractedValue
	)
		public
		returns (bool)
	{
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue >= oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function burn(uint256 _value) onlyOwner public {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		 
		 

		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}

	function pause() onlyOwner public {
		paused = true;
	}

	function unpause() onlyOwner public {
		paused = false;
	}

	function setCrowdsale(address _crowdsale) onlyOwner public {
		crowdsale = _crowdsale;
	}

	 
	 
	function recoverTokens(ERC20 token) onlyOwner public {
		token.transfer(owner, tokensToBeReturned(token));
	}

	 
	 
	 
	function tokensToBeReturned(ERC20 token) public view returns (uint) {
		return token.balanceOf(this);
	}

}