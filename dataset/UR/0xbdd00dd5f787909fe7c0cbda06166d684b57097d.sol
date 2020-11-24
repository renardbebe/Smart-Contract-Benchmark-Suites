 

pragma solidity ^0.4.13;

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

contract SealTokenSale is Pausable {
  using SafeMath for uint256;

   
  struct Supporter {
    bool hasKYC;
    address referrerAddress;
  }

   
  struct ExternalSupporter {
    uint256 reservedAmount;
  }

   
  enum TokenSaleState {Private, Pre, Main, Finished}

   
  mapping(address => Supporter) public supportersMap;  
  mapping(address => ExternalSupporter) public externalSupportersMap;  
  SealToken public token;  
  address public vaultWallet;  
  address public airdropWallet;  
  address public kycWallet;  
  uint256 public tokensSold;  
  uint256 public tokensReserved;  
  uint256 public maxTxGasPrice;  
  TokenSaleState public currentState;  

  uint256 public constant ONE_MILLION = 10 ** 6;  
  uint256 public constant PRE_SALE_TOKEN_CAP = 384 * ONE_MILLION * 10 ** 18;  
  uint256 public constant TOKEN_SALE_CAP = 492 * ONE_MILLION * 10 ** 18;  
  uint256 public constant TOTAL_TOKENS_SUPPLY = 1200 * ONE_MILLION * 10 ** 18;  
  uint256 public constant MIN_ETHER = 0.1 ether;  

   
  uint256 public constant PRE_SALE_MIN_ETHER = 1 ether;  
  uint256 public constant PRE_SALE_15_BONUS_MIN = 60 ether;  
  uint256 public constant PRE_SALE_20_BONUS_MIN = 300 ether;  
  uint256 public constant PRE_SALE_30_BONUS_MIN = 1200 ether;  

   
  uint256 public tokenBaseRate;  

  uint256 public referrerBonusRate;  
  uint256 public referredBonusRate;  

   
  modifier onlyOwnerOrKYCWallet() {
    require(msg.sender == owner || msg.sender == kycWallet);
    _;
  }

   
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

   
  event TokenReservation(address indexed wallet, uint256 amount);

   
  event TokenReservationConfirmation(address indexed wallet, uint256 amount);

   
  event TokenReservationCancellation(address indexed wallet, uint256 amount);

   
  event KYC(address indexed user, bool isApproved);

   
  event ReferrerSet(address indexed user, address indexed referrerAddress);

   
  event ReferralBonusIncomplete(address indexed userAddress, uint256 missingAmount);

   
  event ReferralBonusMinted(address indexed userAddress, uint256 amount);

   
  function SealTokenSale(
    address _vaultWallet,
    address _airdropWallet,
    address _kycWallet,
    uint256 _tokenBaseRate,
    uint256 _referrerBonusRate,
    uint256 _referredBonusRate,
    uint256 _maxTxGasPrice
  )
  public
  {
    require(_vaultWallet != address(0));
    require(_airdropWallet != address(0));
    require(_kycWallet != address(0));
    require(_tokenBaseRate > 0);
    require(_referrerBonusRate > 0);
    require(_referredBonusRate > 0);
    require(_maxTxGasPrice > 0);

    vaultWallet = _vaultWallet;
    airdropWallet = _airdropWallet;
    kycWallet = _kycWallet;
    tokenBaseRate = _tokenBaseRate;
    referrerBonusRate = _referrerBonusRate;
    referredBonusRate = _referredBonusRate;
    maxTxGasPrice = _maxTxGasPrice;

    tokensSold = 0;
    tokensReserved = 0;

    token = new SealToken();

     
    currentState = TokenSaleState.Private;
  }

   
  function() public payable {
    buyTokens();
  }

   
  function buyTokens() public payable whenNotPaused {
     
     
     
    require(tx.gasprice <= maxTxGasPrice);

     
    require(isPublicTokenSaleRunning());

     
    require(userHasKYC(msg.sender));

     
    require(aboveMinimumPurchase());

    address sender = msg.sender;
    uint256 weiAmountSent = msg.value;

     
    uint256 bonusMultiplier = getBonusMultiplier(weiAmountSent);
    uint256 newTokens = weiAmountSent.mul(tokenBaseRate).mul(bonusMultiplier).div(100);

     
    checkTotalsAndMintTokens(sender, newTokens, false);

     
    TokenPurchase(sender, weiAmountSent, newTokens);

     
    vaultWallet.transfer(msg.value);
  }

   
  function reserveTokens(address _wallet, uint256 _amount) public onlyOwner {
     
    require(_amount > 0);
     
    require(_wallet != address(0));

     
    require(isPrivateSaleRunning() || isPreSaleRunning());

     
    uint256 totalTokensReserved = tokensReserved.add(_amount);
    require(tokensSold + totalTokensReserved <= PRE_SALE_TOKEN_CAP);

     
    tokensReserved = totalTokensReserved;

     
    externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.add(_amount);

     
    TokenReservation(_wallet, _amount);
  }

   
  function confirmReservedTokens(address _wallet, uint256 _amount) public onlyOwner {
     
    require(_amount > 0);
     
    require(_wallet != address(0));

     
    require(!hasEnded());

     
    require(_amount <= externalSupportersMap[_wallet].reservedAmount);

     
    checkTotalsAndMintTokens(_wallet, _amount, true);

     
    TokenReservationConfirmation(_wallet, _amount);
  }

   
  function cancelReservedTokens(address _wallet, uint256 _amount) public onlyOwner {
     
    require(_amount > 0);
     
    require(_wallet != address(0));

     
    require(!hasEnded());

     
    require(_amount <= externalSupportersMap[_wallet].reservedAmount);

     
    tokensReserved = tokensReserved.sub(_amount);

     
    externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.sub(_amount);

     
    TokenReservationCancellation(_wallet, _amount);
  }

   
  function checkTotalsAndMintTokens(address _wallet, uint256 _amount, bool _fromReservation) private {
     
    uint256 totalTokensSold = tokensSold.add(_amount);

    uint256 totalTokensReserved = tokensReserved;
    if (_fromReservation) {
      totalTokensReserved = totalTokensReserved.sub(_amount);
    }

    if (isMainSaleRunning()) {
      require(totalTokensSold + totalTokensReserved <= TOKEN_SALE_CAP);
    } else {
      require(totalTokensSold + totalTokensReserved <= PRE_SALE_TOKEN_CAP);
    }

     
    tokensSold = totalTokensSold;

    if (_fromReservation) {
      externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.sub(_amount);
      tokensReserved = totalTokensReserved;
    }

     
    token.mint(_wallet, _amount);

    address userReferrer = getUserReferrer(_wallet);

    if (userReferrer != address(0)) {
       
      mintReferralShare(_amount, userReferrer, referrerBonusRate);

       
      mintReferralShare(_amount, _wallet, referredBonusRate);
    }
  }

   
  function mintReferralShare(uint256 _amount, address _userAddress, uint256 _bonusRate) private {
     
    uint256 currentCap;

    if (isMainSaleRunning()) {
      currentCap = TOKEN_SALE_CAP;
    } else {
      currentCap = PRE_SALE_TOKEN_CAP;
    }

    uint256 maxTokensAvailable = currentCap - tokensSold - tokensReserved;

     
    uint256 fullShare = _amount.mul(_bonusRate).div(10000);
    if (fullShare <= maxTokensAvailable) {
       
      token.mint(_userAddress, fullShare);

       
      tokensSold = tokensSold.add(fullShare);

       
      ReferralBonusMinted(_userAddress, fullShare);
    }
    else {
       
      token.mint(_userAddress, maxTokensAvailable);

       
      tokensSold = tokensSold.add(maxTokensAvailable);

       

      ReferralBonusMinted(_userAddress, maxTokensAvailable);
      ReferralBonusIncomplete(_userAddress, fullShare - maxTokensAvailable);
    }
  }

   
  function startPreSale() public onlyOwner {
     
    require(currentState == TokenSaleState.Private);

     
    currentState = TokenSaleState.Pre;
  }

   
  function goBackToPrivateSale() public onlyOwner {
     
    require(currentState == TokenSaleState.Pre);

     
    currentState = TokenSaleState.Private;
  }

   
  function startMainSale() public onlyOwner {
     
    require(currentState == TokenSaleState.Pre);

     
    currentState = TokenSaleState.Main;
  }

   
  function goBackToPreSale() public onlyOwner {
     
    require(currentState == TokenSaleState.Main);

     
    currentState = TokenSaleState.Pre;
  }

   
  function finishContract() public onlyOwner {
     
    require(currentState == TokenSaleState.Main);

     
    require(tokensReserved == 0);

     
    currentState = TokenSaleState.Finished;

     
    uint256 unsoldTokens = TOKEN_SALE_CAP.sub(tokensSold);
    token.mint(airdropWallet, unsoldTokens);

     
    uint256 notForSaleTokens = TOTAL_TOKENS_SUPPLY.sub(TOKEN_SALE_CAP);
    token.mint(vaultWallet, notForSaleTokens);

     
    token.finishMinting();

     
     
    token.transferOwnership(owner);
  }

   
  function updateMaxTxGasPrice(uint256 _newMaxTxGasPrice) public onlyOwner {
    require(_newMaxTxGasPrice > 0);
    maxTxGasPrice = _newMaxTxGasPrice;
  }

   
  function updateTokenBaseRate(uint256 _tokenBaseRate) public onlyOwner {
    require(_tokenBaseRate > 0);
    tokenBaseRate = _tokenBaseRate;
  }

   
  function updateVaultWallet(address _vaultWallet) public onlyOwner {
    require(_vaultWallet != address(0));
    vaultWallet = _vaultWallet;
  }

   
  function updateKYCWallet(address _kycWallet) public onlyOwner {
    require(_kycWallet != address(0));
    kycWallet = _kycWallet;
  }

   
  function approveUserKYC(address _user) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = true;
    KYC(_user, true);
  }

   
  function disapproveUserKYC(address _user) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = false;
    KYC(_user, false);
  }

   
  function approveUserKYCAndSetReferrer(address _user, address _referrerAddress) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = true;
    sup.referrerAddress = _referrerAddress;

     
    KYC(_user, true);
    ReferrerSet(_user, _referrerAddress);
  }

   
  function isPrivateSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Private);
  }

   
  function isPublicTokenSaleRunning() public view returns (bool) {
    return (isPreSaleRunning() || isMainSaleRunning());
  }

   
  function isPreSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Pre);
  }

   
  function isMainSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Main);
  }

   
  function hasEnded() public view returns (bool) {
    return (currentState == TokenSaleState.Finished);
  }

   
  function userHasKYC(address _user) public view returns (bool) {
    return supportersMap[_user].hasKYC;
  }

   
  function getUserReferrer(address _user) public view returns (address) {
    return supportersMap[_user].referrerAddress;
  }

   
  function getReservedAmount(address _user) public view returns (uint256) {
    return externalSupportersMap[_user].reservedAmount;
  }

   
  function getBonusMultiplier(uint256 _weiAmount) internal view returns (uint256) {
    if (isMainSaleRunning()) {
      return 100;
    }
    else if (isPreSaleRunning()) {
      if (_weiAmount >= PRE_SALE_30_BONUS_MIN) {
         
        return 130;
      }
      else if (_weiAmount >= PRE_SALE_20_BONUS_MIN) {
         
        return 120;
      }
      else if (_weiAmount >= PRE_SALE_15_BONUS_MIN) {
         
        return 115;
      }
      else if (_weiAmount >= PRE_SALE_MIN_ETHER) {
         
        return 110;
      }
      else {
         
        revert();
      }
    }
  }

   
  function aboveMinimumPurchase() internal view returns (bool) {
    if (isMainSaleRunning()) {
      return msg.value >= MIN_ETHER;
    }
    else if (isPreSaleRunning()) {
      return msg.value >= PRE_SALE_MIN_ETHER;
    } else {
      return false;
    }
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract SealToken is MintableToken {
     
    string public constant name = "SealToken";
    string public constant symbol = "SEAL";
    uint8 public constant decimals = 18;

     
    modifier onlyWhenTransferEnabled() {
        require(mintingFinished);
        _;
    }

    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function SealToken() public {
    }

    function transferFrom(address _from, address _to, uint256 _value) public        
        onlyWhenTransferEnabled
        validDestination(_to)         
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval (address _spender, uint _addedValue) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)         
        returns (bool) {
        return super.transfer(_to, _value);
    }
}