 

pragma solidity ^0.5.1;

 

contract ERC20Standard {
    using SafeMath for uint256;
	uint256 public totalSupply;
	string public name;
	uint8 public decimals;
	string public symbol;
	address public owner;

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

   constructor(uint256 _totalSupply, string memory _symbol, string memory _name, uint8 _decimals) public {
		symbol = _symbol;
		name = _name;
        decimals = _decimals;
		owner = msg.sender;
        totalSupply = SafeMath.mul(_totalSupply ,(10 ** uint256(decimals)));
        balances[owner] = totalSupply;
  }
	 
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == SafeMath.add(size,4));
		_;
	} 

	function balanceOf(address _owner) view public returns (uint256) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint256 _value) onlyPayloadSize(2*32) public returns(bool){
		require(balances[msg.sender] >= _value && _value >= 0);
	    require(balances[_recipient].add(_value)>= balances[_recipient]);
	    balances[msg.sender] = balances[msg.sender].sub(_value) ;
	    balances[_recipient] = balances[_recipient].add(_value) ;
	    emit Transfer(msg.sender, _recipient, _value);  
	    return true;
    }

	function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);
		require(balances[_to].add(_value) >= balances[_to]);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value) ;
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value) ;
        emit Transfer(_from, _to, _value);
        return true;
    }

	function approve(address _spender, uint256 _value) public returns(bool){
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) view public returns (uint256) {
		return allowed[_owner][_spender];
	}

	 
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
		);
		
	 
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
		);

}
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}