 

pragma solidity ^0.4.21;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract Subscription is Ownable {
  uint256 constant UINT256_MAX = ~uint256(0);
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public subscriptionRate;

  uint public fee;

  uint256 lastAppId;

  struct Pricing {
    uint256 day;
    uint256 price;
  }

  struct Application {
     
    uint256 appId;

     
    bytes32 appName;

     
    address beneficiary;

     
    address owner;

     
    mapping(uint256 => uint256) subscriptionExpiration;

    Pricing[] prices;
  }

  mapping(uint256 => Application) public applications;

   
  event SubscriptionPurchase(
    address indexed purchaser,
    uint256 indexed _appId,
    uint256 indexed userId,
    uint256 day,
    uint256 amount,
    uint256 expiration
  );

  event Registration(
    address indexed creator,
    uint256 _appId,
    bytes32 _appName,
    uint256 _price,
    address _beneficiary
  );

  function Subscription(
    uint _fee,
    address _fundWallet,
    ERC20 _token) public
  {
    require(_token != address(0));
    require(_fundWallet != address(0));
    require(_fee > 0);
    token = _token;
    wallet = _fundWallet;
    fee = _fee;
    lastAppId = 0;
  }

  function renewSubscriptionByDays(uint256 _appId, uint256 _userId, uint _day) external {
    Application storage app = applications[_appId];
    require(app.appId == _appId);
    require(_day >= 1);
    uint256 amount = getPrice(_appId, _day);
    require(amount > 0);

    uint256 currentExpiration = app.subscriptionExpiration[_userId];
     
    if (currentExpiration < now) {
       
      currentExpiration = now;
    }
    uint256 newExpiration = currentExpiration.add(_day.mul(1 days));
    app.subscriptionExpiration[_userId] = newExpiration;
    uint256 txFee = processFee(amount);
    uint256 toAppOwner = amount.sub(txFee);
    require(token.transferFrom(msg.sender, app.beneficiary, toAppOwner));
    emit SubscriptionPurchase(
      msg.sender,
      _appId,
      _userId,
      _day,
      amount,
      newExpiration);
  }

  function registration(
    bytes32 _appName,
    uint256 _price,
    address _beneficiary)
  external
  {
    require(_appName != "");
    require(_price > 0);
    require(_beneficiary != address(0));
    lastAppId = lastAppId.add(1);
    Application storage app = applications[lastAppId];
    app.appId = lastAppId;
    app.appName = _appName;
    app.beneficiary = _beneficiary;
    app.owner = msg.sender;
    app.prices.push(Pricing({
      day : 1,
      price : _price
      }));
    emit Registration(
      msg.sender,
      lastAppId,
      _appName,
      _price,
      _beneficiary);
  }

  function setPrice(uint256 _appId, uint256[] _days, uint256[] _prices) external {
    Application storage app = applications[_appId];
    require(app.owner == msg.sender);
    app.prices.length = 0;
    for (uint i = 0; i < _days.length; i++) {
      require(_days[i] > 0);
      require(_prices[i] > 0);
      app.prices.push(Pricing({
        day : _days[i],
        price : _prices[i]
        }));
    }
  }

   
  function setFee(uint _fee) external onlyOwner {
    fee = _fee;
  }

  function getExpiration(uint256 _appId, uint256 _userId) public view returns (uint256) {
    Application storage app = applications[_appId];
    return app.subscriptionExpiration[_userId];
  }

  function getPrice(uint256 _appId, uint256 _day) public view returns (uint256) {
    Application storage app = applications[_appId];
    uint256 amount = UINT256_MAX;
    for (uint i = 0; i < app.prices.length; i++) {
      if (_day == app.prices[i].day) {
        amount = app.prices[i].price;
        return amount;
      } else if (_day > app.prices[i].day) {
        uint256 rate = app.prices[i].price.div(app.prices[i].day);
        uint256 amountInPrice = _day.mul(rate);
        if (amountInPrice < amount) {
          amount = amountInPrice;
        }
      }
    }
    if (amount == UINT256_MAX) {
      amount = 0;
    }
    return amount;
  }

  function processFee(uint256 _weiAmount) internal returns (uint256) {
    uint256 txFee = _weiAmount.mul(fee).div(100);
    require(token.transferFrom(msg.sender, wallet, txFee));
    return txFee;
  }
}