 

pragma solidity ^0.4.26;

 
 
 


 
 
 
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}
	function sub(uint a, uint b) internal pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}
	function mul(uint a, uint b) internal pure returns (uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}
	function div(uint a, uint b) internal pure returns (uint c) {
		require(b > 0);
		c = a / b;
	}
}


 
 
 
 
contract ERC20Interface {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


 
 
 
contract Owned {
	address public owner;

	constructor(address admin) public {
		owner = admin;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	function isOwner() public view returns (bool is_owner) {
	    return msg.sender == owner;
	}
}


 
 
 
 
contract STARBIT is ERC20Interface, Owned {
	using SafeMath for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	bool _stopTrade;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	event Burn(address indexed burner, uint256 value);

	 
	 
	 
	constructor(address admin) Owned(admin) public {
		symbol = "ARM";
		name = "ARAMI";
		decimals = 18;
		_totalSupply = 1000000 * 10**uint(decimals);
		_stopTrade = false;
		balances[owner] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);
	}


	 
	 
	 
	function totalSupply() public view returns (uint) {
		return _totalSupply.sub(balances[address(0)]);
	}


	 
	 
	 
	function stopTrade() public onlyOwner {
		require(_stopTrade != true);
		_stopTrade = true;
	}


	 
	 
	 
	function startTrade() public onlyOwner {
		require(_stopTrade == true);
		_stopTrade = false;
	}


	 
	 
	 
	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}


	 
	 
	 
	 
	 
	function transfer(address to, uint tokens) public returns (bool success) {
		require(_stopTrade != true || isOwner());
		require(to > address(0));

		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}


	 
	 
	 
	 
	 
	 
	 
	 
	function approve(address spender, uint tokens) public returns (bool success) {
		require(_stopTrade != true);
		require(msg.sender != spender);

		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}


	 
	 
	 
	 
	 
	 
	 
	 
	 
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		require(_stopTrade != true);
		require(from > address(0));
		require(to > address(0));

		balances[from] = balances[from].sub(tokens);
		if(from != to && from != msg.sender) {
			allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		}
		balances[to] = balances[to].add(tokens);
		emit Transfer(from, to, tokens);
		return true;
	}


	 
	 
	 
	 
	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		require(_stopTrade != true);

		return allowed[tokenOwner][spender];
	}


	 
	 
	 
	 
	 
	function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
		require(_stopTrade != true);
		require(msg.sender != spender);

		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
		return true;
	}


	 
	 
	 
	function () external payable {
		revert();
	}


	 
	 
	 
	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}


	 
	 
	 
	function burn(uint256 tokens) public {
		require(tokens <= balances[msg.sender]);
		require(tokens <= _totalSupply);

		balances[msg.sender] = balances[msg.sender].sub(tokens);
		_totalSupply = _totalSupply.sub(tokens);
		emit Burn(msg.sender, tokens);
	}
}