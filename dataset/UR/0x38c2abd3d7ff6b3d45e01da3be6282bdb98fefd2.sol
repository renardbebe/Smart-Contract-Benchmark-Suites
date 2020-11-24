 

pragma solidity ^0.4.18;

 
contract Restriction {
	address internal owner = msg.sender;
	mapping(address => bool) internal granted;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	 
	function changeOwner(address _owner) external onlyOwner {
		require(_owner != address(0) && _owner != owner);
		owner = _owner;
		ChangeOwner(owner);
	}
	event ChangeOwner(address indexed _owner);
} 

 
interface TokenReceiver {
    function tokenFallback(address, uint256, bytes) external;
}

 
contract BasicToken is Restriction {
	string public name;
	string public symbol;
	uint8 public decimals = 0;
	uint256 public totalSupply = 0;

	mapping(address => uint256) private balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);	

	 
	function BasicToken(string _name, string _symbol, uint8 _decimals, uint256 _supply) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		_mintTokens(_supply);
	}
	 
	function balanceOf(address _holder) external view returns (uint256) {
		return balances[_holder];
	}
	 
	function transfer(address _to, uint256 _amount) external returns (bool) {
		return _transfer(msg.sender, _to, _amount, "");
	}
	 
	function transfer(address _to, uint256 _amount, bytes _data) external returns (bool) {
		return _transfer(msg.sender, _to, _amount, _data);
	}
	 
	function _transfer(address _from, address _to, uint256 _amount, bytes _data) internal returns (bool) {
		require(_to != address(0)
			&& _to != address(this)
			&& _from != address(0)
			&& _from != _to
			&& _amount > 0
			&& balances[_from] >= _amount
			&& balances[_to] + _amount > balances[_to]
		);
		balances[_from] -= _amount;
		balances[_to] += _amount;
		uint size;
		assembly {
			size := extcodesize(_to)
		}
		if(size > 0){
			TokenReceiver(_to).tokenFallback(msg.sender, _amount, _data);
		}
		Transfer(_from, _to, _amount);
		return true;
	}
	 
	function _mintTokens(uint256 _amount) internal onlyOwner returns (bool success){
		require(totalSupply + _amount > totalSupply);
		totalSupply += _amount;
		balances[msg.sender] += _amount;
		Transfer(address(0), msg.sender, _amount);
		return true;
	}
	 
	function _burnTokens(uint256 _amount) internal returns (bool success){
		require(balances[msg.sender] > _amount);
		totalSupply -= _amount;
		balances[owner] -= _amount;
		Transfer(msg.sender, address(0), _amount);
		return true;
	}
}

contract ERC20Compatible {
	mapping(address => mapping(address => uint256)) private allowed;

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);	
	function _transfer(address _from, address _to, uint256 _amount, bytes _data) internal returns (bool success);

	 
	function allowance(address _owner, address _spender) external constant returns (uint256 amount) {
		return allowed[_owner][_spender];
	}
	 
	function approve(address _spender, uint256 _amount) external returns (bool success) {
		require( _spender != address(0) 
			&& _spender != msg.sender 
			&& (_amount == 0 || allowed[msg.sender][_spender] == 0)
		);
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}
	 
	function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success) {
		require(allowed[_from][msg.sender] >= _amount);
		allowed[_from][msg.sender] -= _amount;
		return _transfer(_from, _to, _amount, "");
	}
}

contract Regulatable is Restriction {
	function _mintTokens(uint256 _amount) internal onlyOwner returns (bool success);
	function _burnTokens(uint256 _amount) internal returns (bool success);
	 
	function mintTokens(uint256 _amount) external onlyOwner returns (bool){
		return _mintTokens(_amount);
	}
	 
	function burnTokens(uint256 _amount) external returns (bool){
		return _burnTokens(_amount);
	}
}

contract Token is ERC20Compatible, Regulatable, BasicToken {
	string private constant NAME = "Crypto USD";
	string private constant SYMBOL = "USDc";
	uint8 private constant DECIMALS = 2;
	uint256 private constant SUPPLY = 201205110 * uint256(10) ** DECIMALS;
	
	function Token() public 
		BasicToken(NAME, SYMBOL, DECIMALS, SUPPLY) {
	}
}