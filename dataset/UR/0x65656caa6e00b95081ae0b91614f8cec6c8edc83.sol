 

pragma solidity ^0.4.23;

 
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

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BablosTokenInterface is ERC20 {
  bool public frozen;
  function burn(uint256 _value) public;
  function setSale(address _sale) public;
  function thaw() external;
}

contract PriceUpdaterInterface {
  enum Currency { ETH, BTC, WME, WMZ, WMR, WMX }

  uint public decimalPrecision = 3;

  mapping(uint => uint) public price;
}

contract BablosCrowdsaleWalletInterface {
  enum State {
     
    GATHERING,
     
    REFUNDING,
     
    SUCCEEDED
  }

  event StateChanged(State state);
  event Invested(address indexed investor, PriceUpdaterInterface.Currency currency, uint amount, uint tokensReceived);
  event EtherWithdrawan(address indexed to, uint value);
  event RefundSent(address indexed to, uint value);
  event ControllerRetired(address was);

   
  PriceUpdaterInterface public priceUpdater;

   
  mapping(uint => uint) public totalInvested;

   
  State public state = State.GATHERING;

   
  mapping(address => uint) public weiBalances;

   
  mapping(address => uint) public tokenBalances;

   
  address[] public investors;

   
  BablosTokenInterface public token;

   
  address public controller;

   
  uint public teamPercent;

   
  uint public prTokens;
  
   
  function changeState(State _newState) external;

   
   
   
   
   
  function invested(address _investor, uint _tokenAmount, PriceUpdaterInterface.Currency _currency, uint _amount) external payable;

   
  function getTotalInvestedEther() external view returns (uint);

   
  function getTotalInvestedEur() external view returns (uint);

   
   
  function withdrawEther(uint _value) external;

   
   
   
  function withdrawTokens(uint _value) external;

   
   
  function withdrawPayments() external;

   
  function getInvestorsCount() external view returns (uint);

   
  function detachController() external;

   
  function unholdTeamTokens() external;
}

contract BablosCrowdsale is ReentrancyGuard, Ownable {
  using SafeMath for uint;

  enum SaleState { INIT, ACTIVE, PAUSED, SOFT_CAP_REACHED, FAILED, SUCCEEDED }

  SaleState public state = SaleState.INIT;

   
  BablosTokenInterface public token;

   
  BablosCrowdsaleWalletInterface public wallet;

   
  uint public rate;

  uint public openingTime;
  uint public closingTime;

  uint public tokensSold;
  uint public tokensSoldExternal;

  uint public softCap;
  uint public hardCap;
  uint public minimumAmount;

  address public controller;
  PriceUpdaterInterface public priceUpdater;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint currency,
    uint value,
    uint amount
  );

  event StateChanged(SaleState _state);
  event FundTransfer(address _backer, uint _amount);

   

  modifier requiresState(SaleState _state) {
    require(state == _state);
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

   
   
   
   
   
  modifier timedStateChange(address _client, uint _payment, PriceUpdaterInterface.Currency _currency) {
    if (SaleState.INIT == state && getTime() >= openingTime) {
      changeState(SaleState.ACTIVE);
    }

    if ((state == SaleState.ACTIVE || state == SaleState.SOFT_CAP_REACHED) && getTime() >= closingTime) {
      finishSale();

      if (_currency == PriceUpdaterInterface.Currency.ETH && _payment > 0) {
        _client.transfer(_payment);
      }
    } else {
      _;
    }
  }

  constructor(
    uint _rate, 
    BablosTokenInterface _token,
    uint _openingTime, 
    uint _closingTime, 
    uint _softCap,
    uint _hardCap,
    uint _minimumAmount) 
    public
  {
    require(_rate > 0);
    require(_token != address(0));
    require(_openingTime >= getTime());
    require(_closingTime > _openingTime);
    require(_softCap > 0);
    require(_hardCap > 0);

    rate = _rate;
    token = _token;
    openingTime = _openingTime;
    closingTime = _closingTime;
    softCap = _softCap;
    hardCap = _hardCap;
    minimumAmount = _minimumAmount;
  }

  function setWallet(BablosCrowdsaleWalletInterface _wallet) external onlyOwner {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function setController(address _controller) external onlyOwner {
    require(_controller != address(0));
    controller = _controller;
  }

  function setPriceUpdater(PriceUpdaterInterface _priceUpdater) external onlyOwner {
    require(_priceUpdater != address(0));
    priceUpdater = _priceUpdater;
  }

  function isActive() public view returns (bool active) {
    return state == SaleState.ACTIVE || state == SaleState.SOFT_CAP_REACHED;
  }

   
  function () external payable {
    require(msg.data.length == 0);
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {
    uint weiAmount = msg.value;

    require(_beneficiary != address(0));
    require(weiAmount != 0);

     
    uint tokens = _getTokenAmount(weiAmount);

    require(tokens >= minimumAmount && token.balanceOf(address(this)) >= tokens);

    _internalBuy(_beneficiary, PriceUpdaterInterface.Currency.ETH, weiAmount, tokens);
  }

   
  function externalBuyToken(
    address _beneficiary, 
    PriceUpdaterInterface.Currency _currency, 
    uint _amount, 
    uint _tokens)
      external
      onlyController
  {
    require(_beneficiary != address(0));
    require(_tokens >= minimumAmount && token.balanceOf(address(this)) >= _tokens);
    require(_amount != 0);

    _internalBuy(_beneficiary, _currency, _amount, _tokens);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate).div(1 ether);
  }

  function _internalBuy(
    address _beneficiary, 
    PriceUpdaterInterface.Currency _currency, 
    uint _amount, 
    uint _tokens)
      internal
      nonReentrant
      timedStateChange(_beneficiary, _amount, _currency)
  {
    require(isActive());
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      tokensSold = tokensSold.add(_tokens);
    } else {
      tokensSoldExternal = tokensSoldExternal.add(_tokens);
    }
    token.transfer(_beneficiary, _tokens);

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      uint(_currency),
      _amount,
      _tokens
    );

    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      wallet.invested.value(_amount)(_beneficiary, _tokens, _currency, _amount);
      emit FundTransfer(_beneficiary, _amount);
    } else {
      wallet.invested(_beneficiary, _tokens, _currency, _amount);
    }
    
     
    if (state == SaleState.ACTIVE && wallet.getTotalInvestedEther() >= softCap) {
      changeState(SaleState.SOFT_CAP_REACHED);
    }

     
    if (token.balanceOf(address(this)) < minimumAmount) {
      finishSale();
    }

     
    if (state == SaleState.SOFT_CAP_REACHED && wallet.getTotalInvestedEur() >= hardCap) {
      finishSale();
    }
  }

  function finishSale() private {
    if (wallet.getTotalInvestedEther() < softCap) {
      changeState(SaleState.FAILED);
    } else {
      changeState(SaleState.SUCCEEDED);
    }
  }

   
  function changeState(SaleState _newState) private {
    require(state != _newState);

    if (SaleState.INIT == state) {
      assert(SaleState.ACTIVE == _newState);
    } else if (SaleState.ACTIVE == state) {
      assert(
        SaleState.PAUSED == _newState ||
        SaleState.SOFT_CAP_REACHED == _newState ||
        SaleState.FAILED == _newState ||
        SaleState.SUCCEEDED == _newState
      );
    } else if (SaleState.SOFT_CAP_REACHED == state) {
      assert(
        SaleState.PAUSED == _newState ||
        SaleState.SUCCEEDED == _newState
      );
    } else if (SaleState.PAUSED == state) {
      assert(SaleState.ACTIVE == _newState || SaleState.FAILED == _newState);
    } else {
      assert(false);
    }

    state = _newState;
    emit StateChanged(state);

    if (SaleState.SOFT_CAP_REACHED == state) {
      onSoftCapReached();
    } else if (SaleState.SUCCEEDED == state) {
      onSuccess();
    } else if (SaleState.FAILED == state) {
      onFailure();
    }
  }

  function onSoftCapReached() private {
    wallet.changeState(BablosCrowdsaleWalletInterface.State.SUCCEEDED);
  }

  function onSuccess() private {
     
    token.burn(token.balanceOf(address(this)));
    token.thaw();
    wallet.unholdTeamTokens();
    wallet.detachController();
  }

  function onFailure() private {
     
    wallet.changeState(BablosCrowdsaleWalletInterface.State.REFUNDING);
    wallet.unholdTeamTokens();
    wallet.detachController();
  }

   
  function getTime() internal view returns (uint) {
     
    return now;
  }

}