 

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

interface IWallet {

    function getInvestorLastDeposited(address _investor) external view returns (uint);

    function getUserWallet(address _investor) external view returns (uint, uint[], uint, uint, uint, uint, uint);

    function getProfitBalance(address _investor) external view returns (uint);

    function ethWithdrew() external view returns (uint);
}

contract WalletStore is Auth {
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

    uint public ethWithdrew;
    uint private profitPaid;
    uint private f11RewardCondition = 200000000;  
    IWallet private oldWallet;
    address private reserveFund;
    address private walletContract;

    mapping(address => Balance) private userWallets;

    modifier onlyReserveFundContract() {
        require(msg.sender == reserveFund, "onlyReserveFundContract");
        _;
    }

    modifier onlyWalletContract() {
        require(msg.sender == walletContract, "onlyWalletContract");
        _;
    }

    constructor (address _oldWallet, address _mainAdmin)
    Auth(_mainAdmin, msg.sender)
    public {
        oldWallet = IWallet(_oldWallet);
    }

     

    function updateContractAdmin(address _newAddress)
    onlyContractAdmin
    public {
        transferOwnership(_newAddress);
    }

    function setReserveFundContract(address _reserveFund)
    onlyContractAdmin
    public {
        reserveFund = _reserveFund;
    }

    function setW(address _walletContract)
    onlyContractAdmin
    public {
        walletContract = _walletContract;
    }

    function syncContractLevelData(uint _profitPaid)
    onlyContractAdmin
    public {
        ethWithdrew = oldWallet.ethWithdrew();
        profitPaid = _profitPaid;
    }

    function syncData(address[] _investors, uint[] _amountToMineToken)
    onlyContractAdmin
    public {
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

     

    function makeDailyProfit(address _user, uint dailyProfit)
    onlyWalletContract
    public {
        Balance storage balance = userWallets[_user];
        balance.profitableBalance = balance.profitableBalance.sub(dailyProfit);
        balance.profitBalance = balance.profitBalance.add(dailyProfit);
        balance.totalProfited = balance.totalProfited.add(dailyProfit);
        profitPaid = profitPaid.add(dailyProfit);
    }

     

    function bonusForAdminWhenUserBuyPackageViaDollar(uint _amount, address _admin)
    onlyReserveFundContract
    public
    {
        Balance storage adminBalance = userWallets[_admin];
        userWallets[_admin].profitBalance = adminBalance.profitBalance.add(_amount);
    }

    function increaseETHWithdrew(uint _amount)
    onlyReserveFundContract
    public {
        ethWithdrew = ethWithdrew.add(_amount);
    }

    function increaseETHWithdrewOfInvestor(address _investor, uint _ethWithdrew)
    onlyReserveFundContract
    public {
        Balance storage balance = userWallets[_investor];
        balance.ethWithdrew = balance.ethWithdrew.add(_ethWithdrew);
    }

    function mineToken(address _from, uint _amount)
    onlyReserveFundContract
    public {
        Balance storage userBalance = userWallets[_from];
        userBalance.profitBalance = userBalance.profitBalance.sub(_amount);
        userBalance.amountToMineToken = userBalance.amountToMineToken.add(_amount);
    }

    function getTD(address _investor)
    onlyReserveFundContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].totalDeposited;
    }

     

    function setTotalDeposited(address _investor, uint _totalDeposited)
    onlyWalletContract
    public {
        userWallets[_investor].totalDeposited = _totalDeposited;
    }

    function pushDeposited(address _investor, uint256 _deposited)
    onlyWalletContract
    public {
        Balance storage balance = userWallets[_investor];
        balance.deposited.push(_deposited);
    }

    function setProfitableBalance(address _investor, uint _profitableBalance)
    onlyWalletContract
    public {
        userWallets[_investor].profitableBalance = _profitableBalance;
    }

    function setProfitSourceBalance(address _investor, uint _profitSourceBalance)
    onlyWalletContract
    public {
        userWallets[_investor].profitSourceBalance = _profitSourceBalance;
    }

    function setProfitBalance(address _investor, uint _profitBalance)
    onlyWalletContract
    public {
        userWallets[_investor].profitBalance = _profitBalance;
    }

    function setTotalProfited(address _investor, uint _totalProfited)
    onlyWalletContract
    public {
        userWallets[_investor].totalProfited = _totalProfited;
    }

    function setAmountToMineToken(address _investor, uint _amountToMineToken)
    onlyWalletContract
    public {
        userWallets[_investor].amountToMineToken = _amountToMineToken;
    }


     

    function getProfitPaid()
    onlyWalletContract
    public
    view
    returns (uint) {
        return profitPaid;
    }

    function getUserWallet(address _investor)
    onlyWalletContract
    public
    view
    returns (uint, uint[], uint, uint, uint, uint, uint, uint)
    {
        Balance storage balance = userWallets[_investor];
        return (
        balance.totalDeposited,
        balance.deposited,
        balance.profitableBalance,
        balance.profitSourceBalance,
        balance.profitBalance,
        balance.totalProfited,
        balance.amountToMineToken,
        balance.ethWithdrew
        );
    }

    function getTotalDeposited(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].totalDeposited;
    }

    function getDeposited(address _investor)
    onlyWalletContract
    public
    view
    returns (uint[])
    {
        return userWallets[_investor].deposited;
    }

    function getProfitableBalance(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].profitableBalance;
    }

    function getProfitSourceBalance(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].profitSourceBalance;
    }

    function getTotalProfited(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].totalProfited;
    }

    function getAmountToMineToken(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].amountToMineToken;
    }

    function getEthWithdrewOfInvestor(address _investor)
    onlyWalletContract
    public
    view
    returns (uint)
    {
        return userWallets[_investor].ethWithdrew;
    }



     

    function getInvestorLastDeposited(address _investor)
    public
    view
    returns (uint) {
        return userWallets[_investor].deposited.length == 0 ? 0 : userWallets[_investor].deposited[userWallets[_investor].deposited.length - 1];
    }

    function getProfitBalance(address _investor)
    public
    view
    returns (uint) {
        return userWallets[_investor].profitBalance;
    }

    function getEthWithdrew()
    public
    view
    returns (uint)
    {
        return ethWithdrew;
    }

    function getF11RewardCondition()
    public
    view
    returns (uint)
    {
        return f11RewardCondition;
    }

}