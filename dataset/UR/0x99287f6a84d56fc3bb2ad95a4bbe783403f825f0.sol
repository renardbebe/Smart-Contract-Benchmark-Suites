 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


 
contract DadiPreSale is Ownable {
    using SafeMath for uint256;

    StandardToken public token;                          
    address public owner;
    address[] public preSaleWallets;

    struct WhitelistUser {
      uint256 pledged;
      uint index;
    }

    struct Investor {
      uint256 tokens;
      uint256 contribution;
      uint index;
    }

    uint256 public tokenSupply;
    uint256 public tokensPurchased = 0;
    uint256 public individualCap = 10000 * 1000;         
    uint256 public preSaleTokenPrice = 400;              
    uint256 public ethRate;                              
 
    mapping(address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;
    mapping(address => Investor) private investors;
    address[] private investorIndex;

     
    enum SaleState { Preparing, PreSale, PreSaleFinalized, Success, TokenDistribution, Closed }
    SaleState public state = SaleState.Preparing;

     
    enum PurchasePeriod { Preparing, Whitelist, WhitelistApplicant, Public }
    PurchasePeriod public purchasePeriod = PurchasePeriod.Preparing;

     
    event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);
    event LogTokenDistribution(address recipient, uint256 tokens);
    event LogRedistributeTokens(address recipient, SaleState _state, uint256 tokens);
    event LogFundTransfer(address wallet, uint256 value);
    event LogRefund(address wallet, uint256 value);
    event LogStateChange(SaleState _state);
    event LogNewWhitelistUser(address indexed userAddress, uint index, uint256 value);

     
    modifier nonZero() {
        require(msg.value != 0);
        _;
    }

     
    function DadiPreSale (StandardToken _token,uint256 _tokenSupply) public {
        require(_token != address(0));
        require(_tokenSupply != 0);

        owner = msg.sender;

        token = StandardToken(_token);
        tokenSupply = _tokenSupply * (uint256(10) ** 18);
    }

     
    function () public nonZero payable {
        require(state == SaleState.PreSale);
        buyTokens(msg.sender, msg.value);
    }

     
    function addPreSaleWallet (address _wallet) public onlyOwner returns (bool) {
        require(_wallet != address(0));
        preSaleWallets.push(_wallet);
        return true;
    }

     
    function addWhitelistUsers(address[] userAddresses, uint256[] pledges) public onlyOwner {
        for (uint i = 0; i < userAddresses.length; i++) {
            addWhitelistUser(userAddresses[i], pledges[i]);
        }
    }

     
    function addWhitelistUser(address userAddress, uint256 pledged) public onlyOwner {
        if (!isWhitelisted(userAddress)) {
            whitelisted[userAddress].pledged = pledged * 1000;
            whitelisted[userAddress].index = whitelistedIndex.push(userAddress) - 1;
          
            LogNewWhitelistUser(userAddress, whitelisted[userAddress].index, pledged);
        }
    }

     
    function calculateTokens (uint256 _amount) public constant returns (uint256 tokens) {
        tokens = _amount * ethRate / preSaleTokenPrice;
        return tokens;
    }

     
    function setState (uint256 _state) public onlyOwner {
        state = SaleState(uint(_state));
        LogStateChange(state);
    }

     
    function setPurchasePeriod (uint256 phase) public onlyOwner {
        purchasePeriod = PurchasePeriod(uint(phase));
    }

     
    function startPreSale (uint256 rate) public onlyOwner {
        state = SaleState.PreSale;
        purchasePeriod = PurchasePeriod.Whitelist;
        updateEthRate(rate);
        LogStateChange(state);
    }

     
    function updateEthRate (uint256 rate) public onlyOwner returns (bool) {
        require(rate >= 100000);
        
        ethRate = rate;
        return true;
    }

     
    function offlineTransaction (address _recipient, uint256 _tokens) public onlyOwner returns (bool) {
        require(_tokens > 0);

         
        uint256 tokens = _tokens * (uint256(10) ** uint8(18));

         
        if (tokens >= getTokensAvailable()) {
            revert();
        }

        addToInvestor(_recipient, 0, tokens);

         
        updateSaleParameters(tokens);

        LogTokenPurchase(msg.sender, _recipient, 0, tokens);

        return true;
    }

     
    function finalizeSale () public onlyOwner {
        state = SaleState.Success;
        LogStateChange(state);

         
        if (this.balance > 0) {
            forwardFunds(this.balance);
        }
    }

     
    function closeSale (address recipient) public onlyOwner {
        state = SaleState.Closed;
        LogStateChange(state);

         
        uint256 remaining = getTokensAvailable();
        updateSaleParameters(remaining);

        if (remaining > 0) {
            token.transfer(recipient, remaining);
            LogRedistributeTokens(recipient, state, remaining);
        }
    }

     
    function setTokenDistribution () public onlyOwner {
        state = SaleState.TokenDistribution;
        LogStateChange(state);
    }

     
    function distributeTokens (address _address) public onlyOwner returns (bool) {
        require(state == SaleState.TokenDistribution);
        
         
        uint256 tokens = investors[_address].tokens;
        require(tokens > 0);

        investors[_address].tokens = 0;
        investors[_address].contribution = 0;

        token.transfer(_address, tokens);
      
        LogTokenDistribution(_address, tokens);
        return true;
    }

     
    function distributeToAlternateAddress (address _purchaseAddress, address _tokenAddress) public onlyOwner returns (bool) {
        require(state == SaleState.TokenDistribution);
        
         
        uint256 tokens = investors[_purchaseAddress].tokens;
        require(tokens > 0);

        investors[_purchaseAddress].tokens = 0;

        token.transfer(_tokenAddress, tokens);
      
        LogTokenDistribution(_tokenAddress, tokens);
        return true;
    }

     
    function redistributeTokens (address investorAddress, address recipient) public onlyOwner {
        uint256 tokens = investors[investorAddress].tokens;
        require(tokens > 0);
        
         
        investors[investorAddress].tokens = 0;
        token.transfer(recipient, tokens);

        LogRedistributeTokens(recipient, state, tokens);
    }

     
    function getTokensAvailable () public constant returns (uint256) {
        return tokenSupply - tokensPurchased;
    }

     
    function getTokensPurchased () public constant returns (uint256) {
        return tokensPurchased;
    }

     
    function getBalance () public constant returns (uint256) {
        return this.balance;
    }

     
    function ethToUsd (uint256 _amount) public constant returns (uint256) {
        return (_amount * ethRate) / (uint256(10) ** 18);
    }

     
    function isSuccessful () public constant returns (bool) {
        return state == SaleState.Success;
    }

     
    function getWhitelistUser (address userAddress) public constant returns (uint256 pledged, uint index) {
        require(isWhitelisted(userAddress));
        return(whitelisted[userAddress].pledged, whitelisted[userAddress].index);
    }

     
    function getInvestorCount () public constant returns (uint count) {
        return investorIndex.length;
    }


     
    function getInvestor (address _address) public constant returns (uint256 contribution, uint256 tokens, uint index) {
        require(isInvested(_address));
        return(investors[_address].contribution, investors[_address].tokens, investors[_address].index);
    }

     
    function isWhitelisted (address userAddress) internal constant returns (bool isIndeed) {
        if (whitelistedIndex.length == 0) return false;
        return (whitelistedIndex[whitelisted[userAddress].index] == userAddress);
    }

     
    function isInvested (address _address) internal constant returns (bool isIndeed) {
        if (investorIndex.length == 0) return false;
        return (investorIndex[investors[_address].index] == _address);
    }

     
    function addToInvestor(address _address, uint256 _value, uint256 _tokens) internal {
         
        if (!isInvested(_address)) {
            investors[_address].index = investorIndex.push(_address) - 1;
        }
      
        investors[_address].tokens = investors[_address].tokens.add(_tokens);
        investors[_address].contribution = investors[_address].contribution.add(_value);
    }

     
    function forwardFunds (uint256 _value) internal {
        uint accountNumber;
        address account;

         
        if (preSaleWallets.length > 0) {
            accountNumber = getRandom(preSaleWallets.length) - 1;
            account = preSaleWallets[accountNumber];
            account.transfer(_value);
            LogFundTransfer(account, _value);
        }
    }

     
    function buyTokens (address _address, uint256 _value) internal returns (bool) {
        require(isBelowCap(_value));

        if (isWhitelistPeriod()) {
            require(isWhitelisted(_address));
        }

        require(isValidContribution(_address, _value));

        uint256 boughtTokens = calculateTokens(_value);
        require(boughtTokens != 0);

         
         
        if (boughtTokens >= getTokensAvailable()) {
            revert();
        }

         
        addToInvestor(_address, _value, boughtTokens);

        LogTokenPurchase(msg.sender, _address, _value, boughtTokens);

        forwardFunds(_value);

        updateSaleParameters(boughtTokens);

        return true;
    }

     
    function isValidContribution (address _address, uint256 _amount) internal constant returns (bool valid) {
        if (isWhitelistPeriod() && isWhitelisted(_address)) {
            return ethToUsd(_amount + investors[_address].contribution) <= whitelisted[_address].pledged;
        }

        return isBelowCap(_amount + investors[_address].contribution); 
    }

     
    function isBelowCap (uint256 _amount) internal constant returns (bool) {
        return ethToUsd(_amount) < individualCap;
    }

     
    function getRandom(uint max) internal constant returns (uint randomNumber) {
        return (uint(keccak256(block.blockhash(block.number - 1))) % max) + 1;
    }

     
    function updateSaleParameters (uint256 _tokens) internal {
        tokensPurchased = tokensPurchased.add(_tokens);
    }

     
    function isWhitelistPeriod () private constant returns (bool) {
        return purchasePeriod == PurchasePeriod.Whitelist;
    }

     
    function isWhitelistApplicantPeriod () private constant returns (bool) {
        return purchasePeriod == PurchasePeriod.WhitelistApplicant;
    }

     
    function isPublicPeriod () private constant returns (bool) {
        return purchasePeriod == PurchasePeriod.Public;
    }
}