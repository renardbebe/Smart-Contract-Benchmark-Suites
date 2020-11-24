 

pragma solidity ^0.4.18;



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  

   
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

contract TOKKA is StandardToken {
    string public name = "StreamPay Token";
    string public symbol = "STPY";
    uint256 public decimals = 18;

   
    function TOKKA() public {
       totalSupply = 35000000 * 10**18;
       balances[msg.sender] = totalSupply;
    }
}


contract Crowdsale is Ownable {
  using SafeMath for uint256;

    
  TOKKA public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate ;

   
  uint256 public weiRaised;
  
   
  uint256 public CAP = 68254061116636440000000;
  
  bool crowdsaleClosed = false;
  
   
  
  uint256 public PreIcobonusEnds = 1535731200;
  
  uint256 public StgOnebonusEnds = 1538323200;
  uint256 public StgTwobonusEnds = 1541001600;
  uint256 public StgThreebonusEnds = 1543593600;
  uint256 public StgFourbonusEnds = 1546272000;
  
  
  

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    
     
    
     
    
    token = createTokenContract();
  }

 
 
function createTokenContract() internal returns (TOKKA) {
    return new TOKKA();
  }


   
  function() external payable {
    buyTokens(msg.sender);
  }

   
function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    require(!crowdsaleClosed);
    
     
    
    
    
    if (now <= PreIcobonusEnds) {
            rate = 667;
         } 
    
     else if (now <= StgOnebonusEnds && now > PreIcobonusEnds) {
            rate = 641;
         }  
    
    else if (now <= StgTwobonusEnds && now > StgOnebonusEnds ) {
            rate = 616;
         }  
     
     else if (now <= StgThreebonusEnds && now > StgTwobonusEnds ) {
            rate = 590;
         } 
         else if (now <= StgFourbonusEnds && now > StgThreebonusEnds ) {
            rate = 564;
         }
    else{
        rate = 513;
    }
     
    

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

     
     
     
    token.transfer(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
}


  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }


  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
  
  function GoalReached() public view returns (bool) {
    return (weiRaised >= CAP);
  }
  
  function Pause() public onlyOwner
  {
        
           
         
        require(weiRaised >= CAP);
        
        crowdsaleClosed = true;
  }
  
  function Play() public onlyOwner
  {
        
           
         
        require(crowdsaleClosed == true);
        
        crowdsaleClosed = false;
  }

}