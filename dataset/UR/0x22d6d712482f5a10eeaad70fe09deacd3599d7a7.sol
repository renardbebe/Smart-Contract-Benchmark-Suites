 

pragma solidity 0.4.25;

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


interface IContractNo1 {
  function minJP() external returns (uint);
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

 
contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ContractNo2 is Auth {
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

  enum CommissionType {
    DAB,
    GEM
  }

  struct Balance {
    uint totalDeposited;
    uint dividendBalance;
    uint dabStakingBalance;
    uint gemStakingBalance;
    int gemBalance;
    uint totalProfited;
  }

  struct Package {
    PackageType packageType;
    uint lastPackage;
    uint dabAmount;
    uint gemAmount;
    uint startAt;
    uint endAt;
  }

  struct TTracker {
    uint time;
    uint amount;
  }

  IContractNo1 public contractNo1;
  IContractNo3 public contractNo3;

  uint constant private secondsInOntMonth = 2592000;  

  uint public minT = 1e18;
  uint public maxT = 10000e18;
  uint8 public gemCommission = 10;
  uint32 public profitInterval = 60;
  uint public minProfit = 1e18;
  bool private gemT = true;
  string DAB = 'DAB';
  string GEM = 'GEM';
  uint16 firstProfitCheckpoint = 1e4;
  uint16 secondProfitCheckpoint = 2e4;
  uint16 thirdProfitCheckpoint = 3e4;
  mapping(address => TTracker[]) private tTracker;
  mapping(address => Package) private packages;
  mapping(address => Balance) private balances;
  mapping(address => bool) private ha;
  mapping(address => uint) private lP;
  mapping(address => uint) private lW;
  mapping(address => mapping(address => mapping(string => uint))) private commissions;

  event DividendBalanceChanged(address user, address reason, int amount);
  event GEMBalanceChanged(address user, address reason, int amount);
  event GEMBalanceTransferred(address from, address to, int amount, int receivedAmount);

  modifier onlyContractAContract() {
    require(msg.sender == address(contractNo1), 'onlyContractAContract');
    _;
  }

constructor(
    address _backupAdmin,
    address _mainAdmin,
    address _gemAdmin
  )
  public
  Auth(
    _backupAdmin,
    _mainAdmin,
    msg.sender,
    address(0x0),
    _gemAdmin,
    address(0x0)
  ) {
  }

   

  function setE(address _u) onlyMainAdmin public {
    packages[_u].endAt = now;
  }

  function setLW(address _u) onlyMainAdmin public {
    lW[_u] = now - 31 days;
  }

  function setC(address _c) onlyContractAdmin public {
    contractNo3 = IContractNo3(_c);
  }

  function setS(address _s) onlyContractAdmin public {
    contractNo1 = IContractNo1(_s);
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

  function updateGEMAdmin(address _newGEMAdmin) onlyMainAdmin public {
    require(_newGEMAdmin != address(0x0), 'Invalid address');
    gemAdmin = _newGEMAdmin;
  }

  function setMinT(uint _minT) onlyMainAdmin public {
    require(_minT > 0, 'Must be > 0');
    require(_minT < maxT, 'Must be < maxT');
    minT = _minT;
  }

  function setMaxT(uint _maxT) onlyMainAdmin public {
    require(_maxT > minT, 'Must be > minT');
    maxT = _maxT;
  }

  function setMinProfit(uint _minProfit) onlyMainAdmin public {
    require(_minProfit > 0, 'Must be > 0');
    minProfit = _minProfit;
  }

  function setProfitInterval(uint32 _profitInterval) onlyMainAdmin public {
    require(0 < _profitInterval, 'Must be > 0');
    profitInterval = _profitInterval;
  }

  function setGemCommission(uint8 _gemCommission) onlyMainAdmin public {
    require(0 < _gemCommission && _gemCommission < 101, 'Must be in range 1-100');
    gemCommission = _gemCommission;
  }

  function setGemT(bool _gemT) onlyMainAdmin public {
    gemT = _gemT;
  }

  function updateHA(address[] _addresses, bool _value) onlyMainAdmin public {
    require(_addresses.length <= 256, 'Max length is 256');
    for(uint8 i; i < _addresses.length; i++) {
      ha[_addresses[i]] = _value;
    }
  }

  function checkHA(address _address) onlyMainAdmin public view returns (bool) {
    return ha[_address];
  }

   

  function validateJoinPackage(address _from, address _to, uint8 _type, uint _dabAmount, uint _gemAmount)
  onlyContractAContract
  public
  view
  returns (bool)
  {
    Package storage package = packages[_to];
    Balance storage balance = balances[_from];
    return _type > uint8(PackageType.M0) &&
      _type <= uint8(PackageType.M18) &&
      _type >= uint8(package.packageType) &&
      _dabAmount.add(_gemAmount) >= package.lastPackage &&
      (_gemAmount == 0 || balance.gemBalance >= int(_gemAmount));
  }

  function adminCommission(uint _amount) onlyContractAContract public {
    Balance storage balance = balances[gemAdmin];
    balance.gemBalance += int(_amount);
  }

  function deposit(address _to, uint8 _type, uint _packageAmount, uint _dabAmount, uint _gemAmount) onlyContractAContract public {
    PackageType packageType = parsePackageType(_type);

    updatePackageInfo(_to, packageType, _dabAmount, _gemAmount);

    Balance storage userBalance = balances[_to];
    bool firstDeposit = userBalance.dividendBalance == 0;
    if (firstDeposit) {
      userBalance.dividendBalance = _packageAmount;
      emit DividendBalanceChanged(_to, address(0x0), int(_packageAmount));
    } else {
      userBalance.dividendBalance = userBalance.dividendBalance.add(_packageAmount.div(2));
      emit DividendBalanceChanged(_to, address(0x0), int(_packageAmount.div(2)));
    }
    userBalance.totalDeposited = userBalance.totalDeposited.add(_packageAmount);
    userBalance.dabStakingBalance = userBalance.dabStakingBalance.add(_dabAmount);
    userBalance.gemStakingBalance = userBalance.gemStakingBalance.add(_gemAmount);

    if (_gemAmount > 0) {
      bool selfDeposit = _to == tx.origin;
      if (selfDeposit) {
        userBalance.gemBalance -= int(_gemAmount);
      } else {
        Balance storage senderBalance = balances[tx.origin];
        senderBalance.gemBalance -= int(_gemAmount);
      }
      emit GEMBalanceChanged(tx.origin, address(0x0), int(_gemAmount) * -1);
    }

    if (packageType >= PackageType.M9) {
      contractNo3.addF1M9DepositedToInviter(_to, _packageAmount);
      contractNo3.increaseInviterF1HaveJoinedM9Package(_to);
    }
    if (firstDeposit) {
      contractNo3.increaseInviterF1HaveJoinedPackage(_to);
    }
    addRewardToUpLines(_to, _dabAmount, _gemAmount, packageType);
    lW[_to] = 0;
    lP[_to] = packages[_to].startAt;
  }

  function getProfit(address _user, uint _contractNo1Balance) onlyContractAContract public returns (uint, uint) {
    require(getProfitWallet(_user) <= 300000, 'You have got max profit');
    Package storage userPackage = packages[_user];
    uint lastProfit = lP[_user];
    require(lastProfit < userPackage.endAt, 'You have got all your profits');
    uint profitableTime = userPackage.endAt < now ? userPackage.endAt.sub(lastProfit) : now.sub(lastProfit);
    require(profitableTime >= uint(profitInterval), 'Please wait more time and comeback later');
    Balance storage userBalance = balances[_user];

    uint rate = parseProfitRate(userPackage.packageType);
    uint profitable = userBalance.dividendBalance.mul(rate).div(100).mul(profitableTime).div(secondsInOntMonth);
    if (userBalance.totalProfited.add(profitable) > userBalance.totalDeposited.mul(3)) {
      profitable = userBalance.totalDeposited.mul(3).sub(userBalance.totalProfited);
    }
    require(profitable > minProfit, 'Please wait for more profit and comeback later');
    uint dabProfit;
    uint gemProfit;
    (dabProfit, gemProfit) = calculateProfit(_user, profitable);
    if (gemProfit > 0) {
      userBalance.gemBalance += int(gemProfit);
      emit GEMBalanceChanged(_user, address(0x0), int(gemProfit));
    }
    lP[_user] = now;
    if (_contractNo1Balance < dabProfit) {
      userBalance.gemBalance += int(dabProfit.sub(_contractNo1Balance));
      emit GEMBalanceChanged(_user, address(0x0), int(dabProfit.sub(_contractNo1Balance)));
      return (_contractNo1Balance, gemProfit.add(dabProfit.sub(_contractNo1Balance)));
    }
    userBalance.totalProfited = userBalance.totalProfited.add(profitable);
    return (dabProfit, gemProfit);
  }

  function getWithdraw(address _user, uint _contractNo1Balance, uint8 _type) onlyContractAContract public returns (uint, uint) {
    require(getEndAt(_user) <= now, 'Please wait for more times and comeback later');
    uint lastWithdraw = lW[_user];
    bool firstWithdraw = lastWithdraw == 0;
    Balance storage userBalance = balances[_user];
    resetUserBalance(_user);

    uint dabWithdrawable;
    uint gemWithdrawable;
    if (_type == 1) {
      require(firstWithdraw, 'You have withdrew 50%');
      dabWithdrawable = userBalance.dabStakingBalance.mul(90).div(100);
      gemWithdrawable = userBalance.gemStakingBalance.mul(90).div(100);
      userBalance.gemBalance += int(gemWithdrawable);
      emit GEMBalanceChanged(_user, address(0x0), int(gemWithdrawable));
      userBalance.dabStakingBalance = 0;
      userBalance.gemStakingBalance = 0;
      removeUpLineCommission(_user);
      return calculateWithdrawableDAB(_user, _contractNo1Balance, dabWithdrawable);
    } else {
      require(now - lastWithdraw >= secondsInOntMonth, 'Please wait for more times and comeback later');
      if (firstWithdraw) {
        dabWithdrawable = userBalance.dabStakingBalance.div(2);
        gemWithdrawable = userBalance.gemStakingBalance.div(2);
        userBalance.dabStakingBalance = dabWithdrawable;
        userBalance.gemStakingBalance = gemWithdrawable;
        removeUpLineCommission(_user);
      } else {
        dabWithdrawable = userBalance.dabStakingBalance;
        gemWithdrawable = userBalance.gemStakingBalance;
        userBalance.dabStakingBalance = 0;
        userBalance.gemStakingBalance = 0;
      }
      userBalance.gemBalance += int(gemWithdrawable);
      emit GEMBalanceChanged(_user, address(0x0), int(gemWithdrawable));
      lW[_user] = now;
      return calculateWithdrawableDAB(_user, _contractNo1Balance, dabWithdrawable);
    }
  }

   

  function getUserWallet(address _investor)
  public
  view
  returns (uint, uint, uint, uint, int, uint)
  {
    validateSender(_investor);
    Balance storage balance = balances[_investor];
    return (
      balance.totalDeposited,
      balance.dividendBalance,
      balance.dabStakingBalance,
      balance.gemStakingBalance,
      balance.gemBalance,
      balance.totalProfited
    );
  }

  function getUserPackage(address _investor)
  public
  view
  returns (uint8, uint, uint, uint, uint, uint)
  {
    validateSender(_investor);
    Package storage package = packages[_investor];
    return (
      uint8(package.packageType),
      package.lastPackage,
      package.dabAmount,
      package.gemAmount,
      package.startAt,
      package.endAt
    );
  }

  function transferGem(address _to, uint _amount) public {
    require(gemT, 'Not available right now');
    int amountToTransfer = int(_amount);
    validateTransferGem(msg.sender, _to, _amount);
    Balance storage senderBalance = balances[msg.sender];
    require(senderBalance.gemBalance >= amountToTransfer, 'You have not enough balance');
    Balance storage receiverBalance = balances[_to];
    Balance storage adminBalance = balances[gemAdmin];
    senderBalance.gemBalance -= amountToTransfer;
    int fee = amountToTransfer * int(gemCommission) / 100;
    require(fee > 0, 'Invalid fee');
    adminBalance.gemBalance += fee;
    int receivedAmount = amountToTransfer - int(fee);
    receiverBalance.gemBalance += receivedAmount;
    emit GEMBalanceTransferred(msg.sender, _to, amountToTransfer, receivedAmount);
  }

  function getProfitWallet(address _user) public view returns (uint16) {
    validateSender(_user);
    Balance storage userBalance = balances[_user];
    return uint16(userBalance.totalProfited.mul(1e4).div(userBalance.totalDeposited));
  }

  function getEndAt(address _user) public view returns (uint) {
    validateSender(_user);
    return packages[_user].endAt;
  }

  function getNextWithdraw(address _user) public view returns (uint) {
    validateSender(_user);
    uint lastWithdraw = lW[_user];
    if (lastWithdraw == 0) {
      return 0;
    }
    return lastWithdraw + 30 days;
  }

  function getLastProfited(address _user) public view returns (uint) {
    validateSender(_user);
    return lP[_user];
  }

   

  function updatePackageInfo(address _to, PackageType _packageType, uint _dabAmount, uint _gemAmount) private {
    Package storage package = packages[_to];
    package.packageType = _packageType;
    package.lastPackage = _dabAmount.add(_gemAmount);
    package.dabAmount = package.dabAmount.add(_dabAmount);
    package.gemAmount = package.gemAmount.add(_gemAmount);
    package.startAt = now;
    package.endAt = package.startAt + parseEndAt(_packageType);
  }

  function parsePackageType(uint8 _index) private pure returns (PackageType) {
    require(_index >= 0 && _index <= 10, 'Invalid index');
    if (_index == 1) {
      return PackageType.M3;
    } else if (_index == 2) {
      return PackageType.M6;
    } else if (_index == 3) {
      return PackageType.M9;
    } else if (_index == 4) {
      return PackageType.M12;
    } else if (_index == 5) {
      return PackageType.M15;
    } else if (_index == 6) {
      return PackageType.M18;
    } else {
      return PackageType.M0;
    }
  }

  function parseEndAt(PackageType _type) private pure returns (uint) {
    return uint(_type) * 3 * 30 days;
  }

  function parseProfitRate(PackageType _type) private pure returns (uint) {
    if (_type == PackageType.M3) {
      return 4;
    } else if (_type == PackageType.M6) {
      return 5;
    } else if (_type == PackageType.M9) {
      return 6;
    } else if (_type == PackageType.M12) {
      return 8;
    } else if (_type == PackageType.M15) {
      return 10;
    } else if (_type == PackageType.M18) {
      return 12;
    } else {
      return 0;
    }
  }

  function addRewardToUpLines(address _invitee, uint _dabAmount, uint _gemAmount, PackageType _packageType) private {
    address inviter;
    uint16 referralLevel = 1;
    address tempInvitee = _invitee;
    do {
      inviter = contractNo3.getInviter(tempInvitee);
      if (inviter != address(0x0)) {
        contractNo3.addNetworkDepositedToInviter(inviter, _dabAmount, _gemAmount);
        if (_packageType >= PackageType.M6) {
          checkAddReward(_invitee, inviter, referralLevel, _dabAmount.add(_gemAmount));
        }
        tempInvitee = inviter;
        referralLevel += 1;
      }
    } while (inviter != address(0x0));
  }

  function checkAddReward(address _invitee, address _inviter, uint16 _referralLevel, uint _packageAmount) private {
    Balance storage inviterBalance = balances[_inviter];
    Package storage inviterPackage = packages[_inviter];
    bool userCannotGetCommission = inviterBalance.totalProfited > inviterBalance.totalDeposited.mul(3);
    if (inviterPackage.packageType < PackageType.M9 || userCannotGetCommission) {
      return;
    }
    uint f1M9Deposited = contractNo3.getF1M9Deposited(_inviter);
    uint16 directlyM9InviteeCount = uint16(contractNo3.getDirectlyInviteeHaveJoinedM9Package(_inviter).length);
    uint8 rank = contractNo3.getRank(_inviter);
    mapping(string => uint) userCommission = commissions[_inviter][_invitee];
    uint commissionAmount;
    if (_referralLevel == 1) {
      commissionAmount = _packageAmount.div(5);
      inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
      emit DividendBalanceChanged(_inviter, _invitee, int(commissionAmount));
      userCommission[DAB] = userCommission[DAB].add(commissionAmount);
    } else if (_referralLevel > 1 && _referralLevel < 11) {
      bool condition1 = f1M9Deposited >= contractNo1.minJP().mul(3);
      bool condition2 = directlyM9InviteeCount >= _referralLevel;
      if (condition1 && condition2) {
        commissionAmount = _packageAmount.div(20);
        inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
        emit DividendBalanceChanged(_inviter, _invitee, int(commissionAmount));
        inviterBalance.gemBalance += int(commissionAmount);
        emit GEMBalanceChanged(_inviter, _invitee, int(commissionAmount));
        userCommission[DAB] = userCommission[DAB].add(commissionAmount);
        userCommission[GEM] = userCommission[GEM].add(commissionAmount);
      }
    } else if (_referralLevel < 21) {
      if (rank == 1) {
        commissionAmount = _packageAmount.div(20);
        inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
      } else if (2 <= rank && rank <= 5) {
        commissionAmount = increaseInviterDividendBalance(inviterBalance, rank, _packageAmount);
      }
      userCommission[DAB] = userCommission[DAB].add(commissionAmount);
      emit DividendBalanceChanged(_inviter, _invitee, int(commissionAmount));
    } else {
      commissionAmount = increaseInviterDividendBalance(inviterBalance, rank, _packageAmount);
      userCommission[DAB] = userCommission[DAB].add(commissionAmount);
      emit DividendBalanceChanged(_inviter, _invitee, int(commissionAmount));
    }
  }

  function increaseInviterDividendBalance(Balance storage inviterBalance, uint8 _rank, uint _packageAmount) private returns (uint) {
    uint commissionAmount;
    if (_rank == 2) {
      commissionAmount = _packageAmount.div(20);
      inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
    } else if (_rank == 3) {
      commissionAmount = _packageAmount.div(10);
      inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
    } else if (_rank == 4) {
      commissionAmount = _packageAmount.mul(15).div(100);
      inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
    } else if (_rank == 5) {
      commissionAmount = _packageAmount.div(5);
      inviterBalance.dividendBalance = inviterBalance.dividendBalance.add(commissionAmount);
    }
    return commissionAmount;
  }

  function validateTransferGem(address _from, address _to, uint _amount) private {
    require(contractNo3.isCitizen(_from), 'Please register first');
    require(contractNo3.isCitizen(_to), 'You can only transfer to exists member');
    if (_from != _to) {
      require(contractNo3.checkInvestorsInTheSameReferralTree(_from, _to), 'This user isn\'t in your referral tree');
    }
    validateTAmount(_amount);
  }

  function validateTAmount(uint _amount) private {
    require(_amount >= minT, 'Transfer failed due to difficulty');
    TTracker[] storage userTransferHistory = tTracker[msg.sender];
    if (userTransferHistory.length == 0) {
      require(_amount <= maxT, 'Amount is invalid');
    } else {
      uint totalTransferredInLast24Hour = 0;
      uint countTrackerNotInLast24Hour = 0;
      uint length = userTransferHistory.length;
      for (uint i = 0; i < length; i++) {
        TTracker storage tracker = userTransferHistory[i];
        bool transferInLast24Hour = now - 1 days < tracker.time;
        if(transferInLast24Hour) {
          totalTransferredInLast24Hour = totalTransferredInLast24Hour.add(tracker.amount);
        } else {
          countTrackerNotInLast24Hour++;
        }
      }
      if (countTrackerNotInLast24Hour > 0) {
        for (uint j = 0; j < userTransferHistory.length - countTrackerNotInLast24Hour; j++){
          userTransferHistory[j] = userTransferHistory[j + countTrackerNotInLast24Hour];
        }
        userTransferHistory.length -= countTrackerNotInLast24Hour;
      }
      require(totalTransferredInLast24Hour.add(_amount) <= maxT, 'Too much for today');
    }
    userTransferHistory.push(TTracker(now, _amount));
  }

  function calculateProfit(address _user, uint _profitable) private view returns (uint, uint) {
    uint16 profitedPercent = getProfitWallet(_user);
    if (profitedPercent <= firstProfitCheckpoint) {
      return (_profitable, 0);
    } else if (profitedPercent <= secondProfitCheckpoint) {
      return (_profitable.div(2), _profitable.div(2));
    } else if (profitedPercent <= thirdProfitCheckpoint) {
      Balance storage userBalance = balances[_user];
      if (userBalance.totalProfited.add(_profitable) > userBalance.totalDeposited.mul(3)) {
        _profitable = userBalance.totalDeposited.mul(3).sub(userBalance.totalProfited);
      }
      return (_profitable.mul(30).div(100), _profitable.mul(70).div(100));
    } else {
      return (0, 0);
    }
  }

  function calculateWithdrawableDAB(address _user, uint _contractNo1Balance, uint _withdrawable) private returns (uint, uint) {
    Balance storage userBalance = balances[_user];
    if (_contractNo1Balance < _withdrawable) {
      int gemAmount = int(_withdrawable.sub(_contractNo1Balance));
      userBalance.gemBalance += gemAmount;
      emit GEMBalanceChanged(_user, address(0x0), gemAmount);
      return (_contractNo1Balance, _withdrawable.sub(_contractNo1Balance));
    } else {
      return (_withdrawable, 0);
    }
  }

  function resetUserBalance(address _user) private {
    Balance storage userBalance = balances[_user];
    emit DividendBalanceChanged(_user, address(0x0), int(int(userBalance.dividendBalance) * -1));
    userBalance.dividendBalance = 0;
    userBalance.totalProfited = 0;
    Package storage userPackage = packages[_user];
    userPackage.packageType = PackageType.M0;
    userPackage.lastPackage = 0;
    userPackage.dabAmount = 0;
    userPackage.gemAmount = 0;
    userPackage.startAt = 0;
    userPackage.endAt = 0;
  }

  function removeUpLineCommission(address _invitee) private {
    address inviter;
    address directInvitee = _invitee;
    do {
      inviter = contractNo3.getInviter(directInvitee);
      if (inviter != address(0x0)) {
        mapping(string => uint) userCommission = commissions[inviter][_invitee];
        Balance storage userBalance = balances[inviter];
        if (userBalance.dividendBalance > userCommission[DAB]) {
          userBalance.dividendBalance = userBalance.dividendBalance.sub(userCommission[DAB]);
        } else {
          userBalance.dividendBalance = 0;
        }
        if (int(int(userCommission[DAB]) * -1) != 0) {
          emit DividendBalanceChanged(inviter, address(0x0), int(int(userCommission[DAB]) * -1));
        }
        userBalance.gemBalance -= int(userCommission[GEM]);
        if (int(int(userCommission[GEM]) * -1) != 0) {
          emit GEMBalanceChanged(inviter, address(0x0), int(int(userCommission[GEM]) * -1));
        }
        userCommission[DAB] = 0;
        userCommission[GEM] = 0;
        directInvitee = inviter;
      }
    } while (inviter != address(0x0));
  }

  function validateSender(address _investor) private view {
    if (msg.sender != _investor &&
    msg.sender != mainAdmin &&
    msg.sender != address(contractNo1) &&
    msg.sender != address(contractNo3) &&
    msg.sender != address(this)
    ) {
      require(!ha[_investor], 'Stop!!!');
    }
  }
}