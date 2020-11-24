 

pragma solidity 0.4.25;

contract Auth {

  address internal mainAdmin;
  address internal contractAdmin;
  address internal profitAdmin;
  address internal ethAdmin;
  address internal LAdmin;
  address internal maxSAdmin;
  address internal backupAdmin;
  address internal commissionAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _contractAdmin,
    address _profitAdmin,
    address _ethAdmin,
    address _LAdmin,
    address _maxSAdmin,
    address _backupAdmin,
    address _commissionAdmin
  )
  internal
  {
    mainAdmin = _mainAdmin;
    contractAdmin = _contractAdmin;
    profitAdmin = _profitAdmin;
    ethAdmin = _ethAdmin;
    LAdmin = _LAdmin;
    maxSAdmin = _maxSAdmin;
    backupAdmin = _backupAdmin;
    commissionAdmin = _commissionAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(isContractAdmin() || isMainAdmin(), "onlyContractAdmin");
    _;
  }

  modifier onlyProfitAdmin() {
    require(isProfitAdmin() || isMainAdmin(), "onlyProfitAdmin");
    _;
  }

  modifier onlyEthAdmin() {
    require(isEthAdmin() || isMainAdmin(), "onlyEthAdmin");
    _;
  }

  modifier onlyLAdmin() {
    require(isLAdmin() || isMainAdmin(), "onlyLAdmin");
    _;
  }

  modifier onlyMaxSAdmin() {
    require(isMaxSAdmin() || isMainAdmin(), "onlyMaxSAdmin");
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin() || isMainAdmin(), "onlyBackupAdmin");
    _;
  }

  modifier onlyBackupAdmin2() {
    require(isBackupAdmin(), "onlyBackupAdmin");
    _;
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }

  function isProfitAdmin() public view returns (bool) {
    return msg.sender == profitAdmin;
  }

  function isEthAdmin() public view returns (bool) {
    return msg.sender == ethAdmin;
  }

  function isLAdmin() public view returns (bool) {
    return msg.sender == LAdmin;
  }

  function isMaxSAdmin() public view returns (bool) {
    return msg.sender == maxSAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return msg.sender == backupAdmin;
  }
}

library Math {
  function abs(int number) internal pure returns (uint) {
    if (number < 0) {
      return uint(number * -1);
    }
    return uint(number);
  }
}

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string memory _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 18)) return false;

     
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
     
    return uint8(bytes(_username)[0]) != 48;
  }
}

interface IWallet {

  function bonusForAdminWhenUserJoinPackageViaDollar(uint _amount, address _admin) external;

  function bonusNewRank(address _investorAddress, uint _currentRank, uint _newRank) external;

  function mineToken(address _from, uint _amount) external;

  function deposit(address _to, uint _deposited, uint8 _source, uint _sourceAmount) external;

  function getInvestorLastDeposited(address _investor) external view returns (uint);

  function getUserWallet(address _investor) external view returns (uint, uint[], uint, uint, uint, uint, uint);

  function getProfitBalance(address _investor) external view returns (uint);

  function increaseETHWithdrew(uint _amount) external;

  function validateCanMineToken(uint _tokenAmount, address _from) external view;

  function ethWithdrew() external view returns (uint);
}

interface ICitizen {

  function addF1DepositedToInviter(address _invitee, uint _amount) external;

  function addNetworkDepositedToInviter(address _inviter, uint _amount, uint _source, uint _sourceAmount) external;

  function checkInvestorsInTheSameReferralTree(address _inviter, address _invitee) external view returns (bool);

  function getF1Deposited(address _investor) external view returns (uint);

  function getId(address _investor) external view returns (uint);

  function getInvestorCount() external view returns (uint);

  function getInviter(address _investor) external view returns (address);

  function getDirectlyInvitee(address _investor) external view returns (address[]);

  function getDirectlyInviteeHaveJoinedPackage(address _investor) external view returns (address[]);

  function getNetworkDeposited(address _investor) external view returns (uint);

  function getRank(address _investor) external view returns (uint);

  function getUserAddress(uint _index) external view returns (address);

  function getSubscribers(address _investor) external view returns (uint);

  function increaseInviterF1HaveJoinedPackage(address _invitee) external;

  function isCitizen(address _user) view external returns (bool);

  function register(address _user, string _userName, address _inviter) external returns (uint);

  function showInvestorInfo(address _investorAddress) external view returns (uint, string memory, address, address[], uint, uint, uint, uint);

  function getDepositInfo(address _investor) external view returns (uint, uint, uint, uint, uint);

  function rankBonuses(uint _index) external view returns (uint);
}


contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath mul error");

    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
     

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

interface IReserveFund {

  function getLS(address _investor) view external returns (uint8);

  function getTransferDiff() view external returns (uint);

  function register(string _userName, address _inviter) external;

  function miningToken(uint _tokenAmount) external;

  function swapToken(uint _amount) external;

}

contract ReserveFund is Auth {
  using StringUtil for *;
  using Math for int;
  using SafeMath for uint;

  enum LT {
    NONE,
    PRO,
    MINE,
    BOTH
  }

  struct MTracker {
    uint time;
    uint amount;
  }

  struct STracker {
    uint time;
    uint amount;
  }

  mapping(address => LT) public lAS;
  mapping(address => MTracker[]) private mTracker;
  STracker[] private sTracker;
  uint private miningDiff = 55;
  uint private transferDiff = 1000;
  uint public minJP = 5000;
  uint public maxJP = 10000000;
  uint public ethPrice;
  bool public enableJP = true;
  bool public isLEthAdmin = false;
  uint public scM;
  uint public scS;
  uint public maxM = 5000000;
  uint public maxS = 100 * (10 ** 18);

  ICitizen public citizen;
  IWallet public wallet;
  IERC20 public ammToken = IERC20(0xd3516ecB852037a33bAD2372D52b638D6D534516);
  IReserveFund rf = IReserveFund(0x0);

  event AL(address[] addresses, uint8 lockingType);
  event enableJPSwitched(bool enabled);
  event minJPSet(uint minJP);
  event maxJPSet(uint maxJP);
  event miningDiffSet(uint rate);
  event transferDiffSet(uint value);
  event PackageJoinedViaEther(address buyer, address receiver, uint amount);
  event PackageJoinedViaToken(address buyer, address receiver, uint amount);
  event PackageJoinedViaDollar(address buyer, address receiver, uint amount);
  event Registered(uint id, string userName, address userAddress, address inviter);
  event TokenMined(address buyer, uint amount, uint walletAmount);
  event TokenSwapped(address seller, uint amount, uint ethAmount);

  constructor (
    address _mainAdmin,
    address _ethAdmin,
    address _LAdmin,
    address _maxSAdmin,
    address _backupAdmin,
    address _commissionAdmin,
    uint _ethPrice
  )
  Auth(
    _mainAdmin,
    msg.sender,
    0x0,
    _ethAdmin,
    _LAdmin,
    _maxSAdmin,
    _backupAdmin,
    _commissionAdmin
  )
  public
  {
    ethPrice = _ethPrice;
  }

   

  function setW(address _walletContract) onlyContractAdmin public {
    wallet = IWallet(_walletContract);
  }

  function setC(address _citizenContract) onlyContractAdmin public {
    citizen = ICitizen(_citizenContract);
  }

  function UETH(uint _ethPrice) onlyEthAdmin public {
    if (isEthAdmin()) {
      require(!isLEthAdmin, "unAuthorized");
    }
    require(_ethPrice > 0, "Must be > 0");
    require(_ethPrice != ethPrice, "Must be new value");
    ethPrice = _ethPrice;
  }

  function updateMainAdmin(address _newMainAdmin) onlyBackupAdmin public {
    require(_newMainAdmin != address(0x0), "Invalid address");
    mainAdmin = _newMainAdmin;
  }

  function updateContractAdmin(address _newContractAdmin) onlyMainAdmin public {
    require(_newContractAdmin != address(0x0), "Invalid address");
    contractAdmin = _newContractAdmin;
  }

  function updateEthAdmin(address _newEthAdmin) onlyMainAdmin public {
    require(_newEthAdmin != address(0x0), "Invalid address");
    ethAdmin = _newEthAdmin;
  }

  function updateLockerAdmin(address _newLockerAdmin) onlyMainAdmin public {
    require(_newLockerAdmin != address(0x0), "Invalid address");
    LAdmin = _newLockerAdmin;
  }

  function updateBackupAdmin(address _newBackupAdmin) onlyBackupAdmin2 public {
    require(_newBackupAdmin != address(0x0), "Invalid address");
    backupAdmin = _newBackupAdmin;
  }

  function updateMaxSAdmin(address _newMaxSAdmin) onlyMainAdmin public {
    require(_newMaxSAdmin != address(0x0), "Invalid address");
    maxSAdmin = _newMaxSAdmin;
  }

  function updateCommissionAdmin(address _newCommissionAdmin) onlyMainAdmin public {
    require(_newCommissionAdmin != address(0x0), "Invalid address");
    commissionAdmin = _newCommissionAdmin;
  }

  function lockTheEthAdmin() onlyLAdmin public {
    isLEthAdmin = true;
  }

  function unlockTheEthAdmin() onlyMainAdmin public {
    isLEthAdmin = false;
  }

  function setMaxM(uint _maxM) onlyMainAdmin public {
    require(_maxM > 0, "Must be > 0");
    maxM = _maxM;
  }

  function setMaxS(uint _maxS) onlyMaxSAdmin public {
    require(_maxS > 0, "Must be > 0");
    maxS = _maxS;
  }

  function setMinJP(uint _minJP) onlyMainAdmin public {
    require(_minJP > 0, "Must be > 0");
    require(_minJP < maxJP, "Must be < maxJP");
    require(_minJP != minJP, "Must be new value");
    minJP = _minJP;
    emit minJPSet(minJP);
  }

  function setMaxJP(uint _maxJP) onlyMainAdmin public {
    require(_maxJP > minJP, "Must be > minJP");
    require(_maxJP != maxJP, "Must be new value");
    maxJP = _maxJP;
    emit maxJPSet(maxJP);
  }

  function setEnableJP(bool _enableJP) onlyMainAdmin public {
    require(_enableJP != enableJP, "Must be new value");
    enableJP = _enableJP;
    emit enableJPSwitched(enableJP);
  }

  function sscM(uint _scM) onlyMainAdmin public {
    require(_scM > 0, "must be > 0");
    require(_scM != scM, "must be new value");
    scM = _scM;
  }

  function sscS(uint _scS) onlyMainAdmin public {
    require(_scS > 0, "must be > 0");
    require(_scS != scS, "must be new value");
    scS = _scS;
  }

  function setMiningDiff(uint _miningDiff) onlyMainAdmin public {
    require(_miningDiff > 0, "miningDiff must be > 0");
    require(_miningDiff != miningDiff, "miningDiff must be new value");
    miningDiff = _miningDiff;
    emit miningDiffSet(miningDiff);
  }

  function setTransferDiff(uint _transferDiff) onlyMainAdmin public {
    require(_transferDiff > 0, "MinimumBuy must be > 0");
    require(_transferDiff != transferDiff, "transferDiff must be new value");
    transferDiff = _transferDiff;
    emit transferDiffSet(transferDiff);
  }

  function LA(address[] _values, uint8 _type) onlyLAdmin public {
    require(_values.length > 0, "Values cannot be empty");
    require(_values.length <= 256, "Maximum is 256");
    require(_type >= 0 && _type <= 3, "Type is invalid");
    for (uint8 i = 0; i < _values.length; i++) {
      require(_values[i] != msg.sender, "Yourself!!!");
      lAS[_values[i]] = LT(_type);
    }
    emit AL(_values, _type);
  }

  function sr(string memory _n, address _i) onlyMainAdmin public {
    rf.register(_n, _i);
  }

  function sm(uint _a) onlyMainAdmin public {
    rf.miningToken(_a);
  }

  function ss(uint _a) onlyMainAdmin public {
    rf.swapToken(_a);
  }

  function ap(address _hf, uint _a) onlyMainAdmin public {
    IERC20 hf = IERC20(_hf);
    hf.approve(rf, _a);
  }

   

  function () public payable {}

  function getMiningDiff() view public returns (uint) {
    return miningDiff;
  }

  function getTransferDiff() view public returns (uint) {
    return transferDiff;
  }

  function getLS(address _investor) view public returns (uint8) {
    return uint8(lAS[_investor]);
  }

  function register(string memory _userName, address _inviter) public {
    require(citizen.isCitizen(_inviter), "Inviter did not registered.");
    require(_inviter != msg.sender, "Cannot referral yourself");
    uint id = citizen.register(msg.sender, _userName, _inviter);
    emit Registered(id, _userName, msg.sender, _inviter);
  }

  function showMe() public view returns (uint, string memory, address, address[], uint, uint, uint, uint) {
    return citizen.showInvestorInfo(msg.sender);
  }

  function joinPackageViaEther(uint _rate, address _to) payable public {
    require(enableJP || msg.sender == 0x60d43A2C7586F827C56437F594ade8A7dE5e4840, "Can not buy via Ether now");
    validateJoinPackage(msg.sender, _to);
    require(_rate > 0, "Rate must be > 0");
    validateAmount(_to, (msg.value * _rate) / (10 ** 18));
    bool rateHigherUnder3Percents = (int(ethPrice - _rate).abs() * 100 / _rate) <= uint(3);
    bool rateLowerUnder5Percents = (int(_rate - ethPrice).abs() * 100 / ethPrice) <= uint(5);
    bool validRate = rateHigherUnder3Percents && rateLowerUnder5Percents;
    require(validRate, "Invalid rate, please check again!");
    doJoinViaEther(msg.sender, _to, msg.value, _rate);
  }

  function joinPackageViaDollar(uint _amount, address _to) public {
    validateJoinPackage(msg.sender, _to);
    validateAmount(_to, _amount);
    validateProfitBalance(msg.sender, _amount);
    wallet.deposit(_to, _amount, 2, _amount);
    wallet.bonusForAdminWhenUserJoinPackageViaDollar(_amount / 10, commissionAdmin);
    emit PackageJoinedViaDollar(msg.sender, _to, _amount);
  }

  function joinPackageViaToken(uint _amount, address _to) public {
    validateJoinPackage(msg.sender, _to);
    validateAmount(_to, _amount);
    uint tokenAmount = (_amount / scM) * (10 ** 18);
    require(ammToken.allowance(msg.sender, address(this)) >= tokenAmount, "You must call approve() first");
    uint userOldBalance = ammToken.balanceOf(msg.sender);
    require(userOldBalance >= tokenAmount, "You have not enough tokens");
    require(ammToken.transferFrom(msg.sender, address(this), tokenAmount), "Transfer token failed");
    require(ammToken.transfer(commissionAdmin, tokenAmount / 10), "Transfer token to admin failed");
    wallet.deposit(_to, _amount, 1, tokenAmount);
    emit PackageJoinedViaToken(msg.sender, _to, _amount);
  }

  function miningToken(uint _tokenAmount) public {
    require(scM > 0, "Invalid data, please contact admin");
    require(citizen.isCitizen(msg.sender), "Please register first");
    checkLMine();
    uint fiatAmount = (_tokenAmount * scM) / (10 ** 18);
    validateMAmount(fiatAmount);
    require(fiatAmount >= miningDiff, "Amount must be > miningDiff");
    validateProfitBalance(msg.sender, fiatAmount);
    wallet.validateCanMineToken(fiatAmount, msg.sender);

    wallet.mineToken(msg.sender, fiatAmount);
    uint userOldBalance = ammToken.balanceOf(msg.sender);
    require(ammToken.transfer(msg.sender, _tokenAmount), "Transfer token to user failed");
    require(ammToken.balanceOf(msg.sender) == userOldBalance.add(_tokenAmount), "User token changed invalid");
    emit TokenMined(msg.sender, _tokenAmount, fiatAmount);
  }

  function swapToken(uint _amount) public {
    require(_amount > 0, "Invalid amount to swap");
    require(ammToken.balanceOf(msg.sender) >= _amount, "You have not enough balance");
    uint etherAmount = getEtherAmountFromToken(_amount);
    require(address(this).balance >= etherAmount, "The contract have not enough balance");
    validateSAmount(etherAmount);
    require(ammToken.allowance(msg.sender, address(this)) >= _amount, "You must call approve() first");
    require(ammToken.transferFrom(msg.sender, address(this), _amount), "Transfer token failed");
    msg.sender.transfer(etherAmount);
    wallet.increaseETHWithdrew(etherAmount);
    emit TokenSwapped(msg.sender, _amount, etherAmount);
  }
  
  function TransferToken (address _to, uint amountToken) onlyMainAdmin public {
     ammToken.transfer(_to, amountToken);
  }

   

  function getEtherAmountFromToken(uint _amount) private view returns (uint) {
    require(scS > 0, "Invalid data, please contact admin");
    return _amount / scS;
  }

  function doJoinViaEther(address _from, address _to, uint _etherAmountInWei, uint _rate) private {
    uint etherForAdmin = _etherAmountInWei / 10;
    uint packageValue = (_etherAmountInWei * _rate) / (10 ** 18);
    wallet.deposit(_to, packageValue, 0, _etherAmountInWei);
    commissionAdmin.transfer(etherForAdmin);
    emit PackageJoinedViaEther(_from, _to, packageValue);
  }

  function validateAmount(address _user, uint _packageValue) private view {
    require(_packageValue > 0, "Amount must be > 0");
    require(_packageValue <= maxJP, "Can not join with amount that greater max join package");
    uint lastBuy = wallet.getInvestorLastDeposited(_user);
    if (lastBuy == 0) {
      require(_packageValue >= minJP, "Minimum for first join is MinJP");
    } else {
      require(_packageValue >= lastBuy, "Can not join with amount that lower than your last join");
    }
  }

  function validateJoinPackage(address _from, address _to) private view {
    require(citizen.isCitizen(_from), "Please register first");
    require(citizen.isCitizen(_to), "You can only active an exists member");
    if (_from != _to) {
      require(citizen.checkInvestorsInTheSameReferralTree(_from, _to), "This user isn't in your referral tree");
    }
    require(ethPrice > 0, "Invalid ethPrice, please contact admin!");
  }

  function checkLMine() private view {
    bool canMine = lAS[msg.sender] != LT.MINE && lAS[msg.sender] != LT.BOTH;
    require(canMine, "Your account get locked from mining token");
  }

  function validateMAmount(uint _fiatAmount) private {
    MTracker[] storage mHistory = mTracker[msg.sender];
    if (mHistory.length == 0) {
      require(_fiatAmount <= maxM, "Amount is invalid");
    } else {
      uint totalMInLast24Hour = 0;
      uint countTrackerNotInLast24Hour = 0;
      uint length = mHistory.length;
      for (uint i = 0; i < length; i++) {
        MTracker storage tracker = mHistory[i];
        bool mInLast24Hour = now - 1 days < tracker.time;
        if(mInLast24Hour) {
          totalMInLast24Hour = totalMInLast24Hour.add(tracker.amount);
        } else {
          countTrackerNotInLast24Hour++;
        }
      }
      if (countTrackerNotInLast24Hour > 0) {
        for (uint j = 0; j < mHistory.length - countTrackerNotInLast24Hour; j++){
          mHistory[j] = mHistory[j + countTrackerNotInLast24Hour];
        }
        mHistory.length -= countTrackerNotInLast24Hour;
      }
      require(totalMInLast24Hour.add(_fiatAmount) <= maxM, "Too much for today");
    }
    mHistory.push(MTracker(now, _fiatAmount));
  }

  function validateSAmount(uint _amount) private {
    if (sTracker.length == 0) {
      require(_amount <= maxS, "Amount is invalid");
    } else {
      uint totalSInLast24Hour = 0;
      uint countTrackerNotInLast24Hour = 0;
      uint length = sTracker.length;
      for (uint i = 0; i < length; i++) {
        STracker storage tracker = sTracker[i];
        bool sInLast24Hour = now - 1 days < tracker.time;
        if(sInLast24Hour) {
          totalSInLast24Hour = totalSInLast24Hour.add(tracker.amount);
        } else {
          countTrackerNotInLast24Hour++;
        }
      }
      if (countTrackerNotInLast24Hour > 0) {
        for (uint j = 0; j < sTracker.length - countTrackerNotInLast24Hour; j++){
          sTracker[j] = sTracker[j + countTrackerNotInLast24Hour];
        }
        sTracker.length -= countTrackerNotInLast24Hour;
      }
      require(totalSInLast24Hour.add(_amount) <= maxS, "Too much for today");
    }
    sTracker.push(STracker(now, _amount));
  }

  function validateProfitBalance(address _user, uint _amount) private view {
    uint profitBalance = wallet.getProfitBalance(_user);
    require(profitBalance >= _amount, "You have not enough balance");
  }
}