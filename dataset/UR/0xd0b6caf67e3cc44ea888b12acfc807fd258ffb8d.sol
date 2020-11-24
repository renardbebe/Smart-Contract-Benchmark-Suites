 

pragma solidity ^0.4.23;

 
 
 
 
 
 
 

 
 
 
 
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
      if (a == 0) {
         return 0;
      }

      uint256 r = a * b;

      require(r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

 
 
 
 
 
 
 


 
contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);


   constructor() public
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

      emit OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      emit OwnershipTransferCompleted(owner);

      return true;
   }
}

 
 
 
 
 
 
 


contract Finalizable is Owned() {

   bool public finalized;

   event Finalized();


   constructor() public
   {
      finalized = false;
   }


   function finalize() public onlyOwner returns (bool) {
      require(!finalized);

      finalized = true;

      emit Finalized();

      return true;
   }
}

 
 
 
 
 
 
 



 
 
 
contract OpsManaged is Owned() {

   address public opsAddress;

   event OpsAddressUpdated(address indexed _newAddress);


   constructor() public
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

      emit OpsAddressUpdated(opsAddress);

      return true;
   }
}

 
 
 
 
 
 
 


contract ERC20Token is ERC20Interface {

   using Math for uint256;

   string  private tokenName;
   string  private tokenSymbol;
   uint8   private tokenDecimals;
   uint256 internal tokenTotalSupply;

   mapping(address => uint256) internal balances;
   mapping(address => mapping (address => uint256)) allowed;


   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
      tokenName = _name;
      tokenSymbol = _symbol;
      tokenDecimals = _decimals;
      tokenTotalSupply = _totalSupply;

       
      balances[_initialTokenHolder] = _totalSupply;

       
      emit Transfer(0x0, _initialTokenHolder, _totalSupply);
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

      emit Transfer(msg.sender, _to, _value);

      return true;
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(_from, _to, _value);

      return true;
   }


   function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);

      return true;
   }
}

 
 
 
 
 
 
 


 
 
 
 
 
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

   using Math for uint256;


    
   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
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


   constructor(uint256 _startTime, uint256 _endTime, address _walletAddress) public
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

      emit Initialized();

      return true;
   }


    
    
    

    
    
   function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
      require(_walletAddress != address(0));
      require(_walletAddress != address(this));
      require(_walletAddress != address(token));
      require(isOwnerOrOps(_walletAddress) == false);

      walletAddress = _walletAddress;

      emit WalletAddressUpdated(_walletAddress);

      return true;
   }


    
    
   function setMaxTokensPerAccount(uint256 _maxTokens) external onlyOwner returns(bool) {

      maxTokensPerAccount = _maxTokens;

      emit MaxTokensPerAccountUpdated(_maxTokens);

      return true;
   }


    
    
   function setTokensPerKEther(uint256 _tokensPerKEther) external onlyOwner returns(bool) {
      require(_tokensPerKEther > 0);

      tokensPerKEther = _tokensPerKEther;

      emit TokensPerKEtherUpdated(_tokensPerKEther);

      return true;
   }


    
    
    
   function setBonus(uint256 _bonus) external onlyOwner returns(bool) {
      require(_bonus <= 10000);

      bonus = _bonus;

      emit BonusUpdated(_bonus);

      return true;
   }


    
    
    
   function setSaleWindow(uint256 _startTime, uint256 _endTime) external onlyOwner returns(bool) {
      require(_startTime > 0);
      require(_endTime > _startTime);

      startTime = _startTime;
      endTime   = _endTime;

      emit SaleWindowUpdated(_startTime, _endTime);

      return true;
   }


    
   function suspend() external onlyOwner returns(bool) {
      if (suspended == true) {
          return false;
      }

      suspended = true;

      emit SaleSuspended();

      return true;
   }


    
   function resume() external onlyOwner returns(bool) {
      if (suspended == false) {
          return false;
      }

      suspended = false;

      emit SaleResumed();

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

      emit TokensPurchased(_beneficiary, cost, tokens);

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

      emit TokensReclaimed(tokens);

      return true;
   }
}


 
 
 
 
 
 


contract CaspianTokenConfig {

    string  public constant TOKEN_SYMBOL      = "CSP";
    string  public constant TOKEN_NAME        = "Caspian Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}



 
 
 
 
 
 


contract CaspianTokenSaleConfig is CaspianTokenConfig {

     
     
     
    uint256 public constant INITIAL_STARTTIME    = 1538553600;  
    uint256 public constant INITIAL_ENDTIME      = 1538726400;  


     
     
     

     
    uint256 public constant CONTRIBUTION_MIN     = 0.5 ether;

     
    uint256 public constant TOKENS_PER_KETHER    = 4000000;

     
    uint256 public constant BONUS                = 0;

     
    uint256 public constant TOKENS_ACCOUNT_MAX   = 400000 * DECIMALSFACTOR;  
}


 
 
 
 
 
 
 
 
 


contract CaspianTokenSale is FlexibleTokenSale, CaspianTokenSaleConfig {

    
    
    
   uint8 public currentPhase;

   mapping(address => uint8) public whitelist;


    
    
    
   event WhitelistUpdated(address indexed _account, uint8 _phase);


   constructor(address wallet) public
      FlexibleTokenSale(INITIAL_STARTTIME, INITIAL_ENDTIME, wallet)
   {
      tokensPerKEther     = TOKENS_PER_KETHER;
      bonus               = BONUS;
      maxTokensPerAccount = TOKENS_ACCOUNT_MAX;
      contributionMin     = CONTRIBUTION_MIN;
      currentPhase        = 1;
   }


    
   function updateWhitelist(address _address, uint8 _phase) external onlyOwnerOrOps returns (bool) {
      return updateWhitelistInternal(_address, _phase);
   }


   function updateWhitelistInternal(address _address, uint8 _phase) internal returns (bool) {
      require(_address != address(0));
      require(_address != address(this));
      require(_address != walletAddress);
      require(_phase <= 1);

      whitelist[_address] = _phase;

      emit WhitelistUpdated(_address, _phase);

      return true;
   }


    
   function updateWhitelistBatch(address[] _addresses, uint8 _phase) external onlyOwnerOrOps returns (bool) {
      require(_addresses.length > 0);

      for (uint256 i = 0; i < _addresses.length; i++) {
         require(updateWhitelistInternal(_addresses[i], _phase));
      }

      return true;
   }


    
    
    
   function buyTokensInternal(address _beneficiary, uint256 _bonus) internal returns (uint256) {
      require(whitelist[msg.sender] >= currentPhase);
      require(whitelist[_beneficiary] >= currentPhase);

      return super.buyTokensInternal(_beneficiary, _bonus);
   }
}