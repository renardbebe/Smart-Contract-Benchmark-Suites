 

pragma solidity ^0.4.18;

 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}
 
 
contract CAC is StandardToken, BurnableToken, Ownable {
     
    string  public constant name = "Candy Token";
    string  public constant symbol = "CAC";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 50000000000 * (10 ** uint256(decimals));

    mapping(address => uint256) public balanceLocked;    
    mapping(address => uint256) public lockAtTime;       
    
    uint public amountRaised;
    uint256 public buyPrice = 250000;
    bool public crowdsaleClosed;
    bool public transferEnabled = true;


    function CAC() public {
      totalSupply_ = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
      Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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
         
        _lock(_to);
         
        Transfer(_from, _to, _value);
    }

    function setPrices(bool closebuy, uint256 newBuyPrice) onlyOwner public {
        crowdsaleClosed = closebuy;
        buyPrice = newBuyPrice;
    }

    function () external payable {
        require(!crowdsaleClosed);
        uint amount = msg.value ;                
        amountRaised = amountRaised.add(amount);
        _transfer(owner, msg.sender, amount.mul(buyPrice)); 
    }

     
    function safeWithdrawal(uint _value ) onlyOwner public {
       if (_value == 0) 
           owner.transfer(address(this).balance);
       else
           owner.transfer(_value);
    }

     
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        return true;
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
     
     
    function transferEx(address _to, uint256 _value) onlyOwner public returns (bool) {
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

     
   function getFreeBalances( address _addr ) public view returns(uint)  {
      if (balanceLocked[_addr] > 0) {
          if (now > lockAtTime[_addr] + 180 days) {
              return balances[_addr];
          } else if (now > lockAtTime[_addr]  + 90 days)   {
              return balances[_addr] - balanceLocked[_addr] / 10 * 4;
          } else {
              return balances[_addr] - balanceLocked[_addr] / 10 * 7 ;
          }  
      }

      return balances[_addr];      
   }

   function checkLocked(address _addr, uint256 _value) internal view returns (bool) {
      if (balanceLocked[_addr] > 0) {    
         if (now > lockAtTime[_addr] + 180 days) {  
             return true;
         } else if (now > lockAtTime[_addr] + 90 days)   {
             return (balances[_addr] - _value >= balanceLocked[_addr] / 10 * 4);
         } else {
             return (balances[_addr] - _value >= balanceLocked[_addr] / 10 * 7 );   
         }  
      }
     
      return true;
   } 
        
}