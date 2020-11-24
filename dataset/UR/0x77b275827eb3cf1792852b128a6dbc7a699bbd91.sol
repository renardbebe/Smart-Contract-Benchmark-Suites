 

pragma solidity ^0.4.15;

 
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_to] = balances[_to].add(_value);
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


 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


 
contract PallyCoin is PausableToken {
   using SafeMath for uint256;

   string public constant name = 'PallyCoin';

   string public constant symbol = 'PAL';

   uint8 public constant decimals = 18;

   uint256 public constant totalSupply = 100e24;  

    
   uint256 public tokensDistributedPresale = 0;

    
   uint256 public tokensDistributedCrowdsale = 0;

   address public crowdsale;

    
   modifier onlyCrowdsale() {
      require(msg.sender == crowdsale);
      _;
   }

    
   event RefundedTokens(address indexed user, uint256 tokens);

    
    
    
    
   function PallyCoin() {
      balances[msg.sender] = 40e24;  
   }

    
    
   function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenNotPaused {
      require(_crowdsale != address(0));

      crowdsale = _crowdsale;
   }

    
    
    
   function distributePresaleTokens(address _buyer, uint tokens) external onlyOwner whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0 && tokens <= 10e24);

       
      require(tokensDistributedPresale < 10e24);

      tokensDistributedPresale = tokensDistributedPresale.add(tokens);
      balances[_buyer] = balances[_buyer].add(tokens);
   }

    
    
    
   function distributeICOTokens(address _buyer, uint tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);

       
      require(tokensDistributedCrowdsale < 50e24);

      tokensDistributedCrowdsale = tokensDistributedCrowdsale.add(tokens);
      balances[_buyer] = balances[_buyer].add(tokens);
   }

    
    
    
   function refundTokens(address _buyer, uint256 tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);
      require(balances[_buyer] >= tokens);

      balances[_buyer] = balances[_buyer].sub(tokens);
      RefundedTokens(_buyer, tokens);
   }
}

 
 
 

 
 
 
 
 
 
contract Crowdsale is Pausable {
   using SafeMath for uint256;

    
   PallyCoin public token;

    
   RefundVault public vault;

    
    
    
   uint256 public startTime = 1508065200;

    
    
    
   uint256 public endTime = 1510570800;

    
   address public wallet;

    
    
   uint256 public rate;

    
    
   uint256 public rateTier2;

    
    
   uint256 public rateTier3;

    
    
   uint256 public rateTier4;

    
   uint256 public limitTier1 = 12.5e24;
   uint256 public limitTier2 = 25e24;
   uint256 public limitTier3 = 37.5e24;

    
   uint256 public weiRaised = 0;

    
   uint256 public tokensRaised = 0;

    
   uint256 public constant maxTokensRaised = 50e24;

    
   uint256 public constant minPurchase = 10 finney;  

    
   uint256 public constant maxPurchase = 2000 ether;

    
    
    
   uint256 public constant minimumGoal = 5.33e24;

    
    
   bool public isRefunding = false;

    
   bool public isEnded = false;

    
   uint256 public numberOfTransactions;

    
   uint256 public limitGasPrice = 50000000000 wei;

    
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

       
      if(_startTime > 0 && _endTime > 0)
         require(_startTime < _endTime);

      wallet = _wallet;
      token = PallyCoin(_tokenAddress);
      vault = new RefundVault(_wallet);

      if(_startTime > 0)
         startTime = _startTime;

      if(_endTime > 0)
         endTime = _endTime;
   }

    
   function () payable {
      buyTokens();
   }

    
   function buyTokens() public payable whenNotPaused {
      require(validPurchase());

      uint256 tokens = 0;
      uint256 amountPaid = calculateExcessBalance();

      if(tokensRaised < limitTier1) {

          
         tokens = amountPaid.mul(rate);

          
         if(tokensRaised.add(tokens) > limitTier1)
            tokens = calculateExcessTokens(amountPaid, limitTier1, 1, rate);
      } else if(tokensRaised >= limitTier1 && tokensRaised < limitTier2) {

          
         tokens = amountPaid.mul(rateTier2);

          
         if(tokensRaised.add(tokens) > limitTier2)
            tokens = calculateExcessTokens(amountPaid, limitTier2, 2, rateTier2);
      } else if(tokensRaised >= limitTier2 && tokensRaised < limitTier3) {

          
         tokens = amountPaid.mul(rateTier3);

          
         if(tokensRaised.add(tokens) > limitTier3)
            tokens = calculateExcessTokens(amountPaid, limitTier3, 3, rateTier3);
      } else if(tokensRaised >= limitTier3) {

          
         tokens = amountPaid.mul(rateTier4);
      }

      weiRaised = weiRaised.add(amountPaid);
      tokensRaised = tokensRaised.add(tokens);
      token.distributeICOTokens(msg.sender, tokens);

       
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);
      TokenPurchase(msg.sender, amountPaid, tokens);
      numberOfTransactions = numberOfTransactions.add(1);

      forwardFunds(amountPaid);
   }

    
    
    
   function forwardFunds(uint256 amountPaid) internal whenNotPaused {
      if(goalReached()) {

         wallet.transfer(amountPaid);

      } else {
         vault.deposit.value(amountPaid)(msg.sender);
      }

       
       
      checkCompletedCrowdsale();
   }

    
    
    
    
    
   function calculateExcessBalance() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;
      uint256 exceedingBalance = 0;

       
       
       
      if(tokensRaised >= limitTier3) {
         uint256 addedTokens = tokensRaised.add(amountPaid.mul(rateTier4));

          
         if(addedTokens > maxTokensRaised) {

             
            uint256 difference = addedTokens.sub(maxTokensRaised);
            differenceWei = difference.div(rateTier4);
            amountPaid = amountPaid.sub(differenceWei);
         }
      }

      uint256 addedBalance = crowdsaleBalances[msg.sender].add(amountPaid);

       
      if(addedBalance <= maxPurchase) {
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      } else {

          
         exceedingBalance = addedBalance.sub(maxPurchase);
         amountPaid = amountPaid.sub(exceedingBalance);

          
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      }

       
      if(differenceWei > 0)
         msg.sender.transfer(differenceWei);

      if(exceedingBalance > 0) {

          
         msg.sender.transfer(exceedingBalance);
      }

      return amountPaid;
   }

    
    
    
    
    
    
    
   function setTierRates(uint256 tier1, uint256 tier2, uint256 tier3, uint256 tier4)
      external onlyOwner whenNotPaused
   {
      require(tier1 > 0 && tier2 > 0 && tier3 > 0 && tier4 > 0);
      require(tier1 > tier2 && tier2 > tier3 && tier3 > tier4);

      rate = tier1;
      rateTier2 = tier2;
      rateTier3 = tier3;
      rateTier4 = tier4;
   }

    
    
   function setEndDate(uint256 _endTime)
      external onlyOwner whenNotPaused
   {
      require(now <= _endTime);
      require(startTime < _endTime);
      
      endTime = _endTime;
   }


    
    
   function checkCompletedCrowdsale() public whenNotPaused {
      if(!isEnded) {
         if(hasEnded() && !goalReached()){
            vault.enableRefunds();

            isRefunding = true;
            isEnded = true;
            Finalized();
         } else if(goalReached()) {
            
            vault.close();
            isEnded = true;
            Finalized();
         }
      }
   }

    
   function claimRefund() public whenNotPaused {
     require(hasEnded() && !goalReached() && isRefunding);

     vault.refund(msg.sender);
     token.refundTokens(msg.sender, tokensBought[msg.sender]);
   }

    
    
    
    
    
    
   function calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
   ) public returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;
      bool returnTokens = false;

       
      if(tierSelected != 4)
         tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
      else
         returnTokens = true;

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

       
      if(returnTokens) msg.sender.transfer(weiNextTier);
   }

    
    
    
    
   function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        internal constant returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      if(tierSelected == 1)
         calculatedTokens = weiPaid.mul(rate);
      else if(tierSelected == 2)
         calculatedTokens = weiPaid.mul(rateTier2);
      else if(tierSelected == 3)
         calculatedTokens = weiPaid.mul(rateTier3);
      else
         calculatedTokens = weiPaid.mul(rateTier4);
   }


    
    
   function validPurchase() internal constant returns(bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool nonZeroPurchase = msg.value > 0;
      bool withinTokenLimit = tokensRaised < maxTokensRaised;
      bool minimumPurchase = msg.value >= minPurchase;
      bool hasBalanceAvailable = crowdsaleBalances[msg.sender] < maxPurchase;

       
       

      return withinPeriod && nonZeroPurchase && withinTokenLimit && minimumPurchase && hasBalanceAvailable;
   }

    
    
   function goalReached() public constant returns(bool) {
      return tokensRaised >= minimumGoal;
   }

    
   function hasEnded() public constant returns(bool) {
      return now > endTime || tokensRaised >= maxTokensRaised;
   }
}