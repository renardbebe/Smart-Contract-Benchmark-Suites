 

pragma solidity 0.4.18;

 
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract CostumeToken is PausableToken {
  using SafeMath for uint256;

   
  string public constant name = 'Costume Token';
  string public constant symbol = 'COST';
  uint8 public constant decimals = 18;

   
  uint256 public constant totalSupply = 200e24;

   
  uint256 public initialSupply = 120e24;

   
  uint256 public limitCrowdsale = 80e24;

   
  uint256 public tokensDistributedCrowdsale = 0;

   
  address public crowdsale;

   

   
  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

   
  function CostumeToken() public {
    balances[msg.sender] = initialSupply;
  }

   
   
  function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenNotPaused {
    require(crowdsale == address(0));
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

   
   
   
  function distributeCrowdsaleTokens(address _buyer, uint tokens) external onlyCrowdsale whenNotPaused {
    require(_buyer != address(0));
    require(tokens > 0);

    require(tokensDistributedCrowdsale < limitCrowdsale);
    require(tokensDistributedCrowdsale.add(tokens) <= limitCrowdsale);

     
    tokensDistributedCrowdsale = tokensDistributedCrowdsale.add(tokens);

     
    balances[_buyer] = balances[_buyer].add(tokens);
  }

}

contract Crowdsale is Pausable {
   using SafeMath for uint256;

    
   CostumeToken public token;

    
   uint256 public startTime = 1513339200;

    
   uint256 public endTime = 1517400000;

    
   address public wallet;

    
   uint256 public rate = 3400;
   uint256 public rateTier2 = 3200;
   uint256 public rateTier3 = 3000;
   uint256 public rateTier4 = 2800;

    
    
   uint256 public limitTier1 = 20e24;
   uint256 public limitTier2 = 40e24;
   uint256 public limitTier3 = 60e24;

    
   uint256 public constant maxTokensRaised = 80e24;

    
   uint256 public weiRaised = 0;

    
   uint256 public tokensRaised = 0;

    
   uint256 public constant minPurchase = 100 finney;

    
   bool public remainingTransfered = false;

    
   uint256 public numberOfTransactions;

    

    
   mapping(address => uint256) public crowdsaleBalances;

    
   mapping(address => uint256) public tokensBought;

    

    
   event TokenPurchase(address indexed buyer, uint256 value, uint256 amountOfTokens);

    
   event Finalized();

    

    
   modifier beforeStarting() {
      require(now < startTime);
      _;
   }

    
    
    
    
    
   function Crowdsale(
      address _wallet,
      address _tokenAddress,
      uint256 _startTime,
      uint256 _endTime
   ) public {
      require(_wallet != address(0));
      require(_tokenAddress != address(0));

      if (_startTime > 0 && _endTime > 0) {
          require(_startTime < _endTime);
      }

      wallet = _wallet;
      token = CostumeToken(_tokenAddress);

      if (_startTime > 0) {
          startTime = _startTime;
      }

      if (_endTime > 0) {
          endTime = _endTime;
      }

   }

    
   function () external payable {
      buyTokens();
   }

    
   function buyTokens() public payable whenNotPaused {
      require(validPurchase());

      uint256 tokens = 0;
      uint256 amountPaid = adjustAmountValue();

      if (tokensRaised < limitTier1) {

          
         tokens = amountPaid.mul(rate);

          
         if (tokensRaised.add(tokens) > limitTier1) {

            tokens = adjustTokenTierValue(amountPaid, limitTier1, 1, rate);
         }

      } else if (tokensRaised >= limitTier1 && tokensRaised < limitTier2) {

          
         tokens = amountPaid.mul(rateTier2);

           
         if (tokensRaised.add(tokens) > limitTier2) {
            tokens = adjustTokenTierValue(amountPaid, limitTier2, 2, rateTier2);
         }

      } else if (tokensRaised >= limitTier2 && tokensRaised < limitTier3) {

          
         tokens = amountPaid.mul(rateTier3);

          
         if (tokensRaised.add(tokens) > limitTier3) {
            tokens = adjustTokenTierValue(amountPaid, limitTier3, 3, rateTier3);
         }

      } else if (tokensRaised >= limitTier3) {

          
         tokens = amountPaid.mul(rateTier4);

      }

      weiRaised = weiRaised.add(amountPaid);
      tokensRaised = tokensRaised.add(tokens);
      token.distributeCrowdsaleTokens(msg.sender, tokens);

       
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);

       
      TokenPurchase(msg.sender, amountPaid, tokens);

       
      numberOfTransactions = numberOfTransactions.add(1);

      forwardFunds(amountPaid);
   }

    
   function forwardFunds(uint256 amountPaid) internal whenNotPaused {

      
     wallet.transfer(amountPaid);
   }

    
   function adjustAmountValue() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;

       
      if(tokensRaised >= limitTier3) {
         uint256 addedTokens = tokensRaised.add(amountPaid.mul(rateTier4));

          
         if(addedTokens > maxTokensRaised) {

             
            uint256 difference = addedTokens.sub(maxTokensRaised);
            differenceWei = difference.div(rateTier4);
            amountPaid = amountPaid.sub(differenceWei);
         }
      }

       
      crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);

       
      if (differenceWei > 0) msg.sender.transfer(differenceWei);

      return amountPaid;
   }

    
    
   function setTierRates(uint256 tier1, uint256 tier2, uint256 tier3, uint256 tier4)
      external onlyOwner whenNotPaused {

      require(tier1 > 0 && tier2 > 0 && tier3 > 0 && tier4 > 0);
      require(tier1 > tier2 && tier2 > tier3 && tier3 > tier4);

      rate = tier1;
      rateTier2 = tier2;
      rateTier3 = tier3;
      rateTier4 = tier4;
   }

    
    
    
    
    
   function adjustTokenTierValue(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
   ) internal returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;
      bool returnTokens = false;

       
      if(tierSelected != 4) {

         tokensNextTier = calculateTokensPerTier(weiNextTier, tierSelected.add(1));

      } else {

         returnTokens = true;

      }

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

       
      if (returnTokens) msg.sender.transfer(weiNextTier);
   }

    
    
    
   function calculateTokensPerTier(uint256 weiPaid, uint256 tierSelected)
        internal constant returns(uint256 calculatedTokens)
    {
      require(weiPaid > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      if (tierSelected == 1) {

         calculatedTokens = weiPaid.mul(rate);

      } else if (tierSelected == 2) {

         calculatedTokens = weiPaid.mul(rateTier2);

      } else if (tierSelected == 3) {

         calculatedTokens = weiPaid.mul(rateTier3);

      } else {

         calculatedTokens = weiPaid.mul(rateTier4);
     }
   }

    
   function validPurchase() internal constant returns(bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool nonZeroPurchase = msg.value > 0;
      bool withinTokenLimit = tokensRaised < maxTokensRaised;
      bool minimumPurchase = msg.value >= minPurchase;

      return withinPeriod && nonZeroPurchase && withinTokenLimit && minimumPurchase;
   }

    
   function hasEnded() public constant returns(bool) {
       return now > endTime || tokensRaised >= maxTokensRaised;
   }

    
   function completeCrowdsale() external onlyOwner whenNotPaused {
       require(hasEnded());

        
       transferTokensLeftOver();

        
       Finalized();
   }

    
   function transferTokensLeftOver() internal {
       require(!remainingTransfered);
       require(maxTokensRaised > tokensRaised);

       remainingTransfered = true;

       uint256 remainingTokens = maxTokensRaised.sub(tokensRaised);
       token.distributeCrowdsaleTokens(msg.sender, remainingTokens);
   }

    
    
    
   function changeDates(uint256 _startTime, uint256 _endTime)
        external onlyOwner beforeStarting
    {

       if (_startTime > 0 && _endTime > 0) {
           require(_startTime < _endTime);
       }

       if (_startTime > 0) {
           startTime = _startTime;
       }

       if (_endTime > 0) {
           endTime = _endTime;
       }
   }

    
    
   function changeEndDate(uint256 _endTime) external onlyOwner {
       require(_endTime > startTime);
       require(_endTime > now);
       require(!hasEnded());

       if (_endTime > 0) {
           endTime = _endTime;
       }
   }

}