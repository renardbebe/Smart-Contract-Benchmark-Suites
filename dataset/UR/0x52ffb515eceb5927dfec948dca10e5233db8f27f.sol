 

pragma solidity ^0.4.19;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


 
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() internal {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


 
contract Authorizable is Ownable {
  mapping(address => bool) public authorized;
  
  event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    
  function Authorizable() public {
	authorized[msg.sender] = true;
  }

   
  modifier onlyAuthorized() {
    require(authorized[msg.sender]);
    _;
  }

  
  function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
    AuthorizationSet(addressAuthorized, authorization);
    authorized[addressAuthorized] = authorization;
  }
  
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transferFunction(address _sender, address _to, uint256 _value) internal returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    require(_value <= balances[_sender]);

     
    balances[_sender] = balances[_sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_sender, _to, _value);
    return true;
  }
  
   
  function transfer(address _to, uint256 _value) public returns (bool) {
	return transferFunction(msg.sender, _to, _value);
  }
  
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC223TokenCompatible is BasicToken {
  using SafeMath for uint256;
  
  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

   
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		require(_to != address(0));
        require(_to != address(this));
		require(_value <= balances[msg.sender]);
		 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
		if( isContract(_to) ) {
			_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data);
		} 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		return transfer( _to, _value, _data, "tokenFallback(address,uint256,bytes)");
	}

	 
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
             
            length := extcodesize(_addr)
		}
		return (length>0);
    }
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract Startable is Ownable, Authorizable {
  event Start();

  bool public started = false;

   
  modifier whenStarted() {
	require( started || authorized[msg.sender] );
    _;
  }

   
  function start() onlyOwner public {
    started = true;
    Start();
  }
}

 

contract StartToken is Startable, ERC223TokenCompatible, StandardToken {

  function transfer(address _to, uint256 _value) public whenStarted returns (bool) {
    return super.transfer(_to, _value);
  }
  function transfer(address _to, uint256 _value, bytes _data) public whenStarted returns (bool) {
    return super.transfer(_to, _value, _data);
  }
  function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public whenStarted returns (bool) {
    return super.transfer(_to, _value, _data, _custom_fallback);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenStarted returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenStarted returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenStarted returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenStarted returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract HumanStandardToken is StandardToken, StartToken {
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);
        require(_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData));
        return true;
    }
}

contract BurnToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burnFunction(address _burner, uint256 _value) internal returns (bool) {
        require(_value > 0);
		require(_value <= balances[_burner]);
         
         

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_burner, _value);
		return true;
    }
    
     
	function burn(uint256 _value) public returns(bool) {
        return burnFunction(msg.sender, _value);
    }
	
	 
	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(_value <= allowed[_from][msg.sender]);  
		burnFunction(_from, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
	}
}

contract OriginToken is Authorizable, BasicToken, BurnToken {
    
      
    function originTransfer(address _to, uint256 _value) onlyAuthorized public returns (bool) {
	    return transferFunction(tx.origin, _to, _value);
    }
    
     	
	function originBurn(uint256 _value) onlyAuthorized public returns(bool) {
        return burnFunction(tx.origin, _value);
    }
}

contract Token is ERC223TokenCompatible, StandardToken, StartToken, HumanStandardToken, BurnToken, OriginToken {
	uint256 public totalSupply;
	uint256 public initialSupply;
	uint8 public decimals;
    string public name;
    string public symbol;

    function Token(uint256 _totalSupply, uint8 _decimals, string _name, string _symbol) public {
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint(decimals);  
        initialSupply = totalSupply;
		name = _name;
		symbol = _symbol;
        balances[msg.sender] = totalSupply;
        Transfer(0, msg.sender, totalSupply);
    }
}

contract Presale is Ownable {
    using SafeMath for uint256;
    Token public tokenContract;
    
	uint8 public decimals;
    uint256 public tokenValue;   
    uint256 public centToken;  

    uint256 public endTime;   
    uint256 public startTime;   

    function Presale() public {
         
        centToken = 25;  
        
        tokenValue = 402693728269933;  
        startTime = 1513625400;  
        endTime = 1516476600;  
		
		uint256 totalSupply = 12000000;  
		decimals = 18;
		string memory name = "MethaVoucher";
		string memory symbol = "MTV";
		
		 
		
        tokenContract = new Token(totalSupply, decimals, name, symbol);
		 
		tokenContract.transferOwnership(msg.sender);
    }

    address public updater;   
    event UpdateValue(uint256 newValue);

    function updateValue(uint256 newValue) public {
        require(msg.sender == updater || msg.sender == owner);
        tokenValue = newValue;
        UpdateValue(newValue);
    }

    function updateUpdater(address newUpdater) public onlyOwner {
        updater = newUpdater;
    }

    function updateTime(uint256 _newStart, uint256 _newEnd) public onlyOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    event Buy(address buyer, uint256 value);

    function buy(address _buyer) public payable returns(uint256) {
        require(now > startTime);  
        require(now < endTime);  
        require(msg.value > 0);
		
		uint256 remainingTokens = tokenContract.balanceOf(this);
        require( remainingTokens > 0 );  
        
        uint256 oneToken = 10 ** uint256(decimals);
        uint256 tokenAmount = msg.value.mul(oneToken).div(tokenValue);
        
        if ( remainingTokens < tokenAmount ) {
            uint256 refund = (tokenAmount - remainingTokens).mul(tokenValue).div(oneToken);
            tokenAmount = remainingTokens;
            owner.transfer(msg.value-refund);
			remainingTokens = 0;  
             _buyer.transfer(refund);
        } else {
			remainingTokens = remainingTokens.sub(tokenAmount);  
            owner.transfer(msg.value);
        }
        
        tokenContract.transfer(_buyer, tokenAmount);
        Buy(_buyer, tokenAmount);
		
        return tokenAmount; 
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
    
    function updateTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = Token(_tokenContract);
    }

    function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
        return tokenContract.transfer(to, value);
    }

    function () public payable {
        buy(msg.sender);
    }
}