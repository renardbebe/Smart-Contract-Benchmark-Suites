 

 
 
 
 
 

pragma solidity ^0.4.24;

 
 
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

contract Verify_U42 {
	 
	using SafeMath for uint256;

	string public constant name = "Verification token for U42 distribution";
	string public constant symbol = "VU42";
	uint8 public constant decimals = 18;
	uint256 public constant initialSupply = 525000000 * (10 ** uint256(decimals));
	uint256 internal totalSupply_ = initialSupply;
	address public contractOwner;

	 
	mapping(address => uint256) balances;

	 
	mapping (address => mapping (address => uint256)) internal allowed;

	 
	event Transfer (
		address indexed from, 
		address indexed to, 
		uint256 value );

	event TokensBurned (
		address indexed burner, 
		uint256 value );

	event Approval (
		address indexed owner,
		address indexed spender,
		uint256 value );


	constructor() public {
		 
		balances[msg.sender] = totalSupply_;

		 
		contractOwner=msg.sender;

		 
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function ownerBurn ( 
			uint256 _value )
		public returns (
			bool success) {

		 
		require(msg.sender == contractOwner);

		 
		require(_value <= balances[contractOwner]);

		 
		totalSupply_ = totalSupply_.sub(_value);

		 
		balances[contractOwner] = balances[contractOwner].sub(_value);

		 
		emit Transfer(contractOwner, address(0), _value);
		emit TokensBurned(contractOwner, _value);

		return true;

	}
	
	
	function totalSupply ( ) public view returns (
		uint256 ) {

		return totalSupply_;
	}

	function balanceOf (
			address _owner ) 
		public view returns (
			uint256 ) {

		return balances[_owner];
	}

	function transfer (
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

   	 
   	 
   	 
	function approve (
			address _spender, 
			uint256 _value ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function increaseApproval (
			address _spender, 
			uint256 _addedValue ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (
			address _spender,
			uint256 _subtractedValue ) 
		public returns (
			bool ) {

		uint256 oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function allowance (
			address _owner, 
			address _spender ) 
		public view returns (
			uint256 remaining ) {

		return allowed[_owner][_spender];
	}

	function transferFrom (
			address _from, 
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

}