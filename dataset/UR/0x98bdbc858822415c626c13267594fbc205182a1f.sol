 

pragma solidity ^0.4.24;

interface MilAuthInterface {
    function requiredSignatures() external view returns(uint256);
    function requiredDevSignatures() external view returns(uint256);
    function adminCount() external view returns(uint256);
    function devCount() external view returns(uint256);
    function adminName(address _who) external view returns(bytes32);
    function isAdmin(address _who) external view returns(bool);
    function isDev(address _who) external view returns(bool);
    function checkGameRegiester(address _gameAddr) external view returns(bool);
    function checkGameClosed(address _gameAddr) external view returns(bool);
}
interface MillionaireInterface {
    function invest(address _addr, uint256 _affID, uint256 _mfCoin, uint256 _general) external payable;
    function updateGenVaultAndMask(address _addr, uint256 _affID) external payable;
    function clearGenVaultAndMask(address _addr, uint256 _affID, uint256 _eth, uint256 _milFee) external;
    function assign(address _addr) external payable;
    function splitPot() external payable;   
}
interface MilFoldInterface {
    function addPot() external payable;
    function activate() external;    
}

contract Milevents {

     
    event onNewPlayer
    (
        address indexed playerAddress,
        uint256 playerID,
        uint256 timeStamp
    );

     
    event onEndTx
    (
        uint256 rid,                     
        address indexed buyerAddress,    
        uint256 compressData,            
        uint256 eth,                     
        uint256 totalPot,                
        uint256 tickets,                 
        uint256 timeStamp                
    );

     
    event onGameClose
    (
        address indexed gameAddr,        
        uint256 amount,                  
        uint256 timeStamp                
    );

     
    event onReward
    (
        address indexed         rewardAddr,      
        Mildatasets.RewardType  rewardType,      
        uint256 amount                           
    );

	 
    event onWithdraw
    (
        address indexed playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onAffiliatePayout
    (
        address indexed affiliateAddress,
        address indexed buyerAddress,
        uint256 eth,
        uint256 timeStamp
    );

     
    event onICO
    (
        address indexed buyerAddress,    
        uint256 buyAmount,               
        uint256 buyMf,                   
        uint256 totalIco,                
        bool    ended                    
    );

     
    event onPlayerWin(
        address indexed addr,
        uint256 roundID,
        uint256 winAmount,
        uint256 winNums
    );

    event onClaimWinner(
        address indexed addr,
        uint256 winnerNum,
        uint256 totalNum
    );

    event onBuyMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onSellMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onUpdateGenVault(
        address indexed addr,
        uint256 mfAmount,
        uint256 genAmount,
        uint256 ethAmount
    );
}

contract Millionaire is MillionaireInterface,Milevents {
    using SafeMath for *;
    using MFCoinsCalc for uint256;

 
 
 
 
    string  constant private    name_ = "Millionaire Official";
    uint256 constant private    icoRndMax_ = 2 weeks;         
    uint256 private             icoEndtime_;                     
    uint256 private             icoAmount_;                      
    uint256 private             sequence_;                       
    bool    private             activated_;                      
    bool    private             icoEnd_;                         

    MilFoldInterface     public          milFold_;                        
    MilAuthInterface constant private milAuth_ = MilAuthInterface(0xf856f6a413f7756FfaF423aa2101b37E2B3aFFD9);

    uint256     public          globalMask_;                     
    uint256     public          mfCoinPool_;                     
    uint256     public          totalSupply_;                    

    address constant private fundAddr_ = 0xB0c7Dc00E8A74c9dEc8688EFb98CcB2e24584E3B;  
    uint256 constant private REGISTER_FEE = 0.01 ether;          
    uint256 constant private MAX_ICO_AMOUNT = 3000 ether;        

    mapping(address => uint256) private balance_;                
    mapping(uint256 => address) private plyrAddr_;              
    mapping(address => Mildatasets.Player) private plyr_;       

 
 
 
 
     
    modifier isActivated() {
        require(activated_ == true, "its not ready start");
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
        require(_eth >= 0.1 ether, "must > 0.1 ether");
        _;
    }

     
    modifier onlyDevs()
    {
        require(milAuth_.isDev(msg.sender) == true, "msg sender is not a dev");
        _;
    }

     
    function()
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        icoCore(msg.value);
    }

     
    function buyICO()
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        icoCore(msg.value);
    }

    function icoCore(uint256 _eth) private {
        if (icoEnd_) {
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
        } else {
            if (block.timestamp > icoEndtime_ || icoAmount_ >= MAX_ICO_AMOUNT) {
                plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
                icoEnd_ = true;

                milFold_.activate();
                emit onICO(msg.sender, 0, 0, MAX_ICO_AMOUNT, icoEnd_);
            } else {
                uint256 ethAmount = _eth;
                if (ethAmount + icoAmount_ > MAX_ICO_AMOUNT) {
                    ethAmount = MAX_ICO_AMOUNT.sub(icoAmount_);
                    plyr_[msg.sender].eth = _eth.sub(ethAmount);
                }
                icoAmount_ = icoAmount_.add(ethAmount);

                uint256 converts = ethAmount.mul(65)/100;
                uint256 pot = ethAmount.sub(converts);

                 
                uint256 buytMf = buyMFCoins(msg.sender, converts);

                 
                milFold_.addPot.value(pot)();

                if (icoAmount_ >= MAX_ICO_AMOUNT) {
                    icoEnd_ = true;

                    milFold_.activate();
                }
                emit onICO(msg.sender, ethAmount, buytMf, icoAmount_, icoEnd_);
            }
        }
    }

     
    function withdraw()
        public
        isActivated()
        isHuman()
    {
        updateGenVault(msg.sender);
        if (plyr_[msg.sender].eth > 0) {
            uint256 amount = plyr_[msg.sender].eth;
            plyr_[msg.sender].eth = 0;
            msg.sender.transfer(amount);
            emit onWithdraw(
                msg.sender,
                amount,
                block.timestamp
            );
        }
    }

     
    function registerAff()
        public
        isHuman()
        payable
    {
        require (msg.value >= REGISTER_FEE, "register affiliate fees must >= 0.01 ether");
        require (plyr_[msg.sender].playerID == 0, "you already register!");
        plyrAddr_[++sequence_] = msg.sender;
        plyr_[msg.sender].playerID = sequence_;
        fundAddr_.transfer(msg.value);
        emit onNewPlayer(msg.sender,sequence_, block.timestamp);
    }

    function setMilFold(address _milFoldAddr)
        public
        onlyDevs
    {
        require(address(milFold_) == 0, "milFold has been set");
        require(_milFoldAddr != 0, "milFold is invalid");

        milFold_ = MilFoldInterface(_milFoldAddr);
    }

    function activate()
        public
        onlyDevs
    {
        require(address(milFold_) != 0, "milFold has not been set");
        require(activated_ == false, "ICO already activated");

         
        activated_ = true;
        icoEndtime_ = block.timestamp + icoRndMax_;
    }

     
    function invest(address _addr, uint256 _affID, uint256 _mfCoin, uint256 _general)
        external
        isActivated()
        payable
    {
        require(milAuth_.checkGameRegiester(msg.sender), "game no register");
        require(_mfCoin.add(_general) <= msg.value, "account is insufficient");

        if (msg.value > 0) {
            uint256 tmpAffID = 0;
            if (_affID == 0 || plyrAddr_[_affID] == _addr) {
                tmpAffID = plyr_[_addr].laff;
            } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
                plyr_[_addr].laff = _affID;
                tmpAffID = _affID;
            }
            
             
            uint256 _affiliate = msg.value.sub(_mfCoin).sub(_general);
            if (tmpAffID > 0 && _affiliate > 0) {
                address affAddr = plyrAddr_[tmpAffID];
                plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(_affiliate);
                plyr_[affAddr].eth = plyr_[affAddr].eth.add(_affiliate);
                emit onAffiliatePayout(affAddr, _addr, _affiliate, block.timestamp);
            }

            if (totalSupply_ > 0) {
                uint256 delta = _general.mul(1 ether).div(totalSupply_);
                globalMask_ = globalMask_.add(delta);
            } else {
                 
                fundAddr_.transfer(_general);
            }

            updateGenVault(_addr);
            
            buyMFCoins(_addr, _mfCoin);

            emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
        }
    }

     
    function calcUnMaskedEarnings(address _addr)
        private
        view
        returns(uint256)
    {
        uint256 diffMask = globalMask_.sub(plyr_[_addr].mask);
        if (diffMask > 0) {
            return diffMask.mul(balance_[_addr]).div(1 ether);
        }
    }

     
    function updateGenVaultAndMask(address _addr, uint256 _affID)
        external
        payable
    {
        require(msg.sender == address(milFold_), "no authrity");

        if (msg.value > 0) {
             
            uint256 converts = msg.value.mul(50).div(80);

            uint256 tmpAffID = 0;
            if (_affID == 0 || plyrAddr_[_affID] == _addr) {
                tmpAffID = plyr_[_addr].laff;
            } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
                plyr_[_addr].laff = _affID;
                tmpAffID = _affID;
            }
            uint256 affAmount = 0;
            if (tmpAffID > 0) {
                affAmount = msg.value.mul(10).div(80);
                address affAddr = plyrAddr_[tmpAffID];
                plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(affAmount);
                plyr_[affAddr].eth = plyr_[affAddr].eth.add(affAmount);
                emit onAffiliatePayout(affAddr, _addr, affAmount, block.timestamp);
            }
            if (totalSupply_ > 0) {
                uint256 delta = msg.value.sub(converts).sub(affAmount).mul(1 ether).div(totalSupply_);
                globalMask_ = globalMask_.add(delta);
            } else {
                 
                fundAddr_.transfer(msg.value.sub(converts).sub(affAmount));
            }
            
            updateGenVault(_addr);
            
            buyMFCoins(_addr, converts);

            emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
        }
    }

     
    function clearGenVaultAndMask(address _addr, uint256 _affID, uint256 _eth, uint256 _milFee)
        external
    {
        require(msg.sender == address(milFold_), "no authrity");

         
        uint256 _earnings = calcUnMaskedEarnings(_addr);
        require(plyr_[_addr].eth.add(_earnings) >= _eth, "eth balance not enough");
        
         
        uint256 converts = _milFee.mul(50).div(80);
        
        uint256 tmpAffID = 0;
        if (_affID == 0 || plyrAddr_[_affID] == _addr) {
            tmpAffID = plyr_[_addr].laff;
        } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
            plyr_[_addr].laff = _affID;
            tmpAffID = _affID;
        }
        
        uint256 affAmount = 0;
        if (tmpAffID > 0) {
            affAmount = _milFee.mul(10).div(80);
            address affAddr = plyrAddr_[tmpAffID];
            plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(affAmount);
            plyr_[affAddr].eth = plyr_[affAddr].eth.add(affAmount);

            emit onAffiliatePayout(affAddr, _addr, affAmount, block.timestamp);
        }
        if (totalSupply_ > 0) {
            uint256 delta = _milFee.sub(converts).sub(affAmount).mul(1 ether).div(totalSupply_);
            globalMask_ = globalMask_.add(delta);
        } else {
             
            fundAddr_.transfer(_milFee.sub(converts).sub(affAmount));
        }

        updateGenVault(_addr);
        
        buyMFCoins(_addr,converts);

        plyr_[_addr].eth = plyr_[_addr].eth.sub(_eth);
        milFold_.addPot.value(_eth.sub(_milFee))();

        emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
    }


     
    function updateGenVault(address _addr) private
    {
        uint256 _earnings = calcUnMaskedEarnings(_addr);
        if (_earnings > 0) {
            plyr_[_addr].mask = globalMask_;
            plyr_[_addr].genTotal = plyr_[_addr].genTotal.add(_earnings);
            plyr_[_addr].eth = plyr_[_addr].eth.add(_earnings);
        } else if (globalMask_ > plyr_[_addr].mask) {
            plyr_[_addr].mask = globalMask_;
        }
        
    }
    
     
    function buyMFCoins(address _addr, uint256 _eth) private returns(uint256) {
        uint256 _coins = calcCoinsReceived(_eth);
        mfCoinPool_ = mfCoinPool_.add(_eth);
        totalSupply_ = totalSupply_.add(_coins);
        balance_[_addr] = balance_[_addr].add(_coins);

        emit onBuyMFCoins(_addr, _eth, _coins, now);
        return _coins;
    }

     
    function sellMFCoins(uint256 _coins) public {
        require(icoEnd_, "ico phase not end");
        require(balance_[msg.sender] >= _coins, "coins amount is out of range");

        updateGenVault(msg.sender);
        
        uint256 _eth = totalSupply_.ethRec(_coins);
        mfCoinPool_ = mfCoinPool_.sub(_eth);
        totalSupply_ = totalSupply_.sub(_coins);
        balance_[msg.sender] = balance_[msg.sender].sub(_coins);

        if (milAuth_.checkGameClosed(address(milFold_))) {
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
        } else {
             
            uint256 earnAmount = _eth.mul(90).div(100);
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(earnAmount);
    
            milFold_.addPot.value(_eth.sub(earnAmount))();
        }
        
        emit onSellMFCoins(msg.sender, earnAmount, _coins, now);
    }

     
    function assign(address _addr)
        external
        payable
    {
        require(msg.sender == address(milFold_), "no authrity");

        plyr_[_addr].eth = plyr_[_addr].eth.add(msg.value);
    }

     
    function splitPot()
        external
        payable
    {
        require(milAuth_.checkGameClosed(msg.sender), "game has not been closed");
        
        uint256 delta = msg.value.mul(1 ether).div(totalSupply_);
        globalMask_ = globalMask_.add(delta);
        emit onGameClose(msg.sender, msg.value, now);
    }

     
    function getIcoInfo()
        public
        view
        returns(uint256, uint256, bool) {
        return (icoAmount_, icoEndtime_, icoEnd_);
    }

     
    function getPlayerAccount(address _addr)
        public
        isActivated()
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        uint256 genAmount = calcUnMaskedEarnings(_addr);
        return (
            plyr_[_addr].playerID,
            plyr_[_addr].eth.add(genAmount),
            balance_[_addr],
            plyr_[_addr].genTotal.add(genAmount),
            plyr_[_addr].affTotal
        );
    }

     
    function calcCoinsReceived(uint256 _eth)
        public
        view
        returns(uint256)
    {
        return mfCoinPool_.keysRec(_eth);
    }

     
    function calcEthReceived(uint256 _coins)
        public
        view
        returns(uint256)
    {
        if (totalSupply_ < _coins) {
            return 0;
        }
        return totalSupply_.ethRec(_coins);
    }

    function getMFBalance(address _addr)
        public
        view
        returns(uint256) {
        return balance_[_addr];
    }

}

 
 
 
 
library Mildatasets {

     
    enum RoundState {
        UNKNOWN,         
        STARTED,         
        STOPPED,         
        DRAWN,           
        ASSIGNED         
    }

     
    enum TxAction {
        UNKNOWN,         
        BUY,             
        DRAW,            
        ASSIGN,          
        ENDROUND         
    }

     
    enum RewardType {
        UNKNOWN,         
        DRAW,            
        ASSIGN,          
        END,             
        CLIAM            
    }

    struct Player {
        uint256 playerID;        
        uint256 eth;             
        uint256 mask;            
        uint256 genTotal;        
        uint256 affTotal;        
        uint256 laff;            
    }

    struct Round {
        uint256                         roundDeadline;       
        uint256                         claimDeadline;       
        uint256                         pot;                 
        uint256                         blockNumber;         
        RoundState                      state;               
        uint256                         drawCode;            
        uint256                         totalNum;            
        mapping (address => uint256)    winnerNum;           
        address[]                       winners;             
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

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}

 
 
 
 
library MFCoinsCalc {
    using SafeMath for *;
     
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return (((((_eth).mul(1000000000000000000).mul(2000000000000000000000000000)).add(39999800000250000000000000000000000000000000000000000000000000000)).sqrt()).sub(199999500000000000000000000000000)) / (1000000000);
    }

     
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((500000000).mul(_keys.sq()).add(((399999000000000).mul(_keys.mul(1000000000000000000))) / (2) )) / ((1000000000000000000).sq());
    }
}