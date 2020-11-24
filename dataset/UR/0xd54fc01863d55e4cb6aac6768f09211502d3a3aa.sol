 

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
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
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

contract BCWPausableToken is StandardToken, Pausable,BurnableToken {

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

contract BCWToken is BCWPausableToken {
 using SafeMath for uint;
     
    string public constant name = "BcwWolfCoin";
    string public constant symbol = "BCW";
    uint256 public constant decimals = 18;
    
   	address private ethFundDeposit;       
		
		    	
	uint256 public icoTokenExchangeRate = 715;  
	uint256 public tokenCreationCap =  350 * (10**6) * 10**decimals;  
	
	 
	 
    	bool public tokenSaleActive;               
		bool public airdropActive;
	bool public haltIco;
	bool public dead = false;

 
     
    event CreateToken(address indexed _to, uint256 _value);
    event Transfer(address from, address to, uint256 value);
    
     
    constructor (		
       	address _ethFundDeposit
		
		
        	) public {
        	
		tokenSaleActive = true;                   
		haltIco = true;
		paused = true;
		airdropActive = true;	
		require(_ethFundDeposit != address(0));
		
		uint256  _tokenCreationCap =tokenCreationCap-150 * (10**6) * 10**decimals;
		ethFundDeposit = _ethFundDeposit;
		balances[ethFundDeposit] = _tokenCreationCap;
		totalSupply = _tokenCreationCap;
		emit CreateToken(ethFundDeposit, totalSupply);
		
		
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
	 
	
    function mint(address _privSaleAddr,uint _privFundAmt) onlyOwner external {
         require(airdropActive == true);
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
               tokenSaleActive=false;
        }  
		
		function endAirdrop() onlyOwner external {  
           
              require(airdropActive == true);
               airdropActive=false;
        }  
    
      
}