 

pragma solidity ^0.4.11;

 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

}
 
contract XrpcToken is BasicToken,Ownable {

   using SafeMath for uint256;
   
    
   string public constant name = "XRPConnect";
   string public constant symbol = "XRPC";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 10000000;
   event Debug(string message, address addr, uint256 number);
   
    
    function XrpcToken(address wallet) public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[wallet] = INITIAL_SUPPLY * 10 ** 18;    
    }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);                
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                   
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                         
      Transfer(wallet, buyer, tokenAmount); 
    }
  function showMyTokenBalance(address addr) public view returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
    }
}
contract Crowdsale {
  using SafeMath for uint256;
 
   
  XrpcToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;


   

  uint256 public week1Price = 2117;   
  uint256 public week2Price = 1466;
  uint256 public week3Price = 1121;
  uint256 public week4Price = 907;
  
  bool ownerAmountPaid = false; 

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, address _wallet) public {
     
    require(_startTime >= now);
    startTime = _startTime;
    
     
     
    endTime = startTime + 30 days;
    
    require(endTime >= startTime);
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
    
  }

    function sendOwnerShares(address wal) public
    {
        require(msg.sender == wallet);
        require(ownerAmountPaid == false);
        uint256 ownerAmount = 350000*10**18;
        token.mint(wallet, wal,ownerAmount);
        ownerAmountPaid = true;
    }
   
   
  function createTokenContract(address wall) internal returns (XrpcToken) {
    return new XrpcToken(wall);
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function determineRate() internal view returns (uint256 weekRate) {
    uint256 timeElapsed = now - startTime;
    uint256 timeElapsedInWeeks = timeElapsed.div(7 days);

    if (timeElapsedInWeeks == 0)
      weekRate = week1Price;         

    else if (timeElapsedInWeeks == 1)
      weekRate = week2Price;         

    else if (timeElapsedInWeeks == 2)
      weekRate = week3Price;         

    else if (timeElapsedInWeeks == 3)
      weekRate = week4Price;         

    else
    {
        weekRate = 0;    
    }
  }

   
   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
     

     
    rate = determineRate();
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(wallet, beneficiary, tokens); 
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
    
}