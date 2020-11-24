 

pragma solidity ^0.4.25;

contract IStdToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
}

contract EtheramaCommon {
    
     
    mapping(address => bool) private _administrators;

     
    mapping(address => bool) private _managers;

    
    modifier onlyAdministrator() {
        require(_administrators[msg.sender]);
        _;
    }

    modifier onlyAdministratorOrManager() {
        require(_administrators[msg.sender] || _managers[msg.sender]);
        _;
    }
    
    constructor() public {
        _administrators[msg.sender] = true;
    }
    
    
    function addAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = true;
    }

    function removeAdministator(address addr) onlyAdministrator public {
        _administrators[addr] = false;
    }

    function isAdministrator(address addr) public view returns (bool) {
        return _administrators[addr];
    }

    function addManager(address addr) onlyAdministrator public {
        _managers[addr] = true;
    }

    function removeManager(address addr) onlyAdministrator public {
        _managers[addr] = false;
    }
    
    function isManager(address addr) public view returns (bool) {
        return _managers[addr];
    }
}


contract EtheramaGasPriceLimit is EtheramaCommon {
    
    uint256 public MAX_GAS_PRICE = 0 wei;
    
    event onSetMaxGasPrice(uint256 val);    
    
     
     
    modifier validGasPrice(uint256 val) {
        require(val > 0);
        _;
    }
    
    constructor(uint256 maxGasPrice) public validGasPrice(maxGasPrice) {
        setMaxGasPrice(maxGasPrice);
    } 
    
    
     
    function setMaxGasPrice(uint256 val) public validGasPrice(val) onlyAdministratorOrManager {
        MAX_GAS_PRICE = val;
        
        emit onSetMaxGasPrice(val);
    }
}

 
contract EtheramaCore is EtheramaGasPriceLimit {
    
    uint256 constant public MAGNITUDE = 2**64;

     
    uint256 constant public MIN_TOKEN_DEAL_VAL = 0.1 ether;
    uint256 constant public MAX_TOKEN_DEAL_VAL = 1000000 ether;

     
    uint256 constant public MIN_ETH_DEAL_VAL = 0.001 ether;
    uint256 constant public MAX_ETH_DEAL_VAL = 200000 ether;
    
     
    uint256 public _bigPromoPercent = 5 ether;

     
    uint256 public _quickPromoPercent = 5 ether;

     
    uint256 public _devRewardPercent = 15 ether;
    
     
    uint256 public _tokenOwnerRewardPercent = 30 ether;

     
    uint256 public _shareRewardPercent = 25 ether;

     
    uint256 public _refBonusPercent = 20 ether;

     
    uint128 public _bigPromoBlockInterval = 9999;

     
    uint128 public _quickPromoBlockInterval = 100;
    
     
    uint256 public _promoMinPurchaseEth = 1 ether;
    
     
    uint256 public _minRefEthPurchase = 0.5 ether;

     
    uint256 public _totalIncomeFeePercent = 100 ether;

     
    uint256 public _currentBigPromoBonus;
     
    uint256 public _currentQuickPromoBonus;
    
    uint256 public _devReward;

    
    uint256 public _initBlockNum;

    mapping(address => bool) private _controllerContracts;
    mapping(uint256 => address) private _controllerIndexer;
    uint256 private _controllerContractCount;
    
     
    mapping(address => mapping(address => uint256)) private _userTokenLocalBalances;
     
    mapping(address => mapping(address => uint256)) private _rewardPayouts;
     
    mapping(address => mapping(address => uint256)) private _refBalances;
     
    mapping(address => mapping(address => uint256)) private _promoQuickBonuses;
     
    mapping(address => mapping(address => uint256)) private _promoBigBonuses;  
     
    mapping(address => mapping(address => uint256)) private _userEthVolumeSaldos;  

     
    mapping(address => uint256) private _bonusesPerShare;
     
    mapping(address => uint256) private _buyCounts;
     
    mapping(address => uint256) private _sellCounts;
     
    mapping(address => uint256) private _totalVolumeEth;
     
    mapping(address => uint256) private _totalVolumeToken;

    
    event onWithdrawUserBonus(address indexed userAddress, uint256 ethWithdrawn); 


    modifier onlyController() {
        require(_controllerContracts[msg.sender]);
        _;
    }
    
    constructor(uint256 maxGasPrice) EtheramaGasPriceLimit(maxGasPrice) public { 
         _initBlockNum = block.number;
    }
    
    function getInitBlockNum() public view returns (uint256) {
        return _initBlockNum;
    }
    
    function addControllerContract(address addr) onlyAdministrator public {
        _controllerContracts[addr] = true;
        _controllerIndexer[_controllerContractCount] = addr;
        _controllerContractCount = SafeMath.add(_controllerContractCount, 1);
    }

    function removeControllerContract(address addr) onlyAdministrator public {
        _controllerContracts[addr] = false;
    }
    
    function changeControllerContract(address oldAddr, address newAddress) onlyAdministrator public {
         _controllerContracts[oldAddr] = false;
         _controllerContracts[newAddress] = true;
    }
    
    function setBigPromoInterval(uint128 val) onlyAdministrator public {
        _bigPromoBlockInterval = val;
    }

    function setQuickPromoInterval(uint128 val) onlyAdministrator public {
        _quickPromoBlockInterval = val;
    }
    
    function addBigPromoBonus() onlyController payable public {
        _currentBigPromoBonus = SafeMath.add(_currentBigPromoBonus, msg.value);
    }
    
    function addQuickPromoBonus() onlyController payable public {
        _currentQuickPromoBonus = SafeMath.add(_currentQuickPromoBonus, msg.value);
    }
    
    
    function setPromoMinPurchaseEth(uint256 val) onlyAdministrator public {
        _promoMinPurchaseEth = val;
    }
    
    function setMinRefEthPurchase(uint256 val) onlyAdministrator public {
        _minRefEthPurchase = val;
    }
    
    function setTotalIncomeFeePercent(uint256 val) onlyController public {
        require(val > 0 && val <= 100 ether);

        _totalIncomeFeePercent = val;
    }
        
    
     
    function setRewardPercentages(uint256 tokenOwnerRewardPercent, uint256 shareRewardPercent, uint256 refBonusPercent, uint256 bigPromoPercent, uint256 quickPromoPercent) onlyAdministrator public {
        require(tokenOwnerRewardPercent <= 40 ether);
        require(shareRewardPercent <= 100 ether);
        require(refBonusPercent <= 100 ether);
        require(bigPromoPercent <= 100 ether);
        require(quickPromoPercent <= 100 ether);

        require(tokenOwnerRewardPercent + shareRewardPercent + refBonusPercent + _devRewardPercent + _bigPromoPercent + _quickPromoPercent == 100 ether);

        _tokenOwnerRewardPercent = tokenOwnerRewardPercent;
        _shareRewardPercent = shareRewardPercent;
        _refBonusPercent = refBonusPercent;
        _bigPromoPercent = bigPromoPercent;
        _quickPromoPercent = quickPromoPercent;
    }    
    
    
    function payoutQuickBonus(address userAddress) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _promoQuickBonuses[dataContractAddress][userAddress] = SafeMath.add(_promoQuickBonuses[dataContractAddress][userAddress], _currentQuickPromoBonus);
        _currentQuickPromoBonus = 0;
    }
    
    function payoutBigBonus(address userAddress) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _promoBigBonuses[dataContractAddress][userAddress] = SafeMath.add(_promoBigBonuses[dataContractAddress][userAddress], _currentBigPromoBonus);
        _currentBigPromoBonus = 0;
    }

    function addDevReward() onlyController payable public {
        _devReward = SafeMath.add(_devReward, msg.value);
    }    
    
    function withdrawDevReward() onlyAdministrator public {
        uint256 reward = _devReward;
        _devReward = 0;

        msg.sender.transfer(reward);
    }
    
    function getBlockNumSinceInit() public view returns(uint256) {
        return block.number - getInitBlockNum();
    }

    function getQuickPromoRemainingBlocks() public view returns(uint256) {
        uint256 d = getBlockNumSinceInit() % _quickPromoBlockInterval;
        d = d == 0 ? _quickPromoBlockInterval : d;

        return _quickPromoBlockInterval - d;
    }

    function getBigPromoRemainingBlocks() public view returns(uint256) {
        uint256 d = getBlockNumSinceInit() % _bigPromoBlockInterval;
        d = d == 0 ? _bigPromoBlockInterval : d;

        return _bigPromoBlockInterval - d;
    } 
    
    
    function getBonusPerShare(address dataContractAddress) public view returns(uint256) {
        return _bonusesPerShare[dataContractAddress];
    }
    
    function getTotalBonusPerShare() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _bonusesPerShare[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }          
    }
    
    
    function addBonusPerShare() onlyController payable public {
        EtheramaData data = Etherama(msg.sender)._data();
        uint256 shareBonus = (msg.value * MAGNITUDE) / data.getTotalTokenSold();
        
        _bonusesPerShare[address(data)] = SafeMath.add(_bonusesPerShare[address(data)], shareBonus);
    }        
 
    function getUserRefBalance(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _refBalances[dataContractAddress][userAddress];
    }
    
    function getUserRewardPayouts(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _rewardPayouts[dataContractAddress][userAddress];
    }    

    function resetUserRefBalance(address userAddress) onlyController public {
        resetUserRefBalance(Etherama(msg.sender).getDataContractAddress(), userAddress);
    }
    
    function resetUserRefBalance(address dataContractAddress, address userAddress) internal {
        _refBalances[dataContractAddress][userAddress] = 0;
    }
    
    function addUserRefBalance(address userAddress) onlyController payable public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _refBalances[dataContractAddress][userAddress] = SafeMath.add(_refBalances[dataContractAddress][userAddress], msg.value);
    }

    function addUserRewardPayouts(address userAddress, uint256 val) onlyController public {
        addUserRewardPayouts(Etherama(msg.sender).getDataContractAddress(), userAddress, val);
    }    

    function addUserRewardPayouts(address dataContractAddress, address userAddress, uint256 val) internal {
        _rewardPayouts[dataContractAddress][userAddress] = SafeMath.add(_rewardPayouts[dataContractAddress][userAddress], val);
    }

    function resetUserPromoBonus(address userAddress) onlyController public {
        resetUserPromoBonus(Etherama(msg.sender).getDataContractAddress(), userAddress);
    }
    
    function resetUserPromoBonus(address dataContractAddress, address userAddress) internal {
        _promoQuickBonuses[dataContractAddress][userAddress] = 0;
        _promoBigBonuses[dataContractAddress][userAddress] = 0;
    }
    
    
    function trackBuy(address userAddress, uint256 volEth, uint256 volToken) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _buyCounts[dataContractAddress] = SafeMath.add(_buyCounts[dataContractAddress], 1);
        _userEthVolumeSaldos[dataContractAddress][userAddress] = SafeMath.add(_userEthVolumeSaldos[dataContractAddress][userAddress], volEth);
        
        trackTotalVolume(dataContractAddress, volEth, volToken);
    }

    function trackSell(address userAddress, uint256 volEth, uint256 volToken) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _sellCounts[dataContractAddress] = SafeMath.add(_sellCounts[dataContractAddress], 1);
        _userEthVolumeSaldos[dataContractAddress][userAddress] = SafeMath.sub(_userEthVolumeSaldos[dataContractAddress][userAddress], volEth);
        
        trackTotalVolume(dataContractAddress, volEth, volToken);
    }
    
    function trackTotalVolume(address dataContractAddress, uint256 volEth, uint256 volToken) internal {
        _totalVolumeEth[dataContractAddress] = SafeMath.add(_totalVolumeEth[dataContractAddress], volEth);
        _totalVolumeToken[dataContractAddress] = SafeMath.add(_totalVolumeToken[dataContractAddress], volToken);
    }
    
    function getBuyCount(address dataContractAddress) public view returns (uint256) {
        return _buyCounts[dataContractAddress];
    }
    
    function getTotalBuyCount() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _buyCounts[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }         
    }
    
    function getSellCount(address dataContractAddress) public view returns (uint256) {
        return _sellCounts[dataContractAddress];
    }
    
    function getTotalSellCount() public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _sellCounts[Etherama(_controllerIndexer[i]).getDataContractAddress()]);
        }         
    }

    function getTotalVolumeEth(address dataContractAddress) public view returns (uint256) {
        return _totalVolumeEth[dataContractAddress];
    }
    
    function getTotalVolumeToken(address dataContractAddress) public view returns (uint256) {
        return _totalVolumeToken[dataContractAddress];
    }

    function getUserEthVolumeSaldo(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _userEthVolumeSaldos[dataContractAddress][userAddress];
    }
    
    function getUserTotalEthVolumeSaldo(address userAddress) public view returns (uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            res = SafeMath.add(res, _userEthVolumeSaldos[Etherama(_controllerIndexer[i]).getDataContractAddress()][userAddress]);
        } 
    }
    
    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return SafeMath.add(_currentBigPromoBonus, _currentQuickPromoBonus);
    }

    function getUserTotalPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return SafeMath.add(_promoQuickBonuses[dataContractAddress][userAddress], _promoBigBonuses[dataContractAddress][userAddress]);
    }
    
    function getUserQuickPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _promoQuickBonuses[dataContractAddress][userAddress];
    }
    
    function getUserBigPromoBonus(address dataContractAddress, address userAddress) public view returns (uint256) {
        return _promoBigBonuses[dataContractAddress][userAddress];
    }

    
    function getUserTokenLocalBalance(address dataContractAddress, address userAddress) public view returns(uint256) {
        return _userTokenLocalBalances[dataContractAddress][userAddress];
    }
  
    
    function addUserTokenLocalBalance(address userAddress, uint256 val) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _userTokenLocalBalances[dataContractAddress][userAddress] = SafeMath.add(_userTokenLocalBalances[dataContractAddress][userAddress], val);
    }
    
    function subUserTokenLocalBalance(address userAddress, uint256 val) onlyController public {
        address dataContractAddress = Etherama(msg.sender).getDataContractAddress();
        _userTokenLocalBalances[dataContractAddress][userAddress] = SafeMath.sub(_userTokenLocalBalances[dataContractAddress][userAddress], val);
    }

  
    function getUserReward(address dataContractAddress, address userAddress, bool incShareBonus, bool incRefBonus, bool incPromoBonus) public view returns(uint256 reward) {
        EtheramaData data = EtheramaData(dataContractAddress);
        
        if (incShareBonus) {
            reward = data.getBonusPerShare() * data.getActualUserTokenBalance(userAddress);
            reward = ((reward < data.getUserRewardPayouts(userAddress)) ? 0 : SafeMath.sub(reward, data.getUserRewardPayouts(userAddress))) / MAGNITUDE;
        }
        
        if (incRefBonus) reward = SafeMath.add(reward, data.getUserRefBalance(userAddress));
        if (incPromoBonus) reward = SafeMath.add(reward, data.getUserTotalPromoBonus(userAddress));
        
        return reward;
    }
    
     
    function getUserTotalReward(address userAddress, bool incShareBonus, bool incRefBonus, bool incPromoBonus) public view returns(uint256 res) {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            address dataContractAddress = Etherama(_controllerIndexer[i]).getDataContractAddress();
            
            res = SafeMath.add(res, getUserReward(dataContractAddress, userAddress, incShareBonus, incRefBonus, incPromoBonus));
        }
    }
    
     
    function getCurrentUserReward(bool incRefBonus, bool incPromoBonus) public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, incRefBonus, incPromoBonus);
    }
 
     
    function getCurrentUserTotalReward() public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, true, true);
    }
    
     
    function getCurrentUserShareBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, true, false, false);
    }
    
     
    function getCurrentUserRefBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, false, true, false);
    }
    
     
    function getCurrentUserPromoBonus() public view returns(uint256) {
        return getUserTotalReward(msg.sender, false, false, true);
    }
    
     
    function isRefAvailable(address refAddress) public view returns(bool) {
        return getUserTotalEthVolumeSaldo(refAddress) >= _minRefEthPurchase;
    }
    
     
    function isRefAvailable() public view returns(bool) {
        return isRefAvailable(msg.sender);
    }
    
      
    function withdrawUserReward() public {
        uint256 reward = getRewardAndPrepareWithdraw();
        
        require(reward > 0);
        
        msg.sender.transfer(reward);
        
        emit onWithdrawUserBonus(msg.sender, reward);
    }

     
    function getRewardAndPrepareWithdraw() internal returns(uint256 reward) {
        
        for (uint256 i = 0; i < _controllerContractCount; i++) {

            address dataContractAddress = Etherama(_controllerIndexer[i]).getDataContractAddress();
            
            reward = SafeMath.add(reward, getUserReward(dataContractAddress, msg.sender, true, false, false));

             
            addUserRewardPayouts(dataContractAddress, msg.sender, reward * MAGNITUDE);

             
            reward = SafeMath.add(reward, getUserRefBalance(dataContractAddress, msg.sender));
            resetUserRefBalance(dataContractAddress, msg.sender);
            
             
            reward = SafeMath.add(reward, getUserTotalPromoBonus(dataContractAddress, msg.sender));
            resetUserPromoBonus(dataContractAddress, msg.sender);
        }
        
        return reward;
    }
    
     
    function withdrawRemainingEthAfterAll() onlyAdministrator public {
        for (uint256 i = 0; i < _controllerContractCount; i++) {
            if (Etherama(_controllerIndexer[i]).isActive()) revert();
        }
        
        msg.sender.transfer(address(this).balance);
    }

    
    
    function calcPercent(uint256 amount, uint256 percent) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(SafeMath.div(amount, 100), percent), 1 ether);
    }

     
    function convertRealTo256(int128 realVal) public pure returns(uint256) {
        int128 roundedVal = RealMath.fromReal(RealMath.mul(realVal, RealMath.toReal(1e12)));

        return SafeMath.mul(uint256(roundedVal), uint256(1e6));
    }

     
    function convert256ToReal(uint256 val) public pure returns(int128) {
        uint256 intVal = SafeMath.div(val, 1e6);
        require(RealMath.isUInt256ValidIn64(intVal));
        
        return RealMath.fraction(int64(intVal), 1e12);
    }    
}

 
contract EtheramaData {

    address public _tokenContractAddress;
    
     
    uint256 constant public TOKEN_PRICE_INITIAL = 0.001 ether;
     
    uint64 constant public PRICE_SPEED_PERCENT = 5;
     
    uint64 constant public PRICE_SPEED_INTERVAL = 10000;
     
    uint64 constant public EXP_PERIOD_DAYS = 365;

    
    mapping(address => bool) private _administrators;
    uint256 private  _administratorCount;

    uint64 public _initTime;
    uint64 public _expirationTime;
    uint256 public _tokenOwnerReward;
    
    uint256 public _totalSupply;
    int128 public _realTokenPrice;

    address public _controllerAddress = address(0x0);

    EtheramaCore public _core;

    uint256 public _initBlockNum;
    
    bool public _hasMaxPurchaseLimit = false;
    
    IStdToken public _token;

     
    modifier onlyController() {
        require(msg.sender == _controllerAddress);
        _;
    }

    constructor(address coreAddress) public {
        require(coreAddress != address(0x0));

        _core = EtheramaCore(coreAddress);
        _initBlockNum = block.number;
    }
    
    function init(address tokenContractAddress) public {
        require(_controllerAddress == address(0x0));
        require(tokenContractAddress != address(0x0));
        require(EXP_PERIOD_DAYS > 0);
        require(RealMath.isUInt64ValidIn64(PRICE_SPEED_PERCENT) && PRICE_SPEED_PERCENT > 0);
        require(RealMath.isUInt64ValidIn64(PRICE_SPEED_INTERVAL) && PRICE_SPEED_INTERVAL > 0);
        
        
        _controllerAddress = msg.sender;

        _token = IStdToken(tokenContractAddress);
        _initTime = uint64(now);
        _expirationTime = _initTime + EXP_PERIOD_DAYS * 1 days;
        _realTokenPrice = _core.convert256ToReal(TOKEN_PRICE_INITIAL);
    }
    
    function isInited()  public view returns(bool) {
        return (_controllerAddress != address(0x0));
    }
    
    function getCoreAddress()  public view returns(address) {
        return address(_core);
    }
    

    function setNewControllerAddress(address newAddress) onlyController public {
        _controllerAddress = newAddress;
    }


    
    function getPromoMinPurchaseEth() public view returns(uint256) {
        return _core._promoMinPurchaseEth();
    }

    function addAdministator(address addr) onlyController public {
        _administrators[addr] = true;
        _administratorCount = SafeMath.add(_administratorCount, 1);
    }

    function removeAdministator(address addr) onlyController public {
        _administrators[addr] = false;
        _administratorCount = SafeMath.sub(_administratorCount, 1);
    }

    function getAdministratorCount() public view returns(uint256) {
        return _administratorCount;
    }
    
    function isAdministrator(address addr) public view returns(bool) {
        return _administrators[addr];
    }

    
    function getCommonInitBlockNum() public view returns (uint256) {
        return _core.getInitBlockNum();
    }
    
    
    function resetTokenOwnerReward() onlyController public {
        _tokenOwnerReward = 0;
    }
    
    function addTokenOwnerReward(uint256 val) onlyController public {
        _tokenOwnerReward = SafeMath.add(_tokenOwnerReward, val);
    }
    
    function getCurrentBigPromoBonus() public view returns (uint256) {
        return _core._currentBigPromoBonus();
    }        
    

    function getCurrentQuickPromoBonus() public view returns (uint256) {
        return _core._currentQuickPromoBonus();
    }    

    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return _core.getTotalCollectedPromoBonus();
    }    

    function setTotalSupply(uint256 val) onlyController public {
        _totalSupply = val;
    }
    
    function setRealTokenPrice(int128 val) onlyController public {
        _realTokenPrice = val;
    }    
    
    
    function setHasMaxPurchaseLimit(bool val) onlyController public {
        _hasMaxPurchaseLimit = val;
    }
    
    function getUserTokenLocalBalance(address userAddress) public view returns(uint256) {
        return _core.getUserTokenLocalBalance(address(this), userAddress);
    }
    
    function getActualUserTokenBalance(address userAddress) public view returns(uint256) {
        return SafeMath.min(getUserTokenLocalBalance(userAddress), _token.balanceOf(userAddress));
    }  
    
    function getBonusPerShare() public view returns(uint256) {
        return _core.getBonusPerShare(address(this));
    }
    
    function getUserRewardPayouts(address userAddress) public view returns(uint256) {
        return _core.getUserRewardPayouts(address(this), userAddress);
    }
    
    function getUserRefBalance(address userAddress) public view returns(uint256) {
        return _core.getUserRefBalance(address(this), userAddress);
    }
    
    function getUserReward(address userAddress, bool incRefBonus, bool incPromoBonus) public view returns(uint256) {
        return _core.getUserReward(address(this), userAddress, true, incRefBonus, incPromoBonus);
    }
    
    function getUserTotalPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserTotalPromoBonus(address(this), userAddress);
    }
    
    function getUserBigPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserBigPromoBonus(address(this), userAddress);
    }

    function getUserQuickPromoBonus(address userAddress) public view returns(uint256) {
        return _core.getUserQuickPromoBonus(address(this), userAddress);
    }

    function getRemainingTokenAmount() public view returns(uint256) {
        return _token.balanceOf(_controllerAddress);
    }

    function getTotalTokenSold() public view returns(uint256) {
        return _totalSupply - getRemainingTokenAmount();
    }   
    
    function getUserEthVolumeSaldo(address userAddress) public view returns(uint256) {
        return _core.getUserEthVolumeSaldo(address(this), userAddress);
    }

}


contract Etherama {

    IStdToken public _token;
    EtheramaData public _data;
    EtheramaCore public _core;


    bool public isActive = false;
    bool public isMigrationToNewControllerInProgress = false;
    bool public isActualContractVer = true;
    address public migrationContractAddress = address(0x0);
    bool public isMigrationApproved = false;

    address private _creator = address(0x0);
    

    event onTokenPurchase(address indexed userAddress, uint256 incomingEth, uint256 tokensMinted, address indexed referredBy);
    
    event onTokenSell(address indexed userAddress, uint256 tokensBurned, uint256 ethEarned);
    
    event onReinvestment(address indexed userAddress, uint256 ethReinvested, uint256 tokensMinted);
    
    event onWithdrawTokenOwnerReward(address indexed toAddress, uint256 ethWithdrawn); 

    event onWinQuickPromo(address indexed userAddress, uint256 ethWon);    
   
    event onWinBigPromo(address indexed userAddress, uint256 ethWon);    


     
    modifier onlyContractUsers() {
        require(getUserLocalTokenBalance(msg.sender) > 0);
        _;
    }
    

     
     
     
     
     
     
     
     
    modifier onlyAdministrator() {
        require(isCurrentUserAdministrator());
        _;
    }
    
     
    modifier onlyCoreAdministrator() {
        require(_core.isAdministrator(msg.sender));
        _;
    }

     
    modifier onlyActive() {
        require(isActive);
        _;
    }

     
    modifier validGasPrice() {
        require(tx.gasprice <= _core.MAX_GAS_PRICE());
        _;
    }
    
     
    modifier validPayableValue() {
        require(msg.value > 0);
        _;
    }
    
    modifier onlyCoreContract() {
        require(msg.sender == _data.getCoreAddress());
        _;
    }

     
     
    constructor(address tokenContractAddress, address dataContractAddress) public {
        
        require(dataContractAddress != address(0x0));
        _data = EtheramaData(dataContractAddress);
        
        if (!_data.isInited()) {
            _data.init(tokenContractAddress);
            _data.addAdministator(msg.sender);
            _creator = msg.sender;
        }
        
        _token = _data._token();
        _core = _data._core();
    }



    function addAdministator(address addr) onlyAdministrator public {
        _data.addAdministator(addr);
    }

    function removeAdministator(address addr) onlyAdministrator public {
        _data.removeAdministator(addr);
    }

     
    function transferOwnershipRequest(address addr) onlyAdministrator public {
        addAdministator(addr);
    }

     
    function acceptOwnership() onlyAdministrator public {
        require(_creator != address(0x0));

        removeAdministator(_creator);

        require(_data.getAdministratorCount() == 1);
    }
    
     
    function setHasMaxPurchaseLimit(bool val) onlyAdministrator public {
        _data.setHasMaxPurchaseLimit(val);
    }
        
     
    function activate() onlyAdministrator public {
        require(!isActive);
        
        if (getTotalTokenSupply() == 0) setTotalSupply();
        require(getTotalTokenSupply() > 0);
        
        isActive = true;
        isMigrationToNewControllerInProgress = false;
    }

     
    function finish() onlyActive onlyAdministrator public {
        require(uint64(now) >= _data._expirationTime());
        
        _token.transfer(msg.sender, getRemainingTokenAmount());   
        msg.sender.transfer(getTotalEthBalance());
        
        isActive = false;
    }
    
     
    function buy(address refAddress, uint256 minReturn) onlyActive validGasPrice validPayableValue public payable returns(uint256) {
        return purchaseTokens(msg.value, refAddress, minReturn);
    }

     
    function sell(uint256 tokenAmount, uint256 minReturn) onlyActive onlyContractUsers validGasPrice public returns(uint256) {
        if (tokenAmount > getCurrentUserLocalTokenBalance() || tokenAmount == 0) return 0;

        uint256 ethAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (ethAmount, totalFeeEth, tokenPrice) = estimateSellOrder(tokenAmount, true);
        require(ethAmount >= minReturn);

        subUserTokens(msg.sender, tokenAmount);

        msg.sender.transfer(ethAmount);

        updateTokenPrice(-_core.convert256ToReal(tokenAmount));

        distributeFee(totalFeeEth, address(0x0));

        _core.trackSell(msg.sender, ethAmount, tokenAmount);
       
        emit onTokenSell(msg.sender, tokenAmount, ethAmount);

        return ethAmount;
    }   


     
    function() onlyActive validGasPrice validPayableValue payable external {
        purchaseTokens(msg.value, address(0x0), 1);
    }

     
    function withdrawTokenOwnerReward() onlyAdministrator public {
        uint256 reward = getTokenOwnerReward();
        
        require(reward > 0);
        
        _data.resetTokenOwnerReward();

        msg.sender.transfer(reward);

        emit onWithdrawTokenOwnerReward(msg.sender, reward);
    }

     
    function prepareForMigration() onlyAdministrator public {
        require(!isMigrationToNewControllerInProgress);
        isMigrationToNewControllerInProgress = true;
    }

     
    function migrateFunds() payable public {
        require(isMigrationToNewControllerInProgress);
    }
    

     

     
    function getMaxGasPrice() public view returns(uint256) {
        return _core.MAX_GAS_PRICE();
    }

     
    function getExpirationTime() public view returns (uint256) {
        return _data._expirationTime();
    }
            
     
    function getRemainingTimeTillExpiration() public view returns (uint256) {
        if (_data._expirationTime() <= uint64(now)) return 0;
        
        return _data._expirationTime() - uint64(now);
    }

    
    function isCurrentUserAdministrator() public view returns(bool) {
        return _data.isAdministrator(msg.sender);
    }

     
    function getDataContractAddress() public view returns(address) {
        return address(_data);
    }

     
    function getTokenAddress() public view returns(address) {
        return address(_token);
    }

     
    function requestControllerContractMigration(address newControllerAddr) onlyAdministrator public {
        require(!isMigrationApproved);
        
        migrationContractAddress = newControllerAddr;
    }
    
     
    function approveControllerContractMigration() onlyCoreAdministrator public {
        isMigrationApproved = true;
    }
    
     
    function migrateToNewNewControllerContract() onlyAdministrator public {
        require(isMigrationApproved && migrationContractAddress != address(0x0) && isActualContractVer);
        
        isActive = false;

        Etherama newController = Etherama(address(migrationContractAddress));
        _data.setNewControllerAddress(migrationContractAddress);

        uint256 remainingTokenAmount = getRemainingTokenAmount();
        uint256 ethBalance = getTotalEthBalance();

        if (remainingTokenAmount > 0) _token.transfer(migrationContractAddress, remainingTokenAmount); 
        if (ethBalance > 0) newController.migrateFunds.value(ethBalance)();
        
        isActualContractVer = false;
    }

     
    function getBuyCount() public view returns(uint256) {
        return _core.getBuyCount(address(this));
    }
     
    function getSellCount() public view returns(uint256) {
        return _core.getSellCount(address(this));
    }
     
    function getTotalVolumeEth() public view returns(uint256) {
        return _core.getTotalVolumeEth(address(this));
    }   
     
    function getTotalVolumeToken() public view returns(uint256) {
        return _core.getTotalVolumeToken(address(this));
    } 
     
    function getBonusPerShare() public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_data.getBonusPerShare(), 1 ether), _core.MAGNITUDE());
    }    
     
    function getTokenInitialPrice() public view returns(uint256) {
        return _data.TOKEN_PRICE_INITIAL();
    }

    function getDevRewardPercent() public view returns(uint256) {
        return _core._devRewardPercent();
    }

    function getTokenOwnerRewardPercent() public view returns(uint256) {
        return _core._tokenOwnerRewardPercent();
    }
    
    function getShareRewardPercent() public view returns(uint256) {
        return _core._shareRewardPercent();
    }
    
    function getRefBonusPercent() public view returns(uint256) {
        return _core._refBonusPercent();
    }
    
    function getBigPromoPercent() public view returns(uint256) {
        return _core._bigPromoPercent();
    }
    
    function getQuickPromoPercent() public view returns(uint256) {
        return _core._quickPromoPercent();
    }

    function getBigPromoBlockInterval() public view returns(uint256) {
        return _core._bigPromoBlockInterval();
    }

    function getQuickPromoBlockInterval() public view returns(uint256) {
        return _core._quickPromoBlockInterval();
    }

    function getPromoMinPurchaseEth() public view returns(uint256) {
        return _core._promoMinPurchaseEth();
    }


    function getPriceSpeedPercent() public view returns(uint64) {
        return _data.PRICE_SPEED_PERCENT();
    }

    function getPriceSpeedTokenBlock() public view returns(uint64) {
        return _data.PRICE_SPEED_INTERVAL();
    }

    function getMinRefEthPurchase() public view returns (uint256) {
        return _core._minRefEthPurchase();
    }    

    function getTotalCollectedPromoBonus() public view returns (uint256) {
        return _data.getTotalCollectedPromoBonus();
    }   

    function getCurrentBigPromoBonus() public view returns (uint256) {
        return _data.getCurrentBigPromoBonus();
    }  

    function getCurrentQuickPromoBonus() public view returns (uint256) {
        return _data.getCurrentQuickPromoBonus();
    }    

     
    function getCurrentTokenPrice() public view returns(uint256) {
        return _core.convertRealTo256(_data._realTokenPrice());
    }

     
    function getTotalEthBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
     
    function getTotalTokenSupply() public view returns(uint256) {
        return _data._totalSupply();
    }

     
    function getRemainingTokenAmount() public view returns(uint256) {
        return _token.balanceOf(address(this));
    }
    
     
    function getTotalTokenSold() public view returns(uint256) {
        return getTotalTokenSupply() - getRemainingTokenAmount();
    }
    
     
    function getUserLocalTokenBalance(address userAddress) public view returns(uint256) {
        return _data.getUserTokenLocalBalance(userAddress);
    }
    
     
    function getCurrentUserLocalTokenBalance() public view returns(uint256) {
        return getUserLocalTokenBalance(msg.sender);
    }    

     
    function isCurrentUserRefAvailable() public view returns(bool) {
        return _core.isRefAvailable();
    }


    function getCurrentUserRefBonus() public view returns(uint256) {
        return _data.getUserRefBalance(msg.sender);
    }
    
    function getCurrentUserPromoBonus() public view returns(uint256) {
        return _data.getUserTotalPromoBonus(msg.sender);
    }
    
     
    function getTokenDealRange() public view returns(uint256, uint256) {
        return (_core.MIN_TOKEN_DEAL_VAL(), _core.MAX_TOKEN_DEAL_VAL());
    }
    
     
    function getEthDealRange() public view returns(uint256, uint256) {
        uint256 minTokenVal; uint256 maxTokenVal;
        (minTokenVal, maxTokenVal) = getTokenDealRange();
        
        return ( SafeMath.max(_core.MIN_ETH_DEAL_VAL(), tokensToEth(minTokenVal, true)), SafeMath.min(_core.MAX_ETH_DEAL_VAL(), tokensToEth(maxTokenVal, true)) );
    }
    
     
    function getUserReward(address userAddress, bool isTotal) public view returns(uint256) {
        return isTotal ? 
            _core.getUserTotalReward(userAddress, true, true, true) :
            _data.getUserReward(userAddress, true, true);
    }
    
     
    function get1TokenSellPrice() public view returns(uint256) {
        uint256 tokenAmount = 1 ether;

        uint256 ethAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (ethAmount, totalFeeEth, tokenPrice) = estimateSellOrder(tokenAmount, true);

        return ethAmount;
    }
    
     
    function get1TokenBuyPrice() public view returns(uint256) {
        uint256 ethAmount = 1 ether;

        uint256 tokenAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (tokenAmount, totalFeeEth, tokenPrice) = estimateBuyOrder(ethAmount, true);  

        return SafeMath.div(ethAmount * 1 ether, tokenAmount);
    }

     
    function calcReward(uint256 tokenAmount) public view returns(uint256) {
        return (uint256) ((int256)(_data.getBonusPerShare() * tokenAmount)) / _core.MAGNITUDE();
    }  

     
    function estimateBuyOrder(uint256 amount, bool fromEth) public view returns(uint256, uint256, uint256) {
        uint256 minAmount; uint256 maxAmount;
        (minAmount, maxAmount) = fromEth ? getEthDealRange() : getTokenDealRange();
         

        uint256 ethAmount = fromEth ? amount : tokensToEth(amount, true);
        require(ethAmount > 0);

        uint256 tokenAmount = fromEth ? ethToTokens(amount, true) : amount;
        uint256 totalFeeEth = calcTotalFee(tokenAmount, true);
        require(ethAmount > totalFeeEth);

        uint256 tokenPrice = SafeMath.div(ethAmount * 1 ether, tokenAmount);

        return (fromEth ? tokenAmount : SafeMath.add(ethAmount, totalFeeEth), totalFeeEth, tokenPrice);
    }
    
     
    function estimateSellOrder(uint256 amount, bool fromToken) public view returns(uint256, uint256, uint256) {
        uint256 minAmount; uint256 maxAmount;
        (minAmount, maxAmount) = fromToken ? getTokenDealRange() : getEthDealRange();
         

        uint256 tokenAmount = fromToken ? amount : ethToTokens(amount, false);
        require(tokenAmount > 0);
        
        uint256 ethAmount = fromToken ? tokensToEth(tokenAmount, false) : amount;
        uint256 totalFeeEth = calcTotalFee(tokenAmount, false);
        require(ethAmount > totalFeeEth);

        uint256 tokenPrice = SafeMath.div(ethAmount * 1 ether, tokenAmount);
        
        return (fromToken ? ethAmount : tokenAmount, totalFeeEth, tokenPrice);
    }

     
    function getUserMaxPurchase(address userAddress) public view returns(uint256) {
        return _token.balanceOf(userAddress) - SafeMath.mul(getUserLocalTokenBalance(userAddress), 2);
    }
     
    function getCurrentUserMaxPurchase() public view returns(uint256) {
        return getUserMaxPurchase(msg.sender);
    }

     
    function getTokenOwnerReward() public view returns(uint256) {
        return _data._tokenOwnerReward();
    }

     
    function getCurrentUserTotalPromoBonus() public view returns(uint256) {
        return _data.getUserTotalPromoBonus(msg.sender);
    }

     
    function getCurrentUserBigPromoBonus() public view returns(uint256) {
        return _data.getUserBigPromoBonus(msg.sender);
    }
     
    function getCurrentUserQuickPromoBonus() public view returns(uint256) {
        return _data.getUserQuickPromoBonus(msg.sender);
    }
   
     
    function getBlockNumSinceInit() public view returns(uint256) {
        return _core.getBlockNumSinceInit();
    }

     
    function getQuickPromoRemainingBlocks() public view returns(uint256) {
        return _core.getQuickPromoRemainingBlocks();
    }
     
    function getBigPromoRemainingBlocks() public view returns(uint256) {
        return _core.getBigPromoRemainingBlocks();
    } 
    
    
     
    
    function purchaseTokens(uint256 ethAmount, address refAddress, uint256 minReturn) internal returns(uint256) {
        uint256 tokenAmount = 0; uint256 totalFeeEth = 0; uint256 tokenPrice = 0;
        (tokenAmount, totalFeeEth, tokenPrice) = estimateBuyOrder(ethAmount, true);
        require(tokenAmount >= minReturn);

        if (_data._hasMaxPurchaseLimit()) {
             
            require(getCurrentUserMaxPurchase() >= tokenAmount);
        }

        require(tokenAmount > 0 && (SafeMath.add(tokenAmount, getTotalTokenSold()) > getTotalTokenSold()));

        if (refAddress == msg.sender || !_core.isRefAvailable(refAddress)) refAddress = address(0x0);

        distributeFee(totalFeeEth, refAddress);

        addUserTokens(msg.sender, tokenAmount);

         
        _core.addUserRewardPayouts(msg.sender, _data.getBonusPerShare() * tokenAmount);

        checkAndSendPromoBonus(ethAmount);
        
        updateTokenPrice(_core.convert256ToReal(tokenAmount));
        
        _core.trackBuy(msg.sender, ethAmount, tokenAmount);

        emit onTokenPurchase(msg.sender, ethAmount, tokenAmount, refAddress);
        
        return tokenAmount;
    }

    function setTotalSupply() internal {
        require(_data._totalSupply() == 0);

        uint256 tokenAmount = _token.balanceOf(address(this));

        _data.setTotalSupply(tokenAmount);
    }


    function checkAndSendPromoBonus(uint256 purchaseAmountEth) internal {
        if (purchaseAmountEth < _data.getPromoMinPurchaseEth()) return;

        if (getQuickPromoRemainingBlocks() == 0) sendQuickPromoBonus();
        if (getBigPromoRemainingBlocks() == 0) sendBigPromoBonus();
    }

    function sendQuickPromoBonus() internal {
        _core.payoutQuickBonus(msg.sender);

        emit onWinQuickPromo(msg.sender, _data.getCurrentQuickPromoBonus());
    }

    function sendBigPromoBonus() internal {
        _core.payoutBigBonus(msg.sender);

        emit onWinBigPromo(msg.sender, _data.getCurrentBigPromoBonus());
    }

    function distributeFee(uint256 totalFeeEth, address refAddress) internal {
        addProfitPerShare(totalFeeEth, refAddress);
        addDevReward(totalFeeEth);
        addTokenOwnerReward(totalFeeEth);
        addBigPromoBonus(totalFeeEth);
        addQuickPromoBonus(totalFeeEth);
    }

    function addProfitPerShare(uint256 totalFeeEth, address refAddress) internal {
        uint256 refBonus = calcRefBonus(totalFeeEth);
        uint256 totalShareReward = calcTotalShareRewardFee(totalFeeEth);

        if (refAddress != address(0x0)) {
            _core.addUserRefBalance.value(refBonus)(refAddress);
        } else {
            totalShareReward = SafeMath.add(totalShareReward, refBonus);
        }

        if (getTotalTokenSold() == 0) {
            _data.addTokenOwnerReward(totalShareReward);
        } else {
            _core.addBonusPerShare.value(totalShareReward)();
        }
    }

    function addDevReward(uint256 totalFeeEth) internal {
        _core.addDevReward.value(calcDevReward(totalFeeEth))();
    }    
    
    function addTokenOwnerReward(uint256 totalFeeEth) internal {
        _data.addTokenOwnerReward(calcTokenOwnerReward(totalFeeEth));
    }  

    function addBigPromoBonus(uint256 totalFeeEth) internal {
        _core.addBigPromoBonus.value(calcBigPromoBonus(totalFeeEth))();
    }

    function addQuickPromoBonus(uint256 totalFeeEth) internal {
        _core.addQuickPromoBonus.value(calcQuickPromoBonus(totalFeeEth))();
    }   


    function addUserTokens(address user, uint256 tokenAmount) internal {
        _core.addUserTokenLocalBalance(user, tokenAmount);
        _token.transfer(msg.sender, tokenAmount);   
    }

    function subUserTokens(address user, uint256 tokenAmount) internal {
        _core.subUserTokenLocalBalance(user, tokenAmount);
        _token.transferFrom(user, address(this), tokenAmount);    
    }

    function updateTokenPrice(int128 realTokenAmount) public {
        _data.setRealTokenPrice(calc1RealTokenRateFromRealTokens(realTokenAmount));
    }

    function ethToTokens(uint256 ethAmount, bool isBuy) internal view returns(uint256) {
        int128 realEthAmount = _core.convert256ToReal(ethAmount);
        int128 t0 = RealMath.div(realEthAmount, _data._realTokenPrice());
        int128 s = getRealPriceSpeed();

        int128 tn =  RealMath.div(t0, RealMath.toReal(100));

        for (uint i = 0; i < 100; i++) {

            int128 tns = RealMath.mul(tn, s);
            int128 exptns = RealMath.exp( RealMath.mul(tns, RealMath.toReal(isBuy ? int64(1) : int64(-1))) );

            int128 tn1 = RealMath.div(
                RealMath.mul( RealMath.mul(tns, tn), exptns ) + t0,
                RealMath.mul( exptns, RealMath.toReal(1) + tns )
            );

            if (RealMath.abs(tn-tn1) < RealMath.fraction(1, 1e18)) break;

            tn = tn1;
        }

        return _core.convertRealTo256(tn);
    }

    function tokensToEth(uint256 tokenAmount, bool isBuy) internal view returns(uint256) {
        int128 realTokenAmount = _core.convert256ToReal(tokenAmount);
        int128 s = getRealPriceSpeed();
        int128 expArg = RealMath.mul(RealMath.mul(realTokenAmount, s), RealMath.toReal(isBuy ? int64(1) : int64(-1)));
        
        int128 realEthAmountFor1Token = RealMath.mul(_data._realTokenPrice(), RealMath.exp(expArg));
        int128 realEthAmount = RealMath.mul(realTokenAmount, realEthAmountFor1Token);

        return _core.convertRealTo256(realEthAmount);
    }

    function calcTotalFee(uint256 tokenAmount, bool isBuy) internal view returns(uint256) {
        int128 realTokenAmount = _core.convert256ToReal(tokenAmount);
        int128 factor = RealMath.toReal(isBuy ? int64(1) : int64(-1));
        int128 rateAfterDeal = calc1RealTokenRateFromRealTokens(RealMath.mul(realTokenAmount, factor));
        int128 delta = RealMath.div(rateAfterDeal - _data._realTokenPrice(), RealMath.toReal(2));
        int128 fee = RealMath.mul(realTokenAmount, delta);
        
         
        if (!isBuy) fee = RealMath.mul(fee, RealMath.fraction(95, 100));

        return _core.calcPercent(_core.convertRealTo256(RealMath.mul(fee, factor)), _core._totalIncomeFeePercent());
    }



    function calc1RealTokenRateFromRealTokens(int128 realTokenAmount) internal view returns(int128) {
        int128 expArg = RealMath.mul(realTokenAmount, getRealPriceSpeed());

        return RealMath.mul(_data._realTokenPrice(), RealMath.exp(expArg));
    }
    
    function getRealPriceSpeed() internal view returns(int128) {
        require(RealMath.isUInt64ValidIn64(_data.PRICE_SPEED_PERCENT()));
        require(RealMath.isUInt64ValidIn64(_data.PRICE_SPEED_INTERVAL()));
        
        return RealMath.div(RealMath.fraction(int64(_data.PRICE_SPEED_PERCENT()), 100), RealMath.toReal(int64(_data.PRICE_SPEED_INTERVAL())));
    }


    function calcTotalShareRewardFee(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._shareRewardPercent());
    }
    
    function calcRefBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._refBonusPercent());
    }
    
    function calcTokenOwnerReward(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._tokenOwnerRewardPercent());
    }

    function calcDevReward(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._devRewardPercent());
    }

    function calcQuickPromoBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._quickPromoPercent());
    }    

    function calcBigPromoBonus(uint256 totalFee) internal view returns(uint256) {
        return _core.calcPercent(totalFee, _core._bigPromoPercent());
    }        


}


library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    } 

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }   

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }   
}

 
library RealMath {
    
    int64 constant MIN_INT64 = int64((uint64(1) << 63));
    int64 constant MAX_INT64 = int64(~((uint64(1) << 63)));
    
     
    int256 constant REAL_BITS = 128;
    
     
    int256 constant REAL_FBITS = 64;
    
     
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;
    
     
    int128 constant REAL_ONE = int128(1) << REAL_FBITS;
    
     
    int128 constant REAL_HALF = REAL_ONE >> 1;
    
     
    int128 constant REAL_TWO = REAL_ONE << 1;
    
     
    int128 constant REAL_LN_TWO = 762123384786;
    
     
    int128 constant REAL_PI = 3454217652358;
    
     
    int128 constant REAL_HALF_PI = 1727108826179;
    
     
    int128 constant REAL_TWO_PI = 6908435304715;
    
     
    int128 constant SIGN_MASK = int128(1) << 127;
    

    function getMinInt64() internal pure returns (int64) {
        return MIN_INT64;
    }
    
    function getMaxInt64() internal pure returns (int64) {
        return MAX_INT64;
    }
    
    function isUInt256ValidIn64(uint256 val) internal pure returns (bool) {
        return val >= 0 && val <= uint256(getMaxInt64());
    }
    
    function isInt256ValidIn64(int256 val) internal pure returns (bool) {
        return val >= int256(getMinInt64()) && val <= int256(getMaxInt64());
    }
    
    function isUInt64ValidIn64(uint64 val) internal pure returns (bool) {
        return val >= 0 && val <= uint64(getMaxInt64());
    }
    
    function isInt128ValidIn64(int128 val) internal pure returns (bool) {
        return val >= int128(getMinInt64()) && val <= int128(getMaxInt64());
    }

     
    function toReal(int64 ipart) internal pure returns (int128) {
        return int128(ipart) * REAL_ONE;
    }
    
     
    function fromReal(int128 real_value) internal pure returns (int64) {
        int128 intVal = real_value / REAL_ONE;
        require(isInt128ValidIn64(intVal));
        
        return int64(intVal);
    }
    
    
     
    function abs(int128 real_value) internal pure returns (int128) {
        if (real_value > 0) {
            return real_value;
        } else {
            return -real_value;
        }
    }
    
    
     
    function fpart(int128 real_value) internal pure returns (int128) {
         
        return abs(real_value) % REAL_ONE;
    }

     
    function fpartSigned(int128 real_value) internal pure returns (int128) {
         
        int128 fractional = fpart(real_value);
        return real_value < 0 ? -fractional : fractional;
    }
    
     
    function ipart(int128 real_value) internal pure returns (int128) {
         
        return real_value - fpartSigned(real_value);
    }
    
     
    function mul(int128 real_a, int128 real_b) internal pure returns (int128) {
         
         
        return int128((int256(real_a) * int256(real_b)) >> REAL_FBITS);
    }
    
     
    function div(int128 real_numerator, int128 real_denominator) internal pure returns (int128) {
         
         
        return int128((int256(real_numerator) * REAL_ONE) / int256(real_denominator));
    }
    
     
    function fraction(int64 numerator, int64 denominator) internal pure returns (int128) {
        return div(toReal(numerator), toReal(denominator));
    }
    
     
     
     
    
     
    function ipow(int128 real_base, int64 exponent) internal pure returns (int128) {
        if (exponent < 0) {
             
            revert();
        }
        
         
        int128 real_result = REAL_ONE;
        while (exponent != 0) {
             
            if ((exponent & 0x1) == 0x1) {
                 
                real_result = mul(real_result, real_base);
            }
             
            exponent = exponent >> 1;
             
            real_base = mul(real_base, real_base);
        }
        
         
        return real_result;
    }
    
     
    function hibit(uint256 val) internal pure returns (uint256) {
         
        val |= (val >>  1);
        val |= (val >>  2);
        val |= (val >>  4);
        val |= (val >>  8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }
    
     
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
         
        
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
             
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
             
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
             
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
             
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
             
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
             
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
             
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
             
            index |= 128;
        }
    }
    
     
    function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int64 shift) {
        if (real_arg <= 0) {
             
            revert();
        }
        
        require(isInt256ValidIn64(REAL_FBITS));
        
         
        int64 high_bit = findbit(hibit(uint256(real_arg)));
        
         
        shift = high_bit - int64(REAL_FBITS);
        
        if (shift < 0) {
             
            real_scaled = real_arg << -shift;
        } else if (shift >= 0) {
             
            real_scaled = real_arg >> shift;
        }
    }
    
     
    function lnLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
        if (real_arg <= 0) {
             
            revert();
        }
        
        if (real_arg == REAL_ONE) {
             
             
            return 0;
        }
        
         
        int128 real_rescaled;
        int64 shift;
        (real_rescaled, shift) = rescale(real_arg);
        
         
        int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);
        
         
        int128 real_series_result = 0;
        
        for (int64 n = 0; n < max_iterations; n++) {
             
            int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
             
            real_series_result += real_term;
            if (real_term == 0) {
                 
                break;
            }
             
        }
        
         
        real_series_result = mul(real_series_result, REAL_TWO);
        
         
        return mul(toReal(shift), REAL_LN_TWO) + real_series_result;
        
    }
    
     
    function ln(int128 real_arg) internal pure returns (int128) {
        return lnLimited(real_arg, 100);
    }
    

      
    function expLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
         
        int128 real_result = 0;
        
         
        int128 real_term = REAL_ONE;
        
        for (int64 n = 0; n < max_iterations; n++) {
             
            real_result += real_term;
            
             
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                 
                break;
            }
             
        }
        
         
        return real_result;
        
    }

    function expLimited(int128 real_arg, int max_iterations, int k) internal pure returns (int128) {
         
        int128 real_result = 0;
        
         
        int128 real_term = REAL_ONE;
        
        for (int64 n = 0; n < max_iterations; n++) {
             
            real_result += real_term;
            
             
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                 
                break;
            }

            if (n == k) return real_term;

             
        }
        
         
        return real_result;
        
    }

     
    function exp(int128 real_arg) internal pure returns (int128) {
        return expLimited(real_arg, 100);
    }
    
     
    function pow(int128 real_base, int128 real_exponent) internal pure returns (int128) {
        if (real_exponent == 0) {
             
            return REAL_ONE;
        }
        
        if (real_base == 0) {
            if (real_exponent < 0) {
                 
                revert();
            }
             
            return 0;
        }
        
        if (fpart(real_exponent) == 0) {
             
            
            if (real_exponent > 0) {
                 
                return ipow(real_base, fromReal(real_exponent));
            } else {
                 
                return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
            }
        }
        
        if (real_base < 0) {
             
             
             
            revert();
        }
        
         
        return exp(mul(real_exponent, ln(real_base)));
    }
}