 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

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

 

pragma solidity ^0.4.24;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;

contract ERC1132 {
     
    mapping(address => bytes32[]) public lockReason;

     
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

     
    mapping(address => mapping(bytes32 => lockToken)) public locked;

     
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

     
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );
    
     
    function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of)
        public returns (bool);
  
     
    function tokensLocked(address _of, bytes32 _reason)
        public view returns (uint256 amount);
    
     
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public view returns (uint256 amount);
    
     
    function totalBalanceOf(address _of)
        public view returns (uint256 amount);
    
     
    function extendLock(bytes32 _reason, uint256 _time)
        public returns (bool);
    
     
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public returns (bool);

     
    function tokensUnlockable(address _of, bytes32 _reason)
        public view returns (uint256 amount);
 
     
    function unlock(address _of)
        public returns (uint256 unlockableTokens);

     
    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}

 

pragma solidity ^0.4.24;

 





 
contract YoonwooCoin is StandardToken, Ownable, ERC1132 {
	 
	string public constant name 					= "YoonwooCoin";
	string public constant symbol 					= "YWC";
	uint256 public constant decimals 				= 18;
	uint256 public constant INITIAL_SUPPLY 				= 10000000 * (10 ** decimals);
    
	constructor() public {
        	totalSupply_ 						= INITIAL_SUPPLY;
		balances[msg.sender] 					= INITIAL_SUPPLY;
	}

	 
    	event Mint(address minter, uint256 value);
	event Burn(address burner, uint256 value);

	 
	string internal constant INVALID_TOKEN_VALUES 			= 'Invalid token values';
	string internal constant NOT_ENOUGH_TOKENS 			= 'Not enough tokens';
	string internal constant ALREADY_LOCKED 			= 'Tokens already locked';
	string internal constant NOT_LOCKED 				= 'No tokens locked';
	string internal constant AMOUNT_ZERO 				= 'Amount can not be 0';

	 
	function mint(address _to, uint256 _amount) public onlyOwner {
        	require(_amount > 0, INVALID_TOKEN_VALUES);
        	
		balances[_to] 						= balances[_to].add(_amount);
        	totalSupply_ 						= totalSupply_.add(_amount);
        	
		emit Mint(_to, _amount);
	}	

	 
	function burn(address _of, uint256 _amount) public onlyOwner {
        	require(_amount > 0, INVALID_TOKEN_VALUES);
        	require(_amount <= balances[_of], NOT_ENOUGH_TOKENS);
        	
		balances[_of] 						= balances[_of].sub(_amount);
        	totalSupply_ 						= totalSupply_.sub(_amount);
        	
		emit Burn(_of, _amount);
	}

	 
    	function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of) public onlyOwner returns (bool) {
        	uint256 validUntil 					= now.add(_time);

		require(_amount <= balances[_of], NOT_ENOUGH_TOKENS);
		require(tokensLocked(_of, _reason) == 0, ALREADY_LOCKED);
		require(_amount != 0, AMOUNT_ZERO);

		if (locked[_of][_reason].amount == 0)
			lockReason[_of].push(_reason);

		balances[address(this)] = balances[address(this)].add(_amount);
		balances[_of] = balances[_of].sub(_amount);

		locked[_of][_reason] = lockToken(_amount, validUntil, false);

		emit Transfer(_of, address(this), _amount);
		emit Locked(_of, _reason, _amount, validUntil);
		
		return true;
    	}

    	function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        	public
        	returns (bool)
    	{
        	uint256 validUntil 					= now.add(_time); 

        	require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        	require(_amount != 0, AMOUNT_ZERO);

        	if (locked[_to][_reason].amount == 0)
            		lockReason[_to].push(_reason);

        	transfer(address(this), _amount);

        	locked[_to][_reason] 					= lockToken(_amount, validUntil, false);

        	emit Locked(_to, _reason, _amount, validUntil);
        
		return true;
    	}

    	function tokensLocked(address _of, bytes32 _reason)
        	public
        	view
        	returns (uint256 amount)
    	{	
        	if (!locked[_of][_reason].claimed)
            		amount 						= locked[_of][_reason].amount;
    	}

    	function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        	public
        	view
        	returns (uint256 amount)
    	{
        	if (locked[_of][_reason].validity > _time)
            		amount 						= locked[_of][_reason].amount;
    	}

    	function totalBalanceOf(address _of)
        	public
        	view
        	returns (uint256 amount)
    	{
        	amount 							= balanceOf(_of);

        	for (uint256 i = 0; i < lockReason[_of].length; i++) {
            		amount 						= amount.add(tokensLocked(_of, lockReason[_of][i]));
        	}
    	}

    	function extendLock(bytes32 _reason, uint256 _time)
        	public
        	returns (bool)
    	{
        	require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        	locked[msg.sender][_reason].validity 			= locked[msg.sender][_reason].validity.add(_time);

        	emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        
		return true;
    	}	

    	function increaseLockAmount(bytes32 _reason, uint256 _amount)
        	public
        	returns (bool)
    	{
        	require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        	
		transfer(address(this), _amount);

        	locked[msg.sender][_reason].amount 			= locked[msg.sender][_reason].amount.add(_amount);

        	emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        
		return true;
   	}

    	function tokensUnlockable(address _of, bytes32 _reason)
        	public
        	view
        	returns (uint256 amount)
    	{
        	if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) 
            		amount 						= locked[_of][_reason].amount;
    	}

    	function unlock(address _of)
        	public
        	returns (uint256 unlockableTokens)
    	{
        	uint256 lockedTokens;

        	for (uint256 i = 0; i < lockReason[_of].length; i++) {
            		lockedTokens 					= tokensUnlockable(_of, lockReason[_of][i]);
            
	    		if (lockedTokens > 0) {
                		unlockableTokens 			= unlockableTokens.add(lockedTokens);
                		locked[_of][lockReason[_of][i]].claimed = true;

                		emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            		}
        	}

        	if (unlockableTokens > 0)
            		this.transfer(_of, unlockableTokens);
    	}

    	function getUnlockableTokens(address _of)
        	public
        	view
        	returns (uint256 unlockableTokens)
    	{
        	for (uint256 i = 0; i < lockReason[_of].length; i++) {
            		unlockableTokens 				= unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        	}
    	}
}