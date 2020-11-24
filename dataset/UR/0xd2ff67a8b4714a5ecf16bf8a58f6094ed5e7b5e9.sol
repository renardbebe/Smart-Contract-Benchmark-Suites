 

pragma solidity ^0.4.16;

contract ERC20Basic 
{
	uint256 public totalSupply;
	function balanceOf(address who) constant public returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic
{
	function allowance(address owner, address spender) constant  public returns (uint256);
	function transferFrom(address from, address to, uint256 value)  public returns (bool);
	function approve(address spender, uint256 value)  public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath 
{
    
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
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

contract BasicToken is ERC20Basic 
{
    
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(msg.data.length >= (2*32) + 4);      
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) constant public returns (uint256 balance) {
		return balances[_owner];
	}
}

contract StandardToken is ERC20, BasicToken 
{

	mapping (address => mapping (address => uint256)) allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
	{
		require(msg.data.length >= (3*32) + 4);      
		var _allowance = allowed[_from][msg.sender];
		
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
    return true;
	}

    function approve(address _spender, uint256 _value) public returns (bool)
	{
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant public returns (uint256 remaining) 
	{
		return allowed[_owner][_spender];
	}

}

contract Ownable 
{
    address public owner;

	function Ownable()  public
	{
		owner = msg.sender;
	}

	modifier onlyOwner() 
	{
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner)  public onlyOwner
	{
		require(newOwner != address(0));      
		owner = newOwner;
	}
}

contract BurnableToken is StandardToken, Ownable 
{
    uint256 endIco = 1527854400;  

    modifier BurnAll() 
    { 
		require(now > endIco && balances[owner] > 0);  
		_;
	}
    
	function burn()  public BurnAll 
	{
		uint256 surplus = balances[owner];
		totalSupply = totalSupply.sub(1000);
		balances[owner] = 0;
		Burn(owner, surplus);
	}
	event Burn(address indexed burner, uint indexed value);
}

contract OSCoinToken is BurnableToken 
{
	string public constant name = "OSCoin";   
	string public constant symbol = "OSC";    
	uint32 public constant decimals = 18;

	uint256 public INITIAL_SUPPLY = 2000000 * 1 ether;

	function OSCoinToken()  public
	{
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		
		allowed[owner][0x740F7A070C283edc1cAd9351A67aD3b513f3136a] = (totalSupply).div(100).mul(11);      
		Approval(owner,0x740F7A070C283edc1cAd9351A67aD3b513f3136a, (totalSupply).div(100).mul(11));      
	}
}