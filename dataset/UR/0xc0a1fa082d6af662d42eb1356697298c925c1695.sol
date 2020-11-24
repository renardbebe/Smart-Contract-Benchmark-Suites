 

pragma solidity ^0.4.18;

 
library SafeMath {

  	 
  	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    	 
    	 
    	 
    	if (_a == 0) {
      		return 0;
    	}

    	uint256 c = _a * _b;
    	assert(c / _a == _b);

    	return c;
  	}

  	 
  	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    	 
    	uint256 c = _a / _b;
    	 

    	return c;
  	}

  	 
  	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    	assert(_b <= _a);
    	uint256 c = _a - _b;

    	return c;
  	}

  	 
  	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    	uint256 c = _a + _b;
    	assert(c >= _a);

    	return c;
  	}
}

 
contract Ownable {

    address public owner;

    address internal newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

  	 
    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

  	 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract Pausable is Ownable {
  	event Pause();
  	event Unpause();

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
    	emit Pause();
  	}

  	 
  	function unpause() public onlyOwner whenPaused {
    	paused = false;
    	emit Unpause();
  	}
}

 
contract ERC20 {
  	function totalSupply() public view returns (uint256);

  	function balanceOf(address _who) public view returns (uint256);

  	function allowance(address _owner, address _spender) public view returns (uint256);

  	function transfer(address _to, uint256 _value) public returns (bool);

  	function approve(address _spender, uint256 _value) public returns (bool);

  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  	event Transfer(address indexed from, address indexed to, uint256 value);

  	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, Pausable {
	
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    mapping(address => mapping(address => uint256)) internal allowed;
    
    uint256 totalSupply_;
    
  	 
  	function totalSupply() public view returns (uint256) {
    	return totalSupply_;
  	}    
    
  	     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
  	     
    function allowance(address _owner, address _spender) public view whenNotPaused returns (uint256) {
        return allowed[_owner][_spender];
    }
    
  	     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    	require(_value <= balances[msg.sender]);
    	require(_to != address(0));
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

  	 
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

  	 
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
	    require(_value <= balances[_from]);
	    require(_value <= allowed[_from][msg.sender]);
	    require(_to != address(0));    	

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

	 
    function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  	 
    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool) {
    	uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

  	 
    function spenderDecreaseApproval(address _from, uint256 _subtractedValue) public whenNotPaused returns (bool) {
    	uint256 oldValue = allowed[_from][msg.sender];
        if (_subtractedValue >= oldValue) {
            allowed[_from][msg.sender] = 0;
        } else {
            allowed[_from][msg.sender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        return true;
    }
}

 
contract BCLToken is StandardToken {
    string public name = "Blockchainlock Token";
    string public symbol = "BCL";
    uint8 public decimals = 18;

  	 
    constructor() public {
        totalSupply_ = 360 * (10**26);			 
        balances[msg.sender] = totalSupply_; 	 
    }
}