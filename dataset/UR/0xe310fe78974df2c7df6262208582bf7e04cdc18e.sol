 

pragma solidity ^0.4.24;

contract S3Devents {
     
    event onEndTx
    (
        uint256 compressedData,
        uint256 compressedIDs,
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
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );

     
     
    event onBuyAndDistribute
    (
        address playerAddress,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
}

contract modularLong is S3Devents { }

contract Solitaire3D is modularLong {
    using SafeMath for *;
    using S3DKeysCalcLong for uint256;

    string constant public name = "Solitaire 3D";
    string constant public symbol = "Solitaire";
    uint256 private rndExtra_ = 30 seconds;      
    uint256 private rndGap_ = 30 seconds;          
    uint256 constant private rndInit_ = 24 hours;                 
    uint256 constant private rndInc_ = 60 seconds;               
    uint256 constant private rndMax_ = 24 hours;                 
    address constant private developer = 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897;
    address constant private operator = 0xc3F465FD001f78DCEeF6f47FD18E3B04F95f2337;

    uint256 public rID_;     

    mapping (address => uint256) public pIDxAddr_;           
    mapping (uint256 => S3Ddatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => S3Ddatasets.PlayerRounds)) public plyrRnds_;     

    mapping (uint256 => S3Ddatasets.Round) public round_;    
    uint256 public pID_;
    S3Ddatasets.TeamFee public fee_;

    constructor()
        public
    {

        fee_ = S3Ddatasets.TeamFee(50);    
        plyr_[1].addr = 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897;
        pIDxAddr_[0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897] = 1;
        pID_ = 1;
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
        require(_eth >= 0, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

     
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        S3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        if (msg.value > 1000000000){
            buyCore(_pID, _eventData_);
        }else{
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
            withdraw();
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
             
            S3Ddatasets.EventReturns memory _eventData_;

             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

			 
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit S3Devents.onWithdrawAndDistribute
            (
                msg.sender,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );

         
        } else {
             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            emit S3Devents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
    }

 
 
 
 
     
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else  
            return ( 75000000000000 );  
    }

     
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }

     
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256)
    {
         
        uint256 _rID = rID_;

         
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(90)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   )
                );
             
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  )
                );
            }

         
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd))
            );
        }
    }

     
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(((((round_[_rID].mask) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000);
    }

    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, address)
    {
         
        uint256 _rID = rID_;

        return
        (
            _rID,                            
            round_[_rID].keys,               
            round_[_rID].end,                
            round_[_rID].strt,               
            round_[_rID].pot,                
            plyr_[round_[_rID].plyr].addr   
        );
    }

    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                                
            plyrRnds_[_pID][_rID].keys,          
            plyr_[_pID].win,                     
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),  
            plyrRnds_[_pID][_rID].eth            
        );
    }

 
 
 
 
     
    function buyCore(uint256 _pID, S3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
            core(_rID, _pID, msg.value, _eventData_);

         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                 
                emit S3Devents.onBuyAndDistribute
                (
                    msg.sender,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.genAmount
                );
            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
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
    function managePlayer(uint256 _pID, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }
     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, S3Ddatasets.EventReturns memory _eventData_)
        private
    {

        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
         
        if (_eth > 1000000000)
        {

             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

             
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                 
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;

                 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);

             
            _eventData_ = distributeExternal(_eth, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _keys, _eventData_);

             
            endTx(_pID, _eth, _keys, _eventData_);
        }
    }

     
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else  
            return ( (_eth).keys() );
    }

     
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else  
            return ( (_keys).eth() );
    }

     
    function determinePID(S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)
        {
             

            pID_++;
            _pID = pID_;
             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

             
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

     
    function endRound(S3Ddatasets.EventReturns memory _eventData_)
        private
        returns (S3Ddatasets.EventReturns)
    {
         
        uint256 _rID = rID_;

         
        uint256 _winPID = round_[_rID].plyr;

         
        uint256 _pot = round_[_rID].pot;

         
         
        uint256 _win = (_pot.mul(90)) / 100;
        uint256 _com = (_pot / 20);
        uint256 _res = ((_pot.sub(_win)).sub(_com)).sub(_com);

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        if (_com > 0) {
            developer.transfer(_com);
            operator.transfer(_com);
        }

         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = 0;
        _eventData_.newPot = _res;

         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;

        return(_eventData_);
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
     
    function distributeExternal(uint256 _eth, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns(S3Ddatasets.EventReturns)
    {

         
        uint256 _long = _eth / 20;
        developer.transfer(_long);
        operator.transfer(_long);

        return(_eventData_);
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys, S3Ddatasets.EventReturns memory _eventData_)
        private
        returns(S3Ddatasets.EventReturns)
    {
         
        uint256 _gen = (_eth.mul(fee_.gen)) / 100;

         
        _eth = _eth.sub(((_eth.mul(10)) / 100));

         
        uint256 _pot = _eth.sub(_gen);

         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }

     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {

         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

         
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

     
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        updateGenVault(_pID, plyr_[_pID].lrnd);
         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return(_earnings);
    }

     
    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, S3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit S3Devents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
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

    bool public activated_ = false;
    function activate()
        public
    {
         
        require(
            msg.sender == 0xA7759a5CAcE1a3b54E872879Cf3942C5D4ff5897,
            "only team just can activate"
        );

         
        require(activated_ == false, "Solitaire3D already activated");

         
        activated_ = true;

         
		rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
}

library S3Ddatasets {

    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 potAmount;           
        uint256 genAmount;
    }
    struct Player {
        address addr;    
        uint256 win;     
        uint256 gen;     
        uint256 lrnd;    
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
    }
    struct Round {
        uint256 plyr;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
    }
    struct TeamFee {
        uint256 gen;     
    }
    struct PotSplit {
        uint256 gen;     
    }
}

 
 
 
 
library S3DKeysCalcLong {
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