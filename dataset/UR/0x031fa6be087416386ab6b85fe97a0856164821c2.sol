 

pragma solidity ^0.4.24;

interface ERC20 {
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	function name() external view returns (string);
	function symbol() external view returns (string);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _to, uint256 _value) external payable returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) external payable returns (bool success);
	function approve(address _spender, uint256 _value) external payable returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
library SafeMath {
	
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint256 a, uint256 b) pure internal returns (uint256 c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint256 a, uint256 b) pure internal returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) pure internal returns (uint256 c) {
		return a / b;
	}
}

contract RankCoin is ERC20, ERC165 {
	using SafeMath for uint256;
	
	event ChangeName(address indexed user, string name);
	event ChangeMessage(address indexed user, string message);
	
	 
	string constant public NAME = "RankCoin";
	string constant public SYMBOL = "RC";
	uint8 constant public DECIMALS = 18;
	uint256 constant public TOTAL_SUPPLY = 100000000000 * (10 ** uint256(DECIMALS));
	
	address public author;
	
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;
	
	 
	address[] public users;
	mapping(address => string) public names;
	mapping(address => string) public messages;
	
	function getUserCount() view public returns (uint256) {
		return users.length;
	}
	
	 
	mapping(address => bool) internal userToIsExisted;
	
	constructor() public {
		
		author = msg.sender;
		
		balances[author] = TOTAL_SUPPLY;
		
		emit Transfer(0x0, author, TOTAL_SUPPLY);
	}
	
	 
	function checkAddressMisused(address target) internal view returns (bool) {
		return
			target == address(0) ||
			target == address(this);
	}
	
	 
	function name() external view returns (string) {
		return NAME;
	}
	
	 
	function symbol() external view returns (string) {
		return SYMBOL;
	}
	
	 
	function decimals() external view returns (uint8) {
		return DECIMALS;
	}
	
	 
	function totalSupply() external view returns (uint256) {
		return TOTAL_SUPPLY;
	}
	
	 
	function balanceOf(address user) external view returns (uint256 balance) {
		return balances[user];
	}
	
	 
	function transfer(address to, uint256 amount) external payable returns (bool success) {
		
		 
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[msg.sender]);
		
		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[to] = balances[to].add(amount);
		
		 
		if (to != author && userToIsExisted[to] != true) {
			users.push(to);
			userToIsExisted[to] = true;
		}
		
		emit Transfer(msg.sender, to, amount);
		
		return true;
	}
	
	 
	function approve(address spender, uint256 amount) external payable returns (bool success) {
		
		allowed[msg.sender][spender] = amount;
		
		emit Approval(msg.sender, spender, amount);
		
		return true;
	}
	
	 
	function allowance(address user, address spender) external view returns (uint256 remaining) {
		return allowed[user][spender];
	}
	
	 
	function transferFrom(address from, address to, uint256 amount) external payable returns (bool success) {
		
		 
		require(checkAddressMisused(to) != true);
		
		require(amount <= balances[from]);
		require(amount <= allowed[from][msg.sender]);
		
		balances[from] = balances[from].sub(amount);
		balances[to] = balances[to].add(amount);
		
		 
		if (to != author && userToIsExisted[to] != true) {
			users.push(to);
			userToIsExisted[to] = true;
		}
		
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
		
		emit Transfer(from, to, amount);
		
		return true;
	}
	
	 
	function getUsersByBalance() view public returns (address[]) {
		address[] memory _users = new address[](users.length);
		
		for (uint256 i = 0; i < users.length; i += 1) {
			
			uint256 balance = balances[users[i]];
			
			for (uint256 j = i; j > 0; j -= 1) {
				if (balances[_users[j - 1]] < balance) {
					_users[j] = _users[j - 1];
				} else {
					break;
				}
			}
			
			_users[j] = users[i];
		}
		
		return _users;
	}
	
	 
	function getRank(address user) view public returns (uint256) {
		
		uint256 rank = 1;
		uint256 balance = balances[user];
		
		for (uint256 i = 0; i < users.length; i += 1) {
			if (balances[users[i]] > balance) {
				rank += 1;
			}
		}
		
		return rank;
	}
	
	 
	function setName(string _name) public {
		
		names[msg.sender] = _name;
		
		emit ChangeName(msg.sender, _name);
	}
	
	 
	function setMessage(string message) public {
		
		messages[msg.sender] = message;
		
		emit ChangeMessage(msg.sender, message);
	}
	
	 
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		return
			 
			interfaceID == this.supportsInterface.selector ||
			 
			interfaceID == 0x942e8b22 ||
			interfaceID == 0x36372b07;
	}
}