 

pragma solidity ^0.5.11;

 
 
 
 
 
 
 
 
 


 
library SafeMath256 {
     
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
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 
library SafeMath16 {
     
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b <= a, errorMessage);
        uint16 c = a - b;

        return c;
    }

     
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }

        uint16 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
         
        require(b > 0, errorMessage);
        return a / b;
    }

     
    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


 
contract Ownable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);


     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address currentOwner, address newOwner) {
        currentOwner = _owner;
        newOwner = _newOwner;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _newOwner = newOwner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner address");
        require(msg.sender != address(0), "Ownable: caller is the zero address");

        emit OwnershipAccepted(_owner, msg.sender);
        _owner = msg.sender;
        _newOwner = address(0);
    }

     
    function rescueTokens(address tokenAddr, address recipient, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Withdraw: recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }
}


 
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);


     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

     
    function setPaused(bool value) external onlyOwner {
        _paused = value;

        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }
}


 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


 
interface IVoken2 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function mintWithAllocation(address account, uint256 amount, address allocationContract) external returns (bool);
    function whitelisted(address account) external view returns (bool);
    function whitelistReferee(address account) external view returns (address payable);
    function whitelistReferralsCount(address account) external view returns (uint256);
}


 
interface IAllocation {
    function reservedOf(address account) external view returns (uint256);
}


 
library Allocations {
    struct Allocation {
        uint256 amount;
        uint256 timestamp;
    }
}


 
interface VokenShareholders {
     
}


 
contract VokenPublicSale2 is Ownable, Pausable, IAllocation {
    using SafeMath16 for uint16;
    using SafeMath256 for uint256;
    using Roles for Roles.Role;
    using Allocations for Allocations.Allocation;

     
    Roles.Role private _proxies;

     
    IVoken2 private _VOKEN = IVoken2(0xFfFAb974088Bd5bF3d7E6F522e93Dd7861264cDB);
    VokenShareholders private _SHAREHOLDERS = VokenShareholders(0x7712F76D2A52141D44461CDbC8b660506DCAB752);
    address payable private _TEAM;

     
    uint16[15] private REWARDS_PCT = [6, 6, 5, 4, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1];

     
    uint16[] private LIMIT_COUNTER = [1, 3, 10, 50, 100, 200, 300];
    uint256[] private LIMIT_WEIS = [100 ether, 50 ether, 40 ether, 30 ether, 20 ether, 10 ether, 5 ether];
    uint256 private LIMIT_WEI_MIN = 3 ether;

     
    uint24 private GAS_MIN = 6000000;

     
    uint256 private VOKEN_USD_PRICE_START = 1000;        
    uint256 private VOKEN_USD_PRICE_STEP = 10;           
    uint256 private STAGE_USD_CAP_START = 100000000;     
    uint256 private STAGE_USD_CAP_STEP = 1000000;        
    uint256 private STAGE_USD_CAP_MAX = 15100000000;     

     
    uint256 private _etherUsdPrice;
    uint256 private _vokenUsdPrice;

     
    uint16 private SEASON_MAX = 100;     
    uint16 private SEASON_LIMIT = 20;    
    uint16 private SEASON_STAGES = 600;  
    uint16 private STAGE_MAX = SEASON_STAGES.mul(SEASON_MAX);
    uint16 private STAGE_LIMIT = SEASON_STAGES.mul(SEASON_LIMIT);
    uint16 private _stage;
    uint16 private _season;

     
    uint256 private _txs;
    uint256 private _vokenIssued;
    uint256 private _vokenIssuedTxs;
    uint256 private _vokenBonus;
    uint256 private _vokenBonusTxs;
    uint256 private _weiSold;
    uint256 private _weiRewarded;
    uint256 private _weiShareholders;
    uint256 private _weiTeam;
    uint256 private _weiPended;
    uint256 private _usdSold;
    uint256 private _usdRewarded;

     
    uint256 private SHAREHOLDERS_RATIO_START = 15000000;     
    uint256 private SHAREHOLDERS_RATIO_DISTANCE = 50000000;  
    uint256 private _shareholdersRatio;

     
    bool private _cacheWhitelisted;
    uint256 private _cacheWeiShareholders;
    uint256 private _cachePended;
    uint16[] private _cacheRewards;
    address payable[] private _cacheReferees;

     
    mapping (address => Allocations.Allocation[]) private _allocations;

     
    mapping (address => uint256) private _accountVokenIssued;
    mapping (address => uint256) private _accountVokenBonus;
    mapping (address => uint256) private _accountVokenReferral;
    mapping (address => uint256) private _accountVokenReferrals;
    mapping (address => uint256) private _accountUsdPurchased;
    mapping (address => uint256) private _accountWeiPurchased;
    mapping (address => uint256) private _accountUsdRewarded;
    mapping (address => uint256) private _accountWeiRewarded;

     
    mapping (uint16 => uint256) private _stageUsdSold;
    mapping (uint16 => uint256) private _stageVokenIssued;
    mapping (uint16 => uint256) private _stageVokenBonus;

     
    mapping (uint16 => uint256) private _seasonWeiSold;
    mapping (uint16 => uint256) private _seasonWeiRewarded;
    mapping (uint16 => uint256) private _seasonWeiShareholders;
    mapping (uint16 => uint256) private _seasonWeiPended;
    mapping (uint16 => uint256) private _seasonUsdSold;
    mapping (uint16 => uint256) private _seasonUsdRewarded;
    mapping (uint16 => uint256) private _seasonUsdShareholders;
    mapping (uint16 => uint256) private _seasonVokenIssued;
    mapping (uint16 => uint256) private _seasonVokenBonus;

     
    mapping (uint16 => mapping (address => uint256)) private _vokenSeasonAccountIssued;
    mapping (uint16 => mapping (address => uint256)) private _vokenSeasonAccountBonus;
    mapping (uint16 => mapping (address => uint256)) private _vokenSeasonAccountReferral;
    mapping (uint16 => mapping (address => uint256)) private _vokenSeasonAccountReferrals;
    mapping (uint16 => mapping (address => uint256)) private _weiSeasonAccountPurchased;
    mapping (uint16 => mapping (address => uint256)) private _weiSeasonAccountReferrals;
    mapping (uint16 => mapping (address => uint256)) private _weiSeasonAccountRewarded;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountPurchased;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountReferrals;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountRewarded;

     
    mapping (uint16 => mapping (uint256 => address[])) private _seasonLimitAccounts;
    mapping (uint16 => address[]) private _seasonLimitWeiMinAccounts;

     
    mapping (uint16 => address[]) private _seasonAccounts;
    mapping (uint16 => address[]) private _seasonReferrals;
    mapping (uint16 => mapping (address => bool)) private _seasonHasAccount;
    mapping (uint16 => mapping (address => bool)) private _seasonHasReferral;
    mapping (uint16 => mapping (address => address[])) private _seasonAccountReferrals;
    mapping (uint16 => mapping (address => mapping (address => bool))) private _seasonAccountHasReferral;

     
    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);
    event StageClosed(uint256 _stageNumber);
    event SeasonClosed(uint16 _seasonNumber);
    event AuditEtherPriceUpdated(uint256 value, address indexed account);

    event Log(uint256 value);

     
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

     
    function isProxy(address account) public view returns (bool) {
        return _proxies.has(account);
    }

     
    function addProxy(address account) public onlyOwner {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

     
    function removeProxy(address account) public onlyOwner {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }

     
    function VOKEN() public view returns (IVoken2) {
        return _VOKEN;
    }

     
    function SHAREHOLDERS() public view returns (VokenShareholders) {
        return _SHAREHOLDERS;
    }

     
    function TEAM() public view returns (address) {
        return _TEAM;
    }

     
    function status() public view returns (uint16 stage,
                                           uint16 season,
                                           uint256 etherUsdPrice,
                                           uint256 vokenUsdPrice,
                                           uint256 shareholdersRatio) {
        if (_stage > STAGE_MAX) {
            stage = STAGE_MAX;
            season = SEASON_MAX;
        }
        else {
            stage = _stage;
            season = _season;
        }

        etherUsdPrice = _etherUsdPrice;
        vokenUsdPrice = _vokenUsdPrice;
        shareholdersRatio = _shareholdersRatio;
    }

     
    function sum() public view returns(uint256 vokenIssued,
                                       uint256 vokenBonus,
                                       uint256 weiSold,
                                       uint256 weiRewarded,
                                       uint256 weiShareholders,
                                       uint256 weiTeam,
                                       uint256 weiPended,
                                       uint256 usdSold,
                                       uint256 usdRewarded) {
        vokenIssued = _vokenIssued;
        vokenBonus = _vokenBonus;

        weiSold = _weiSold;
        weiRewarded = _weiRewarded;
        weiShareholders = _weiShareholders;
        weiTeam = _weiTeam;
        weiPended = _weiPended;

        usdSold = _usdSold;
        usdRewarded = _usdRewarded;
    }

     
    function transactions() public view returns(uint256 txs,
                                                uint256 vokenIssuedTxs,
                                                uint256 vokenBonusTxs) {
        txs = _txs;
        vokenIssuedTxs = _vokenIssuedTxs;
        vokenBonusTxs = _vokenBonusTxs;
    }

     
    function queryAccount(address account) public view returns (uint256 vokenIssued,
                                                                uint256 vokenBonus,
                                                                uint256 vokenReferral,
                                                                uint256 vokenReferrals,
                                                                uint256 weiPurchased,
                                                                uint256 weiRewarded,
                                                                uint256 usdPurchased,
                                                                uint256 usdRewarded) {
        vokenIssued = _accountVokenIssued[account];
        vokenBonus = _accountVokenBonus[account];
        vokenReferral = _accountVokenReferral[account];
        vokenReferrals = _accountVokenReferrals[account];
        weiPurchased = _accountWeiPurchased[account];
        weiRewarded = _accountWeiRewarded[account];
        usdPurchased = _accountUsdPurchased[account];
        usdRewarded = _accountUsdRewarded[account];
    }

     
    function stage(uint16 stageIndex) public view returns (uint256 vokenUsdPrice,
                                                           uint256 shareholdersRatio,
                                                           uint256 vokenIssued,
                                                           uint256 vokenBonus,
                                                           uint256 vokenCap,
                                                           uint256 vokenOnSale,
                                                           uint256 usdSold,
                                                           uint256 usdCap,
                                                           uint256 usdOnSale) {
        if (stageIndex <= STAGE_LIMIT) {
            vokenUsdPrice = _calcVokenUsdPrice(stageIndex);
            shareholdersRatio = _calcShareholdersRatio(stageIndex);

            vokenIssued = _stageVokenIssued[stageIndex];
            vokenBonus = _stageVokenBonus[stageIndex];
            vokenCap = _stageVokenCap(stageIndex);
            vokenOnSale = vokenCap.sub(vokenIssued);

            usdSold = _stageUsdSold[stageIndex];
            usdCap = _stageUsdCap(stageIndex);
            usdOnSale = usdCap.sub(usdSold);
        }
    }

     
    function season(uint16 seasonNumber) public view returns (uint256 vokenIssued,
                                                              uint256 vokenBonus,
                                                              uint256 weiSold,
                                                              uint256 weiRewarded,
                                                              uint256 weiShareholders,
                                                              uint256 weiPended,
                                                              uint256 usdSold,
                                                              uint256 usdRewarded,
                                                              uint256 usdShareholders) {
        if (seasonNumber <= SEASON_LIMIT) {
            vokenIssued = _seasonVokenIssued[seasonNumber];
            vokenBonus = _seasonVokenBonus[seasonNumber];

            weiSold = _seasonWeiSold[seasonNumber];
            weiRewarded = _seasonWeiRewarded[seasonNumber];
            weiShareholders = _seasonWeiShareholders[seasonNumber];
            weiPended = _seasonWeiPended[seasonNumber];

            usdSold = _seasonUsdSold[seasonNumber];
            usdRewarded = _seasonUsdRewarded[seasonNumber];
            usdShareholders = _seasonUsdShareholders[seasonNumber];
        }
    }

     
    function accountInSeason(address account, uint16 seasonNumber) public view returns (uint256 vokenIssued,
                                                                                        uint256 vokenBonus,
                                                                                        uint256 vokenReferral,
                                                                                        uint256 vokenReferrals,
                                                                                        uint256 weiPurchased,
                                                                                        uint256 weiReferrals,
                                                                                        uint256 weiRewarded,
                                                                                        uint256 usdPurchased,
                                                                                        uint256 usdReferrals,
                                                                                        uint256 usdRewarded) {
        if (seasonNumber > 0 && seasonNumber <= SEASON_LIMIT) {
            vokenIssued = _vokenSeasonAccountIssued[seasonNumber][account];
            vokenBonus = _vokenSeasonAccountBonus[seasonNumber][account];
            vokenReferral = _vokenSeasonAccountReferral[seasonNumber][account];
            vokenReferrals = _vokenSeasonAccountReferrals[seasonNumber][account];
            weiPurchased = _weiSeasonAccountPurchased[seasonNumber][account];
            weiReferrals = _weiSeasonAccountReferrals[seasonNumber][account];
            weiRewarded = _weiSeasonAccountRewarded[seasonNumber][account];
            usdPurchased = _usdSeasonAccountPurchased[seasonNumber][account];
            usdReferrals = _usdSeasonAccountReferrals[seasonNumber][account];
            usdRewarded = _usdSeasonAccountRewarded[seasonNumber][account];
        }
    }

     
    function seasonReferrals(uint16 seasonNumber) public view returns (address[] memory) {
        return _seasonReferrals[seasonNumber];
    }

     
    function seasonAccountReferrals(uint16 seasonNumber, address account) public view returns (address[] memory) {
        return _seasonAccountReferrals[seasonNumber][account];
    }









     
    function _calcVokenUsdPrice(uint16 stageIndex) private view returns (uint256) {
        return VOKEN_USD_PRICE_START.add(VOKEN_USD_PRICE_STEP.mul(stageIndex));
    }

     
    function _calcShareholdersRatio(uint16 stageIndex) private view returns (uint256) {
        return SHAREHOLDERS_RATIO_START.add(SHAREHOLDERS_RATIO_DISTANCE.mul(stageIndex).div(STAGE_MAX));
    }

     
    function _stageUsdCap(uint16 stageIndex) private view returns (uint256) {
        uint256 __usdCap = STAGE_USD_CAP_START.add(STAGE_USD_CAP_STEP.mul(stageIndex));

        if (__usdCap > STAGE_USD_CAP_MAX) {
            return STAGE_USD_CAP_MAX;
        }

        return __usdCap;
    }

     
    function _stageVokenCap(uint16 stageIndex) private view returns (uint256) {
        return _stageUsdCap(stageIndex).mul(1000000).div(_calcVokenUsdPrice(stageIndex));
    }

     
    function _2shareholders(uint256 value) private view returns (uint256) {
        return value.mul(_shareholdersRatio).div(100000000);
    }

     
    function _wei2usd(uint256 weiAmount) private view returns (uint256) {
        return weiAmount.mul(_etherUsdPrice).div(1 ether);
    }

     
    function _usd2wei(uint256 usdAmount) private view returns (uint256) {
        return usdAmount.mul(1 ether).div(_etherUsdPrice);
    }

     
    function _usd2voken(uint256 usdAmount) private view returns (uint256) {
        return usdAmount.mul(1000000).div(_vokenUsdPrice);
    }

     
    function _seasonNumber(uint16 stageIndex) private view returns (uint16) {
        if (stageIndex > 0) {
            uint16 __seasonNumber = stageIndex.div(SEASON_STAGES);

            if (stageIndex.mod(SEASON_STAGES) > 0) {
                return __seasonNumber.add(1);
            }

            return __seasonNumber;
        }

        return 1;
    }

     
    function _closeStage() private {
        _stage = _stage.add(1);
        emit StageClosed(_stage);

         
        uint16 __seasonNumber = _seasonNumber(_stage);
        if (_season < __seasonNumber) {
            _season = __seasonNumber;
            emit SeasonClosed(_season);
        }

        _vokenUsdPrice = _calcVokenUsdPrice(_stage);
        _shareholdersRatio = _calcShareholdersRatio(_stage);
    }

     
    function updateEtherUsdPrice(uint256 value) external onlyProxy {
        _etherUsdPrice = value;
        emit AuditEtherPriceUpdated(value, msg.sender);
    }

     
    function updateTeamWallet(address payable account) external onlyOwner {
        _TEAM = account;
    }

     
    function weiMax() public view returns (uint256) {
        for(uint16 i = 0; i < LIMIT_WEIS.length; i++) {
            if (_seasonLimitAccounts[_season][i].length < LIMIT_COUNTER[i]) {
                return LIMIT_WEIS[i];
            }
        }

        return LIMIT_WEI_MIN;
    }

     
    function _limit(uint256 weiAmount) private view returns (uint256 __wei) {
        uint256 __purchased = _weiSeasonAccountPurchased[_season][msg.sender];
        for(uint16 i = 0; i < LIMIT_WEIS.length; i++) {
            if (__purchased >= LIMIT_WEIS[i]) {
                return 0;
            }

            if (__purchased < LIMIT_WEIS[i]) {
                __wei = LIMIT_WEIS[i].sub(__purchased);
                if (weiAmount >= __wei && _seasonLimitAccounts[_season][i].length < LIMIT_COUNTER[i]) {
                    return __wei;
                }
            }
        }

        if (__purchased < LIMIT_WEI_MIN) {
            return LIMIT_WEI_MIN.sub(__purchased);
        }
    }

     
    function _updateSeasonLimits() private {
        uint256 __purchased = _weiSeasonAccountPurchased[_season][msg.sender];
        if (__purchased > LIMIT_WEI_MIN) {
            for(uint16 i = 0; i < LIMIT_WEIS.length; i++) {
                if (__purchased >= LIMIT_WEIS[i]) {
                    _seasonLimitAccounts[_season][i].push(msg.sender);
                    return;
                }
            }
        }

        else if (__purchased == LIMIT_WEI_MIN) {
            _seasonLimitWeiMinAccounts[_season].push(msg.sender);
            return;
        }
    }

     
    function seasonLimitAccounts(uint16 seasonNumber, uint16 limitIndex) public view returns (uint256 weis, address[] memory accounts) {
        if (limitIndex < LIMIT_WEIS.length) {
            weis = LIMIT_WEIS[limitIndex];
            accounts = _seasonLimitAccounts[seasonNumber][limitIndex];
        }

        else {
            weis = LIMIT_WEI_MIN;
            accounts = _seasonLimitWeiMinAccounts[seasonNumber];
        }
    }

     
    constructor () public {
        _stage = 3277;
        _season = _seasonNumber(_stage);
        _vokenUsdPrice = _calcVokenUsdPrice(_stage);
        _shareholdersRatio = _calcShareholdersRatio(_stage);

        _TEAM = msg.sender;
        addProxy(msg.sender);
    }

     
    function () external payable whenNotPaused {
        require(_etherUsdPrice > 0, "VokenPublicSale2: Audit ETH price is zero");
        require(_stage <= STAGE_MAX, "VokenPublicSale2: Voken Public-Sale Completled");

        uint256 __usdAmount;
        uint256 __usdRemain;
        uint256 __usdUsed;
        uint256 __weiUsed;
        uint256 __voken;

         
        uint256 __weiMax = _limit(msg.value);
        if (__weiMax < msg.value) {
            __usdAmount = _wei2usd(__weiMax);
        }
        else {
            __usdAmount = _wei2usd(msg.value);
        }

        __usdRemain = __usdAmount;

        if (__usdRemain > 0) {
             
            _cache();

             
            while (gasleft() > GAS_MIN && __usdRemain > 0 && _stage <= STAGE_LIMIT) {
                uint256 __txVokenIssued;
                (__txVokenIssued, __usdRemain) = _tx(__usdRemain);
                __voken = __voken.add(__txVokenIssued);
            }

             
            __usdUsed = __usdAmount.sub(__usdRemain);
            __weiUsed = _usd2wei(__usdUsed);

             
            if (_cacheWhitelisted && __voken > 0) {
                _mintVokenBonus(__voken);

                for(uint16 i = 0; i < _cacheReferees.length; i++) {
                    address payable __referee = _cacheReferees[i];
                    uint256 __usdReward = __usdUsed.mul(_cacheRewards[i]).div(100);
                    uint256 __weiReward = __weiUsed.mul(_cacheRewards[i]).div(100);

                    __referee.transfer(__weiReward);
                    _usdRewarded = _usdRewarded.add(__usdReward);
                    _weiRewarded = _weiRewarded.add(__weiReward);
                    _accountUsdRewarded[__referee] = _accountUsdRewarded[__referee].add(__usdReward);
                    _accountWeiRewarded[__referee] = _accountWeiRewarded[__referee].add(__weiReward);
                }

                if (_cachePended > 0) {
                    _weiPended = _weiPended.add(__weiUsed.mul(_cachePended).div(100));
                }
            }

             
            if (__weiUsed > 0) {
                _txs = _txs.add(1);
                _usdSold = _usdSold.add(__usdUsed);
                _weiSold = _weiSold.add(__weiUsed);
                _accountUsdPurchased[msg.sender] = _accountUsdPurchased[msg.sender].add(__usdUsed);
                _accountWeiPurchased[msg.sender] = _accountWeiPurchased[msg.sender].add(__weiUsed);

                 
                _weiShareholders = _weiShareholders.add(_cacheWeiShareholders);
                (bool __bool,) = address(_SHAREHOLDERS).call.value(_cacheWeiShareholders)("");
                assert(__bool);

                 
                uint256 __weiTeam = _weiSold.sub(_weiRewarded).sub(_weiShareholders).sub(_weiPended).sub(_weiTeam);
                _weiTeam = _weiTeam.add(__weiTeam);
                _TEAM.transfer(__weiTeam);

                 
                _updateSeasonLimits();
            }

             
            _resetCache();
        }

         
        uint256 __weiRemain = msg.value.sub(__weiUsed);
        if (__weiRemain > 0) {
            msg.sender.transfer(__weiRemain);
        }
    }

     
    function _cache() private {
        if (!_seasonHasAccount[_season][msg.sender]) {
            _seasonAccounts[_season].push(msg.sender);
            _seasonHasAccount[_season][msg.sender] = true;
        }

        _cacheWhitelisted = _VOKEN.whitelisted(msg.sender);
        if (_cacheWhitelisted) {
            address __account = msg.sender;
            for(uint16 i = 0; i < REWARDS_PCT.length; i++) {
                address __referee = _VOKEN.whitelistReferee(__account);

                if (__referee != address(0) && __referee != __account && _VOKEN.whitelistReferralsCount(__referee) > i) {
                    if (!_seasonHasReferral[_season][__referee]) {
                        _seasonReferrals[_season].push(__referee);
                        _seasonHasReferral[_season][__referee] = true;
                    }

                    if (!_seasonAccountHasReferral[_season][__referee][__account]) {
                        _seasonAccountReferrals[_season][__referee].push(__account);
                        _seasonAccountHasReferral[_season][__referee][__account] = true;
                    }

                    _cacheReferees.push(address(uint160(__referee)));
                    _cacheRewards.push(REWARDS_PCT[i]);
                }
                else {
                    _cachePended = _cachePended.add(REWARDS_PCT[i]);
                }

                __account = __referee;
            }
        }
    }

     
    function _resetCache() private {
        delete _cacheWeiShareholders;

        if (_cacheWhitelisted) {
            delete _cacheWhitelisted;
            delete _cacheReferees;
            delete _cacheRewards;
            delete _cachePended;
        }
    }

     
    function _tx(uint256 __usd) private returns (uint256 __voken, uint256 __usdRemain) {
        uint256 __stageUsdCap = _stageUsdCap(_stage);
        uint256 __usdUsed;

         
        if (_stageUsdSold[_stage].add(__usd) <= __stageUsdCap) {
            __usdUsed = __usd;

            (__voken, ) = _calcExchange(__usdUsed);
            _mintVokenIssued(__voken);

             
            if (__stageUsdCap == _stageUsdSold[_stage]) {
                _closeStage();
            }
        }

         
        else {
            __usdUsed = __stageUsdCap.sub(_stageUsdSold[_stage]);

            (__voken, ) = _calcExchange(__usdUsed);
            _mintVokenIssued(__voken);

            _closeStage();

            __usdRemain = __usd.sub(__usdUsed);
        }
    }

     
    function _calcExchange(uint256 __usd) private returns (uint256 __voken, uint256 __wei) {
        __wei = _usd2wei(__usd);
        __voken = _usd2voken(__usd);

        uint256 __usdShareholders = _2shareholders(__usd);
        uint256 __weiShareholders = _usd2wei(__usdShareholders);

         
        _stageUsdSold[_stage] = _stageUsdSold[_stage].add(__usd);

         
        _seasonUsdSold[_season] = _seasonUsdSold[_season].add(__usd);
        _seasonWeiSold[_season] = _seasonWeiSold[_season].add(__wei);

         
        if (_cachePended > 0) {
            _seasonWeiPended[_season] = _seasonWeiPended[_season].add(__wei.mul(_cachePended).div(100));
        }

         
        _seasonUsdShareholders[_season] = _seasonUsdShareholders[_season].add(__usdShareholders);
        _seasonWeiShareholders[_season] = _seasonWeiShareholders[_season].add(__weiShareholders);

         
        _cacheWeiShareholders = _cacheWeiShareholders.add(__weiShareholders);

         
        _usdSeasonAccountPurchased[_season][msg.sender] = _usdSeasonAccountPurchased[_season][msg.sender].add(__usd);
        _weiSeasonAccountPurchased[_season][msg.sender] = _weiSeasonAccountPurchased[_season][msg.sender].add(__wei);

         
        if (_cacheWhitelisted) {
            for (uint16 i = 0; i < _cacheRewards.length; i++) {
                address __referee = _cacheReferees[i];
                uint256 __usdReward = __usd.mul(_cacheRewards[i]).div(100);
                uint256 __weiReward = __wei.mul(_cacheRewards[i]).div(100);

                 
                _seasonUsdRewarded[_season] = _seasonUsdRewarded[_season].add(__usdReward);
                _seasonWeiRewarded[_season] = _seasonWeiRewarded[_season].add(__weiReward);

                 
                _usdSeasonAccountRewarded[_season][__referee] = _usdSeasonAccountRewarded[_season][__referee].add(__usdReward);
                _weiSeasonAccountRewarded[_season][__referee] = _weiSeasonAccountRewarded[_season][__referee].add(__weiReward);
                _usdSeasonAccountReferrals[_season][__referee] = _usdSeasonAccountReferrals[_season][__referee].add(__usd);
                _weiSeasonAccountReferrals[_season][__referee] = _weiSeasonAccountReferrals[_season][__referee].add(__wei);

                _vokenSeasonAccountReferrals[_season][__referee] = _vokenSeasonAccountReferrals[_season][__referee].add(__voken);
                _accountVokenReferrals[__referee] = _accountVokenReferrals[__referee].add(__voken);

                if (i == 0) {
                    _vokenSeasonAccountReferral[_season][__referee] = _vokenSeasonAccountReferral[_season][__referee].add(__voken);
                    _accountVokenReferral[__referee] = _accountVokenReferral[__referee].add(__voken);
                }
            }
        }
    }

     
    function _mintVokenIssued(uint256 amount) private {
         
        _vokenIssued = _vokenIssued.add(amount);
        _vokenIssuedTxs = _vokenIssuedTxs.add(1);

         
        _accountVokenIssued[msg.sender] = _accountVokenIssued[msg.sender].add(amount);

         
        _stageVokenIssued[_stage] = _stageVokenIssued[_stage].add(amount);

         
        _seasonVokenIssued[_season] = _seasonVokenIssued[_season].add(amount);
        _vokenSeasonAccountIssued[_season][msg.sender] = _vokenSeasonAccountIssued[_season][msg.sender].add(amount);

         
        assert(_VOKEN.mint(msg.sender, amount));
    }

     
    function _mintVokenBonus(uint256 amount) private {
         
        _vokenBonus = _vokenBonus.add(amount);
        _vokenBonusTxs = _vokenBonusTxs.add(1);

         
        _accountVokenBonus[msg.sender] = _accountVokenBonus[msg.sender].add(amount);

         
        _stageVokenBonus[_stage] = _stageVokenBonus[_stage].add(amount);

         
        _seasonVokenBonus[_season] = _seasonVokenBonus[_season].add(amount);
        _vokenSeasonAccountBonus[_season][msg.sender] = _vokenSeasonAccountBonus[_season][msg.sender].add(amount);

         
        Allocations.Allocation memory __allocation;
        __allocation.amount = amount;
        __allocation.timestamp = now;
        _allocations[msg.sender].push(__allocation);
        assert(_VOKEN.mintWithAllocation(msg.sender, amount, address(this)));
    }

     
    function reservedOf(address account) public view returns (uint256) {
        Allocations.Allocation[] memory __allocations = _allocations[account];

        uint256 __len = __allocations.length;
        if (__len > 0) {
            uint256 __vokenIssued = _accountVokenIssued[account];
            uint256 __vokenBonus = _accountVokenBonus[account];
            uint256 __vokenReferral = _accountVokenReferral[account];
            uint256 __vokenBalance = _VOKEN.balanceOf(account);

             
            if (__vokenIssued < __vokenBalance) {
                __vokenBalance = __vokenBalance.sub(__vokenIssued);
            }
            else {
                __vokenBalance = 0;
            }

             
            if (__vokenBonus < __vokenBalance) {
                __vokenBalance = __vokenBalance.sub(__vokenBonus);
            }
            else {
                __vokenBalance = 0;
            }

            uint256 __reserved;
            for (uint256 i = 0; i < __len; i++) {
                 
                Allocations.Allocation memory __allocation = __allocations[i];
                __reserved = __reserved.add(__allocation.amount);
                if (now >= __allocation.timestamp.add(90 days)) {
                     
                    uint256 __distance = 180 days;

                     
                    if (__vokenReferral > __allocation.amount) {
                        __distance = __distance.sub(__vokenReferral.div(__allocation.amount).mul(1 days));
                        if (__distance > 120 days) {
                            __distance = 120 days;
                        }
                    }

                     
                    if (__vokenBalance > __allocation.amount) {
                        __distance = __distance.sub(__vokenBalance.div(__allocation.amount).mul(30 days));
                    }

                     
                    if (__distance > 90 days) {
                        __distance = 90 days;
                    }

                     
                    uint256 __timestamp = __allocation.timestamp.add(__distance);
                    if (now > __timestamp) {
                        uint256 __passed = now.sub(__timestamp).div(1 days).add(1);

                        if (__passed > 30) {
                            __reserved = __reserved.sub(__allocation.amount);
                        }
                        else {
                            __reserved = __reserved.sub(__allocation.amount.mul(__passed).div(30));
                        }
                    }
                }
            }

            return __reserved;
        }

        return 0;
    }
}