 

pragma solidity ^0.4.24;
 
contract SafeMath {

	function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a * b;
		judgement(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
		judgement(b > 0);
		uint256 c = a / b;
		judgement(a == b * c + a % b);
		return c;
	}

	function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
		judgement(b <= a);
		return a - b;
	}

	function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a + b;
		judgement(c >= a && c >= b);
		return c;
	}

	function safeMulWithPresent(uint256 a, uint256 b) pure internal returns (uint256){
		uint256 c = safeDiv(safeMul(a, b), 1000);
		judgement(b == (c * 1000) / a);
		return c;
	}

	function judgement(bool assertion) pure internal {
		if (!assertion) {
			revert();
		}
	}
}

contract CREAuth {
	address public owner;
	constructor () public{
		owner = msg.sender;
	}
	event LogOwnerChanged (address msgSender);

	 
	modifier onlyOwner{
		assert(msg.sender == owner);
		_;
	}

	function setOwner(address newOwner) public onlyOwner returns (bool){
		require(newOwner != address(0));
		owner = newOwner;
		emit LogOwnerChanged(msg.sender);
		return true;
	}

}

contract Token is SafeMath {
	 
	uint256 public totalSupply;
	uint256 internal maxSupply;
	 
	 
	 
	function balanceOf(address _owner) public view returns (uint256 balance);

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success);

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool success);

	 
	 
	 
	function allowance(address _owner, address _spender) view public returns (uint256 remaining);

	 
	 

	function burn(uint256 amount) public returns (bool);

	 
	 
	function register(string key) public returns (bool);

	 
	 
	function mint(uint256 amountOfMint) public returns (bool);

	event Transfer                           (address indexed _from, address indexed _to, uint256 _value);
	event Approval                           (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn                               (address indexed _owner, uint256 indexed _value);
	event LogRegister                        (address user, string key);
	event Mint                               (address user,uint256 indexed amountOfMint);
}

contract StandardToken is Token, CREAuth {

	function transfer(address _to, uint256 _value) public returns (bool ind) {
		 
		 
		 

		require(_to != address(0));
		assert(balances[msg.sender] >= _value && _value > 0);

		balances[msg.sender] = safeSub(balances[msg.sender], _value);
		balances[_to] = safeAdd(balances[_to], _value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		 
		require(_to != address(0));
		assert(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);

		balances[_to] = safeAdd(balances[_to], _value);
		balances[_from] = safeSub(balances[_from], _value);
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_spender != address(0));
		require(_value > 0);
		require(allowed[msg.sender][_spender] == 0);
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function burn(uint256 amount) public onlyOwner returns (bool){

		require(balances[msg.sender] >= amount);
		balances[msg.sender] = safeSub(balances[msg.sender], amount);
		totalSupply = safeSub(totalSupply, amount);
		emit Burn(msg.sender, amount);
		return true;

	}

	function register(string key) public returns (bool){
		assert(bytes(key).length <= 64);

		keys[msg.sender] = key;
		emit LogRegister(msg.sender, key);
		return true;
	}

	function mint(uint256 amountOfMint) public onlyOwner returns (bool){
		 
		require(safeAdd(totalSupply, amountOfMint) <= maxSupply);
		totalSupply = safeAdd(totalSupply, amountOfMint);
		balances[msg.sender] = safeAdd(balances[msg.sender], amountOfMint);
		emit Mint(msg.sender ,amountOfMint);
		return true;
	}

	mapping(address => uint256)                      internal balances;
	mapping(address => mapping(address => uint256))  private  allowed;
	mapping(address => string)                       private  keys;

}

contract CREToken is StandardToken {

	string public name = "CoinRealEcosystem";                                    
	uint256 public decimals = 18;                                  
	string public symbol = "CRE";                                  


	constructor() public { 
		owner = msg.sender;
		totalSupply = 1000000000000000000000000000;
		 
		maxSupply = 2000000000000000000000000000;
		 
		balances[msg.sender] = totalSupply;
	}

	function() public {
		revert();
	}

}