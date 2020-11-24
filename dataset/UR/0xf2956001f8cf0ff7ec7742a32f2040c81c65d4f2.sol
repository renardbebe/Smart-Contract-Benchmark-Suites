 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;
 
   
  constructor() public {
    owner = 0x3df7390eA4f9D7Ca5A7f30ab52d18FD4F247bf44;
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
     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

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

contract GSTT is StandardToken,  Ownable {
     
    string  public constant name = "Great International standard Token";
    string  public constant symbol = "GSTT";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant D      = 10 ** uint256(decimals);
 
    address constant holder = 0x3df7390eA4f9D7Ca5A7f30ab52d18FD4F247bf44;

    mapping(address => uint256) public balanceLocked;   
   

    bool public transferEnabled = true;

    constructor() public {
      totalSupply_ = INITIAL_SUPPLY;
      balances[holder] = INITIAL_SUPPLY;
      emit Transfer(0x0, holder, INITIAL_SUPPLY);
    }
 


    function () external payable {
        revert();
    }
 
 
    function enableTransfer(bool _enable) onlyOwner external {
        transferEnabled = _enable;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require((balances[_from] - _value) >= balanceLocked[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        require((balances[msg.sender] - _value) >= balanceLocked[msg.sender]);
        
        return super.transfer(_to, _value);
    }    
  
 
    function lock ( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          balanceLocked[_addr[i]] =  balances[_addr[i]];  
        }
    }

  
    function lockEx ( address[] _addr , uint256[] _value) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          balanceLocked[_addr[i]] = _value[i] * D;
        }
    }
    
  
    function unlock ( address[] _addr ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          balanceLocked[_addr[i]] =  0;  
        }
    }
 
 
    function unlockEx ( address[] _addr , uint256[] _value ) onlyOwner external  {
        for (uint i = 0; i < _addr.length; i++) {
          uint256 v = (_value[i] * D) > balanceLocked[_addr[i]] ? balanceLocked[_addr[i]] : (_value[i] * D);
          balanceLocked[_addr[i]] -= v;  
        }
    }
        
 
   function getFreeBalances( address _addr ) public view returns(uint)  {
      return balances[_addr] - balanceLocked[_addr];      
   }

   function mint(address _to, uint256 _am) onlyOwner public returns (bool) {
      uint256 _amount = _am * (10 ** uint256(decimals)) ;
      totalSupply_ = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      
      emit Transfer(address(0), _to, _amount);
      return true;
  }

  function burn(address _who, uint256 _value) onlyOwner public  {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Transfer(_who, address(0), _value);
  }

}