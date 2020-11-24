 

 

pragma solidity ^0.5.0;

contract Proxiable {
     

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                    0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
                ) ==
                Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
             
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

 

pragma solidity >=0.5.10 <0.6.0;

contract RTokenStructs {
     
    struct GlobalStats {
         
        uint256 totalSupply;
         
        uint256 totalSavingsAmount;
    }


     
    struct AccountStatsView {
         
        uint256 hatID;
         
        uint256 rAmount;
         
        uint256 rInterest;
         
        uint256 lDebt;
         
        uint256 sInternalAmount;
         
        uint256 rInterestPayable;
         
        uint256 cumulativeInterest;
    }

     
    struct AccountStatsStored {
         
        uint256 cumulativeInterest;
    }

     
    struct HatStatsView {
         
        uint256 useCount;
         
        uint256 totalLoans;
         
        uint256 totalSavings;
    }

     
    struct HatStatsStored {
         
        uint256 useCount;
         
        uint256 totalLoans;
         
        uint256 totalInternalSavings;
    }

     
    struct Hat {
        address[] recipients;
        uint32[] proportions;
    }

     
    struct Account {
        uint256 hatID;
        uint256 rAmount;
        uint256 rInterest;
        mapping(address => uint256) lRecipients;
        uint256 lDebt;
        uint256 sInternalAmount;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
pragma solidity >=0.5.10 <0.6.0;
pragma experimental ABIEncoderV2;



 
contract IRToken is RTokenStructs, IERC20 {
     
     
     
     
    function mint(uint256 mintAmount) external returns (bool);

     
    function mintWithSelectedHat(uint256 mintAmount, uint256 hatID)
        external
        returns (bool);

     
    function mintWithNewHat(
        uint256 mintAmount,
        address[] calldata recipients,
        uint32[] calldata proportions
    ) external returns (bool);

     
    function transferAll(address dst) external returns (bool);

     
    function transferAllFrom(address src, address dst) external returns (bool);

     
    function redeem(uint256 redeemTokens) external returns (bool);

     
    function redeemAll() external returns (bool);

     
    function redeemAndTransfer(address redeemTo, uint256 redeemTokens)
        external
        returns (bool);

     
    function redeemAndTransferAll(address redeemTo) external returns (bool);

     
    function createHat(
        address[] calldata recipients,
        uint32[] calldata proportions,
        bool doChangeHat
    ) external returns (uint256 hatID);

     
    function changeHat(uint256 hatID) external returns (bool);

     
    function payInterest(address owner) external returns (bool);

     
     
     
     
    function getMaximumHatID() external view returns (uint256 hatID);

     
    function getHatByAddress(address owner)
        external
        view
        returns (
            uint256 hatID,
            address[] memory recipients,
            uint32[] memory proportions
        );

     
    function getHatByID(uint256 hatID)
        external
        view
        returns (address[] memory recipients, uint32[] memory proportions);

     
    function receivedSavingsOf(address owner)
        external
        view
        returns (uint256 amount);

     
    function receivedLoanOf(address owner)
        external
        view
        returns (uint256 amount);

     
    function interestPayableOf(address owner)
        external
        view
        returns (uint256 amount);

     
     
     
     
    function getCurrentSavingStrategy() external view returns (address);

     
    function getSavingAssetBalance()
        external
        view
        returns (uint256 rAmount, uint256 sOriginalAmount);

     
    function getGlobalStats() external view returns (GlobalStats memory);

     
    function getAccountStats(address owner)
        external
        view
        returns (AccountStatsView memory);

     
    function getHatStats(uint256 hatID)
        external
        view
        returns (HatStatsView memory);

     
     
     
     
    event LoansTransferred(
        address indexed owner,
        address indexed recipient,
        uint256 indexed hatId,
        bool isDistribution,
        uint256 redeemableAmount,
        uint256 internalSavingsAmount);

     
    event InterestPaid(address indexed recipient, uint256 amount);

     
    event HatCreated(uint256 indexed hatID);

     
    event HatChanged(address indexed account, uint256 indexed oldHatID, uint256 indexed newHatID);
}

 

pragma solidity ^0.5.8;

 
interface IAllocationStrategy {

     
    function underlying() external view returns (address);

     
    function exchangeRateStored() external view returns (uint256);

     
    function accrueInterest() external returns (bool);

     
    function investUnderlying(uint256 investAmount) external returns (uint256);

     
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

}

 

 
pragma solidity >=0.5.10 <0.6.0;
 




contract RTokenStorage is RTokenStructs, IERC20 {
     
    address public _owner;
    bool public initialized;
     
    uint256 public _guardCounter;
     
    string public name;
     
    string public symbol;
     
    uint256 public decimals;
     
    uint256 public totalSupply;
     
    IAllocationStrategy public ias;
     
    IERC20 public token;
     
     
    uint256 public savingAssetOrignalAmount;
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint256 public savingAssetConversionRate;
     
    mapping(address => mapping(address => uint256)) public transferAllowances;
     
    Hat[] internal hats;
     
    mapping(address => Account) public accounts;
     
    mapping(address => AccountStatsStored) public accountStats;
     
    mapping(uint256 => HatStatsStored) public hatStats;
}

 

pragma solidity ^0.5.0;


contract Ownable is RTokenStorage {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;


contract LibraryLock is RTokenStorage {
     
     

    modifier delegatedOnly() {
        require(
            initialized == true,
            "The library is locked. No direct 'call' is allowed."
        );
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;


contract ReentrancyGuard is RTokenStorage {
     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

 

 
pragma solidity >= 0.4.24;

 
interface IRTokenAdmin {

     
    function owner() external view returns (address);

     
    function transferOwnership(address newOwner) external;

     
    function getCurrentAllocationStrategy()
        external view returns (address allocationStrategy);

     
    function changeAllocationStrategy(address allocationStrategy)
        external;

     
    function changeHatFor(address contractAddress, uint256 hatID)
        external;

     
    function updateCode(address newCode) external;

     
    event CodeUpdated(address newCode);

     
    event AllocationStrategyChanged(address strategy, uint256 conversionRate);
}

 

 
pragma solidity >=0.5.10 <0.6.0;
 











 
contract RToken is
    RTokenStorage,
    IRToken,
    IRTokenAdmin,
    Ownable,
    Proxiable,
    LibraryLock,
    ReentrancyGuard {
    using SafeMath for uint256;


    uint256 public constant ALLOCATION_STRATEGY_EXCHANGE_RATE_SCALE = 1e18;
    uint256 public constant INITIAL_SAVING_ASSET_CONVERSION_RATE = 1e18;
    uint256 public constant MAX_UINT256 = uint256(int256(-1));
    uint256 public constant SELF_HAT_ID = MAX_UINT256;
    uint32 public constant PROPORTION_BASE = 0xFFFFFFFF;
    uint256 public constant MAX_NUM_HAT_RECIPIENTS = 50;

     
    function initialize(
        IAllocationStrategy allocationStrategy,
        string calldata name_,
        string calldata symbol_,
        uint256 decimals_) external {
        require(!initialized, "The library has already been initialized.");
        LibraryLock.initialize();
        _owner = msg.sender;
        _guardCounter = 1;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        savingAssetConversionRate = INITIAL_SAVING_ASSET_CONVERSION_RATE;
        ias = allocationStrategy;
        token = IERC20(ias.underlying());

         
        hats.push(Hat(new address[](0), new uint32[](0)));

         
        hatStats[0].useCount = MAX_UINT256;

        emit AllocationStrategyChanged(address(ias), savingAssetConversionRate);
    }

     
     
     

     
    function balanceOf(address owner) external view returns (uint256) {
        return accounts[owner].rAmount;
    }

     
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return transferAllowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

     
    function transfer(address dst, uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        address src = msg.sender;
        payInterestInternal(src);
        transferInternal(src, src, dst, amount);
        payInterestInternal(dst);
        return true;
    }

     
    function transferAll(address dst) external nonReentrant returns (bool) {
        address src = msg.sender;
        payInterestInternal(src);
        transferInternal(src, src, dst, accounts[src].rAmount);
        payInterestInternal(dst);
        return true;
    }

     
    function transferAllFrom(address src, address dst)
        external
        nonReentrant
        returns (bool)
    {
        payInterestInternal(src);
        transferInternal(msg.sender, src, dst, accounts[src].rAmount);
        payInterestInternal(dst);
        return true;
    }

     
    function transferFrom(address src, address dst, uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        payInterestInternal(src);
        transferInternal(msg.sender, src, dst, amount);
        payInterestInternal(dst);
        return true;
    }

     
     
     

     
    function mint(uint256 mintAmount) external nonReentrant returns (bool) {
        mintInternal(mintAmount);
        payInterestInternal(msg.sender);
        return true;
    }

     
    function mintWithSelectedHat(uint256 mintAmount, uint256 hatID)
        external
        nonReentrant
        returns (bool)
    {
        changeHatInternal(msg.sender, hatID);
        mintInternal(mintAmount);
        payInterestInternal(msg.sender);
        return true;
    }

     
    function mintWithNewHat(
        uint256 mintAmount,
        address[] calldata recipients,
        uint32[] calldata proportions
    ) external nonReentrant returns (bool) {
        uint256 hatID = createHatInternal(recipients, proportions);
        changeHatInternal(msg.sender, hatID);
        mintInternal(mintAmount);
        payInterestInternal(msg.sender);
        return true;
    }

     
    function redeem(uint256 redeemTokens) external nonReentrant returns (bool) {
        address src = msg.sender;
        payInterestInternal(src);
        redeemInternal(src, redeemTokens);
        return true;
    }

     
    function redeemAll() external nonReentrant returns (bool) {
        address src = msg.sender;
        payInterestInternal(src);
        redeemInternal(src, accounts[src].rAmount);
        return true;
    }

     
    function redeemAndTransfer(address redeemTo, uint256 redeemTokens)
        external
        nonReentrant
        returns (bool)
    {
        address src = msg.sender;
        payInterestInternal(src);
        redeemInternal(redeemTo, redeemTokens);
        return true;
    }

     
    function redeemAndTransferAll(address redeemTo)
        external
        nonReentrant
        returns (bool)
    {
        address src = msg.sender;
        payInterestInternal(src);
        redeemInternal(redeemTo, accounts[src].rAmount);
        return true;
    }

     
    function createHat(
        address[] calldata recipients,
        uint32[] calldata proportions,
        bool doChangeHat
    ) external nonReentrant returns (uint256 hatID) {
        hatID = createHatInternal(recipients, proportions);
        if (doChangeHat) {
            changeHatInternal(msg.sender, hatID);
        }
    }

     
    function changeHat(uint256 hatID) external nonReentrant returns (bool) {
        changeHatInternal(msg.sender, hatID);
        payInterestInternal(msg.sender);
        return true;
    }

     
    function getMaximumHatID() external view returns (uint256 hatID) {
        return hats.length - 1;
    }

     
    function getHatByAddress(address owner)
        external
        view
        returns (
            uint256 hatID,
            address[] memory recipients,
            uint32[] memory proportions
        )
    {
        hatID = accounts[owner].hatID;
        (recipients, proportions) = _getHatByID(hatID);
    }

     
    function getHatByID(uint256 hatID)
        external
        view
        returns (address[] memory recipients, uint32[] memory proportions) {
        (recipients, proportions) = _getHatByID(hatID);
    }

    function _getHatByID(uint256 hatID)
        private
        view
        returns (address[] memory recipients, uint32[] memory proportions) {
        if (hatID != 0 && hatID != SELF_HAT_ID) {
            Hat memory hat = hats[hatID];
            recipients = hat.recipients;
            proportions = hat.proportions;
        } else {
            recipients = new address[](0);
            proportions = new uint32[](0);
        }
    }

     
    function receivedSavingsOf(address owner)
        external
        view
        returns (uint256 amount)
    {
        Account storage account = accounts[owner];
        uint256 rGross = sInternalToR(account.sInternalAmount);
        return rGross;
    }

     
    function receivedLoanOf(address owner)
        external
        view
        returns (uint256 amount)
    {
        Account storage account = accounts[owner];
        return account.lDebt;
    }

     
    function interestPayableOf(address owner)
        external
        view
        returns (uint256 amount)
    {
        Account storage account = accounts[owner];
        return getInterestPayableOf(account);
    }

     
    function payInterest(address owner) external nonReentrant returns (bool) {
        payInterestInternal(owner);
        return true;
    }

     
    function getGlobalStats() external view returns (GlobalStats memory) {
        uint256 totalSavingsAmount;
        totalSavingsAmount += sOriginalToR(savingAssetOrignalAmount);
        return
            GlobalStats({
                totalSupply: totalSupply,
                totalSavingsAmount: totalSavingsAmount
            });
    }

     
    function getAccountStats(address owner)
        external
        view
        returns (AccountStatsView memory stats)
    {
        Account storage account = accounts[owner];
        stats.hatID = account.hatID;
        stats.rAmount = account.rAmount;
        stats.rInterest = account.rInterest;
        stats.lDebt = account.lDebt;
        stats.sInternalAmount = account.sInternalAmount;

        stats.rInterestPayable = getInterestPayableOf(account);

        AccountStatsStored storage statsStored = accountStats[owner];
        stats.cumulativeInterest = statsStored.cumulativeInterest;

        return stats;
    }

     
    function getHatStats(uint256 hatID)
        external
        view
        returns (HatStatsView memory stats) {
        HatStatsStored storage statsStored = hatStats[hatID];
        stats.useCount = statsStored.useCount;
        stats.totalLoans = statsStored.totalLoans;

        stats.totalSavings = sInternalToR(statsStored.totalInternalSavings);
        return stats;
    }

     
    function getCurrentSavingStrategy() external view returns (address) {
        return address(ias);
    }

     
    function getSavingAssetBalance()
        external
        view
        returns (uint256 rAmount, uint256 sOriginalAmount)
    {
        sOriginalAmount = savingAssetOrignalAmount;
        rAmount = sOriginalToR(sOriginalAmount);
    }

     
    function changeAllocationStrategy(address allocationStrategy_)
        external
        nonReentrant
        onlyOwner
    {
        IAllocationStrategy allocationStrategy = IAllocationStrategy(allocationStrategy_);
        require(
            allocationStrategy.underlying() == address(token),
            "New strategy should have the same underlying asset"
        );
        IAllocationStrategy oldIas = ias;
        ias = allocationStrategy;
         
        uint256 sOriginalBurned = oldIas.redeemUnderlying(totalSupply);
         
        require(token.approve(address(ias), totalSupply), "token approve failed");
        uint256 sOriginalCreated = ias.investUnderlying(totalSupply);

         
         
         
         
         
         
         
         
         
         
         
         
        uint256 savingAssetConversionRateOld = savingAssetConversionRate;
        savingAssetConversionRate = sOriginalBurned
            .mul(savingAssetConversionRateOld)
            .div(sOriginalCreated);

        emit AllocationStrategyChanged(allocationStrategy_, savingAssetConversionRate);
    }

     
    function getCurrentAllocationStrategy()
        external view returns (address allocationStrategy) {
        return address(ias);
    }

     
    function changeHatFor(address contractAddress, uint256 hatID) external onlyOwner {
        require(_isContract(contractAddress), "Admin can only change hat for contract address");
        changeHatInternal(contractAddress, hatID);
    }

     
    function updateCode(address newCode) external onlyOwner delegatedOnly {
        updateCodeAddress(newCode);
        emit CodeUpdated(newCode);
    }

     
    function transferInternal(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        require(src != dst, "src should not equal dst");

        require(
            accounts[src].rAmount >= tokens,
            "Not enough balance to transfer"
        );

         
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = MAX_UINT256;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }
        require(
            startingAllowance >= tokens,
            "Not enough allowance for transfer"
        );

         
        uint256 allowanceNew = startingAllowance.sub(tokens);
        uint256 srcTokensNew = accounts[src].rAmount.sub(tokens);
        uint256 dstTokensNew = accounts[dst].rAmount.add(tokens);

         
         
         

         
        bool sameHat = accounts[src].hatID == accounts[dst].hatID;

         
        if ((accounts[src].hatID != 0 &&
            accounts[dst].hatID == 0 &&
            accounts[src].hatID != SELF_HAT_ID)) {
            changeHatInternal(dst, accounts[src].hatID);
        }

        accounts[src].rAmount = srcTokensNew;
        accounts[dst].rAmount = dstTokensNew;

         
        if (startingAllowance != MAX_UINT256) {
            transferAllowances[src][spender] = allowanceNew;
        }

         
        if (!sameHat) {
            uint256 sInternalAmountCollected = estimateAndRecollectLoans(
                src,
                tokens
            );
            distributeLoans(dst, tokens, sInternalAmountCollected);
        } else {
             
            sameHatTransfer(src, dst, accounts[src].hatID, tokens);
        }

         
         
         
         
         
        if (accounts[src].rInterest > accounts[src].rAmount) {
            accounts[src].rInterest = accounts[src].rAmount;
        }

         
        emit Transfer(src, dst, tokens);
    }

     
    function mintInternal(uint256 mintAmount) internal {
        require(
            token.allowance(msg.sender, address(this)) >= mintAmount,
            "Not enough allowance"
        );

        Account storage account = accounts[msg.sender];

         
        require(token.transferFrom(msg.sender, address(this), mintAmount), "token transfer failed");
        require(token.approve(address(ias), mintAmount), "token approve failed");
        uint256 sOriginalCreated = ias.investUnderlying(mintAmount);

         
        totalSupply = totalSupply.add(mintAmount);
        account.rAmount = account.rAmount.add(mintAmount);

         
        savingAssetOrignalAmount = savingAssetOrignalAmount.add(sOriginalCreated);

         
        uint256 sInternalCreated = sOriginalToSInternal(sOriginalCreated);
        distributeLoans(msg.sender, mintAmount, sInternalCreated);

        emit Transfer(address(0), msg.sender, mintAmount);
    }

     
    function redeemInternal(address redeemTo, uint256 redeemAmount) internal {
        Account storage account = accounts[msg.sender];
        require(redeemAmount > 0, "Redeem amount cannot be zero");
        require(
            redeemAmount <= account.rAmount,
            "Not enough balance to redeem"
        );

        uint256 sOriginalBurned = redeemAndRecollectLoans(
            msg.sender,
            redeemAmount
        );

         
        account.rAmount = account.rAmount.sub(redeemAmount);
        if (account.rInterest > account.rAmount) {
            account.rInterest = account.rAmount;
        }
        totalSupply = totalSupply.sub(redeemAmount);

         
        if (savingAssetOrignalAmount > sOriginalBurned) {
            savingAssetOrignalAmount -= sOriginalBurned;
        } else {
            savingAssetOrignalAmount = 0;
        }

         
        require(token.transfer(redeemTo, redeemAmount), "token transfer failed");

        emit Transfer(msg.sender, address(0), redeemAmount);
    }

     
    function createHatInternal(
        address[] memory recipients,
        uint32[] memory proportions
    ) internal returns (uint256 hatID) {
        uint256 i;

        require(recipients.length > 0, "Invalid hat: at least one recipient");
        require(recipients.length <= MAX_NUM_HAT_RECIPIENTS, "Invalild hat: maximum number of recipients reached");
        require(
            recipients.length == proportions.length,
            "Invalid hat: length not matching"
        );

         
         
         
        uint256 totalProportions = 0;
        for (i = 0; i < recipients.length; ++i) {
            require(
                proportions[i] > 0,
                "Invalid hat: proportion should be larger than 0"
            );
            require(recipients[i] != address(0), "Invalid hat: recipient should not be 0x0");
             
            totalProportions += uint256(proportions[i]);
        }
        for (i = 0; i < proportions.length; ++i) {
            proportions[i] = uint32(
                 
                (uint256(proportions[i]) * uint256(PROPORTION_BASE)) /
                    totalProportions
            );
        }

        hatID = hats.push(Hat(recipients, proportions)) - 1;
        emit HatCreated(hatID);
    }

     
    function changeHatInternal(address owner, uint256 hatID) internal {
        require(hatID == SELF_HAT_ID || hatID < hats.length, "Invalid hat ID");
        Account storage account = accounts[owner];
        uint256 oldHatID = account.hatID;
        HatStatsStored storage oldHatStats = hatStats[oldHatID];
        HatStatsStored storage newHatStats = hatStats[hatID];
        account.hatID = hatID;
        if (account.rAmount > 0) {
            uint256 sInternalAmountCollected = estimateAndRecollectLoans(
                owner,
                account.rAmount
            );
            distributeLoans(owner, account.rAmount, sInternalAmountCollected);
        }
        oldHatStats.useCount -= 1;
        newHatStats.useCount += 1;
        emit HatChanged(owner, oldHatID, hatID);
    }

     
    function getInterestPayableOf(Account storage account)
        internal
        view
        returns (uint256)
    {
        uint256 rGross = sInternalToR(account.sInternalAmount);
        if (rGross > (account.lDebt.add(account.rInterest))) {
             
            return rGross - account.lDebt - account.rInterest;
        } else {
             
            return 0;
        }
    }

     
    function distributeLoans(
        address owner,
        uint256 rAmount,
        uint256 sInternalAmount
    ) internal {
        Account storage account = accounts[owner];
        Hat storage hat = hats[account.hatID == SELF_HAT_ID
            ? 0
            : account.hatID];
        uint256 i;
        if (hat.recipients.length > 0) {
            uint256 rLeft = rAmount;
            uint256 sInternalLeft = sInternalAmount;
            for (i = 0; i < hat.proportions.length; ++i) {
                address recipientAddress = hat.recipients[i];
                Account storage recipientAccount = accounts[recipientAddress];
                bool isLastRecipient = i == (hat.proportions.length - 1);

                 
                uint256 lDebtRecipient = isLastRecipient
                    ? rLeft
                    : (rAmount.mul(hat.proportions[i])) / PROPORTION_BASE;
                 
                account.lRecipients[recipientAddress] = account.lRecipients[recipientAddress]
                    .add(lDebtRecipient);
                recipientAccount.lDebt = recipientAccount.lDebt
                    .add(lDebtRecipient);
                 
                rLeft = gentleSub(rLeft, lDebtRecipient);

                 
                uint256 sInternalAmountRecipient = isLastRecipient
                    ? sInternalLeft
                    : (sInternalAmount.mul(hat.proportions[i])) / PROPORTION_BASE;
                recipientAccount.sInternalAmount = recipientAccount.sInternalAmount
                    .add(sInternalAmountRecipient);
                 
                sInternalLeft = gentleSub(sInternalLeft, sInternalAmountRecipient);

                _updateLoanStats(owner, recipientAddress, account.hatID, true, lDebtRecipient, sInternalAmountRecipient);
            }
        } else {
             
            account.lDebt = account.lDebt.add(rAmount);
            account.sInternalAmount = account.sInternalAmount
                .add(sInternalAmount);

            _updateLoanStats(owner, owner, account.hatID, true, rAmount, sInternalAmount);
        }
    }

     
    function estimateAndRecollectLoans(address owner, uint256 rAmount)
        internal
        returns (uint256 sInternalAmount)
    {
         
        require(ias.accrueInterest(), "accrueInterest failed");
        sInternalAmount = rToSInternal(rAmount);
        recollectLoans(owner, rAmount, sInternalAmount);
    }

     
    function redeemAndRecollectLoans(address owner, uint256 rAmount)
        internal
        returns (uint256 sOriginalBurned)
    {
        sOriginalBurned = ias.redeemUnderlying(rAmount);
        uint256 sInternalBurned = sOriginalToSInternal(sOriginalBurned);
        recollectLoans(owner, rAmount, sInternalBurned);
    }

     
    function recollectLoans(
        address owner,
        uint256 rAmount,
        uint256 sInternalAmount
    ) internal {
        Account storage account = accounts[owner];
        Hat storage hat = hats[account.hatID == SELF_HAT_ID
            ? 0
            : account.hatID];
        if (hat.recipients.length > 0) {
            uint256 rLeft = rAmount;
            uint256 sInternalLeft = sInternalAmount;
            uint256 i;
            for (i = 0; i < hat.proportions.length; ++i) {
                address recipientAddress = hat.recipients[i];
                Account storage recipientAccount = accounts[recipientAddress];
                bool isLastRecipient = i == (hat.proportions.length - 1);

                 
                uint256 lDebtRecipient = isLastRecipient
                    ? rLeft
                    : (rAmount.mul(hat.proportions[i])) / PROPORTION_BASE;
                recipientAccount.lDebt = gentleSub(
                    recipientAccount.lDebt,
                    lDebtRecipient);
                account.lRecipients[recipientAddress] = gentleSub(
                    account.lRecipients[recipientAddress],
                    lDebtRecipient);
                 
                rLeft = gentleSub(rLeft, lDebtRecipient);

                 
                uint256 sInternalAmountRecipient = isLastRecipient
                    ? sInternalLeft
                    : (sInternalAmount.mul(hat.proportions[i])) / PROPORTION_BASE;
                recipientAccount.sInternalAmount = gentleSub(
                    recipientAccount.sInternalAmount,
                    sInternalAmountRecipient);
                 
                sInternalLeft = gentleSub(sInternalLeft, sInternalAmountRecipient);

                _updateLoanStats(owner, recipientAddress, account.hatID, false, lDebtRecipient, sInternalAmountRecipient);
            }
        } else {
             
            account.lDebt = gentleSub(account.lDebt, rAmount);
            account.sInternalAmount = gentleSub(account.sInternalAmount, sInternalAmount);

            _updateLoanStats(owner, owner, account.hatID, false, rAmount, sInternalAmount);
        }
    }

     
    function sameHatTransfer(
        address src,
        address dst,
        uint256 hatID,
        uint256 rAmount) internal {
         
        require(ias.accrueInterest(), "accrueInterest failed");

        Account storage srcAccount = accounts[src];
        Account storage dstAccount = accounts[dst];

        uint256 sInternalAmount = rToSInternal(rAmount);

        srcAccount.lDebt = gentleSub(srcAccount.lDebt, rAmount);
        srcAccount.sInternalAmount = gentleSub(srcAccount.sInternalAmount, sInternalAmount);
        _updateLoanStats(src, src, hatID, false, rAmount, sInternalAmount);

        dstAccount.lDebt = dstAccount.lDebt.add(rAmount);
        dstAccount.sInternalAmount = dstAccount.sInternalAmount.add(sInternalAmount);
        _updateLoanStats(dst, dst, hatID, true, rAmount, sInternalAmount);
    }

     
    function payInterestInternal(address owner) internal {
        Account storage account = accounts[owner];
        AccountStatsStored storage stats = accountStats[owner];

        require(ias.accrueInterest(), "accrueInterest failed");
        uint256 interestAmount = getInterestPayableOf(account);

        if (interestAmount > 0) {
            stats.cumulativeInterest = stats
                .cumulativeInterest
                .add(interestAmount);
            account.rInterest = account.rInterest.add(interestAmount);
            account.rAmount = account.rAmount.add(interestAmount);
            totalSupply = totalSupply.add(interestAmount);
            emit InterestPaid(owner, interestAmount);
            emit Transfer(address(0), owner, interestAmount);
        }
    }

    function _updateLoanStats(
        address owner,
        address recipient,
        uint256 hatID,
        bool isDistribution,
        uint256 redeemableAmount,
        uint256 sInternalAmount) private {
        HatStatsStored storage hatStats = hatStats[hatID];

        emit LoansTransferred(owner, recipient, hatID,
            isDistribution,
            redeemableAmount,
            sInternalAmount);

        if (isDistribution) {
            hatStats.totalLoans = hatStats.totalLoans.add(redeemableAmount);
            hatStats.totalInternalSavings = hatStats.totalInternalSavings
                .add(sInternalAmount);
        } else {
            hatStats.totalLoans = gentleSub(hatStats.totalLoans, redeemableAmount);
            hatStats.totalInternalSavings = gentleSub(
                hatStats.totalInternalSavings,
                sInternalAmount);
        }
    }

    function _isContract(address addr) private view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }

     
    function gentleSub(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return 0;
        else return a - b;
    }

     
    function sInternalToR(uint256 sInternalAmount)
        private view
        returns (uint256 rAmount) {
         
         
         
         
         
         
         
        return sInternalAmount
            .mul(ias.exchangeRateStored())
            .div(savingAssetConversionRate);
    }

     
    function rToSInternal(uint256 rAmount)
        private view
        returns (uint256 sInternalAmount) {
        return rAmount
            .mul(savingAssetConversionRate)
            .div(ias.exchangeRateStored());
    }

     
    function sOriginalToR(uint sOriginalAmount)
        private view
        returns (uint256 sInternalAmount) {
        return sOriginalAmount
            .mul(ias.exchangeRateStored())
            .div(ALLOCATION_STRATEGY_EXCHANGE_RATE_SCALE);
    }

     
    function sOriginalToSInternal(uint sOriginalAmount)
        private view
        returns (uint256 sInternalAmount) {
         
        return sOriginalAmount
            .mul(savingAssetConversionRate)
            .div(ALLOCATION_STRATEGY_EXCHANGE_RATE_SCALE);
    }
}