 

pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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
}

 
library SafeERC20Transfer {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }
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


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  using SafeERC20Transfer for IERC20;

   
  IERC20 private _token;

   
  address private _wallet;

   
  uint256 private _rate = 5000;

   
  uint256 private _weiRaised;

   
  uint256 private _accruedTokensAmount;

   
  uint256 private _threeMonths = 5256000;
  uint256 private _sixMonths = 15768000;
  uint256 private _nineMonths = 21024000;
  uint256 private _twelveMonths = 31536000;

   
  uint256 private _foundersTokens = 4e7;
  uint256 private _distributedTokens = 1e9;
  uint256 public softCap = 1000 ether;
  uint256 public hardCap = 35000 ether;
  uint256 public preICO_1_Start = 1541030400;  
  uint256 public preICO_2_Start = 1541980800;  
  uint256 public preICO_3_Start = 1542844800;  
  uint256 public ICO_Start = 1543622400;  
  uint256 public ICO_End = 1548979199;  
  uint32 public bonus1 = 30;  
  uint32 public bonus2 = 20;  
  uint32 public bonus3 = 10;  
  uint32 public whitelistedBonus = 10;

  mapping (address => bool) private _whitelist;

   
  mapping (address => uint256) public threeMonthsFreezingAccrual;
  mapping (address => uint256) public sixMonthsFreezingAccrual;
  mapping (address => uint256) public nineMonthsFreezingAccrual;
  mapping (address => uint256) public twelveMonthsFreezingAccrual;

   
  mapping (address => uint256) public ledger;

   
  event Accrual(
    address to,
    uint256 accruedAmount,
    uint256 freezingTime,
    uint256 purchasedAmount,
    uint256 weiValue
  );

   
  event Released(
    address to,
    uint256 amount
  );

   
  event Refunded(
    address to,
    uint256 value
  );

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(address newOwner, address wallet, address founders, IERC20 token) public {
    require(wallet != address(0));
    require(founders != address(0));
    require(token != address(0));
    require(newOwner != address(0));
    transferOwnership(newOwner);

    _wallet = wallet;
    _token = token;

    twelveMonthsFreezingAccrual[founders] = _foundersTokens;
    _accruedTokensAmount = _foundersTokens;
    emit Accrual(founders, _foundersTokens, _twelveMonths, 0, 0);
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function token() public view returns(IERC20) {
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

   
  function whitelist(address who) public view returns (bool) {
    return _whitelist[who];
  }

   
  function addToWhitelist(address who) public onlyOwner {
    _whitelist[who] = true;
  }

   
  function removeFromWhitelist(address who) public onlyOwner {
    _whitelist[who] = false;
  }

   
  function accrueAdvisorsTokens(address to, uint256 amount) public onlyOwner {
    require(now > ICO_End);
    uint256 tokenBalance = _token.balanceOf(address(this));
    require(tokenBalance >= _accruedTokensAmount.add(amount));

    _accruedTokensAmount = _accruedTokensAmount.add(amount);
    
    sixMonthsFreezingAccrual[to] = sixMonthsFreezingAccrual[to].add(amount);

    emit Accrual(to, amount, _sixMonths, 0, 0);    
  }

   
  function accruePartnersTokens(address to, uint256 amount) public onlyOwner {
    require(now > ICO_End);
    uint256 tokenBalance = _token.balanceOf(address(this));
    require(tokenBalance >= _accruedTokensAmount.add(amount));

    _accruedTokensAmount = _accruedTokensAmount.add(amount);
    
    nineMonthsFreezingAccrual[to] = nineMonthsFreezingAccrual[to].add(amount);

    emit Accrual(to, amount, _nineMonths, 0, 0);    
  }

   
  function accrueBountyTokens(address to, uint256 amount) public onlyOwner {
    require(now > ICO_End);
    uint256 tokenBalance = _token.balanceOf(address(this));
    require(tokenBalance >= _accruedTokensAmount.add(amount));

    _accruedTokensAmount = _accruedTokensAmount.add(amount);
    
    twelveMonthsFreezingAccrual[to] = twelveMonthsFreezingAccrual[to].add(amount);

    emit Accrual(to, amount, _twelveMonths, 0, 0);    
  }

   
  function release() public {
    address who = msg.sender;
    uint256 amount;
    if (now > ICO_End.add(_twelveMonths) && twelveMonthsFreezingAccrual[who] > 0) {
      amount = amount.add(twelveMonthsFreezingAccrual[who]);
      _accruedTokensAmount = _accruedTokensAmount.sub(twelveMonthsFreezingAccrual[who]);
      twelveMonthsFreezingAccrual[who] = 0;
    }
    if (now > ICO_End.add(_nineMonths) && nineMonthsFreezingAccrual[who] > 0) {
      amount = amount.add(nineMonthsFreezingAccrual[who]);
      _accruedTokensAmount = _accruedTokensAmount.sub(nineMonthsFreezingAccrual[who]);
      nineMonthsFreezingAccrual[who] = 0;
    }
    if (now > ICO_End.add(_sixMonths) && sixMonthsFreezingAccrual[who] > 0) {
      amount = amount.add(sixMonthsFreezingAccrual[who]);
      _accruedTokensAmount = _accruedTokensAmount.sub(sixMonthsFreezingAccrual[who]);
      sixMonthsFreezingAccrual[who] = 0;
    }
    if (now > ICO_End.add(_threeMonths) && threeMonthsFreezingAccrual[who] > 0) {
      amount = amount.add(threeMonthsFreezingAccrual[who]);
      _accruedTokensAmount = _accruedTokensAmount.sub(threeMonthsFreezingAccrual[who]);
      threeMonthsFreezingAccrual[who] = 0;
    }
    if (amount > 0) {
      _deliverTokens(who, amount);
      emit Released(who, amount);
    }
  }

   
  function refund() public {
    address investor = msg.sender;
    require(now > ICO_End);
    require(_weiRaised < softCap);
    require(ledger[investor] > 0);
    uint256 value = ledger[investor];
    ledger[investor] = 0;
    investor.transfer(value);
    emit Refunded(investor, value);
  }

   
  function buyTokens(address beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _accrueBonusTokens(beneficiary, tokens, weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    if (_weiRaised >= softCap) _forwardFunds();

    ledger[msg.sender] = ledger[msg.sender].add(msg.value);
  }

   
   
   

     
  function _accrueBonusTokens(address beneficiary, uint256 tokenAmount, uint256 weiAmount) internal {
    uint32 bonus = 0;
    uint256 bonusTokens = 0;
    uint256 tokenBalance = _token.balanceOf(address(this));
    if (_whitelist[beneficiary] && now < ICO_Start) bonus = bonus + whitelistedBonus;
    if (now < preICO_2_Start) {
      bonus = bonus + bonus1;
      bonusTokens = tokenAmount.mul(bonus).div(100);

      require(tokenBalance >= _accruedTokensAmount.add(bonusTokens).add(tokenAmount));

      _accruedTokensAmount = _accruedTokensAmount.add(bonusTokens);

      nineMonthsFreezingAccrual[beneficiary] = nineMonthsFreezingAccrual[beneficiary].add(bonusTokens);

      emit Accrual(beneficiary, bonusTokens, _nineMonths, tokenAmount, weiAmount);
    } else if (now < preICO_3_Start) {
      bonus = bonus + bonus2;
      bonusTokens = tokenAmount.mul(bonus).div(100);

      require(tokenBalance >= _accruedTokensAmount.add(bonusTokens).add(tokenAmount));

      _accruedTokensAmount = _accruedTokensAmount.add(bonusTokens);
      
      sixMonthsFreezingAccrual[beneficiary] = sixMonthsFreezingAccrual[beneficiary].add(bonusTokens);

      emit Accrual(beneficiary, bonusTokens, _sixMonths, tokenAmount, weiAmount);
    } else if (now < ICO_Start) {
      bonus = bonus + bonus3;
      bonusTokens = tokenAmount.mul(bonus).div(100);

      require(tokenBalance >= _accruedTokensAmount.add(bonusTokens).add(tokenAmount));

      _accruedTokensAmount = _accruedTokensAmount.add(bonusTokens);
      
      threeMonthsFreezingAccrual[beneficiary] = threeMonthsFreezingAccrual[beneficiary].add(bonusTokens);

      emit Accrual(beneficiary, bonusTokens, _threeMonths, tokenAmount, weiAmount);
    } else {
      require(tokenBalance >= _accruedTokensAmount.add(tokenAmount));

      emit Accrual(beneficiary, 0, 0, tokenAmount, weiAmount);
    }
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
    require(_weiRaised.add(weiAmount) <= hardCap);
    require(now >= preICO_1_Start);
    require(now <= ICO_End);
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

   
  function _getTokenAmount(
    uint256 weiAmount
  )
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate).div(1e18);
  }

   
  function _forwardFunds() internal {
    uint256 balance = address(this).balance;
    _wallet.transfer(balance);
  }
}