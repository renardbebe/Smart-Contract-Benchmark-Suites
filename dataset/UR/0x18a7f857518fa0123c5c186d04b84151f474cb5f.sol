 

 

 

 

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
        require(newOwner != _owner);
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
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


 
interface ICt {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function inWhitelist(address account) external view returns (bool);
    function referrer(address account) external view returns (address);
    function referrerel(address account) external view returns (address[] memory);
    function refCount(address account) external view returns (uint256);
}


 
contract CtPublicSale is Ownable, Pausable{
    using SafeMath16 for uint16;
    using SafeMath256 for uint256;

     
    ICt public CT = ICt(0x3Fa7807FF5a1C70699C912b66413f358AaDeaA75);

     
    uint32 _startTimestamp;

     
    uint256 private _etherPrice;    

    
	
    uint16[2] private WHITELIST_REF_REWARDS_PCT = [
        15,   
        12   
        
    ];
	
	
     
    uint72 private WEI_MIN = 0.1 ether;     
    uint72 private WEI_MAX = 100 ether;     
    uint72 private WEI_BONUS = 10 ether;    
    uint24 private GAS_MIN = 3000000;       
    uint24 private GAS_EX  = 1500000;        

     
    uint256 private CT_USD_PRICE_START = 100000;       
    uint256 private CT_USD_PRICE_STEP = 10000;         
   
    uint256 private STAGE_USD_CAP_START = 10000000000000;    
    uint256 private STAGE_USD_CAP_STEP = 1000000000000;       
    uint256 private STAGE_USD_CAP_MAX = 100000000000000;   
    
    uint256 private STAGE_CT_CAP_START = 1000000000000;    
    uint256 private STAGE_CT_CAP_STEP  = 1000000000000;       
    uint256 private STAGE_CT_CAP_MAX   = 100000000000000;    
    
    uint256 private _CTUsdPrice = CT_USD_PRICE_START; 
    
    uint16 private STAGE_MAX = 100;  
    

    uint16 private _stage;
   

     
    uint256 private _txs; 
    uint256 private _CTTxs;
    uint256 private _CTBonusTxs;
    uint256 private _CTWhitelistTxs;
    uint256 private _CTIssued;
    uint256 private _CTBonus;
    uint256 private _CTWhitelist;
    uint256 private _usdSold;
    uint256 private _weiSold;  
    uint256 private _weiRefRewarded;  
    
    uint256 private _ctRefRewarded;
    uint256 private _weiTeam=0; 
    


     
    bool private _inWhitelist_;
   
    uint16[] private _rewards_;
    address[] private _referrers_;

    

     
    mapping (uint16 => uint256) private _stageUsdSold; 
    mapping (uint16 => uint256) private _stageCTIssued; 
    mapping (uint16 => uint256) private _stageCTRewarded;
    
    mapping (uint16 => uint256) private _stageCTRewardedTx;

   

     
    mapping (address => uint256) private _accountCTIssued;
    mapping (address => uint256) private _accountCTBonus;
    mapping (address => uint256) private _accountCTWhitelisted;
    mapping (address => uint256) private _accountWeiPurchased; 
    mapping (address => uint256) private _accountWeiRefRewarded; 

  
   

     
    event AuditEtherPriceChanged(uint256 value, address indexed account);
    event AuditEtherPriceAuditorChanged(address indexed account, bool state);

    event CTBonusTransfered(address indexed to, uint256 amount);
    event CTWhitelistTransfered(address indexed to, uint256 amount);
    event CTIssuedTransfered(uint16 stageIndex, address indexed to, uint256 CTAmount, uint256 auditEtherPrice, uint256 weiUsed);

    event StageClosed(uint256 _stageNumber, address indexed account);
   
    event TeamWeiTransfered(address indexed to, uint256 amount);
    event PendingWeiTransfered(address indexed to, uint256 amount);


     
    function startTimestamp() public view returns (uint32) {
        return _startTimestamp;
    }

     
    function setStartTimestamp(uint32 timestamp) external onlyOwner {
        _startTimestamp = timestamp;
    }

  

     
    function setEtherPrice(uint256 value) external onlyOwner {
        _etherPrice = value;
        emit AuditEtherPriceChanged(value, msg.sender);
    }

 

   

     
	 
	function stageCTUsdPrice(uint16 stageIndex) private view returns (uint256) {
		
        return CT_USD_PRICE_START.add(CT_USD_PRICE_STEP.mul(stageIndex));
    }

     
    function wei2usd(uint256 amount) private view returns (uint256) {
        return amount.mul(_etherPrice).div(1 ether);
    }

     
    function usd2wei(uint256 amount) private view returns (uint256) {
        return amount.mul(1 ether).div(_etherPrice);
    }

     
    function usd2CT(uint256 usdAmount) private view returns (uint256) {
      
		return usdAmount.mul(1000000).div(_CTUsdPrice);
    }
    
      
    function CT2usd(uint256 usdAmount) private view returns (uint256) {
      
		return usdAmount.mul(_CTUsdPrice).div(1000000);
    }

     
    function usd2CTByStage(uint256 usdAmount, uint16 stageIndex) public view returns (uint256) {

        if(stageIndex<1){
            stageIndex = 0;
        }
        return usdAmount.mul(1000000).div(stageCTUsdPrice(stageIndex));
    }


     
    function status() public view returns (uint256 auditEtherPrice,
                                           uint16  stage,
                                           uint256 CTUsdPrice,
                                           uint256 txs,
                                           uint256 CTTxs,
                                           uint256 CTBonusTxs,
                                           uint256 CTWhitelistTxs,
                                           uint256 CTIssued,
                                           uint256 CTBonus,
                                           uint256 useSold,
                                           uint256 weiSold,
                                           uint256 weiReferralRewarded,
                                           uint256 ctReferralRewarded,
                                           uint256 weiTeam) {
        auditEtherPrice = _etherPrice;

        if (_stage > STAGE_MAX) {
            stage = STAGE_MAX;
            
        } else {
            stage = _stage + 1;
            
        }

        CTUsdPrice = _CTUsdPrice;
        txs = _txs;
        CTTxs = _CTTxs;
        CTBonusTxs = _CTBonusTxs;
        CTWhitelistTxs = _CTWhitelistTxs;
        CTIssued = _CTIssued;
        CTBonus = _CTBonus;
        useSold = _usdSold;
        weiSold = _weiSold;
        weiReferralRewarded = _weiRefRewarded;
        ctReferralRewarded  = _ctRefRewarded;
        weiTeam = _weiTeam;
    }

   

     
    modifier enoughGas() {
        require(gasleft() > GAS_MIN);
        _;
    }

     
    modifier onlyOnSale() {
        require(_startTimestamp > 0 && now > _startTimestamp, "CT Public-Sale has not started yet.");
        require(_etherPrice > 0, "Audit ETH price must be greater than zero.");
        require(!paused(), "CT Public-Sale is paused.");
        require(_stage <= STAGE_MAX, "CT Public-Sale Closed.");
        _;
    }


     
    function stageUsdCap(uint16 stageIndex) private view returns (uint256) {
        uint256 __usdCap = STAGE_USD_CAP_START.add(STAGE_USD_CAP_STEP.mul(stageIndex));

        if (__usdCap > STAGE_USD_CAP_MAX) {
            return STAGE_USD_CAP_MAX;
        }

        return __usdCap;
    }
    
    
    function stageCTCapGet(uint16 stageIndex) private view returns (uint256) {
        uint256 __ctCap = STAGE_CT_CAP_START.add(STAGE_CT_CAP_STEP.mul(stageIndex));

        if (__ctCap >= STAGE_CT_CAP_MAX) {
            return STAGE_CT_CAP_MAX;
        }

        return __ctCap;
    }

     
    function stageCTCap(uint16 stageIndex) private view returns (uint256) {
      
        stageIndex = 1;
        return STAGE_CT_CAP_STEP.mul(stageIndex);
    }

     
    function stageStatus(uint16 stageIndex) public view returns (uint256 CTUsdPrice,
                                                                 uint256 CTCap,
                                                                 uint256 CTOnSale,
                                                                 uint256 CTSold,
                                                                 uint256 CTRewarded,
                                                                 uint256 CTWhitelistTxs,
                                                                 uint256 weiSold,
                                                                 uint256 usdSold
                                                                 ) {
        if (stageIndex > STAGE_MAX) {
            return (0, 0, 0, 0, 0,0,0,0);
        }
        
        if(stageIndex<1)
        {
            return (0, 0, 0, 0, 0,0,0,0);
        }
        
        stageIndex = stageIndex.sub(1);

        CTUsdPrice = stageCTUsdPrice(stageIndex);

        CTSold = _stageCTIssued[stageIndex]; 
        CTRewarded = _stageCTRewarded[stageIndex];
        CTCap = stageCTCap(stageIndex); 
        CTOnSale = CTCap.sub(CTSold);
        
        CTWhitelistTxs = _stageCTRewardedTx[stageIndex];
        
        usdSold = _stageUsdSold[stageIndex];
        weiSold = usd2wei(usdSold);
       
    }



     
    function accountQuery(address account) public view returns (uint256 CTIssued,
                                                                uint256 CTWhitelisted,
                                                                uint256 weiPurchased,
                                                                uint256 weiReferralRewarded) {
        CTIssued = _accountCTIssued[account];
        CTWhitelisted = _accountCTWhitelisted[account];
        weiPurchased = _accountWeiPurchased[account];
        weiReferralRewarded = _accountWeiRefRewarded[account];
    }



     
    constructor () public {
       
        _stage = 0;
        
    }
    

     
    function () external payable enoughGas onlyOnSale {
        require(msg.value >= WEI_MIN);  
        require(msg.value <= WEI_MAX);  

         
         setTemporaryVariables();
		
		
        uint256 __usdAmount = wei2usd(msg.value);
        uint256 __usdRemain = __usdAmount;
        uint256 __ctRemain = usd2CT(__usdAmount);
        uint256 __CTIssued; 
        uint256 __usdUsed;
        uint256 __weiUsed;
        
         
		while (gasleft() > GAS_EX && __ctRemain > 0 && _stage <= STAGE_MAX) {
			
			if(_stage.add(1)==STAGE_MAX && _stageCTIssued[_stage] == STAGE_CT_CAP_STEP){
			    break;
			}
			
            uint256 __txCTIssued;
			
            (__txCTIssued, __usdRemain,__ctRemain) = ex(__usdRemain);
            __CTIssued = __CTIssued.add(__txCTIssued);
        }
        
        if(__CTIssued>0)
        {
            assert(CT.transfer(msg.sender, __CTIssued));
        }
        
        
         
        __usdUsed = __usdAmount.sub(__usdRemain);
        __weiUsed = usd2wei(__usdUsed);

       
         
         
        if (_inWhitelist_ && __CTIssued > 0 && _stage <= STAGE_MAX) {
            
             
            sendWhitelistReferralRewards(__CTIssued);
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
        
        emit CTWhitelistTransfered(msg.sender, _weiSold);
        
        emit CTWhitelistTransfered(msg.sender, _weiRefRewarded);

         
        uint256 __weiTeam;
       
        __weiTeam = _weiSold.sub(_weiRefRewarded).sub(_weiTeam);

        _weiTeam = _weiTeam.add(__weiTeam);
         
        _receiver.transfer(__weiTeam);

         
        assert(true);
    }
    
    function _mint(address account, uint256 value) public onlyOwner returns (bool) {
        require(CT.balanceOf(address(this)) > value);
        require(account != address(0));

        assert(CT.transfer(account, value));
        
        return transferCTWhitelisted(value);
     
        
    }

     
    function setTemporaryVariables() private {
        delete _referrers_;
        delete _rewards_;
		
        _inWhitelist_ = true;
		
        address __cursor = msg.sender;

        for(uint16 i = 0; i < WHITELIST_REF_REWARDS_PCT.length; i++) {
			
            address __refAccount = CT.referrer(__cursor);
            
            
            if(__refAccount==address(0)){
                break;
            }
            
            if (__cursor == __refAccount) {
				
                break;
            }
            
            _rewards_.push(WHITELIST_REF_REWARDS_PCT[i]);
            _referrers_.push(__refAccount);
            
            __cursor = __refAccount;
        }
    }

     
    function ex(uint256 usdAmount) private returns (uint256, uint256, uint256) {
	
		
		uint256 __stageCtCap = STAGE_CT_CAP_STEP;
		uint256 __CTsued;
        uint256 __CTIssued;
        
        __CTsued = usd2CT(usdAmount);

         
        if (_stageCTIssued[_stage].add(__CTsued) <= __stageCtCap) {
            
			exCount(usdAmount);

            __CTIssued = usd2CT(usdAmount);
           assert(transferCTIssued(__CTIssued, usdAmount));

             
            if (__stageCtCap == _stageCTIssued[_stage]) {
                assert(closeStage());
            }

            return (__CTIssued, 0, 0);
        }
		
         
        __CTIssued = __stageCtCap.sub(_stageCTIssued[_stage]);
        
        uint256 __usdUsed = CT2usd(__CTIssued);
        
        
        exCount(__usdUsed);
        
        uint256 __ctRemain = __CTsued.sub(__CTIssued);
        uint256 __usdRemain = usdAmount.sub(__usdUsed);
        
        assert(transferCTIssued(__CTIssued, __usdUsed));
        assert(closeStage());

        return (__CTIssued, __usdRemain, __ctRemain);
    }
	
   

     
    function exCount(uint256 usdAmount) private {
       
        _stageUsdSold[_stage] = _stageUsdSold[_stage].add(usdAmount);                    
        _usdSold = _usdSold.add(usdAmount);
    }

     
    function transferCTIssued(uint256 amount, uint256 usdAmount) private returns (bool) {
        
		_CTTxs = _CTTxs.add(1);
	
        _CTIssued = _CTIssued.add(amount);
		
        _stageCTIssued[_stage] = _stageCTIssued[_stage].add(amount);
	
        _accountCTIssued[msg.sender] = _accountCTIssued[msg.sender].add(amount);

        emit CTIssuedTransfered(_stage, msg.sender, amount, _etherPrice, usdAmount);
        return true;
    }

 

     
    function transferCTWhitelisted(uint256 amount) private returns (bool) {
      
		_CTBonusTxs = _CTBonusTxs.add(1) ;
		
		uint256 __stageCtCap = STAGE_CT_CAP_STEP; 
	    
	    uint256 __remainCT = amount; 
      
	    while (_stageCTIssued[_stage].add(__remainCT) >= __stageCtCap) {
            
            uint256 __transferCT = __stageCtCap.sub(_stageCTIssued[_stage]);
            
                
            _stageCTIssued[_stage] = _stageCTIssued[_stage].add(__transferCT);
            __remainCT = __remainCT.sub(__transferCT);
            
            assert(closeStage());
            
        }
        
        _stageCTIssued[_stage] = _stageCTIssued[_stage].add(__remainCT);
        
        _CTWhitelist = _CTWhitelist.add(amount);
		
        _accountCTWhitelisted[msg.sender] = _accountCTWhitelisted[msg.sender].add(amount);
        
		_CTIssued = _CTIssued.add(amount);
		_CTBonus =  _CTBonus.add(amount);
        
        emit CTWhitelistTransfered(msg.sender, amount);
        return true;
    }

     
    function closeStage() private returns (bool) {
        emit StageClosed(_stage, msg.sender);
        _stage = _stage.add(1);
        _CTUsdPrice = stageCTUsdPrice(_stage);
        
        if(_stage>=STAGE_MAX)
        {
            _stage = STAGE_MAX.sub(1);
        }
       
        return true;
    }
    
    
     
    function sendWhitelistReferralRewards(uint256 ctIssued) private {
        uint256 __ctIssued = ctIssued;
         
        for (uint16 i = 0; i < _rewards_.length; i++) {
			
            uint256 __ctReward = __ctIssued.mul(_rewards_[i]).div(100);
            
            assert(CT.transfer(_referrers_[i], __ctReward));
            
            transferCTWhitelisted(__ctReward);
            _ctRefRewarded = _ctRefRewarded.add(__ctReward);
            _CTWhitelistTxs = _CTWhitelistTxs.add(1);
            _stageCTRewarded[_stage] = _stageCTRewarded[_stage].add(__ctReward);
            
            _stageCTRewardedTx[_stage] = _stageCTRewardedTx[_stage].add(1);
		
            
        }

       
    }
}