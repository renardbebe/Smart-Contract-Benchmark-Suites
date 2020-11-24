 

pragma solidity 0.5.9;

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

contract ServiceInterface { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}

contract StorexOwner {
	address public owner;
	
	event OwnershipTransferred(address indexed _from, address indexed _to);
	
	constructor() public {
		owner = msg.sender;
	}
	
	modifier isOwner {
		require(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address _newOwner) public isOwner {
		owner = _newOwner;
		emit OwnershipTransferred(msg.sender, _newOwner);
	}
}

contract StorexToken is ERC20Interface, StorexOwner {
	using SafeMath for uint;
	
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
	
	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;
	
	constructor() public {
		name = "Storex";
		symbol = "STRX";
		decimals = 18;
		_totalSupply = 2000000 * 10**uint(decimals);
		
		balances[owner] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);
	}
	
	function totalSupply() public view returns (uint256) {
		return _totalSupply.sub(balances[address(0)]);
	}
	
	function balanceOf(address tokenOwner) public view returns (uint256 balance) {
		return balances[tokenOwner];
	}
	
	function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
	
	function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
	
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
	
	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
	
	function() external payable {
        revert();
    }
    
    function approveAndCall(address spender, uint256 value, bytes memory extraData) public returns (bool success) {
		ServiceInterface service = ServiceInterface(spender);
		if (approve(spender, value)) {
			service.receiveApproval(msg.sender, value, address(this), extraData);
			return true;
		}
	}
	
	function transferAnyERC20Token(address tokenAddress, uint tokens) public isOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}