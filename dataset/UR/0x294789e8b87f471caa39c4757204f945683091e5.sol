 

pragma solidity ^0.4.21;

 

 
contract Ownable {
  address public owner;

  

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

 

}

 

 
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 
contract AMFC is StandardToken, BurnableToken, Ownable {
     
    string  public constant name = "Anything Macgic Fans";
    string  public constant symbol = "AMFC";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 500000000 * (10 ** uint256(decimals));

    address constant LOCK_ADDR = 0xF63Fb7657B11B408eEdD263fE0753E1665E7400a;
    uint256 constant LOCK_SUPPLY    = 300000000 * (10 ** uint256(decimals));  
    uint256 constant UNLOCK_2Y    =   200000000 * (10 ** uint256(decimals)); 
    uint256 constant UNLOCK_1Y    =   100000000 * (10 ** uint256(decimals)); 

    uint256 constant OWNER_SUPPLY      = INITIAL_SUPPLY - LOCK_SUPPLY;

    mapping(address => uint256)  balanceLocked;    
    mapping(address => uint256)  lockAtTime;       
    
  
    uint256 public buyPrice = 585;
    bool public crowdsaleClosed;
    bool public transferEnabled = true;


    constructor() public {
      totalSupply_ = INITIAL_SUPPLY;

      balances[msg.sender] = OWNER_SUPPLY;
      emit Transfer(0x0, msg.sender, OWNER_SUPPLY);

      balances[LOCK_ADDR] = LOCK_SUPPLY;
      emit Transfer(0x0, LOCK_ADDR, LOCK_SUPPLY);

      _lock(LOCK_ADDR);
    }

    function _lock(address _owner) internal {
        balanceLocked[_owner] =  balances[_owner];  
        lockAtTime[_owner] = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require (balances[_from] >= _value);                
        require (balances[_to] + _value > balances[_to]);  
   
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                             

        emit Transfer(_from, _to, _value);
    }

    function setPrices(bool closebuy, uint256 newBuyPrice) onlyOwner public {
        crowdsaleClosed = closebuy;
        buyPrice = newBuyPrice;
    }

    function () external payable {
        require(!crowdsaleClosed);
        uint amount = msg.value ;                
 
        _transfer(owner, msg.sender, amount.mul(buyPrice)); 
        owner.transfer(amount);
    }

     
    function safeWithdrawal(uint _value ) onlyOwner public {
       if (_value == 0) 
           owner.transfer(address(this).balance);
       else
           owner.transfer(_value);
    }

 
    function enableTransfer(bool _enable) onlyOwner external {
        transferEnabled = _enable;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require(checkLocked(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require(checkLocked(msg.sender, _value));
        
        return super.transfer(_to, _value);
    }    
  
     
     
     
    function lockAddress( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          _lock(_addr[i]);
        }
    }
    
     
    function unlockAddress( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          balanceLocked[_addr[i]] =  0;  
        }
    }
 

   function checkLocked(address _addr, uint256 _value) internal view returns (bool) {
      if (balanceLocked[_addr] > 0) {    
         if (now > lockAtTime[_addr] + 3 years) {  
             return true;
         } else if (now > lockAtTime[_addr] + 2 years)   {
             return (balances[_addr] - _value >= UNLOCK_1Y);
         } else if (now > lockAtTime[_addr] + 1 years)   {
             return (balances[_addr] - _value >= UNLOCK_2Y);    
         }  else {
             return false;   
         }  
      }
     
      return true;
   } 
        
}