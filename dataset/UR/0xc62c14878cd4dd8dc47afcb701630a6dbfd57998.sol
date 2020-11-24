 

pragma solidity 0.4.25;

contract ERC20Interface {

  function totalSupply() public constant returns(uint);

  function balanceOf(address tokenOwner) public constant returns(uint balance);

  function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

  function transfer(address to, uint tokens) public returns(bool success);

  function approve(address spender, uint tokens) public returns(bool success);

  function transferFrom(address from, address to, uint tokens) public returns(bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract _0xBitconnect {
  using SafeMath
  for uint;

   

  modifier onlyHolders() {
    require(myFrontEndTokens() > 0);
    _;
  }

  modifier dividendHolder() {
    require(myDividends(true) > 0);
    _;
  }

  modifier onlyAdministrator() {
    address _customerAddress = msg.sender;
    require(administrators[_customerAddress]);
    _;
  }

   

  event onTokenPurchase(
    address indexed customerAddress,
    uint incoming,
    uint8 dividendRate,
    uint tokensMinted,
    address indexed referredBy
  );

  event UserDividendRate(
    address user,
    uint divRate
  );

  event onTokenSell(
    address indexed customerAddress,
    uint tokensBurned,
    uint earned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint reinvested,
    uint tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint withdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint tokens
  );

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint tokens
  );

  event Allocation(
    uint toBankRoll,
    uint toReferrer,
    uint toTokenHolders,
    uint toDivCardHolders,
    uint forTokens
  );

  event Referral(
    address referrer,
    uint amountReceived
  );

   

  uint8 constant public decimals = 18;

  uint constant internal magnitude = 2 ** 64;

  uint constant internal MULTIPLIER = 1140;

  uint constant internal MIN_TOK_BUYIN = 0.0001 ether;
  uint constant internal MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal MIN_TOKEN_TRANSFER = 1e10;
  uint constant internal referrer_percentage = 25;
  uint constant internal MAX_SUPPLY = 1e25;

  ERC20Interface internal _0xBTC;

  uint public stakingRequirement = 100e18;

   

  string public name = "0xBitconnect";
  string public symbol = "0xBCC";

  address internal bankrollAddress;

  _0xBitconnectDividendCards divCardContract;

   

   
  mapping(address => uint) internal frontTokenBalanceLedger_;
  mapping(address => uint) internal dividendTokenBalanceLedger_;
  mapping(address =>
    mapping(address => uint))
  public allowed;

   
  mapping(uint8 => bool) internal validDividendRates_;
  mapping(address => bool) internal userSelectedRate;
  mapping(address => uint8) internal userDividendRate;

   
  mapping(address => uint) internal referralBalance_;
  mapping(address => int256) internal payoutsTo_;

  uint public current0xbtcInvested;

  uint internal tokenSupply = 0;
  uint internal divTokenSupply = 0;

  uint internal profitPerDivToken;

  mapping(address => bool) public administrators;

  bool public regularPhase = false;

   
  constructor(address _bankrollAddress, address _divCardAddress, address _btcAddress)
  public {
    bankrollAddress = _bankrollAddress;
    divCardContract = _0xBitconnectDividendCards(_divCardAddress);
    _0xBTC = ERC20Interface(_btcAddress);

    administrators[msg.sender] = true;  

    validDividendRates_[10] = true;
    validDividendRates_[20] = true;
    validDividendRates_[30] = true;

    userSelectedRate[bankrollAddress] = true;
    userDividendRate[bankrollAddress] = 30;

   

    uint initiallyAssigned = 3*10**24;

    address heavenA = 0xA7cDc6cF8E8a4db39bc03ac675662D6E2F8F84f3;
    address heavenB = 0xbC539A28e85c587987297da7039949eA23b51723;

    userSelectedRate[heavenA] = true;
    userDividendRate[heavenA] = 30;

    userSelectedRate[heavenB] = true;
    userDividendRate[heavenB] = 30;

    tokenSupply = tokenSupply.add(initiallyAssigned);
    divTokenSupply = divTokenSupply.add(initiallyAssigned.mul(30));

    profitPerDivToken = profitPerDivToken.add((initiallyAssigned.mul(magnitude)).div(divTokenSupply));
    
    payoutsTo_[heavenA] += (int256)((profitPerDivToken * (initiallyAssigned.div(3)).mul(userDividendRate[heavenA])));
    payoutsTo_[heavenB] += (int256)((profitPerDivToken * (initiallyAssigned.div(3)).mul(userDividendRate[heavenB])));
    payoutsTo_[bankrollAddress] += (int256)((profitPerDivToken * (initiallyAssigned.div(3)).mul(userDividendRate[bankrollAddress])));


    frontTokenBalanceLedger_[heavenA] = frontTokenBalanceLedger_[heavenA].add(initiallyAssigned.div(3));
    dividendTokenBalanceLedger_[heavenA] = dividendTokenBalanceLedger_[heavenA].add((initiallyAssigned.div(3)).mul(userDividendRate[heavenA]));

    frontTokenBalanceLedger_[heavenB] = frontTokenBalanceLedger_[heavenB].add(initiallyAssigned.div(3));
    dividendTokenBalanceLedger_[heavenB] = dividendTokenBalanceLedger_[heavenB].add((initiallyAssigned.div(3)).mul(userDividendRate[heavenB]));

    frontTokenBalanceLedger_[bankrollAddress] = frontTokenBalanceLedger_[bankrollAddress].add(initiallyAssigned.div(3));
    dividendTokenBalanceLedger_[bankrollAddress] = dividendTokenBalanceLedger_[bankrollAddress].add((initiallyAssigned.div(3)).mul(userDividendRate[bankrollAddress]));


  }

   
  function buyAndSetDivPercentage(uint _0xbtcAmount, address _referredBy, uint8 _divChoice, string providedUnhashedPass)
  public
  returns(uint) {

    require(regularPhase);

     
    require(validDividendRates_[_divChoice]);

     
    userSelectedRate[msg.sender] = true;
    userDividendRate[msg.sender] = _divChoice;
    emit UserDividendRate(msg.sender, _divChoice);

     
    purchaseTokens(_0xbtcAmount, _referredBy, false);
  }

   

  function buy(uint _0xbtcAmount, address _referredBy)
  public
  returns(uint) {
    require(regularPhase);
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    purchaseTokens(_0xbtcAmount, _referredBy, false);
  }

  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target)
  public {
    bytes memory empty;
    buyAndTransfer(_0xbtcAmount, _referredBy, target, empty, 20);
  }

  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target, bytes _data)
  public {
    buyAndTransfer(_0xbtcAmount, _referredBy, target, _data, 20);
  }

   
  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target, bytes _data, uint8 divChoice)
  public {
    require(regularPhase);
    address _customerAddress = msg.sender;
    uint256 frontendBalance = frontTokenBalanceLedger_[msg.sender];
    if (userSelectedRate[_customerAddress] && divChoice == 0) {
      purchaseTokens(_0xbtcAmount, _referredBy, false);
    } else {
      buyAndSetDivPercentage(_0xbtcAmount, _referredBy, divChoice, "0x0");
    }
    uint256 difference = SafeMath.sub(frontTokenBalanceLedger_[msg.sender], frontendBalance);
    transferTo(msg.sender, target, difference, _data);
  }

   
  function () public {
    revert();
  }

  function reinvest()
  dividendHolder()
  public {
    require(regularPhase);
    uint _dividends = myDividends(false);

     
    address _customerAddress = msg.sender;
    payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    uint _tokens = purchaseTokens(_dividends.div(1e10), address(0), true);  

     
    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

  function exit()
  public {
    require(regularPhase);
     
    address _customerAddress = msg.sender;
    uint _tokens = frontTokenBalanceLedger_[_customerAddress];

    if (_tokens > 0) sell(_tokens);

    withdraw(_customerAddress);
  }

  function withdraw(address _recipient)
  dividendHolder()
  public {
    require(regularPhase);
     
    address _customerAddress = msg.sender;
    uint _dividends = myDividends(false);

     
    payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

     
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    if (_recipient == address(0x0)) {
      _recipient = msg.sender;
    }

    _dividends = _dividends.div(1e10);  
    _0xBTC.transfer(_recipient, _dividends);

     
    emit onWithdraw(_recipient, _dividends);
  }

   
  function sell(uint _amountOfTokens)
  onlyHolders()
  public {
    require(regularPhase);

    require(_amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);

    uint _frontEndTokensToBurn = _amountOfTokens;

     
     
     
    uint userDivRate = getUserAverageDividendRate(msg.sender);
    require((2 * magnitude) <= userDivRate && (50 * magnitude) >= userDivRate);
    uint _divTokensToBurn = (_frontEndTokensToBurn.mul(userDivRate)).div(magnitude);

     
    uint _0xbtc = tokensTo0xbtc_(_frontEndTokensToBurn);

    if (_0xbtc > current0xbtcInvested) {
       
      current0xbtcInvested = 0;
    } else {
      current0xbtcInvested = current0xbtcInvested - _0xbtc;
    }

     
    uint _dividends = (_0xbtc.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude);

     
    uint _taxed0xbtc = _0xbtc.sub(_dividends);

     
    tokenSupply = tokenSupply.sub(_frontEndTokensToBurn);
    divTokenSupply = divTokenSupply.sub(_divTokensToBurn);

     
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].sub(_frontEndTokensToBurn);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].sub(_divTokensToBurn);

     
    int256 _updatedPayouts = (int256)(profitPerDivToken * _divTokensToBurn + (_taxed0xbtc * magnitude));
    payoutsTo_[msg.sender] -= _updatedPayouts;

     
    if (divTokenSupply > 0) {
       
      profitPerDivToken = profitPerDivToken.add((_dividends * magnitude) / divTokenSupply);
    }

     
    emit onTokenSell(msg.sender, _frontEndTokensToBurn, _taxed0xbtc);
  }

   
  function transfer(address _toAddress, uint _amountOfTokens)
  onlyHolders()
  public
  returns(bool) {
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER &&
      _amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);
    bytes memory empty;
    transferFromInternal(msg.sender, _toAddress, _amountOfTokens, empty);
    return true;

  }

  function approve(address spender, uint tokens)
  public
  returns(bool) {
    address _customerAddress = msg.sender;
    allowed[_customerAddress][spender] = tokens;

     
    emit Approval(_customerAddress, spender, tokens);

     
    return true;
  }

   
  function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
  public
  returns(bool) {
     
    address _customerAddress = _from;
    bytes memory empty;
     
     
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER &&
      _amountOfTokens <= frontTokenBalanceLedger_[_customerAddress] &&
      _amountOfTokens <= allowed[_customerAddress][msg.sender]);

    transferFromInternal(_from, _toAddress, _amountOfTokens, empty);

     
    return true;

  }

  function transferTo(address _from, address _to, uint _amountOfTokens, bytes _data)
  public {
    if (_from != msg.sender) {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER &&
        _amountOfTokens <= frontTokenBalanceLedger_[_from] &&
        _amountOfTokens <= allowed[_from][msg.sender]);
    } else {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER &&
        _amountOfTokens <= frontTokenBalanceLedger_[_from]);
    }

    transferFromInternal(_from, _to, _amountOfTokens, _data);
  }

   
  function totalSupply()
  public
  view
  returns(uint256) {
    return tokenSupply;
  }

   

  function startRegularPhase()
  onlyAdministrator
  public {
    regularPhase = true;
  }

   
  function setAdministrator(address _newAdmin, bool _status)
  onlyAdministrator()
  public {
    administrators[_newAdmin] = _status;
  }

  function setStakingRequirement(uint _amountOfTokens)
  onlyAdministrator()
  public {
     
    require(_amountOfTokens >= 100e18);
    stakingRequirement = _amountOfTokens;
  }

  function setName(string _name)
  onlyAdministrator()
  public {
    name = _name;
  }

  function setSymbol(string _symbol)
  onlyAdministrator()
  public {
    symbol = _symbol;
  }

  function changeBankroll(address _newBankrollAddress)
  onlyAdministrator
  public {
    bankrollAddress = _newBankrollAddress;
  }

   

  function total0xbtcBalance()
  public
  view
  returns(uint) {
    return _0xBTC.balanceOf(address(this));
  }

  function total0xbtcReceived()
  public
  view
  returns(uint) {
    return current0xbtcInvested;
  }

   
  function getMyDividendRate()
  public
  view
  returns(uint8) {
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    return userDividendRate[_customerAddress];
  }

   
  function getFrontEndTokenSupply()
  public
  view
  returns(uint) {
    return tokenSupply;
  }

   
  function getDividendTokenSupply()
  public
  view
  returns(uint) {
    return divTokenSupply;
  }

   
  function myFrontEndTokens()
  public
  view
  returns(uint) {
    address _customerAddress = msg.sender;
    return getFrontEndTokenBalanceOf(_customerAddress);
  }

   
  function myDividendTokens()
  public
  view
  returns(uint) {
    address _customerAddress = msg.sender;
    return getDividendTokenBalanceOf(_customerAddress);
  }

  function myReferralDividends()
  public
  view
  returns(uint) {
    return myDividends(true) - myDividends(false);
  }

  function myDividends(bool _includeReferralBonus)
  public
  view
  returns(uint) {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function theDividendsOf(bool _includeReferralBonus, address _customerAddress)
  public
  view
  returns(uint) {
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function getFrontEndTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint) {
    return frontTokenBalanceLedger_[_customerAddress];
  }

  function balanceOf(address _owner)
  view
  public
  returns(uint) {
    return getFrontEndTokenBalanceOf(_owner);
  }

  function getDividendTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint) {
    return dividendTokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress)
  view
  public
  returns(uint) {
    return (uint)((int256)(profitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

   
  function sellPrice()
  public
  view
  returns(uint) {
    uint price;

     
     
    uint tokensReceivedFor0xbtc = btcToTokens_(0.001 ether);

    price = (1e18 * 0.001 ether) / tokensReceivedFor0xbtc;

     
    uint theSellPrice = price.sub((price.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude));

    return theSellPrice;
  }

   
  function buyPrice(uint dividendRate)
  public
  view
  returns(uint) {
    uint price;

     
     
    uint tokensReceivedFor0xbtc = btcToTokens_(0.001 ether);

    price = (1e18 * 0.001 ether) / tokensReceivedFor0xbtc;

     
    uint theBuyPrice = (price.mul(dividendRate).div(100)).add(price);

    return theBuyPrice;
  }

  function calculateTokensReceived(uint _0xbtcToSpend)
  public
  view
  returns(uint) {
    uint fixedAmount = _0xbtcToSpend.mul(1e10);
    uint _dividends = (fixedAmount.mul(userDividendRate[msg.sender])).div(100);
    uint _taxed0xbtc = fixedAmount.sub(_dividends);
    uint _amountOfTokens = btcToTokens_(_taxed0xbtc);
    return _amountOfTokens;
  }

   
   
  function calculate0xbtcReceived(uint _tokensToSell)
  public
  view
  returns(uint) {
    require(_tokensToSell <= tokenSupply);
    uint _0xbtc = tokensTo0xbtc_(_tokensToSell);
    uint userAverageDividendRate = getUserAverageDividendRate(msg.sender);
    uint _dividends = (_0xbtc.mul(userAverageDividendRate).div(100)).div(magnitude);
    uint _taxed0xbtc = _0xbtc.sub(_dividends);
    return _taxed0xbtc.div(1e10);
  }

   

  function getUserAverageDividendRate(address user) public view returns(uint) {
    return (magnitude * dividendTokenBalanceLedger_[user]).div(frontTokenBalanceLedger_[user]);
  }

  function getMyAverageDividendRate() public view returns(uint) {
    return getUserAverageDividendRate(msg.sender);
  }

   

   
  function purchaseTokens(uint _incoming, address _referredBy, bool _reinvest)
  internal
  returns(uint) {

    require(_incoming.mul(1e10) >= MIN_TOK_BUYIN || msg.sender == bankrollAddress, "Tried to buy below the min 0xbtc buyin threshold.");

    uint toReferrer;
    uint toTokenHolders;
    uint toDivCardHolders;

    uint dividendAmount;

    uint tokensBought;

    uint remaining0xbtc = _incoming.mul(1e10);

    uint fee;

     
    if (regularPhase) {
      toDivCardHolders = _incoming.mul(1e8);
      remaining0xbtc = remaining0xbtc.sub(toDivCardHolders);
    }

     

     
    dividendAmount = (remaining0xbtc.mul(userDividendRate[msg.sender])).div(100);

    remaining0xbtc = remaining0xbtc.sub(dividendAmount);

     
    tokensBought = btcToTokens_(remaining0xbtc);

     
    require(tokenSupply.add(tokensBought) <= MAX_SUPPLY);
    tokenSupply = tokenSupply.add(tokensBought);
    divTokenSupply = divTokenSupply.add(tokensBought.mul(userDividendRate[msg.sender]));

     

    current0xbtcInvested = current0xbtcInvested + remaining0xbtc;

     

     
     
    if (_referredBy != 0x0000000000000000000000000000000000000000 &&
      _referredBy != msg.sender &&
      frontTokenBalanceLedger_[_referredBy] >= stakingRequirement) {
      toReferrer = (dividendAmount.mul(referrer_percentage)).div(100);
      referralBalance_[_referredBy] += toReferrer;
      emit Referral(_referredBy, toReferrer);
    }

     
    toTokenHolders = dividendAmount.sub(toReferrer);

    fee = toTokenHolders * magnitude;
    fee = fee - (fee - (tokensBought.mul(userDividendRate[msg.sender]) * (toTokenHolders * magnitude / (divTokenSupply))));

     
    profitPerDivToken = profitPerDivToken.add((toTokenHolders.mul(magnitude)).div(divTokenSupply));
    payoutsTo_[msg.sender] += (int256)((profitPerDivToken * tokensBought.mul(userDividendRate[msg.sender])) - fee);

     
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].add(tokensBought);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].add(tokensBought.mul(userDividendRate[msg.sender]));

    if (_reinvest == false) {
       
      _0xBTC.transferFrom(msg.sender, address(this), _incoming);
    }

     
    if (regularPhase) {
      _0xBTC.approve(address(divCardContract), toDivCardHolders.div(1e10));
      divCardContract.receiveDividends(toDivCardHolders.div(1e10), userDividendRate[msg.sender]);
    }

     
    emit Allocation(0, toReferrer, toTokenHolders, toDivCardHolders, remaining0xbtc);

    emit onTokenPurchase(msg.sender, _incoming, userDividendRate[msg.sender], tokensBought, _referredBy);

     
    uint sum = toReferrer + toTokenHolders + toDivCardHolders + remaining0xbtc - _incoming.mul(1e10);
    assert(sum == 0);
  }

   
  function btcToTokens_(uint _0xbtcAmount)
  public
  view
  returns(uint) {

     

    require(_0xbtcAmount > MIN_TOK_BUYIN, "Tried to buy tokens with too little 0xbtc.");

    uint _0xbtcTowardsVariablePriceTokens = _0xbtcAmount;

    uint varPriceTokens = 0;

    if (_0xbtcTowardsVariablePriceTokens != 0) {

      uint simulated0xbtcBeforeInvested = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint simulated0xbtcAfterInvested = simulated0xbtcBeforeInvested + _0xbtcTowardsVariablePriceTokens;

      uint tokensBefore = toPowerOfTwoThirds(simulated0xbtcBeforeInvested.mul(3).div(2)).mul(MULTIPLIER);
      uint tokensAfter = toPowerOfTwoThirds(simulated0xbtcAfterInvested.mul(3).div(2)).mul(MULTIPLIER);

       

      varPriceTokens = (1e6) * tokensAfter.sub(tokensBefore);
    }

    uint totalTokensReceived = varPriceTokens;

    assert(totalTokensReceived > 0);
    return totalTokensReceived;
  }

   
  function tokensTo0xbtc_(uint _tokens)
  public
  view
  returns(uint) {
    require(_tokens >= MIN_TOKEN_SELL_AMOUNT, "Tried to sell too few tokens.");

     

    uint tokensToSellAtVariablePrice = _tokens;

    uint _0xbtcFromVarPriceTokens;

     

    if (tokensToSellAtVariablePrice != 0) {

       

      uint investmentBefore = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint investmentAfter = toPowerOfThreeHalves((tokenSupply - tokensToSellAtVariablePrice).div(MULTIPLIER * 1e6)).mul(2).div(3);

      _0xbtcFromVarPriceTokens = investmentBefore.sub(investmentAfter);
    }

    uint _0xbtcReceived = _0xbtcFromVarPriceTokens;

    assert(_0xbtcReceived > 0);
    return _0xbtcReceived;
  }

  function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
  internal {
    require(regularPhase);
    require(_toAddress != address(0x0));
    address _customerAddress = _from;
    uint _amountOfFrontEndTokens = _amountOfTokens;

     
    if (theDividendsOf(true, _customerAddress) > 0) withdrawFrom(_customerAddress);

     
     
    uint _amountOfDivTokens = _amountOfFrontEndTokens.mul(getUserAverageDividendRate(_customerAddress)).div(magnitude);

    if (_customerAddress != msg.sender) {
       
       
      allowed[_customerAddress][msg.sender] -= _amountOfTokens;
    }

     
    frontTokenBalanceLedger_[_customerAddress] = frontTokenBalanceLedger_[_customerAddress].sub(_amountOfFrontEndTokens);
    frontTokenBalanceLedger_[_toAddress] = frontTokenBalanceLedger_[_toAddress].add(_amountOfFrontEndTokens);
    dividendTokenBalanceLedger_[_customerAddress] = dividendTokenBalanceLedger_[_customerAddress].sub(_amountOfDivTokens);
    dividendTokenBalanceLedger_[_toAddress] = dividendTokenBalanceLedger_[_toAddress].add(_amountOfDivTokens);

     
    if (!userSelectedRate[_toAddress]) {
      userSelectedRate[_toAddress] = true;
      userDividendRate[_toAddress] = userDividendRate[_customerAddress];
    }

     
    payoutsTo_[_customerAddress] -= (int256)(profitPerDivToken * _amountOfDivTokens);
    payoutsTo_[_toAddress] += (int256)(profitPerDivToken * _amountOfDivTokens);

    uint length;

    assembly {
      length: = extcodesize(_toAddress)
    }

    if (length > 0) {
       
       
      ERC223Receiving receiver = ERC223Receiving(_toAddress);
      receiver.tokenFallback(_from, _amountOfTokens, _data);
    }

     
    emit Transfer(_customerAddress, _toAddress, _amountOfFrontEndTokens);
  }

   
  function withdrawFrom(address _customerAddress)
  internal {
     
    uint _dividends = theDividendsOf(false, _customerAddress);

     
    payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

     
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    _dividends = _dividends.div(1e10);  
    _0xBTC.transfer(_customerAddress, _dividends);  

     
    emit onWithdraw(_customerAddress, _dividends);
  }

   

  function toPowerOfThreeHalves(uint x) public pure returns(uint) {
     
     
    return sqrt(x ** 3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns(uint) {
     
     
    return cbrt(x ** 2);
  }

  function sqrt(uint x) public pure returns(uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns(uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z * z) + 2 * z) / 3;
    }
  }
}

 


interface _0xBitconnectDividendCards {
  function ownerOf(uint   ) external pure returns(address);

  function receiveDividends(uint amount, uint divCardRate) external;
}

interface _0xBitconnectBankroll {
  function receiveDividends(uint amount) external;
}


interface ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) external returns(bool);
}

 

library SafeMath {

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}