 

pragma solidity 0.4.23;

 
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


 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


contract PausableToken is StandardToken, BurnableToken, Claimable, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    	return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    	return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    	return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract LockableToken is PausableToken {
	using SafeMath for uint256;

	event Lock(address indexed owner, uint256 orderId, uint256 amount, uint256 releaseTimestamp);
	event UnLock(address indexed owner, uint256 orderId, uint256 amount);

	struct LockRecord {
	    
	     
	    uint256 orderId;

	     
	    uint256 amount;

	     
	    uint256 releaseTimestamp;
	}
	
	mapping (address => LockRecord[]) ownedLockRecords;
	mapping (address => uint256) ownedLockAmount;


	 
	function lockTokenForNode(uint256 _orderId, uint256 _amount, uint256 _timeSpan) public whenNotPaused {
		require(balances[msg.sender] >= _amount);
		require(_timeSpan > 0 && _timeSpan <= 3 * 365 days);
	    
		uint256 releaseTimestamp = now + _timeSpan;

	 	_lockToken(_orderId, _amount, releaseTimestamp);
	}


	function unlockToken() public whenNotPaused {
		LockRecord[] memory list = ownedLockRecords[msg.sender];
    require(list.length > 0);
		for(uint i = list.length - 1; i >= 0; i--) {
			 
			if (now >= list[i].releaseTimestamp) {
				_unlockTokenByIndex(i);
			}
			 
			if (i == 0) {
				break;
			}
		}
	}

	 
	function getLockByIndex(uint256 _index) public view returns(uint256, uint256, uint256) {
        LockRecord memory record = ownedLockRecords[msg.sender][_index];
        
        return (record.orderId, record.amount, record.releaseTimestamp);
    }

  function getLockAmount() public view returns(uint256) {
  	LockRecord[] memory list = ownedLockRecords[msg.sender];
  	uint sum = 0;
  	for (uint i = 0; i < list.length; i++) {
  		sum += list[i].amount;
  	}

  	return sum;
  }

   
  function getLockRecordCount() view public returns(uint256) {
    return ownedLockRecords[msg.sender].length;
  }

	 
	function _lockToken(uint256 _orderId, uint256 _amount, uint256 _releaseTimestamp) internal {
		require(ownedLockRecords[msg.sender].length <= 20);
    
    balances[msg.sender] = balances[msg.sender].sub(_amount);

		 
		 
		ownedLockRecords[msg.sender].push( LockRecord(_orderId, _amount, _releaseTimestamp) );
		ownedLockAmount[msg.sender] = ownedLockAmount[msg.sender].add(_amount);

		emit Lock(msg.sender, _orderId, _amount, _releaseTimestamp);
	}

	 
	function _unlockTokenByIndex(uint256 _index) internal {
		LockRecord memory record = ownedLockRecords[msg.sender][_index];
		uint length = ownedLockRecords[msg.sender].length;

		ownedLockRecords[msg.sender][_index] = ownedLockRecords[msg.sender][length - 1];
		delete ownedLockRecords[msg.sender][length - 1];
		ownedLockRecords[msg.sender].length--;

		ownedLockAmount[msg.sender] = ownedLockAmount[msg.sender].sub(record.amount);
		balances[msg.sender] = balances[msg.sender].add(record.amount);

		emit UnLock(msg.sender, record.orderId, record.amount);
	}

}

contract TuzyPayableToken is LockableToken {
	
	event Pay(address indexed owner, uint256 orderId, uint256 amount, uint256 burnAmount);

	address public cooAddress;

	 
	 

	 
	 


	 
	constructor() public {
		cooAddress = msg.sender;
	}
	
 
   
  function setCOO(address _newCOO) external onlyOwner {
      require(_newCOO != address(0));
      
      cooAddress = _newCOO;
  }

    
  function payOrder(uint256 _orderId, uint256 _amount, uint256 _burnAmount) external whenNotPaused {
  	require(balances[msg.sender] >= _amount);
  	
  	 
  	uint256 fee = _amount.sub(_burnAmount);
  	if (fee > 0) {
  		transfer(cooAddress, fee);
  	}
  	burn(_burnAmount);
  	emit Pay(msg.sender, _orderId, _amount, _burnAmount);
  }
}

contract TuzyCoin is TuzyPayableToken {
	string public name    = "Tuzy Coin";
	string public symbol  = "TUC";
	uint8 public decimals = 8;

	 
	uint256 public constant INITIAL_SUPPLY = 1600000000;

	constructor() public {
		totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
		balances[msg.sender] = totalSupply_;
	}

  function globalBurnAmount() public view returns(uint256) {
    return INITIAL_SUPPLY * (10 ** uint256(decimals)) - totalSupply_;
  }

}