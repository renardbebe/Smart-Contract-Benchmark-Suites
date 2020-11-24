 

pragma solidity 0.4.21;

 
 
 
 
 
 
 
 
 
 
 

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
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
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
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
  event Refunded(address indexed _beneficiary, uint256 _weiAmount);

   
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address _contributor) onlyOwner public payable {
    require(state == State.Active);
    deposited[_contributor] = deposited[_contributor].add(msg.value); 
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address _contributor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[_contributor];
    require(depositedValue > 0);
    deposited[_contributor] = 0;
    _contributor.transfer(depositedValue);
    emit Refunded(_contributor, depositedValue);
  }
}

 
contract CutdownToken {
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

 
contract PICOPSCertifier {
    function certified(address) public constant returns (bool);
}

 
contract DigitizeCoinPresale is Ownable {
  using SafeMath for uint256;

   
  CutdownToken public token;
   
  PICOPSCertifier public picopsCertifier;
   
  RefundVault public vault;

   
  uint256 public startTime;
  uint256 public endTime;
  uint256 public softCap;
  bool public hardCapReached;

  mapping(address => bool) public whitelist;

   
  uint256 public constant rate = 6667;

   
  uint256 public weiRaised;

   
  mapping(address => uint256) public contributed;

   
  uint256 public constant minContribution = 0.1 ether;

   
  uint256 public constant maxAnonymousContribution = 5 ether;

   
  event TokenPurchase(address indexed _purchaser, uint256 _value, uint256 _tokens);
  event PicopsCertifierUpdated(address indexed _oldCertifier, address indexed _newCertifier);
  event AddedToWhitelist(address indexed _who);
  event RemovedFromWhitelist(address indexed _who);
  event WithdrawnERC20Tokens(address indexed _tokenContract, address indexed _owner, uint256 _balance);
  event WithdrawnEther(address indexed _owner, uint256 _balance);

   
  function DigitizeCoinPresale(uint256 _startTime, uint256 _durationInDays, 
    uint256 _softCap, address _wallet, CutdownToken _token, address _picops) public {
    bool validTimes = _startTime >= now && _durationInDays > 0;
    bool validAddresses = _wallet != address(0) && _token != address(0) && _picops != address(0);
    require(validTimes && validAddresses);

    owner = msg.sender;
    startTime = _startTime;
    endTime = _startTime + (_durationInDays * 1 days);
    softCap = _softCap;
    token = _token;
    vault = new RefundVault(_wallet);
    picopsCertifier = PICOPSCertifier(_picops);
  }

   
  function () external payable {
    require(validPurchase());

    address purchaser = msg.sender;
    uint256 weiAmount = msg.value;
    uint256 chargedWeiAmount = weiAmount;
    uint256 tokensAmount = weiAmount.mul(rate);
    uint256 tokensDue = tokensAmount;
    uint256 tokensLeft = token.balanceOf(address(this));

     
    if(tokensAmount > tokensLeft) {
      chargedWeiAmount = tokensLeft.div(rate);
      tokensDue = tokensLeft;
      hardCapReached = true;
    } else if(tokensAmount == tokensLeft) {
      hardCapReached = true;
    }

    weiRaised = weiRaised.add(chargedWeiAmount);
    contributed[purchaser] = contributed[purchaser].add(chargedWeiAmount);
    token.transfer(purchaser, tokensDue);

     
    if(chargedWeiAmount < weiAmount) {
      purchaser.transfer(weiAmount - chargedWeiAmount);
    }
    emit TokenPurchase(purchaser, chargedWeiAmount, tokensDue);

     
    vault.deposit.value(chargedWeiAmount)(purchaser);
  }

   
  function softCapReached() public view returns (bool) {
    return weiRaised >= softCap;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime || hardCapReached;
  }

  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }

   
  function claimRefund() public {
    require(hasEnded() && !softCapReached());

    vault.refund(msg.sender);
  }

   
  function finalize() public onlyOwner {
    require(hasEnded());

    if (softCapReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = hasStarted() && !hasEnded();
    bool validContribution = msg.value >= minContribution;
    bool passKyc = picopsCertifier.certified(msg.sender);
     
    bool anonymousAllowed = contributed[msg.sender].add(msg.value) < maxAnonymousContribution;
    bool allowedKyc = passKyc || anonymousAllowed;
    return withinPeriod && validContribution && allowedKyc;
  }

   
  function setPicopsCertifier(address _picopsCertifier) onlyOwner public  {
    require(_picopsCertifier != address(picopsCertifier));
    emit PicopsCertifierUpdated(address(picopsCertifier), _picopsCertifier);
    picopsCertifier = PICOPSCertifier(_picopsCertifier);
  }

  function passedKYC(address _wallet) view public returns (bool) {
    return picopsCertifier.certified(_wallet);
  }

   
  function addToWhitelist(address[] _wallets) public onlyOwner {
    for (uint i = 0; i < _wallets.length; i++) {
      whitelist[_wallets[i]] = true;
      emit AddedToWhitelist(_wallets[i]);
    }
  }

   
  function removeFromWhitelist(address[] _wallets) public onlyOwner {
    for (uint i = 0; i < _wallets.length; i++) {
      whitelist[_wallets[i]] = false;
      emit RemovedFromWhitelist(_wallets[i]);
    }
  }

   
  function withdrawEther() onlyOwner public {
    require(hasEnded());
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0);
    owner.transfer(totalBalance);
    emit WithdrawnEther(owner, totalBalance);
  }
  
   
  function withdrawERC20Tokens(CutdownToken _token) onlyOwner public {
    require(hasEnded());
    uint256 totalBalance = _token.balanceOf(address(this));
    require(totalBalance > 0);
    _token.transfer(owner, totalBalance);
    emit WithdrawnERC20Tokens(address(_token), owner, totalBalance);
  }
}