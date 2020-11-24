 

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

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract HashcoCoin is ERC20Interface,Ownable {

   using SafeMath for uint256;
   
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   mapping(address => uint256) tokenBalances;
   address ownerWallet;
    
   mapping (address => mapping (address => uint256)) allowed;
   
    
    function HashcoCoin(address wallet) public {
        owner = msg.sender;
        ownerWallet = wallet;
        name  = "HashcoCoin";
        symbol = "HCC";
        decimals = 18;
        _totalSupply = 60000000 * 10 ** uint(decimals);
        tokenBalances[wallet] = _totalSupply;    
    }
    
      
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
      
     function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         Transfer(msg.sender, to, tokens);
         return true;
     }
  
      
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
      
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

      
      
      
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - tokenBalances[address(0)];
     }
     
    
     
      
      
      
      
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
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

     
      
      
      
     function () public payable {
         revert();
     }
 
 
      
      
      
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }
     
      
     
     function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);                
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                   
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                         
      Transfer(wallet, buyer, tokenAmount); 
      _totalSupply = _totalSupply.sub(tokenAmount);
    }
}
contract HashcoCoinCrowdsale {
  using SafeMath for uint256;
 
   
  HashcoCoin public token;

   
   
  address public wallet;

   
  uint256 public ratePerWeiFirstPhase = 5263;
  uint256 public ratePerWeiSecondPhase = 3333;

   
  uint256 public weiRaised;

  uint256 TOKENS_SOLD;
  uint256 maxTokensToSale = 60000000 * 10 ** 18;
  
  
  bool isCrowdsalePaused = false;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function HashcoCoinCrowdsale(address _wallet) public 
  {
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
  }
  
    
  function createTokenContract(address wall) internal returns (HashcoCoin) {
    return new HashcoCoin(wall);
  }
   
  function () public payable {
    buyTokens(msg.sender);
  }
   
   
   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(msg.value>0);
    require(TOKENS_SOLD<maxTokensToSale);
    uint256 weiAmount = msg.value;
    uint256 tokens;
    uint256 bonus;

     
    if (TOKENS_SOLD < 15000000 * 10 ** 18)
    {
        tokens = weiAmount.mul(ratePerWeiFirstPhase);
        require(TOKENS_SOLD+tokens<=maxTokensToSale);
    }
    else 
    {
        tokens = weiAmount.mul(ratePerWeiSecondPhase);
        require(TOKENS_SOLD+tokens<=maxTokensToSale);
    }
    bonus = tokens.mul(10);
    bonus = bonus.div(100);
    tokens = tokens.add(bonus);

     
    weiRaised = weiRaised.add(weiAmount);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    require (TOKENS_SOLD<=maxTokensToSale);
    token.mint(wallet, beneficiary, tokens); 
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

    
     
     
    function setPriceRatePhase1(uint256 newPrice) public returns (bool) {
        require (msg.sender == wallet);
        ratePerWeiFirstPhase = newPrice;
    }
    
     
     
    function setPriceRatePhase2(uint256 newPrice) public returns (bool) {
        require (msg.sender == wallet);
        ratePerWeiSecondPhase = newPrice;
    }
    
      
     
    function pauseCrowdsale() public returns(bool) {
        require(msg.sender==wallet);
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public returns (bool) {
        require(msg.sender==wallet);
        isCrowdsalePaused = false;
    }
    
      
      
      
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale - TOKENS_SOLD;
     }
     
     function showMyTokenBalance() public constant returns (uint) {
         return token.balanceOf(msg.sender);
     }
}