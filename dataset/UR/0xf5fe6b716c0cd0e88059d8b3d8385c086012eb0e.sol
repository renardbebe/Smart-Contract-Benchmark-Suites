 

pragma solidity ^0.4.24;

 
 
 
 
contract F3Devents {
     
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
        uint256 potAmount,
        uint256 airDropPot
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

 
 
 
 

contract modularLong is F3Devents { }

contract FoMo3Dlong is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;

     
    address private otherF3D_;
    uint8 private rSees_;
    
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xED8c249B7EB8d5b3cF7e0d6CcFA270249f7C0CeF);

 
 
 
 
    string constant public name = "Gold medal winner Official";
    string constant public symbol = "Gold";
    uint256 private rndExtra_ = 60;      
    uint256 private rndGap_ = 60;          
    uint256 constant private rndInit_ = 24 hours;                 
    uint256 constant private rndInc_ = 30 seconds;               
    uint256 constant private rndMax_ = 24 hours;                 
    address constant private ceo = 0x918b8dc988e3702DA4625d69E3D043E8aA9358e6;
    address constant private cfo = 0xCC221D6154A5091919240b36d476C2BdeAf246BD;
    address constant private coo = 0x139aAc9edD31015327394160516C26E8f3Ee06AB;
    address constant private cto = 0xDe0015b72D1dC1F32768Dc1983788F4c32F70f05;
 
 
 
 
    uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      
    uint256 public rID_;     
 
 
 
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => F3Ddatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
 
 
 
    mapping (uint256 => F3Ddatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
 
 
 
    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;           
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;      
 
 
 
 
    constructor()
        public
    {
         
         
         
         
         

         
         
             
        fees_[0] = F3Ddatasets.TeamFee(48,0);   
        fees_[1] = F3Ddatasets.TeamFee(28,0);   
        fees_[2] = F3Ddatasets.TeamFee(18,0);   
        fees_[3] = F3Ddatasets.TeamFee(38,0);   

         
         
        potSplit_[0] = F3Ddatasets.PotSplit(38,0);  
        potSplit_[1] = F3Ddatasets.PotSplit(28,0);  
        potSplit_[2] = F3Ddatasets.PotSplit(23,0);  
        potSplit_[3] = F3Ddatasets.PotSplit(33,0);  
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
        require(_eth >= 100000000000000000, "pocket lint: not a valid currency");
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
         
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        buyCore(_pID, plyr_[_pID].laff, 0, _eventData_);
    }

     
    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
       
        public
    {
         
        F3Ddatasets.EventReturns memory _eventData_;

         
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
       
        public
    {
         
        F3Ddatasets.EventReturns memory _eventData_;

         
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
       
        public
    {
         
        F3Ddatasets.EventReturns memory _eventData_;

         
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
             
            F3Ddatasets.EventReturns memory _eventData_;

             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit F3Devents.onWithdrawAndDistribute
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

             
            emit F3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
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

         
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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

         
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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

         
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
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
            return ( 1000000000000000 );  
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
                uint256 bonus = 0;
                uint256 count = 0;
                uint256 l = round_[_rID].lastNum;
            for(uint i = 0; i<l; i++)
            { 
            uint _pid = round_[_rID].lastPlys[i]; 
            count += plyr_[_pid].lbks;
            }
            bonus = (((round_[_rID].pot).mul(48)) / 100).mul(plyr_[_pID].lbks) / count;
                return
                (
                    (plyr_[_pID].win).add(bonus),
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
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }

     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

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
            rndTmEth_[_rID][3],              
            airDropTracker_ + (airDropPot_ * 1000)               
        );
    }

     
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256,uint256)
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
            plyrRnds_[_pID][_rID].eth,            
            plyr_[_pID].laff
        );
    }

 
 
 
 
     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

      
         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {   

    
            insertLastPlys(_pID);
             
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);

         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                 
                emit F3Devents.onBuyAndDistribute
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
                    _eventData_.P3DAmount,
                    _eventData_.genAmount
                );
            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
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

             
            emit F3Devents.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.P3DAmount,
                _eventData_.genAmount
            );
        }
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);


         
        if (_eth > 1000000000)
        {

             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth,round_[_rID].keys);

             
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                 
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
            }

         
            if (airdrop(_team) == true)
            {
                 
                uint256 _prize;
               
                 _prize = ((airDropPot_).mul(50)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                     
                    airDropPot_ = (airDropPot_).sub(_prize);

                     
                    _eventData_.compressedData += 300000000000000000000000000000000;
           
            }
     

             
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyr_[_pID].lbks = _keys;
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _eventData_);
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

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth,round_[_rID].keys) );
        else  
            return ( (_eth).keys(round_[_rID].keys) );
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

     
    function determinePID(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
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

     
    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

     
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
         
        uint256 _rID = rID_;

         
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;


         
        uint256 _pot = round_[_rID].pot;

         
         
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 25);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);

         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

        payLast(_win);

     
         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
      
        if (_com > 0)
         {
            ceo.transfer( _com.mul(20) / 100);
            cfo.transfer( _com.mul(20) / 100);
            coo.transfer( _com.mul(50) / 100);
            cto.transfer(_com.mul(10) / 100);
         }
         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.P3DAmount = _p3d;
        _eventData_.newPot = _res;

         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
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
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInit_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }

     
    function airdrop(uint256 _temp)
        private
        view
        returns(bool)
    {
        uint8 cc= 0;
        uint8[5] memory randomNum;
         if(_temp == 0){
            randomNum[0]=6;
            randomNum[1]=22;
            randomNum[2]=38;
            randomNum[3]=59;
            randomNum[4]=96;
            cc = 5;
            
            }else if(_temp == 1){
            randomNum[0]=9;
            randomNum[1]=25;
            randomNum[2]=65;
            randomNum[3]=79;
            cc = 4;
            }else if(_temp == 2){
            randomNum[0]=2;
            randomNum[1]=57;
            randomNum[2]=32;
            cc = 3;
         
            }else if(_temp == 3){
            randomNum[0]=44;
            randomNum[1]=90;
            cc = 2;
         
            }
        
        
        uint256 seed = uint256(keccak256(abi.encodePacked(

            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)

        )));
        seed = seed - ((seed / 100) * 100);
        for(uint j=0;j<cc;j++)
        {
           if(randomNum[j] == seed)
           {
             return(true);
           } 
        }
       
            return(false);
    }
    
     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
         
        uint256 _com = _eth / 5;
     
         
        uint256 _aff;
        _aff = _eth.mul(10) / 100;
      
         
         
        if (_affID != _pID && plyr_[_affID].name != "") {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
             emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
             
         
            ceo.transfer(_aff.mul(40) / 100);
            cfo.transfer(_aff.mul(40) / 100);
            cto.transfer(_aff.mul(20) / 100);
        }

 
        if (_com > 0)
        {
           
            
            ceo.transfer(_com.mul(20) / 100);
            cfo.transfer(_com.mul(20) / 100);
            coo.transfer( _com.mul(50) / 100);
            cto.transfer(_com.mul(10) / 100);
             
            _eventData_.P3DAmount = _com.add(_eventData_.P3DAmount);
        }

        return(_eventData_);
    }

    function potSwap()
        external
        payable
    {
         
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
        emit F3Devents.onPotSwapDeposit(_rID, msg.value);
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
         
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;

         
        uint256 _air = (_eth.mul(2)/ 100);
        airDropPot_ = airDropPot_.add(_air);

         
        _eth = _eth.sub(((_eth.mul(20)) / 100).add((_eth.mul(12)) / 100));

         
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

         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

     
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

        emit F3Devents.onEndTx
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
            _eventData_.potAmount,
            airDropPot_
        );
    }
 
 
 
 
     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(
            msg.sender == 0x100d5695a0b35bbb8c044AEFef7C7b278E5843e1,
            "only team just can activate"
        );

         
         

         
        require(activated_ == false, "fomo3d already activated");

         
        activated_ = true;

         
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
    function setOtherFomo(address _otherF3D)
        public
    {
         
        require(
            msg.sender == 0x100d5695a0b35bbb8c044AEFef7C7b278E5843e1,
            "only team just can activate"
        );

         
        require(address(otherF3D_) == address(0), "silly dev, you already did that");

         
         
        otherF3D_ = _otherF3D;
    }


    function insertLastPlys(uint256 _pID)
    private
    {   
        uint256 _rID = rID_;    
        if(round_[_rID].lastNum == 0)
        {   round_[_rID].lastPlys[0] = _pID;
            round_[_rID].lastNum++;
             
            }else if(round_[_rID].lastNum <10)
            {
                if(round_[rID_].lastPlys[round_[_rID].lastNum-1] != _pID)
                {
                    bool repeat = false;
                    for(uint j=0; j<round_[_rID].lastNum; j++)
                    {
                        if(_pID == round_[rID_].lastPlys[j])
                        {
                            repeat = true;
                            break;
                        }
                    }
                    if(!repeat){
                        round_[rID_].lastPlys[round_[_rID].lastNum] = _pID;
                        round_[_rID].lastNum++;
                     
                    }else{
                        for(j; j<round_[_rID].lastNum-1; j++){
                            round_[rID_].lastPlys[j] = round_[rID_].lastPlys[j+1];
                        }
                        round_[rID_].lastPlys[round_[_rID].lastNum-1] = _pID;
                    }
                }    
            }else{
             if(round_[rID_].lastPlys[round_[_rID].lastNum-1] != _pID)
             {
                round_[_rID].lastNum = 10;
                for(j=0; j<round_[_rID].lastNum-1; j++){
                    round_[rID_].lastPlys[j] = round_[rID_].lastPlys[j+1];
                    }
                round_[rID_].lastPlys[round_[_rID].lastNum-1] = _pID;
            }    
        }  
    }

   
    function payLast(uint _win)
    private{
        uint256 _rID = rID_;
        uint l = round_[_rID].lastNum;
        uint _pid;
        uint i;
        uint256  count = 0;
       
        for( i = 0; i<l; i++)
        {   
            _pid = round_[_rID].lastPlys[i];       
            count += plyr_[_pid].lbks;
        }
        for( i = 0; i<l; i++)
        {  
            _pid = round_[_rID].lastPlys[i];
            plyr_[_pid].win = (_win.mul(plyr_[_pid].lbks / count) ).add(plyr_[_pid].win);  

        }
    
    }

}

 
 
 
 
library F3Ddatasets {
     
     
         
         
         
         
         
         
         
         
         
         
         
         
     
     
         
         
         
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
        uint256 lbks;    
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
        uint256[10] lastPlys;  
        uint256 lastNum;         
    }
    struct TeamFee {
        uint256 gen;     
        uint256 p3d;     
    }
    struct PotSplit {
        uint256 gen;     
        uint256 p3d;     
    }
}

 
 
 
 
library F3DKeysCalcLong {
    using SafeMath for *;
     
      
    function keysRec(uint256 _curEth, uint256 _newEth,uint256 _curKeys)
        internal
        pure
        returns (uint256)
    {
         if(_curKeys<=0){
            _curKeys=1000000000000000000;
        }   
        return (keys(_newEth,_curKeys));
 
    }
     
      
     function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
       if(_curKeys<=0){
            _curKeys=1000000000000000000;
        }
        return eth(_curKeys).mul(_sellKeys)/1000000000000000000;
     
    }

     
      
     function keys(uint256 _eth,uint256 _curKeys)
        internal
        pure
        returns(uint256)
    {
       
        uint a =1000000000000000;
        uint b =2000000000;
        if(_curKeys<=0){
            _curKeys=1000000000000000000;
        }
        uint c = a .add((b.mul((_curKeys.sub(1000000000000000000))))/1000000000000000000);
        return (_eth.mul(1000000000000000000)/(c));
    }
     
      
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {   
        uint a =1000000000000000;
        uint b =2000000000;
        uint c = a .add((b.mul((_keys.sub(1000000000000000000))))/1000000000000000000);
        
        return c;
    }
}

 
 
 
 
interface otherFoMo3D {
    function potSwap() external payable;
}

interface F3DexternalSettingsInterface {
    function getFastGap() external returns(uint256);
    function getLongGap() external returns(uint256);
    function getFastExtra() external returns(uint256);
    function getLongExtra() external returns(uint256);
}

interface DiviesInterface {
    function deposit() external payable;
}

interface JIincForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address, bool);
    function startMigration(address _newCorpBank) external returns(bool);
    function cancelMigration() external returns(bool);
    function finishMigration() external returns(bool);
    function setup(address _firstCorpBank) external;
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