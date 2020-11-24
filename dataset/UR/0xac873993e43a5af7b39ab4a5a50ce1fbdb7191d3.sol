 

pragma solidity ^0.5.7;

 
 
 
 
 
 
 
 
 


 
library SafeMath256 {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library SafeMath16 {
     
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint16 a, uint16 b) internal pure returns (uint16 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }

     
    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address private _owner;
    address payable internal _receiver;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReceiverChanged(address indexed previousReceiver, address indexed newReceiver);

     
    constructor () internal {
        _owner = msg.sender;
        _receiver = msg.sender;
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
    }

     
    function changeReceiver(address payable newReceiver) external onlyOwner {
        require(newReceiver != address(0));
        address __previousReceiver = _receiver;
        _receiver = newReceiver;
        emit ReceiverChanged(__previousReceiver, newReceiver);
    }

     
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount);

        assert(_token.transfer(receiver, amount));
    }

     
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));
        uint256 balance = address(this).balance;
        require(balance >= amount);

        to.transfer(amount);
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
        require(!_paused, "Paused.");
        _;
    }

     
    function setPaused(bool state) external onlyOwner {
        if (_paused && !state) {
            _paused = false;
            emit Unpaused(msg.sender);
        } else if (!_paused && state) {
            _paused = true;
            emit Paused(msg.sender);
        }
    }
}


 
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}


 
interface IVoken {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function inWhitelist(address account) external view returns (bool);
    function referrer(address account) external view returns (address);
    function refCount(address account) external view returns (uint256);
}


 
contract VokenPublicSale is Ownable, Pausable{
    using SafeMath16 for uint16;
    using SafeMath256 for uint256;

     
    IVoken public VOKEN = IVoken(0x82070415FEe803f94Ce5617Be1878503e58F0a6a);

     
    uint32 _startTimestamp;

     
    uint256 private _etherPrice;     

     
    uint16 private WHITELIST_REF_REWARDS_PCT_SUM = 35;
    uint16[15] private WHITELIST_REF_REWARDS_PCT = [
        6,   
        6,   
        5,   
        4,   
        3,   
        2,   
        1,   
        1,   
        1,   
        1,   
        1,   
        1,   
        1,   
        1,   
        1    
    ];

     
    uint72 private WEI_MIN = 0.1 ether;      
    uint72 private WEI_MAX = 100 ether;      
    uint72 private WEI_BONUS = 10 ether;     
    uint24 private GAS_MIN = 3000000;        
    uint24 private GAS_EX = 1500000;         

     
    uint256 private VOKEN_USD_PRICE_START = 1000;        
    uint256 private VOKEN_USD_PRICE_STEP = 10;           
    uint256 private STAGE_USD_CAP_START = 100000000;     
    uint256 private STAGE_USD_CAP_STEP = 1000000;        
    uint256 private STAGE_USD_CAP_MAX = 15100000000;     

    uint256 private _vokenUsdPrice = VOKEN_USD_PRICE_START;

     
    uint16 private STAGE_MAX = 60000;    
    uint16 private SEASON_MAX = 100;     
    uint16 private SEASON_STAGES = 600;  

    uint16 private _stage;
    uint16 private _season;

     
    uint256 private _txs;
    uint256 private _vokenTxs;
    uint256 private _vokenBonusTxs;
    uint256 private _vokenWhitelistTxs;
    uint256 private _vokenIssued;
    uint256 private _vokenBonus;
    uint256 private _vokenWhitelist;
    uint256 private _weiSold;
    uint256 private _weiRefRewarded;
    uint256 private _weiTopSales;
    uint256 private _weiTeam;
    uint256 private _weiPending;
    uint256 private _weiPendingTransfered;

     
    uint256 private TOP_SALES_RATIO_START = 15000000;          
    uint256 private TOP_SALES_RATIO_DISTANCE = 50000000;       

    uint256 private _topSalesRatio = TOP_SALES_RATIO_START;    

     
    bool private _inWhitelist_;
    uint256 private _pending_ = WHITELIST_REF_REWARDS_PCT_SUM;
    uint16[] private _rewards_;
    address[] private _referrers_;

     
    mapping (address => bool) private _etherPriceAuditors;

     
    mapping (uint16 => uint256) private _stageUsdSold;
    mapping (uint16 => uint256) private _stageVokenIssued;

     
    mapping (uint16 => uint256) private _seasonWeiSold;
    mapping (uint16 => uint256) private _seasonWeiTopSales;
    mapping (uint16 => uint256) private _seasonWeiTopSalesTransfered;

     
    mapping (address => uint256) private _accountVokenIssued;
    mapping (address => uint256) private _accountVokenBonus;
    mapping (address => uint256) private _accountVokenWhitelisted;
    mapping (address => uint256) private _accountWeiPurchased;
    mapping (address => uint256) private _accountWeiRefRewarded;

     
    mapping (uint16 => address[]) private _seasonRefAccounts;
    mapping (uint16 => mapping (address => bool)) private _seasonHasRefAccount;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountPurchased;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountRef;

     
    event AuditEtherPriceChanged(uint256 value, address indexed account);
    event AuditEtherPriceAuditorChanged(address indexed account, bool state);

    event VokenBonusTransfered(address indexed to, uint256 amount);
    event VokenWhitelistTransfered(address indexed to, uint256 amount);
    event VokenIssuedTransfered(uint16 stageIndex, address indexed to, uint256 vokenAmount, uint256 auditEtherPrice, uint256 weiUsed);

    event StageClosed(uint256 _stageNumber, address indexed account);
    event SeasonClosed(uint16 _seasonNumber, address indexed account);

    event SeasonTopSalesWeiTransfered(uint16 seasonNumber, address indexed to, uint256 amount);
    event TeamWeiTransfered(address indexed to, uint256 amount);
    event PendingWeiTransfered(address indexed to, uint256 amount);


     
    function startTimestamp() public view returns (uint32) {
        return _startTimestamp;
    }

     
    function setStartTimestamp(uint32 timestamp) external onlyOwner {
        _startTimestamp = timestamp;
    }

     
    modifier onlyEtherPriceAuditor() {
        require(_etherPriceAuditors[msg.sender]);
        _;
    }

     
    function setEtherPrice(uint256 value) external onlyEtherPriceAuditor {
        _etherPrice = value;
        emit AuditEtherPriceChanged(value, msg.sender);
    }

     
    function etherPriceAuditor(address account) public view returns (bool) {
        return _etherPriceAuditors[account];
    }

     
    function setEtherPriceAuditor(address account, bool state) external onlyOwner {
        _etherPriceAuditors[account] = state;
        emit AuditEtherPriceAuditorChanged(account, state);
    }

     
    function stageVokenUsdPrice(uint16 stageIndex) private view returns (uint256) {
        return VOKEN_USD_PRICE_START.add(VOKEN_USD_PRICE_STEP.mul(stageIndex));
    }

     
    function wei2usd(uint256 amount) private view returns (uint256) {
        return amount.mul(_etherPrice).div(1 ether);
    }

     
    function usd2wei(uint256 amount) private view returns (uint256) {
        return amount.mul(1 ether).div(_etherPrice);
    }

     
    function usd2voken(uint256 usdAmount) private view returns (uint256) {
        return usdAmount.mul(1000000).div(_vokenUsdPrice);
    }

     
    function usd2vokenByStage(uint256 usdAmount, uint16 stageIndex) public view returns (uint256) {
        return usdAmount.mul(1000000).div(stageVokenUsdPrice(stageIndex));
    }

     
    function calcSeason(uint16 stageIndex) private view returns (uint16) {
        if (stageIndex > 0) {
            uint16 __seasonNumber = stageIndex.div(SEASON_STAGES);

            if (stageIndex.mod(SEASON_STAGES) > 0) {
                return __seasonNumber.add(1);
            }
            
            return __seasonNumber;
        }
        
        return 1;
    }

     
    function transferTopSales(uint16 seasonNumber, address payable to) external onlyOwner {
        uint256 __weiRemain = seasonTopSalesRemain(seasonNumber);
        require(to != address(0));
        
        _seasonWeiTopSalesTransfered[seasonNumber] = _seasonWeiTopSalesTransfered[seasonNumber].add(__weiRemain);
        emit SeasonTopSalesWeiTransfered(seasonNumber, to, __weiRemain);
        to.transfer(__weiRemain);
    }

     
    function pendingRemain() private view returns (uint256) {
        return _weiPending.sub(_weiPendingTransfered);
    }

     
    function transferPending(address payable to) external onlyOwner {
        uint256 __weiRemain = pendingRemain();
        require(to != address(0));

        _weiPendingTransfered = _weiPendingTransfered.add(__weiRemain);
        emit PendingWeiTransfered(to, __weiRemain);
        to.transfer(__weiRemain);
    }

     
    function transferTeam(address payable to) external onlyOwner {
        uint256 __weiRemain = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam);
        require(to != address(0));

        _weiTeam = _weiTeam.add(__weiRemain);
        emit TeamWeiTransfered(to, __weiRemain);
        to.transfer(__weiRemain);
    }

     
    function status() public view returns (uint256 auditEtherPrice,
                                           uint16 stage,
                                           uint16 season,
                                           uint256 vokenUsdPrice,
                                           uint256 currentTopSalesRatio,
                                           uint256 txs,
                                           uint256 vokenTxs,
                                           uint256 vokenBonusTxs,
                                           uint256 vokenWhitelistTxs,
                                           uint256 vokenIssued,
                                           uint256 vokenBonus,
                                           uint256 vokenWhitelist) {
        auditEtherPrice = _etherPrice;

        if (_stage > STAGE_MAX) {
            stage = STAGE_MAX;
            season = SEASON_MAX;
        } else {
            stage = _stage;
            season = _season;
        }

        vokenUsdPrice = _vokenUsdPrice;
        currentTopSalesRatio = _topSalesRatio;

        txs = _txs;
        vokenTxs = _vokenTxs;
        vokenBonusTxs = _vokenBonusTxs;
        vokenWhitelistTxs = _vokenWhitelistTxs;
        vokenIssued = _vokenIssued;
        vokenBonus = _vokenBonus;
        vokenWhitelist = _vokenWhitelist;
    }

     
    function sum() public view returns(uint256 weiSold,
                                       uint256 weiReferralRewarded,
                                       uint256 weiTopSales,
                                       uint256 weiTeam,
                                       uint256 weiPending,
                                       uint256 weiPendingTransfered,
                                       uint256 weiPendingRemain) {
        weiSold = _weiSold;
        weiReferralRewarded = _weiRefRewarded;
        weiTopSales = _weiTopSales;
        weiTeam = _weiTeam;
        weiPending = _weiPending;
        weiPendingTransfered = _weiPendingTransfered;
        weiPendingRemain = pendingRemain();
    }

     
    modifier enoughGas() {
        require(gasleft() > GAS_MIN);
        _;
    }

     
    modifier onlyOnSale() {
        require(_startTimestamp > 0 && now > _startTimestamp, "Voken Public-Sale has not started yet.");
        require(_etherPrice > 0, "Audit ETH price must be greater than zero.");
        require(!paused(), "Voken Public-Sale is paused.");
        require(_stage <= STAGE_MAX, "Voken Public-Sale Closed.");
        _;
    }

     
    function topSalesRatio(uint16 stageIndex) private view returns (uint256) {
        return TOP_SALES_RATIO_START.add(TOP_SALES_RATIO_DISTANCE.mul(stageIndex).div(STAGE_MAX));
    }

     
    function usd2weiTopSales(uint256 usdAmount) private view returns (uint256) {
        return usd2wei(usdAmount.mul(_topSalesRatio).div(100000000));
    }

     
    function stageUsdCap(uint16 stageIndex) private view returns (uint256) {
        uint256 __usdCap = STAGE_USD_CAP_START.add(STAGE_USD_CAP_STEP.mul(stageIndex)); 

        if (__usdCap > STAGE_USD_CAP_MAX) {
            return STAGE_USD_CAP_MAX;
        }

        return __usdCap;
    }

     
    function stageVokenCap(uint16 stageIndex) private view returns (uint256) {
        return usd2vokenByStage(stageUsdCap(stageIndex), stageIndex);
    }

     
    function stageStatus(uint16 stageIndex) public view returns (uint256 vokenUsdPrice,
                                                                 uint256 vokenCap,
                                                                 uint256 vokenOnSale,
                                                                 uint256 vokenSold,
                                                                 uint256 usdCap,
                                                                 uint256 usdOnSale,
                                                                 uint256 usdSold,
                                                                 uint256 weiTopSalesRatio) {
        if (stageIndex > STAGE_MAX) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        vokenUsdPrice = stageVokenUsdPrice(stageIndex);

        vokenSold = _stageVokenIssued[stageIndex];
        vokenCap = stageVokenCap(stageIndex);
        vokenOnSale = vokenCap.sub(vokenSold);

        usdSold = _stageUsdSold[stageIndex];
        usdCap = stageUsdCap(stageIndex);
        usdOnSale = usdCap.sub(usdSold);

        weiTopSalesRatio = topSalesRatio(stageIndex);
    }

     
    function seasonTopSalesRemain(uint16 seasonNumber) private view returns (uint256) {
        return _seasonWeiTopSales[seasonNumber].sub(_seasonWeiTopSalesTransfered[seasonNumber]);
    }

     
    function seasonTopSalesRewards(uint16 seasonNumber) public view returns (uint256 weiSold,
                                                                             uint256 weiTopSales,
                                                                             uint256 weiTopSalesTransfered,
                                                                             uint256 weiTopSalesRemain) {
        weiSold = _seasonWeiSold[seasonNumber];
        weiTopSales = _seasonWeiTopSales[seasonNumber];
        weiTopSalesTransfered = _seasonWeiTopSalesTransfered[seasonNumber];
        weiTopSalesRemain = seasonTopSalesRemain(seasonNumber);
    }

     
    function accountQuery(address account) public view returns (uint256 vokenIssued,
                                                                uint256 vokenBonus,
                                                                uint256 vokenWhitelisted,
                                                                uint256 weiPurchased,
                                                                uint256 weiReferralRewarded) {
        vokenIssued = _accountVokenIssued[account];
        vokenBonus = _accountVokenBonus[account];
        vokenWhitelisted = _accountVokenWhitelisted[account];
        weiPurchased = _accountWeiPurchased[account];
        weiReferralRewarded = _accountWeiRefRewarded[account];
    }

     
    function seasonRefAccounts(uint16 seasonNumber) public view returns (address[] memory accounts) {
        accounts = _seasonRefAccounts[seasonNumber];
    }

     
    function usdSeasonAccountPurchased(uint16 seasonNumber, address account) public view returns (uint256) {
        return _usdSeasonAccountPurchased[seasonNumber][account];
    }

     
    function usdSeasonAccountRef(uint16 seasonNumber, address account) public view returns (uint256) {
        return _usdSeasonAccountRef[seasonNumber][account];
    }

     
    constructor () public {
        _etherPriceAuditors[msg.sender] = true;
        _stage = 0;
        _season = 1;
    }

     
    function () external payable enoughGas onlyOnSale {
        require(msg.value >= WEI_MIN);
        require(msg.value <= WEI_MAX);

         
        setTemporaryVariables();
        uint256 __usdAmount = wei2usd(msg.value);
        uint256 __usdRemain = __usdAmount;
        uint256 __vokenIssued;
        uint256 __vokenBonus;
        uint256 __usdUsed;
        uint256 __weiUsed;

         
        while (gasleft() > GAS_EX && __usdRemain > 0 && _stage <= STAGE_MAX) {
            uint256 __txVokenIssued;
            (__txVokenIssued, __usdRemain) = ex(__usdRemain);
            __vokenIssued = __vokenIssued.add(__txVokenIssued);
        }

         
        __usdUsed = __usdAmount.sub(__usdRemain);
        __weiUsed = usd2wei(__usdUsed);

         
        if (msg.value >= WEI_BONUS) {
            __vokenBonus = __vokenIssued.div(10);
            assert(transferVokenBonus(__vokenBonus));
        }

         
         
        if (_inWhitelist_ && __vokenIssued > 0) {
             
            assert(transferVokenWhitelisted(__vokenIssued.add(__vokenBonus)));

             
            sendWhitelistReferralRewards(__weiUsed);
        }

         
        if (__usdRemain > 0) {
            uint256 __weiRemain = usd2wei(__usdRemain);
            
            __weiUsed = msg.value.sub(__weiRemain);
            
             
            msg.sender.transfer(__weiRemain);
        }

         
        if (__weiUsed > 0) {
            _txs = _txs.add(1);
            _weiSold = _weiSold.add(__weiUsed);
            _accountWeiPurchased[msg.sender] = _accountWeiPurchased[msg.sender].add(__weiUsed);
        }

         
        uint256 __weiTeam;
        if (_season > SEASON_MAX)
            __weiTeam = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam);
        else
            __weiTeam = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam).div(0.01 ether).mul(0.01 ether);

        _weiTeam = _weiTeam.add(__weiTeam);
        _receiver.transfer(__weiTeam);

         
        assert(true);
    }

     
    function setTemporaryVariables() private {
        delete _referrers_;
        delete _rewards_;

        _inWhitelist_ = VOKEN.inWhitelist(msg.sender);
        _pending_ = WHITELIST_REF_REWARDS_PCT_SUM;

        address __cursor = msg.sender;
        for(uint16 i = 0; i < WHITELIST_REF_REWARDS_PCT.length; i++) {
            address __refAccount = VOKEN.referrer(__cursor);

            if (__cursor == __refAccount)
                break;

            if (VOKEN.refCount(__refAccount) > i) {
                if (!_seasonHasRefAccount[_season][__refAccount]) {
                    _seasonRefAccounts[_season].push(__refAccount);
                    _seasonHasRefAccount[_season][__refAccount] = true;
                }

                _pending_ = _pending_.sub(WHITELIST_REF_REWARDS_PCT[i]);
                _rewards_.push(WHITELIST_REF_REWARDS_PCT[i]);                    
                _referrers_.push(__refAccount);
            }

            __cursor = __refAccount;
        }
    }

     
    function ex(uint256 usdAmount) private returns (uint256, uint256) {
        uint256 __stageUsdCap = stageUsdCap(_stage);
        uint256 __vokenIssued;

         
        if (_stageUsdSold[_stage].add(usdAmount) <= __stageUsdCap) {
            exCount(usdAmount);

            __vokenIssued = usd2voken(usdAmount);
            assert(transfervokenIssued(__vokenIssued, usdAmount));

             
            if (__stageUsdCap == _stageUsdSold[_stage]) {
                assert(closeStage());
            }

            return (__vokenIssued, 0);
        }

         
        uint256 __usdUsed = __stageUsdCap.sub(_stageUsdSold[_stage]);
        uint256 __usdRemain = usdAmount.sub(__usdUsed);

        exCount(__usdUsed);

        __vokenIssued = usd2voken(__usdUsed);
        assert(transfervokenIssued(__vokenIssued, __usdUsed));
        assert(closeStage());

        return (__vokenIssued, __usdRemain);
    }

     
    function exCount(uint256 usdAmount) private {
        uint256 __weiSold = usd2wei(usdAmount);
        uint256 __weiTopSales = usd2weiTopSales(usdAmount);

        _usdSeasonAccountPurchased[_season][msg.sender] = _usdSeasonAccountPurchased[_season][msg.sender].add(usdAmount);    
        
        _stageUsdSold[_stage] = _stageUsdSold[_stage].add(usdAmount);                    
        _seasonWeiSold[_season] = _seasonWeiSold[_season].add(__weiSold);                
        _seasonWeiTopSales[_season] = _seasonWeiTopSales[_season].add(__weiTopSales);    
        _weiTopSales = _weiTopSales.add(__weiTopSales);                                  

         
        if (_inWhitelist_) {
            for (uint16 i = 0; i < _rewards_.length; i++) {
                _usdSeasonAccountRef[_season][_referrers_[i]] = _usdSeasonAccountRef[_season][_referrers_[i]].add(usdAmount);
            }
        }
    }

     
    function transfervokenIssued(uint256 amount, uint256 usdAmount) private returns (bool) {
        _vokenTxs = _vokenTxs.add(1);
        
        _vokenIssued = _vokenIssued.add(amount);
        _stageVokenIssued[_stage] = _stageVokenIssued[_stage].add(amount);
        _accountVokenIssued[msg.sender] = _accountVokenIssued[msg.sender].add(amount);

        assert(VOKEN.transfer(msg.sender, amount));
        emit VokenIssuedTransfered(_stage, msg.sender, amount, _etherPrice, usdAmount);
        return true;
    }

     
    function transferVokenBonus(uint256 amount) private returns (bool) {
        _vokenBonusTxs = _vokenBonusTxs.add(1);

        _vokenBonus = _vokenBonus.add(amount);
        _accountVokenBonus[msg.sender] = _accountVokenBonus[msg.sender].add(amount);

        assert(VOKEN.transfer(msg.sender, amount));
        emit VokenBonusTransfered(msg.sender, amount);
        return true;
    }

     
    function transferVokenWhitelisted(uint256 amount) private returns (bool) {
        _vokenWhitelistTxs = _vokenWhitelistTxs.add(1);

        _vokenWhitelist = _vokenWhitelist.add(amount);
        _accountVokenWhitelisted[msg.sender] = _accountVokenWhitelisted[msg.sender].add(amount);

        assert(VOKEN.transfer(msg.sender, amount));
        emit VokenWhitelistTransfered(msg.sender, amount);
        return true;
    }

     
    function closeStage() private returns (bool) {
        emit StageClosed(_stage, msg.sender);
        _stage = _stage.add(1);
        _vokenUsdPrice = stageVokenUsdPrice(_stage);
        _topSalesRatio = topSalesRatio(_stage);

         
        uint16 __seasonNumber = calcSeason(_stage);
        if (_season < __seasonNumber) {
            emit SeasonClosed(_season, msg.sender);
            _season = __seasonNumber;
        }

        return true;
    }

     
    function sendWhitelistReferralRewards(uint256 weiAmount) private {
        uint256 __weiRemain = weiAmount;
        for (uint16 i = 0; i < _rewards_.length; i++) {
            uint256 __weiReward = weiAmount.mul(_rewards_[i]).div(100);
            address payable __receiver = address(uint160(_referrers_[i]));

            _weiRefRewarded = _weiRefRewarded.add(__weiReward);
            _accountWeiRefRewarded[__receiver] = _accountWeiRefRewarded[__receiver].add(__weiReward);
            __weiRemain = __weiRemain.sub(__weiReward);

            __receiver.transfer(__weiReward);
        }
        
        if (_pending_ > 0)
            _weiPending = _weiPending.add(weiAmount.mul(_pending_).div(100));
    }
}