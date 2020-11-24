 

pragma solidity ^0.4.23;

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract PriceUpdaterInterface {
  enum Currency { ETH, BTC, WME, WMZ, WMR, WMX }

  uint public decimalPrecision = 3;

  mapping(uint => uint) public price;
}

contract CrowdsaleInterface {
  uint public rate;
  uint public minimumAmount;

  function externalBuyToken(address _beneficiary, PriceUpdaterInterface.Currency _currency, uint _amount, uint _tokens) external;
}

contract MerchantControllerInterface {
  mapping(uint => uint) public totalInvested;
  mapping(uint => bool) public paymentId;

  function calcPrice(PriceUpdaterInterface.Currency _currency, uint _tokens) public view returns(uint);
  function buyTokens(address _beneficiary, PriceUpdaterInterface.Currency _currency, uint _amount, uint _tokens, uint _paymentId) external;
}

contract MerchantController is MerchantControllerInterface, ReentrancyGuard, Ownable {
  using SafeMath for uint;

  PriceUpdaterInterface public priceUpdater;
  CrowdsaleInterface public crowdsale;

  constructor(PriceUpdaterInterface _priceUpdater, CrowdsaleInterface _crowdsale) public  {
    priceUpdater = _priceUpdater;
    crowdsale = _crowdsale;
  }

  function calcPrice(PriceUpdaterInterface.Currency _currency, uint _tokens) 
      public 
      view 
      returns(uint) 
  {
    uint priceInWei = _tokens.mul(1 ether).div(crowdsale.rate());
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      return priceInWei;
    }
    uint etherPrice = priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH));
    uint priceInEur = priceInWei.mul(etherPrice).div(1 ether);

    uint currencyPrice = priceUpdater.price(uint(_currency));
    uint tokensPrice = priceInEur.mul(currencyPrice);
    
    return tokensPrice;
  }

  function buyTokens(
    address _beneficiary,
    PriceUpdaterInterface.Currency _currency,
    uint _amount,
    uint _tokens,
    uint _paymentId)
      external
      onlyOwner
      nonReentrant
  {
    require(_beneficiary != address(0));
    require(_currency != PriceUpdaterInterface.Currency.ETH);
    require(_amount != 0);
    require(_tokens >= crowdsale.minimumAmount());
    require(_paymentId != 0);
    require(!paymentId[_paymentId]);
    paymentId[_paymentId] = true;
    crowdsale.externalBuyToken(_beneficiary, _currency, _amount, _tokens);
  }
}