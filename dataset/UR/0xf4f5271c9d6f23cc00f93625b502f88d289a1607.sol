 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
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
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
 
 
contract WithdrawConfirmation is Owned {
	event Confirmation(address indexed sender, uint indexed withdrawId);
	event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
	event WithdrawCreated(address indexed destination, uint indexed value, uint indexed id);
	event Execution(uint indexed withdrawId);
	event ExecutionFailure(uint indexed withdrawId);

	mapping(address => bool) public isOwner;
	mapping(uint => Withdraw) public withdraws;
	mapping(uint => mapping(address => bool)) public confirmations;
	address[] public owners;
	uint public withdrawCount;
	
	struct Withdraw {
		address destination;
		uint value;
		bool executed;
	}
	
	modifier hasPermission() {
        require(isOwner[msg.sender]);
        _;
    }
	
	modifier ownerDoesNotExist(address _owner) {
        require(!isOwner[_owner]);
        _;
    }
	
	modifier ownerExists(address _owner) {
        require(isOwner[_owner]);
        _;
    }
	
	modifier notNull(address _address) {
        require(_address != 0);
        _;
    }
	
	modifier notConfirmed(uint withdrawId, address _owner) {
        require(!confirmations[withdrawId][_owner]);
        _;
    }
	
	modifier withdrawExists(uint withdrawId) {
        require(withdraws[withdrawId].destination != 0);
        _;
    }
	
	modifier confirmed(uint withdrawId, address _owner) {
        require(confirmations[withdrawId][_owner]);
        _;
    }
	
	modifier notExecuted(uint withdrawId) {
        require(!withdraws[withdrawId].executed);
        _;
    }
	
	constructor() public {
		owners.push(owner);
		isOwner[owner] = true;
	}
	
	function addOwner(address _owner) public ownerDoesNotExist(_owner) hasPermission {
		isOwner[_owner] = true;
		owners.push(_owner);
		emit OwnerAddition(_owner);
	}
	
	function removeOwner(address _owner) public ownerExists(_owner) hasPermission {
		require(_owner != owner);
        isOwner[_owner] = false;
        for(uint i=0; i < owners.length - 1; i++) {
            if(owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
		}
        owners.length -= 1;
        emit OwnerRemoval(_owner);
    }
	
	function createWithdraw(address to, uint value) public ownerExists(msg.sender) notNull(to) {
		uint withdrawId = withdrawCount;
		withdraws[withdrawId] = Withdraw({
			destination: to,
			value: value,
			executed: false
		});
		withdrawCount += 1;
		confirmations[withdrawId][msg.sender] = true;
		emit WithdrawCreated(to, value, withdrawId);
		executeWithdraw(withdrawId);
	}
	
	function isConfirmed(uint withdrawId) public constant returns(bool) {
		for(uint i=0; i < owners.length; i++) {
            if(!confirmations[withdrawId][owners[i]])
                return false;
        }
		return true;
	}
	
	function confirmWithdraw(uint withdrawId) public ownerExists(msg.sender) withdrawExists(withdrawId) notConfirmed(withdrawId, msg.sender) {
		confirmations[withdrawId][msg.sender] = true;
		emit Confirmation(msg.sender, withdrawId);
		executeWithdraw(withdrawId);
	}
	
	function executeWithdraw(uint withdrawId) public ownerExists(msg.sender) confirmed(withdrawId, msg.sender) notExecuted(withdrawId) {
		if(isConfirmed(withdrawId)) {
			Withdraw storage with = withdraws[withdrawId];
			with.executed = true;
			if(with.destination.send(with.value))
				emit Execution(withdrawId);
			else {
				emit ExecutionFailure(withdrawId);
                with.executed = false;
			}
		}
	}
}

 
 
 
 
contract AkilosToken is ERC20Interface, Owned, WithdrawConfirmation {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
	
	bool public started = false;
	uint public currentRate;
	uint public minimalInvestment = 0.1 ether;
	uint public currentRoundSales;
	uint public roundNumber;
	uint public roundOneTotal;
	uint public roundTwoTotal;
	
	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	 
    event Burn(address indexed from, uint value);

     
     
     
    constructor() public {
        symbol = "ALS";
        name = "Akilos";
        decimals = 18;
        _totalSupply = 15000000 * 10**uint(decimals);
		roundOneTotal = 3000000 * 10**uint(decimals);
		roundTwoTotal = 7000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
	
	function setCurrentRate(uint _rate) public onlyOwner () {
		currentRate = _rate;
	}
	
	function setStarted(bool _started) public onlyOwner () {
		started = _started;
	}
	
	function setRoundNumber(uint _roundNumber) public onlyOwner () {
		roundNumber = _roundNumber;
	}
	
	function resetCurrentRoundSales() public onlyOwner () {
		currentRoundSales = 0;
	}

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
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


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
		require(started);
		require(msg.value >= minimalInvestment);
		require(currentRate != 0);
		require(roundNumber != 0);
		uint tokens;
		tokens = msg.value * currentRate;
		if(roundNumber == 1) {
			require(currentRoundSales.add(tokens) <= roundOneTotal);
		}
		if(roundNumber == 2) {
			require(currentRoundSales.add(tokens) <= roundTwoTotal);
		}
        balances[msg.sender] = balances[msg.sender].add(tokens);
		balances[owner] = balances[owner].sub(tokens);
		currentRoundSales = currentRoundSales.add(tokens);
        emit Transfer(owner, msg.sender, tokens);
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
	
	 
     
     
    function burn(uint _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);  
		require(_value > 0);  
        balances[msg.sender] = balances[msg.sender].sub(_value);  
        _totalSupply = _totalSupply.sub(_value);  
        emit Burn(msg.sender, _value);
        return true;
    }
}