 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor () public {
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

contract Token {

    function totalSupply() public pure {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract SafeMath {
  function safeMul(uint256 a, uint256 b)pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b)pure internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b)pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b)pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract StandardToken is Token,SafeMath {

    function approve(address _spender, uint256 _value)public returns (bool success) {
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

contract HECFinalToken is StandardToken,owned {

 string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;
    
 uint256 public deploymentTime = now;
 uint256 public burnTime = now + 2 minutes;
 
      uint256 public sellPrice;
    uint256 public buyPrice;

     
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
constructor(
        )public {
       
        initialSupply =10000000000*100000000; 
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                          
        name = "Haeinenergy coin";                                    
        symbol = "HEC";                                
        decimals = 8;                             
		owner = msg.sender;
        }
        
    function transfer(address _to, uint256 _value)public returns (bool success) {
        if (balanceOf[msg.sender] >= _value && _value > 0) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        if (balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balanceOf[_to] += _value;
            balanceOf[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

      function burn(uint256 _value) public returns (bool success) {
      if (burnTime <= now)
      {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
      }
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

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
   
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }
     
    function buy() payable public {
        uint amount = msg.value / buyPrice;                
        _transfer(this, msg.sender, amount);               
    }
    
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
    
    }