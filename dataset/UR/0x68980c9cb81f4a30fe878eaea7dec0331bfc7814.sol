 

pragma solidity 0.4.25;

 
contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Auth {
  address internal backupAdmin;
  address internal mainAdmin;
  address internal contractAdmin;
  address internal dabAdmin;
  address internal gemAdmin;
  address internal LAdmin;

  constructor(
    address _backupAdmin,
    address _mainAdmin,
    address _contractAdmin,
    address _dabAdmin,
    address _gemAdmin,
    address _LAdmin
  )
  internal
  {
    backupAdmin = _backupAdmin;
    mainAdmin = _mainAdmin;
    contractAdmin = _contractAdmin;
    dabAdmin = _dabAdmin;
    gemAdmin = _gemAdmin;
    LAdmin = _LAdmin;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), "onlyBackupAdmin");
    _;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyBackupOrMainAdmin() {
    require(isMainAdmin() || isBackupAdmin(), "onlyBackupOrMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(isContractAdmin() || isMainAdmin(), "onlyContractAdmin");
    _;
  }

  modifier onlyLAdmin() {
    require(isLAdmin() || isMainAdmin(), "onlyLAdmin");
    _;
  }

  modifier onlyDABAdmin() {
    require(isDABAdmin() || isMainAdmin(), "onlyDABAdmin");
    _;
  }

  modifier onlyGEMAdmin() {
    require(isGEMAdmin() || isMainAdmin(), "onlyGEMAdmin");
    _;
  }

  function isBackupAdmin() public view returns (bool) {
    return msg.sender == backupAdmin;
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }

  function isLAdmin() public view returns (bool) {
    return msg.sender == LAdmin;
  }

  function isDABAdmin() public view returns (bool) {
    return msg.sender == dabAdmin;
  }

  function isGEMAdmin() public view returns (bool) {
    return msg.sender == gemAdmin;
  }
}

interface IContractNo2 {
  function adminCommission(uint _amount) external;

  function deposit(
    address _user,
    uint8 _type,
    uint packageAmount,
    uint _dabAmount,
    uint _gemAmount
  ) external;

  function getProfit(address _user, uint _stakingBalance) external returns (uint, uint);

  function getWithdraw(address _user, uint _stakingBalance, uint8 _type) external returns (uint, uint);

  function validateJoinPackage(
    address _user,
    address _to,
    uint8 _type,
    uint _dabAmount,
    uint _gemAmount
  ) external returns (bool);
}

interface IContractNo3 {

  function isCitizen(address _user) view external returns (bool);

  function register(address _user, string _userName, address _inviter) external returns (uint);

  function addF1M9DepositedToInviter(address _invitee, uint _amount) external;

  function checkInvestorsInTheSameReferralTree(address _inviter, address _invitee) external view returns (bool);

  function increaseInviterF1HaveJoinedPackage(address _invitee) external;

  function increaseInviterF1HaveJoinedM9Package(address _invitee) external;

  function addNetworkDepositedToInviter(address _inviter, uint _dabAmount, uint _gemAmount) external;

  function getF1M9Deposited(address _investor) external view returns (uint);

  function getDirectlyInviteeHaveJoinedM9Package(address _investor) external view returns (address[]);

  function getRank(address _investor) external view returns (uint8);

  function getInviter(address _investor) external view returns (address);

  function showInvestorInfo(address _investorAddress) external view returns (uint, string memory, address, address[],  address[],  address[], uint, uint, uint, uint, uint);
}

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul error');

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, 'SafeMath div error');
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub error');
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add error');

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath mod error');
    return a % b;
  }
}

contract ContractNo1 is Auth {
  using SafeMath for uint;

  enum PackageType {
    M0,
    M3,
    M6,
    M9,
    M12,
    M15,
    M18
  }

  enum WithdrawType {
    Half,
    Full
  }

  mapping(address => bool) public lAS;
  IERC20 public dabToken = IERC20(0x5E7Ebea68ab05198F771d77a875480314f1d0aae);
  IContractNo2 public contractNo2;
  IContractNo3 public contractNo3;

  uint public minJP = 5e18;
  uint8 public gemJPPercent = 30;

  event Registered(uint id, string userName, address userAddress, address inviter);
  event PackageJoined(address indexed from, address indexed to, PackageType packageType, uint dabAmount, uint gemAmount);
  event Profited(address indexed user, uint dabAmount, uint gemAmount);
  event Withdrew(address indexed user, uint dabAmount, uint gemAmount);

  constructor(
    address _backupAdmin,
    address _mainAdmin,
    address _dabAdmin,
    address _LAdmin
  )
  public
  Auth(
    _backupAdmin,
    _mainAdmin,
    msg.sender,
    _dabAdmin,
    address(0x0),
    _LAdmin
  ) {
  }

   

  function setC(address _c) onlyContractAdmin public {
    contractNo3 = IContractNo3(_c);
  }

  function setW(address _w) onlyContractAdmin public {
    contractNo2 = IContractNo2(_w);
  }

  function updateBackupAdmin(address _newBackupAdmin) onlyBackupAdmin public {
    require(_newBackupAdmin != address(0x0), 'Invalid address');
    backupAdmin = _newBackupAdmin;
  }

  function updateMainAdmin(address _newMainAdmin) onlyBackupOrMainAdmin public {
    require(_newMainAdmin != address(0x0), 'Invalid address');
    mainAdmin = _newMainAdmin;
  }

  function updateContractAdmin(address _newContractAdmin) onlyMainAdmin public {
    require(_newContractAdmin != address(0x0), 'Invalid address');
    contractAdmin = _newContractAdmin;
  }

  function updateDABAdmin(address _newDABAdmin) onlyMainAdmin public {
    require(_newDABAdmin != address(0x0), 'Invalid address');
    dabAdmin = _newDABAdmin;
  }

  function updateLockerAdmin(address _newLockerAdmin) onlyMainAdmin public {
    require(_newLockerAdmin != address(0x0), 'Invalid address');
    LAdmin = _newLockerAdmin;
  }

  function LA(address[] _values, bool _locked) onlyLAdmin public {
    require(_values.length > 0, 'Values cannot be empty');
    require(_values.length <= 256, 'Maximum is 256');
    for (uint8 i = 0; i < _values.length; i++) {
      require(_values[i] != msg.sender, 'Yourself!!!');
      lAS[_values[i]] = _locked;
    }
  }

  function setMinJP(uint _minJP) onlyMainAdmin public {
    require(_minJP > 0, 'Must be > 0');
    minJP = _minJP;
  }

  function setGemJP(uint8 _gemJPPercent) onlyMainAdmin public {
    require(0 < _gemJPPercent && _gemJPPercent < 101, 'Must be 1 - 100');
    gemJPPercent = _gemJPPercent;
  }

   

  function register(string memory _userName, address _inviter) public {
    require(contractNo3.isCitizen(_inviter), 'Inviter did not registered');
    require(_inviter != msg.sender, 'Cannot referral yourself');
    uint id = contractNo3.register(msg.sender, _userName, _inviter);
    emit Registered(id, _userName, msg.sender, _inviter);
  }

  function showMe() public view returns (uint, string memory, address, address[], address[], address[], uint, uint, uint, uint, uint) {
    return contractNo3.showInvestorInfo(msg.sender);
  }

  function joinPackage(address _to, PackageType _type, uint _dabAmount, uint _gemAmount) public {
    uint packageAmount = _dabAmount.add(_gemAmount);
    validateJoinPackage(msg.sender, _to, _type, _dabAmount, _gemAmount);
    require(packageAmount >= minJP, 'Package amount must be greater min');
    require(dabToken.allowance(msg.sender, address(this)) >= _dabAmount, 'Please call approve() first');
    require(dabToken.balanceOf(msg.sender) >= _dabAmount, 'You have not enough funds');
    if (_gemAmount > 0) {
      uint8 gemPercent = uint8(_gemAmount.mul(100).div(packageAmount));
      require(gemPercent <= gemJPPercent, 'Too much GEM');
      contractNo2.adminCommission(_gemAmount.div(5));
    }

    require(dabToken.transferFrom(msg.sender, address(this), _dabAmount), 'Transfer token to contract failed');

    contractNo2.deposit(_to, uint8(_type), packageAmount, _dabAmount, _gemAmount);

    require(dabToken.transfer(dabAdmin, _dabAmount.div(5)), 'Transfer token to admin failed');

    emit PackageJoined(msg.sender, _to, _type, _dabAmount, _gemAmount);
  }

  function profit() public {
    require(!lAS[msg.sender], 'You can\'t do this now');
    uint dabProfit;
    uint gemProfit;
    (dabProfit, gemProfit) = contractNo2.getProfit(msg.sender, dabToken.balanceOf(address(this)));
    require(dabToken.transfer(msg.sender, dabProfit), 'Transfer profit to user failed');
    emit Profited(msg.sender, dabProfit, gemProfit);
  }

  function withdraw(WithdrawType _type) public {
    require(!lAS[msg.sender], 'You can\'t do this now');
    uint dabWithdrawable;
    uint gemWithdrawable;
    (dabWithdrawable, gemWithdrawable) = contractNo2.getWithdraw(msg.sender, dabToken.balanceOf(address(this)), uint8(_type));
    require(dabToken.transfer(msg.sender, dabWithdrawable), 'Transfer token to user failed');
    emit Withdrew(msg.sender, dabWithdrawable, gemWithdrawable);
  }

   

  function validateJoinPackage(address _from, address _to, PackageType _type, uint _dabAmount, uint _gemAmount) private {
    require(contractNo3.isCitizen(_from), 'Please register first');
    require(contractNo3.isCitizen(_to), 'You can only active an exists member');
    if (_from != _to) {
      require(contractNo3.checkInvestorsInTheSameReferralTree(_from, _to), 'This user isn\'t in your referral tree');
    }
    require(contractNo2.validateJoinPackage(_from, _to, uint8(_type), _dabAmount, _gemAmount), 'Type or amount is invalid');
  }
}