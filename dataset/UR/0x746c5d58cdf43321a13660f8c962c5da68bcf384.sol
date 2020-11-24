 

pragma solidity ^0.5.0;

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

contract Whitelisted is Ownable {

    mapping (address => uint16) public whitelist;
    mapping (address => bool) public provider;

     
    modifier onlyWhitelisted {
      require(isWhitelisted(msg.sender));
      _;
    }

      modifier onlyProvider {
        require(isProvider(msg.sender));
        _;
      }

       
      function isProvider(address _provider) public view returns (bool){
        if (owner() == _provider){
          return true;
        }
        return provider[_provider] == true ? true : false;
      }
       
      function setProvider(address _provider) public onlyOwner {
         provider[_provider] = true;
      }
       
      function deactivateProvider(address _provider) public onlyOwner {
         require(provider[_provider] == true);
         provider[_provider] = false;
      }
       
      function setWhitelisted(address _purchaser, uint16 _zone) public onlyProvider {
         whitelist[_purchaser] = _zone;
      }
       
      function deleteFromWhitelist(address _purchaser) public onlyProvider {
         whitelist[_purchaser] = 0;
      }
       
      function getWhitelistedZone(address _purchaser) public view returns(uint16) {
        return whitelist[_purchaser] > 0 ? whitelist[_purchaser] : 0;
      }
       
      function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
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

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
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
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
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
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
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

     
    constructor (uint256 openingTime, uint256 closingTime) public {
         
        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

     
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

     
    function isOpen() public view returns (bool) {
         
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > _closingTime;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

 

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

     
    function withdrawTokens(address beneficiary) public {
        require(hasClosed());
        uint256 amount = _balances[beneficiary];
        require(amount > 0);
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    }

}

 

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

 
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _tokenWallet;

     
    constructor (address tokenWallet) public {
        require(tokenWallet != address(0));
        _tokenWallet = tokenWallet;
    }

     
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

     
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}

 

contract MocoCrowdsale is TimedCrowdsale, AllowanceCrowdsale, Whitelisted {
   

  uint256 public bonusPeriod;

  uint256 public bonusAmount;
   
  uint256 private _unlock1;

   
  uint256 private _unlock2;

   
  uint8 private _lockedZone;

   
  uint256 private _totalTokensDistributed;


   
  uint256 private _totalTokensLocked;


  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    address asset,
    uint256 value,
    uint256 amount
  );

  struct Asset {
    uint256 weiRaised;
    uint256 minAmount;
    uint256 rate;
    bool active;
  }

  mapping (address => Asset) private asset;
  mapping (address => uint256) private _balances;


  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _unlockPeriod1,
    uint256 _unlockPeriod2,
    uint256 _bonusPeriodEnd,
    uint256 _bonusAmount,
    uint256 _rate,
    address payable _wallet,
    IERC20 _token,
    address _tokenWallet
  ) public
  TimedCrowdsale(_openingTime, _closingTime)
  Crowdsale(_rate, _wallet, _token)
  AllowanceCrowdsale(_tokenWallet){
       _unlock1 = _unlockPeriod1;
       _unlock2 = _unlockPeriod2;
       bonusPeriod = _bonusPeriodEnd;
      bonusAmount  = _bonusAmount;
      asset[address(0)].rate  = _rate;
  }
  function getAssetRaised(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].weiRaised;
  }
  function getAssetMinAmount(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].minAmount;
  }
  function getAssetRate(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].rate;
  }
  function isAssetActive(address _assetAddress) public view returns(bool) {
      return asset[_assetAddress].active == true ? true : false;
  }
   
  function setAsset(address _assetAddress, uint256 _weiRaised, uint256 _minAmount, uint256 _rate) public onlyOwner {
      asset[_assetAddress].weiRaised = _weiRaised;
      asset[_assetAddress].minAmount = _minAmount;
      asset[_assetAddress].rate = _rate;
      asset[_assetAddress].active = true;
  }

   

  function weiRaised(address _asset) public view returns (uint256) {
    return asset[_asset].weiRaised;
  }
  function _getTokenAmount(uint256 weiAmount, address asst)
    internal view returns (uint256)
  {
    return weiAmount.mul(asset[asst].rate);
  }

  function minAmount(address _asset) public view returns (uint256) {
    return asset[_asset].minAmount;
  }

   
  function buyTokens(address beneficiary) public onlyWhitelisted payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount, address(0));

     
    uint256 tokens = _getTokenAmount(weiAmount, address(0));

     
    asset[address(0)].weiRaised = asset[address(0)].weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);

    emit TokensPurchased(
      msg.sender,
      beneficiary,
      address(0),
      weiAmount,
      tokens
    );

     

    super._forwardFunds();
     
  }
   
  function buyTokensAsset(address beneficiary, address asst, uint256 amount) public onlyWhitelisted {
     require(isAssetActive(asst));
    _preValidatePurchase(beneficiary, amount, asst);

     
    uint256 tokens = _getTokenAmount(amount, asst);

     
    asset[asst].weiRaised = asset[asst].weiRaised.add(amount);

    _processPurchase(beneficiary, tokens);

    emit TokensPurchased(
      msg.sender,
      beneficiary,
      asst,
      amount,
      tokens
    );

     address _wallet  = wallet();
     IERC20(asst).safeTransferFrom(beneficiary, _wallet, amount);

     
  }

   
  function lockedHasEnd() public view returns (bool) {
    return block.timestamp > _unlock1 ? true : false;
  }
   
  function lockedTwoHasEnd() public view returns (bool) {
    return block.timestamp > _unlock2 ? true : false;
  }
 
  function withdrawTokens(address beneficiary) public {
    require(lockedHasEnd());
    uint256 amount = _balances[beneficiary];
    require(amount > 0);
    uint256 zone = super.getWhitelistedZone(beneficiary);
    if (zone == 840){
       
      if(lockedTwoHasEnd()){
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
      }
    } else {
    _balances[beneficiary] = 0;
    _deliverTokens(beneficiary, amount);
    }
  }

   
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }
   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount,
    address asst
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
    require(weiAmount >= minAmount(asst));
}
  function getBonusAmount(uint256 _tokenAmount) public view returns(uint256) {
    return block.timestamp < bonusPeriod ? _tokenAmount.div(bonusAmount) : 0;
  }

  function calculateTokens(uint256 _weiAmount) public view returns(uint256) {
    uint256 tokens  = _getTokenAmount(_weiAmount);
    return  tokens + getBonusAmount(tokens);
  }
  function lockedTokens(address beneficiary, uint256 tokenAmount) public onlyOwner returns(bool) {
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    return true;
  }
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    uint256 zone = super.getWhitelistedZone(beneficiary);
   uint256 bonusTokens = getBonusAmount(tokenAmount);
    if (zone == 840){
      uint256 totalTokens = bonusTokens.add(tokenAmount);
      _balances[beneficiary] = _balances[beneficiary].add(totalTokens);
    }
    else {
      super._deliverTokens(beneficiary, tokenAmount);
      _balances[beneficiary] = _balances[beneficiary].add(bonusTokens);
    }

  }

}