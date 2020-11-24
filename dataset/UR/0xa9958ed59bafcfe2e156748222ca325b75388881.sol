 

pragma solidity ^0.4.21;
 

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
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

 

 
contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	 
	function Ownable() public {
		owner = msg.sender;
	}
	
	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	 
	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

contract Destroyable is Ownable {
	 
	function destroy() public onlyOwner {
		selfdestruct(owner);
	}
}

interface Token {
	function balanceOf(address who) view external returns (uint256);
	
	function allowance(address _owner, address _spender) view external returns (uint256);
	
	function transfer(address _to, uint256 _value) external returns (bool);
	
	function approve(address _spender, uint256 _value) external returns (bool);
	
	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool);
	
	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool);
}

contract TokenPool is Ownable, Destroyable {
	using SafeMath for uint256;
	
	Token public token;
	address public spender;
	
	event AllowanceChanged(uint256 _previousAllowance, uint256 _allowed);
	event SpenderChanged(address _previousSpender, address _spender);
	
	
	 
	function TokenPool(address _token, address _spender) public{
		require(_token != address(0) && _spender != address(0));
		token = Token(_token);
		spender = _spender;
	}
	
	 
	function Balance() view public returns (uint256 _balance) {
		return token.balanceOf(address(this));
	}
	
	 
	function Allowance() view public returns (uint256 _balance) {
		return token.allowance(address(this), spender);
	}
	
	 
	function setUpAllowance() public onlyOwner {
		emit AllowanceChanged(token.allowance(address(this), spender), token.balanceOf(address(this)));
		token.approve(spender, token.balanceOf(address(this)));
	}
	
	 
	function updateAllowance() public onlyOwner {
		uint256 balance = token.balanceOf(address(this));
		uint256 allowance = token.allowance(address(this), spender);
		uint256 difference = balance.sub(allowance);
		token.increaseApproval(spender, difference);
		emit AllowanceChanged(allowance, allowance.add(difference));
	}
	
	 
	function destroy() public onlyOwner {
		token.transfer(owner, token.balanceOf(address(this)));
		selfdestruct(owner);
	}
	
	 
	function changeSpender(address _spender) public onlyOwner {
		require(_spender != address(0));
		emit SpenderChanged(spender, _spender);
		token.approve(spender, 0);
		spender = _spender;
		setUpAllowance();
	}
	
}