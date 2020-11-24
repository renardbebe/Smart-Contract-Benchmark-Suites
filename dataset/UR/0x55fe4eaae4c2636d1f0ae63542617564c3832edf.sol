 

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
        uint256 affKeys;    
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
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
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
     
     
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xF2940f868fcD1Fbe8D1E1c02d2eaF68d8D7Db338);

    address private admin = msg.sender;
     
    uint256 constant private rndInc_ = 60 seconds;               
    uint256 constant private smallTime_ = 5 minutes;               
    uint256 constant private rndMax_ = 24 hours;                 
    uint256 public rID_;     
    uint256 constant public keyPricePot_ = 10000000000000000;  
     
     
     
    mapping(address => uint256) public pIDxAddr_;           
    mapping(uint256 => F3Ddatasets.PlayerVault) public plyr_;    
     
    mapping(uint256 => mapping(uint256 => F3Ddatasets.PlayerRound)) public plyrRnds_;
     
     
     
    mapping(uint256 => F3Ddatasets.Auction) public auction_;    
    mapping(uint256 => F3Ddatasets.BigPot) public bigPot_;    
    F3Ddatasets.SmallPot public smallPot_;    
    mapping(uint256 => uint256) public rndTmEth_;       
    uint256 private keyMax_ = 0;
    address private keyMaxAddress_ = address(0);
    uint256 private affKeyMax_ = 0;
    uint256 private affKeyMaxPlayId_ = 0;

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


    function determinePID(address senderAddr)
    private
    {
        uint256 _pID = pIDxAddr_[senderAddr];
        if (_pID == 0)
        {
            _pID = PlayerBook.getPlayerID(senderAddr);
            pIDxAddr_[senderAddr] = _pID;
            plyr_[_pID].addr = senderAddr;

        }
    }


     
     
     
     
     
    function()
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    external
    payable
    {
         
        determinePID(msg.sender);

         
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _now = now;
        uint256 _rID = rID_;

        if (_now > bigPot_[_rID].strt && _now < bigPot_[_rID].end) {
             
            buy(_pID, 0);
        } else {
             
            if (_now > bigPot_[_rID].end && bigPot_[_rID].ended == false)
            {
                 
                bigPot_[_rID].ended = true;
                endRound();
            }

             
            plyr_[_pID].gen = msg.value.add(plyr_[_pID].gen);
        }
    }

    function buyXQR(address senderAddr, uint256 _affID)
    isActivated()
    isWithinLimits(msg.value)
    public
    payable
    {
         
        determinePID(senderAddr);

         
        uint256 _pID = pIDxAddr_[senderAddr];
        uint256 _now = now;
        uint256 _rID = rID_;


        if (_affID == _pID)
        {
            _affID = 0;

        }

        if (_now > bigPot_[_rID].strt && _now < bigPot_[_rID].end) {
             
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
        address _winAddress = keyMaxAddress_;
         

        uint256 _winPID = pIDxAddr_[_winAddress];

         
        uint256 _win = bigPot_[_rID].pot;
         

         
        plyr_[_winPID].winBigPot = _win.add(plyr_[_winPID].winBigPot);

         
        smallPot_.keys = 0;
        smallPot_.eth = 0;
        smallPot_.pot = 0;
        smallPot_.plyr = 0;

        if (smallPot_.on == true) {
            uint256 _currentPot = smallPot_.eth;
            uint256 _winSmallPot = smallPot_.pot;
            uint256 _surplus = _currentPot.sub(_winSmallPot);
            smallPot_.on = false;
            plyr_[_winPID].winSmallPot = _winSmallPot.add(plyr_[_winPID].winSmallPot);
            if (_surplus > 0) {
                plyr_[1].winSmallPot = _surplus.add(plyr_[1].winSmallPot);
            }
        } else {
            uint256 _currentPot1 = smallPot_.pot;
            if (_currentPot1 > 0) {
                plyr_[1].winSmallPot = _currentPot1.add(plyr_[1].winSmallPot);
            }
        }


         
        rID_++;
        _rID++;
        uint256 _now = now;

        bigPot_[_rID].strt = _now;
        bigPot_[_rID].end = _now + rndMax_;
        keyMax_ = 0;
        keyMaxAddress_ = address(0);
        affKeyMax_ = 0;
        affKeyMaxPlayId_ = 0;
    }


    function withdrawXQR(address _realSender)
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
    returns (uint256)
    {
        return ((((bigPot_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask));
    }

    function managePlayer(uint256 _pID)
    private
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;
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
             
            if (_keys >= 1)
            {
                updateTimer(_keys, _rID);
                 
                if (bigPot_[_rID].plyr != _pID)
                    bigPot_[_rID].plyr = _pID;
            }


             
            bigPot_[_rID].keys = _keys.add(bigPot_[_rID].keys);
            bigPot_[_rID].eth = _eth.add(bigPot_[_rID].eth);

            smallPot_.keys = _keys.add(smallPot_.keys);

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

            if (_affID != 0) {
                plyrRnds_[_affID][_rID].affKeys = _keys.add(plyrRnds_[_affID][_rID].affKeys);
            }

             
            if (plyrRnds_[_pID][_rID].keys > keyMax_) {
                keyMax_ = plyrRnds_[_pID][_rID].keys;
                keyMaxAddress_ = plyr_[_pID].addr;
            }

             
            if (plyrRnds_[_affID][_rID].affKeys > affKeyMax_) {
                affKeyMax_ = plyrRnds_[_affID][_rID].affKeys;
                affKeyMaxPlayId_ = pIDxAddr_[plyr_[_affID].addr];
            }


             
            uint256 _gen = _eth.mul(5) / 10;
            updateMasks(_rID, _pID, _gen, _keys);

            distributeBuy(_rID, _eth, _affID);
            smallPot();
        }
    }

    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
    private
    returns (uint256)
    {
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (bigPot_[_rID].keys);
        bigPot_[_rID].mask = _ppt.add(bigPot_[_rID].mask);

         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((bigPot_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

         
        return (_gen.sub((_ppt.mul(bigPot_[_rID].keys)) / (1000000000000000000)));
    }

    function distributeBuy(uint256 _rID, uint256 _eth, uint256 _affID)
    private
    {
         
        uint256 _team = _eth.mul(15) / 2 / 100;
        uint256 _team1 = _team;
         
        uint256 _aff = _eth.mul(10) / 100;

        uint256 _ethMaxAff = _eth.mul(5) / 100;

        if (_affID == 0) {
            _team = _team.add(_aff);
            _aff = 0;
        }
        if (affKeyMaxPlayId_ == 0) {
            _team = _team.add(_ethMaxAff);
            _ethMaxAff = 0;
        }
         
        uint256 _bigPot = _eth / 10;
         
        uint256 _smallPot = _eth / 10;

         
        plyr_[1].aff = _team.add(plyr_[1].aff);
        plyr_[2].aff = _team1.add(plyr_[2].aff);

        if (_ethMaxAff != 0) {
            plyr_[affKeyMaxPlayId_].aff = _ethMaxAff.add(plyr_[affKeyMaxPlayId_].aff);
        }
        if (_aff != 0) {
             
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
        }

         
        bigPot_[_rID].pot = bigPot_[_rID].pot.add(_bigPot);
        smallPot_.pot = smallPot_.pot.add(_smallPot);
    }

    function smallPot()
    private
    {
        uint256 _now = now;

        if (smallPot_.on == false && smallPot_.keys >= (1000)) {
            smallPot_.on = true;
            smallPot_.eth = smallPot_.pot;
            smallPot_.strt = _now;
            smallPot_.end = _now + smallTime_;
        } else if (smallPot_.on == true && _now > smallPot_.end) {
            uint256 _winSmallPot = smallPot_.eth;
            uint256 _currentPot = smallPot_.pot;
            uint256 _surplus = _currentPot.sub(_winSmallPot);
            uint256 _winPID = pIDxAddr_[keyMaxAddress_];
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


    function updateTimer(uint256 _keys, uint256 _rID)
    private
    {

         
        uint256 _now = now;

         
        uint256 _newTime;
        if (_now > bigPot_[_rID].end && bigPot_[_rID].plyr == 0)
            _newTime = ((_keys).mul(rndInc_)).add(_now);
        else
            _newTime = ((_keys).mul(rndInc_)).add(bigPot_[_rID].end);

         
        if (_newTime < (rndMax_).add(_now))
            bigPot_[_rID].end = _newTime;
        else
            bigPot_[_rID].end = rndMax_.add(_now);

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

        bigPot_[1].strt = _now;
        bigPot_[1].end = _now + rndMax_;
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


     

     
    function getCurrentRoundBigPotInfo()
    public
    view
    returns (uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _currentpID = pIDxAddr_[keyMaxAddress_];
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
        bigPot_[_rID].pot,  
        keyMaxAddress_,  
        keyMax_,
        affKeyMax_
        );
    }

     
    function getSmallPotInfo()
    public
    view
    returns (uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
         
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _currentpID = pIDxAddr_[keyMaxAddress_];
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
        keyMaxAddress_  
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

    function getPlayerVaults(uint256 _pID)
    public
    view
    returns (uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

         
        if (now > bigPot_[_rID].end && bigPot_[_rID].ended == false && keyMaxAddress_ != address(0))
        {
             
            if (pIDxAddr_[keyMaxAddress_] == _pID)
            {
                return
                (
                plyr_[_pID].winBigPot.add(bigPot_[_rID].pot),
                plyr_[_pID].winSmallPot,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
                );

                 
            } else {
                return
                (
                plyr_[_pID].winBigPot,
                plyr_[_pID].winSmallPot,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
                );
            }

             
        } else {
            return
            (
            plyr_[_pID].winBigPot,
            plyr_[_pID].winSmallPot,
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
            plyr_[_pID].aff
            );
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
}