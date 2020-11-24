 

 

pragma solidity ^0.4.18;

 
 
 
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

interface OldXRPCToken {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address _owner) external returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) external;
    function showMyTokenBalance(address addr) external;
}
contract ARBITRAGEToken is ERC20Interface,Ownable {

   using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) tokenBalances;
   
   string public constant name = "ARBITRAGE";
   string public constant symbol = "ARB";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 10000000;
    address ownerWallet;
    
   mapping (address => mapping (address => uint256)) allowed;
   event Debug(string message, address addr, uint256 number);

    function ARBITRAGEToken(address wallet) public {
        owner = msg.sender;
        ownerWallet=wallet;
        totalSupply = INITIAL_SUPPLY * 10 ** 18;
        tokenBalances[wallet] = INITIAL_SUPPLY * 10 ** 18;    
    }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
         return totalSupply  - tokenBalances[address(0)];
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
 

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);                
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                   
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                         
      Transfer(wallet, buyer, tokenAmount); 
      totalSupply=totalSupply.sub(tokenAmount);
    }
    function pullBack(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
        require(tokenBalances[buyer]>=tokenAmount);
        tokenBalances[buyer] = tokenBalances[buyer].sub(tokenAmount);
        tokenBalances[wallet] = tokenBalances[wallet].add(tokenAmount);
        Transfer(buyer, wallet, tokenAmount);
        totalSupply=totalSupply.add(tokenAmount);
     }
    function showMyTokenBalance(address addr) public view returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
    }
}
contract ARBITRAGECrowdsale {
    
    struct Stakeholder
    {
        address stakeholderAddress;
        uint stakeholderPerc;
    }
  using SafeMath for uint256;
 
   
  ARBITRAGEToken public token;
  OldXRPCToken public prevXRPCToken;
  
   
  uint256 public startTime;
  Stakeholder[] ownersList;
  
   
   
  address public walletOwner;
  Stakeholder stakeholderObj;
  

  uint256 public coinPercentage = 5;

     
    uint256 public ratePerWei = 1657;
    uint256 public maxBuyLimit=2000;
    uint256 public tokensSoldInThisRound=0;
    uint256 public totalTokensSold = 0;

     
    uint256 public weiRaised;


    bool public isCrowdsalePaused = false;
    address partnerHandler;
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function ARBITRAGECrowdsale(address _walletOwner, address _partnerHandler) public {
      
        prevXRPCToken = OldXRPCToken(0xAdb41FCD3DF9FF681680203A074271D3b3Dae526); 
        
        startTime = now;
        
        require(_walletOwner != 0x0);
        walletOwner=_walletOwner;

         stakeholderObj = Stakeholder({
         stakeholderAddress: walletOwner,
         stakeholderPerc : 100});
         
         ownersList.push(stakeholderObj);
        partnerHandler = _partnerHandler;
        token = createTokenContract(_walletOwner);
  }

   
  function createTokenContract(address wall) internal returns (ARBITRAGEToken) {
    return new ARBITRAGEToken(wall);
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

  
   

  function buyTokens(address beneficiary) public payable {
    require (isCrowdsalePaused != true);
        
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
     

    uint256 tokens = weiAmount.mul(ratePerWei);
    require(tokensSoldInThisRound.add(tokens)<=maxBuyLimit);
     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(walletOwner, beneficiary, tokens); 
    tokensSoldInThisRound=tokensSoldInThisRound+tokens;
    TokenPurchase(walletOwner, beneficiary, weiAmount, tokens);
    totalTokensSold = totalTokensSold.add(tokens);
    uint partnerCoins = tokens.mul(coinPercentage);
    partnerCoins = partnerCoins.div(100);
    forwardFunds(partnerCoins);
  }

    
    function forwardFunds(uint256 partnerTokenAmount) internal {
      for (uint i=0;i<ownersList.length;i++)
      {
         uint percent = ownersList[i].stakeholderPerc;
         uint amountToBeSent = msg.value.mul(percent);
         amountToBeSent = amountToBeSent.div(100);
         ownersList[i].stakeholderAddress.transfer(amountToBeSent);
         
         if (ownersList[i].stakeholderAddress!=walletOwner &&  ownersList[i].stakeholderPerc>0)
         {
             token.mint(walletOwner,ownersList[i].stakeholderAddress,partnerTokenAmount);
         }
      }
    }
    
    function updateOwnerShares(address[] partnersAddresses, uint[] partnersPercentages) public{
        require(msg.sender==partnerHandler);
        require(partnersAddresses.length==partnersPercentages.length);
        
        uint sumPerc=0;
        for(uint i=0; i<partnersPercentages.length;i++)
        {
            sumPerc+=partnersPercentages[i];
        }
        require(sumPerc==100);
        
        delete ownersList;
        
        for(uint j=0; j<partnersAddresses.length;j++)
        {
            delete stakeholderObj;
             stakeholderObj = Stakeholder({
             stakeholderAddress: partnersAddresses[j],
             stakeholderPerc : partnersPercentages[j]});
             ownersList.push(stakeholderObj);
        }
    }


   
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase;
  }

  
   function showMyTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = token.showMyTokenBalance(msg.sender);
    }
    
     
    function pullBack(address buyer) public {
        require(msg.sender==walletOwner);
        uint bal = token.balanceOf(buyer);
        token.pullBack(walletOwner,buyer,bal);
    }
    

      
    function setPriceRate(uint256 newPrice) public returns (bool) {
        require(msg.sender==walletOwner);
        ratePerWei = newPrice;
    }
    
      
    
      function setMaxBuyLimit(uint256 maxlimit) public returns (bool) {
        require(msg.sender==walletOwner);
        maxBuyLimit = maxlimit *10 ** 18;
    }
    
        
    
      function startNewICORound(uint256 maxlimit, uint256 newPrice) public returns (bool) {
        require(msg.sender==walletOwner);
        setMaxBuyLimit(maxlimit);
        setPriceRate(newPrice);
        tokensSoldInThisRound=0;
    }
    
        
    
      function getCurrentICORoundInfo() public view returns 
      (uint256 maxlimit, uint256 newPrice, uint tokensSold) {
       return(maxBuyLimit,ratePerWei,tokensSoldInThisRound);
    }
    
     
     
    function pauseCrowdsale() public returns(bool) {
        require(msg.sender==walletOwner);
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public returns (bool) {
        require(msg.sender==walletOwner);
        isCrowdsalePaused = false;
    }
    
      
    function tokensRemainingForSale() public view returns (uint256 balance) {
        balance = token.balanceOf(walletOwner);
    }
    
     
    function checkOwnerShare (address owner) public constant returns (uint share) {
        require(msg.sender==walletOwner);
        
        for(uint i=0;i<ownersList.length;i++)
        {
            if(ownersList[i].stakeholderAddress==owner)
            {
                return ownersList[i].stakeholderPerc;
            }
        }
        return 0;
    }

     
    function changePartnerCoinPercentage(uint percentage) public {
        require(msg.sender==walletOwner);
        coinPercentage = percentage;
    }
    
      
    function airDropToOldTokenHolders(address[] oldTokenHolders) public {
        require(msg.sender==walletOwner);
        for(uint i = 0; i<oldTokenHolders.length; i++){
            if(prevXRPCToken.balanceOf(oldTokenHolders[i])>0)
            {
                token.mint(walletOwner,oldTokenHolders[i],prevXRPCToken.balanceOf(oldTokenHolders[i]));
            }
        }
    }
    
    function changeWalletOwner(address newWallet) public {
        require(msg.sender==walletOwner);
        walletOwner = newWallet;
    }
}