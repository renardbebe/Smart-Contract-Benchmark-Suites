 

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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

contract Terminable is Ownable {
    bool public isTerminated = false;
    
    event Terminated();
    
    modifier whenLive() {
        require(!isTerminated);
        _;
    }
    
    function terminate() onlyOwner whenLive public {
        isTerminated = true;
        emit Terminated();
    }
}
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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract DaicoToken is BurnableToken, Ownable {
    using SafeERC20 for ERC20;
    
    address public daicoManager;
    
    event DaicoManagerSet(address indexed manager);
    
    modifier onlyDaicoManager () {
        require(daicoManager == msg.sender);
		_;
    }
    
      
    function setDaicoManager(address _daicoManager) onlyOwner public {
        require(address(0) != _daicoManager);
        require(address(this) != _daicoManager);
        
        daicoManager = _daicoManager;
        emit DaicoManagerSet(daicoManager);
    } 
    
     
	function burnFromDaico(address _from) onlyDaicoManager external {
	    require(0 != balances[_from]);
	    _burn(_from, balances[_from]);
	}
}

contract MBA is StandardToken, DaicoToken, DetailedERC20 {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
	
	 
	mapping (address => bool) public hasTranfered;
	
	ERC20 public mbaccToken; 
	ERC20 public mbasToken;
	
	 
	address public companyWallet;
	
	 
	uint256 public icoAmount = 0;
	
	 
	uint256 public INITIAL_SUPPLY = 4000000000;
	
	 
	constructor(ERC20 _mbaccToken, ERC20 _mbasToken, address _companyWallet) 
	    DetailedERC20("MBA", "MBA", 18)
	    public
	{
	     
	    require(_mbaccToken != address(0));
	    require(_mbasToken != address(0));
	    require(Terminable(_mbaccToken).isTerminated());
	    require(Terminable(_mbasToken).isTerminated());
	    require(_companyWallet != address(0));
	    
	     
	    mbaccToken = _mbaccToken;
	    mbasToken = _mbasToken;
	    
	     
		totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
		
		 
		icoAmount = totalSupply_.mul(65).div(100)
		          + mbaccToken.balanceOf(msg.sender)
		          + mbasToken.balanceOf(msg.sender);
		
		 
		companyWallet = _companyWallet;
		balances[companyWallet] = totalSupply_.mul(16).div(100);
		
		 
		_tryTransfered(msg.sender);
		
		 
		balances[msg.sender] = balances[msg.sender].add(
		    totalSupply_.mul(65).div(100));
	}
	
	function balanceOf(address who) public view returns (uint256) {
	    if (hasTranfered[who]) {
	        return balances[who];
	    } else {
	        return balances[who].add(mbaccToken.balanceOf(who))
	                .add(mbasToken.balanceOf(who));
	    }
	}
	
	function transfer(address to, uint256 value) public returns (bool) {
	    _tryTransfered(msg.sender);
	    _tryTransfered(to);
	    
	    return super.transfer(to, value);
	}
	
	function transferFrom(address from, address to, uint256 value) public returns (bool) {
	    _tryTransfered(from);
	    _tryTransfered(to);
	    
	    return super.transferFrom(from, to, value);
	}
	
	function _tryTransfered(address _who) internal {
	    if (!hasTranfered[_who]) {
	        hasTranfered[_who] = true;
	        if (0 != mbaccToken.balanceOf(_who)) {
	            balances[_who] = balances[_who].add(mbaccToken.balanceOf(_who));
	        }
	        
	        if (0 != mbasToken.balanceOf(_who)) {
	            balances[_who] = balances[_who].add(mbasToken.balanceOf(_who));
	        }
	    }
	}
}