 

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

 

contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0));
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}

 

contract Pausable is HasAdmin {
  event Paused();
  event Unpaused();

  bool public paused;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

 

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return a < b ? a : b;
  }
}

 

interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

 

contract Withdrawable is HasAdmin {
  function withdrawEther() external onlyAdmin {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawToken(IERC20 _token) external onlyAdmin {
    require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
  }
}

 

interface IERC20Receiver {
  function receiveApproval(
    address _from,
    uint256 _value,
    address _tokenAddress,
    bytes calldata _data
  )
    external;
}

 

interface IKyber {
  function getExpectedRate(
    address _src,
    address _dest,
    uint256 _srcAmount
  )
    external
    view
    returns (
      uint256 _expectedRate,
      uint256 _slippageRate
    );

  function trade(
    address _src,
    uint256 _maxSrcAmount,
    address _dest,
    address payable _receiver,
    uint256 _maxDestAmount,
    uint256 _minConversionRate,
    address _wallet
  )
    external
    payable
    returns (uint256 _destAmount);
}

 

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
    require(b > 0);
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
    require(b > 0);
    return a % b;
  }

  function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
  }

  function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require(b <= a);
    return a - b;
  }

  function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    require(c >= a);
  }
}

 

interface IERC20Detailed {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function decimals() external view returns (uint8 _decimals);
}

 

contract KyberTokenDecimals {
  using SafeMath for uint256;

  address public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function _getTokenDecimals(address _token) internal view returns (uint8 _decimals) {
    return _token != ethAddress ? IERC20Detailed(_token).decimals() : 18;
  }

  function _fixTokenDecimals(
    address _src,
    address _dest,
    uint256 _unfixedDestAmount,
    bool _ceiling
  )
    internal
    view
    returns (uint256 _destTokenAmount)
  {
    uint256 _unfixedDecimals = _getTokenDecimals(_src) + 18;  
    uint256 _decimals = _getTokenDecimals(_dest);

    if (_unfixedDecimals > _decimals) {
       
      if (_ceiling) {
        return _unfixedDestAmount.ceilingDiv(10 ** (_unfixedDecimals - _decimals));
      } else {
        return _unfixedDestAmount.div(10 ** (_unfixedDecimals - _decimals));
      }
    } else {
       
      return _unfixedDestAmount.mul(10 ** (_decimals - _unfixedDecimals));
    }
  }
}

 

contract KyberAdapter is KyberTokenDecimals {
  IKyber public kyber = IKyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

  function() external payable {
    require(msg.sender == address(kyber));
  }

  function _getConversionRate(
    address _src,
    uint256 _srcAmount,
    address _dest
  )
    internal
    view
    returns (
      uint256 _expectedRate,
      uint256 _slippageRate
    )
  {
    return kyber.getExpectedRate(_src, _dest, _srcAmount);
  }

  function _convertToken(
    address _src,
    uint256 _srcAmount,
    address _dest
  )
    internal
    view
    returns (
      uint256 _expectedAmount,
      uint256 _slippageAmount
    )
  {
    (uint256 _expectedRate, uint256 _slippageRate) = _getConversionRate(_src, _srcAmount, _dest);

    return (
      _fixTokenDecimals(_src, _dest, _srcAmount.mul(_expectedRate), false),
      _fixTokenDecimals(_src, _dest, _srcAmount.mul(_slippageRate), false)
    );
  }

  function _getTokenBalance(address _token, address _account) internal view returns (uint256 _balance) {
    return _token != ethAddress ? IERC20(_token).balanceOf(_account) : _account.balance;
  }

  function _swapToken(
    address _src,
    uint256 _maxSrcAmount,
    address _dest,
    uint256 _maxDestAmount,
    uint256 _minConversionRate,
    address payable _initiator,
    address payable _receiver
  )
    internal
    returns (
      uint256 _srcAmount,
      uint256 _destAmount
    )
  {
    require(_src != _dest);
    require(_src == ethAddress ? msg.value >= _maxSrcAmount : msg.value == 0);

     
    uint256 _balanceBefore = _getTokenBalance(_src, address(this));

    if (_src != ethAddress) {
      require(IERC20(_src).transferFrom(_initiator, address(this), _maxSrcAmount));
      require(IERC20(_src).approve(address(kyber), _maxSrcAmount));
    } else {
       
      _balanceBefore = _balanceBefore.sub(_maxSrcAmount);
    }

    _destAmount = kyber.trade.value(
      _src == ethAddress ? _maxSrcAmount : 0
    )(
      _src,
      _maxSrcAmount,
      _dest,
      _receiver,
      _maxDestAmount,
      _minConversionRate,
      address(0)
    );

    uint256 _balanceAfter = _getTokenBalance(_src, address(this));
    _srcAmount = _maxSrcAmount;

     
    if (_balanceAfter > _balanceBefore) {
      uint256 _change = _balanceAfter - _balanceBefore;
      _srcAmount = _srcAmount.sub(_change);

      if (_src != ethAddress) {
        require(IERC20(_src).transfer(_initiator, _change));
      } else {
        _initiator.transfer(_change);
      }
    }
  }
}

 

contract KyberCustomTokenRates is HasAdmin, KyberAdapter {
  struct Rate {
    address quote;
    uint256 value;
  }

  event CustomTokenRateUpdated(
    address indexed _tokenAddress,
    address indexed _quoteTokenAddress,
    uint256 _rate
  );

  mapping (address => Rate) public customTokenRate;

  function _hasCustomTokenRate(address _tokenAddress) internal view returns (bool _correct) {
    return customTokenRate[_tokenAddress].value > 0;
  }

  function _setCustomTokenRate(address _tokenAddress, address _quoteTokenAddress, uint256 _rate) internal {
    require(_rate > 0);
    customTokenRate[_tokenAddress] = Rate({ quote: _quoteTokenAddress, value: _rate });
    emit CustomTokenRateUpdated(_tokenAddress, _quoteTokenAddress, _rate);
  }

   
  function _getConversionRate(
    address _src,
    uint256 _srcAmount,
    address _dest
  )
    internal
    view
    returns (
      uint256 _expectedRate,
      uint256 _slippageRate
    )
  {
    uint256 _numerator = 1;
    uint256 _denominator = 1;

    if (_hasCustomTokenRate(_src)) {
      Rate storage _rate = customTokenRate[_src];

      _src = _rate.quote;
      _srcAmount = _srcAmount.mul(_rate.value).div(10**18);

      _numerator = _rate.value;
      _denominator = 10**18;
    }

    if (_hasCustomTokenRate(_dest)) {
      Rate storage _rate = customTokenRate[_dest];

      _dest = _rate.quote;

       
      if (_numerator == 1) { _numerator = 10**18; }
      _denominator = _rate.value;
    }

    if (_src != _dest) {
      (_expectedRate, _slippageRate) = super._getConversionRate(_src, _srcAmount, _dest);
    } else {
      _expectedRate = _slippageRate = 10**18;
    }

    return (
      _expectedRate.mul(_numerator).div(_denominator),
      _slippageRate.mul(_numerator).div(_denominator)
    );
  }

  function _swapToken(
    address _src,
    uint256 _maxSrcAmount,
    address _dest,
    uint256 _maxDestAmount,
    uint256 _minConversionRate,
    address payable _initiator,
    address payable _receiver
  )
    internal
    returns (
      uint256 _srcAmount,
      uint256 _destAmount
    )
  {
    if (_hasCustomTokenRate(_src) || _hasCustomTokenRate(_dest)) {
      require(_src == ethAddress ? msg.value >= _maxSrcAmount : msg.value == 0);
      require(_receiver == address(this));

      (uint256 _expectedRate, ) = _getConversionRate(_src, _srcAmount, _dest);
      require(_expectedRate >= _minConversionRate);

      _srcAmount = _maxSrcAmount;
      _destAmount = _fixTokenDecimals(_src, _dest, _srcAmount.mul(_expectedRate), false);

      if (_destAmount > _maxDestAmount) {
        _destAmount = _maxDestAmount;
        _srcAmount = _fixTokenDecimals(_dest, _src, _destAmount.mul(10**36).ceilingDiv(_expectedRate), true);

         
        if (_srcAmount > _maxSrcAmount) {
          _srcAmount = _maxSrcAmount;
        }
      }

      if (_src != ethAddress) {
        require(IERC20(_src).transferFrom(_initiator, address(this), _srcAmount));
      } else if (msg.value > _srcAmount) {
        _initiator.transfer(msg.value - _srcAmount);
      }

      return (_srcAmount, _destAmount);
    }

    return super._swapToken(
      _src,
      _maxSrcAmount,
      _dest,
      _maxDestAmount,
      _minConversionRate,
      _initiator,
      _receiver
    );
  }
}

 

library AddressUtils {
  function toPayable(address _address) internal pure returns (address payable _payable) {
    return address(uint160(_address));
  }

  function isContract(address _address) internal view returns (bool _correct) {
    uint256 _size;
     
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }
}

 

contract LandSale is Pausable, Withdrawable, KyberCustomTokenRates, IERC20Receiver {
  using AddressUtils for address;

  enum ChestType {
    Savannah,
    Forest,
    Arctic,
    Mystic
  }

  event ChestPurchased(
    ChestType indexed _chestType,
    uint256 _chestAmount,
    address indexed _tokenAddress,
    uint256 _tokenAmount,
    uint256 _totalPrice,
    uint256 _lunaCashbackAmount,
    address _buyer,  
    address indexed _owner
  );

  event ReferralRewarded(
    address indexed _referrer,
    uint256 _referralReward
  );

  event ReferralPercentageUpdated(
    address indexed _referrer,
    uint256 _percentage
  );

  address public daiAddress = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
  address public loomAddress = 0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0;

  uint256 public startedAt = 1548165600;  
  uint256 public endedAt = 1563804000;  

  mapping (uint8 => bool) public chestTypeEnabled;
  mapping (address => bool) public tokenEnabled;

  uint256 public savannahChestPrice = 0.05 ether;
  uint256 public forestChestPrice   = 0.16 ether;
  uint256 public arcticChestPrice   = 0.45 ether;
  uint256 public mysticChestPrice   = 1.00 ether;

  uint256 public initialDiscountPercentage = 1000;  
  uint256 public initialDiscountDays = 10 days;

  uint256 public cashbackPercentage = 1000;  

  uint256 public defaultReferralPercentage = 500;  
  mapping (address => uint256) public referralPercentage;

  IERC20 public lunaContract;
  address public lunaBankAddress;

  modifier whenInSale {
     
    require(now >= startedAt && now <= endedAt);
    _;
  }

  constructor(IERC20 _lunaContract, address _lunaBankAddress) public {
     
    _setCustomTokenRate(address(_lunaContract), daiAddress, 10**17);

    lunaContract = _lunaContract;
    lunaBankAddress = _lunaBankAddress;

    enableChestType(ChestType.Savannah, true);
    enableChestType(ChestType.Forest, true);
    enableChestType(ChestType.Arctic, true);
    enableChestType(ChestType.Mystic, true);

    enableToken(ethAddress, true);
    enableToken(daiAddress, true);
    enableToken(address(lunaContract), true);
  }

  function getPrice(
    ChestType _chestType,
    uint256 _chestAmount,
    address _tokenAddress
  )
    external
    view
    returns (
      uint256 _tokenAmount,
      uint256 _minConversionRate
    )
  {
    uint256 _totalPrice = _getEthPrice(_chestType, _chestAmount, _tokenAddress);

    if (_tokenAddress != ethAddress) {
      (_tokenAmount, ) = _convertToken(ethAddress, _totalPrice, _tokenAddress);
      (, _minConversionRate) = _getConversionRate(_tokenAddress, _tokenAmount, ethAddress);
      _tokenAmount = _totalPrice.mul(10**36).ceilingDiv(_minConversionRate);
      _tokenAmount = _fixTokenDecimals(ethAddress, _tokenAddress, _tokenAmount, true);
    } else {
      _tokenAmount = _totalPrice;
    }
  }

  function purchase(
    ChestType _chestType,
    uint256 _chestAmount,
    address _tokenAddress,
    uint256 _maxTokenAmount,
    uint256 _minConversionRate,
    address payable _referrer
  )
    external
    payable
    whenInSale
    whenNotPaused
  {
    _purchase(
      _chestType,
      _chestAmount,
      _tokenAddress,
      _maxTokenAmount,
      _minConversionRate,
      msg.sender,
      msg.sender,
      _referrer
    );
  }

  function purchaseFor(
    ChestType _chestType,
    uint256 _chestAmount,
    address _tokenAddress,
    uint256 _maxTokenAmount,
    uint256 _minConversionRate,
    address _owner
  )
    external
    payable
    whenInSale
    whenNotPaused
  {
    _purchase(
      _chestType,
      _chestAmount,
      _tokenAddress,
      _maxTokenAmount,
      _minConversionRate,
      msg.sender,
      _owner,
      msg.sender
    );
  }

  function receiveApproval(
    address _from,
    uint256 _value,
    address _tokenAddress,
    bytes calldata  
  )
    external
    whenInSale
    whenNotPaused
  {
    require(msg.sender == _tokenAddress);

    uint256 _action;
    ChestType _chestType;
    uint256 _chestAmount;
    uint256 _minConversionRate;
    address payable _referrerOrOwner;

     
    assembly {
      _action := calldataload(0xa4)
      _chestType := calldataload(0xc4)
      _chestAmount := calldataload(0xe4)
      _minConversionRate := calldataload(0x104)
      _referrerOrOwner := calldataload(0x124)
    }

    address payable _buyer;
    address _owner;
    address payable _referrer;

    if (_action == 0) {  
      _buyer = _from.toPayable();
      _owner = _from;
      _referrer = _referrerOrOwner;
    } else if (_action == 1) {  
      _buyer = _from.toPayable();
      _owner = _referrerOrOwner;
      _referrer = _from.toPayable();
    } else {
      revert();
    }

    _purchase(
      _chestType,
      _chestAmount,
      _tokenAddress,
      _value,
      _minConversionRate,
      _buyer,
      _owner,
      _referrer
    );
  }

  function setReferralPercentages(address[] calldata _referrers, uint256[] calldata _percentage) external onlyAdmin {
    for (uint256 i = 0; i < _referrers.length; i++) {
      referralPercentage[_referrers[i]] = _percentage[i];
      emit ReferralPercentageUpdated(_referrers[i], _percentage[i]);
    }
  }

  function setCustomTokenRates(address[] memory _tokenAddresses, Rate[] memory _rates) public onlyAdmin {
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      _setCustomTokenRate(_tokenAddresses[i], _rates[i].quote, _rates[i].value);
    }
  }

  function enableChestType(ChestType _chestType, bool _enabled) public onlyAdmin {
    chestTypeEnabled[uint8(_chestType)] = _enabled;
  }

  function enableToken(address _tokenAddress, bool _enabled) public onlyAdmin {
    tokenEnabled[_tokenAddress] = _enabled;
  }

  function _getPresentPercentage() internal view returns (uint256 _percentage) {
     
    uint256 _elapsedDays = (now - startedAt).div(1 days).mul(1 days);

    return uint256(10000)  
      .sub(initialDiscountPercentage)
      .add(
        initialDiscountPercentage
          .mul(Math.min(_elapsedDays, initialDiscountDays))
          .div(initialDiscountDays)
      );
  }

  function _getEthPrice(
    ChestType _chestType,
    uint256 _chestAmount,
    address _tokenAddress
  )
    internal
    view
    returns (uint256 _price)
  {
     
         if (_chestType == ChestType.Savannah) { _price = savannahChestPrice; }  
    else if (_chestType == ChestType.Forest  ) { _price = forestChestPrice;   }  
    else if (_chestType == ChestType.Arctic  ) { _price = arcticChestPrice;   }  
    else if (_chestType == ChestType.Mystic  ) { _price = mysticChestPrice;   }  
    else { revert(); }  

    _price = _price
      .mul(_getPresentPercentage())
      .div(10000)
      .mul(_chestAmount);

    if (_tokenAddress == address(lunaContract)) {
      _price = _price
        .mul(uint256(10000).sub(cashbackPercentage))
        .ceilingDiv(10000);
    }
  }

  function _getLunaCashbackAmount(
    uint256 _ethPrice,
    address _tokenAddress
  )
    internal
    view
    returns (uint256 _lunaCashbackAmount)
  {
    if (_tokenAddress != address(lunaContract)) {
      (uint256 _lunaPrice, ) = _convertToken(ethAddress, _ethPrice, address(lunaContract));

      return _lunaPrice
        .mul(cashbackPercentage)
        .div(uint256(10000));
    }
  }

  function _getReferralPercentage(address _referrer, address _owner) internal view returns (uint256 _percentage) {
    return _referrer != _owner && _referrer != address(0)
      ? Math.max(referralPercentage[_referrer], defaultReferralPercentage)
      : 0;
  }

  function _purchase(
    ChestType _chestType,
    uint256 _chestAmount,
    address _tokenAddress,
    uint256 _maxTokenAmount,
    uint256 _minConversionRate,
    address payable _buyer,
    address _owner,
    address payable _referrer
  )
    internal
  {
    require(chestTypeEnabled[uint8(_chestType)]);
    require(tokenEnabled[_tokenAddress]);

    require(_tokenAddress == ethAddress ? msg.value >= _maxTokenAmount : msg.value == 0);

    uint256 _totalPrice = _getEthPrice(_chestType, _chestAmount, _tokenAddress);
    uint256 _lunaCashbackAmount = _getLunaCashbackAmount(_totalPrice, _tokenAddress);

    uint256 _tokenAmount;
    uint256 _ethAmount;

    if (_tokenAddress != ethAddress) {
      (_tokenAmount, _ethAmount) = _swapToken(
        _tokenAddress,
        _maxTokenAmount,
        ethAddress,
        _totalPrice,
        _minConversionRate,
        _buyer,
        address(this)
      );
    } else {
       
      require(_maxTokenAmount >= _totalPrice);

       
      require(_minConversionRate == 0);

      _tokenAmount = _totalPrice;
      _ethAmount = msg.value;
    }

     
    require(_ethAmount >= _totalPrice);

     
    if (_ethAmount > _totalPrice) {
      _buyer.transfer(_ethAmount - _totalPrice);
    }

    emit ChestPurchased(
      _chestType,
      _chestAmount,
      _tokenAddress,
      _tokenAmount,
      _totalPrice,
      _lunaCashbackAmount,
      _buyer,
      _owner
    );

    if (_tokenAddress != address(lunaContract)) {
       
      require(lunaContract.transferFrom(lunaBankAddress, _owner, _lunaCashbackAmount));
    }

    if (!_hasCustomTokenRate(_tokenAddress)) {
      uint256 _referralReward = _totalPrice
        .mul(_getReferralPercentage(_referrer, _owner))
        .div(10000);

       
       
      if (_referralReward > 0 && !_referrer.send(_referralReward)) {
        _referralReward = 0;
      }

      if (_referralReward > 0) {
        emit ReferralRewarded(_referrer, _referralReward);
      }
    }
  }
}