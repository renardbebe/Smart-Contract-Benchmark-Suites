 

pragma solidity ^0.4.23;

 
contract Token {
    string public symbol = "";
    string public name = "";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 0;
    address owner = 0;
    bool setupDone = false;
   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
    function SetupToken(string tokenName, string tokenSymbol, uint256 tokenSupply);
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
    function approve(address _spender, uint256 _amount) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 

contract IBCLottery
{
    uint256 private ticketPrice_;
    
     
    mapping(address => Ticket) internal ticketRecord_;
    
    Token public ibcToken_;
    
    address public officialWallet_;
    address public devATeamWallet_;
    address public devBTeamWallet_;
    
     
    uint256 public tokenRaised_;
    uint256 public actualTokenRaised_;
    mapping(address => uint256) public userPaidIn_;
    
     
     
     
     
     
    constructor(
        address _ibcoin,
        address _officialWallet,
        address _devATeamWallet,
        address _devBTeamWallet
    )
        public
    {
        ibcToken_ = Token(_ibcoin);
        officialWallet_ = _officialWallet;
        devATeamWallet_ = _devATeamWallet;
        devBTeamWallet_ = _devBTeamWallet;
    }
    
     
     
    event BuyTicket(
        address indexed buyer,
        uint256 price
    );
     
      
     
    modifier onlyBoughtTicket(
        address _user,
        uint256 _timeLeft
    )
    {
        require(hasValidTicketCore(_user, _timeLeft), "You don't have ticket yet!");
        _;
    }
    
     
    
    function buyTicketCore(
        uint256 _pot,
        uint256 _timeLeft,
        address _user
    )
        internal
        returns
        (bool)
    {
        if(!hasValidTicketCore(_user, _timeLeft)) {
            if (_timeLeft == 0) return false;
             
            uint256 _allowance = ibcToken_.allowance(_user, this);
            
             
            require(_allowance > 0, "Please approve token to this contract.");
            
             
            uint256 _ticketPrice = calculateTicketPrice(_pot, _timeLeft);
            
             
            require(_allowance >= _ticketPrice, "Insufficient allowance for this contract.");
            
             
            require(ibcToken_.transferFrom(_user, this, _ticketPrice));
            
             
            tokenRaised_ = tokenRaised_ + _ticketPrice;
            
             
            ticketRecord_[_user].hasTicket = true;
            ticketRecord_[_user].expirationTime = now + 30 minutes;
            ticketRecord_[_user].ticketPrice = _ticketPrice;
            
            emit BuyTicket(_user, _ticketPrice);
        }
        return true;
    }
    
    function hasValidTicketCore(
        address _user,
        uint256 _timeLeft
    )
        view
        internal
        returns
        (bool)
    {
        if (_timeLeft == 0) return false;
        bool _hasTicket = ticketRecord_[_user].hasTicket;
        uint256 _expirationTime = ticketRecord_[_user].expirationTime;
        
        return (_hasTicket && now <= _expirationTime);
    }
    
    function calculateTicketPrice(
        uint256 _pot,
        uint256 _timeLeft
    ) 
        pure
        internal
        returns
        (uint256)
    {
        uint256 _potFixed = _pot / 1000000000000000000;
        
         
        uint256 _leftHour = _timeLeft / 3600;
        
         
         
         
         
        if (_leftHour >= 24) return 1000000000000000000;
        
         
         
         
         
        if (_pot >= 100000000000000000000000000) 
            return 10000000000000000000000000;
        
         
    
        uint256 _gap = 100;
        for(uint8 _step = 0; _step < 7; _gap = _gap * 10) {
            if (_potFixed < _gap) {
                return (_gap / 100) * (8 - (_leftHour / 3)) * 1000000000000000000;
            }    
        }
    }
    
    function getTokenRaised()
        view
        public
        returns
        (uint256, uint256)
    {
         
         
         
        return (
            tokenRaised_, 
            actualTokenRaised_
        );
    }
    
    function getUserPaidIn(
        address _address
    )
        view
        public
        returns
        (uint256)
    {
        return userPaidIn_[_address];
    }
    
    struct Ticket {
        bool hasTicket;
        uint256 expirationTime;
        uint256 ticketPrice;
    }
}

 
contract IBCLotteryEvents {
    
     
    event onEndTx
    (
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount
    );
    
	 
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
    
     
    event onWithdrawAndDistribute
    (
        address playerAddress,
        uint256 ethOut,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
    event onBuyAndDistribute
    (
        address playerAddress,
        uint256 ethIn,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
    event onBuyTicketAndDistribute
    (
        address playerAddress,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
    event onReLoadAndDistribute
    (
        address playerAddress,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
    
    event onRefundTicket
    (
        uint256 indexed playerID,
        uint256 refundAmount
    );
}

 

contract IBCLotteryGame is IBCLotteryEvents, IBCLottery {
    using SafeMath for *;
    using IBCLotteryKeysCalcLong for uint256;
	
     
    
	 
     
     
     
     
    uint256 private rndInit_ = 24 hours;
     
     
     
    uint256 private rndInc_ = 1 minutes;
     
     
     
    uint256 private rndMax_ = 24 hours;
    
     
     
    uint256 private maxUserId_ = 0;
    
    address private owner_;

     
	uint256 public rID_;     

     
    mapping (address => uint256) public pIDxAddr_;           
    mapping (uint256 => IBCLotteryDatasets.Player) public plyr_;    
    mapping (uint256 => IBCLotteryDatasets.PlayerRounds) public plyrRnds_;     

     
    IBCLotteryDatasets.Round round_;    

     
    constructor(
        address _ibcoin,
        address _officialWallet,
        address _devATeamWallet,
        address _devBTeamWallet
    )
        IBCLottery(_ibcoin, _officialWallet, _devATeamWallet, _devBTeamWallet)
        public
    {
        owner_ = msg.sender;
	}
     
     
    modifier isActivated() {
        require(activated_ == true, "Be patient!!!"); 
        _;
    }
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier onlyInRound() {
        require(!round_.ended, "The game has ended");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
    modifier onlyOwner(
        address _address
    ) {
        require(_address == owner_, "You are not owner!!!!");
        _;
    }
    
     
     
    function()
        isActivated()
        onlyInRound()
        isHuman()
        isWithinLimits(msg.value)
        onlyBoughtTicket(msg.sender, getTimeLeft())
        public
        payable
    {
         
        IBCLotteryDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
        uint256 _affID = plyr_[_pID].laff;
        
        core(_pID, msg.value, _affID, _eventData_);
    }
    
     
    
    function buyXaddr(address _affCode)
        isActivated()
        onlyInRound()
        isHuman()
        isWithinLimits(msg.value)
        onlyBoughtTicket(msg.sender, getTimeLeft())
        public
        payable
    {
         
        IBCLotteryDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _affID = pIDxAddr_[_affCode];
         
        if (_affCode == address(0) 
            || _affCode == msg.sender 
            || plyrRnds_[_affID].keys < 1000000000000000000)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
        core(_pID, msg.value, _affID, _eventData_);
    }
    
    function buyTicket()
        onlyInRound()
        public
        returns
        (bool)
    {
        uint256 _now = now;
        if (_now > round_.end && round_.ended == false && round_.plyr != 0) 
        {
            IBCLotteryDatasets.EventReturns memory _eventData_;
            
             
		    round_.ended = true;
            _eventData_ = endRound(_eventData_);
            
             
            emit IBCLotteryEvents.onBuyTicketAndDistribute
            (
                msg.sender, 
                _eventData_.winnerAddr, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.genAmount
            );
        } else {
            uint256 _pot = round_.pot;
            uint256 _timeLeft = getTimeLeft();
            return buyTicketCore(_pot, _timeLeft, msg.sender);
        }
    }

     
    function withdraw()
        isActivated()
        isHuman()
        public
    {
         
        uint256 _now = now;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _eth;
        
         
        if (_now > round_.end && round_.ended == false && round_.plyr != 0)
        {
             
            IBCLotteryDatasets.EventReturns memory _eventData_;
            
             
			round_.ended = true;
            _eventData_ = endRound(_eventData_);
            
			 
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
             
            emit IBCLotteryEvents.onWithdrawAndDistribute
            (
                msg.sender, 
                _eth, 
                _eventData_.winnerAddr, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.genAmount
            );
            
         
        } else {
             
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
             
            emit IBCLotteryEvents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
        
        if (now > round_.end && round_.plyr != 0) {
            refundTicket(_pID);
        }
    }

     
     
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
         
        uint256 _now = now;
        
         
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else  
            return ( 75000000000000 );  
    }
    
     
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        
        if (_now < round_.end)
            if (_now > round_.strt)
                return( (round_.end).sub(_now) );
            else
                return( (round_.strt).sub(_now) );
        else
            return(0);
    }
    
     
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256, uint256)
    {
        uint256 _gen;
        uint256 _limiter;
        uint256 _genShow;
         
        if (now > round_.end && round_.ended == false && round_.plyr != 0)
        {
             
            if (round_.plyr == _pID)
            {
                _gen = (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID).sub(plyrRnds_[_pID].mask));
                _limiter = (plyrRnds_[_pID].eth.mul(22) / 10);
                _genShow = 0;
                
                if (plyrRnds_[_pID].genWithdraw.add(_gen) > _limiter) {
                    _genShow = _limiter - plyrRnds_[_pID].genWithdraw;
                } else {
                    _genShow = _gen;
                }
                
                return
                (
                    (plyr_[_pID].win).add( ((round_.pot).mul(2)) / 5 ).add(getFinalDistribute(_pID)),
                    _genShow,
                    plyr_[_pID].aff,
                    plyr_[_pID].tokenShare.add(getTokenShare(_pID))
                );
             
            } else {
                
                _gen = (plyr_[_pID].gen).add(getPlayerVaultsHelper(_pID).sub(plyrRnds_[_pID].mask));
                _limiter = (plyrRnds_[_pID].eth.mul(22) / 10);
                _genShow = 0;
                
                if (plyrRnds_[_pID].genWithdraw.add(_gen) > _limiter) {
                    _genShow = _limiter - plyrRnds_[_pID].genWithdraw;
                } else {
                    _genShow = _gen;
                }    
                
                return
                (
                    (plyr_[_pID]).win.add(getFinalDistribute(_pID)),
                    _genShow,
                    plyr_[_pID].aff,
                    plyr_[_pID].tokenShare.add(getTokenShare(_pID))
                );
            }
            
         
        } else {
            _gen = (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID)) ;
            _limiter = (plyrRnds_[_pID].eth.mul(22) / 10);
            _genShow = 0;
            
            if (plyrRnds_[_pID].genWithdraw.add(_gen) > _limiter) {
                _genShow = _limiter - plyrRnds_[_pID].genWithdraw;
            } else {
                _genShow = _gen;
            }  
            
            return
            (
                plyr_[_pID].win.add(getFinalDistribute(_pID)),
                _genShow,
                plyr_[_pID].aff,
                plyr_[_pID].tokenShare.add(getTokenShare(_pID))
            );
        }
    }
    
     
    function getPlayerVaultsHelper(uint256 _pID)
        private
        view
        returns(uint256)
    {
        return(  (((round_.mask).mul(plyrRnds_[_pID].keys)) / 1000000000000000000)  );
    }
    
    function getFinalDistribute(uint256 _pID)
        private
        view
        returns(uint256)
    {
        uint256 _now = now;
        
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
        {
            return 0;
        }
        
        uint256 _boughtTime = plyrRnds_[_pID].boughtTime;
        
        if(_boughtTime == 0) return 0;
        
        uint256 _firstKeyShare = round_.firstKeyShare;
        
        uint256 _eachKeyCanShare = round_.eachKeyCanShare;
        uint256 _totalKeyCanShare = 0;
        for (uint256 _bought = _boughtTime; _bought > 0; _bought --) {
            uint256 _lastKey = plyrRnds_[_pID].boughtRecord[_bought].lastKey;
            if (_lastKey < _firstKeyShare) break;
            uint256 _amount = plyrRnds_[_pID].boughtRecord[_bought].amount;
            uint256 _firstKey = _lastKey - _amount;
            if (_firstKey > _firstKeyShare) {
                _totalKeyCanShare = _totalKeyCanShare.add(_amount);
            } else {
                _totalKeyCanShare = _totalKeyCanShare.add(_lastKey - _firstKeyShare);
            }
        }
        return (_totalKeyCanShare.mul(_eachKeyCanShare) / 1000000000000000000);
    }
    
    function getTokenShare(uint256 _pID) 
        private
        view
        returns(uint256)
    {
        uint256 _now = now;
        
        if(plyrRnds_[_pID].tokenShareCalc) {
            return 0;
        }
        
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
        {
            return 0;   
        }
        
        address _address = plyr_[_pID].addr;
        uint256 _userPaidIn = userPaidIn_[_address];
        
        return ((round_.tokenShare.mul(_userPaidIn)) / 1000000000000000000);
    }
    
    
     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
        (uint256 _tokenRaised, uint256 _tokenActualRaised) = getTokenRaised();
        
        return
        (
            round_.keys,               
            round_.end,                
            round_.strt,               
            round_.pot,                
            round_.plyr,      
            plyr_[round_.plyr].addr,   
            _tokenRaised,  
            _tokenActualRaised  
        );
    }

     
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        uint256 _gen = (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID));
        uint256 _limiter = (plyrRnds_[_pID].eth.mul(22) / 10);
        uint256 _genShow = 0;
        
        if (plyrRnds_[_pID].genWithdraw.add(_gen) > _limiter) {
            _genShow = _limiter - plyrRnds_[_pID].genWithdraw;
        } else {
            _genShow = _gen;
        } 
        
        return
        (
            _pID,                                
            plyrRnds_[_pID].keys,          
            plyr_[_pID].win,                     
            _genShow,        
            plyr_[_pID].aff,                     
            plyr_[_pID].tokenShare,              
            plyrRnds_[_pID].eth            
        );
    }

     
    
     
    function core(uint256 _pID, uint256 _eth, uint256 _affID, IBCLotteryDatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
         
        
         
        uint256 _keys = (round_.eth).keysRec(_eth);
        uint256 _keyBonus = getKeyBonus();
        
        _keys = (_keys.mul(_keyBonus) / 10);
        
         
        if (_keys >= 1000000000000000000 && _keyBonus == 10)
        {
            updateTimer(_keys);

             
            if (round_.plyr != _pID)
                round_.plyr = _pID;  
        }
        
         
        if (round_.overEarningMask > 0) {
            plyrRnds_[_pID].mask = plyrRnds_[_pID].mask.add(
                (round_.overEarningMask.mul(_keys) / 1000000000000000000)
            );
        }
        
         
        plyrRnds_[_pID].keys = _keys.add(plyrRnds_[_pID].keys);
        plyrRnds_[_pID].eth = _eth.add(plyrRnds_[_pID].eth);
        
         
        round_.keys = _keys.add(round_.keys);
        round_.eth = _eth.add(round_.eth);
        
        uint256 _boughtTime = plyrRnds_[_pID].boughtTime + 1;
        plyrRnds_[_pID].boughtTime = _boughtTime;
        
        plyrRnds_[_pID].boughtRecord[_boughtTime].lastKey = round_.keys;
        plyrRnds_[_pID].boughtRecord[_boughtTime].amount = _keys;

         
        _eventData_ = distributeExternal(_pID, _eth, _affID, _eventData_);
        _eventData_ = distributeInternal(_pID, _eth, _keys, _eventData_);
        
         
        endTx(_eth, _keys, _eventData_);
    }
     
     
    function calcUnMaskedEarnings(uint256 _pID)
        private
        view
        returns(uint256)
    {
        return(  (((round_.mask.add(round_.overEarningMask)).mul(plyrRnds_[_pID].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID].mask)  );
    }
    
     
    function calcKeysReceived(uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        
         
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.eth).keysRec(_eth) );
        else  
            return ( (_eth).keys() );
    }
    
     
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        
         
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ( (round_.keys.add(_keys)).ethRec(_keys) );
        else  
            return ( (_keys).eth() );
    }

    function getTicketPrice()
        public
        view
        returns(uint256)
    {
        uint256 _now = now;
         
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
        {
            uint256 _timeLeft = round_.end - now;
            return calculateTicketPrice(round_.pot, _timeLeft);
        }
         
        else {
            return 1000000000000000000;
        }
    }

     
        
     
    function determinePID(IBCLotteryDatasets.EventReturns memory _eventData_)
        private
        returns (IBCLotteryDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0)
        {
            maxUserId_ = maxUserId_ + 1;
            _pID = maxUserId_;
            
             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
        } 
        return (_eventData_);
    }
    
    function getKeyBonus()
        view
        internal
        returns
        (uint256)
    {
        uint256 _timeLeft = getTimeLeft();
        
        if(_timeLeft == 86400) return 10;
        
        uint256 _hoursLeft = _timeLeft / 3600;
        uint256 _minutesLeft = (_timeLeft % 3600) / 60;
        
        if(_minutesLeft <= 59 && _minutesLeft >= 5) return 10;
        
        uint256 _flag = 0;
        if (_hoursLeft <= 24 && _hoursLeft >= 12) {
            _flag = 3;
        } else {
            _flag = 6;
        }
        
        uint256 _randomNumber = getRandomNumber() % _flag;
        
        return ((5*_randomNumber) + 15);
    }
    
     
    function managePlayer(uint256 _pID, IBCLotteryDatasets.EventReturns memory _eventData_)
        private
        returns (IBCLotteryDatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID);
            
         
        plyr_[_pID].lrnd = rID_;
        
        return(_eventData_);
    }
    
     
    function endRound(IBCLotteryDatasets.EventReturns memory _eventData_)
        private
        returns (IBCLotteryDatasets.EventReturns)
    {
        
         
        uint256 _winPID = round_.plyr;
        
         
        uint256 _pot = round_.pot;
        
         
         
         
         
        uint256 _win = ((_pot.mul(2)) / 5);
        
         
        uint256 tokenBackToTeam = tokenRaised_ - actualTokenRaised_;
        if (tokenBackToTeam > 0) {
            ibcToken_.transfer(officialWallet_, tokenBackToTeam / 2);
            ibcToken_.transfer(devATeamWallet_, tokenBackToTeam / 2);
        }
        
         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        
            
         
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.amountWon = _win;
        
        return(_eventData_);
    }
    
     
    function updateGenVault(uint256 _pID)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID);
        if (_earnings > 0)
        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds_[_pID].mask = _earnings.add(plyrRnds_[_pID].mask);
        }
    }
    
    function updateFinalDistribute(uint256 _pID)
        private
    {
        uint256 _now = now;
        if (!(_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0))))
        {
            plyr_[_pID].win = plyr_[_pID].win + getFinalDistribute(_pID);
            plyrRnds_[_pID].boughtTime = 0;
        }
    }
    
    function updateTokenShare(uint256 _pID)
        internal
    {
        uint256 _now = now;
        if (!(_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0))))
        {
            if (!plyrRnds_[_pID].tokenShareCalc) {
                plyr_[_pID].tokenShare = plyr_[_pID].tokenShare + getTokenShare(_pID);
                plyrRnds_[_pID].tokenShareCalc = true;
            }
        }
    }
    
     
    function updateTimer(uint256 _keys)
        private
    {
         
        uint256 _now = now;
        
         
        uint256 _newTime;
        if (_now > round_.end && round_.plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_.end);
        
         
        if (_newTime < (rndMax_).add(_now))
            round_.end = _newTime;
        else
            round_.end = rndMax_.add(_now);
    }

     
    function distributeExternal(uint256 _pID, uint256 _eth, uint256 _affID, IBCLotteryDatasets.EventReturns memory _eventData_)
        private 
        returns(IBCLotteryDatasets.EventReturns)
    {
        
         
         
         
        uint256 _aff = ((_eth).mul(88) / 500);
        
         
         
         
         
         
         
        if (_affID != _pID && _affID != 0) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit IBCLotteryEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, _pID, _aff, now);
        } else if (!round_.firstPlayerIn){
             
            devATeamWallet_.transfer(_aff);
            round_.firstPlayerIn = true;
            emit IBCLotteryEvents.onAffiliatePayout(0, devATeamWallet_, _pID, _aff, now);
        } else {
             
             
            devBTeamWallet_.transfer(_aff);
            emit IBCLotteryEvents.onAffiliatePayout(0, devBTeamWallet_, _pID, _aff, now);
        }
        
        return(_eventData_);
    }
    
     
    function distributeInternal(uint256 _pID, uint256 _eth, uint256 _keys, IBCLotteryDatasets.EventReturns memory _eventData_)
        private
        returns(IBCLotteryDatasets.EventReturns)
    {
         
         
        uint256 _gen = (_eth.mul(3960) / 10000);
        
         
         
         
         
        
         
         
        uint256 _pot = _pot.add((_eth.mul(88)) / 400);
        
         
         
        uint256 _dust = updateMasks(_pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
         
        round_.pot = _pot.add(_dust).add(round_.pot);
        
         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }
    
    function refundTicket(uint256 _pID)
        public
    {
        address _playerAddress = plyr_[_pID].addr;
        uint256 _userPaidIn = userPaidIn_[_playerAddress];
        
        if (!plyr_[_pID].ibcRefund && _userPaidIn != 0) {
             
            uint256 _refund = userPaidIn_[_playerAddress] / 4;
            plyr_[_pID].ibcRefund = true;
            ibcToken_.transfer(_playerAddress, _refund);
            emit onRefundTicket(
                _pID,
                _refund
            );
        }
    }

     
    function updateMasks(uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         
        
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_.keys);
        round_.mask = _ppt.add(round_.mask);
            
         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID].mask = (((round_.mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID].mask);
        
         
        return(_gen.sub((_ppt.mul(round_.keys)) / (1000000000000000000)));
    }
    
     
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
         
        updateGenVault(_pID);
        updateTokenShare(_pID);
        updateFinalDistribute(_pID);
        
        uint256 _playerGenWithdraw = plyrRnds_[_pID].genWithdraw;
        
        uint256 _limiter = (plyrRnds_[_pID].eth.mul(22) / 10);
        
        uint256 _withdrawGen = 0;
        
        if(_playerGenWithdraw.add(plyr_[_pID].gen) > _limiter) {
            _withdrawGen = _limiter - _playerGenWithdraw;
            
            uint256 _overEarning = _playerGenWithdraw.add(plyr_[_pID].gen) - _limiter;
            round_.overEarningMask = round_.overEarningMask.add(_overEarning.mul(1000000000000000000) / round_.keys);
            for (int i = 0; i < 5; i ++) {
                round_.overEarningMask = round_.overEarningMask.add(_overEarning.mul(1000000000000000000) / round_.keys);
                _overEarning = (round_.overEarningMask.mul(plyrRnds_[_pID].keys) / 1000000000000000000);
            }
            
            plyrRnds_[_pID].genWithdraw = _limiter;
        } else {
            _withdrawGen = plyr_[_pID].gen;
            
            plyrRnds_[_pID].genWithdraw = _playerGenWithdraw.add(plyr_[_pID].gen);
        }
        
         
        uint256 _earnings = (plyr_[_pID].win)
                            .add(_withdrawGen)
                            .add(plyr_[_pID].aff)
                            .add(plyr_[_pID].tokenShare);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
            plyr_[_pID].tokenShare = 0;
        }

        return(_earnings);
    }
    
     
    function endTx(uint256 _eth, uint256 _keys, IBCLotteryDatasets.EventReturns memory _eventData_)
        private
    {
        uint256 _pot = round_.pot;
        
        round_.firstKeyShare = ((round_.keys.mul(95)) / 100);
        uint256 _finalShareAmount = (round_.keys).sub(round_.firstKeyShare);
        round_.eachKeyCanShare = ((((_pot * 3) / 5).mul(1000000000000000000)) / _finalShareAmount);
        
        uint256 _ticketPrice = ticketRecord_[msg.sender].ticketPrice;
        
        userPaidIn_[msg.sender] = userPaidIn_[msg.sender] + _ticketPrice;
        actualTokenRaised_ = actualTokenRaised_ + _ticketPrice;
        
        ibcToken_.transfer(officialWallet_, (_ticketPrice / 2));
        ibcToken_.transfer(devATeamWallet_, (_ticketPrice / 4));
        
         
         
        uint256 totalTokenShare = (((round_.eth).mul(88)) / 1000);
        round_.tokenShare = ((totalTokenShare.mul(1000000000000000000)) / (actualTokenRaised_));
        
        devATeamWallet_.transfer(((_eth.mul(12)) / 100));
        
        ticketRecord_[msg.sender].hasTicket = false;
        
        emit IBCLotteryEvents.onEndTx
        (
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }
    
    function getRandomNumber() 
        view
        internal
        returns
        (uint8)
    {
        uint256 _timeLeft = getTimeLeft();
        return uint8(uint256(keccak256(
            abi.encodePacked(
            block.timestamp, 
            block.difficulty, 
            block.coinbase,
            _timeLeft,
            msg.sender
            )))%256);
    }
    
    function hasValidTicket()
        view
        public
        returns
        (bool)
    {
        address _buyer = msg.sender;
        uint256 _timeLeft = getTimeLeft();
        
        return hasValidTicketCore(_buyer, _timeLeft);
    }
    
     
     
    bool public activated_ = false;
    function activate()
        onlyOwner(msg.sender)
        public
    {
         
        require(activated_ == false, "IBCLottery already activated");
        
         
        activated_ = true;
        
         
		rID_ = 1;
        round_.strt = now;
        round_.end = now + rndInit_;
    }
}

 

library IBCLotteryDatasets {
    struct EventReturns {
        address winnerAddr;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 genAmount;           
        uint256 potAmount;           
    }
    struct Player {
        address addr;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 tokenShare;  
        uint256 lrnd;    
        uint256 laff;    
        bool ibcRefund;
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
        bool tokenShareCalc;  
        mapping(uint256 => BoughtRecord) boughtRecord;
        uint256 boughtTime;
        uint256 genWithdraw;
    }
    struct Round {
        uint256 plyr;    
        bool firstPlayerIn;
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
        uint256 tokenShare;  
        uint256 firstKeyShare;
        uint256 eachKeyCanShare;
        uint256 overEarningMask;
    }
    struct TeamFee {
        uint256 gen;     
    }
    struct BoughtRecord {
        uint256 lastKey;
        uint256 amount;
    }
}

 
library IBCLotteryKeysCalcLong {
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
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
     
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
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