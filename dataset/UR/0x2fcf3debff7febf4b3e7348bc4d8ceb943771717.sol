 

pragma solidity ^0.4.24;

 
 
 
 
 
 
contract PolyFomoEvents {
     
    event onEndTx
    (
        uint256 compressedData,     
        uint256 compressedIDs,      
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 polyBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 cubeAmount,
        uint256 genAmount,
        uint256 potAmount
    );
    
     
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    
     
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot
    );
    
     
     
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot
    );
    
     
     
    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot
    );
    
     
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

 
 
 
 

contract modularLong is PolyFomoEvents {}

contract PolyFomo is modularLong {
    using SafeMath for *;
    using PolygonCalcLong for uint256;
    
    address private comAddress_;
    CubeInterface private cube;
    UsernameInterface private username;
    
 
 
 
 
    string constant public name = "PolyFomo";
    string constant public symbol = "POLY";
    uint256 constant private rndExtra_ = 24 hours;               
    uint256 constant private rndInit_ = 1 hours;                 
    uint256 constant private rndInc_ = 30 minutes;               
    uint256 constant private rndMax_ = 72 hours;                 
    
 
 
 
 
    uint256 public rID_;     
    uint256 public pID_;   
 
 
 
    mapping (address => uint256) public pIDxAddr_;                                                
    mapping (uint256 => PolyFomoDatasets.Player) public plyr_;                                    
    mapping (uint256 => mapping (uint256 => PolyFomoDatasets.PlayerRounds)) public plyrRnds_;     

 
 
 
    mapping (uint256 => PolyFomoDatasets.Round) public round_;               
    uint256 public rndEth_;
 
 
 
 
 
 
 
    constructor(address usernameAddress, address cubeAddress, address comAddress)
        public
    {
        username = UsernameInterface(usernameAddress);
        cube = CubeInterface(cubeAddress);
        comAddress_ = comAddress;
        
         
         
        
         
        rID_ = 1;
        round_[1].strt = cube.startTime() + rndExtra_;
        round_[1].end = cube.startTime() + rndInit_ + rndExtra_;
	}
 
 
 
 

     
    modifier isHuman() {
        require(tx.origin == msg.sender);
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
 
 
 
 
     
    function()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        PolyFomoDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
            
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        buyCore(_pID, plyr_[_pID].laff, _eventData_);
    }
    
     
    
    function buyXaddr(address _affCode)
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        PolyFomoDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
            if (_affID == 0) {
                _affID = registerReferrer(_affCode);
            }
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        buyCore(_pID, _affID, _eventData_);
    }
    
     
    
    function reLoadXaddr(address _affCode, uint256 _eth)
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        PolyFomoDatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID == 0) {
                _affID = registerReferrer(_affCode);
            }
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

     
    function withdraw()
        isHuman()
        public
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _eth;
        
         
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            PolyFomoDatasets.EventReturns memory _eventData_;
            
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
             
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            
             
            emit PolyFomoEvents.onWithdrawAndDistribute
            (
                msg.sender, 
                username.getNameByAddress(plyr_[_pID].addr), 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot
            );
            
         
        } else {
             
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
             
            emit PolyFomoEvents.onWithdraw(_pID, msg.sender, username.getNameByAddress(plyr_[_pID].addr), _eth, _now);
        }
    }
    
 
 
 
 

     

    function getIncrementPrice()
        public 
        view
        returns(uint256)
    {  
         
        uint256 _rID = rID_;
        
         
        uint256 _pot = round_[_rID].pot;
        
        return (_pot / 1000000000000000000).mul(100000000000000000000);
    }

     
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].poly.add(1000000000000000000)).ethRec(1000000000000000000) );
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
            if (_now > round_[_rID].strt)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt).sub(_now) );
        else
            return(0);
    }
    
     
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
         
        uint256 _rID = rID_;
        
         
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add(round_[_rID].pot),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
             
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
            
         
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }
    
     
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return round_[_rID].mask.mul(plyrRnds_[_pID][_rID].poly) / 1000000000000000000;
    }
    
     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256)
    {
         
        uint256 _rID = rID_;
        
        return
        (
            _rID,                                                      
            round_[_rID].poly,                                         
            round_[_rID].end,                                          
            round_[_rID].strt,                                         
            round_[_rID].pot,                                          
            plyr_[round_[_rID].plyr].addr,                             
            username.getNameByAddress(plyr_[round_[_rID].plyr].addr),  
            rndEth_                                                    
        );
    }

     
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
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
            username.getNameByAddress(_addr),    
            plyrRnds_[_pID][_rID].poly,          
            plyr_[_pID].win,                     
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
            plyr_[_pID].aff,                     
            plyrRnds_[_pID][_rID].eth            
        );
    }

 
 
 
 
     
    function buyCore(uint256 _pID, uint256 _affID, PolyFomoDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
             
            core(_rID, _pID, msg.value, _affID, _eventData_);
        
         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
                
                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
                 
                emit PolyFomoEvents.onBuyAndDistribute
                (
                    msg.sender, 
                    username.getNameByAddress(plyr_[_pID].addr), 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot
                );
            }
            
             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, PolyFomoDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
             
             
             
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
             
            core(_rID, _pID, _eth, _affID, _eventData_);
        
         
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
                
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
             
            emit PolyFomoEvents.onReLoadAndDistribute
            (
                msg.sender, 
                username.getNameByAddress(plyr_[_pID].addr), 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot
            );
        }
    }
    
     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, PolyFomoDatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID][_rID].poly == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
         
        if (round_[_rID].eth < 30000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        
         
        if (_eth > 1000000000) 
        {
            
             
            uint256 _poly = (round_[_rID].eth).polyRec(_eth);
            
            if (_poly >= getIncrementPrice())
            {
                updateTimer(_rID);

                 
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;  
                
                 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }
            
             
            plyrRnds_[_pID][_rID].poly = _poly.add(plyrRnds_[_pID][_rID].poly);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            
             
            round_[_rID].poly = _poly.add(round_[_rID].poly);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndEth_ = _eth.add(rndEth_);
    
             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _poly, _eventData_);
            
             
            endTx(_pID, _eth, _poly, _eventData_);
        }
    }
 
 
 
 
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].poly)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }
    
     
    function calcPolyReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).polyRec(_eth) );
        else  
            return ( (_eth).poly() );
    }
    
     
    function iWantXPoly(uint256 _poly)
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].poly.add(_poly)).ethRec(_poly) );
        else  
            return ( (_poly).eth() );
    }
 
 
 
 
        
     
    function determinePID(PolyFomoDatasets.EventReturns memory _eventData_)
        private
        returns (PolyFomoDatasets.EventReturns memory)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        if (_pID == 0)
        {
            pID_++;
            pIDxAddr_[msg.sender] = pID_;
            plyr_[pID_].addr = msg.sender;
            
             
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        
        return (_eventData_);
    }
    
     
    function registerReferrer(address _affCode)
        private
        returns (uint256 affID)
    {
        pID_++;
        pIDxAddr_[_affCode] = pID_;
        plyr_[pID_].addr = _affCode;
        
        return pID_;
    }
    
     
    function managePlayer(uint256 _pID, PolyFomoDatasets.EventReturns memory _eventData_)
        private
        returns (PolyFomoDatasets.EventReturns memory)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
            
         
        plyr_[_pID].lrnd = rID_;
            
         
        _eventData_.compressedData = _eventData_.compressedData + 10;
        
        return(_eventData_);
    }
    
     
    function endRound(PolyFomoDatasets.EventReturns memory _eventData_)
        private
        returns (PolyFomoDatasets.EventReturns memory)
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _winPID = round_[_rID].plyr;
        
         
        uint256 _win = round_[_rID].pot;

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        
         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = username.getNameByAddress(plyr_[_winPID].addr);
        _eventData_.amountWon = _win;
        _eventData_.newPot = 0;
        
         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = 0;
        
        return(_eventData_);
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
    
     
    function updateTimer(uint256 _rID)
        private
    {
         
        uint256 _now = now;
        
         
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = rndInc_.add(_now);
        else
            _newTime = rndInc_.add(round_[_rID].end);
        
         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, PolyFomoDatasets.EventReturns memory _eventData_)
        private
        returns(PolyFomoDatasets.EventReturns memory)
    {       
        uint256 _cube;
    
         
        uint256 _com = _eth / 20;
        comAddress_.transfer(_com);
        
         
        uint256 _aff = _eth / 10;
        
        if (_affID != _pID && _affID != 0) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit PolyFomoEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, username.getNameByAddress(plyr_[_affID].addr), _rID, _pID, _aff, now);
        } else {
            _cube = _aff;
        }
        
         
        _cube = _cube.add((_eth.mul(15)) / (100));
        if (_cube > 0)
        {
             
            cube.distribute.value(_cube)();
            
             
            _eventData_.cubeAmount = _cube.add(_eventData_.cubeAmount);
        }
        
        return(_eventData_);
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _poly, PolyFomoDatasets.EventReturns memory _eventData_)
        private
        returns(PolyFomoDatasets.EventReturns memory)
    {
         
        uint256 _gen = (_eth.mul(50)) / 100;
        
         
        _eth = _eth.sub((_eth.mul(30)) / 100);
        
         
        uint256 _pot = _eth.sub(_gen);
        
         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _poly);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
         
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
        
         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }
    
     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _poly)
        private
        returns(uint256)
    {
         
        
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].poly);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
            
         
         
        uint256 _pearn = (_ppt.mul(_poly)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_poly)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
         
        return(_gen.sub((_ppt.mul(round_[_rID].poly)) / (1000000000000000000)));
    }
    
     
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
     
    function endTx(uint256 _pID, uint256 _eth, uint256 _poly, PolyFomoDatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);
        
        emit PolyFomoEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            username.getNameByAddress(plyr_[_pID].addr),
            msg.sender,
            _eth,
            _poly,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.cubeAmount,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }
}

 
 
 
 
library PolyFomoDatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 cubeAmount;          
        uint256 genAmount;           
        uint256 potAmount;           
    }
    struct Player {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 lrnd;    
        uint256 laff;    
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 poly;    
        uint256 mask;    
    }
    struct Round {
        uint256 plyr;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 poly;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
    }
}

 
 
 
 
library PolygonCalcLong {
    using SafeMath for *;
     
    function polyRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(poly((_curEth).add(_newEth)).sub(poly(_curEth)));
    }
    
     
    function ethRec(uint256 _curPoly, uint256 _sellPoly)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curPoly)).sub(eth(_curPoly.sub(_sellPoly))));
    }

     
    function poly(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
     
    function eth(uint256 _poly) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_poly.sq()).add(((149999843750000).mul(_poly.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

 
 
 
 

interface UsernameInterface {
    function getNameByAddress(address _addr) external view returns (bytes32);
}

interface CubeInterface {
    function distribute() external payable;
    function startTime() external view returns (uint256);
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