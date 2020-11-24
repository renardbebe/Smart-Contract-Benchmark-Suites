 

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

contract BablosCrowdsaleWallet is BablosCrowdsaleWalletInterface, Ownable, ReentrancyGuard {
  using SafeMath for uint;

  modifier requiresState(State _state) {
    require(state == _state);
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }
  
  constructor(
    BablosTokenInterface _token, 
    address _controller, 
    PriceUpdaterInterface _priceUpdater, 
    uint _teamPercent, 
    uint _prTokens) 
      public 
  {
    token = _token;
    controller = _controller;
    priceUpdater = _priceUpdater;
    teamPercent = _teamPercent;
    prTokens = _prTokens;
  }

  function getTotalInvestedEther() external view returns (uint) {
    uint etherPrice = priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH));
    uint totalInvestedEth = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)];
    uint totalAmount = _totalInvestedNonEther();
    return totalAmount.mul(1 ether).div(etherPrice).add(totalInvestedEth);
  }

  function getTotalInvestedEur() external view returns (uint) {
    uint totalAmount = _totalInvestedNonEther();
    uint etherAmount = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)]
      .mul(priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH)))
      .div(1 ether);
    return totalAmount.add(etherAmount);
  }

   
  function _totalInvestedNonEther() internal view returns (uint) {
    uint totalAmount;
    uint precision = priceUpdater.decimalPrecision();
     
    uint btcAmount = totalInvested[uint(PriceUpdaterInterface.Currency.BTC)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.BTC)));
    totalAmount = totalAmount.add(btcAmount);
     
    uint wmeAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WME)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WME)));
    totalAmount = totalAmount.add(wmeAmount);
     
    uint wmzAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMZ)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMZ)));
    totalAmount = totalAmount.add(wmzAmount);
     
    uint wmrAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMR)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMR)));
    totalAmount = totalAmount.add(wmrAmount);
     
    uint wmxAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMX)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMX)));
    totalAmount = totalAmount.add(wmxAmount);
    return totalAmount;
  }

  function changeState(State _newState) external onlyController {
    assert(state != _newState);

    if (State.GATHERING == state) {
      assert(_newState == State.REFUNDING || _newState == State.SUCCEEDED);
    } else {
      assert(false);
    }

    state = _newState;
    emit StateChanged(state);
  }

  function invested(
    address _investor,
    uint _tokenAmount,
    PriceUpdaterInterface.Currency _currency,
    uint _amount) 
      external 
      payable
      onlyController
  {
    require(state == State.GATHERING || state == State.SUCCEEDED);
    uint amount;
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      amount = msg.value;
      weiBalances[_investor] = weiBalances[_investor].add(amount);
    } else {
      amount = _amount;
    }
    require(amount != 0);
    require(_tokenAmount != 0);
    assert(_investor != controller);

     
    if (tokenBalances[_investor] == 0) {
      investors.push(_investor);
    }

     
    totalInvested[uint(_currency)] = totalInvested[uint(_currency)].add(amount);
    tokenBalances[_investor] = tokenBalances[_investor].add(_tokenAmount);

    emit Invested(_investor, _currency, amount, _tokenAmount);
  }

  function withdrawEther(uint _value)
    external
    onlyOwner
    requiresState(State.SUCCEEDED) 
  {
    require(_value > 0 && address(this).balance >= _value);
    owner.transfer(_value);
    emit EtherWithdrawan(owner, _value);
  }

  function withdrawTokens(uint _value)
    external
    onlyOwner
    requiresState(State.REFUNDING)
  {
    require(_value > 0 && token.balanceOf(address(this)) >= _value);
    token.transfer(owner, _value);
  }

  function withdrawPayments()
    external
    nonReentrant
    requiresState(State.REFUNDING)
  {
    address payee = msg.sender;
    uint payment = weiBalances[payee];
    uint tokens = tokenBalances[payee];

     
    require(payment != 0);
     
    require(address(this).balance >= payment);
     
    require(token.allowance(payee, address(this)) >= tokenBalances[payee]);

    totalInvested[uint(PriceUpdaterInterface.Currency.ETH)] = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)].sub(payment);
    weiBalances[payee] = 0;
    tokenBalances[payee] = 0;

    token.transferFrom(payee, address(this), tokens);

    payee.transfer(payment);
    emit RefundSent(payee, payment);
  }

  function getInvestorsCount() external view returns (uint) { return investors.length; }

  function detachController() external onlyController {
    address was = controller;
    controller = address(0);
    emit ControllerRetired(was);
  }

  function unholdTeamTokens() external onlyController {
    uint tokens = token.balanceOf(address(this));
    if (state == State.SUCCEEDED) {
      uint soldTokens = token.totalSupply().sub(token.balanceOf(address(this))).sub(prTokens);
      uint soldPecent = 100 - teamPercent;
      uint teamShares = soldTokens.mul(teamPercent).div(soldPecent).sub(prTokens);
      token.transfer(owner, teamShares);
      token.burn(token.balanceOf(address(this)));
    } else {
      token.approve(owner, tokens);
    }
  }
}