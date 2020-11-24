 

pragma solidity ^0.5.4;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract BOB is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor()  public  {
        balanceOf[msg.sender] = 1000000000000000000000000000;
        totalSupply = 1000000000000000000000000000;
        name = "BOBO Chain";
        symbol = "BOB";
        decimals = 18;
		owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
		require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
		uint previousBalances = balanceOf[msg.sender] + balanceOf[_to];		
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
		assert(balanceOf[msg.sender]+balanceOf[_to]==previousBalances);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0));
		require (_value > 0); 
        require (balanceOf[_from] >= _value) ;
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require (_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);
		require (_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        require (freezeOf[msg.sender] >= _value);
		require (_value > 0) ; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
}