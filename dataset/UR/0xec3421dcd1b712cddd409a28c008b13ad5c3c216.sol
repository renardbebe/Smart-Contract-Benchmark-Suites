 

pragma solidity ^0.4.24;




 
library SafeMath {




	 
	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
		 
		 
		 
		if (_a == 0) {
			return 0;
		}




		uint256 c = _a * _b;
		require(c / _a == _b);




		return c;
	}




	 
	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b > 0);  
		uint256 c = _a / _b;
		 




		return c;
	}




	 
	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b <= _a);
		uint256 c = _a - _b;




		return c;
	}




	 
	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		require(c >= _a);




		return c;
	}
}




 




contract Ownable {
	address internal _owner;




	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




	 
	constructor() public {
		_owner = msg.sender;
	}




	 
	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}




	 
	function transferOwnership(address newOwner) onlyOwner() public {
		require(newOwner != _owner);
		_transferOwnership(newOwner);
	}




	 
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}




	function getOwner() public constant returns(address) {
		return (_owner);
	}
}




 
contract Pausable is Ownable {
	event Paused();
	event Unpaused();




	bool public paused = false;








	 
	modifier whenNotPaused() {
			require(!paused);
		_;
	}




	 
	modifier whenPaused() {
		require(paused);
		_;
	}




	 
	function pause() public onlyOwner whenNotPaused {
		paused = true;
		emit Paused();
	}




	 
	function unpause() public onlyOwner whenPaused {
		paused = false;
		emit Unpaused();
	}
}




 
interface IERC20 {
	function totalSupply()
		external view returns (uint256);




	function balanceOf(address _who)
		external view returns (uint256);




	function allowance(address _owner, address _spender)
		external view returns (uint256);




	function transfer(address _to, uint256 _value)
		external returns (bool);




	function approve(address _spender, uint256 _value)
		external returns (bool);




	function transferFrom(address _from, address _to, uint256 _value)
		external returns (bool);




	event Transfer(
		address indexed from,
		address indexed to,
		uint256 value
	);




	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}








 
contract ERC20 is IERC20 {
	using SafeMath for uint256;




	mapping (address => uint256) internal balances_;




	mapping (address => mapping (address => uint256)) internal allowed_;




	uint256 internal totalSupply_;




	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}




	 
	function balanceOf(address _owner) public view returns (uint256) {
		return balances_[_owner];
	}




	 
	function allowance(
		address _owner,
		address _spender
	 )
		public
		view
		returns (uint256)
	{
		return allowed_[_owner][_spender];
	}




	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_value <= balances_[msg.sender]);
		require(_to != address(0));




		balances_[msg.sender] = balances_[msg.sender].sub(_value);
		balances_[_to] = balances_[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}




	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed_[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}




	 
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		returns (bool)
	{
		require(_value <= balances_[_from]);
		require(_value <= allowed_[_from][msg.sender]);
		require(_to != address(0));




		balances_[_from] = balances_[_from].sub(_value);
		balances_[_to] = balances_[_to].add(_value);
		allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}




	 
	function _mint(address _account, uint256 _amount) internal {
		require(_account != 0);
		totalSupply_ = totalSupply_.add(_amount);
		balances_[_account] = balances_[_account].add(_amount);
		emit Transfer(address(0), _account, _amount);
	}
}








 
contract ERC20Pausable is ERC20, Pausable {




	function transfer(
		address _to,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.transfer(_to, _value);
	}




	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}




	function approve(
		address _spender,
		uint256 _value
	)
		public
		whenNotPaused
		returns (bool)
	{
		return super.approve(_spender, _value);
	}
}












contract BetMatchToken is ERC20Pausable {
	string public constant name = "XBM";
	string public constant symbol = "XBM";
	uint8 public constant decimals = 18;




	uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));




	constructor () public {
		totalSupply_ = INITIAL_SUPPLY;
		balances_[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}
}