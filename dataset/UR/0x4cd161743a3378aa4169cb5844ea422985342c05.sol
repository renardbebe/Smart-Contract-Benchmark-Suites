 

pragma solidity ^0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BEX is ERC20Interface {
	
	
	 

	function totalSupply()public constant returns (uint) {
		return totalBEXSupply;
	}
	
	function balanceOf(address tokenOwner)public constant returns (uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens)public returns (bool success) {
		if (balances[msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
            
			balances[msg.sender] -= tokens;
			balances[to] += tokens;
			emit Transfer(msg.sender, to, tokens);
			return true;
		} else {
			return false;
		}
	}
	

	function transferFrom(address from, address to, uint tokens)public returns (bool success) {
		if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
           
            
			balances[from] -= tokens;
			allowed[from][msg.sender] -= tokens;
			balances[to] += tokens;
			emit Transfer(from, to, tokens);
			return true;
		} else {
			return false;
		}
	}
	
	
	function approve(address spender, uint tokens)public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	
	function allowance(address tokenOwner, address spender)public constant returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}
	
	event Transfer(address indexed from, address indexed to, uint tokens); 
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);  
	
	 
		
    string public name = "BEX";
    string public symbol = "BEX";
    uint8 public decimals = 18;
     
	uint256 private totalBEXSupply = 1000000000000000000000000000;
	uint256 private _totalBalance = totalBEXSupply;
	
	
	
	address public owner = 0x0;
	address public operater = 0x0;
	
    mapping (address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

	uint32 private constant MAX_UINT32 = 0xFFFFFFFF;
	
	event SendTo(uint32 indexed _idx, uint8 indexed _type, address _from, address _to, uint256 _value);
	
	uint32 sendToIdx = 0;
	
	function safeToNextIdx() internal{
        if (sendToIdx >= MAX_UINT32){
			sendToIdx = 1;
		}
        else{
			sendToIdx += 1;
		}
    }

    function BEX() public {
	
		owner = msg.sender;
    }
	

	
	function sendByOwner(address _to, uint256 _value) public {
		if (msg.sender != owner && msg.sender != operater) 
		{
		    revert();
		}
		
		if(_to == 0x0){
			revert();
		}
				

		if(_value > _totalBalance){
			revert();
		}

		_totalBalance -= _value;
		balances[msg.sender] += _value;
			
		emit Transfer(operater, msg.sender, _value);
			
		safeToNextIdx();
		emit SendTo(sendToIdx, 1, 0x0, _to, _value);
	
	}
	

	
	
	function changeOwner(address newOwner) public {
		if (msg.sender != owner) 
		{
		    revert();
		}
		else
		{
			owner = newOwner;
		}
    }
	
	function destruct() public {
		if (msg.sender != owner) 
		{
		    revert();
		}
		else
		{
			selfdestruct(owner);
		}
    }
	
	function setOperater(address op) public {
		if (msg.sender != owner && msg.sender != operater) 
		{
		    revert();
		}
		else
		{
			operater = op;
		}
    }
}