 

pragma solidity ^0.4.15;

 
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


 
 
contract B2BCToken is StandardToken, Ownable{
    
    string public version = "1.8";
    string public name = "B2B Coin Token";
    string public symbol = "B2BC";
    uint8 public  decimals = 18;

    
    uint256 internal constant INITIAL_SUPPLY = 300 * (10**6) * (10 **18);
    uint256 internal constant DEVELOPER_RESERVED = 120 * (10**6) * (10**18);

     
     


    event Burn(address indexed burner, uint256 value);
    
     
    function B2BCToken(address _developer) { 
        balances[_developer] = DEVELOPER_RESERVED;
        totalSupply = DEVELOPER_RESERVED;
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
    
     
    function mintB2BC(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
}


 
contract B2BCCrowdsale is Ownable{
    using SafeMath for uint256;

       
      B2BCToken public b2bcToken;

       
      uint256 public startTime;
      uint256 public endTime;
      

      uint256 internal constant baseExchangeRate =  2000 ;   
      uint256 internal constant earlyExchangeRate = 2300 ;   
      uint256 internal constant vipExchangeRate =   2900 ;   
      uint256 internal constant vcExchangeRate  =   3000 ;   
      uint8   internal constant  DaysForEarlyDay = 11;
      uint256 internal constant vipThrehold = 1000 * (10**18);
           
       
      uint256 public weiCrowded;
      event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

       
      function B2BCCrowdsale() {          
            owner = 0xeedA60D0C81836747f684cE48d53137d08392448;
            b2bcToken = new B2BCToken(owner); 
      }

      function setStartEndTime(uint256 _startTime, uint256 _endTime) onlyOwner{
            require(_startTime >= now);
            require(_endTime >= _startTime);
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
            uint256 rewardB2BC = weiAmount.mul(rRate);
            uint256 baseB2BC = weiAmount.mul(baseExchangeRate);
           
             
            if(rRate > baseExchangeRate) {
                b2bcToken.mintB2BC(beneficiary, rewardB2BC);  
                TokenPurchase(msg.sender, beneficiary, weiAmount, rewardB2BC);
            } else {
                b2bcToken.mintB2BC(beneficiary, baseB2BC);  
                TokenPurchase(msg.sender, beneficiary, weiAmount, baseB2BC);
            }

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
            return rate;
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
            return (now > endTime) || b2bcToken.isSoleout(); 
      }
}