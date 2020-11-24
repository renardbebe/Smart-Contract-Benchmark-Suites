 

pragma solidity ^0.4.24;
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

 
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Burn(address _address, uint256 _value);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
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
  
     
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);                  
        balances[msg.sender] = balances[msg.sender].sub(_value);  
        totalSupply_ = totalSupply_.sub(_value);                  
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        totalSupply_ = totalSupply_.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() public {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); 
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}


 
contract VTest is StandardToken, Ownable {
    address public icoAccount       = address(0x8Df21F9e41Dd7Bd681fcB6d49248f897595a5304);   
	address public marketingAccount = address(0x83313B9c27668b41151509a46C1e2a8140187362);   
	address public advisorAccount   = address(0xB6763FeC658338A7574a796Aeda45eb6D81E69B9);   
	mapping(address => bool) public owners;
	
	string public name   = "VTest";   
	string public symbol = "VT";        
	uint public decimals = 18;
	uint public INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));   
	
	mapping(address => bool) public icoProceeding;  
	
	bool public released      = false;    
    uint8 public transferStep = 0;        
	bool public stepLockCheck = true;     
    mapping(uint8 => mapping(address => bool)) public holderStep;  
	
	event ReleaseToken(address _owner, bool released);
	event ChangeTransferStep(address _owner, uint8 newStep);
	
	  
	constructor() public {
	    require(msg.sender != address(0));
		totalSupply_ = INITIAL_SUPPLY;       
		balances[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
		
		super.transfer(icoAccount, INITIAL_SUPPLY.mul(45).div(100));        
		super.transfer(marketingAccount, INITIAL_SUPPLY.mul(15).div(100));  
		super.transfer(advisorAccount, INITIAL_SUPPLY.mul(10).div(100));    
		
		
		 
		owners[msg.sender] = true;
		owners[icoAccount] = true;
		owners[marketingAccount] = true;
		owners[advisorAccount] = true;
		
		holderStep[0][msg.sender] = true;
		holderStep[0][icoAccount] = true;
		holderStep[0][marketingAccount] = true;
		holderStep[0][advisorAccount] = true;
    }	
	 
	function registIcoAddress(address _icoAddress) onlyOwner public {
	    require(_icoAddress != address(0));
	    require(!icoProceeding[_icoAddress]);
	    icoProceeding[_icoAddress] = true;
	}
	function unregisttIcoAddress(address _icoAddress) onlyOwner public {
	    require(_icoAddress != address(0));
	    require(icoProceeding[_icoAddress]);
	    icoProceeding[_icoAddress] = false;
	}
	 
	function releaseToken() onlyOwner public {
	    require(!released);
	    released = true;
	    emit ReleaseToken(msg.sender, released);
	}
	function lockToken() onlyOwner public {
		require(released);
		released = false;
		emit ReleaseToken(msg.sender, released); 
	}	
	function changeTransferStep(uint8 _changeStep) onlyOwner public {
	    require(transferStep != _changeStep);
	    require(_changeStep >= 0 && _changeStep < 10);
        transferStep = _changeStep;
        emit ChangeTransferStep(msg.sender, _changeStep);
	}
	function changeTransferStepLock(bool _stepLock) onlyOwner public {
	    require(stepLockCheck != _stepLock);
	    stepLockCheck = _stepLock;
	}
	
	 
	modifier onlyReleased() {
	    require(released);
	    _;
	}
	modifier onlyStepUnlock(address _funderAddr) {
	    if (!owners[_funderAddr]) {
	        if (stepLockCheck) {
    		    require(checkHolderStep(_funderAddr));
	        }    
	    }
	    _;
	}
	
	 
    function registHolderStep(address _contractAddr, uint8 _icoStep, address _funderAddr) public returns (bool) {
		require(icoProceeding[_contractAddr]);
		require(_icoStep > 0);
        holderStep[_icoStep][_funderAddr] = true;
        
        return true;
    }
	 
	function checkHolderStep(address _funderAddr) public view returns (bool) {
		bool returnBool = false;        
        for (uint8 i = transferStep; i >= 1; i--) {
            if (holderStep[i][_funderAddr]) {
                returnBool = true;
                break;
            }
        }
		return returnBool;
	}
	
	
	 
	function transfer(address to, uint256 value) public onlyReleased onlyStepUnlock(msg.sender) returns (bool) {
	    return super.transfer(to, value);
    }
    function allowance(address owner, address spender) public onlyReleased view returns (uint256) {
        return super.allowance(owner,spender);
    }
    function transferFrom(address from, address to, uint256 value) public onlyReleased onlyStepUnlock(msg.sender) returns (bool) {
        
        return super.transferFrom(from, to, value);
    }
    function approve(address spender, uint256 value) public onlyReleased returns (bool) {
        return super.approve(spender,value);
    }
	 
	function burn(uint256 _value) public onlyOwner returns (bool success) {
		return super.burn(_value);
	}
	function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
		return super.burnFrom(_from, _value);
	}
	
    function transferSoldToken(address _contractAddr, address _to, uint256 _value) public returns(bool) {
	    require(icoProceeding[_contractAddr]);
	    require(balances[icoAccount] >= _value);
	    balances[icoAccount] = balances[icoAccount].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(icoAccount, _to, _value);
        return true;
	}
	function transferBonusToken(address _to, uint256 _value) public onlyOwner returns(bool) {
	    require(balances[icoAccount] >= _value);
	    balances[icoAccount] = balances[icoAccount].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(icoAccount, _to, _value);
		return true;
	}
	function transferAdvisorToken(address _to, uint256 _value)  public onlyOwner returns (bool) {
	    require(balances[advisorAccount] >= _value);
	    balances[advisorAccount] = balances[advisorAccount].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(advisorAccount, _to, _value);
		return true;
	}
}