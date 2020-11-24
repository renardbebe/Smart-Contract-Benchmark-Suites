 

pragma solidity 0.4.24;

 
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

 
contract Authorizable is Ownable {
  mapping(address => bool) public authorized;
  
  event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    
  constructor() public {
	authorized[msg.sender] = true;
  }

   
  modifier onlyAuthorized() {
    require(authorized[msg.sender]);
    _;
  }

  
  function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
    emit AuthorizationSet(addressAuthorized, authorization);
    authorized[addressAuthorized] = authorization;
  }
  
}


 
contract Pausable is Ownable, Authorizable {
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



contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}




 
contract StandardToken is Token {
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
       require(balances[msg.sender] >= _value);      
       balances[msg.sender] -= _value;
       balances[_to] += _value;
       emit Transfer(msg.sender, _to, _value);
       return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     	require(balances[msg.sender] >= _value); 
        require(allowed[_from][msg.sender] >= _value); 
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
}

contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 amount);

     
    function burn(uint256 _amount) public {
        require(_amount > 0);
        require(_amount <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = SafeMath.sub(balances[burner],_amount);
        totalSupply = SafeMath.sub(totalSupply,_amount);
        emit Transfer(burner, address(0), _amount);
        emit Burn(burner, _amount);
    }

     
    function burnFrom(address _from, uint256 _amount) onlyOwner public {
        require(_from != address(0));
        require(_amount > 0);
        require(_amount <= balances[_from]);
        balances[_from] = SafeMath.sub(balances[_from],_amount);
        totalSupply = SafeMath.sub(totalSupply,_amount);
        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }

}

contract BlockPausableToken is StandardToken, Pausable,BurnableToken {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

 
}

contract BlockToken is BlockPausableToken {
 using SafeMath for uint;
     
    string public constant name = "Block66";
    string public constant symbol = "B66";
    uint256 public constant decimals = 18;
    
   	address private ethFundDeposit;     
   	
   	address private bugFundDeposit;       
	uint256 public constant bugFund = 13.5 * (10**6) * 10**decimals;    
			
	address private b66AdvisorFundDeposit;       
	uint256 public constant b66AdvisorFundDepositAmt = 13.5 * (10**6) * 10**decimals;   
    	
	address private b66ReserveFundDeposit;  
	uint256 public constant b66ReserveTokens = 138 * (10**6) * 10**decimals;  
    	
	uint256 public icoTokenExchangeRate = 715;  
	uint256 public tokenCreationCap =  300 * (10**6) * 10**decimals;  
	
	 
	 
   	bool public tokenSaleActive;               
	bool public haltIco;
	bool public dead = false;
	bool public privateEquityClaimed;
	 
	uint256 public ethRaised = 0;
	 
	address public checkaddress;

 
     
    event CreateToken(address indexed _to, uint256 _value);
    event Transfer(address from, address to, uint256 value);
    event TokenSaleFinished
      (
        uint256 totalSupply
  	);
    event PrivateEquityReserveBlock(uint256 _value);
     
    constructor (		
       	address _ethFundDeposit,
       	address _bugFundDeposit,
		address _b66AdvisorFundDeposit,	
		address _b66ReserveFundDeposit

        	) public {
        	
		tokenSaleActive = true;                   
		haltIco = true;
		privateEquityClaimed=false;	
		require(_ethFundDeposit != address(0));
		require(_bugFundDeposit != address(0));	
		require(_b66AdvisorFundDeposit != address(0));
		require(_b66ReserveFundDeposit != address(0));
		
		ethFundDeposit = _ethFundDeposit;
		b66ReserveFundDeposit=_b66ReserveFundDeposit;
		bugFundDeposit = _bugFundDeposit;
		balances[bugFundDeposit] = bugFund;     
		emit CreateToken(bugFundDeposit, bugFund);   
		totalSupply = SafeMath.add(totalSupply, bugFund);  
		b66AdvisorFundDeposit = _b66AdvisorFundDeposit;				
		balances[b66AdvisorFundDeposit] = b66AdvisorFundDepositAmt;     
		emit CreateToken(b66AdvisorFundDeposit, b66AdvisorFundDepositAmt); 
		
		totalSupply = SafeMath.add(totalSupply, b66AdvisorFundDepositAmt);  				
		paused = true;
    }

    
	
     
    function createTokens() payable external {
      if (!tokenSaleActive) 
        revert();
	  if (haltIco) 
	    revert();
	  
      if (msg.value == 0) 
        revert();
      uint256 tokens;
      tokens = SafeMath.mul(msg.value, icoTokenExchangeRate);  
      uint256 checkedSupply = SafeMath.add(totalSupply, tokens);
 
       
      if (tokenCreationCap < checkedSupply) 
        revert();   
 
      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      emit CreateToken(msg.sender, tokens);   
    }  
	 
	
    function mint(address _privSaleAddr,uint _privFundAmt) onlyAuthorized external {
    	  require(tokenSaleActive == true);
	  uint256 privToken = _privFundAmt*10**decimals;
          uint256 checkedSupply = SafeMath.add(totalSupply, privToken);     
           
          if (tokenCreationCap < checkedSupply) 
            revert();   
          totalSupply = checkedSupply;
          balances[_privSaleAddr] += privToken;   
          emit CreateToken (_privSaleAddr, privToken);   
    }
    
  
    
    function setIcoTokenExchangeRate (uint _icoTokenExchangeRate) onlyOwner external {		
    	icoTokenExchangeRate = _icoTokenExchangeRate;            
    }
        

    function setHaltIco(bool _haltIco) onlyOwner external {
	haltIco = _haltIco;            
    }

	 
     function vestPartnerEquityReserve() onlyOwner external {
        emit  PrivateEquityReserveBlock(block.number);
        require(!privateEquityClaimed);
         
     	require(block.number > 8357500);
	balances[b66ReserveFundDeposit] = b66ReserveTokens;     
    	emit CreateToken(b66ReserveFundDeposit, b66ReserveTokens);          
    	totalSupply = SafeMath.add(totalSupply, b66ReserveTokens);   
    	privateEquityClaimed=true;
    }
    
    function setReserveFundDepositAddress(address _b66ReserveFundDeposit) onlyOwner external {
    	  require(_b66ReserveFundDeposit != address(0));
          b66ReserveFundDeposit=_b66ReserveFundDeposit;
    } 
    
      
    function sendFundHome() onlyOwner external {   
      if (!ethFundDeposit.send(address(this).balance)) 
        revert();   
    } 
	
    function sendFundHomeAmt(uint _amt) onlyOwner external {
      if (!ethFundDeposit.send(_amt*10**decimals)) 
        revert();   
    }    
    
      function toggleDead()
          external
          onlyOwner
          returns (bool)
        {
          dead = !dead;
      }
     
        function endIco() onlyOwner external {  
           
          require(tokenSaleActive == true);
          tokenSaleActive = false;
    	  
    	    emit TokenSaleFinished(
    	      totalSupply
        );
        }  
    
      
      function()
        external
      {
        revert();
  	}
  	
  	
	 
	function checkEthRaised() onlyAuthorized external returns(uint256 balance) {
	ethRaised = address(this).balance;
	return ethRaised;  
	} 
	 

	 
	function checkEthFundDepositAddress() onlyAuthorized external returns(address) {
	  checkaddress = ethFundDeposit;
	  return checkaddress;  
	} 
}