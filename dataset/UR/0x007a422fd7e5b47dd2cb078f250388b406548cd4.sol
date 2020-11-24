 

pragma solidity ^0.4.16;


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  
    
   
    
   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  
    
    
   
  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
   
  function increaseApproval (address _spender, uint256 _addedValue) 
    returns (bool success) 
    {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint256 _subtractedValue) 
    returns (bool success) 
    {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Ownable {
  address public owner;

     
   function Ownable() {
    owner = msg.sender;
  }

     
   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

     
     
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
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

     
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }
     
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

     
     
contract SalePausable is Ownable {
  event SalePause();
  event SaleUnpause();

  bool public salePaused = false;

     
  modifier saleWhenNotPaused() {
    require(!salePaused);
    _;
  }

     
  modifier saleWhenPaused() {
    require(salePaused);
    _;
  }

     
  function salePause() onlyOwner saleWhenNotPaused {
    salePaused = true;
    SalePause();
  }
     
  function saleUnpause() onlyOwner saleWhenPaused {
    salePaused = false;
    SaleUnpause();
  }
}

contract PriceUpdate is Ownable {
  uint256 public price;

     
   function PriceUpdate() {
    price = 400;
  }

     
  function newPrice(uint256 _newPrice) onlyOwner {
    require(_newPrice > 0);
    price = _newPrice;
  }

}

contract BLTToken is StandardToken, Ownable, PriceUpdate, Pausable, SalePausable {
	using SafeMath for uint256;
	mapping(address => uint256) balances;
	uint256 public totalSupply;
    uint256 public totalCap = 100000000000000000000000000;
    string 	public constant name = "BitLifeAndTrust";
	string 	public constant symbol = "BLT";
	uint256	public constant decimals = 18;
	 
    
    address public bltRetainedAcc = 0x48259a35030c8dA6aaA1710fD31068D30bfc716C;   
    address public bltOwnedAcc =    0x1CA33C197952B8D9dd0eDC9EFa20018D6B3dcF5F;   
    address public bltMasterAcc =   0xACc2be4D782d472cf4f928b116054904e5513346;  

    uint256 public bltRetained = 15000000000000000000000000;
    uint256 public bltOwned =    15000000000000000000000000;
    uint256 public bltMaster =   70000000000000000000000000;


	function balanceOf(address _owner) constant returns (uint256 balance) {
	    return balances[_owner];
	}


	function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	}


	function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool success) {
	    
	    var allowance = allowed[_from][msg.sender];
	    
	    balances[_to] = balances[_to].add(_value);
	    balances[_from] = balances[_from].sub(_value);
	    allowed[_from][msg.sender] = allowance.sub(_value);
	    Transfer(_from, _to, _value);
	    return true;
	}


	function approve(address _spender, uint256 _value) returns (bool success) {
	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	}


	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}


	function BLTToken() {
		balances[bltRetainedAcc] = bltRetained;              
        balances[bltOwnedAcc] = bltOwned;                    
        balances[bltMasterAcc] = bltMaster;                  
        
        allowed[bltMasterAcc][msg.sender] = bltMaster;

        totalSupply = bltRetained + bltOwned + bltMaster;

        Transfer(0x0,bltRetainedAcc,bltRetained);
        Transfer(0x0,bltOwnedAcc,bltOwned);
        Transfer(0x0,bltMasterAcc,bltMaster);

	}

}


contract BLTTokenSale is BLTToken {
    using SafeMath for uint256;    

    BLTToken public token;
    uint256 public etherRaised;
    uint256 public saleStartTime = now;
     
    address public ethDeposits = 0x50c19a8D73134F8e649bB7110F2E8860e4f6cfB6;         
    address public bltMasterToSale = 0xACc2be4D782d472cf4f928b116054904e5513346;     

    event MintedToken(address from, address to, uint256 value1);                     
    event RecievedEther(address from, uint256 value1);                                

    function () payable {
		createTokens(msg.sender,msg.value);
	}

         
	function createTokens(address _recipient, uint256 _value) saleWhenNotPaused {
        
        require (_value != 0);                                                       
        require (now >= saleStartTime);                                              
        require (_recipient != 0x0);                                                 
		uint256 tokens = _value.mul(PriceUpdate.price);                              
        uint256 remainingTokenSuppy = balanceOf(bltMasterToSale);

        if (remainingTokenSuppy >= tokens) {                                         
            require(mint(_recipient, tokens));                                       
            etherRaised = etherRaised.add(_value);
            forwardFunds();
            RecievedEther(msg.sender,_value);
        }                                        

	}
    
      
    function mint(address _to, uint256 _tokens) internal saleWhenNotPaused returns (bool success) {
        
        address _from = bltMasterToSale;
	    var allowance = allowed[_from][owner];
	    
	    balances[_to] = balances[_to].add(_tokens);
	    balances[_from] = balances[_from].sub(_tokens);
	    allowed[_from][owner] = allowance.sub(_tokens);
        Transfer(_from, _to, _tokens);                                                
	    MintedToken(_from,_to, _tokens); 
      return true;
	}    
       
      function forwardFunds() internal {
        ethDeposits.transfer(msg.value);
        
        }
}