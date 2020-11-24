 

pragma solidity 0.4.24;


 
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



contract BFEXMini is Ownable {

  using SafeMath for uint256;

   
  uint public startTime;
   

   
  address public wallet;
  address public feeWallet;

   
  bool public whitelistEnable;

   
  bool public timeLimitEnable;

  mapping (address => bool) public whitelist;
  mapping (address => uint256) public bfexAmount;  
  mapping (address => uint256) public weiParticipate;
  mapping (address => uint256) public balances;

   
  uint256 public weiRaised = 0;

   
  uint256 public rate;
  uint256 public rateSecondTier;

   
  uint256 public minimum;

   
  uint256 public contributor;

   
  uint256 public maxContributor;

  event BFEXParticipate(
    address sender,
    uint256 amount
  );

  event WhitelistState(
    address beneficiary,
    bool whitelistState
  );

  event LogWithdrawal(
    address receiver,
    uint amount
  );

   
  constructor(address _wallet, address _feeWallet, uint256 _rate, uint256 _rateSecondTier, uint256 _minimum) public {

    require(_wallet != address(0));

    wallet = _wallet;
    feeWallet = _feeWallet;
    rate = _rate;
    rateSecondTier = _rateSecondTier;
    minimum = _minimum;
    whitelistEnable = true;
    timeLimitEnable = true;
    contributor = 0;
    maxContributor = 10001;
    startTime = 1528625400;  
  }
   

   
  function() external payable {
    getBFEX(msg.sender);
  }

   
  function setRate(uint _rate) public onlyOwner {
    rate = _rate;
  }

   
  function setMinimum(uint256 _minimum) public onlyOwner {
    minimum = _minimum;
  }

   
  function setMaxContributor(uint256 _max) public onlyOwner {
    maxContributor = _max;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    emit WhitelistState(_beneficiary, true);
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhiteList(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    emit WhitelistState(_beneficiary, false);
  }

  function isWhitelist(address _beneficiary) public view returns (bool whitelisted) {
    return whitelist[_beneficiary];
  }

  function checkBenefit(address _beneficiary) public view returns (uint256 bfex) {
    return bfexAmount[_beneficiary];
  }

  function checkContribution(address _beneficiary) public view returns (uint256 weiContribute) {
    return weiParticipate[_beneficiary];
  }
   
  function getBFEX(address _participant) public payable {

    uint256 weiAmount = msg.value;

    _preApprove(_participant);
    require(_participant != address(0));
    require(weiAmount >= minimum);

     
    uint256 bfexToken = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);
     
    uint256 raise = weiAmount.div(1000).mul(955);
    uint256 fee = weiAmount.div(1000).mul(45);
     
    contributor += 1;

    balances[wallet] = balances[wallet].add(raise);
    balances[feeWallet] = balances[feeWallet].add(fee);

    bfexAmount[_participant] = bfexAmount[_participant].add(bfexToken);
    weiParticipate[_participant] = weiParticipate[_participant].add(weiAmount);

    emit BFEXParticipate(_participant, weiAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _rate;
    if (_weiAmount >= 0.1 ether && _weiAmount < 1 ether ) {
      _rate = rate;
    } else if (_weiAmount >= 1 ether ) {
      _rate = rateSecondTier;
    }
    uint256 bfex = _weiAmount.mul(_rate);
     
    return bfex;
  }

   
  function _preApprove(address _participant) internal view {
    require (maxContributor >= contributor);
    if (timeLimitEnable == true) {
      require (now >= startTime && now <= startTime + 1 days);
    }
    if (whitelistEnable == true) {
      require(isWhitelist(_participant));
      return;
    } else {
      return;
    }
  }

   
  function disableWhitelist() public onlyOwner returns (bool whitelistState) {
    whitelistEnable = false;
    emit WhitelistState(msg.sender, whitelistEnable);
    return whitelistEnable;
  }

   
  function enableWhitelist() public onlyOwner returns (bool whitelistState) {
    whitelistEnable = true;
    emit WhitelistState(msg.sender, whitelistEnable);
    return whitelistEnable;
  }

  function withdraw(uint _value) public returns (bool success) {
    require(balances[msg.sender] <= _value);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    msg.sender.transfer(_value);
    emit LogWithdrawal(msg.sender, _value);

    return true;
  }

  function checkBalance(address _account) public view returns (uint256 balance)  {
    return balances[_account];
  }
}