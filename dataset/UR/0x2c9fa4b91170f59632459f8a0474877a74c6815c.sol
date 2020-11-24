 

pragma solidity ^0.4.24; 

interface IToken {
  function name() external view returns(string);

  function symbol() external view returns(string);

  function decimals() external view returns(uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function mint(address to, uint256 value) external returns (bool);

  function burn(address from, uint256 value) external returns (bool);

  function isMinter(address account) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event Paused(address account);
  event Unpaused(address account);
}
  
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IToken token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IToken token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IToken token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IToken token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IToken token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}



contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

contract Crowdsale is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IToken;

   
  IToken private _token;

   
  address private _wallet;

   
   
   
   
  uint256 private _rate;

   
  uint256 private _weiRaised;

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 rate, address wallet, IToken token) internal {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function token() public view returns(IToken) {
    return _token;
  }

   
  function wallet() public view returns(address) {
    return _wallet;
  }

   
  function rate() public view returns(uint256) {
    return _rate;
  }

   
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

   
  function buyTokens(address beneficiary) public nonReentrant payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
     
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

   
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _cap;

   
  constructor(uint256 cap) internal {
    require(cap > 0);
    _cap = cap;
  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised() >= _cap;
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
    require(weiRaised().add(weiAmount) <= _cap);
  }

}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _openingTime;
  uint256 private _closingTime;

   
  modifier onlyWhileOpen {
    require(isOpen());
    _;
  }

   
  constructor(uint256 openingTime, uint256 closingTime) internal {
     
    require(openingTime >= block.timestamp);
    require(closingTime > openingTime);

    _openingTime = openingTime;
    _closingTime = closingTime;
  }

   
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

   
  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

   
  function isOpen() public view returns (bool) {
     
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > _closingTime;
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

contract MintedCrowdsale is Crowdsale {
  constructor() internal {}

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    require(token().mint(beneficiary, tokenAmount));
  }
}

contract SharesCrowdsale is Crowdsale {
  address[] public wallets;

  constructor(
    address[] _wallets
  ) internal {
    wallets = _wallets;
  }

   
  modifier canBuyOneToken() {
    uint256 calculatedRate = rate() + increaseRateValue - decreaseRateValue;
    uint256 priceOfTokenInWei = 1 ether / calculatedRate;
    require(msg.value >= priceOfTokenInWei);
    _;
  }

  event IncreaseRate(
    uint256 change,
    uint256 rate
  );

  event DecreaseRate(
    uint256 change,
    uint256 rate
  );

  uint256 public increaseRateValue = 0;
  uint256 public decreaseRateValue = 0;

   
  function increaseRateBy(uint256 value)
    external returns (uint256)
  {
    require(token().isMinter(msg.sender));

    increaseRateValue = value;
    decreaseRateValue = 0;

    uint256 calculatedRate = rate() + increaseRateValue;

    emit IncreaseRate(value, calculatedRate);

    return calculatedRate;
  }

   
  function decreaseRateBy(uint256 value)
    external returns (uint256)
  {
    require(token().isMinter(msg.sender));

    increaseRateValue = 0;
    decreaseRateValue = value;

    uint256 calculatedRate = rate() - decreaseRateValue;

    emit DecreaseRate(value, calculatedRate);

    return calculatedRate;
  }

   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    uint256 calculatedRate = rate() + increaseRateValue - decreaseRateValue;
    uint256 tokensAmount = weiAmount.mul(calculatedRate).div(1 ether);

    uint256 charge = weiAmount.mul(calculatedRate).mod(1 ether);
    if (charge > 0) {
        tokensAmount += 1;
    }

    return tokensAmount;
  }

   
  function _forwardFunds() internal {
    if (weiRaised() > 100 ether) {
        wallet().transfer(msg.value);
    } else {
        uint256 walletsNumber = wallets.length;
        uint256 amountPerWallet = msg.value.div(walletsNumber);

        for (uint256 i = 0; i < walletsNumber; i++) {
            wallets[i].transfer(amountPerWallet);
        }

        uint256 charge = msg.value.mod(walletsNumber);
        if (charge > 0) {
            wallets[0].transfer(charge);
        }
    }
  }

  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    canBuyOneToken()
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }
}

contract Tokensale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, SharesCrowdsale {
  constructor(
    uint256 rate,
    address finalWallet,
    address token,
    uint256 cap,
    uint256 openingTime,
    uint256 closingTime,
    address[] wallets
  )
    public
    Crowdsale(rate, finalWallet, IToken(token))
    CappedCrowdsale(cap)
    TimedCrowdsale(openingTime, closingTime)
    SharesCrowdsale(wallets)
  {
  }
}