 

pragma solidity 0.4.25;


 
    contract Owned {
        address public owner;      

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
         

        function transferOwnership(address _newOwner) onlyOwner public {
            require(_newOwner != address(0)); 
            owner = _newOwner;
        }          
    }

 
contract Pausable is Owned {
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

  

contract ERC20 is Pausable{
  
  using SafeMath for uint256;

   
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowed;  
    
   
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;
   
   
  event Approval(address indexed owner, address indexed spender, uint256 value);

   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  constructor (uint256 _initialSupply,string _tokenName, string _tokenSymbol) public {    
    totalSupply = _initialSupply * 10 ** uint256(decimals);  
    balanceOf[msg.sender] = totalSupply;  
    name = _tokenName;
    symbol = _tokenSymbol;   
  }
  
     
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool)  {      
        require(balanceOf[msg.sender] > 0);                     
        require(balanceOf[msg.sender] >= _value);                    
        require(_to != address(0));                                  
        require(_value > 0);	
        require(_to != msg.sender);                                  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        balanceOf[_to] = balanceOf[_to].add(_value);                 
        emit Transfer(msg.sender, _to, _value);                      
        return true;
	}

	 
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) public whenNotPaused returns (bool success)
      { 
        require(balanceOf[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);
        require(_amount > 0);
        require(_to != address(0));           
        require(_from!=_to);   
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;        
    }
    
     
     function approve(address _spender, uint256 _amount) public whenNotPaused  returns (bool success) {    
         require(msg.sender!=_spender);  
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
    } 

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
    }
}

 
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


 
contract CryptoRiyalToken is Owned, ERC20 {

    using SafeMath for uint256;

    uint256  public tokenSupply = 2000000000; 
              
     
    event Burn(address from, uint256 value); 
    
     
	constructor() 

	ERC20 (tokenSupply,"CryptoRiyal","CR") public
    {
		owner = msg.sender;
        emit Transfer(address(0), msg.sender, tokenSupply);
	}          

     
    function burn(uint256 _value) public onlyOwner {
      require(_value <= balanceOf[msg.sender]);
       
       
      address burner = msg.sender;
      balanceOf[burner] = balanceOf[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      emit Burn(burner, _value);
  }
   
}