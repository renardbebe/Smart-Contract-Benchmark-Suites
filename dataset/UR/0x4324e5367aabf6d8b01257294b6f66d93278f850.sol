 

pragma solidity 0.4.24;

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

interface IReserveFund {

  function getLS(address _investor) view external returns (uint8);

  function getTransferDiff() view external returns (uint);

  function register(string _userName, address _inviter) external;

  function miningToken(uint _tokenAmount) external;

  function swapToken(uint _amount) external;

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

contract Wallet is Auth {
  using SafeMath for uint;

  struct Balance {
    uint totalDeposited;  
    uint[] deposited;
    uint profitableBalance;  
    uint profitSourceBalance;  
    uint profitBalance;  
    uint totalProfited;
    uint amountToMineToken;
    uint ethWithdrew;
  }

  struct TTracker {
    uint time;
    uint amount;
  }

  IReserveFund public reserveFund;
  ICitizen public citizen;
  IWallet private oldWallet = IWallet(0x2A20e2Fe3a6fF17e30953dFE6D4b859Ee8221ca9);

  uint public ethWithdrew;
  uint private profitPaid;
  uint private f11RewardCondition = 183000000;  
  bool public isLProfitAdmin = false;
  uint public maxT = 5000000;
  mapping(address => TTracker[]) private transferTracker;
  mapping (address => Balance) private userWallets;
  mapping (address => bool) private ha;

  modifier onlyReserveFundContract() {
    require(msg.sender == address(reserveFund), "onlyReserveFundContract");
    _;
  }

  modifier onlyCitizenContract() {
    require(msg.sender == address(citizen), "onlyCitizenContract");
    _;
  }

  event ProfitBalanceTransferred(address from, address to, uint amount);
  event RankBonusSent(address investor, uint rank, uint amount);
   
  event ProfitSourceBalanceChanged(address investor, int amount, address from, uint8 source);
  event ProfitableBalanceChanged(address investor, int amount, address from, uint8 source);
   
  event ProfitBalanceChanged(address from, address to, int amount, uint8 source);

  constructor (
    address _mainAdmin,
    address _profitAdmin,
    address _LAdmin,
    address _backupAdmin
  )
  Auth(
    _mainAdmin,
    msg.sender,
    _profitAdmin,
    0x0,
    _LAdmin,
    0x0,
    _backupAdmin,
    0x0
  )
  public {}

   
  function getProfitPaid() onlyMainAdmin public view returns(uint) {
    return profitPaid;
  }

  function setC(address _citizen) onlyContractAdmin public {
    citizen = ICitizen(_citizen);
  }

  function setMaxT(uint _maxT) onlyMainAdmin public {
    require(_maxT > 0, "Must be > 0");
    maxT = _maxT;
  }

  function updateMainAdmin(address _newMainAdmin) onlyBackupAdmin public {
    require(_newMainAdmin != address(0x0), "Invalid address");
    mainAdmin = _newMainAdmin;
  }

  function updateContractAdmin(address _newContractAdmin) onlyMainAdmin public {
    require(_newContractAdmin != address(0x0), "Invalid address");
    contractAdmin = _newContractAdmin;
  }

  function updateLockerAdmin(address _newLockerAdmin) onlyMainAdmin public {
    require(_newLockerAdmin != address(0x0), "Invalid address");
    LAdmin = _newLockerAdmin;
  }

  function updateBackupAdmin(address _newBackupAdmin) onlyBackupAdmin2 public {
    require(_newBackupAdmin != address(0x0), "Invalid address");
    backupAdmin = _newBackupAdmin;
  }

  function updateProfitAdmin(address _newProfitAdmin) onlyMainAdmin public {
    require(_newProfitAdmin != address(0x0), "Invalid profitAdmin address");
    profitAdmin = _newProfitAdmin;
  }

  function lockTheProfitAdmin() onlyLAdmin public {
    isLProfitAdmin = true;
  }

  function unLockTheProfitAdmin() onlyMainAdmin public {
    isLProfitAdmin = false;
  }

  function updateHA(address _address, bool _value) onlyMainAdmin public {
    ha[_address] = _value;
  }

  function checkHA(address _address) onlyMainAdmin public view returns (bool) {
    return ha[_address];
  }

   

  function setRF(address _reserveFundContract) onlyContractAdmin public {
    reserveFund = IReserveFund(_reserveFundContract);
  }

  function syncContractLevelData(uint _profitPaid) onlyContractAdmin public {
    ethWithdrew = oldWallet.ethWithdrew();
    profitPaid = _profitPaid;
  }

  function syncData(address[] _investors, uint[] _amountToMineToken) onlyContractAdmin public {
    require(_investors.length == _amountToMineToken.length, "Array length invalid");
    for (uint i = 0; i < _investors.length; i++) {
      uint totalDeposited;
      uint[] memory deposited;
      uint profitableBalance;
      uint profitSourceBalance;
      uint profitBalance;
      uint totalProfited;
      uint oldEthWithdrew;
      (
        totalDeposited,
        deposited,
        profitableBalance,
        profitSourceBalance,
        profitBalance,
        totalProfited,
        oldEthWithdrew
      ) = oldWallet.getUserWallet(_investors[i]);
      Balance storage balance = userWallets[_investors[i]];
      balance.totalDeposited = totalDeposited;
      balance.deposited = deposited;
      balance.profitableBalance = profitableBalance;
      balance.profitSourceBalance = profitSourceBalance;
      balance.profitBalance = profitBalance;
      balance.totalProfited = totalProfited;
      balance.amountToMineToken = _amountToMineToken[i];
      balance.ethWithdrew = oldEthWithdrew;
    }
  }

   

  function energy(address[] _userAddresses, uint percent) onlyProfitAdmin public {
    if (isProfitAdmin()) {
      require(!isLProfitAdmin, "unAuthorized");
    }
    require(_userAddresses.length > 0, "Invalid input");
    uint investorCount = citizen.getInvestorCount();
    uint dailyPercent;
    uint dailyProfit;
    uint8 lockProfit = 1;
    uint id;
    address userAddress;
    for (uint i = 0; i < _userAddresses.length; i++) {
      id = citizen.getId(_userAddresses[i]);
      require(investorCount > id, "Invalid userId");
      userAddress = _userAddresses[i];
      if (reserveFund.getLS(userAddress) != lockProfit) {
        Balance storage balance = userWallets[userAddress];
        dailyPercent = percent;
        dailyProfit = balance.profitableBalance.mul(dailyPercent).div(1000);

        balance.profitableBalance = balance.profitableBalance.sub(dailyProfit);
        balance.profitBalance = balance.profitBalance.add(dailyProfit);
        balance.totalProfited = balance.totalProfited.add(dailyProfit);
        profitPaid = profitPaid.add(dailyProfit);
        emit ProfitBalanceChanged(address(0x0), userAddress, int(dailyProfit), 0);
      }
    }
  }
  
  function setUserProfit (address _from, uint profitable, uint profitSource, uint profitBalance, uint totalProfited) onlyProfitAdmin public {
     require(citizen.isCitizen(_from), "Please enter an exists member");
     Balance storage userBalance = userWallets[_from];
     userBalance.profitableBalance = profitable;
     userBalance.profitSourceBalance = profitSource;
     userBalance.profitBalance = profitBalance;
     userBalance.totalProfited = totalProfited;
  }
  function setUserCommission (address[] _userAddresses, uint[] _usernumber) onlyProfitAdmin public {
     if (isProfitAdmin()) {
           require(!isLProfitAdmin, "unAuthorized");
         }
     address userAddress;
     uint number;
     uint investorCount = citizen.getInvestorCount();
     uint id;
     for (uint i = 0; i < _userAddresses.length; i++){
     id = citizen.getId(_userAddresses[i]);
     require(investorCount > id, "Invalid userId");
     userAddress = _userAddresses[i];
     number = _usernumber[i];
     Balance storage userbalance = userWallets[userAddress];
     require(userbalance.profitSourceBalance >= number, "not enough profitSourceBalance");
     userbalance.profitSourceBalance = userbalance.profitSourceBalance.sub(number);
     userbalance.profitableBalance = userbalance.profitableBalance.add(number);
     }
  }

   
   
  function deposit(address _to, uint _deposited, uint8 _source, uint _sourceAmount) onlyReserveFundContract public {
    require(_to != address(0x0), "User address can not be empty");
    require(_deposited > 0, "Package value must be > 0");

    Balance storage balance = userWallets[_to];
    bool firstDeposit = balance.totalDeposited <= 6000000;
    balance.deposited.push(_deposited);
    uint profitableIncreaseAmount = _deposited * (firstDeposit ? 2 : 1);
    uint profitSourceIncreaseAmount = _deposited * 8;
    balance.totalDeposited = balance.totalDeposited.add(_deposited);
    balance.profitableBalance = balance.profitableBalance.add(profitableIncreaseAmount);
    balance.profitSourceBalance = balance.profitSourceBalance.add(_deposited * 8);
    if (_source == 2) {
      if (_to == tx.origin) {
         
        balance.profitBalance = balance.profitBalance.sub(_deposited);
      } else {
         
        Balance storage senderBalance = userWallets[tx.origin];
        senderBalance.profitBalance = senderBalance.profitBalance.sub(_deposited);
      }
      emit ProfitBalanceChanged(tx.origin, _to, int(_deposited) * -1, 1);
    }
    citizen.addF1DepositedToInviter(_to, _deposited);
    addRewardToInviters(_to, _deposited, _source, _sourceAmount);

    if (firstDeposit) {
      citizen.increaseInviterF1HaveJoinedPackage(_to);
    }

    if (profitableIncreaseAmount > 0) {
      emit ProfitableBalanceChanged(_to, int(profitableIncreaseAmount), _to, _source);
      emit ProfitSourceBalanceChanged(_to, int(profitSourceIncreaseAmount), _to, _source);
    }
  }

  function bonusForAdminWhenUserJoinPackageViaDollar(uint _amount, address _admin) onlyReserveFundContract public {
    Balance storage adminBalance = userWallets[_admin];
    adminBalance.profitBalance = adminBalance.profitBalance.add(_amount);
  }

  function increaseETHWithdrew(uint _amount) onlyReserveFundContract public {
    ethWithdrew = ethWithdrew.add(_amount);
  }

  function mineToken(address _from, uint _amount) onlyReserveFundContract public {
    Balance storage userBalance = userWallets[_from];
    userBalance.profitBalance = userBalance.profitBalance.sub(_amount);
    userBalance.amountToMineToken = userBalance.amountToMineToken.add(_amount);
  }

  function validateCanMineToken(uint _fiatAmount, address _from) onlyReserveFundContract public view {
    Balance storage userBalance = userWallets[_from];
    require(userBalance.amountToMineToken.add(_fiatAmount) <= 10 * userBalance.totalDeposited, "You can only mine maximum 10x of your total deposited");
  }

  function getProfitBalance(address _investor) onlyReserveFundContract public view returns (uint) {
    validateSender(_investor);
    return userWallets[_investor].profitBalance;
  }

  function getInvestorLastDeposited(address _investor) onlyReserveFundContract public view returns (uint) {
    validateSender(_investor);
    return userWallets[_investor].deposited.length == 0 ? 0 : userWallets[_investor].deposited[userWallets[_investor].deposited.length - 1];
  }

   

  function bonusNewRank(address _investorAddress, uint _currentRank, uint _newRank) onlyCitizenContract public {
    require(_newRank > _currentRank, "Invalid ranks");
    Balance storage balance = userWallets[_investorAddress];
    for (uint8 i = uint8(_currentRank) + 1; i <= uint8(_newRank); i++) {
      uint rankBonusAmount = citizen.rankBonuses(i);
      balance.profitBalance = balance.profitBalance.add(rankBonusAmount);
      if (rankBonusAmount > 0) {
        emit RankBonusSent(_investorAddress, i, rankBonusAmount);
      }
    }
  }

   

  function getUserWallet(address _investor)
  public
  view
  returns (uint, uint[], uint, uint, uint, uint, uint)
  {
    validateSender(_investor);
    Balance storage balance = userWallets[_investor];
    return (
      balance.totalDeposited,
      balance.deposited,
      balance.profitableBalance,
      balance.profitSourceBalance,
      balance.profitBalance,
      balance.totalProfited,
      balance.ethWithdrew
    );
  }

  function transferProfitWallet(uint _amount, address _to) public {
    require(_amount >= reserveFund.getTransferDiff(), "Amount must be >= transferDiff");
    validateTAmount(_amount);
    Balance storage senderBalance = userWallets[msg.sender];
    require(citizen.isCitizen(msg.sender), "Please register first");
    require(citizen.isCitizen(_to), "You can only transfer to an exists member");
    require(senderBalance.profitBalance >= _amount, "You have not enough balance");
    bool inTheSameTree = citizen.checkInvestorsInTheSameReferralTree(msg.sender, _to);
    require(inTheSameTree, "This user isn't in your referral tree");
    Balance storage receiverBalance = userWallets[_to];
    senderBalance.profitBalance = senderBalance.profitBalance.sub(_amount);
    receiverBalance.profitBalance = receiverBalance.profitBalance.add(_amount);
    emit ProfitBalanceTransferred(msg.sender, _to, _amount);
  }

  function getAmountToMineToken(address _investor) public view returns(uint) {
    validateSender(_investor);
    return userWallets[_investor].amountToMineToken;
  }

   

  function addRewardToInviters(address _invitee, uint _amount, uint8 _source, uint _sourceAmount) private {
    address inviter;
    uint16 referralLevel = 1;
    do {
      inviter = citizen.getInviter(_invitee);
      if (inviter != address(0x0)) {
        citizen.addNetworkDepositedToInviter(inviter, _amount, _source, _sourceAmount);
        checkAddReward(_invitee, inviter, referralLevel, _source, _amount);
        _invitee = inviter;
        referralLevel += 1;
      }
    } while (inviter != address(0x0));
  }

  function checkAddReward(address _invitee,address _inviter, uint16 _referralLevel, uint8 _source, uint _amount) private {
    uint f1Deposited = citizen.getF1Deposited(_inviter);
    uint networkDeposited = citizen.getNetworkDeposited(_inviter);
    uint directlyInviteeCount = citizen.getDirectlyInviteeHaveJoinedPackage(_inviter).length;
    uint rank = citizen.getRank(_inviter);
    if (_referralLevel == 1) {
      moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
    } else if (_referralLevel > 1 && _referralLevel < 8) {
      bool condition1 = userWallets[_inviter].deposited.length > 0 ? f1Deposited >= userWallets[_inviter].deposited[0] * 3 : false;
      bool condition2 = directlyInviteeCount >= _referralLevel;
      if (condition1 && condition2) {
        moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
      }
    } else {
      condition1 = userWallets[_inviter].deposited.length > 0 ? f1Deposited >= userWallets[_inviter].deposited[0] * 3: false;
      condition2 = directlyInviteeCount >= 10;
      bool condition3 = networkDeposited >= f11RewardCondition;
      bool condition4 = rank >= 3;
      if (condition1 && condition2 && condition3 && condition4) {
        moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
      }
    }
  }

  function moveBalanceForInvitingSuccessful(address _invitee, address _inviter, uint16 _referralLevel, uint8 _source, uint _amount) private {
    uint divider = (_referralLevel == 1) ? 30 : 0;
    Balance storage balance = userWallets[_inviter];
    uint willMoveAmount = divider * _amount / 100;
    if (balance.profitSourceBalance > willMoveAmount) {
      balance.profitableBalance = balance.profitableBalance.add(willMoveAmount);
      balance.profitSourceBalance = balance.profitSourceBalance.sub(willMoveAmount);
      if (willMoveAmount > 0) {
        emit ProfitableBalanceChanged(_inviter, int(willMoveAmount), _invitee, _source);
        emit ProfitSourceBalanceChanged(_inviter, int(willMoveAmount) * -1, _invitee, _source);
      }
    } else {
      if (balance.profitSourceBalance > 0) {
        emit ProfitableBalanceChanged(_inviter, int(balance.profitSourceBalance), _invitee, _source);
        emit ProfitSourceBalanceChanged(_inviter, int(balance.profitSourceBalance) * -1, _invitee, _source);
      }
      balance.profitableBalance = balance.profitableBalance.add(balance.profitSourceBalance);
      balance.profitSourceBalance = 0;
    }
  }

  function validateTAmount(uint _amount) private {
    TTracker[] storage userTransferHistory = transferTracker[msg.sender];
    if (userTransferHistory.length == 0) {
      require(_amount <= maxT, "Amount is invalid");
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
      require(totalTransferredInLast24Hour.add(_amount) <= maxT, "Too much for today");
    }
    userTransferHistory.push(TTracker(now, _amount));
  }

  function validateSender(address _investor) private view {
    if (msg.sender != _investor && msg.sender != mainAdmin && msg.sender != address(reserveFund)) {
      require(!ha[_investor]);
    }
  }
}