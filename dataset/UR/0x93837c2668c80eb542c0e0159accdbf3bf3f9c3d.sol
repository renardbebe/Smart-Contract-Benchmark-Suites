 

pragma solidity 0.4.25;

contract Auth {

    address internal mainAdmin;
    address internal contractAdmin;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    constructor(
        address _mainAdmin,
        address _contractAdmin
    )
    internal
    {
        mainAdmin = _mainAdmin;
        contractAdmin = _contractAdmin;
    }

    modifier onlyAdmin() {
        require(isMainAdmin() || isContractAdmin(), "onlyAdmin");
        _;
    }

    modifier onlyMainAdmin() {
        require(isMainAdmin(), "onlyMainAdmin");
        _;
    }

    modifier onlyContractAdmin() {
        require(isContractAdmin(), "onlyContractAdmin");
        _;
    }

    function transferOwnership(address _newOwner) onlyContractAdmin internal {
        require(_newOwner != address(0x0));
        contractAdmin = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function isMainAdmin() public view returns (bool) {
        return msg.sender == mainAdmin;
    }

    function isContractAdmin() public view returns (bool) {
        return msg.sender == contractAdmin;
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
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
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

    function getRankBonus(uint _index) external view returns (uint);

    function getUserAddresses(uint _index) external view returns (address);

    function getSubscribers(address _investor) external view returns (uint);

    function increaseInviterF1HaveJoinedPackage(address _invitee) external;

    function isCitizen(address _user) view external returns (bool);

    function register(address _user, string _userName, address _inviter) external returns (uint);

    function showInvestorInfo(address _investorAddress) external view returns (uint, string memory, address, address[], uint, uint, uint, uint);
}

interface IReserveFund {

    function getLockedStatus(address _investor) view external returns (uint8);

    function getTransferDifficulty() view external returns (uint);
}

interface IWalletStore {

    function makeDailyProfit(address _user, uint dailyProfit) external;

    function bonusForAdminWhenUserBuyPackageViaDollar(uint _amount, address _admin) external;

    function increaseETHWithdrew(uint _amount) external;

    function mineToken(address _from, uint _amount) external;

    function getProfitPaid() view external returns (uint);

    function setTotalDeposited(address _investor, uint _totalDeposited) external;

    function getTotalDeposited(address _investor) view external returns (uint);

    function pushDeposited(address _investor, uint _deposited) external;

    function getDeposited(address _investor) view external returns (uint[]);

    function setProfitableBalance(address _investor, uint _profitableBalance) external;

    function getProfitableBalance(address _investor) view external returns (uint);

    function setProfitSourceBalance(address _investor, uint _profitSourceBalance) external;

    function getProfitSourceBalance(address _investor) view external returns (uint);

    function setProfitBalance(address _investor, uint _profitBalance) external;

    function getProfitBalance(address _investor) view external returns (uint);

    function setTotalProfited(address _investor, uint _totalProfited) external;

    function getTotalProfited(address _investor) view external returns (uint);

    function setAmountToMineToken(address _investor, uint _amountToMineToken) external;

    function getAmountToMineToken(address _investor) view external returns (uint);

    function getEthWithdrewOfInvestor(address _investor) view external returns (uint);

    function getEthWithdrew() view external returns (uint);

    function getUserWallet(address _investor) view external returns (uint, uint[], uint, uint, uint, uint, uint, uint);

    function getInvestorLastDeposited(address _investor) view external returns (uint);

    function getF11RewardCondition() view external returns (uint);
}

contract Wallet is Auth {
    using SafeMath for uint;

    IReserveFund private reserveFundContract;
    ICitizen private citizen;
    IWalletStore private walletStore;

    modifier onlyReserveFundContract() {
        require(msg.sender == address(reserveFundContract), "onlyReserveFundContract");
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

    constructor (address _mainAdmin) Auth(_mainAdmin, msg.sender) public {}


     

    function setReserveFundContract(address _reserveFundContract) onlyContractAdmin public {
        reserveFundContract = IReserveFund(_reserveFundContract);
    }

    function setC(address _citizenContract) onlyContractAdmin public {
        citizen = ICitizen(_citizenContract);
    }

    function setWS(address _walletStore) onlyContractAdmin public {
        walletStore = IWalletStore(_walletStore);
    }

    function updateContractAdmin(address _newAddress) onlyContractAdmin public {
        transferOwnership(_newAddress);
    }

    function makeDailyProfit(address[] _users) onlyContractAdmin public {
        require(_users.length > 0, "Invalid input");
        uint investorCount = citizen.getInvestorCount();
        uint dailyPercent;
        uint dailyProfit;
        uint8 lockProfit = 1;
        uint id;
        address userAddress;
        for (uint i = 0; i < _users.length; i++) {
            id = citizen.getId(_users[i]);
            require(investorCount > id, "Invalid userId");
            userAddress = _users[i];
            if (reserveFundContract.getLockedStatus(userAddress) != lockProfit) {
                uint totalDeposited = walletStore.getTotalDeposited(userAddress);
                uint profitableBalance = walletStore.getProfitableBalance(userAddress);
                uint totalProfited = walletStore.getTotalProfited(userAddress);

                dailyPercent = (totalProfited == 0 || totalProfited < totalDeposited) ? 5 : (totalProfited < 4 * totalDeposited) ? 4 : 3;
                dailyProfit = profitableBalance.mul(dailyPercent).div(1000);

                walletStore.makeDailyProfit(userAddress, dailyProfit);
                emit ProfitBalanceChanged(address(0x0), userAddress, int(dailyProfit), 0);
            }
        }
    }

     
     
    function deposit(address _to, uint _deposited, uint8 _source, uint _sourceAmount)
    onlyReserveFundContract
    public {
        require(_to != address(0x0), "User address can not be empty");
        require(_deposited > 0, "Package value must be > 0");

        uint totalDeposited = walletStore.getTotalDeposited(_to);
        uint[] memory deposited = walletStore.getDeposited(_to);
        uint profitableBalance = walletStore.getProfitableBalance(_to);
        uint profitSourceBalance = walletStore.getProfitSourceBalance(_to);
        uint profitBalance = getProfitBalance(_to);


        bool firstDeposit = deposited.length == 0;
        walletStore.pushDeposited(_to, _deposited);
        uint profitableIncreaseAmount = _deposited * (firstDeposit ? 2 : 1);
        uint profitSourceIncreaseAmount = _deposited * 10;
        walletStore.setTotalDeposited(_to, totalDeposited.add(_deposited));
        walletStore.setProfitableBalance(_to, profitableBalance.add(profitableIncreaseAmount));
        walletStore.setProfitSourceBalance(_to, profitSourceBalance.add(profitSourceIncreaseAmount));
        if (_source == 2) {
            if (_to == tx.origin) {
                 
                walletStore.setProfitBalance(_to, profitBalance.sub(_deposited));
            } else {
                 
                uint senderProfitBalance = getProfitBalance(tx.origin);
                walletStore.setProfitBalance(tx.origin, senderProfitBalance.sub(_deposited));
            }
            emit ProfitBalanceChanged(tx.origin, _to, int(_deposited) * - 1, 1);
        }
        citizen.addF1DepositedToInviter(_to, _deposited);
        addRewardToInviter(_to, _deposited, _source, _sourceAmount);

        if (firstDeposit) {
            citizen.increaseInviterF1HaveJoinedPackage(_to);
        }

        if (profitableIncreaseAmount > 0) {
            emit ProfitableBalanceChanged(_to, int(profitableIncreaseAmount), _to, _source);
            emit ProfitSourceBalanceChanged(_to, int(profitSourceIncreaseAmount), _to, _source);
        }
    }

     

    function bonusNewRank(address _investor, uint _currentRank, uint _newRank)
    onlyCitizenContract
    public {
        require(_newRank > _currentRank, "Invalid ranks");
        uint profitBalance = getProfitBalance(_investor);

        for (uint8 i = uint8(_currentRank) + 1; i <= uint8(_newRank); i++) {
            uint rankBonusAmount = citizen.getRankBonus(i);
            walletStore.setProfitBalance(_investor, profitBalance.add(rankBonusAmount));
            if (rankBonusAmount > 0) {
                emit RankBonusSent(_investor, i, rankBonusAmount);
            }
        }
    }

     

    function getUserWallet(address _investor)
    public
    view
    returns (uint, uint[], uint, uint, uint, uint, uint, uint)
    {
        if (msg.sender != address(reserveFundContract) && msg.sender != contractAdmin && msg.sender != mainAdmin) {
            require(_investor != mainAdmin, "You can not see admin account");
        }

        return walletStore.getUserWallet(_investor);
    }

    function getInvestorLastDeposited(address _investor)
    public
    view
    returns (uint) {
        return walletStore.getInvestorLastDeposited(_investor);
    }

    function transferProfitWallet(uint _amount, address _to)
    public {
        require(_amount >= reserveFundContract.getTransferDifficulty(), "Amount must be >= minimumTransferProfitBalance");
        uint profitBalanceOfSender = getProfitBalance(msg.sender);

        require(citizen.isCitizen(msg.sender), "Please register first");
        require(citizen.isCitizen(_to), "You can only transfer to an exists member");
        require(profitBalanceOfSender >= _amount, "You have not enough balance");
        bool inTheSameTree = citizen.checkInvestorsInTheSameReferralTree(msg.sender, _to);
        require(inTheSameTree, "This user isn't in your referral tree");

        uint profitBalanceOfReceiver = getProfitBalance(_to);
        walletStore.setProfitBalance(msg.sender, profitBalanceOfSender.sub(_amount));
        walletStore.setProfitBalance(_to, profitBalanceOfReceiver.add(_amount));
        emit ProfitBalanceTransferred(msg.sender, _to, _amount);
    }

    function getProfitBalance(address _investor)
    public
    view
    returns (uint) {
        return walletStore.getProfitBalance(_investor);
    }

     

    function addRewardToInviter(address _invitee, uint _amount, uint8 _source, uint _sourceAmount)
    private {
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
        }
        while (inviter != address(0x0));
    }

    function checkAddReward(address _invitee, address _inviter, uint16 _referralLevel, uint8 _source, uint _amount)
    private {
        if (_referralLevel == 1) {
            moveBalanceForInviting(_invitee, _inviter, _referralLevel, _source, _amount);
        } else if (_referralLevel > 1 && _referralLevel < 11) {
            moveBalanceForInviting(_invitee, _inviter, _referralLevel, _source, _amount);
        } else {
            uint f11RewardCondition = walletStore.getF11RewardCondition();
            uint totalDeposited = walletStore.getTotalDeposited(_inviter);
            uint rank = citizen.getRank(_inviter);

            bool condition1 = totalDeposited > f11RewardCondition;
            bool condition2 = rank >= 1;

            if (condition1 && condition2) {
                moveBalanceForInviting(_invitee, _inviter, _referralLevel, _source, _amount);
            }
        }
    }

    function moveBalanceForInviting(address _invitee, address _inviter, uint16 _referralLevel, uint8 _source, uint _amount)
    private
    {
        uint willMoveAmount = 0;
        uint[] memory deposited = walletStore.getDeposited(_inviter);
        uint profitableBalance = walletStore.getProfitableBalance(_inviter);
        uint profitSourceBalance = walletStore.getProfitSourceBalance(_inviter);
        uint profitBalance = getProfitBalance(_inviter);
        uint f1Deposited = citizen.getF1Deposited(_inviter);
        uint directlyInviteeCount = citizen.getDirectlyInviteeHaveJoinedPackage(_inviter).length;

        if (_referralLevel == 1) {
            willMoveAmount = (_amount * 50) / 100;
            uint reward = (_amount * 3) / 100;
            walletStore.setProfitBalance(_inviter, profitBalance.add(reward));
            emit ProfitBalanceChanged(_invitee, _inviter, int(reward), 1);
        }
        if (profitSourceBalance == 0) {
            return;
        }

        bool condition1 = deposited.length > 0 ? f1Deposited >= minArray(deposited) * 3 : false;
        bool condition2 = directlyInviteeCount >= _referralLevel;

        if (_referralLevel == 2) {
            willMoveAmount = (_amount * 20) / 100;
            if (condition1 && condition2) {
                willMoveAmount.add((_amount * 20) / 100);
            }
        } else if (_referralLevel == 3) {
            willMoveAmount = (_amount * 15) / 100;
            if (condition1 && condition2) {
                willMoveAmount.add((_amount * 15) / 100);
            }
        } else if (_referralLevel == 4 || _referralLevel == 5) {
            willMoveAmount = (_amount * 10) / 100;
            if (condition1 && condition2) {
                willMoveAmount.add((_amount * 10) / 100);
            }
        } else if (_referralLevel >= 6 || _referralLevel <= 10) {
            willMoveAmount = (_amount * 5) / 100;
            if (condition1 && condition2) {
                willMoveAmount.add((_amount * 5) / 100);
            }
        } else if (_referralLevel > 10 && condition1 && condition2) {
            willMoveAmount = (_amount * 5) / 100;
        }
        if (profitSourceBalance > willMoveAmount) {
            walletStore.setProfitableBalance(_inviter, profitableBalance.add(willMoveAmount));
            walletStore.setProfitSourceBalance(_inviter, profitSourceBalance.sub(willMoveAmount));
            notifyMoveSuccess(_invitee, _inviter, _source, willMoveAmount);
        } else {
            walletStore.setProfitableBalance(_inviter, profitableBalance.add(profitSourceBalance));
            walletStore.setProfitSourceBalance(_inviter, 0);
            notifyMoveSuccess(_invitee, _inviter, _source, profitSourceBalance);
        }
    }


    function notifyMoveSuccess(address _invitee, address _inviter, uint8 _source, uint move)
    private
    {
        emit ProfitableBalanceChanged(_inviter, int(move), _invitee, _source);
        emit ProfitSourceBalanceChanged(_inviter, int(move) * - 1, _invitee, _source);
    }

    function minArray(uint[] _arr)
    internal
    pure
    returns (uint) {
        uint min = _arr[0];
        for (uint i; i < _arr.length; i++) {
            if (min > _arr[i]) {
                min = _arr[i];
            }
        }
        return min;
    }

}