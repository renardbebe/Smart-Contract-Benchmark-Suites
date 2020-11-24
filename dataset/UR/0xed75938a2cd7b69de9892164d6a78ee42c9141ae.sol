 

pragma solidity ^0.4.18;


    contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
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
     
     
     
    return a / b;
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

 
contract IntraCoin is owned {
    using SafeMath for uint256;
    
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;  
    uint256 public totalSupply_;
    
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;
  
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Pause();
    event Unpause();
    event Approval(address indexed owner, address indexed spender, uint256 value);

  bool public paused = false;
  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
    
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }
    

  
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address centralMinter
    ) IntraCoin(initialSupply, tokenName, tokenSymbol, centralMinter) public {
        if(centralMinter != 0 ) owner = centralMinter;
        totalSupply_ = initialSupply * 10 ** uint256(decimals);   
        balances[msg.sender] = totalSupply_;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        
    }


   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }


   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
  
 
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  
   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
      require(_to != address(0));
      require(!frozenAccount[msg.sender]);     
      require(!frozenAccount[_to]);            
      require(_value <= balances[msg.sender]);
      require(balances[_to] + _value > balances[_to]);   
      
    _transfer(msg.sender, _to, _value);
  }
    
    
      
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(!frozenAccount[msg.sender]);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
        
        balances[_from] = balances[_from].sub(_value);    
        balances[_to] = balances[_to].add(_value);      
        
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    
   
   

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);      
    require(!frozenAccount[msg.sender]);      
    require(!frozenAccount[_from]);           
    require(!frozenAccount[_to]);             
    require(balances[_to] + _value > balances[_to]);    

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
     
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  
     
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  
    
  function burn(uint256 _value) onlyOwner public {
    require(_value <= balances[msg.sender]);
    require(_value <= totalSupply_);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);    
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
  
  
      function kill() public onlyOwner() {
        selfdestruct(owner);
    }
}