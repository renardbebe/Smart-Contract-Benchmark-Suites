 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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


 
 
contract BIXToken is StandardToken, Ownable{
    
    string public version = "1.0";
    string public name = "BIX Token";
    string public symbol = "BIX";
    uint8 public  decimals = 18;

    mapping(address=>uint256)  lockedBalance;
    mapping(address=>uint)     timeRelease; 
    
    uint256 internal constant INITIAL_SUPPLY = 500 * (10**6) * (10 **18);
    uint256 internal constant DEVELOPER_RESERVED = 175 * (10**6) * (10**18);

     
     


    event Burn(address indexed burner, uint256 value);
    event Lock(address indexed locker, uint256 value, uint releaseTime);
    event UnLock(address indexed unlocker, uint256 value);
    

     
    function BIXToken(address _developer) { 
        balances[_developer] = DEVELOPER_RESERVED;
        totalSupply = DEVELOPER_RESERVED;
    }

     
    function lockedOf(address _owner) public constant returns (uint256 balance) {
        return lockedBalance[_owner];
    }

     
    function unlockTimeOf(address _owner) public constant returns (uint timelimit) {
        return timeRelease[_owner];
    }


     
    function transferAndLock(address _to, uint256 _value, uint _releaseTime) public returns (bool success) {
        require(_to != 0x0);
        require(_value <= balances[msg.sender]);
        require(_value > 0);
        require(_releaseTime > now && _releaseTime <= now + 60*60*24*365*5);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
       
         
        uint preRelease = timeRelease[_to];
        if (preRelease <= now && preRelease != 0x0) {
            balances[_to] = balances[_to].add(lockedBalance[_to]);
            lockedBalance[_to] = 0;
        }

        lockedBalance[_to] = lockedBalance[_to].add(_value);
        timeRelease[_to] =  _releaseTime >= timeRelease[_to] ? _releaseTime : timeRelease[_to]; 
        Transfer(msg.sender, _to, _value);
        Lock(_to, _value, _releaseTime);
        return true;
    }


    
   function unlock() public constant returns (bool success){
        uint256 amount = lockedBalance[msg.sender];
        require(amount > 0);
        require(now >= timeRelease[msg.sender]);

        balances[msg.sender] = balances[msg.sender].add(amount);
        lockedBalance[msg.sender] = 0;
        timeRelease[msg.sender] = 0;

        Transfer(0x0, msg.sender, amount);
        UnLock(msg.sender, amount);

        return true;

    }


     
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
    
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }

     
    function isSoleout() public constant returns (bool) {
        return (totalSupply >= INITIAL_SUPPLY);
    }


    modifier canMint() {
        require(!isSoleout());
        _;
    } 
    
     
    function mintBIX(address _to, uint256 _amount, uint256 _lockAmount, uint _releaseTime) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        if (_lockAmount > 0) {
            totalSupply = totalSupply.add(_lockAmount);
            lockedBalance[_to] = lockedBalance[_to].add(_lockAmount);
            timeRelease[_to] =  _releaseTime >= timeRelease[_to] ? _releaseTime : timeRelease[_to];            
            Lock(_to, _lockAmount, _releaseTime);
        }

        Transfer(0x0, _to, _amount);
        return true;
    }
}


 
contract BIXCrowdsale {
    using SafeMath for uint256;

       
      BIXToken public bixToken;
      
      address public owner;

       
      uint256 public startTime;
      uint256 public endTime;
      

      uint256 internal constant baseExchangeRate =  1800 ;        
      uint256 internal constant earlyExchangeRate = 2000 ;
      uint256 internal constant vipExchangeRate =   2400 ;
      uint256 internal constant vcExchangeRate  =   2500 ;
      uint8  internal constant  DaysForEarlyDay = 11;
      uint256  internal constant vipThrehold = 1000 * (10**18);
            

       
      event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
       
      uint256 public weiCrowded;


       
      function BIXCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet) {
            require(_startTime >= now);
            require(_endTime >= _startTime);
            require(_wallet != 0);

            owner = _wallet;
            bixToken = new BIXToken(owner);
            

            startTime = _startTime;
            endTime = _endTime;
      }

       
      function () payable {
          buyTokens(msg.sender);
      }

       
      function buyTokens(address beneficiary) public payable {
            require(beneficiary != 0x0);
            require(validPurchase());

            uint256 weiAmount = msg.value;
            weiCrowded = weiCrowded.add(weiAmount);

            
             
            uint256 rRate = rewardRate();
            uint256 rewardBIX = weiAmount.mul(rRate);
            uint256 baseBIX = weiAmount.mul(baseExchangeRate);

             
             uint256 bixAmount = baseBIX.add(rewardBIX);
           
             
            if(rewardBIX > (earlyExchangeRate - baseExchangeRate)) {
                uint releaseTime = startTime + (60 * 60 * 24 * 30 * 3);
                bixToken.mintBIX(beneficiary, baseBIX, rewardBIX, releaseTime);  
            } else {
                bixToken.mintBIX(beneficiary, bixAmount, 0, 0);  
            }
            
            TokenPurchase(msg.sender, beneficiary, weiAmount, bixAmount);
            forwardFunds();           
      }

       
      function rewardRate() internal constant returns (uint256) {
            
            uint256 rate = baseExchangeRate;

            if (now < startTime) {
                rate = vcExchangeRate;
            } else {
                uint crowdIndex = (now - startTime) / (24 * 60 * 60); 
                if (crowdIndex < DaysForEarlyDay) {
                    rate = earlyExchangeRate;
                } else {
                    rate = baseExchangeRate;
                }

                 
                if (msg.value >= vipThrehold) {
                    rate = vipExchangeRate;
                }
            }
            return rate - baseExchangeRate;
        
      }



       
      function forwardFunds() internal {
            owner.transfer(msg.value);
      }

       
      function validPurchase() internal constant returns (bool) {
            bool nonZeroPurchase = msg.value != 0;
            bool noEnd = !hasEnded();
            
            return  nonZeroPurchase && noEnd;
      }

       
      function hasEnded() public constant returns (bool) {
            return (now > endTime) || bixToken.isSoleout(); 
      }
}