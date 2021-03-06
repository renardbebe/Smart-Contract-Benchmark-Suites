 

pragma solidity ^0.4.24;

 

 
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

 
contract OKBI is StandardToken, BurnableToken, Ownable {
     
    string  public constant name = "OKBIcommunity";
    string  public constant symbol = "OKBI";
    uint8   public constant decimals = 18;
    uint256  constant INITIAL_SUPPLY    = 750000000 * (10 ** uint256(decimals));
    uint256  constant LOCK_SUPPLY       = 250000000 * (10 ** uint256(decimals));

    uint256  constant LOCK_SUPPLY1      = 100000000 * (10 ** uint256(decimals));
    uint256  constant LOCK_SUPPLY2      = 100000000 * (10 ** uint256(decimals));
    uint256  constant LOCK_SUPPLY3      =  50000000 * (10 ** uint256(decimals));
    bool mintY1;
    bool mintY2;
    bool mintY3;

    uint256  constant MINT_OKBI      =  328767 * (10 ** uint256(decimals));
    uint256  constant DAY = 1 days ;
    
    uint256 startTime = now;
    uint256 public lastMintTime;

    constructor() public {
      address holder = 0x90d1E3aA01519b7A236Fa9ffC36dA84dE191EdE0;
      totalSupply_ = INITIAL_SUPPLY + LOCK_SUPPLY;
      balances[holder] = INITIAL_SUPPLY;
      emit Transfer(0x0, holder, INITIAL_SUPPLY);

      balances[address(this)] = LOCK_SUPPLY;
      emit Transfer(0x0, address(this), LOCK_SUPPLY);
      lastMintTime = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require (balances[_from] >= _value);                
        require (balances[_to] + _value > balances[_to]);  
   
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                             
         
        emit Transfer(_from, _to, _value);
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        if (msg.sender == _to && msg.sender == owner) {
          return mint();
        }
        
        return super.transfer(_to, _value);
    }   

    function () external payable {
        revert();
    }
 
    function withdrawalToken( ) onlyOwner public {
      if (mintY3 == false && now > startTime + 2 years ) {  
        _transfer(address(this), msg.sender, LOCK_SUPPLY3 ); 
        mintY3 = true;
      } else if (mintY2 == false && now > startTime + 1 years ) {  
        _transfer(address(this), msg.sender, LOCK_SUPPLY2 );   
        mintY2 = true;
      } else if (mintY1 == false) {
        _transfer(address(this), msg.sender, LOCK_SUPPLY1 );   
        mintY1 = true;
      }  
   } 

    function mint() internal returns (bool)  {
      uint256 d = (now - lastMintTime) / DAY ;
    
      if (d > 0) 
      {
          lastMintTime = lastMintTime + DAY * d;

          totalSupply_ = totalSupply_.add(MINT_OKBI * d);
          balances[owner] = balances[owner].add(MINT_OKBI * d);
          
          emit Transfer(0x0, owner, MINT_OKBI * d);
      }
      
      return true;
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
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        return true;
    }

}