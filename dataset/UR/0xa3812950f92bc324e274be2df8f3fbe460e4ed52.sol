 

pragma solidity ^0.4.24;
 
contract Star3Devents {
     
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

interface CompanyShareInterface {
    function deposit() external payable;
}

 
 
 
 

contract modularLong is Star3Devents { uint codeLength=0;}

contract Star3Dlong is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using Star3DKeysCalcLong for uint256;

    address public admin;
 
 
 
 
    string constant public name = "Save the planet";
    string constant public symbol = "Star";
    CompanyShareInterface constant private CompanyShare = CompanyShareInterface(0x9d9d35ffd945be6e1a75e975fd696ac4736e65c8);
    
    uint256 private pID_ = 0;    
	uint256 private rndExtra_ = 0 hours;      
    uint256 private rndGap_ = 0 seconds;          
    uint256 constant private rndInit_ = 10 hours;                      
    uint256 constant private rndInc_ = 30 seconds;                
    uint256 constant private rndMax_ = 24 hours;                      
    uint256 public registrationFee_ = 10 finney;                

 
 
 
 
 
 
    uint256 public rID_;     
 
 
 
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => Star3Ddatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => Star3Ddatasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
 
 
 
    mapping (uint256 => Star3Ddatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
 
 
 
    mapping (uint256 => Star3Ddatasets.TeamFee) public fees_;           
    mapping (uint256 => Star3Ddatasets.PotSplit) public potSplit_;      
 
 
 
 
    constructor()
        public
    {
        admin = msg.sender;
		 
         
         
         
         

		 
         
             
        fees_[0] = Star3Ddatasets.TeamFee(32, 45, 10, 3);    
        fees_[1] = Star3Ddatasets.TeamFee(45, 32, 10, 3);    
        fees_[2] = Star3Ddatasets.TeamFee(50, 27, 10, 3);   
        fees_[3] = Star3Ddatasets.TeamFee(40, 37, 10, 3);    

 
 
        potSplit_[0] = Star3Ddatasets.PotSplit(20, 30);   
        potSplit_[1] = Star3Ddatasets.PotSplit(15, 35);    
        potSplit_[2] = Star3Ddatasets.PotSplit(25, 25);   
        potSplit_[3] = Star3Ddatasets.PotSplit(30, 20);   
	}
 
 
 
 
     
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    modifier isRegisteredName()
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(plyr_[_pID].name == "" || _pID == 0, "already has name");
        _;
    }
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(codeLength == 0, "sorry humans only");
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
         
        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        _team = verifyTeam(_team);
         
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
         
        buyCore(_pID, _affID, _team, _eventData_);
    }

    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        Star3Ddatasets.EventReturns memory _eventData_;

         
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
         
        Star3Ddatasets.EventReturns memory _eventData_;

         
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
         
        Star3Ddatasets.EventReturns memory _eventData_;

         
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

         
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            Star3Ddatasets.EventReturns memory _eventData_;

             
			round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

			 
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit Star3Devents.onWithdrawAndDistribute
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
                _eventData_.genAmount
            );

         
        } else {
             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            emit Star3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }


     
    function registerNameXID(string _nameString, uint256 _affCode)
        isHuman()
        isRegisteredName()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;

        bool _isNewPlayer = isNewPlayer(_addr);
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = makePlayerID(msg.sender);
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID)
        {
             
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }
        registerNameCore(_pID, _name);
         
        emit Star3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string _nameString, address _affCode)
        isHuman()
        isRegisteredName()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;

        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bool _isNewPlayer = isNewPlayer(_addr);

        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = makePlayerID(msg.sender);
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
             
            _affID = pIDxAddr_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _name);
         
        emit Star3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXname(string _nameString, bytes32 _affCode)
        isHuman()
        isRegisteredName()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;

        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

        bool _isNewPlayer = isNewPlayer(_addr);

        Star3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = makePlayerID(msg.sender);

        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
             
            _affID = pIDxName_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

        registerNameCore(_pID, _name);
         
        emit Star3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameCore(uint256 _pID, bytes32 _name)
        private
    {

         
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

         
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
        }
         
        CompanyShare.deposit.value(msg.value)();
    }

    function isNewPlayer(address _addr)
    public
    view
    returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
             
            return (true);
        } else {
            return (false);
        }
    }
 
 
 
 
     
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        uint256 _timePrice = getBuyPriceTimes();
         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return (((round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000)).mul(_timePrice));
        else  
            return ( 750000000000000 );  
    }

    function getBuyPriceTimes()
        public
        view
        returns(uint256)
    {
        uint256 timeLeft = getTimeLeft();
        if(timeLeft <= 300)
        {
            return 10;
        }else{
            return 1;
        }
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
        returns(uint256 ,uint256, uint256)
    {
         
        uint256 _rID = rID_;

         
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
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
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].endGen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }

     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

        return
        (
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
            plyr_[_pID].name,                    
            plyrRnds_[_pID][_rID].keys,          
            plyr_[_pID].win,                     
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
            plyr_[_pID].aff,                     
            plyrRnds_[_pID][_rID].eth            
        );
    }

 
 
 
 
     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, Star3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);

         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                 
                emit Star3Devents.onBuyAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.genAmount
                );
            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, Star3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
             
             
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

             
            core(_rID, _pID, _eth, _affID, _team, _eventData_);

         
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit Star3Devents.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.genAmount
            );
        }
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, Star3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

         
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

         
        if (_eth > 1000000000)
        {
            uint256 _timeLeft = getTimeLeft();
             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth, _timeLeft);

             
            if (_keys >= 1000000000000000000)
            {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;
            if (round_[_rID].team != _team)
                round_[_rID].team = _team;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
            }

             
            _eventData_.compressedData = _eventData_.compressedData;

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);
            if(_timeLeft <= 300)
            {
                uint256 devValue = (_eth.mul(90) / 100);
                _eth = _eth.sub(devValue);
                CompanyShare.deposit.value(devValue)();
            }

             
            _eventData_ = distributeExternal(_pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

             
		    endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }
 
 
 
 
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

     
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;
        uint256 _timeLeft = getTimeLeft();

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth, _timeLeft) );
        else  
            return ( (_eth).keys(0) );
    }

     
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;
        uint256 _timePrice = getBuyPriceTimes();
         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return (( (round_[_rID].keys.add(_keys)).ethRec(_keys) ).mul(_timePrice));
        else  
            return ( (_keys).eth() );
    }
    function makePlayerID(address _addr)
    private
    returns (uint256)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
             
            return (pID_);
        } else {
            return (pIDxAddr_[_addr]);
        }
    }


    function getPlayerName(uint256 _pID)
    external
    view
    returns (bytes32)
    {
        return (plyr_[_pID].name);
    }
    function getPlayerLAff(uint256 _pID)
        external
        view
        returns (uint256)
    {
        return (plyr_[_pID].laff);
    }

     
    function determinePID(Star3Ddatasets.EventReturns memory _eventData_)
        private
        returns (Star3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)
        {
             
            _pID = makePlayerID(msg.sender);

            bytes32 _name = "";
            uint256 _laff = 0;
             
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

     
    function managePlayer(uint256 _pID, Star3Ddatasets.EventReturns memory _eventData_)
        private
        returns (Star3Ddatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

     
    function endRound(Star3Ddatasets.EventReturns memory _eventData_)
        private
        returns (Star3Ddatasets.EventReturns)
    {
         
        uint256 _rID = rID_;

         
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

         
        uint256 _pot = round_[_rID].pot;

         
         
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 50);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].endGen)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen));

         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

         
        CompanyShare.deposit.value(_com)();

         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
 
 

         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;

         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;

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


     
    function distributeExternal(uint256 _pID, uint256 _eth, uint256 _affID, Star3Ddatasets.EventReturns memory _eventData_)
        private
        returns(Star3Ddatasets.EventReturns)
    {
         
        uint256 _aff = _eth / 10;
        uint256 _affLeader = (_eth.mul(3)) / 100;
        uint256 _affLeaderID = plyr_[_affID].laff;
        if (_affLeaderID == 0)
        {
            _aff = _aff.add(_affLeader);
        } else{
            if (_affLeaderID != _pID && plyr_[_affLeaderID].name != '')
            {
                plyr_[_affLeaderID].aff = _affLeader.add(plyr_[_affLeaderID].aff);
            }else{
                _aff = _aff.add(_affLeader);
            }
        }
         
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
        } else {
             
            CompanyShare.deposit.value(_aff)();
        }
        return(_eventData_);
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, Star3Ddatasets.EventReturns memory _eventData_)
        private
        returns(Star3Ddatasets.EventReturns)
    {
         
        uint256 _gen = (_eth.mul(fees_[_team].firstGive)) / 100;
         
        uint256 _dev = (_eth.mul(fees_[_team].giveDev)) / 100;
         
        _eth = _eth.sub(((_eth.mul(13)) / 100)).sub(_dev);
         
        uint256 _pot =_eth.sub(_gen);

         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        CompanyShare.deposit.value(_dev)();
 
 

         
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

     
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, Star3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit Star3Devents.onEndTx
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
            _eventData_.genAmount,
            _eventData_.potAmount
        );
    }
 
 
 
 
     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(
			msg.sender == admin,
            "only team just can activate"
        );

		 
 

         
        require(activated_ == false, "Star3d already activated");

         
        activated_ = true;

         
		rID_ = 1;
        round_[1].strt = now;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
    
    
    function recycleAfterEnd() public{ 
          require(
			msg.sender == admin,
            "only team can call"
        );
        require(
			round_[rID_].pot < 1 ether,
			"people still playing"
		);
        
        selfdestruct(address(CompanyShare));
    }
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


 
 
 
 
library Star3Ddatasets {
     
     
         
         
         
         
         
         
         
         
         
         
         
         
     
     
         
         
         
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
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
        uint256 icoGen;  
        uint256 icoAvg;  
    }
    struct TeamFee {
        uint256 firstPot;    
        uint256 firstGive;  
        uint256 giveDev; 
        uint256 giveAffLeader; 

    }
    struct PotSplit {
        uint256 endNext;  
        uint256 endGen;  
    }
}

 
 
 
 
library Star3DKeysCalcLong {
    using SafeMath for *;
     
    function keysRec(uint256 _curEth, uint256 _newEth, uint256 _timeLeft)
        internal
        pure
        returns (uint256)
    {
        if(_timeLeft <= 300)
        {
            return keys(_newEth, _timeLeft);
        }else{
            return(keys((_curEth).add(_newEth), _timeLeft).sub(keys(_curEth, _timeLeft)));
        }
    }

     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
    function keys(uint256 _eth, uint256 _timeLeft)
        internal
        pure
        returns(uint256)
    {
        uint256 _timePrice = getBuyPriceTimesByTime(_timeLeft);
        uint256 _keys = ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000) / (_timePrice.mul(10));
        if(_keys >= 990000000000000000 && _keys < 1000000000000000000)
        {
            return 1000000000000000000;
        }
        return _keys;
    }

     
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return (((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq())).mul(10);
    }
    function getBuyPriceTimesByTime(uint256 _timeLeft)
        public
        pure
        returns(uint256)
    {
        if(_timeLeft <= 300)
        {
            return 10;
        }else{
            return 1;
        }
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