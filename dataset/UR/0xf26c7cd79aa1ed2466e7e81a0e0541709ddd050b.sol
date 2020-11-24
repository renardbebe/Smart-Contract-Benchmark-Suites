 

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

contract BTC20Token is BasicToken,Ownable {

   using SafeMath for uint256;
   
    
   string public constant name = "BTC20";
   string public constant symbol = "BTC20";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 21000000;
   event Debug(string message, address addr, uint256 number);
   
    function BTC20Token(address wallet) public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY * 10 ** 18;
        tokenBalances[wallet] = totalSupply;    
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
contract BTC20Crowdsale {
  using SafeMath for uint256;
 
   
  BTC20Token public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
   
  address public wallet;

   
  uint256 public ratePerWei = 50000;

   
  uint256 public weiRaised;

  uint256 TOKENS_SOLD;
  uint256 maxTokensToSale = 15000000 * 10 ** 18;
  uint256 minimumContribution = 5 * 10 ** 16;  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function BTC20Crowdsale(uint256 _startTime, address _wallet) public 
  {
    startTime = _startTime;   
    endTime = startTime + 14 days;
    
    require(endTime >= startTime);
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
    
  }
   
  function createTokenContract(address wall) internal returns (BTC20Token) {
    return new BTC20Token(wall);
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function determineBonus(uint tokens) internal view returns (uint256 bonus) {
    uint256 timeElapsed = now - startTime;
    uint256 timeElapsedInWeeks = timeElapsed.div(7 days);
    if (timeElapsedInWeeks == 0)
    {
      bonus = tokens.mul(50);  
      bonus = bonus.div(100);
    }
    else if (timeElapsedInWeeks == 1)
    {
      bonus = tokens.mul(25);  
      bonus = bonus.div(100);
    }
    else
    {
        bonus = 0;    
    }
  }

   
   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(msg.value>= minimumContribution);
    require(TOKENS_SOLD<maxTokensToSale);
    uint256 weiAmount = msg.value;
    
     
    
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD+tokens<=maxTokensToSale);
    
     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(wallet, beneficiary, tokens); 
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
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
  
   
    function changeEndDate(uint256 endTimeUnixTimestamp) public returns(bool) {
        require (msg.sender == wallet);
        endTime = endTimeUnixTimestamp;
    }
    function changeStartDate(uint256 startTimeUnixTimestamp) public returns(bool) {
        require (msg.sender == wallet);
        startTime = startTimeUnixTimestamp;
    }
    function setPriceRate(uint256 newPrice) public returns (bool) {
        require (msg.sender == wallet);
        ratePerWei = newPrice;
    }
    
    function changeMinimumContribution(uint256 minContribution) public returns (bool) {
        require (msg.sender == wallet);
        minimumContribution = minContribution * 10 ** 15;
    }
}