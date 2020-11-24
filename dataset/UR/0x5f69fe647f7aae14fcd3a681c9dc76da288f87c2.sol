 

 



 




 
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




 
contract StandardTokenExt is StandardToken, Recoverable {

   
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

   
  mapping(address => uint) public lastClaimedAt;

   
  uint public freezeEndsAt;

   
  uint public lockedAt;

   
  mapping(address => uint256) public tokensPerSecond;

   
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

    if (_freezeEndsAt < now) {
      freezeEndsAt = now;
    } else {
      freezeEndsAt = _freezeEndsAt;
    }
    tokensToBeAllocated = _tokensToBeAllocated;
  }

   
  function setInvestor(address investor, uint amount, uint _tokensPerSecond) public onlyOwner {

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

    tokensPerSecond[investor] = _tokensPerSecond;

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

   
   
   
  function getMaxClaimByNow(address investor) public constant returns (uint claimableAmount) {

    if (now < freezeEndsAt) {
      return 0;
    }

    uint previousClaimAt = lastClaimedAt[investor];

     
    if (previousClaimAt == 0) {
      previousClaimAt = freezeEndsAt;
    }

    uint passed = now.minus(previousClaimAt);
    uint maxClaim = passed.times(tokensPerSecond[investor]);
    return maxClaim;
  }

   
   
   
  function getCurrentlyClaimableAmount(address investor) public constant returns (uint claimableAmount) {

    uint maxTokensLeft = balances[investor].minus(claimed[investor]);

    if (now < freezeEndsAt) {
      return 0;
    }

    uint maxClaim = getMaxClaimByNow(investor);

    if (tokensPerSecond[investor] > 0) {
       

      if (maxClaim > maxTokensLeft) {
        return maxTokensLeft;
      } else {
        return maxClaim;
      }
    } else {
       
      return maxTokensLeft;
    }
  }

   
  function claim() public {

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

    uint amount = getCurrentlyClaimableAmount(investor);

    require(amount > 0);  

     
    lastClaimedAt[investor] = now;
    claimed[investor] += amount;

     
    totalClaimed += amount;

     
    token.transfer(investor, amount);
    Distributed(investor, amount);
  }

   
  function tokensToBeReturned(ERC20Basic tokenToClaim) public returns (uint) {
    if (address(tokenToClaim) == address(token)) {
      return getBalance().minus(tokensAllocatedTotal);
    } else {
      return tokenToClaim.balanceOf(this);
    }
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