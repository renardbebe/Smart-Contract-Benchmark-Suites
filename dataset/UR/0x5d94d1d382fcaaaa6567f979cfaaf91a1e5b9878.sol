 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause(uint256 _id);
    event Unpause(uint256 _id);

    bool public paused_1 = false;
    bool public paused_2 = false;
    bool public paused_3 = false;
    bool public paused_4 = false;

    modifier whenNotPaused_1() {
        require(!paused_1);
        _;
    }
    modifier whenNotPaused_2() {
        require(!paused_2);
        _;
    }
    modifier whenNotPaused_3() {
        require(!paused_3);
        _;
    }
    modifier whenNotPaused_4() {
        require(!paused_4);
        _;
    }

    modifier whenPaused_1() {
        require(paused_1);
        _;
    }
    modifier whenPaused_2() {
        require(paused_2);
        _;
    }
    modifier whenPaused_3() {
        require(paused_3);
        _;
    }
    modifier whenPaused_4() {
        require(paused_4);
        _;
    }

    function pause_1() onlyOwner whenNotPaused_1 public {
        paused_1 = true;
        emit Pause(1);
    }
    function pause_2() onlyOwner whenNotPaused_2 public {
        paused_2 = true;
        emit Pause(2);
    }
    function pause_3() onlyOwner whenNotPaused_3 public {
        paused_3 = true;
        emit Pause(3);
    }
    function pause_4() onlyOwner whenNotPaused_4 public {
        paused_4 = true;
        emit Pause(4);
    }

    function unpause_1() onlyOwner whenPaused_1 public {
        paused_1 = false;
        emit Unpause(1);
    }
    function unpause_2() onlyOwner whenPaused_2 public {
        paused_2 = false;
        emit Unpause(2);
    }
    function unpause_3() onlyOwner whenPaused_3 public {
        paused_3 = false;
        emit Unpause(3);
    }
    function unpause_4() onlyOwner whenPaused_4 public {
        paused_4 = false;
        emit Unpause(4);
    }
}

contract JCLYLong is Pausable  {
    using SafeMath for *;
	
    event KeyPurchase(address indexed purchaser, uint256 eth, uint256 amount);
    event LeekStealOn();

    address private constant WALLET_ETH_COM1   = 0x2509CF8921b95bef38DEb80fBc420Ef2bbc53ce3; 
    address private constant WALLET_ETH_COM2   = 0x18d9fc8e3b65124744553d642989e3ba9e41a95a; 

     
    uint256 constant private rndInit_ = 10 hours;      
    uint256 constant private rndInc_ = 30 seconds;   
    uint256 constant private rndMax_ = 24 hours;    

     
    uint256 constant private ethLimiterRange1_ = 1e20;
    uint256 constant private ethLimiterRange2_ = 5e20;
    uint256 constant private ethLimiter1_ = 2e18;
    uint256 constant private ethLimiter2_ = 7e18;

     
    uint256 constant private whitelistRange_ = 1 days;

     
    uint256 constant private priceStage1_ = 500e18;
    uint256 constant private priceStage2_ = 1000e18;
    uint256 constant private priceStage3_ = 2000e18;
    uint256 constant private priceStage4_ = 4000e18;
    uint256 constant private priceStage5_ = 8000e18;
    uint256 constant private priceStage6_ = 16000e18;
    uint256 constant private priceStage7_ = 32000e18;
    uint256 constant private priceStage8_ = 64000e18;
    uint256 constant private priceStage9_ = 128000e18;
    uint256 constant private priceStage10_ = 256000e18;
    uint256 constant private priceStage11_ = 512000e18;
    uint256 constant private priceStage12_ = 1024000e18;

     
    uint256 constant private guPhrase1_ = 5 days;
    uint256 constant private guPhrase2_ = 7 days;
    uint256 constant private guPhrase3_ = 9 days;
    uint256 constant private guPhrase4_ = 11 days;
    uint256 constant private guPhrase5_ = 13 days;
    uint256 constant private guPhrase6_ = 15 days;
    uint256 constant private guPhrase7_ = 17 days;
    uint256 constant private guPhrase8_ = 19 days;
    uint256 constant private guPhrase9_ = 21 days;
    uint256 constant private guPhrase10_ = 23 days;


 
    uint256 public contractStartDate_;     
    uint256 public allMaskGu_;  
    uint256 public allGuGiven_;  
    mapping (uint256 => uint256) public playOrders_;  
 
    uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      
    mapping (uint256 => mapping (uint256 => uint256)) public airDropWinners_;  
    uint256 public airDropCount_;
 
    uint256 public leekStealPot_;              
    uint256 public leekStealTracker_ = 0;      
    uint256 public leekStealToday_;
    bool public leekStealOn_;
    mapping (uint256 => uint256) public dayStealTime_;  
    mapping (uint256 => uint256) public leekStealWins_;  
 
    uint256 public pID_;         
    mapping (address => uint256) public pIDxAddr_;           
     
    mapping (uint256 => Datasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => Datasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (uint256 => Datasets.PlayerPhrases)) public plyrPhas_;     
 
    uint256 public rID_;     
    mapping (uint256 => Datasets.Round) public round_;    
 
    uint256 public phID_;  
    mapping (uint256 => Datasets.Phrase) public phrase_;    
 
    mapping(address => bool) public whitelisted_Prebuy;  

 
    constructor()
        public
    {
         
        pIDxAddr_[owner] = 0; 
        plyr_[0].addr = owner; 
        pIDxAddr_[WALLET_ETH_COM1] = 1; 
        plyr_[1].addr = WALLET_ETH_COM1; 
        pIDxAddr_[WALLET_ETH_COM2] = 2; 
        plyr_[2].addr = WALLET_ETH_COM2; 
        pID_ = 2;
    }

 

    modifier isActivated() {
        require(activated_ == true); 
        _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000);
        require(_eth <= 100000000000000000000000);
        _;    
    }

    modifier withinMigrationPeriod() {
        require(now < 1535637600);
        _;
    }
    
 

    function deposit() 
        isWithinLimits(msg.value)
        onlyOwner
        public
        payable
    {}

    function migrateBasicData(uint256 allMaskGu, uint256 allGuGiven,
        uint256 airDropPot, uint256 airDropTracker, uint256 leekStealPot, uint256 leekStealTracker, uint256 leekStealToday, 
        uint256 pID, uint256 rID)
        withinMigrationPeriod
        onlyOwner
        public
    {
        allMaskGu_ = allMaskGu;
        allGuGiven_ = allGuGiven;
        airDropPot_ = airDropPot;
        airDropTracker_ = airDropTracker;
        leekStealPot_ = leekStealPot;
        leekStealTracker_ = leekStealTracker;
        leekStealToday_ = leekStealToday;
        pID_ = pID;
        rID_ = rID;
    }

    function migratePlayerData1(uint256 _pID, address addr, uint256 win,
        uint256 gen, uint256 genGu, uint256 aff, uint256 refund, uint256 lrnd, 
        uint256 laff, uint256 withdraw)
        withinMigrationPeriod
        onlyOwner
        public
    {
        pIDxAddr_[addr] = _pID;

        plyr_[_pID].addr = addr;
        plyr_[_pID].win = win;
        plyr_[_pID].gen = gen;
        plyr_[_pID].genGu = genGu;
        plyr_[_pID].aff = aff;
        plyr_[_pID].refund = refund;
        plyr_[_pID].lrnd = lrnd;
        plyr_[_pID].laff = laff;
        plyr_[_pID].withdraw = withdraw;
    }

    function migratePlayerData2(uint256 _pID, address addr, uint256 maskGu, 
    uint256 gu, uint256 referEth, uint256 lastClaimedPhID)
        withinMigrationPeriod
        onlyOwner
        public
    {
        pIDxAddr_[addr] = _pID;
        plyr_[_pID].addr = addr;

        plyr_[_pID].maskGu = maskGu;
        plyr_[_pID].gu = gu;
        plyr_[_pID].referEth = referEth;
        plyr_[_pID].lastClaimedPhID = lastClaimedPhID;
    }

    function migratePlayerRoundsData(uint256 _pID, uint256 eth, uint256 keys, uint256 maskKey, uint256 genWithdraw)
        withinMigrationPeriod
        onlyOwner
        public
    {
        plyrRnds_[_pID][1].eth = eth;
        plyrRnds_[_pID][1].keys = keys;
        plyrRnds_[_pID][1].maskKey = maskKey;
        plyrRnds_[_pID][1].genWithdraw = genWithdraw;
    }

    function migratePlayerPhrasesData(uint256 _pID, uint256 eth, uint256 guRewarded)
        withinMigrationPeriod
        onlyOwner
        public
    {
         
        plyrPhas_[_pID][1].eth = eth;
        plyrPhas_[_pID][1].guRewarded = guRewarded;
    }

    function migrateRoundData(uint256 plyr, uint256 end, bool ended, uint256 strt,
        uint256 allkeys, uint256 keys, uint256 eth, uint256 pot, uint256 maskKey, uint256 playCtr, uint256 withdraw)
        withinMigrationPeriod
        onlyOwner
        public
    {
        round_[1].plyr = plyr;
        round_[1].end = end;
        round_[1].ended = ended;
        round_[1].strt = strt;
        round_[1].allkeys = allkeys;
        round_[1].keys = keys;
        round_[1].eth = eth;
        round_[1].pot = pot;
        round_[1].maskKey = maskKey;
        round_[1].playCtr = playCtr;
        round_[1].withdraw = withdraw;
    }

    function migratePhraseData(uint256 eth, uint256 guGiven, uint256 mask, 
        uint256 minEthRequired, uint256 guPoolAllocation)
        withinMigrationPeriod
        onlyOwner
        public
    {
        phrase_[1].eth = eth;
        phrase_[1].guGiven = guGiven;
        phrase_[1].mask = mask;
        phrase_[1].minEthRequired = minEthRequired;
        phrase_[1].guPoolAllocation = guPoolAllocation;
    }


    function updateWhitelist(address[] _addrs, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint i = 0; i < _addrs.length; i++) {
            whitelisted_Prebuy[_addrs[i]] = _isWhitelisted;
        }
    }

     
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0)
        {
            pID_++;  
            pIDxAddr_[msg.sender] = pID_;  
            plyr_[pID_].addr = msg.sender;  
            _pID = pID_;
        } 
        
         
        buyCore(_pID, plyr_[_pID].laff);
    }
 
    function buyXid(uint256 _affID)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        uint256 _pID = pIDxAddr_[msg.sender];  
        if (_pID == 0)
        {
            pID_++;  
            pIDxAddr_[msg.sender] = pID_;  
            plyr_[pID_].addr = msg.sender;  
            _pID = pID_;
        } 
        
         
         
        if (_affID == 0 || _affID == _pID || _affID > pID_)
        {
            _affID = plyr_[_pID].laff;  

         
        } 
        else if (_affID != plyr_[_pID].laff) 
        {
            if (plyr_[_pID].laff == 0)
                plyr_[_pID].laff = _affID;  
            else 
                _affID = plyr_[_pID].laff;
        } 

         
        buyCore(_pID, _affID);
    }

    function reLoadXid()
        isActivated()
        isHuman()
        public
    {
        uint256 _pID = pIDxAddr_[msg.sender];  
        require(_pID > 0);

        reLoadCore(_pID, plyr_[_pID].laff);
    }

    function reLoadCore(uint256 _pID, uint256 _affID)
        private
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;

         
        if (_now < round_[rID_].strt + whitelistRange_) {
            require(whitelisted_Prebuy[plyr_[_pID].addr] || whitelisted_Prebuy[plyr_[_affID].addr]);
        }
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            uint256 _eth = withdrawEarnings(_pID, false);
            
            if (_eth > 0) {
                 
                core(_rID, _pID, _eth, _affID);
            }
        
         
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            endRound();
        }
    }
    
    function withdraw()
        isActivated()
        isHuman()
        public
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _eth;
        
         
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {   
             
			round_[_rID].ended = true;
            endRound();
            
			 
            _eth = withdrawEarnings(_pID, true);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
            
         
        } else {
             
            _eth = withdrawEarnings(_pID, true);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
        }
    }

    function buyCore(uint256 _pID, uint256 _affID)
        whenNotPaused_1
        private
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;

         
        if (_now < round_[rID_].strt + whitelistRange_) {
            require(whitelisted_Prebuy[plyr_[_pID].addr] || whitelisted_Prebuy[plyr_[_affID].addr]);
        }
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
             
            core(_rID, _pID, msg.value, _affID);
        
         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                 
			    round_[_rID].ended = true;
                endRound();
            }
            
             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
         
        if (plyrRnds_[_pID][_rID].keys == 0)
        {
             
             
            if (plyr_[_pID].lrnd != 0)
                updateGenVault(_pID, plyr_[_pID].lrnd);
            
            plyr_[_pID].lrnd = rID_;  
        }
        
         
        uint256 _availableLimit;
        uint256 _refund;
        if (round_[_rID].eth < ethLimiterRange1_ && plyrRnds_[_pID][_rID].eth.add(_eth) > ethLimiter1_)
        {
            _availableLimit = (ethLimiter1_).sub(plyrRnds_[_pID][_rID].eth);
            _refund = _eth.sub(_availableLimit);
            plyr_[_pID].refund = plyr_[_pID].refund.add(_refund);
            _eth = _availableLimit;
        } else if (round_[_rID].eth < ethLimiterRange2_ && plyrRnds_[_pID][_rID].eth.add(_eth) > ethLimiter2_)
        {
            _availableLimit = (ethLimiter2_).sub(plyrRnds_[_pID][_rID].eth);
            _refund = _eth.sub(_availableLimit);
            plyr_[_pID].refund = plyr_[_pID].refund.add(_refund);
            _eth = _availableLimit;
        }
        
         
        if (_eth > 1e9) 
        {
             
            uint256 _keys = keysRec(round_[_rID].eth, _eth);
            
             
            if (_keys >= 1e18)
            {
                updateTimer(_keys, _rID);

                 
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;

                emit KeyPurchase(plyr_[round_[_rID].plyr].addr, _eth, _keys);
            }
            
             
            if (_eth >= 1e17)
            {
                airDropTracker_++;
                if (airdrop() == true)
                {
                     
                    uint256 _prize;
                    if (_eth >= 1e19)
                    {
                         
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                         
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                         
                    } else if (_eth >= 1e18 && _eth < 1e19) {
                         
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                         
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                         
                    } else if (_eth >= 1e17 && _eth < 1e18) {
                         
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        
                         
                        airDropPot_ = (airDropPot_).sub(_prize);
                        
                         
                    }

                     
                    airDropTracker_ = 0;

                     
                    airDropCount_++;
                    airDropWinners_[airDropCount_][_pID] = _prize;
                }
            }   
            
            leekStealGo();

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            round_[_rID].playCtr++;
            playOrders_[round_[_rID].playCtr] = pID_;  
            
             
            round_[_rID].allkeys = _keys.add(round_[_rID].allkeys);
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
    
             
            distributeExternal(_rID, _pID, _eth, _affID);
            distributeInternal(_rID, _pID, _eth, _keys);

             
            updateGuReferral(_pID, _affID, _eth);

            checkDoubledProfit(_pID, _rID);
            checkDoubledProfit(_affID, _rID);
        }
    }

     
    function checkDoubledProfit(uint256 _pID, uint256 _rID)
        private
    {   
         
        uint256 _keys = plyrRnds_[_pID][_rID].keys;
        if (_keys > 0) {

            uint256 _genVault = plyr_[_pID].gen;
            uint256 _genWithdraw = plyrRnds_[_pID][_rID].genWithdraw;
            uint256 _genEarning = calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd);
            uint256 _doubleProfit = (plyrRnds_[_pID][_rID].eth).mul(2);
            if (_genVault.add(_genWithdraw).add(_genEarning) >= _doubleProfit)
            {
                 
                uint256 _remainProfit = _doubleProfit.sub(_genVault).sub(_genWithdraw);
                plyr_[_pID].gen = _remainProfit.add(plyr_[_pID].gen); 
                plyrRnds_[_pID][_rID].keyProfit = _remainProfit.add(plyrRnds_[_pID][_rID].keyProfit);  

                round_[_rID].keys = round_[_rID].keys.sub(_keys);
                plyrRnds_[_pID][_rID].keys = plyrRnds_[_pID][_rID].keys.sub(_keys);

                plyrRnds_[_pID][_rID].maskKey = 0;  
            }   
        }
    }

    function keysRec(uint256 _curEth, uint256 _newEth)
        private
        returns (uint256)
    {
        uint256 _startEth;
        uint256 _incrRate;
        uint256 _initPrice;

        if (_curEth < priceStage1_) {
            _startEth = 0;
            _initPrice = 33333;  
            _incrRate = 50000000;  
        }
        else if (_curEth < priceStage2_) {
            _startEth = priceStage1_;
            _initPrice =  25000;  
            _incrRate = 50000000;  
        }
        else if (_curEth < priceStage3_) {
            _startEth = priceStage2_;
            _initPrice = 20000;  
            _incrRate = 50000000;  
        }
        else if (_curEth < priceStage4_) {
            _startEth = priceStage3_;
            _initPrice = 12500;  
            _incrRate = 26666666;  
        }
        else if (_curEth < priceStage5_) {
            _startEth = priceStage4_;
            _initPrice = 5000;  
            _incrRate = 17777777;  
        }
        else if (_curEth < priceStage6_) {
            _startEth = priceStage5_;
            _initPrice = 2500;  
            _incrRate = 10666666;  
        }
        else if (_curEth < priceStage7_) {
            _startEth = priceStage6_;
            _initPrice = 1000;  
            _incrRate = 5688282;  
        }
        else if (_curEth < priceStage8_) {
            _startEth = priceStage7_;
            _initPrice = 250;  
            _incrRate = 2709292;  
        }
        else if (_curEth < priceStage9_) {
            _startEth = priceStage8_;
            _initPrice = 62;  
            _incrRate = 1161035;  
        }
        else if (_curEth < priceStage10_) {
            _startEth = priceStage9_;
            _initPrice = 14;  
            _incrRate = 451467;  
        }
        else if (_curEth < priceStage11_) {
            _startEth = priceStage10_;
            _initPrice = 2;  
            _incrRate = 144487;  
        }
        else if (_curEth < priceStage12_) {
            _startEth = priceStage11_;
            _initPrice = 0;  
            _incrRate = 40128;  
        }
        else {
            _startEth = priceStage12_;
            _initPrice = 0;
            _incrRate = 40128;  
        }

        return _newEth.mul(((_incrRate.mul(_initPrice)) / (_incrRate.add(_initPrice.mul((_curEth.sub(_startEth))/1e18)))));
    }

    function updateGuReferral(uint256 _pID, uint256 _affID, uint256 _eth) private {
        uint256 _newPhID = updateGuPhrase();

         
        if (phID_ < _newPhID) {
            updateReferralMasks(phID_);
            plyr_[1].gu = (phrase_[_newPhID].guPoolAllocation / 10).add(plyr_[1].gu);  
            plyr_[2].gu = (phrase_[_newPhID].guPoolAllocation / 10).add(plyr_[2].gu);  
            phrase_[_newPhID].guGiven = (phrase_[_newPhID].guPoolAllocation / 5).add(phrase_[_newPhID].guGiven);
            allGuGiven_ = (phrase_[_newPhID].guPoolAllocation / 5).add(allGuGiven_);
            phID_ = _newPhID;  
        }

         
        if (_affID != 0 && _affID != _pID) {
            plyrPhas_[_affID][_newPhID].eth = _eth.add(plyrPhas_[_affID][_newPhID].eth);
            plyr_[_affID].referEth = _eth.add(plyr_[_affID].referEth);
            phrase_[_newPhID].eth = _eth.add(phrase_[_newPhID].eth);
        }
            
        uint256 _remainGuReward = phrase_[_newPhID].guPoolAllocation.sub(phrase_[_newPhID].guGiven);
         
        if (plyrPhas_[_affID][_newPhID].eth >= phrase_[_newPhID].minEthRequired && _remainGuReward >= 1e18) {
             
            uint256 _totalReward = plyrPhas_[_affID][_newPhID].eth / phrase_[_newPhID].minEthRequired;
            _totalReward = _totalReward.mul(1e18);
            uint256 _rewarded = plyrPhas_[_affID][_newPhID].guRewarded;
            uint256 _toReward = _totalReward.sub(_rewarded);
            if (_remainGuReward < _toReward) _toReward =  _remainGuReward;

             
            if (_toReward > 0) {
                plyr_[_affID].gu = _toReward.add(plyr_[_affID].gu);  
                plyrPhas_[_affID][_newPhID].guRewarded = _toReward.add(plyrPhas_[_affID][_newPhID].guRewarded);
                phrase_[_newPhID].guGiven = 1e18.add(phrase_[_newPhID].guGiven);
                allGuGiven_ = 1e18.add(allGuGiven_);
            }
        }
    }

    function updateReferralMasks(uint256 _phID) private {
        uint256 _remainGu = phrase_[phID_].guPoolAllocation.sub(phrase_[phID_].guGiven);
        if (_remainGu > 0 && phrase_[_phID].eth > 0) {
             
            uint256 _gpe = (_remainGu.mul(1e18)) / phrase_[_phID].eth;
            phrase_[_phID].mask = _gpe.add(phrase_[_phID].mask);  
        }
    }

    function transferGu(address _to, uint256 _guAmt) 
        public
        whenNotPaused_2
        returns (bool) 
    {
       require(_to != address(0));

        if (_guAmt > 0) {
            uint256 _pIDFrom = pIDxAddr_[msg.sender];
            uint256 _pIDTo = pIDxAddr_[_to];

            require(plyr_[_pIDFrom].addr == msg.sender);
            require(plyr_[_pIDTo].addr == _to);

             
            uint256 _profit = (allMaskGu_.mul(_guAmt)/1e18).sub(  (plyr_[_pIDFrom].maskGu.mul(_guAmt) / plyr_[_pIDFrom].gu)   ); 
            plyr_[_pIDFrom].genGu = _profit.add(plyr_[_pIDFrom].genGu);  
            plyr_[_pIDFrom].guProfit = _profit.add(plyr_[_pIDFrom].guProfit);

             
            plyr_[_pIDFrom].maskGu = plyr_[_pIDFrom].maskGu.sub(  (allMaskGu_.mul(_guAmt)/1e18).sub(_profit)  );

             
            plyr_[_pIDTo].maskGu = (allMaskGu_.mul(_guAmt)/1e18).add(plyr_[_pIDTo].maskGu);

            plyr_[_pIDFrom].gu = plyr_[_pIDFrom].gu.sub(_guAmt);
            plyr_[_pIDTo].gu = plyr_[_pIDTo].gu.add(_guAmt);

            return true;
        } 
        else
            return false;
    }
    
    function updateGuPhrase() 
        private
        returns (uint256)  
    {
        if (now <= contractStartDate_ + guPhrase1_) {
            phrase_[1].minEthRequired = 5e18;
            phrase_[1].guPoolAllocation = 100e18;
            return 1; 
        }
        if (now <= contractStartDate_ + guPhrase2_) {
            phrase_[2].minEthRequired = 4e18;
            phrase_[2].guPoolAllocation = 200e18;
            return 2; 
        }
        if (now <= contractStartDate_ + guPhrase3_) {
            phrase_[3].minEthRequired = 3e18;
            phrase_[3].guPoolAllocation = 400e18;
            return 3; 
        }
        if (now <= contractStartDate_ + guPhrase4_) {
            phrase_[4].minEthRequired = 2e18;
            phrase_[4].guPoolAllocation = 800e18;
            return 4; 
        }
        if (now <= contractStartDate_ + guPhrase5_) {
            phrase_[5].minEthRequired = 1e18;
            phrase_[5].guPoolAllocation = 1600e18;
            return 5; 
        }
        if (now <= contractStartDate_ + guPhrase6_) {
            phrase_[6].minEthRequired = 1e18;
            phrase_[6].guPoolAllocation = 3200e18;
            return 6; 
        }
        if (now <= contractStartDate_ + guPhrase7_) {
            phrase_[7].minEthRequired = 1e18;
            phrase_[7].guPoolAllocation = 6400e18;
            return 7; 
        }
        if (now <= contractStartDate_ + guPhrase8_) {
            phrase_[8].minEthRequired = 1e18;
            phrase_[8].guPoolAllocation = 12800e18;
            return 8; 
        }
        if (now <= contractStartDate_ + guPhrase9_) {
            phrase_[9].minEthRequired = 1e18;
            phrase_[9].guPoolAllocation = 25600e18;
            return 9; 
        }
        if (now <= contractStartDate_ + guPhrase10_) {
            phrase_[10].minEthRequired = 1e18;
            phrase_[10].guPoolAllocation = 51200e18;
            return 10; 
        }
        phrase_[11].minEthRequired = 0;
        phrase_[11].guPoolAllocation = 0;
        return 11;
    }

    function calcUnMaskedKeyEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        if (    (((round_[_rIDlast].maskKey).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1e18))  >    (plyrRnds_[_pID][_rIDlast].maskKey)       )
            return(  (((round_[_rIDlast].maskKey).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1e18)).sub(plyrRnds_[_pID][_rIDlast].maskKey)  );
        else
            return 0;
    }

    function calcUnMaskedGuEarnings(uint256 _pID)
        private
        view
        returns(uint256)
    {
        if (    ((allMaskGu_.mul(plyr_[_pID].gu)) / (1e18))  >    (plyr_[_pID].maskGu)      )
            return(  ((allMaskGu_.mul(plyr_[_pID].gu)) / (1e18)).sub(plyr_[_pID].maskGu)   );
        else
            return 0;
    }
    
    function endRound()
        private
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _winPID = round_[_rID].plyr;
        
         
        uint256 _pot = round_[_rID].pot;
        
         
         
        uint256 _win = (_pot.mul(40)) / 100;
        uint256 _res = (_pot.mul(10)) / 100;

        
         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

         
        pay500Winners(_pot);
        
         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;
    }

    function pay500Winners(uint256 _pot) private {
        uint256 _rID = rID_;
        uint256 _plyCtr = round_[_rID].playCtr;

         
        uint256 _win2 = _pot.mul(25).div(100).div(9);
        for (uint256 i = _plyCtr.sub(9); i <= _plyCtr.sub(1); i++) {
            plyr_[playOrders_[i]].win = _win2.add(plyr_[playOrders_[i]].win);
        }

         
        uint256 _win3 = _pot.mul(15).div(100).div(90);
        for (uint256 j = _plyCtr.sub(99); j <= _plyCtr.sub(10); j++) {
            plyr_[playOrders_[j]].win = _win3.add(plyr_[playOrders_[j]].win);
        }

         
        uint256 _win4 = _pot.mul(10).div(100).div(400);
        for (uint256 k = _plyCtr.sub(499); k <= _plyCtr.sub(100); k++) {
            plyr_[playOrders_[k]].win = _win4.add(plyr_[playOrders_[k]].win);
        }
    }
    
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedKeyEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds_[_pID][_rIDlast].maskKey = _earnings.add(plyrRnds_[_pID][_rIDlast].maskKey);
            plyrRnds_[_pID][_rIDlast].keyProfit = _earnings.add(plyrRnds_[_pID][_rIDlast].keyProfit);  
        }
    }

    function updateGenGuVault(uint256 _pID)
        private 
    {
        uint256 _earnings = calcUnMaskedGuEarnings(_pID);
        if (_earnings > 0)
        {
             
            plyr_[_pID].genGu = _earnings.add(plyr_[_pID].genGu);
             
            plyr_[_pID].maskGu = _earnings.add(plyr_[_pID].maskGu);
            plyr_[_pID].guProfit = _earnings.add(plyr_[_pID].guProfit);
        }
    }

     
    function updateReferralGu(uint256 _pID)
        private 
    {
         
        uint256 _phID = phID_;

         
        uint256 _lastClaimedPhID = plyr_[_pID].lastClaimedPhID;

        if (_phID > _lastClaimedPhID)
        {
             
            uint256 _guShares;
            for (uint i = (_lastClaimedPhID + 1); i < _phID; i++) {
                _guShares = (((phrase_[i].mask).mul(plyrPhas_[_pID][i].eth))/1e18).add(_guShares);
            
                 
                plyr_[_pID].lastClaimedPhID = i;
                phrase_[i].guGiven = _guShares.add(phrase_[i].guGiven);
                plyrPhas_[_pID][i].guRewarded = _guShares.add(plyrPhas_[_pID][i].guRewarded);
            }

             
            plyr_[_pID].gu = _guShares.add(plyr_[_pID].gu);

             
            plyr_[_pID].maskGu = ((allMaskGu_.mul(_guShares)) / 1e18).add(plyr_[_pID].maskGu);

            allGuGiven_ = _guShares.add(allGuGiven_);
        }
    }
    
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
         
        uint256 _now = now;
        
         
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }
    
    function airdrop()
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }

    function randomNum(uint256 _tracker)
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < _tracker)
            return(true);
        else
            return(false);
    }

    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
         
        uint256 _com = _eth / 100;
        address(WALLET_ETH_COM1).transfer(_com);  
        address(WALLET_ETH_COM2).transfer(_com);  
        
         
        uint256 _aff = _eth / 10;
        
         
        if (_affID != _pID && _affID != 0) {
            plyr_[_affID].aff = (_aff.mul(8)/10).add(plyr_[_affID].aff);  

            uint256 _affID2 =  plyr_[_affID].laff;  
            if (_affID2 != _pID && _affID2 != 0) {
                plyr_[_affID2].aff = (_aff.mul(2)/10).add(plyr_[_affID2].aff);  
            }
        } else {
            plyr_[1].aff = _aff.add(plyr_[_affID].aff);
        }
    }
    
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys)
        private
    {
         
        uint256 _gen = (_eth.mul(40)) / 100;  

         
        uint256 _jcg = (_eth.mul(20)) / 100;  
        
         
        uint256 _air = (_eth.mul(3)) / 100;
        airDropPot_ = airDropPot_.add(_air);

         
        uint256 _steal = (_eth / 20);
        leekStealPot_ = leekStealPot_.add(_steal);
        
         
        _eth = _eth.sub(((_eth.mul(20)) / 100)); 
        
         
        uint256 _pot = _eth.sub(_gen).sub(_jcg);
        
         
         
        uint256 _dustKey = updateKeyMasks(_rID, _pID, _gen, _keys);
        uint256 _dustGu = updateGuMasks(_pID, _jcg);
        
         
        round_[_rID].pot = _pot.add(_dustKey).add(_dustGu).add(round_[_rID].pot);
    }

     
    function updateKeyMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         
        uint256 _ppt = (_gen.mul(1e18)) / (round_[_rID].keys);
        round_[_rID].maskKey = _ppt.add(round_[_rID].maskKey);
            
         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1e18);
        plyrRnds_[_pID][_rID].maskKey = (((round_[_rID].maskKey.mul(_keys)) / (1e18)).sub(_pearn)).add(plyrRnds_[_pID][_rID].maskKey);
        
         
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1e18)));
    }

     
    function updateGuMasks(uint256 _pID, uint256 _jcg)
        private
        returns(uint256)
    {   
        if (allGuGiven_ > 0) {
             
            uint256 _ppg = (_jcg.mul(1e18)) / allGuGiven_;
            allMaskGu_ = _ppg.add(allMaskGu_);
            
             
            return (_jcg.sub((_ppg.mul(allGuGiven_)) / (1e18)));
        } else {
            return _jcg;
        }
    }
    
    function withdrawEarnings(uint256 _pID, bool isWithdraw)
        whenNotPaused_3
        private
        returns(uint256)
    {
        uint256 _rID = plyr_[_pID].lrnd;

        updateGenGuVault(_pID);

        updateReferralGu(_pID);

        checkDoubledProfit(_pID, _rID);
        updateGenVault(_pID, _rID);
        

         
        uint256 _earnings = plyr_[_pID].gen.add(plyr_[_pID].win).add(plyr_[_pID].genGu).add(plyr_[_pID].aff).add(plyr_[_pID].refund);
        if (_earnings > 0)
        {
            if (isWithdraw) {
                plyrRnds_[_pID][_rID].winWithdraw = plyr_[_pID].win.add(plyrRnds_[_pID][_rID].winWithdraw);
                plyrRnds_[_pID][_rID].genWithdraw = plyr_[_pID].gen.add(plyrRnds_[_pID][_rID].genWithdraw);  
                plyrRnds_[_pID][_rID].genGuWithdraw = plyr_[_pID].genGu.add(plyrRnds_[_pID][_rID].genGuWithdraw);
                plyrRnds_[_pID][_rID].affWithdraw = plyr_[_pID].aff.add(plyrRnds_[_pID][_rID].affWithdraw);
                plyrRnds_[_pID][_rID].refundWithdraw = plyr_[_pID].refund.add(plyrRnds_[_pID][_rID].refundWithdraw);
                plyr_[_pID].withdraw = _earnings.add(plyr_[_pID].withdraw);
                round_[_rID].withdraw = _earnings.add(round_[_rID].withdraw);
            }

            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].genGu = 0;
            plyr_[_pID].aff = 0;
            plyr_[_pID].refund = 0;
        }

        return(_earnings);
    }

    bool public activated_ = false;
    function activate()
        onlyOwner
        public
    {
         
        require(activated_ == false);
        
         
        activated_ = true;
        contractStartDate_ = now;
        
         
        rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_;
    }

    function leekStealGo() 
        private 
    {
         
        uint leekStealToday_ = (now.sub(round_[rID_].strt)) / 1 days; 
        if (dayStealTime_[leekStealToday_] == 0)  
        {
            leekStealTracker_++;
            if (randomNum(leekStealTracker_) == true)
            {
                dayStealTime_[leekStealToday_] = now;
                leekStealOn_ = true;
            }
        }
    }

    function stealTheLeek() 
        whenNotPaused_4
        public 
    {
        if (leekStealOn_)
        {   
            if (now.sub(dayStealTime_[leekStealToday_]) > 300)  
            {
                leekStealOn_ = false;
            } else {   
                 
                if (leekStealPot_ > 1e18) {
                    uint256 _pID = pIDxAddr_[msg.sender];  
                    plyr_[_pID].win = plyr_[_pID].win.add(1e18);
                    leekStealPot_ = leekStealPot_.sub(1e18);
                    leekStealWins_[_pID] = leekStealWins_[_pID].add(1e18);
                }
            }
        }
    }

 
    
    function getPrice()
        public
        view
        returns(uint256)
    {   
        uint256 keys = keysRec(round_[rID_].eth, 1e18);
        return (1e36 / keys);
    }
    
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt).sub(_now) );
        else
            return(0);
    }
    
    function getDisplayGenVault(uint256 _pID)
        private
        view
        returns(uint256)
    {
        uint256 _rID = rID_;
        uint256 _lrnd = plyr_[_pID].lrnd;

        uint256 _genVault = plyr_[_pID].gen;
        uint256 _genEarning = calcUnMaskedKeyEarnings(_pID, _lrnd);
        uint256 _doubleProfit = (plyrRnds_[_pID][_rID].eth).mul(2);
        
        uint256 _displayGenVault = _genVault.add(_genEarning);
        if (_genVault.add(_genEarning) > _doubleProfit)
            _displayGenVault = _doubleProfit;

        return _displayGenVault;
    }

    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256, uint256, uint256)
    {
        uint256 _rID = rID_;
        
         
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {   
            uint256 _winVault;
            if (round_[_rID].plyr == _pID)  
            {   
                _winVault = (plyr_[_pID].win).add( ((round_[_rID].pot).mul(40)) / 100 );
            } else {
                _winVault = plyr_[_pID].win;
            }

            return
            (
                _winVault,
                getDisplayGenVault(_pID),
                (plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID)),
                plyr_[_pID].aff,
                plyr_[_pID].refund
            );
         
        } else {
            return
            (
                plyr_[_pID].win,
                getDisplayGenVault(_pID),
                (plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID)),
                plyr_[_pID].aff,
                plyr_[_pID].refund
            );
        }
    }
    
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        
        return
        (
            _rID,                            
            round_[_rID].allkeys,            
            round_[_rID].keys,               
            allGuGiven_,                     
            round_[_rID].end,                
            round_[_rID].strt,               
            round_[_rID].pot,                
            plyr_[round_[_rID].plyr].addr,   
            round_[_rID].eth,                
            airDropTracker_ + (airDropPot_ * 1000)    
        );
    }

    function getCurrentPhraseInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _phID = phID_;
        
        return
        (
            _phID,                             
            phrase_[_phID].eth,                
            phrase_[_phID].guGiven,            
            phrase_[_phID].minEthRequired,     
            phrase_[_phID].guPoolAllocation    
        );
    }

    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _phID = phID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,       
            plyrRnds_[_pID][_rID].keys,          
            plyr_[_pID].gu,                      
            plyr_[_pID].laff,                     
            (plyr_[_pID].gen).add(calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd)).add(plyr_[_pID].genGu).add(calcUnMaskedGuEarnings(_pID)),  
            plyr_[_pID].aff,                     
            plyrRnds_[_pID][_rID].eth,            
            plyrPhas_[_pID][_phID].eth,           
            plyr_[_pID].referEth,                
            plyr_[_pID].withdraw                 
        );
    }

    function getPlayerWithdrawal(uint256 _pID, uint256 _rID)
        public 
        view 
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        return
        (
            plyrRnds_[_pID][_rID].winWithdraw,      
            plyrRnds_[_pID][_rID].genWithdraw,      
            plyrRnds_[_pID][_rID].genGuWithdraw,    
            plyrRnds_[_pID][_rID].affWithdraw,      
            plyrRnds_[_pID][_rID].refundWithdraw    
        );
    }

}

library Datasets {
    struct Player {
        address addr;    
        uint256 win;     
        uint256 gen;     
        uint256 genGu;   
        uint256 aff;     
        uint256 refund;   
        uint256 lrnd;    
        uint256 laff;    
        uint256 withdraw;  
        uint256 maskGu;  
        uint256 gu;     
        uint256 guProfit;  
        uint256 referEth;  
        uint256 lastClaimedPhID;  
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 keyProfit;  
        uint256 maskKey;    
        uint256 winWithdraw;   
        uint256 genWithdraw;   
        uint256 genGuWithdraw;   
        uint256 affWithdraw;   
        uint256 refundWithdraw;   
    }
    struct Round {
        uint256 plyr;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 allkeys;  
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 maskKey;    
        uint256 playCtr;    
        uint256 withdraw;
    }
    struct PlayerPhrases {
        uint256 eth;    
        uint256 guRewarded;   
    }
    struct Phrase {
        uint256 eth;    
        uint256 guGiven;  
        uint256 mask;   
        uint256 minEthRequired;   
        uint256 guPoolAllocation;  
    }
}

library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}