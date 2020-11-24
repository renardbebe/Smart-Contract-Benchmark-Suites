 

pragma solidity ^0.4.23;

contract Ownable {
	address public owner;

	 
	event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

	constructor() public {
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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = true;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ControllablePause is Pausable {
    mapping(address => bool) public transferWhiteList;
    
    modifier whenControllablePaused() {
        if (!paused) {
            require(transferWhiteList[msg.sender]);
        }
        _;
    }
    
    modifier whenControllableNotPaused() {
        if (paused) {
            require(transferWhiteList[msg.sender]);
        }
        _;
    }
    
    function addTransferWhiteList(address _new) public onlyOwner {
        transferWhiteList[_new] = true;
    }
    
    function delTransferWhiteList(address _del) public onlyOwner {
        delete transferWhiteList[_del];
    }
}

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address _owner) public view returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool);
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


 
contract ERC20 is ERC20Basic {
	function allowance(address _owner, address _spender) public view returns (uint256);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	function approve(address _spender, uint256 _value) public returns (bool);
	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    
     
	using SafeMath for uint256;

     
	mapping(address => uint256) balances;

	 
	uint256 totalSupply_;

     
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
	     
		require(_to != address(0));
		 
		require(_to != msg.sender);
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}


 
contract BurnableToken is BasicToken {

	event Burn(address indexed burner, uint256 value);

     
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(burner, _value);
		 
		emit Transfer(burner, address(0), _value);
	}
}


 
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_from != _to);
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

     
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

     
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

     
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}


contract PausableToken is BurnableToken, StandardToken, ControllablePause{
    
    function burn(uint256 _value) public whenControllableNotPaused {
        super.burn(_value);
    }
    
    function transfer(address _to, uint256 _value) public whenControllableNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenControllableNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


contract EOT is PausableToken {
	using SafeMath for uint256;
    
	string public constant name	= 'EOT';
	string public constant symbol = 'EOT';
	uint public constant decimals = 18;
	uint public constant INITIAL_SUPPLY = 21*10**26;

	constructor() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[owner] = totalSupply_;
		emit Transfer(address(0x0), owner, totalSupply_);
	}

	function batchTransfer(address[] _recipients, uint256 _value) public whenControllableNotPaused returns (bool) {
		uint256 count = _recipients.length;
		require(count > 0 && count <= 20);
		uint256 needAmount = count.mul(_value);
		require(_value > 0 && balances[msg.sender] >= needAmount);

		for (uint256 i = 0; i < count; i++) {
			transfer(_recipients[i], _value);
		}
		return true;
	}
	
     
    address public privateSaleWallet;

     
    address public crowdsaleAddress;
    
     
    address public lockTokensAddress;
    
    function setLockTokensAddress(address _lockTokensAddress) external onlyOwner {
        lockTokensAddress = _lockTokensAddress;
    }
	
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
         
        require(crowdsaleAddress == address(0));
        require(_crowdsaleAddress != address(0));
        crowdsaleAddress = _crowdsaleAddress;
    }

    function setPrivateSaleAddress(address _privateSaleWallet) external onlyOwner {
         
        require(privateSaleWallet == address(0));
        privateSaleWallet = _privateSaleWallet;
    }
    
     
    function () public {
        revert();
    }
}


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