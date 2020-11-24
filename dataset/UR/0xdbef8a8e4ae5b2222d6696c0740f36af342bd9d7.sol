 

pragma solidity ^0.4.24;

 


contract BigOneEvents {
    event onNewPlayer
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
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keyCount,
        uint256 newPot
    );

    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
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

    event onEndRound
    (
        uint256 roundID,
        uint256 roundTypeID,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon
    );
}

contract BigOne is BigOneEvents {
    using SafeMath for *;
    using NameFilter for string;

    UserDataManagerInterface constant private UserDataManager = UserDataManagerInterface(0xD7c181F8de81f90020D5c7c3Dcb4DEED86ed8450);

     
     
     
    address private admin = msg.sender;
    address private shareCom = 0xdc02C8B983c52292672b95b057b7F004244e333A;
    address private groupCut = 0xC153a27a8e460A46fA28F796D5221Dc28828c5A4;

    string constant public name = "bigOne";
    string constant public symbol = "bigOne";   

     
     
     
    uint256 public rID_;    
    uint256 public rTypeID_;

     
     
     
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => BigOneData.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => BigOneData.PlayerRoundData)) public plyrRnds_;    
    mapping (uint256 => uint256) private playerSecret_;

     
     
     
    mapping (uint256 => BigOneData.RoundSetting) public rSettingXTypeID_;    
    mapping (uint256 => BigOneData.Round) public round_;    
    mapping (uint256 => uint256) public currentRoundxType_;
    mapping (uint256 => uint256) private roundCommonSecret_;

    mapping (uint256 => address[]) private winners_;  
    mapping (uint256 => uint256[]) private winNumbers_;  

     
     
     
    constructor() public {
        rID_ = 0;
        rTypeID_ = 0;
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

    modifier onlyDevs() {
        require(admin == msg.sender, "msg sender is not a dev");
        _;
    }

    modifier isWithinLimits(uint256 _eth,uint256 _typeID) {
        require(rSettingXTypeID_[_typeID].isValue, "invaild mode id");
        require(_eth >= rSettingXTypeID_[_typeID].perShare, "less than min allow");
        require(_eth <= rSettingXTypeID_[_typeID].limit, "more than max allow");
        _;
    }

    modifier modeCheck(uint256 _typeID) {
        require(rSettingXTypeID_[_typeID].isValue, "invaild mode id");
        _;
    }

     
     
     
    bool public activated_ = false;
    function activate(uint256 _initSecret)
        onlyDevs()
        public
    {
        require(activated_ == false, "BigOne already activated");
        require(rTypeID_ > 0, "No round mode setup");
        activated_ = true;

        for(uint256 i = 0; i < rTypeID_; i++) {
            rID_++;
            round_[rID_].start = now;
            round_[rID_].typeID = i + 1;
            round_[rID_].count = 1;
            round_[rID_].pot = 0;
            generateRndSecret(rID_,_initSecret);
            currentRoundxType_[i + 1] = rID_;
        }
    }

    function addRoundMode(uint256 _limit, uint256 _perShare, uint256 _shareMax)
        onlyDevs()
        public
    {
        require(activated_ == false, "BigOne already started");

        rTypeID_++;
        rSettingXTypeID_[rTypeID_].id = rTypeID_;
        rSettingXTypeID_[rTypeID_].limit = _limit;
        rSettingXTypeID_[rTypeID_].perShare = _perShare;
        rSettingXTypeID_[rTypeID_].shareMax = _shareMax;
        rSettingXTypeID_[rTypeID_].isValue = true;
    }

     
     
     

    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value,1)
        public
        payable
    {
        determinePID();

        uint256 _pID = pIDxAddr_[msg.sender];

        buyCore(_pID, plyr_[_pID].laff,1);
    }

    function buyXid(uint256 _affCode, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value,_mode)
        public
        payable
    {
        determinePID();

        uint256 _pID = pIDxAddr_[msg.sender];

        if (_affCode == 0 || _affCode == _pID)
        {
            _affCode = plyr_[_pID].laff;

        } else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }

        buyCore(_pID, _affCode, _mode);
    }

    function buyXaddr(address _affCode, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value,_mode)
        public
        payable
    {
        determinePID();

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

        buyCore(_pID, _affID, _mode);
    }

    function buyXname(bytes32 _affCode, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value,_mode)
        public
        payable
    {
        determinePID();

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

        buyCore(_pID, _affID, _mode);
    }

    function reLoadXid(uint256 _affCode, uint256 _eth, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(_eth,_mode)
        public
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        if (_affCode == 0 || _affCode == _pID)
        {
            _affCode = plyr_[_pID].laff;

        } else if (_affCode != plyr_[_pID].laff) {
            plyr_[_pID].laff = _affCode;
        }

        reLoadCore(_pID, _affCode, _eth, _mode);
    }

    function reLoadXaddr(address _affCode, uint256 _eth, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(_eth,_mode)
        public
    {
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

        reLoadCore(_pID, _affID, _eth, _mode);
    }

    function reLoadXname(bytes32 _affCode, uint256 _eth, uint256 _mode)
        isActivated()
        isHuman()
        isWithinLimits(_eth,_mode)
        public
    {
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
        reLoadCore(_pID, _affID, _eth,_mode);
    }

    function withdraw()
        isActivated()
        isHuman()
        public
    {
         
        uint256 _now = now;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _eth;
        uint256 _withdrawFee;
    
         
        _eth = withdrawEarnings(_pID);

         
        if (_eth > 0)
        {
             
            _withdrawFee = _eth / 10;
            uint256 _p1 = _withdrawFee / 2;
            uint256 _p2 = _withdrawFee / 2;
            shareCom.transfer(_p1);
            admin.transfer(_p2);

            plyr_[_pID].addr.transfer(_eth.sub(_withdrawFee));
        }

         
        emit BigOneEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
    }

    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = UserDataManager.registerNameXIDFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];
        if(_isNewPlayer) generatePlayerSecret(_pID);
        emit BigOneEvents.onNewPlayer(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = UserDataManager.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];
        if(_isNewPlayer) generatePlayerSecret(_pID);
        emit BigOneEvents.onNewPlayer(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = UserDataManager.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];
        if(_isNewPlayer) generatePlayerSecret(_pID);
        emit BigOneEvents.onNewPlayer(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

 
 
 

    function iWantXKeys(uint256 _keys,uint256 _mode)
        modeCheck(_mode)
        public
        view
        returns(uint256)
    {
        return _keys.mul(rSettingXTypeID_[_mode].perShare);
    }

    function getWinners(uint256 _mode)
        modeCheck(_mode)
        public
        view
        returns(address[])
    {
        return winners_[_mode];
    }

    function getWinNumbers(uint256 _mode)
        modeCheck(_mode)
        public
        view
        returns(uint256[])
    {
        return winNumbers_[_mode];
    }

    function getPlayerVaults(uint256 _pID)
        public
        view
         
        returns(uint256[])
    {
        uint256[] memory _vaults = new uint256[](3);
        _vaults[0] = plyr_[_pID].win;
        _vaults[1] = plyr_[_pID].gen;
        _vaults[2] = plyr_[_pID].aff;

        return _vaults;
    }

    function getCurrentRoundInfo(uint256 _mode)
        modeCheck(_mode)
        public
        view
        returns(uint256[])
    {
        uint256 _rID = currentRoundxType_[_mode];

        uint256[] memory _roundInfos = new uint256[](6);
        _roundInfos[0] = _mode;
        _roundInfos[1] = _rID;
        _roundInfos[2] = round_[_rID].count;
        _roundInfos[3] = round_[_rID].keyCount;
        _roundInfos[4] = round_[_rID].eth;
        _roundInfos[5] = round_[_rID].pot;

        return _roundInfos;
    }

    function getPlayerInfoByAddress(address _addr,uint256 _mode)
        modeCheck(_mode)
        public
        view
        returns(uint256, uint256, bytes32)
    {
        uint256 _rID = currentRoundxType_[_mode];

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                                
            plyrRnds_[_pID][_rID].eth,           
            plyr_[_pID].name                    
        );
    }

    function getPlayerKeys(address _addr,uint256 _mode)
        public
        view
        returns(uint256[]) 
    {
        uint256 _rID = currentRoundxType_[_mode];

        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        uint256[] memory _keys = new uint256[](plyrRnds_[_pID][_rID].keyCount);
        uint256 _keyIndex = 0;
        for(uint256 i = 0;i < plyrRnds_[_pID][_rID].purchaseIDs.length;i++) {
            uint256 _pIndex = plyrRnds_[_pID][_rID].purchaseIDs[i];
            BigOneData.PurchaseRecord memory _pr = round_[_rID].purchases[_pIndex];
            if(_pr.plyr == _pID) {
                for(uint256 j = _pr.start; j <= _pr.end; j++) {
                    _keys[_keyIndex] = j;
                    _keyIndex++;
                }
            }
        }
        return _keys;
    }

    function getPlayerAff(uint256 _pID)
        public
        view
        returns (uint256[])
    {
        uint256[] memory _affs = new uint256[](3);

        _affs[0] = plyr_[_pID].laffID;
        if (_affs[0] != 0)
        {
             
            _affs[1] = plyr_[_affs[0]].laffID;

            if(_affs[1] != 0)
            {
                 
                _affs[2] = plyr_[_affs[1]].laffID;
            }
        }
        return _affs;
    }

 
 
 

    function buyCore(uint256 _pID, uint256 _affID, uint256 _mode)
        private
    {
        uint256 _rID = currentRoundxType_[_mode];

        if (round_[_rID].pot < rSettingXTypeID_[_mode].limit && round_[_rID].plyr == 0)
        {
            core(_rID, _pID, msg.value, _affID,_mode);
        } else {
            if (round_[_rID].pot >= rSettingXTypeID_[_mode].limit && round_[_rID].plyr == 0 && round_[_rID].ended == false)
            {
                round_[_rID].ended = true;
                endRound(_mode); 
            }
             
            plyr_[_pID].addr.transfer(msg.value);
        }
    }

    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, uint _mode)
        private
    {
        uint256 _rID = currentRoundxType_[_mode];

        if (round_[_rID].pot < rSettingXTypeID_[_mode].limit && round_[_rID].plyr == 0)
        {
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            core(_rID, _pID, _eth, _affID,_mode);
        } else {
            if (round_[_rID].pot >= rSettingXTypeID_[_mode].limit && round_[_rID].plyr == 0 && round_[_rID].ended == false) 
            {
                round_[_rID].ended = true;
                endRound(_mode);      
            }
        }
    }

    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _mode)
        private
    {
        if (plyrRnds_[_pID][_rID].keyCount == 0) 
        {
            managePlayer(_pID,_rID);
        }

        if (round_[_rID].keyCount < rSettingXTypeID_[_mode].shareMax)
        {
            uint256 _ethAdd = ((rSettingXTypeID_[_mode].shareMax).sub(round_[_rID].keyCount)).mul(rSettingXTypeID_[_mode].perShare);
            if(_eth > _ethAdd) {
                plyr_[_pID].gen = plyr_[_pID].gen.add(_eth.sub(_ethAdd)); 
            } else {
                _ethAdd = _eth;
            }

            uint256 _keyAdd = _ethAdd.div(rSettingXTypeID_[_mode].perShare);
            uint256 _keyEnd = (round_[_rID].keyCount).add(_keyAdd);
            
            BigOneData.PurchaseRecord memory _pr;
            _pr.plyr = _pID;
            _pr.start = round_[_rID].keyCount;
            _pr.end = _keyEnd - 1;
            round_[_rID].purchases.push(_pr);
            plyrRnds_[_pID][_rID].purchaseIDs.push(round_[_rID].purchases.length - 1);
            plyrRnds_[_pID][_rID].keyCount += _keyAdd;

            plyrRnds_[_pID][_rID].eth = _ethAdd.add(plyrRnds_[_pID][_rID].eth);
            round_[_rID].keyCount = _keyEnd;
            round_[_rID].eth = _ethAdd.add(round_[_rID].eth);
            round_[_rID].pot = (round_[_rID].pot).add((_ethAdd.mul(80)).div(100));

            distributeExternal(_rID, _pID, _ethAdd, _affID);

            if (round_[_rID].pot >= rSettingXTypeID_[_mode].limit && round_[_rID].plyr == 0 && round_[_rID].ended == false) 
            {
                round_[_rID].ended = true;
                endRound(_mode); 
            }

            emit BigOneEvents.onEndTx
            (
                plyr_[_pID].name,
                msg.sender,
                _eth,
                round_[_rID].keyCount,
                round_[_rID].pot
            );

        } else {
             
            plyr_[_pID].gen = plyr_[_pID].gen.add(_eth);    
        }

    }


 
 
 

    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(UserDataManager), "your not userManager contract");
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
    }

    function determinePID()
        private
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0)
        {
            _pID = UserDataManager.getPlayerID(msg.sender);
            bytes32 _name = UserDataManager.getPlayerName(_pID);
            uint256 _laff = UserDataManager.getPlayerLaff(_pID);

            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
            }

            if (_laff != 0 && _laff != _pID) 
            {
                plyr_[_pID].laff = _laff;
            }
            generatePlayerSecret(_pID);
        }
    }

    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

    function managePlayer(uint256 _pID,uint256 _rID)
        private
    {
        plyr_[_pID].lrnd = _rID;
    }

    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
    {
          
        uint256 _com = _eth / 50;
        uint256 _p3d;

        if (address(admin).call.value((_com / 2))() == false)
        {
            _p3d = _com / 2;
            _com = _com / 2;
        }

        if (address(shareCom).call.value((_com / 2))() == false)
        {
            _p3d = _p3d.add(_com / 2);
            _com = _com.sub(_com / 2);
        }

        _p3d = _p3d.add(distributeAff(_rID,_pID,_eth,_affID));

        if (_p3d > 0)
        {
            shareCom.transfer((_p3d / 2));
            admin.transfer((_p3d / 2));
        }
    }

    function distributeAff(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID)
        private
        returns(uint256)
    {
        uint256 _addP3d = 0;

         
        uint256 _aff1 = _eth.div(10);
        uint256 _aff2 = _eth.div(20);
        uint256 _aff3 = _eth.div(100).mul(3);

        groupCut.transfer(_aff1);

         
         
        if ((_affID != 0) && (_affID != _pID) && (plyr_[_affID].name != ''))
        {
            plyr_[_pID].laffID = _affID;
            plyr_[_affID].aff = _aff2.add(plyr_[_affID].aff);

            emit BigOneEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff2, now);

             
            uint256 _secLaff = plyr_[_affID].laffID;
            if((_secLaff != 0) && (_secLaff != _pID))
            {
                plyr_[_secLaff].aff = _aff3.add(plyr_[_secLaff].aff);
                emit BigOneEvents.onAffiliatePayout(_secLaff, plyr_[_secLaff].addr, plyr_[_secLaff].name, _rID, _pID, _aff3, now);
            } else {
                _addP3d = _addP3d.add(_aff3);
            }
        } else {
            _addP3d = _addP3d.add(_aff2);
        }
        return(_addP3d);
    }

    function generateRndSecret(uint256 _rID, uint256 _lastSecret)
        private
    {
        roundCommonSecret_[_rID] = uint256(keccak256(abi.encodePacked(_lastSecret, _rID, block.difficulty, now)));
    }

    function generatePlayerSecret(uint256 _pID)
        private
    {
        playerSecret_[_pID] = uint256(keccak256(abi.encodePacked(block.blockhash(block.number), msg.sender, block.difficulty, now)));
    }

    function endRound(uint256 _mode)
        private
    {
        uint256 _rID = currentRoundxType_[_mode];

        uint256 _winKey = uint256(keccak256(abi.encodePacked(roundCommonSecret_[_rID], playerSecret_[pIDxAddr_[msg.sender]], block.difficulty, now))).mod(round_[_rID].keyCount);
        uint256 _winPID;
        for(uint256 i = 0;i < round_[_rID].purchases.length; i++) {
            if(round_[_rID].purchases[i].start <= _winKey && round_[_rID].purchases[i].end >= _winKey) {
                _winPID = round_[_rID].purchases[i].plyr;
                break;
            }
        }

        if(_winPID != 0) {
             
            plyr_[_winPID].win = (round_[_rID].pot).add(plyr_[_winPID].win);

            winners_[_mode].push(plyr_[_winPID].addr);
            winNumbers_[_mode].push(_winKey);
        }

        round_[_rID].plyr = _winPID;
        round_[_rID].end = now;

        emit BigOneEvents.onEndRound
        (
            _rID,
            _mode,
            plyr_[_winPID].addr,
            plyr_[_winPID].name,
            round_[_rID].pot
        );

         
        rID_++;
        round_[rID_].start = now;
        round_[rID_].typeID = _mode;
        round_[rID_].count = round_[_rID].count + 1;
        round_[rID_].pot = 0;
        generateRndSecret(rID_,roundCommonSecret_[_rID]);
        currentRoundxType_[_mode] = rID_;
    }
}

 
 
 

interface UserDataManagerInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLaff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}

 
 
 
library BigOneData {

    struct Player {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 lrnd;    
        uint256 laff;    
        uint256 laffID;    
    }
    struct PlayerRoundData {
        uint256 eth;     
        uint256[] purchaseIDs;    
        uint256 keyCount;
    }
    struct RoundSetting {
        uint256 id;
        uint256 limit;   
        uint256 perShare; 
        uint256 shareMax;   
        bool isValue;
    }
    struct Round {
        uint256 plyr;    
        uint256 end;     
        bool ended;      
        uint256 start;    

        uint256 keyCount;    
        BigOneData.PurchaseRecord[] purchases;  
        uint256 eth;     
        uint256 pot;     

        uint256 typeID;
        uint256 count;
    }
    struct PurchaseRecord {
        uint256 plyr;   
        uint256 start;
        uint256 end;
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


library SafeMath 
{
     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}