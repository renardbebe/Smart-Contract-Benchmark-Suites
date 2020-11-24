 

pragma solidity ^0.4.24;

 
 


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Owned {
	address public owner;

	function Owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		owner = newOwner;
	}
}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
	 
	string public name;
	string public symbol;
	 
	uint8 public decimals = 4;
	 
	uint256 public totalSupply;

	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Burn(address indexed from, uint256 value);

	 
	function TokenERC20(uint256 initialSupply) public {
	    
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		balanceOf[msg.sender] = totalSupply;                 
		name = "WADCoin";                                    
		symbol = "wad";                                
	}


	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);      
		allowance[_from][msg.sender] -= _value;
		 
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public
		returns (bool success) {
			allowance[msg.sender][_spender] = _value;
			return true;
		}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		public
		returns (bool success) {
			tokenRecipient spender = tokenRecipient(_spender);
			if (approve(_spender, _value)) {
				spender.receiveApproval(msg.sender, _value, this, _extraData);
				return true;
			}
		}

	 
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);    
		balanceOf[msg.sender] -= _value;             
		totalSupply -= _value;                       
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		require(_value <= allowance[_from][msg.sender]);     
		balanceOf[_from] -= _value;                          
		allowance[_from][msg.sender] -= _value;              
		totalSupply -= _value;                               
		emit Burn(_from, _value);
		return true;
	}
}

 
 
 

contract WADCoin is Owned, TokenERC20 {
	using SafeMath for uint256;

	uint256 public sellPrice;
	uint256 public buyPrice;
    address public migrationAgent;
    uint256 public totalMigrated;
    address public migrationMaster;
    
    mapping(address => bytes32[]) public lockReason;
	mapping(address => mapping(bytes32 => lockToken)) public locked;
    
	struct lockToken {
        uint256 amount;
        uint256 validity;
    }
    
     
     
     
     
     
     

	 
	event Migrate(address indexed _from, address indexed _to, uint256 _value);
    
	 
	 
	function WADCoin( uint256 _initialSupply) TokenERC20(_initialSupply) public {
 
 
 
	}

	 
	 
	 
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}

	 
	 
	 
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}
    
     
	function _transfer(address _from, address _to, uint _value) internal {
	    
		 
		require(_to != 0x0);
		 
		require(transferableBalanceOf(_from) >= _value);
		 
		require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		 
		balanceOf[_from] -= _value;
		 
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	 
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}
    
	 
    
    function lock(address _of, bytes32 _reason, uint256 _amount, uint256 _time)
        onlyOwner
        public
        returns (bool)
    {
        uint256 validUntil = block.timestamp.add(_time);
         
         
         
        require(_amount <= transferableBalanceOf(_of));
        
        if (locked[_of][_reason].amount == 0)
            lockReason[_of].push(_reason);
        
        if(tokensLocked(_of, _reason, block.timestamp) == 0){
            locked[_of][_reason] = lockToken(_amount, validUntil);    
        }else{
            locked[_of][_reason].amount += _amount;   
        }
        
         
        return true;
    }
    
     
    function extendLock(bytes32 _reason, uint256 _time)
        public
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason, block.timestamp) > 0);
        locked[msg.sender][_reason].validity += _time;
         
        return true;
    }
    
    
     
    function tokensLocked(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

	function transferableBalanceOf(address _of)
		public
		view
		returns (uint256 amount)
		{
			uint256 lockedAmount = 0;
			for (uint256 i=0; i < lockReason[_of].length; i++) {
				lockedAmount += tokensLocked(_of,lockReason[_of][i], block.timestamp);
			}
			 
			amount = balanceOf[_of].sub(lockedAmount);
			return amount;
		}
    
	 
	 
	 
	 
	 
	function setMigrationAgent(address _agent) external {
		 
		if (migrationAgent != 0) throw;
		if (msg.sender != migrationMaster) throw;
		migrationAgent = _agent;
	}

	function setMigrationMaster(address _master) external {
		if (msg.sender != migrationMaster) throw;
		if (_master == 0) throw;
		migrationMaster = _master;
	}
	
}