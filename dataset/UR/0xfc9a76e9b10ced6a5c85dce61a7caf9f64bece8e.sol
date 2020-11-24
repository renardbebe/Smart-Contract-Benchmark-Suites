 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 


 
contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);
   event OwnershipTransferCanceled();


   function Owned() public
   {
      owner = msg.sender;
   }


   modifier onlyOwner() {
      require(isOwner(msg.sender) == true);
      _;
   }


   function isOwner(address _address) public view returns (bool) {
      return (_address == owner);
   }


   function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
      require(_proposedOwner != address(0));
      require(_proposedOwner != address(this));
      require(_proposedOwner != owner);

      proposedOwner = _proposedOwner;

      OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function cancelOwnershipTransfer() public onlyOwner returns (bool) {
      if (proposedOwner == address(0)) {
         return true;
      }

      proposedOwner = address(0);

      OwnershipTransferCanceled();

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      OwnershipTransferCompleted(owner);

      return true;
   }
}

 
 
 
 
 
 
 



 
 
 
contract OpsManaged is Owned {

   address public opsAddress;

   event OpsAddressUpdated(address indexed _newAddress);


   function OpsManaged() public
      Owned()
   {
   }


   modifier onlyOwnerOrOps() {
      require(isOwnerOrOps(msg.sender));
      _;
   }


   function isOps(address _address) public view returns (bool) {
      return (opsAddress != address(0) && _address == opsAddress);
   }


   function isOwnerOrOps(address _address) public view returns (bool) {
      return (isOwner(_address) || isOps(_address));
   }


   function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool) {
      require(_newOpsAddress != owner);
      require(_newOpsAddress != address(this));

      opsAddress = _newOpsAddress;

      OpsAddressUpdated(opsAddress);

      return true;
   }
}

 
 
 
 
 
 
 


library Math {

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a + b;

      require(r >= a);

      return r;
   }


   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b);

      return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a * b;

      require(a == 0 || r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

 
 
 
 
 
 
 

 
 
 
 
contract ERC20Interface {

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function name() public view returns (string);
   function symbol() public view returns (string);
   function decimals() public view returns (uint8);
   function totalSupply() public view returns (uint256);

   function balanceOf(address _owner) public view returns (uint256 balance);
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   function transfer(address _to, uint256 _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   function approve(address _spender, uint256 _value) public returns (bool success);
}

 
 
 
 
 
 
 


contract ERC20Token is ERC20Interface {

   using Math for uint256;

   string  private tokenName;
   string  private tokenSymbol;
   uint8   private tokenDecimals;
   uint256 internal tokenTotalSupply;

   mapping(address => uint256) internal balances;
   mapping(address => mapping (address => uint256)) allowed;


   function ERC20Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
      tokenName = _name;
      tokenSymbol = _symbol;
      tokenDecimals = _decimals;
      tokenTotalSupply = _totalSupply;

       
      balances[_initialTokenHolder] = _totalSupply;

       
      Transfer(0x0, _initialTokenHolder, _totalSupply);
   }


   function name() public view returns (string) {
      return tokenName;
   }


   function symbol() public view returns (string) {
      return tokenSymbol;
   }


   function decimals() public view returns (uint8) {
      return tokenDecimals;
   }


   function totalSupply() public view returns (uint256) {
      return tokenTotalSupply;
   }


   function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
   }


   function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      Transfer(msg.sender, _to, _value);

      return true;
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      Transfer(_from, _to, _value);

      return true;
   }


   function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      Approval(msg.sender, _spender, _value);

      return true;
   }
}

 
 
 
 
 
 
 



contract Finalizable is Owned {

   bool public finalized;

   event Finalized();


   function Finalizable() public
      Owned()
   {
      finalized = false;
   }


   function finalize() public onlyOwner returns (bool) {
      require(!finalized);

      finalized = true;

      Finalized();

      return true;
   }
}

 
 
 
 
 
 
 



 
 
 
 
 
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

   using Math for uint256;


    
   function FinalizableToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
      ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
      OpsManaged()
      Finalizable()
   {
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transfer(_to, _value);
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transferFrom(_from, _to, _value);
   }


   function validateTransfer(address _sender, address _to) private view {
      require(_to != address(0));

       
      if (finalized) {
         return;
      }

      if (isOwner(_to)) {
         return;
      }

       
       
      require(isOwnerOrOps(_sender));
   }
}



 
 
 
 
 
 
 



contract FlexibleTokenSale is Finalizable, OpsManaged {

   using Math for uint256;

    
    
    
   uint256 public startTime;
   uint256 public endTime;
   bool public suspended;

    
    
    
   uint256 public tokensPerKEther;
   uint256 public bonus;
   uint256 public maxTokensPerAccount;
   uint256 public contributionMin;
   uint256 public tokenConversionFactor;

    
    
    
   address public walletAddress;

    
    
    
   FinalizableToken public token;

    
    
    
   uint256 public totalTokensSold;
   uint256 public totalEtherCollected;


    
    
    
   event Initialized();
   event TokensPerKEtherUpdated(uint256 _newValue);
   event MaxTokensPerAccountUpdated(uint256 _newMax);
   event BonusUpdated(uint256 _newValue);
   event SaleWindowUpdated(uint256 _startTime, uint256 _endTime);
   event WalletAddressUpdated(address _newAddress);
   event SaleSuspended();
   event SaleResumed();
   event TokensPurchased(address _beneficiary, uint256 _cost, uint256 _tokens);
   event TokensReclaimed(uint256 _amount);


   function FlexibleTokenSale(uint256 _startTime, uint256 _endTime, address _walletAddress) public
      OpsManaged()
   {
      require(_endTime > _startTime);

      require(_walletAddress != address(0));
      require(_walletAddress != address(this));

      walletAddress = _walletAddress;

      finalized = false;
      suspended = false;

      startTime = _startTime;
      endTime   = _endTime;

       
       
      tokensPerKEther     = 100000;
      bonus               = 0;
      maxTokensPerAccount = 0;
      contributionMin     = 0.1 ether;

      totalTokensSold     = 0;
      totalEtherCollected = 0;
   }


   function currentTime() public constant returns (uint256) {
      return now;
   }


    
    
   function initialize(FinalizableToken _token) external onlyOwner returns(bool) {
      require(address(token) == address(0));
      require(address(_token) != address(0));
      require(address(_token) != address(this));
      require(address(_token) != address(walletAddress));
      require(isOwnerOrOps(address(_token)) == false);

      token = _token;

       
       
       
       
      tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(3).add(4));
      require(tokenConversionFactor > 0);

      Initialized();

      return true;
   }


    
    
    

    
    
   function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
      require(_walletAddress != address(0));
      require(_walletAddress != address(this));
      require(_walletAddress != address(token));
      require(isOwnerOrOps(_walletAddress) == false);

      walletAddress = _walletAddress;

      WalletAddressUpdated(_walletAddress);

      return true;
   }


    
    
   function setMaxTokensPerAccount(uint256 _maxTokens) external onlyOwner returns(bool) {

      maxTokensPerAccount = _maxTokens;

      MaxTokensPerAccountUpdated(_maxTokens);

      return true;
   }


    
    
   function setTokensPerKEther(uint256 _tokensPerKEther) external onlyOwner returns(bool) {
      require(_tokensPerKEther > 0);

      tokensPerKEther = _tokensPerKEther;

      TokensPerKEtherUpdated(_tokensPerKEther);

      return true;
   }


    
    
    
   function setBonus(uint256 _bonus) external onlyOwner returns(bool) {
      require(_bonus <= 10000);

      bonus = _bonus;

      BonusUpdated(_bonus);

      return true;
   }


    
    
    
   function setSaleWindow(uint256 _startTime, uint256 _endTime) external onlyOwner returns(bool) {
      require(_startTime > 0);
      require(_endTime > _startTime);

      startTime = _startTime;
      endTime   = _endTime;

      SaleWindowUpdated(_startTime, _endTime);

      return true;
   }


    
   function suspend() external onlyOwner returns(bool) {
      if (suspended == true) {
          return false;
      }

      suspended = true;

      SaleSuspended();

      return true;
   }


    
   function resume() external onlyOwner returns(bool) {
      if (suspended == false) {
          return false;
      }

      suspended = false;

      SaleResumed();

      return true;
   }


    
    
    

    
   function () payable public {
      buyTokens(msg.sender);
   }


    
   function buyTokens(address _beneficiary) public payable returns (uint256) {
      return buyTokensInternal(_beneficiary, bonus);
   }


   function buyTokensInternal(address _beneficiary, uint256 _bonus) internal returns (uint256) {
      require(!finalized);
      require(!suspended);
      require(currentTime() >= startTime);
      require(currentTime() <= endTime);
      require(msg.value >= contributionMin);
      require(_beneficiary != address(0));
      require(_beneficiary != address(this));
      require(_beneficiary != address(token));

       
       
      require(msg.sender != address(walletAddress));

       
      uint256 saleBalance = token.balanceOf(address(this));
      require(saleBalance > 0);

       
      uint256 tokens = msg.value.mul(tokensPerKEther).mul(_bonus.add(10000)).div(tokenConversionFactor);
      require(tokens > 0);

      uint256 cost = msg.value;
      uint256 refund = 0;

       
       
      uint256 maxTokens = saleBalance;

      if (maxTokensPerAccount > 0) {
          
          
         uint256 userBalance = getUserTokenBalance(_beneficiary);
         require(userBalance < maxTokensPerAccount);

         uint256 quotaBalance = maxTokensPerAccount.sub(userBalance);

         if (quotaBalance < saleBalance) {
            maxTokens = quotaBalance;
         }
      }

      require(maxTokens > 0);

      if (tokens > maxTokens) {
          
          
         tokens = maxTokens;

          
         cost = tokens.mul(tokenConversionFactor).div(tokensPerKEther.mul(_bonus.add(10000)));

         if (msg.value > cost) {
             
             
            refund = msg.value.sub(cost);
         }
      }

       
      uint256 contribution = msg.value.sub(refund);
      walletAddress.transfer(contribution);

       
      totalTokensSold     = totalTokensSold.add(tokens);
      totalEtherCollected = totalEtherCollected.add(contribution);

       
      require(token.transfer(_beneficiary, tokens));

       
      if (refund > 0) {
         msg.sender.transfer(refund);
      }

      TokensPurchased(_beneficiary, cost, tokens);

      return tokens;
   }


    
    
   function getUserTokenBalance(address _beneficiary) internal view returns (uint256) {
      return token.balanceOf(_beneficiary);
   }


    
   function reclaimTokens() external onlyOwner returns (bool) {
      uint256 tokens = token.balanceOf(address(this));

      if (tokens == 0) {
         return false;
      }

      address tokenOwner = token.owner();
      require(tokenOwner != address(0));

      require(token.transfer(tokenOwner, tokens));

      TokensReclaimed(tokens);

      return true;
   }
}


 
 
 
 
 
 
 
 


contract BluzelleTokenConfig {

    string  public constant TOKEN_SYMBOL      = "BLZ";
    string  public constant TOKEN_NAME        = "Bluzelle Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 500000000 * DECIMALSFACTOR;
}


 
 
 
 
 
 
 
 



contract BluzelleTokenSaleConfig is BluzelleTokenConfig {

     
     
     
    uint256 public constant INITIAL_STARTTIME      = 1516240800;  
    uint256 public constant INITIAL_ENDTIME        = 1517536800;  
    uint256 public constant INITIAL_STAGE          = 1;


     
     
     

     
    uint256 public constant CONTRIBUTION_MIN      = 0.1 ether;

     
    uint256 public constant TOKENS_PER_KETHER     = 1700000;

     
    uint256 public constant BONUS                 = 0;

     
    uint256 public constant TOKENS_ACCOUNT_MAX    = 17000 * DECIMALSFACTOR;
}


 
 
 
 
 
 
 
 



 
 
 
 
 
 
 
 
 
 
 
 
contract BluzelleToken is FinalizableToken, BluzelleTokenConfig {


   event TokensReclaimed(uint256 _amount);


   function BluzelleToken() public
      FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY)
   {
   }


    
   function reclaimTokens() public onlyOwner returns (bool) {

      address account = address(this);
      uint256 amount  = balanceOf(account);

      if (amount == 0) {
         return false;
      }

      balances[account] = balances[account].sub(amount);
      balances[owner] = balances[owner].add(amount);

      Transfer(account, owner, amount);

      TokensReclaimed(amount);

      return true;
   }
}


 
 
 
 
 
 
 
 



contract BluzelleTokenSale is FlexibleTokenSale, BluzelleTokenSaleConfig {

    
    
    

    
    
    
   uint256 public currentStage;

    
    
   mapping(uint256 => uint256) public stageBonus;

    
   mapping(address => uint256) public accountTokensPurchased;

    
    
    
    
   mapping(address => uint256) public whitelist;


    
    
    
   event CurrentStageUpdated(uint256 _newStage);
   event StageBonusUpdated(uint256 _stage, uint256 _bonus);
   event WhitelistedStatusUpdated(address indexed _address, uint256 _stage);


   function BluzelleTokenSale(address wallet) public
      FlexibleTokenSale(INITIAL_STARTTIME, INITIAL_ENDTIME, wallet)
   {
      currentStage        = INITIAL_STAGE;
      tokensPerKEther     = TOKENS_PER_KETHER;
      bonus               = BONUS;
      maxTokensPerAccount = TOKENS_ACCOUNT_MAX;
      contributionMin     = CONTRIBUTION_MIN;
   }


    
    
   function setCurrentStage(uint256 _stage) public onlyOwner returns(bool) {
      require(_stage > 0);

      if (currentStage == _stage) {
         return false;
      }

      currentStage = _stage;

      CurrentStageUpdated(_stage);

      return true;
   }


    
   function setStageBonus(uint256 _stage, uint256 _bonus) public onlyOwner returns(bool) {
      require(_stage > 0);
      require(_bonus <= 10000);

      if (stageBonus[_stage] == _bonus) {
          
         return false;
      }

      stageBonus[_stage] = _bonus;

      StageBonusUpdated(_stage, _bonus);

      return true;
   }


    
   function setWhitelistedStatus(address _address, uint256 _stage) public onlyOwnerOrOps returns (bool) {
      return setWhitelistedStatusInternal(_address, _stage);
   }


   function setWhitelistedStatusInternal(address _address, uint256 _stage) private returns (bool) {
      require(_address != address(0));
      require(_address != address(this));
      require(_address != walletAddress);

      whitelist[_address] = _stage;

      WhitelistedStatusUpdated(_address, _stage);

      return true;
   }


    
    
    
   function setWhitelistedBatch(address[] _addresses, uint256 _stage) public onlyOwnerOrOps returns (bool) {
      require(_addresses.length > 0);

      for (uint256 i = 0; i < _addresses.length; i++) {
         require(setWhitelistedStatusInternal(_addresses[i], _stage));
      }

      return true;
   }


    
    
    
   function buyTokensInternal(address _beneficiary, uint256 _bonus) internal returns (uint256) {
      require(whitelist[msg.sender] > 0);
      require(whitelist[_beneficiary] > 0);
      require(currentStage >= whitelist[msg.sender]);

      uint256 _beneficiaryStage = whitelist[_beneficiary];
      require(currentStage >= _beneficiaryStage);

      uint256 applicableBonus = stageBonus[_beneficiaryStage];
      if (applicableBonus == 0) {
         applicableBonus = _bonus;
      }

      uint256 tokensPurchased = super.buyTokensInternal(_beneficiary, applicableBonus);

      accountTokensPurchased[_beneficiary] = accountTokensPurchased[_beneficiary].add(tokensPurchased);

      return tokensPurchased;
   }


    
    
    
    
   function getUserTokenBalance(address _beneficiary) internal view returns (uint256) {
      return accountTokensPurchased[_beneficiary];
   }
}