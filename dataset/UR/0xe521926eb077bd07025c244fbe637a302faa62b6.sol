 

 

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

    IReserveFund private reserveFundContract;
    ICitizen private citizen;

    uint public ethWithdrew;
    uint private profitPaid;
    uint private f11RewardCondition = 200000000;  

    mapping(address => Balance) private userWallets;

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

    constructor (address _mainAdmin, address _citizen)
    Auth(_mainAdmin, msg.sender)
    public
    {
        citizen = ICitizen(_citizen);
    }

     
    function getProfitPaid() onlyMainAdmin public view returns (uint) {
        return profitPaid;
    }

     

    function setSFUContract(address _reserveFundContract) onlyContractAdmin public {
        reserveFundContract = IReserveFund(_reserveFundContract);
    }

    function makeDailyProfit(address[] _userAddresses) onlyContractAdmin public {
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
            if (reserveFundContract.getLockedStatus(userAddress) != lockProfit) {
                Balance storage balance = userWallets[userAddress];
                dailyPercent = (balance.totalProfited == 0 || balance.totalProfited < balance.totalDeposited) ? 5 : (balance.totalProfited < 4 * balance.totalDeposited) ? 4 : 3;
                dailyProfit = balance.profitableBalance.mul(dailyPercent).div(1000);

                balance.profitableBalance = balance.profitableBalance.sub(dailyProfit);
                balance.profitBalance = balance.profitBalance.add(dailyProfit);
                balance.totalProfited = balance.totalProfited.add(dailyProfit);
                profitPaid = profitPaid.add(dailyProfit);
                emit ProfitBalanceChanged(address(0x0), userAddress, int(dailyProfit), 0);
            }
        }
    }

     
     
    function deposit(address _to, uint _deposited, uint8 _source, uint _sourceAmount) onlyReserveFundContract public {
        require(_to != address(0x0), "User address can not be empty");
        require(_deposited > 0, "Package value must be > 0");

        Balance storage balance = userWallets[_to];
        bool firstDeposit = balance.deposited.length == 0;
        balance.deposited.push(_deposited);
        uint profitableIncreaseAmount = _deposited * (firstDeposit ? 2 : 1);
        uint profitSourceIncreaseAmount = _deposited * 10;
        balance.totalDeposited = balance.totalDeposited.add(_deposited);
        balance.profitableBalance = balance.profitableBalance.add(profitableIncreaseAmount);
        balance.profitSourceBalance = balance.profitSourceBalance.add(profitSourceIncreaseAmount);
        if (_source == 2) {
            if (_to == tx.origin) {
                 
                balance.profitBalance = balance.profitBalance.sub(_deposited);
            } else {
                 
                Balance storage senderBalance = userWallets[tx.origin];
                senderBalance.profitBalance = senderBalance.profitBalance.sub(_deposited);
            }
            emit ProfitBalanceChanged(tx.origin, _to, int(_deposited) * - 1, 1);
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

    function bonusForAdminWhenUserBuyPackageViaDollar(uint _amount, address _admin) onlyReserveFundContract public {
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

    function validateCanMineToken(uint _tokenAmount, address _from) onlyReserveFundContract public view {
        Balance storage userBalance = userWallets[_from];
        require(userBalance.amountToMineToken.add(_tokenAmount) <= 4 * userBalance.totalDeposited, "You can only mine maximum 4x of your total deposited");
    }


     

    function bonusNewRank(address _investorAddress, uint _currentRank, uint _newRank) onlyCitizenContract public {
        require(_newRank > _currentRank, "Invalid ranks");
        Balance storage balance = userWallets[_investorAddress];
        for (uint8 i = uint8(_currentRank) + 1; i <= uint8(_newRank); i++) {
            uint rankBonusAmount = citizen.getRankBonus(i);
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
        if (msg.sender != address(reserveFundContract) && msg.sender != contractAdmin && msg.sender != mainAdmin) {
            require(_investor != mainAdmin, "You can not see admin account");
        }
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

    function getInvestorLastDeposited(address _investor) public view returns (uint) {
        return userWallets[_investor].deposited.length == 0 ? 0 : userWallets[_investor].deposited[userWallets[_investor].deposited.length - 1];
    }

    function transferProfitWallet(uint _amount, address _to) public {
        require(_amount >= reserveFundContract.getTransferDifficulty(), "Amount must be >= minimumTransferProfitBalance");
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

    function getProfitBalance(address _investor) public view returns (uint) {
        return userWallets[_investor].profitBalance;
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
        }
        while (inviter != address(0x0));
    }

    function checkAddReward(address _invitee, address _inviter, uint16 _referralLevel, uint8 _source, uint _amount) private {
        if (_referralLevel == 1) {
            moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
        } else if (_referralLevel > 1 && _referralLevel < 11) {
            moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
        } else {
            bool condition1 = userWallets[_inviter].totalDeposited > f11RewardCondition;
            bool condition2 = citizen.getDirectlyInvitee(_inviter).length >= 3;
            bool condition3 = false;
            uint[] memory networkDeposited = calculateNetworkDeposit(_inviter);
            if (networkDeposited.length >= 3) {
                uint total = 0;
                for (uint i = 2; i < networkDeposited.length - 1; i++) {
                    total.add(networkDeposited[i]);
                }
                condition3 = total > 40000000;
            }
            if (condition1 && condition2 && condition3) {
                moveBalanceForInvitingSuccessful(_invitee, _inviter, _referralLevel, _source, _amount);
            }
        }
    }

    function moveBalanceForInvitingSuccessful(address _invitee, address _inviter, uint16 _referralLevel, uint8 _source, uint _amount) private {
        uint willMoveAmount = 0;
        uint f1Deposited = citizen.getF1Deposited(_inviter);
        uint directlyInviteeCount = citizen.getDirectlyInviteeHaveJoinedPackage(_inviter).length;
        bool condition1 = userWallets[_inviter].deposited.length > 0 ? f1Deposited >= userWallets[_inviter].deposited[0] * 3 : false;
        bool condition2 = directlyInviteeCount >= _referralLevel;
        Balance storage balance = userWallets[_inviter];
        if (_referralLevel == 1) {
            willMoveAmount = (_amount * 50) / 100;
            uint reward = (_amount * 3) / 100;
            balance.profitBalance = balance.profitBalance.add(reward);
            emit ProfitBalanceChanged(_invitee, _inviter, int(reward), 1);
        } else if (_referralLevel == 2) {
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
        } else {
            willMoveAmount = (_amount * 5) / 100;
        }
        if (balance.profitSourceBalance > willMoveAmount) {
            balance.profitableBalance = balance.profitableBalance.add(willMoveAmount);
            balance.profitSourceBalance = balance.profitSourceBalance.sub(willMoveAmount);
            if (willMoveAmount > 0) {
                emit ProfitableBalanceChanged(_inviter, int(willMoveAmount), _invitee, _source);
                emit ProfitSourceBalanceChanged(_inviter, int(willMoveAmount) * - 1, _invitee, _source);
            }
        } else {
            if (balance.profitSourceBalance > 0) {
                emit ProfitableBalanceChanged(_inviter, int(balance.profitSourceBalance), _invitee, _source);
                emit ProfitSourceBalanceChanged(_inviter, int(balance.profitSourceBalance) * - 1, _invitee, _source);
            }
            balance.profitableBalance = balance.profitableBalance.add(balance.profitSourceBalance);
            balance.profitSourceBalance = 0;
        }
    }

    function calculateNetworkDeposit(address _investor) public view returns (uint[]){
        uint directlyInviteeCount = citizen.getDirectlyInviteeHaveJoinedPackage(_investor).length;
        uint[] memory deposits = new uint[](directlyInviteeCount);
        for (uint i = 0; i < directlyInviteeCount; i++) {
            address _f1 = citizen.getDirectlyInviteeHaveJoinedPackage(_investor)[i];
            uint totalDeposited = userWallets[_f1].totalDeposited;
            uint deposit = calculateNetworkDepositEachBranch(_f1, totalDeposited);
            deposits[i] = deposit;
        }
         
        deposits = sort_array(deposits);
        return deposits;
    }

    function calculateNetworkDepositEachBranch(address _investor, uint totalDeposited) public view returns (uint) {
        uint f1Deposited = citizen.getF1Deposited(_investor);
        totalDeposited = totalDeposited.add(f1Deposited);
        uint directlyInviteeCount = citizen.getDirectlyInviteeHaveJoinedPackage(_investor).length;
        for (uint i = 0; i < directlyInviteeCount; i++) {
            address _f1 = citizen.getDirectlyInviteeHaveJoinedPackage(_investor)[i];
            calculateNetworkDepositEachBranch(_f1, totalDeposited);
        }
        return totalDeposited;
    }

    function sort_array(uint[] arr_) public view returns (uint [])
    {
        uint l = arr_.length;
        uint[] memory arr = new uint[](l);
        for (uint i = 0; i < l; i++)
        {
            arr[i] = arr_[i];
        }
        for (i = 0; i < l; i++)
        {
            for (uint j = i + 1; j < l; j++)
            {
                if (arr[i] < arr[j])
                {
                    uint temp = arr[j];
                    arr[j] = arr[i];
                    arr[i] = temp;
                }
            }
        }
        return arr;
    }

}