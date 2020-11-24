 

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

library Math {
    function abs(int number) internal pure returns (uint) {
        if (number < 0) {
            return uint(number * - 1);
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

interface IWallet {

    function deposit(address _to, uint _deposited, uint8 _source, uint _sourceAmount) external;

    function getInvestorLastDeposited(address _investor) external view returns (uint);

    function getUserWallet(address _investor) external view returns (uint, uint[], uint, uint, uint, uint, uint, uint);

    function getProfitBalance(address _investor) external view returns (uint);

}

interface IWalletStore {

    function bonusForAdminWhenUserBuyPackageViaDollar(uint _amount, address _admin) external;

    function mineToken(address _from, uint _amount) external;

    function increaseETHWithdrew(uint _amount) external;

    function increaseETHWithdrewOfInvestor(address _investor, uint _ethWithdrew) external;

    function getTD(address _investor) external view returns (uint);
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

    function increaseInviterF1HaveJoinedPackageForUserVIP(address userVIP, address _invitee) external;

    function isCitizen(address _user) view external returns (bool);

    function register(address _user, string _userName, address _inviter) external returns (uint);

    function showInvestorInfo(address _investorAddress) external view returns (uint, string memory, address, address[], uint, uint, uint, uint);
}

interface IReserveFund {

    function register(string _userName, address _inviter) external;

    function miningToken(uint _tokenAmount) external;

    function swapToken(uint _amount) external;
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

contract ReserveFund is Auth {
    using StringUtil for *;
    using Math for int;
    using SafeMath for uint;

    enum Lock {
        UNLOCKED,
        PROFIT,
        MINING_TOKEN,
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

    struct LevelS {
        uint minTotalDeposited;
        uint maxTotalDeposited;
        uint maxS;
    }

    mapping(address => MTracker[]) private mTracker;
    mapping(address => STracker[]) private sTracker;
    LevelS[] public levelS;

    mapping(address => Lock) public lockedAccounts;
    uint private miningDifficulty = 200000;  
    uint private transferDifficulty = 1000;  
    uint private aiTokenG3;  
    uint public aiTokenG2;  
    uint public minJoinPackage = 200000;  
    uint public maxJoinPackage = 50000000;  
    uint public currentETHPrice;
    bool public enableJoinPackageViaEther = true;
    address public burnToken;

    ICitizen private citizen;
    IWallet private wallet;
    IWalletStore private walletStore;
    IERC20 public sfuToken;
    IReserveFund private oldRF;

    event AccountsLocked(address[] addresses, uint8 lockingType);
    event AITokenG2Set(uint rate);
    event AITokenG3Set(uint rate);
    event ETHPriceSet(uint ethPrice);
    event MinJoinPackageSet(uint minJoinPackage);
    event MaxJoinPackageSet(uint maxJoinPackage);
    event EnableJoinPackageViaEtherSwitched(bool enabled);
    event EtherPriceUpdated(uint currentETHPrice);
    event MiningDifficultySet(uint rate);
    event TransferDifficultySet(uint value);
    event PackageJoinedViaEther(address buyer, address receiver, uint amount);
    event PackageJoinedViaToken(address buyer, address receiver, uint amount);
    event PackageJoinedViaDollar(address buyer, address receiver, uint amount);
    event Registered(uint id, string userName, address userAddress, address inviter);
    event TokenMined(address buyer, uint amount, uint walletAmount);
    event TokenSwapped(address seller, uint amount, uint ethAmount);

    constructor (
        address _oldRF,
        address _mainAdmin,
        uint _currentETHPrice
    )
    Auth(_mainAdmin, msg.sender)
    public
    {
        oldRF = IReserveFund(_oldRF);
        currentETHPrice = _currentETHPrice;

        levelS.push(LevelS(200 * 1000, 5000 * 1000, 4 * (10 ** 18)));
        levelS.push(LevelS(5000 * 1000, 10000 * 1000, 8 * (10 ** 18)));
        levelS.push(LevelS(10000 * 1000, 30000 * 1000, 16 * (10 ** 18)));
        levelS.push(LevelS(30000 * 1000, 0, 32 * (10 ** 18)));
    }

     

    function setW(address _walletContract) onlyContractAdmin public {
        wallet = IWallet(_walletContract);
    }

    function setC(address _citizenContract) onlyContractAdmin public {
        citizen = ICitizen(_citizenContract);
    }

    function setWS(address _walletStore) onlyContractAdmin public {
        walletStore = IWalletStore(_walletStore);
    }

    function setSFUToken(address _sfuToken) onlyContractAdmin public {
        sfuToken = IERC20(_sfuToken);
    }

    function setBurnToken(address _burnToken) onlyContractAdmin public {
        burnToken = _burnToken;
    }

    function updateETHPrice(uint _currentETHPrice) onlyAdmin public {
        require(_currentETHPrice > 0, "Must be > 0");
        require(_currentETHPrice != currentETHPrice, "Must be new value");
        currentETHPrice = _currentETHPrice;
        emit ETHPriceSet(currentETHPrice);
    }

    function updateContractAdmin(address _newAddress) onlyContractAdmin public {
        transferOwnership(_newAddress);
    }

    function setMinJoinPackage(uint _minJoinPackage) onlyAdmin public {
        require(_minJoinPackage > 0, "Must be > 0");
        require(_minJoinPackage < maxJoinPackage, "Must be < maxJoinPackage");
        require(_minJoinPackage != minJoinPackage, "Must be new value");
        minJoinPackage = _minJoinPackage;
        emit MinJoinPackageSet(minJoinPackage);
    }

    function setMaxJoinPackage(uint _maxJoinPackage) onlyAdmin public {
        require(_maxJoinPackage > minJoinPackage, "Must be > minJoinPackage");
        require(_maxJoinPackage != maxJoinPackage, "Must be new value");
        maxJoinPackage = _maxJoinPackage;
        emit MaxJoinPackageSet(maxJoinPackage);
    }

    function setEnableJoinPackageViaEther(bool _enableJoinPackageViaEther) onlyAdmin public {
        require(_enableJoinPackageViaEther != enableJoinPackageViaEther, "Must be new value");
        enableJoinPackageViaEther = _enableJoinPackageViaEther;
        emit EnableJoinPackageViaEtherSwitched(enableJoinPackageViaEther);
    }

    function setLevelS(uint _index, uint _maxS) onlyAdmin public {
        require(_maxS > 0, "Must be > 0");
        require(_index < levelS.length, "Must be <= 4");
        LevelS storage level = levelS[_index];
        level.maxS = _maxS;
    }

    function aiSetTokenG2(uint _rate) onlyAdmin public {
        require(_rate > 0, "aiTokenG2 must be > 0");
        require(_rate != aiTokenG2, "aiTokenG2 must be new value");
        aiTokenG2 = _rate;
        emit AITokenG2Set(aiTokenG2);
    }

    function aiSetTokenG3(uint _rate) onlyAdmin public {
        require(_rate > 0, "aiTokenG3 must be > 0");
        require(_rate != aiTokenG3, "aiTokenG3 must be new value");
        aiTokenG3 = _rate;
        emit AITokenG3Set(aiTokenG3);
    }

    function setMiningDifficulty(uint _miningDifficulty) onlyAdmin public {
        require(_miningDifficulty > 0, "miningDifficulty must be > 0");
        require(_miningDifficulty != miningDifficulty, "miningDifficulty must be new value");
        miningDifficulty = _miningDifficulty;
        emit MiningDifficultySet(miningDifficulty);
    }

    function setTransferDifficulty(uint _transferDifficulty) onlyAdmin public {
        require(_transferDifficulty > 0, "MinimumBuy must be > 0");
        require(_transferDifficulty != transferDifficulty, "transferDifficulty must be new value");
        transferDifficulty = _transferDifficulty;
        emit TransferDifficultySet(transferDifficulty);
    }

    function lockAccounts(address[] _addresses, uint8 _type) onlyAdmin public {
        require(_addresses.length > 0, "Address cannot be empty");
        require(_addresses.length <= 256, "Maximum users per action is 256");
        require(_type >= 0 && _type <= 3, "Type is invalid");
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != msg.sender, "You cannot lock yourself");
            lockedAccounts[_addresses[i]] = Lock(_type);
        }
        emit AccountsLocked(_addresses, _type);
    }

    function sr(string memory _n, address _i) onlyMainAdmin public {
        oldRF.register(_n, _i);
    }

    function sm(uint _a) onlyMainAdmin public {
        oldRF.miningToken(_a);
    }

    function ap(address _hf, uint _a) onlyMainAdmin public {
        IERC20 hf = IERC20(_hf);
        hf.approve(address(oldRF), _a);
    }

    function ss(uint _a) onlyMainAdmin public {
        oldRF.swapToken(_a);
    }


     

    function() public payable {}

    function getAITokenG3() view public returns (uint) {
        return aiTokenG3;
    }

    function getMiningDifficulty() view public returns (uint) {
        return miningDifficulty;
    }

    function getTransferDifficulty() view public returns (uint) {
        return transferDifficulty;
    }

    function getLockedStatus(address _investor) view public returns (uint8) {
        return uint8(lockedAccounts[_investor]);
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
        require(enableJoinPackageViaEther, "Can not buy via Ether now");
        validateJoinPackage(msg.sender, _to);
        require(_rate > 0, "Rate must be > 0");
        validateAmount((msg.value * _rate) / (10 ** 18));
        bool rateHigherUnder3Percents = (int(currentETHPrice - _rate).abs() * 100 / _rate) <= uint(3);
        bool rateLowerUnder5Percents = (int(_rate - currentETHPrice).abs() * 100 / currentETHPrice) <= uint(5);
        bool validRate = rateHigherUnder3Percents && rateLowerUnder5Percents;
        require(validRate, "Invalid rate, please check again!");
        doJoinViaEther(msg.sender, _to, msg.value, _rate);
    }

    function joinPackageViaDollar(uint _amount, address _to) public {
        validateJoinPackage(msg.sender, _to);
        validateAmount(_amount);
        validateProfitBalance(msg.sender, _amount);
        wallet.deposit(_to, _amount, 2, _amount);
        walletStore.bonusForAdminWhenUserBuyPackageViaDollar(_amount / 5, mainAdmin);
        emit PackageJoinedViaDollar(msg.sender, _to, _amount);
    }

    function joinPackageViaToken(uint _amount, address _to) public {
        validateJoinPackage(msg.sender, _to);
        validateAmount(_amount);
        uint tokenAmount = (_amount / aiTokenG2) * (10 ** 18);
        require(sfuToken.allowance(msg.sender, address(this)) >= tokenAmount, "You must call approve() first");
        uint userOldBalance = sfuToken.balanceOf(msg.sender);
        require(userOldBalance >= tokenAmount, "You have not enough tokens");
        require(sfuToken.transferFrom(msg.sender, address(this), tokenAmount), "Transfer token failed");
        require(sfuToken.transfer(mainAdmin, tokenAmount / 5), "Transfer token to admin failed");
        wallet.deposit(_to, _amount, 1, tokenAmount);
        emit PackageJoinedViaToken(msg.sender, _to, _amount);
    }

    function miningToken(uint _tokenAmount) public {
        require(aiTokenG2 > 0, "Invalid aiTokenG2, please contact admin");
        require(citizen.isCitizen(msg.sender), "Please register first");
        validateLockingMiningToken(msg.sender);
        uint fiatAmount = (_tokenAmount * aiTokenG2) / (10 ** 18);
        validateMAmount(fiatAmount);
        require(fiatAmount >= miningDifficulty, "Amount must be >= miningDifficulty");
        validateProfitBalance(msg.sender, fiatAmount);

        walletStore.mineToken(msg.sender, fiatAmount);
        uint userOldBalance = sfuToken.balanceOf(msg.sender);
        require(sfuToken.transfer(msg.sender, _tokenAmount), "Transfer token to user failed");
        require(sfuToken.balanceOf(msg.sender) == userOldBalance + _tokenAmount, "User token changed invalid");
        emit TokenMined(msg.sender, _tokenAmount, fiatAmount);
    }

    function swapToken(uint _amount) public {
        require(_amount > 0, "Invalid amount to swap");
        require(sfuToken.balanceOf(msg.sender) >= _amount, "You have not enough balance");
        uint etherAmount = getEtherAmountFromToken(_amount);
        require(address(this).balance >= etherAmount, "The contract have not enough balance");
        validateSAmount(etherAmount);
        require(sfuToken.allowance(msg.sender, address(this)) >= _amount, "You must call approve() first");
        require(sfuToken.transferFrom(msg.sender, burnToken, _amount), "Transfer token failed");
        msg.sender.transfer(etherAmount);

        walletStore.increaseETHWithdrew(etherAmount);
        walletStore.increaseETHWithdrewOfInvestor(msg.sender, etherAmount);
        emit TokenSwapped(msg.sender, _amount, etherAmount);
    }

    function getCurrentEthPrice() public view returns (uint) {
        return currentETHPrice;
    }

     

    function getEtherAmountFromToken(uint _amount) private view returns (uint) {
        require(aiTokenG3 > 0, "Invalid aiTokenG3, please contact admin");
        return _amount / aiTokenG3;
    }

    function doJoinViaEther(address _from, address _to, uint _etherAmountInWei, uint _rate) private {
        uint etherForAdmin = _etherAmountInWei / 5;
        uint packageValue = (_etherAmountInWei * _rate) / (10 ** 18);
        wallet.deposit(_to, packageValue, 0, _etherAmountInWei);
        mainAdmin.transfer(etherForAdmin);
        emit PackageJoinedViaEther(_from, _to, packageValue);
    }

    function validateAmount(uint _packageValue) public view {
        require(_packageValue > 0, "Amount must be > 0");
        require(_packageValue <= maxJoinPackage, "Can not join with amount that greater max join package");
        require(_packageValue >= minJoinPackage, "Minimum for first join is $200");
    }

    function validateJoinPackage(address _from, address _to) private view {
        require(citizen.isCitizen(_from), "Please register first");
        require(citizen.isCitizen(_to), "You can only buy for an exists member");
        if (_from != _to) {
            require(citizen.checkInvestorsInTheSameReferralTree(_from, _to), "This user isn't in your referral tree");
        }
        require(currentETHPrice > 0, "Invalid currentETHPrice, please contact admin!");
    }

    function validateLockingMiningToken(address _from) private view {
        bool canBuy = lockedAccounts[_from] != Lock.MINING_TOKEN && lockedAccounts[_from] != Lock.BOTH;
        require(canBuy, "Your account get locked from mining token");
    }

    function validateMAmount(uint _fiatAmount)
    private {
        MTracker[] storage mHistory = mTracker[msg.sender];
        uint maxM = 4 * walletStore.getTD(msg.sender);
        if (mHistory.length == 0) {
            require(_fiatAmount <= maxM, "Today: You can only mine maximum 4x of your total deposited");
        } else {
            uint totalMInLast24Hour = 0;
            uint countTrackerNotInLast24Hour = 0;
            uint length = mHistory.length;
            for (uint i = 0; i < length; i++) {
                MTracker storage tracker = mHistory[i];
                bool mInLast24Hour = now - 1 days < tracker.time;
                if (mInLast24Hour) {
                    totalMInLast24Hour = totalMInLast24Hour.add(tracker.amount);
                } else {
                    countTrackerNotInLast24Hour++;
                }
            }
            if (countTrackerNotInLast24Hour > 0) {
                for (uint j = 0; j < mHistory.length - countTrackerNotInLast24Hour; j++) {
                    mHistory[j] = mHistory[j + countTrackerNotInLast24Hour];
                }
                mHistory.length -= countTrackerNotInLast24Hour;
            }
            require(totalMInLast24Hour.add(_fiatAmount) <= maxM, "Today: You can only mine maximum 4x of your total deposited");
        }
        mHistory.push(MTracker(now, _fiatAmount));
    }

    function validateSAmount(uint _amount)
    private {
        STracker[] storage sHistory = sTracker[msg.sender];
        uint maxS = 0;
        uint td = walletStore.getTD(msg.sender);
        for (uint i = 0; i < levelS.length; i++) {
            LevelS storage level = levelS[i];
            if (i == levelS.length - 1) {
                maxS = level.maxS;
                break;
            }
            if (level.minTotalDeposited <= td && td < level.maxTotalDeposited) {
                maxS = level.maxS;
                break;
            }
        }
        require(maxS > 0, "Invalid maxS, maybe you have not joined package or please contact admin");
        if (sHistory.length == 0) {
            require(_amount <= maxS, "Amount is invalid");
        } else {
            uint totalSInLast24Hour = 0;
            uint countTrackerNotInLast24Hour = 0;
            uint length = sHistory.length;
            for (i = 0; i < length; i++) {
                STracker storage tracker = sHistory[i];
                bool sInLast24Hour = now - 1 days < tracker.time;
                if (sInLast24Hour) {
                    totalSInLast24Hour = totalSInLast24Hour.add(tracker.amount);
                } else {
                    countTrackerNotInLast24Hour++;
                }
            }
            if (countTrackerNotInLast24Hour > 0) {
                for (uint j = 0; j < sHistory.length - countTrackerNotInLast24Hour; j++) {
                    sHistory[j] = sHistory[j + countTrackerNotInLast24Hour];
                }
                sHistory.length -= countTrackerNotInLast24Hour;
            }
            require(totalSInLast24Hour.add(_amount) <= maxS, "Too much for today");
        }
        sHistory.push(STracker(now, _amount));
    }

    function validateProfitBalance(address _user, uint _amount) private view {
        uint profitBalance = wallet.getProfitBalance(_user);
        require(profitBalance >= _amount, "You have not enough balance");
    }
}