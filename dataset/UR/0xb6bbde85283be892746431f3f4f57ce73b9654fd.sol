 

pragma solidity ^0.4.24;


 
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



 
 
 
 
library F3Ddatasets {
    struct Referee {
        uint256 pID;
        uint256 offer;
    }
    
    struct EventReturns {
        address winnerBigPotAddr;          
        uint256 amountWonBigPot;           

        address winnerSmallPotAddr;          
        uint256 amountWonSmallPot;           

        uint256 newPot;              
        uint256 P3DAmount;           
        uint256 genAmount;           
        uint256 potAmount;           
    }

    struct PlayerVault {
        address addr;    
        uint256 winBigPot;     
        uint256 winSmallPot;     
        uint256 gen;     
        uint256 aff;     
        uint256 lrnd;
    }

    struct PlayerRound {
        uint256 eth;     
        uint256 auc;     
        uint256 keys;    
        uint256 mask;    
        uint256 refID;   
    }

    struct SmallPot {
        uint256 plyr;    
        uint256 end;     
        uint256 strt;    
        uint256 pot;      
        uint256 keys;    
        uint256 eth;    
        bool on;      
    }

    struct BigPot {
        uint256 plyr;    
        uint256 end;     
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 gen;
        uint256 mask;
        uint256 pot;     
        bool ended;      
    }


    struct Auction {
         
        bool isAuction;  
        uint256 end;     
        uint256 strt;    
        uint256 eth;     
        uint256 gen;  
        uint256 keys;    
         
         
    }
}

 
 
 
 
library F3DKeysCalcShort {
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

 
 
 
 




interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
}



contract F3Devents {
    event eventAuction(
        string funName,
        uint256 round,
        uint256 plyr,
        uint256 money,
        uint256 keyPrice,
        uint256 plyrEth,
        uint256 plyrAuc,
        uint256 plyrKeys,
        uint256 aucEth,
        uint256 aucKeys
    );

    event onPot(
        uint256 plyrBP,  
        uint256 ethBP,
        uint256 plyrSP,  
        uint256 ethSP    
    );

}

contract FoMo3DFast is F3Devents {
    using SafeMath for *;
     
     
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x77ae3DEC9462C8Ac8F1e6D222C1785B5250F0F62);

    address private admin = msg.sender;
    uint256 private prepareTime = 30 minutes;
    uint256 private aucDur = 120 minutes;      
     
    uint256 constant private rndInc_ = 360 seconds;               
    uint256 constant private smallTime_ = 5 minutes;               
    uint256 constant private rndMax_ = 10080 minutes;                 
    uint256 public rID_;     
    uint256 constant public keyPriceAuc_ = 5000000000000000;
    uint256 constant public keyPricePot_ = 10000000000000000;
     
     
     
    mapping(address => uint256) public pIDxAddr_;           
    mapping(uint256 => F3Ddatasets.PlayerVault) public plyr_;    
     
    mapping(uint256 => mapping(uint256 => F3Ddatasets.PlayerRound)) public plyrRnds_;
     
     
     
    mapping(uint256 => F3Ddatasets.Auction) public auction_;    
    mapping(uint256 => F3Ddatasets.BigPot) public bigPot_;    
    F3Ddatasets.SmallPot public smallPot_;    
    mapping(uint256 => uint256) public rndTmEth_;       


     
    mapping(uint256 => F3Ddatasets.Referee[]) public referees_;
    uint256 minOfferValue_;
    uint256 constant referalSlot_ = 2;

    constructor()
    public
    {

    }
     
     
     
     
     
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
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
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        _;
    }

     
     
     
     
     
    function()
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    public
    payable
    {
         
        determinePID(msg.sender);

         
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _now = now;
        uint256 _rID = rID_;

        if (_now > auction_[_rID].strt && _now < auction_[_rID].end)
        {
             
            buyAuction(_pID);
        } else if (_now > bigPot_[_rID].strt && _now < bigPot_[_rID].end) {
             
            buy(_pID, 9999);
        } else {
             
            if (_now > bigPot_[_rID].end && bigPot_[_rID].ended == false)
            {
                 
                bigPot_[_rID].ended = true;
                endRound();
            }

             
            plyr_[_pID].gen = msg.value.add(plyr_[_pID].gen);
        }
    }

    function buyXQR(address _realSender, uint256 _affID)
    isActivated()
    isWithinLimits(msg.value)
    public
    payable
    {
         
        determinePID(_realSender);

         
        uint256 _pID = pIDxAddr_[_realSender];
        uint256 _now = now;
        uint256 _rID = rID_;

        if (_now > auction_[_rID].strt && _now < auction_[_rID].end)
        {
             
            buyAuction(_pID);
        } else if (_now > bigPot_[_rID].strt && _now < bigPot_[_rID].end) {
             
            buy(_pID, _affID);
        } else {
             
            if (_now > bigPot_[_rID].end && bigPot_[_rID].ended == false)
            {
                 
                bigPot_[_rID].ended = true;
                endRound();
            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

    function endRound()
    private
    {
         
        uint256 _rID = rID_;

         
        uint256 _winPID = bigPot_[_rID].plyr;

         
        uint256 _win = bigPot_[_rID].pot;
         

         
        plyr_[_winPID].winBigPot = _win.add(plyr_[_winPID].winBigPot);

         
        uint256 _currentPot = smallPot_.eth;
        if (smallPot_.on == true) {
            uint256 _winSmallPot = smallPot_.pot;
            uint256 _surplus = _currentPot.sub(_winSmallPot);
            smallPot_.on = false;
            smallPot_.keys = 0;
            smallPot_.eth = 0;
            smallPot_.pot = 0;
            smallPot_.plyr = 0;
            plyr_[_winPID].winSmallPot = _winSmallPot.add(plyr_[_winPID].winSmallPot);
            if (_surplus > 0) {
                plyr_[1].winSmallPot = _surplus.add(plyr_[1].winSmallPot);
            }
        } else {
            if (_currentPot > 0) {
                plyr_[1].winSmallPot = _currentPot.add(plyr_[1].winSmallPot);
            }
        }


         
        rID_++;
        _rID++;
        uint256 _now = now;
        auction_[_rID].strt = _now;
        auction_[_rID].end = _now + aucDur;

        bigPot_[_rID].strt = _now + aucDur;
        bigPot_[_rID].end = _now + aucDur + rndMax_;
    }

    function withdrawXQR(address _realSender)
    payable
    isActivated()
    public
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        uint256 _pID = pIDxAddr_[_realSender];

         
        uint256 _eth;

         
        if (_now > bigPot_[_rID].end && bigPot_[_rID].ended == false && bigPot_[_rID].plyr != 0)
        {
             
            bigPot_[_rID].ended = true;
            endRound();

             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
        } else {
             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

        }
    }

    function withdrawEarnings(uint256 _pID)
    private
    returns (uint256)
    {
        updateGenVault(_pID, plyr_[_pID].lrnd);
         
        uint256 _earnings = (plyr_[_pID].winBigPot).add(plyr_[_pID].winSmallPot).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].winBigPot = 0;
            plyr_[_pID].winSmallPot = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }
        return (_earnings);
    }

    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return( (((bigPot_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask) );
    }

    function managePlayer(uint256 _pID)
        private
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
            
         
        plyr_[_pID].lrnd = rID_;
    }


    function buyAuction(uint256 _pID)
    private
    {
         
        uint256 _rID = rID_;
        uint256 _keyPrice = keyPriceAuc_;

         
        if (plyrRnds_[_pID][_rID].keys == 0)
            managePlayer(_pID);
        
         
        bigPot_[_rID].plyr = _pID;

        uint256 _eth = msg.value;
         
        uint256 _keys = _eth / _keyPrice;

         
        plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
        plyrRnds_[_pID][_rID].auc = _eth.add(plyrRnds_[_pID][_rID].auc);
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);

        uint256 plyrEth = plyrRnds_[_pID][_rID].eth;
        uint256 plyrAuc = plyrRnds_[_pID][_rID].auc;
        uint256 plyrKeys = plyrRnds_[_pID][_rID].keys;

         
        auction_[_rID].eth = auction_[_rID].eth.add(_eth);
        auction_[_rID].keys = auction_[_rID].keys.add(_keys);
        uint256 aucEth = auction_[_rID].eth;
        uint256 aucKeys = auction_[_rID].keys;

        emit eventAuction
        (
            "buyFunction",
            _rID,
            _pID,
            _eth,
            _keyPrice,
            plyrEth,
            plyrAuc,
            plyrKeys,
            aucEth,
            aucKeys
        );

         
        refereeCore(_pID, plyrRnds_[_pID][_rID].auc);

         
        distributeAuction(_rID, _eth);
    }

    function distributeAuction(uint256 _rID, uint256 _eth)
    private
    {
         
        uint256 _team = _eth / 2;
        uint256 _pot = _eth.sub(_team);
         
        uint256 _bigPot = _pot / 2;
         
        uint256 _smallPot = _pot / 2;

         
        admin.transfer(_team);

         
        bigPot_[_rID].pot = bigPot_[_rID].pot.add(_bigPot);
        smallPot_.pot = smallPot_.pot.add(_smallPot);
        emit onPot(bigPot_[_rID].plyr, bigPot_[_rID].pot, smallPot_.plyr, smallPot_.pot);
    }

    function buy(uint256 _pID, uint256 _affID)
    private
    {
         
        uint256 _rID = rID_;
        uint256 _keyPrice = keyPricePot_;

        if (plyrRnds_[_pID][_rID].keys == 0)
            managePlayer(_pID);

        uint256 _eth = msg.value;

        uint256 _keys = _eth / _keyPrice;

        if (_eth > 1000000000)
        {
             
            if (_eth >= 1000000000000000000)
            {
                updateTimer(_eth, _rID);
                 
                if (bigPot_[_rID].plyr != _pID)
                    bigPot_[_rID].plyr = _pID;
            }


             
            bigPot_[_rID].keys = _keys.add(bigPot_[_rID].keys);
            bigPot_[_rID].eth = _eth.add(bigPot_[_rID].eth);

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            uint256 _gen = _eth.mul(6) / 10;
            updateMasks(_rID, _pID, _gen, _keys);
             
             

            distributeBuy(_rID, _eth, _affID);
            smallPot();
        }
    }

    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (bigPot_[_rID].keys);
        bigPot_[_rID].mask = _ppt.add(bigPot_[_rID].mask); 
            
         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((bigPot_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
         
        return(_gen.sub((_ppt.mul(bigPot_[_rID].keys)) / (1000000000000000000)));
    }

    function distributeBuy(uint256 _rID, uint256 _eth, uint256 _affID)
    private
    {
         
        uint256 _team = _eth / 10;
         
        uint256 _aff = _eth / 10;
        if (_affID == 9999) {
            _team = _team.add(_aff);
            _aff = 0;
        }

         
        uint256 _bigPot = _eth / 10;
         
        uint256 _smallPot = _eth / 10;

         
        admin.transfer(_team);

        if (_aff != 0) {
             
            uint256 affPID = referees_[_rID][_affID].pID;
            plyr_[affPID].aff = _aff.add(plyr_[affPID].aff);
        }

         
        bigPot_[_rID].pot = bigPot_[_rID].pot.add(_bigPot);
        smallPot_.pot = smallPot_.pot.add(_smallPot);

        emit onPot(bigPot_[_rID].plyr, bigPot_[_rID].pot, smallPot_.plyr, smallPot_.pot);
    }

    function smallPot()
    private
    {
        uint256 _now = now;

        if (smallPot_.on == false && smallPot_.keys >= (1000)) {
            smallPot_.on = true;
            smallPot_.pot = smallPot_.eth;
            smallPot_.strt = _now;
            smallPot_.end = _now + smallTime_;
        } else if (smallPot_.on == true && _now > smallPot_.end) {
            uint256 _winSmallPot = smallPot_.pot;
            uint256 _currentPot = smallPot_.eth;
            uint256 _surplus = _currentPot.sub(_winSmallPot);
            uint256 _winPID = smallPot_.plyr;
            smallPot_.on = false;
            smallPot_.keys = 0;
            smallPot_.eth = 0;
            smallPot_.pot = 0;
            smallPot_.plyr = 0;
            plyr_[_winPID].winSmallPot = _winSmallPot.add(plyr_[_winPID].winSmallPot);
            if (_surplus > 0) {
                plyr_[1].winSmallPot = _surplus.add(plyr_[1].winSmallPot);
            }
        }
    }

    event onBigPot(
        string eventname,
        uint256 rID,
        uint256 plyr,  
     
        uint256 end,  
        uint256 strt,  
        uint256 eth,  
        uint256 keys,  
        bool ended      
    );

    function updateTimer(uint256 _keys, uint256 _rID)
    private
    {
        emit onBigPot
        (
            "updateTimer_start:",
            _rID,
            bigPot_[_rID].plyr,
            bigPot_[_rID].end,
            bigPot_[_rID].strt,
            bigPot_[_rID].eth,
            bigPot_[_rID].keys,
            bigPot_[_rID].ended
        );
         
        uint256 _now = now;

         
        uint256 _newTime;
        if (_now > bigPot_[_rID].end && bigPot_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(bigPot_[_rID].end);

         
        if (_newTime < (rndMax_).add(_now))
            bigPot_[_rID].end = _newTime;
        else
            bigPot_[_rID].end = rndMax_.add(_now);

        emit onBigPot
        (
            "updateTimer_end:",
            _rID,
            bigPot_[_rID].plyr,
            bigPot_[_rID].end,
            bigPot_[_rID].strt,
            bigPot_[_rID].eth,
            bigPot_[_rID].keys,
            bigPot_[_rID].ended
        );

    }

    event pidUpdate(address sender, uint256 pidOri, uint256 pidNew);

    function determinePID(address _realSender)
    private
    {

        uint256 _pID = pIDxAddr_[_realSender];
        uint256 _pIDOri = _pID;
         
        if (_pID == 0)
        {
             
            _pID = PlayerBook.getPlayerID(_realSender);

             
            pIDxAddr_[_realSender] = _pID;
            plyr_[_pID].addr = _realSender;

        }
        emit pidUpdate(_realSender, _pIDOri, _pID);
    }


    function getPlayerIdxAddr(address _addr) public view returns (uint256){
        if (pIDxAddr_[_addr] == 0) {
            return pIDxAddr_[_addr];
        } else {
            return 0;
        }
    }


    function receivePlayerInfo(uint256 _pID, address _addr)
    external
    {
        require(msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
    }

    event consolerefereeCore(
        uint256 _pID, uint256 _value, uint256 minOfferIndex, uint256 minOfferpID, uint256 minOfferValue
    );

    function refereeCore(uint256 _pID, uint256 _value) private {
        uint256 _rID = rID_;
        uint256 length_ = referees_[_rID].length;
        emit consolerefereeCore(_pID, _value, _rID, length_, minOfferValue_);
        if (_value > minOfferValue_) {

            uint256 minXvalue = _value;
            uint256 minXindex = 9999;
            uint256 flag = 1;

             
            for (uint256 i = 0; i < referees_[_rID].length; i++) {
                if (_pID == referees_[_rID][i].pID) {
                    referees_[_rID][i].offer = _value;
                    flag = 0;
                    break;
                }
            }

             
            if (flag == 1) {
                emit consolerefereeCore(1111, minXindex, _rID, referees_[_rID].length, minXvalue);
                 
                for (uint256 j = 0; j < referees_[_rID].length; j++) {
                    if (referees_[_rID][j].offer < minXvalue) {
                        minXvalue = referees_[_rID][j].offer;
                        emit consolerefereeCore(2222, minXindex, _rID, referees_[_rID].length, minXvalue);
                        minXindex = j;
                    }
                }
                emit consolerefereeCore(3333, minXindex, _rID, referees_[_rID].length, minXvalue);
                 
                if (referees_[_rID].length < referalSlot_) {
                    referees_[_rID].push(F3Ddatasets.Referee(_pID, _value));
                } else {
                     
                    if (minXindex != 9999) {
                        referees_[_rID][minXindex].offer = _value;
                        referees_[_rID][minXindex].pID = _pID;
                        minOfferValue_ = _value;
                    }
                }
            }
        }
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

    function getTimeLeft() public
    view returns (uint256){
        return rndTmEth_[rID_] - now;
    }

    function getrID() public
    view returns (uint256){
        return rID_;
    }

    function getAdmin() public
    view returns (address){
        return admin;
    }

     
     
     
     
     
    bool public activated_ = false;
    uint256  public end_ = 0;

    function activate()
    public
    {
         
        require(msg.sender == admin, "only admin can activate");
         
        require(activated_ == false, "FOMO Short already activated");

         
        activated_ = true;

         
        rID_ = 1;
        uint256 _now = now;

        auction_[1].strt = _now;
        auction_[1].end = _now + aucDur;

        bigPot_[1].strt = _now + aucDur;
        bigPot_[1].end = _now + aucDur + rndMax_;
    }

    function getAuctionTimer()
    public
    view
    returns (uint256, uint256, uint256, uint256, bool, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;
        return
        (
        _rID,  
        auction_[_rID].strt,
        auction_[_rID].end,
        _now,
        _now > auction_[_rID].end,
        bigPot_[_rID].strt,
        bigPot_[_rID].end             
        );
    }


     

     
    function getCurrentRoundAucInfo()
    public
    view
    returns (uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;

        return
        (
        _rID,  
         
        auction_[_rID].isAuction,  
        auction_[_rID].strt,
        auction_[_rID].end,
        auction_[_rID].end - _now,
        auction_[_rID].eth,
        auction_[_rID].gen,
        auction_[_rID].keys
        );
    }

     
    function getCurrentRoundBigPotInfo()
    public
    view
    returns (uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _currentpID = bigPot_[_rID].plyr;
        uint256 _eth = bigPot_[_rID].eth;
        return
        (
        _rID,  
         
        _currentpID,  
        bigPot_[_rID].ended,  
        bigPot_[_rID].strt,  
        bigPot_[_rID].end,  
        bigPot_[_rID].end - _now,
        bigPot_[_rID].keys,  
        _eth,  
        _eth.mul(60) / 100,
        bigPot_[_rID].pot,  
        plyr_[_currentpID].addr,  
        keyPricePot_
        );
    }

     
    function getSmallPotInfo()
    public
    view
    returns (uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _currentpID = smallPot_.plyr;
        return
        (
        _rID,  
         
        _currentpID,
        smallPot_.on,
        smallPot_.strt,
        smallPot_.end,
        smallPot_.end - _now,
        smallPot_.keys,
        smallPot_.eth,
        smallPot_.pot,
        plyr_[_currentpID].addr  
        );
    }

     
    function getPlayerInfoxAddr()
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _pID = pIDxAddr_[msg.sender];
        return
        (_rID,  
        _pID,  
        plyrRnds_[_pID][_rID].eth,
        plyrRnds_[_pID][_rID].auc,
        plyrRnds_[_pID][_rID].keys,
        plyrRnds_[_pID][_rID].mask,  
        plyrRnds_[_pID][_rID].refID  
        );
    }

     
    function getPlayerVaultxAddr()
    public
    view
    returns (uint256, address, uint256, uint256, uint256, uint256)
    {
         
        address addr = msg.sender;
        uint256 _pID = pIDxAddr_[addr];
        return
        (
        _pID,  
        plyr_[_pID].addr,
        plyr_[_pID].winBigPot,
        plyr_[_pID].winSmallPot,
        plyr_[_pID].gen,
        plyr_[_pID].aff
        );
    }
     

    event consoleRef(uint256 index, uint256 pID, uint256 value);

    function getReferees()
    public
    payable
    {
         
        uint256 _rID = rID_;
        for (uint256 i = 0; i < referees_[_rID].length; i++) {
            emit consoleRef(i, referees_[_rID][i].pID, referees_[_rID][i].offer);
        }
    }

    function getPlayerInfoByAddress(address addr)
    public
    view
    returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        address _addr = addr;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        return
        (
        _pID,  
        _addr,  
        _rID,  
        plyr_[_pID].winBigPot,  
        plyr_[_pID].winSmallPot,  
        plyr_[_pID].gen,  
        plyr_[_pID].aff,  
        plyrRnds_[_pID][_rID].keys,  
        plyrRnds_[_pID][_rID].eth,  
        plyrRnds_[_pID][_rID].auc,  
        plyrRnds_[_pID][_rID].mask,  
        plyrRnds_[_pID][_rID].refID  
        );
    }

    function getPlayerInfoById(uint256 pID)
    public
    view
    returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _pID = pID;
        address _addr = msg.sender;
        return
        (
        _pID,  
        _addr,  
        _rID,  
        plyr_[_pID].winBigPot,  
        plyr_[_pID].winSmallPot,  
        plyr_[_pID].gen,  
        plyr_[_pID].aff,  
        plyrRnds_[_pID][_rID].keys,  
        plyrRnds_[_pID][_rID].eth,  
        plyrRnds_[_pID][_rID].auc,  
        plyrRnds_[_pID][_rID].mask,  
        plyrRnds_[_pID][_rID].refID  
        );
    }

    function kill() public {
        if (admin == msg.sender) {  
            selfdestruct(admin);  
        }
    }

}