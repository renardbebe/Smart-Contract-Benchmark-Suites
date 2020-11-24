 

 



 




 
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



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Recoverable is Ownable {

   
  function Recoverable() {
  }

   
   
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

   
   
   
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
  }
}

 


 
library SafeMathLib {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}

 









 
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



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
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

}



 
contract StandardTokenExt is StandardToken {

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }
}



 
contract TokenVault is Ownable, Recoverable {
  using SafeMathLib for uint;

   
  uint public investorCount;

   
  uint public tokensToBeAllocated;

   
  uint public totalClaimed;

   
  uint public tokensAllocatedTotal;

   
  mapping(address => uint) public balances;

   
  mapping(address => uint) public claimed;

   
  uint public freezeEndsAt;

   
  uint public lockedAt;

   
  StandardTokenExt public token;

   
  enum State{Unknown, Loading, Holding, Distributing}

   
  event Allocated(address investor, uint value);

   
  event Distributed(address investors, uint count);

  event Locked();

   
  function TokenVault(address _owner, uint _freezeEndsAt, StandardTokenExt _token, uint _tokensToBeAllocated) {

    owner = _owner;

     
    if(owner == 0) {
      throw;
    }

    token = _token;

     
    if(!token.isToken()) {
      throw;
    }

     
    if(_freezeEndsAt == 0) {
      throw;
    }

     
    if(_tokensToBeAllocated == 0) {
      throw;
    }

    freezeEndsAt = _freezeEndsAt;
    tokensToBeAllocated = _tokensToBeAllocated;
  }

   
  function setInvestor(address investor, uint amount) public onlyOwner {

    if(lockedAt > 0) {
       
      throw;
    }

    if(amount == 0) throw;  

     
    if(balances[investor] > 0) {
      throw;
    }

    balances[investor] = amount;

    investorCount++;

    tokensAllocatedTotal += amount;

    Allocated(investor, amount);
  }

   
   
   
   
  function lock() onlyOwner {

    if(lockedAt > 0) {
      throw;  
    }

     
    if(tokensAllocatedTotal != tokensToBeAllocated) {
      throw;
    }

     
    if(token.balanceOf(address(this)) != tokensAllocatedTotal) {
      throw;
    }

    lockedAt = now;

    Locked();
  }

   
  function recoverFailedLock() onlyOwner {
    if(lockedAt > 0) {
      throw;
    }

     
    token.transfer(owner, token.balanceOf(address(this)));
  }

   
   
  function getBalance() public constant returns (uint howManyTokensCurrentlyInVault) {
    return token.balanceOf(address(this));
  }

   
  function claim() {

    address investor = msg.sender;

    if(lockedAt == 0) {
      throw;  
    }

    if(now < freezeEndsAt) {
      throw;  
    }

    if(balances[investor] == 0) {
       
      throw;
    }

    if(claimed[investor] > 0) {
      throw;  
    }

    uint amount = balances[investor];

    claimed[investor] = amount;

    totalClaimed += amount;

    token.transfer(investor, amount);

    Distributed(investor, amount);
  }

   
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return getBalance().minus(tokensAllocatedTotal);
  }

   
  function getState() public constant returns(State) {
    if(lockedAt == 0) {
      return State.Loading;
    } else if(now > freezeEndsAt) {
      return State.Distributing;
    } else {
      return State.Holding;
    }
  }

}