 

pragma solidity ^0.4.24;
contract F4Devents {
     
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );
    
     
    event onEndTx
    (
        uint256 compressedData,     
        uint256 compressedIDs,      
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
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
    
     
    event onPotSwapDeposit
    (
        uint256 roundID,
        uint256 amountAddedToPot
    );
}

contract FoMo4DSoon is F4Devents{
    using SafeMath for uint256;
    using NameFilter for string;
    using F4DKeysCalcFast for uint256;
    
    address private owner_;
	PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xeEd618C15d12C635C3C319aEe7BDED2E2879AEa0);
    string constant public name = "Fomo4D Soon";
    string constant public symbol = "F4D";
	uint256 private rndGap_ = 60 seconds;                        
    uint256 constant private rndInit_ = 5 minutes;               
    uint256 constant private rndInc_ = 5 minutes;                
    uint256 constant private rndMax_ = 5 minutes;                
    uint256 public rID_;     
 
 
 
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => F4Ddatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => F4Ddatasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
 
 
 
    mapping (uint256 => F4Ddatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
 
 
 
    mapping (uint256 => F4Ddatasets.TeamFee) public fees_;           
    mapping (uint256 => F4Ddatasets.PotSplit) public potSplit_;      
    
    constructor()
        public
    {
        owner_ = msg.sender;
		 
         
         
         
         

        fees_[0] = F4Ddatasets.TeamFee(24);
        fees_[1] = F4Ddatasets.TeamFee(38);
        fees_[2] = F4Ddatasets.TeamFee(50);
        fees_[3] = F4Ddatasets.TeamFee(42);
         
        potSplit_[0] = F4Ddatasets.PotSplit(12);
        potSplit_[1] = F4Ddatasets.PotSplit(19);
        potSplit_[2] = F4Ddatasets.PotSplit(26);
        potSplit_[3] = F4Ddatasets.PotSplit(30);
	}
    
     
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    
     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
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
         
        F4Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }
    
     
    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        F4Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;
            
         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }
        
         
        _team = verifyTeam(_team);
        
         
        buyCore(_pID, _affCode, _team, _eventData_);
    }
    
    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        F4Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        _team = verifyTeam(_team);
        
         
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        F4Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxName_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        _team = verifyTeam(_team);
        
         
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
     
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        F4Ddatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;
            
         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

         
        _team = verifyTeam(_team);
            
         
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }
    
    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        F4Ddatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        _team = verifyTeam(_team);
        
         
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }
    
    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        F4Ddatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxName_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
        
         
        _team = verifyTeam(_team);
        
         
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
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
        
         
        if (_now > round_[_rID].end && round_[_rID].ended == false)
        {
             
            F4Ddatasets.EventReturns memory _eventData_;
            
             
			round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
			 
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            
             
            emit F4Devents.onWithdrawAndDistribute
            (
                msg.sender, 
                plyr_[_pID].name, 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.P3DAmount, 
                _eventData_.genAmount
            );
            
         
        } else {
             
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
             
            emit F4Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }
    
     
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit F4Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit F4Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit F4Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
     
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
         
        uint256 _rID = rID_;
            
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt + rndGap_ && round_[_rID].eth != 0 && _now <= round_[_rID].end)
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else if (_now <= round_[_rID].end)  
            return ( ((round_[_rID].ico.keys()).add(1000000000000000000)).ethRec(1000000000000000000) );
        else  
            return ( 100000000000000 );  
    }
    
     
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
        if (_now <= round_[_rID].strt + rndGap_)
            return( ((round_[_rID].end).sub(rndInit_)).sub(_now) );
        else 
            if (_now < round_[_rID].end)
                return( (round_[_rID].end).sub(_now) );
            else
                return(0);
    }
    
     
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
         
        uint256 _rID = rID_;
        
         
        if (now > round_[_rID].end && round_[_rID].ended == false)
        {
            uint256 _roundMask;
            uint256 _roundEth;
            uint256 _roundKeys;
            uint256 _roundPot;
            if (round_[_rID].eth == 0 && round_[_rID].ico > 0)
            {
                 
                _roundEth = round_[_rID].ico;
                
                 
                _roundKeys = (round_[_rID].ico).keys();
                
                 
                _roundMask = ((round_[_rID].icoGen).mul(1000000000000000000)) / _roundKeys;
                
                 
                _roundPot = (round_[_rID].pot).add((round_[_rID].icoGen).sub((_roundMask.mul(_roundKeys)) / (1000000000000000000)));
            } else {
                _roundEth = round_[_rID].eth;
                _roundKeys = round_[_rID].keys;
                _roundMask = round_[_rID].mask;
                _roundPot = round_[_rID].pot;
            }
            
            uint256 _playerKeys;
            if (plyrRnds_[_pID][plyr_[_pID].lrnd].ico == 0)
                _playerKeys = plyrRnds_[_pID][plyr_[_pID].lrnd].keys;
            else
                _playerKeys = calcPlayerICOPhaseKeys(_pID, _rID);
            
             
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( (_roundPot.mul(48)) / 100 ),
                    (plyr_[_pID].gen).add( getPlayerVaultsHelper(_pID, _roundMask, _roundPot, _roundKeys, _playerKeys) ),
                    plyr_[_pID].aff
                );
             
            } else {
                return
                (
                    plyr_[_pID].win,   
                    (plyr_[_pID].gen).add( getPlayerVaultsHelper(_pID, _roundMask, _roundPot, _roundKeys, _playerKeys) ),
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
    
     
    function getPlayerVaultsHelper(uint256 _pID, uint256 _roundMask, uint256 _roundPot, uint256 _roundKeys, uint256 _playerKeys)
        private
        view
        returns(uint256)
    {
        return(  (((_roundMask.add((((_roundPot.mul(potSplit_[round_[rID_].team].gen)) / 100).mul(1000000000000000000)) / _roundKeys)).mul(_playerKeys)) / 1000000000000000000).sub(plyrRnds_[_pID][rID_].mask)  );
    }
    
     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        
        if (round_[_rID].eth != 0)
        {
            return
            (
                round_[_rID].ico,                
                _rID,                            
                round_[_rID].keys,               
                round_[_rID].end,                
                round_[_rID].strt,               
                round_[_rID].pot,                
                (round_[_rID].team + (round_[_rID].plyr * 10)),      
                plyr_[round_[_rID].plyr].addr,   
                plyr_[round_[_rID].plyr].name,   
                rndTmEth_[_rID][0],              
                rndTmEth_[_rID][1],              
                rndTmEth_[_rID][2],              
                rndTmEth_[_rID][3]               
            );
        } else {
            return
            (
                round_[_rID].ico,                
                _rID,                            
                (round_[_rID].ico).keys(),       
                round_[_rID].end,                
                round_[_rID].strt,               
                round_[_rID].pot,                
                (round_[_rID].team + (round_[_rID].plyr * 10)),      
                plyr_[round_[_rID].plyr].addr,   
                plyr_[round_[_rID].plyr].name,   
                rndTmEth_[_rID][0],              
                rndTmEth_[_rID][1],              
                rndTmEth_[_rID][2],              
                rndTmEth_[_rID][3]               
            );
        }
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
        
        if (plyrRnds_[_pID][_rID].ico == 0)
        {
            return
            (
                _pID,                                
                plyr_[_pID].name,                    
                plyrRnds_[_pID][_rID].keys,          
                plyr_[_pID].win,                     
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
                plyr_[_pID].aff,                     
				0						             
            );
        } else {
            return
            (
                _pID,                                
                plyr_[_pID].name,                    
                calcPlayerICOPhaseKeys(_pID, _rID),  
                plyr_[_pID].win,                     
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
                plyr_[_pID].aff,                     
				plyrRnds_[_pID][_rID].ico            
            );
        }
        
    }


     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F4Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        _eventData_ = manageRoundAndPlayer(_pID, _eventData_);
        
         
        if (now <= round_[rID_].strt + rndGap_) 
        {
             
            _eventData_.compressedData = _eventData_.compressedData + 2000000000000000000000000000000;
        
             
            icoPhaseCore(_pID, msg.value, _team, _affID, _eventData_);
        
        
         
        } else {
              
            _eventData_.compressedData = _eventData_.compressedData + 1000000000000000000000000000000;
        
             
            core(_pID, msg.value, _affID, _team, _eventData_);
        }
    }

     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F4Ddatasets.EventReturns memory _eventData_)
        private 
    {
         
        _eventData_ = manageRoundAndPlayer(_pID, _eventData_);
        
         
         
         
        plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
                
         
        if (now <= round_[rID_].strt + rndGap_) 
        {
             
            _eventData_.compressedData = _eventData_.compressedData + 3000000000000000000000000000000;
                
             
            icoPhaseCore(_pID, _eth, _team, _affID, _eventData_);


         
        } else {
             
            core(_pID, _eth, _affID, _team, _eventData_);
        }
    }    
    
     
    function icoPhaseCore(uint256 _pID, uint256 _eth, uint256 _team, uint256 _affID, F4Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;
        
         
        if ((round_[_rID].ico).keysRec(_eth) >= 1000000000000000000 || round_[_rID].plyr == 0)
        {
             
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;  
            if (round_[_rID].team != _team)
                round_[_rID].team = _team;
            
             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }
        
         
         
        plyrRnds_[_pID][_rID].ico = _eth.add(plyrRnds_[_pID][_rID].ico);
        round_[_rID].ico = _eth.add(round_[_rID].ico);
        
         
        rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);
        
         
        _eventData_ = distributeExternal(_eth, _eventData_);

         
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;
        
        uint256 _aff = _eth / 10;
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F4Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _gen = _gen.add(_aff);
            _aff = 0;
        }

         
         
        round_[_rID].icoGen = _gen.add(round_[_rID].icoGen);
        
        uint256 _pot = (_eth.sub(((_eth.mul(14)) / 100))).sub(_gen).sub(_aff);
        
         
        round_[_rID].pot = _pot.add(round_[_rID].pot);
        
         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
         
        endTx(_rID, _pID, _team, _eth, 0, _eventData_);
    }
    
     
    function core(uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F4Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;
        
         
        if (round_[_rID].eth == 0 && round_[_rID].ico > 0)
            roundClaimICOKeys(_rID);
        
         
        if (plyrRnds_[_pID][_rID].keys == 0 && plyrRnds_[_pID][_rID].ico > 0)
        {
             
            plyrRnds_[_pID][_rID].keys = calcPlayerICOPhaseKeys(_pID, _rID);
             
            plyrRnds_[_pID][_rID].ico = 0;
        }
            
         
        uint256 _keys = (round_[_rID].eth).keysRec(_eth);
        
         
        if (_keys >= 1000000000000000000)
        {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;  
            if (round_[_rID].team != _team)
                round_[_rID].team = _team; 
            
             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }
        
        
         
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
        
         
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _eth.add(round_[_rID].eth);
        rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

         
        _eventData_ = distributeExternal(_eth, _eventData_);
        _eventData_ = distributeInternal(_rID, _pID, _eth, _affID, _team, _keys, _eventData_);
        
         
        endTx(_rID, _pID, _team, _eth, _keys, _eventData_);
    }
    
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
         
         
        if (plyrRnds_[_pID][_rIDlast].ico == 0)
            return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
        else
            if (now > round_[_rIDlast].strt + rndGap_ && round_[_rIDlast].eth == 0)
                return(
                      (
                          (
                              (
                                  (
                                      (round_[_rIDlast].icoGen).mul(1000000000000000000)
                                    ) / (round_[_rIDlast].ico).keys()
                              ).mul(calcPlayerICOPhaseKeys(_pID, _rIDlast))
                          ) / (1000000000000000000)
                        ).sub(plyrRnds_[_pID][_rIDlast].mask)  
                      );
            else
                return(  
                        (
                            (
                                (round_[_rIDlast].mask).mul(calcPlayerICOPhaseKeys(_pID, _rIDlast))
                            ) / (1000000000000000000)
                        ).sub(plyrRnds_[_pID][_rIDlast].mask)  
                    );
         
         
         
    }
    
     
    function calcAverageICOPhaseKeyPrice(uint256 _rID)
        public 
        view 
        returns(uint256)
    {
        return(  (round_[_rID].ico).mul(1000000000000000000) / (round_[_rID].ico).keys()  );
    }
    
     
    function calcPlayerICOPhaseKeys(uint256 _pID, uint256 _rID)
        public 
        view
        returns(uint256)
    {
        if (round_[_rID].icoAvg != 0 || round_[_rID].ico == 0 )
            return(  ((plyrRnds_[_pID][_rID].ico).mul(1000000000000000000)) / round_[_rID].icoAvg  );
        else
            return(  ((plyrRnds_[_pID][_rID].ico).mul(1000000000000000000)) / calcAverageICOPhaseKeyPrice(_rID)  );
    }
    
     
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        
         
        if (_now > round_[_rID].strt + rndGap_ && round_[_rID].eth != 0 && _now <= round_[_rID].end)
            return ( (round_[_rID].eth).keysRec(_eth) );
        else if (_now <= round_[_rID].end)  
            return ( (round_[_rID].ico).keysRec(_eth) );
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
        
         
        if (_now > round_[_rID].strt + rndGap_ && round_[_rID].eth != 0 && _now <= round_[_rID].end)
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else if (_now <= round_[_rID].end)  
            return ( (((round_[_rID].ico).keys()).add(_keys)).ethRec(_keys) );
        else  
            return ( (_keys).eth() );
    }
    
     
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff)
            plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

     
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }  
        
     
    function determinePID(F4Ddatasets.EventReturns memory _eventData_)
        private
        returns (F4Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)
        {
             
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            
            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;
            
             
            _eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        return (_eventData_);
    }
    
     
    function verifyTeam(uint256 _team)
        private
        pure
        returns (uint256)
    {
        if (_team < 0 || _team > 3)
            return(2);
        else
            return(_team);
    }
    
     
    function manageRoundAndPlayer(uint256 _pID, F4Ddatasets.EventReturns memory _eventData_)
        private
        returns (F4Ddatasets.EventReturns)
    {
         
        uint256 _rID = rID_;
        
         
        uint256 _now = now;
        
         
         
        if (_now > round_[_rID].end)
        {
             
            if (round_[_rID].ended == false)
            {
                _eventData_ = endRound(_eventData_);
                round_[_rID].ended = true;
            }
            
             
            rID_++;
            _rID++;
            round_[_rID].strt = _now;
            round_[_rID].end = _now.add(rndInit_).add(rndGap_);
        }
        
         
        if (plyr_[_pID].lrnd != _rID)
        {
             
             
            if (plyr_[_pID].lrnd != 0)
                updateGenVault(_pID, plyr_[_pID].lrnd);
            
             
            plyr_[_pID].lrnd = _rID;
            
             
            _eventData_.compressedData = _eventData_.compressedData + 10;
        }
        
        return(_eventData_);
    }
    
     
    function endRound(F4Ddatasets.EventReturns memory _eventData_)
        private
        returns (F4Ddatasets.EventReturns)
    {
         
        uint256 _rID = rID_;
        
         
        if (round_[_rID].eth == 0 && round_[_rID].ico > 0)
            roundClaimICOKeys(_rID);
        
         
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        
         
        uint256 _pot = round_[_rID].pot;
        
         
         
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _own = (_pot.mul(14) / 100);
        owner_.transfer(_own);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_own)).sub(_gen));
        
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }
        
         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

            
         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
                    
         
        round_[_rID + 1].pot += _res;
        
         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;
        
        return(_eventData_);
    }
    
     
    function roundClaimICOKeys(uint256 _rID)
        private
    {
         
        round_[_rID].eth = round_[_rID].ico;
                
         
        round_[_rID].keys = (round_[_rID].ico).keys();
        
         
        round_[_rID].icoAvg = calcAverageICOPhaseKeyPrice(_rID);
                
         
        uint256 _ppt = ((round_[_rID].icoGen).mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = (round_[_rID].icoGen).sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000));
        if (_dust > 0)
            round_[_rID].pot = (_dust).add(round_[_rID].pot);    
                
         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
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
    
     
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
         
        uint256 _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
         
        uint256 _now = now;
        
         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

     
    function distributeExternal(uint256 _eth, F4Ddatasets.EventReturns memory _eventData_)
        private
        returns(F4Ddatasets.EventReturns)
    {
         
        uint256 _own = _eth.mul(14) / 100;
        owner_.transfer(_own);
        
        return(_eventData_);
    }
    
    function potSwap()
        external
        payable
    {
         
        uint256 _rID = rID_ + 1;
        
        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F4Devents.onPotSwapDeposit(_rID, msg.value);
    }
    
     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, uint256 _keys, F4Ddatasets.EventReturns memory _eventData_)
        private
        returns(F4Ddatasets.EventReturns)
    {
         
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;
        
         
        uint256 _aff = _eth / 10;
                
         
         
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F4Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _gen = _gen.add(_aff);
            _aff = 0;
        }
        
         
        _eth = _eth.sub(((_eth.mul(14)) / 100));
        
         
        uint256 _pot = _eth.sub(_gen).sub(_aff);
        
         
         
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
        
         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
     
    function endTx(uint256 _rID, uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F4Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (_rID * 10000000000000000000000000000000000000000000000000000);
        
        emit F4Devents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.P3DAmount,
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }
    
     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(
            msg.sender == owner_,
            "only team just can activate"
        );

         
        require(activated_ == false, "FoMo4D already activated");
        
         
        activated_ = true;
        
         
		rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_ + rndGap_;
    }
}



library F4Ddatasets {
     
     
         
         
         
         
         
         
         
         
     
     
         
         
         
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 P3DAmount;           
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
        uint256 keys;    
        uint256 mask;    
        uint256 ico;     
    }
    struct Round {
        uint256 plyr;    
        uint256 team;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
        uint256 ico;     
        uint256 icoGen;  
        uint256 icoAvg;  
    }
    struct TeamFee {
        uint256 gen;     
    }
    struct PotSplit {
        uint256 gen;     
    }
}


library F4DKeysCalcFast {
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
        return ((((((_eth).mul(1000000000000000000)).mul(200000000000000000000000000000000)).add(2500000000000000000000000000000000000000000000000000000000000000)).sqrt()).sub(50000000000000000000000000000000)) / (100000000000000);
    }
    
     
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((50000000000000).mul(_keys.sq()).add(((100000000000000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
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


library NameFilter {
    
     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
         
        bool _hasNonNumber;
        
         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 || 
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
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