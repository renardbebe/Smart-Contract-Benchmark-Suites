 

pragma solidity ^0.4.24;

 

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns(uint256);
    function getPlayerName(uint256 _pID) external view returns(bytes32);
    function getPlayerLAff(uint256 _pID) external view returns(uint256);
    function getPlayerAddr(uint256 _pID) external view returns(address);
    function getNameFee() external view returns(uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}

 

interface TeamPerfitForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address);
}

 

interface DRSCoinInterface {
    function mint(address _to, uint256 _amount) external;
    function profitEth() external payable;
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
        assert(b > 0);
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

 

 
library DRSDatasets {
     
     
         
         
         
         
         

     
     
         
         
         
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;

        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           

        uint256 newPot;              
        uint256 genAmount;           
        uint256 potAmount;           

        address genAddr;
        uint256 genKeyPrice;
    }

    function setNewPlayerFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 1;
        return _event;
    }

    function setJoinedRoundFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 10;
        return _event;
    }

    function setNewLeaderFlag(EventReturns _event) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + 100;
        return _event;
    }

    function setRoundEndTime(EventReturns _event, uint256 roundEndTime) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + roundEndTime * (10**3);
        return _event;
    }

    function setTimestamp(EventReturns _event, uint256 timestamp) internal pure returns(EventReturns) {
        _event.compressedData = _event.compressedData + timestamp * (10**14);
        return _event;
    }

    function setPID(EventReturns _event, uint256 _pID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + _pID;
        return _event;
    }

    function setWinPID(EventReturns _event, uint256 _winPID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + (_winPID * (10**26));
        return _event;
    }

    function setRID(EventReturns _event, uint256 _rID) internal pure returns(EventReturns) {
        _event.compressedIDs = _event.compressedIDs + (_rID * (10**52));
        return _event;
    }

    function setWinner(EventReturns _event, address _winnerAddr, bytes32 _winnerName, uint256 _amountWon)
        internal pure returns(EventReturns) {
        _event.winnerAddr = _winnerAddr;
        _event.winnerName = _winnerName;
        _event.amountWon = _amountWon;
        return _event;
    }

    function setGenInfo(EventReturns _event, address _genAddr, uint256 _genKeyPrice)
        internal pure returns(EventReturns) {
        _event.genAddr = _genAddr;
        _event.genKeyPrice = _genKeyPrice;
    }

    function setNewPot(EventReturns _event, uint256 _newPot) internal pure returns(EventReturns) {
        _event.newPot = _newPot;
        return _event;
    }

    function setGenAmount(EventReturns _event, uint256 _genAmount) internal pure returns(EventReturns) {
        _event.genAmount = _genAmount;
        return _event;
    }

    function setPotAmount(EventReturns _event, uint256 _potAmount) internal pure returns(EventReturns) {
        _event.potAmount = _potAmount;
        return _event;
    }

    struct Player {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
         
        uint256 lrnd;    
         
    }

    struct PlayerRound {
        uint256 eth;     
        uint256 keys;    
    }

    struct Round {
        uint256 plyr;    

        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
    }

    struct BuyInfo {
        address addr;    
        bytes32 name;    
        uint256 pid;     
        uint256 keyPrice;
        uint256 keyIndex;
    }
}

 

contract DRSEvents {
     
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
         
         
         
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
        uint256 keyIndex,

        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,

        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount,

        address genAddr,
        uint256 genKeyPrice
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

    event onBuyKeyFailure
    (
        uint256 roundID,
        uint256 indexed playerID,
        uint256 amount,
        uint256 keyPrice,
        uint256 timeStamp
    );
}

 

contract ReserveBag is DRSEvents {
    using SafeMath for uint256;
    using NameFilter for string;
    using DRSDatasets for DRSDatasets.EventReturns;

    TeamPerfitForwarderInterface public teamPerfit;
    PlayerBookInterface public playerBook;
    DRSCoinInterface public drsCoin;

     
    string constant public name = "Reserve Bag";
    string constant public symbol = "RB";

    uint256 constant private initKeyPrice = (10**18);

    uint256 private rndExtra_ = 0;        
    uint256 private rndGap_ = 0;          

    uint256 constant private rndMax_ = 24 hours;                 
     

    uint256 public rID_;     

    uint256 public keyPrice = initKeyPrice;
    uint256 public keyBought = 0;

    address public owner;

    uint256 public teamPerfitAmuont = 0;

    uint256 public rewardInternal = 36;
     
    uint256 public keyPriceIncreaseRatio = 8;
    uint256 public genRatio = 90;

    uint256 public drsCoinDividendRatio = 40;
    uint256 public teamPerfitRatio = 5;

    uint256 public ethMintDRSCoinRate = 100;

    bool public activated_ = false;

     
    mapping(address => uint256) public pIDxAddr_;           
    mapping(bytes32 => uint256) public pIDxName_;           
    mapping(uint256 => DRSDatasets.Player) public plyr_;    
    mapping(uint256 => mapping(uint256 => DRSDatasets.PlayerRound)) public plyrRnds_;     
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_;  

    DRSDatasets.BuyInfo[] buyinfos;
    uint256 private startIndex;
    uint256 private endIndex;

     
    mapping(uint256 => DRSDatasets.Round) public round_;    

     

    constructor(address _teamPerfit, address _playBook, address _drsCoin) public
    {
        owner = msg.sender;

        teamPerfit = TeamPerfitForwarderInterface(_teamPerfit);
        playerBook = PlayerBookInterface(_playBook);
        drsCoin = DRSCoinInterface(_drsCoin);

        startIndex = 0;
        endIndex = 0;
    }

    modifier onlyOwner {
        assert(owner == msg.sender);
        _;
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);

        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000 * (10**18), "no vitalik, no");
        _;
    }

    function pushBuyInfo(DRSDatasets.BuyInfo info) internal {
        if(endIndex == buyinfos.length) {
            buyinfos.push(info);
        } else if(endIndex < buyinfos.length) {
            buyinfos[endIndex] = info;
        } else {
             
            revert();
        }

        endIndex = (endIndex + 1) % (rewardInternal + 1);

        if(endIndex == startIndex) {
            startIndex = (startIndex + 1) % (rewardInternal + 1);
        }
    }

     
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        DRSDatasets.EventReturns memory _eventData_;
        _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        buyCore(_pID, _eventData_);
    }

    function buyKey()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        DRSDatasets.EventReturns memory _eventData_;
        _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        buyCore(_pID, _eventData_);
    }

    function reLoadXaddr(uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        uint256 _pID = pIDxAddr_[msg.sender];

        require(_pID != 0, "reLoadXaddr can not be called by new players");

         
        DRSDatasets.EventReturns memory _eventData_;

         
        reLoadCore(_pID, _eth, _eventData_);
    }

    function withdrawTeamPerfit()
        isActivated()
        onlyOwner()
        public
    {
        if(teamPerfitAmuont > 0) {
            uint256 _perfit = teamPerfitAmuont;

            teamPerfitAmuont = 0;

            owner.transfer(_perfit);
        }
    }

    function getTeamPerfitAmuont() public view returns(uint256) {
        return teamPerfitAmuont;
    }

     
    function withdraw()
        isActivated()
        isHuman()
        public
    {
         
        uint256 _pID = pIDxAddr_[msg.sender];

        require(_pID != 0, "withdraw can not be called by new players");

         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        uint256 _eth;

         
        if(_now > round_[_rID].end && !round_[_rID].ended && round_[_rID].plyr != 0)
        {
             
            DRSDatasets.EventReturns memory _eventData_;

             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eth = withdrawEarnings(_pID);

             
            if(_eth > 0) {
                plyr_[_pID].addr.transfer(_eth);    
            }

             
            _eventData_ = _eventData_.setTimestamp(_now);
            _eventData_ = _eventData_.setPID(_pID);

             
            emit DRSEvents.onWithdrawAndDistribute
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

             
            if(_eth > 0) {
                plyr_[_pID].addr.transfer(_eth);
            }

             
            emit DRSEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

    function registerName(string _nameString, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, ) = playerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, address(0), _all);

        uint256 _pID = pIDxAddr_[_addr];

        emit DRSEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _paid, now);
    }

     
    function getBuyPrice() public view returns(uint256)
    {  
        return keyPrice;
    }

     
    function getTimeLeft() public view returns(uint256)
    {
        uint256 _rID = rID_;

        uint256 _now = now;

        if(_now < round_[_rID].end)
            if(_now > round_[_rID].strt + rndGap_)
                return (round_[_rID].end).sub(_now);
            else
                return (round_[_rID].strt + rndGap_).sub(_now);
        else
            return 0;
    }

     
    function getPlayerVaults(uint256 _pID) public view returns(uint256, uint256)
    {
        uint256 _rID = rID_;

        uint256 _now = now;

         
        if(_now > round_[_rID].end && !round_[_rID].ended && round_[_rID].plyr != 0) {
             
            if(round_[_rID].plyr == _pID) {
                return
                (
                    (plyr_[_pID].win).add(getWin(round_[_rID].pot)),
                    plyr_[_pID].gen
                );
            }
        }

        return (plyr_[_pID].win, plyr_[_pID].gen);
    }

     
    function getCurrentRoundInfo() public view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32)
    {
        uint256 _rID = rID_;

        uint256 _winPID = round_[_rID].plyr;

        return
        (
            _rID,                            
            round_[_rID].end,                
            round_[_rID].strt,               
            round_[_rID].pot,                

            keyPrice,                        
            keyBought.add(1),                

            _winPID,                         
            plyr_[_winPID].addr,             
            plyr_[_winPID].name              
        );
    }

     
    function getPlayerInfoByAddress(address _addr) public view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;
        
        if(_addr == address(0)) {
            _addr == msg.sender;
        }

        uint256 _pID = pIDxAddr_[_addr];

        if(_pID == 0) {
            return (0, "", 0, 0, 0, 0);
        }

        return
        (
            _pID,                                
            plyr_[_pID].name,                    
            plyrRnds_[_pID][_rID].keys,          
            plyr_[_pID].win,                     
            plyr_[_pID].gen,                     
            plyrRnds_[_pID][_rID].eth            
        );
    }

     
    function buyCore(uint256 _pID, DRSDatasets.EventReturns memory _eventData_) private
    {
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if(_now >= round_[_rID].strt.add(rndGap_) && (_now <= round_[_rID].end || round_[_rID].plyr == 0)) {
             
            core(_rID, _pID, msg.value, _eventData_);

         
        } else {
             
            if(_now > round_[_rID].end && !round_[_rID].ended) {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_ = _eventData_.setTimestamp(_now);
                _eventData_ = _eventData_.setPID(_pID);

                 
                emit DRSEvents.onBuyAndDistribute
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

     
    function reLoadCore(uint256 _pID, uint256 _eth, DRSDatasets.EventReturns memory _eventData_) private
    {
        uint256 _rID = rID_;

        uint256 _now = now;

         
        if(_now > round_[_rID].strt.add(rndGap_) && (_now <= round_[_rID].end || round_[_rID].plyr == 0)) {
             
             
             
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

             
            core(_rID, _pID, _eth, _eventData_);

         
        } else {
             
            if(_now > round_[_rID].end && !round_[_rID].ended) {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_ = _eventData_.setTimestamp(_now);
                _eventData_ = _eventData_.setPID(_pID);

                 
                emit DRSEvents.onReLoadAndDistribute
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
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, DRSDatasets.EventReturns memory _eventData_) private
    {
        if(_eth < keyPrice) {
            plyr_[_pID].gen = plyr_[_pID].gen.add(_eth);
            emit onBuyKeyFailure(_rID, _pID, _eth, keyPrice, now);
            return;
        }

         
        if(plyrRnds_[_pID][_rID].keys == 0) {
            _eventData_ = managePlayer(_pID, _eventData_);
        }

         
        uint256 _keys = 1;

        uint256 _ethUsed = keyPrice;
        uint256 _ethLeft = _eth.sub(keyPrice);

        updateTimer(_rID);

         
        if(round_[_rID].plyr != _pID) {
            round_[_rID].plyr = _pID;
        }

         
        _eventData_ = _eventData_.setNewLeaderFlag();

         
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
        plyrRnds_[_pID][_rID].eth = _ethUsed.add(plyrRnds_[_pID][_rID].eth);

         
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _ethUsed.add(round_[_rID].eth);

         
        uint256 _ethExt = distributeExternal(_ethUsed);
        _eventData_ = distributeInternal(_rID, _ethUsed, _ethExt, _eventData_);

        bytes32 _name = plyr_[_pID].name;

        pushBuyInfo(DRSDatasets.BuyInfo(msg.sender, _name, _pID, keyPrice, keyBought));

         
        uint256 _keyIndex = keyBought;

        keyBought = keyBought.add(1);
        keyPrice = keyPrice.mul(1000 + keyPriceIncreaseRatio).div(1000);

        if(_ethLeft > 0) {
            plyr_[_pID].gen = _ethLeft.add(plyr_[_pID].gen);
        }

         
        endTx(_pID, _ethUsed, _keyIndex, _eventData_);
    }

     
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name) external
    {
        require(msg.sender == address(playerBook), "your not playerNames contract.");

        if(pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;

        if(pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;

        if(plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;

        if(plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;

        if(!plyrNames_[_pID][_name])
            plyrNames_[_pID][_name] = true;
    }

     
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external
    {
        require(msg.sender == address(playerBook), "your not playerNames contract.");

        if(!plyrNames_[_pID][_name])
            plyrNames_[_pID][_name] = true;
    }

     
    function determinePID(DRSDatasets.EventReturns memory _eventData_) private returns(DRSDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

         
        if(_pID == 0)
        {
             
            _pID = playerBook.getPlayerID(msg.sender);
            bytes32 _name = playerBook.getPlayerName(_pID);

             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            if(_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

             
            _eventData_ = _eventData_.setNewPlayerFlag();
        }

        return _eventData_;
    }

    function managePlayer(uint256 _pID, DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_ = _eventData_.setJoinedRoundFlag();
        
        return _eventData_;
    }

    function getWin(uint256 _pot) private pure returns(uint256) {
        return _pot / 2;
    }

    function getDRSCoinDividend(uint256 _pot) private view returns(uint256) {
        return _pot.mul(drsCoinDividendRatio).div(100);
    }

    function getTeamPerfit(uint256 _pot) private view returns(uint256) {
        return _pot.mul(teamPerfitRatio).div(100);
    }

    function mintDRSCoin() private {
         
        if(startIndex == endIndex) {
            return;
        }

         
        if((startIndex + 1) % (rewardInternal + 1) == endIndex) {
            return;
        }

         
        for(uint256 i = startIndex; (i + 1) % (rewardInternal + 1) != endIndex; i = (i + 1) % (rewardInternal + 1)) {
            drsCoin.mint(buyinfos[i].addr, buyinfos[i].keyPrice.mul(ethMintDRSCoinRate).div(100));
        }
    }

     
    function endRound(DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
        uint256 _rID = rID_;

        uint256 _winPID = round_[_rID].plyr;

        uint256 _pot = round_[_rID].pot;

         
        uint256 _win = getWin(_pot);

         
        uint256 _drsCoinDividend = getDRSCoinDividend(_pot);

         
        uint256 _com = getTeamPerfit(_pot);

         
        uint256 _newPot = _pot.sub(_win).sub(_drsCoinDividend).sub(_com);

         
        depositTeamPerfit(_com);

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

         
        mintDRSCoin();

         
        drsCoin.profitEth.value(_drsCoinDividend)();

         
        _eventData_ = _eventData_.setRoundEndTime(round_[_rID].end);
        _eventData_ = _eventData_.setWinPID(_winPID);
        _eventData_ = _eventData_.setWinner(plyr_[_winPID].addr, plyr_[_winPID].name, _win);
        _eventData_ = _eventData_.setNewPot(_newPot);

         
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndMax_).add(rndGap_);

        keyPrice = initKeyPrice;
        keyBought = 0;

        startIndex = 0;
        endIndex = 0;

         
        round_[_rID].pot = _newPot;

        return _eventData_;
    }

     
    function updateTimer(uint256 _rID) private
    {
        round_[_rID].end = rndMax_.add(now);
    }

    function depositTeamPerfit(uint256 _eth) private {
        if(teamPerfit == address(0)) {
            teamPerfitAmuont = teamPerfitAmuont.add(_eth);
            return;
        }

        bool res = teamPerfit.deposit.value(_eth)();
        if(!res) {
            teamPerfitAmuont = teamPerfitAmuont.add(_eth);
            return;
        }
    }

     
    function distributeExternal(uint256 _eth) private returns(uint256)
    {
         
        uint256 _com = _eth / 50;

        depositTeamPerfit(_com);

        return _com;
    }

     
    function distributeInternal(uint256 _rID, uint256 _eth, uint256 _ethExt, DRSDatasets.EventReturns memory _eventData_)
        private
        returns(DRSDatasets.EventReturns)
    {
        uint256 _gen = 0;
        uint256 _pot = 0;

        if(keyBought < rewardInternal) {
            _gen = 0;
            _pot = _eth.sub(_ethExt);
        } else {
            _gen = _eth.mul(genRatio).div(100);
            _pot = _eth.sub(_ethExt).sub(_gen);

            DRSDatasets.BuyInfo memory info = buyinfos[startIndex];

            uint256 firstPID = info.pid;
            plyr_[firstPID].gen = _gen.add(plyr_[firstPID].gen);

            _eventData_.setGenInfo(info.addr, info.keyPrice);
        }

        if(_pot > 0) {
            round_[_rID].pot = _pot.add(round_[_rID].pot);
        }

        _eventData_.setGenAmount(_gen.add(_eventData_.genAmount));
        _eventData_.setPotAmount(_pot);

        return _eventData_;
    }

     
    function withdrawEarnings(uint256 _pID) private returns(uint256)
    {
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen);
        if(_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
        }

        return _earnings;
    }

     
    function endTx(uint256 _pID, uint256 _eth, uint256 _keyIndex, DRSDatasets.EventReturns memory _eventData_) private
    {
        _eventData_ = _eventData_.setTimestamp(now);
        _eventData_ = _eventData_.setPID(_pID);
        _eventData_ = _eventData_.setRID(rID_);

        emit DRSEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,

            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keyIndex,

            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,

            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount,

            _eventData_.genAddr,
            _eventData_.genKeyPrice
        );
    }

    modifier isActivated() {
        require(activated_, "its not activated yet.");
        _;
    }

    function activate() onlyOwner() public
    {
         
        require(!activated_, "ReserveBag already activated");

        uint256 _now = now;

         
        activated_ = true;

         
        rID_ = 1;
        round_[1].strt = _now.add(rndExtra_).sub(rndGap_);
        round_[1].end = _now.add(rndMax_).add(rndExtra_);
    }

    function getActivated() public view returns(bool) {
        return activated_;
    }

    function setTeamPerfitAddress(address _newTeamPerfitAddress) onlyOwner() public {
        teamPerfit = TeamPerfitForwarderInterface(_newTeamPerfitAddress);
    }

    function setPlayerBookAddress(address _newPlayerBookAddress) onlyOwner() public {
        playerBook = PlayerBookInterface(_newPlayerBookAddress);
    }

    function setDRSCoinAddress(address _newDRSCoinAddress) onlyOwner() public {
        drsCoin = DRSCoinInterface(_newDRSCoinAddress);
    }
}