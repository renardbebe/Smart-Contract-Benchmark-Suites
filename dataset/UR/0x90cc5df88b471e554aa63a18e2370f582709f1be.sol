 

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


 

interface ERC20 {

     
    function balanceOf(address _owner) external constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
     
     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function allowance(address _owner, address _spender) external returns (uint256 remaining);

     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}


contract POMZ is ERC20 {

     
	using SafeMath for uint256;

     
    uint public constant decimals = 8;
    uint256 public totalSupply = 5000000000 * 10 ** decimals;
    string public constant name = "POMZ";
    string public constant symbol = "POMZ";

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
	constructor() public {
		balances[msg.sender] = totalSupply;
	}

     
    function balanceOf(address _owner) public view returns (uint256) {
	    return balances[_owner];
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        uint256 previousBalances = balances[_to];
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        assert(balances[_to].sub(_value) == previousBalances);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        uint256 previousBalances = balances[_to];
	    balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
		assert(balances[_to].sub(_value) == previousBalances);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
	function () public {
        revert();
    }

}