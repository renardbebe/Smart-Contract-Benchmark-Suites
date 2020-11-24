 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


contract PresaleFallbackReceiver {
  bool public presaleFallBackCalled;

  function presaleFallBack(uint256 _presaleWeiRaised) public returns (bool);
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






 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}




 
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




contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}










contract BTCPaymentI is Ownable, PresaleFallbackReceiver {
  PaymentFallbackReceiver public presale;
  PaymentFallbackReceiver public mainsale;

  function addPayment(address _beneficiary, uint256 _tokens) public;
  function setPresale(address _presale) external;
  function setMainsale(address _mainsale) external;
  function presaleFallBack(uint256) public returns (bool);
}


contract PaymentFallbackReceiver {
  BTCPaymentI public payment;

  enum SaleType { pre, main }

  function PaymentFallbackReceiver(address _payment) public {
    require(_payment != address(0));
    payment = BTCPaymentI(_payment);
  }

  modifier onlyPayment() {
    require(msg.sender == address(payment));
    _;
  }

  event MintByBTC(SaleType _saleType, address indexed _beneficiary, uint256 _tokens);

   
  function paymentFallBack(address _beneficiary, uint256 _tokens) external onlyPayment();
}






 
contract Sudo is Ownable {
  bool public sudoEnabled;

  modifier onlySudoEnabled() {
    require(sudoEnabled);
    _;
  }

  event SudoEnabled(bool _sudoEnabled);

  function Sudo(bool _sudoEnabled) public {
    sudoEnabled = _sudoEnabled;
  }

  function enableSudo(bool _sudoEnabled) public onlyOwner {
    sudoEnabled = _sudoEnabled;
    SudoEnabled(_sudoEnabled);
  }
}










 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract FXTI is ERC20 {
  bool public sudoEnabled = true;

  function transfer(address _to, uint256 _amount) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

  function generateTokens(address _owner, uint _amount) public returns (bool);

  function destroyTokens(address _owner, uint _amount) public returns (bool);

  function blockAddress(address _addr) public;

  function unblockAddress(address _addr) public;

  function enableSudo(bool _sudoEnabled) public;

  function enableTransfers(bool _transfersEnabled) public;

   

  function generateTokensByList(address[] _owners, uint[] _amounts) public returns (bool);
}





 
contract KYCI is Ownable {
  function setAdmin(address _addr, bool _value) public returns (bool);
  function isRegistered(address _addr, bool _isPresale) public returns (bool);
  function register(address _addr, bool _isPresale) public;
  function registerByList(address[] _addrs, bool _isPresale) public;
  function unregister(address _addr, bool _isPresale)public;
  function unregisterByList(address[] _addrs, bool _isPresale) public;
}


 
contract SaleBase is Sudo, Pausable, PaymentFallbackReceiver {
  using SafeMath for uint256;

   
  FXTI public token;
  KYCI public kyc;
  RefundVault public vault;

   
  address public fuzexAccount;

   
  mapping (address => uint256) public beneficiaryFunded;
  uint256 public weiRaised;

  bool public isFinalized;  

   
  modifier onlyNotFinalized() {
    require(!isFinalized);
    _;
  }

  function SaleBase(
    address _token,
    address _kyc,
    address _vault,
    address _payment,
    address _fuzexAccount)
    Sudo(false)  
    PaymentFallbackReceiver(_payment)
    public
  {
    require(_token != address(0)
     && _kyc != address(0)
     && _vault != address(0)
     && _fuzexAccount != address(0));

    token = FXTI(_token);
    kyc = KYCI(_kyc);
    vault = RefundVault(_vault);
    fuzexAccount = _fuzexAccount;
  }

   
  function increaseWeiRaised(uint256 _amount) public onlyOwner onlyNotFinalized onlySudoEnabled {
    weiRaised = weiRaised.add(_amount);
  }

  function decreaseWeiRaised(uint256 _amount) public onlyOwner onlyNotFinalized onlySudoEnabled {
    weiRaised = weiRaised.sub(_amount);
  }

  function generateTokens(address _owner, uint _amount) public onlyOwner onlyNotFinalized onlySudoEnabled returns (bool) {
    return token.generateTokens(_owner, _amount);
  }

  function destroyTokens(address _owner, uint _amount) public onlyOwner onlyNotFinalized onlySudoEnabled returns (bool) {
    return token.destroyTokens(_owner, _amount);
  }

   
  function blockAddress(address _addr) public onlyOwner onlyNotFinalized onlySudoEnabled {
    token.blockAddress(_addr);
  }

  function unblockAddress(address _addr) public onlyOwner onlyNotFinalized onlySudoEnabled {
    token.unblockAddress(_addr);
  }

   
  function changeOwnership(address _target, address _newOwner) public onlyOwner {
    Ownable(_target).transferOwnership(_newOwner);
  }

   
  function changeController(address _target, address _newOwner) public onlyOwner {
    Controlled(_target).changeController(_newOwner);
  }

  function setFinalize() internal onlyOwner {
    require(!isFinalized);
    isFinalized = true;
  }
}



 
contract FXTPresale is SaleBase {
  uint256 public baseRate = 12000;     
  uint256 public PRE_BONUS = 25;      
  uint256 public BONUS_COEFF = 100;

   
  uint256 public privateEtherFunded;
  uint256 public privateMaxEtherCap;

   
  uint256 public presaleMaxEtherCap;
  uint256 public presaleMinPurchase;

  uint256 public maxEtherCap;    

  uint64 public startTime;      
  uint64 public endTime;        

  event PresaleTokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 toFund, uint256 tokens);

   
  modifier onlyRegistered(address _addr) {
    require(kyc.isRegistered(_addr, true));
    _;
  }

  function FXTPresale(
    address _token,
    address _kyc,
    address _vault,
    address _payment,
    address _fuzexAccount,
    uint64 _startTime,
    uint64 _endTime,
    uint256 _privateEtherFunded,
    uint256 _privateMaxEtherCap,
    uint256 _presaleMaxEtherCap,
    uint256 _presaleMinPurchase)
    SaleBase(_token, _kyc, _vault, _payment, _fuzexAccount)
    public
  {
    require(now < _startTime && _startTime < _endTime);

    require(_privateEtherFunded >= 0);
    require(_privateMaxEtherCap > 0);
    require(_presaleMaxEtherCap > 0);
    require(_presaleMinPurchase > 0);

    require(_presaleMinPurchase < _presaleMaxEtherCap);

    startTime = _startTime;
    endTime = _endTime;

    privateEtherFunded = _privateEtherFunded;
    privateMaxEtherCap = _privateMaxEtherCap;

    presaleMaxEtherCap = _presaleMaxEtherCap;
    presaleMinPurchase = _presaleMinPurchase;

    maxEtherCap = privateMaxEtherCap.add(presaleMaxEtherCap);
    weiRaised = _privateEtherFunded;  

    require(weiRaised <= maxEtherCap);
  }

  function () external payable {
    buyPresale(msg.sender);
  }

   
  function paymentFallBack(address _beneficiary, uint256 _tokens)
    external
    onlyPayment
  {
     
    require(startTime <= now && now <= endTime);
    require(_beneficiary != address(0));
    require(_tokens > 0);

    uint256 rate = getRate();
    uint256 weiAmount = _tokens.div(rate);

    require(weiAmount >= presaleMinPurchase);

     
    require(weiRaised.add(weiAmount) <= maxEtherCap);

    weiRaised = weiRaised.add(weiAmount);
    beneficiaryFunded[_beneficiary] = beneficiaryFunded[_beneficiary].add(weiAmount);

    token.generateTokens(_beneficiary, _tokens);
    MintByBTC(SaleType.pre, _beneficiary, _tokens);
  }

  function buyPresale(address _beneficiary)
    public
    payable
    onlyRegistered(_beneficiary)
    whenNotPaused
  {
     
    require(_beneficiary != address(0));
    require(msg.value >= presaleMinPurchase);
    require(validPurchase());

    uint256 toFund;
    uint256 tokens;

    (toFund, tokens) = buy(_beneficiary);

    PresaleTokenPurchase(msg.sender, _beneficiary, toFund, tokens);
  }

  function buy(address _beneficiary)
    internal
    returns (uint256 toFund, uint256 tokens)
  {
     
    uint256 weiAmount = msg.value;
    uint256 totalAmount = weiRaised.add(weiAmount);

    if (totalAmount > maxEtherCap) {
      toFund = maxEtherCap.sub(weiRaised);
    } else {
      toFund = weiAmount;
    }

    require(toFund > 0);
    require(weiAmount >= toFund);

    uint256 rate = getRate();
    tokens = toFund.mul(rate);
    uint256 toReturn = weiAmount.sub(toFund);

    weiRaised = weiRaised.add(toFund);
    beneficiaryFunded[_beneficiary] = beneficiaryFunded[_beneficiary].add(toFund);

    token.generateTokens(_beneficiary, tokens);

    if (toReturn > 0) {
      msg.sender.transfer(toReturn);
    }

    forwardFunds(toFund);
  }

  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    bool validTime = now >= startTime && now <= endTime;
    return nonZeroPurchase && !maxReached() && validTime;
  }

   
  function getRate() public view returns (uint256) {
    return calcRate(PRE_BONUS);
  }

   
  function calcRate(uint256 _bonus) internal view returns (uint256) {
    return _bonus.add(BONUS_COEFF).mul(baseRate).div(BONUS_COEFF);
  }

   
  function maxReached() public view  returns (bool) {
    return weiRaised == maxEtherCap;
  }

  function forwardFunds(uint256 _toFund) internal {
    vault.deposit.value(_toFund)(msg.sender);
  }

  function finalizePresale(address _mainsale) public onlyOwner {
      require(!isFinalized);
      require(maxReached() || now > endTime);

      PresaleFallbackReceiver mainsale = PresaleFallbackReceiver(_mainsale);

      require(mainsale.presaleFallBack(weiRaised));
      require(payment.presaleFallBack(weiRaised));

      vault.close();

      changeController(address(token), _mainsale);
      changeOwnership(address(vault), fuzexAccount);

      enableSudo(false);
      setFinalize();
  }
}