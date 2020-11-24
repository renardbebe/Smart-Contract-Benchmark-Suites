 

pragma solidity ^0.4.24;
 


 
contract Ownable {
    address public owner;


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 
 
 
 
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

 
 
 
 

contract modularLong is F3Devents, Ownable {}

contract FoMo3Dlong is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;

    otherFoMo3D private otherF3D_;
     
    DiviesInterface constant private Divies= DiviesInterface(0x0);
     
    address constant private myWallet = 0xAD81260195048D1CafDe04856994d60c14E2188d;
     
    address constant private myWallet1 = 0xa21fd0B4cabfE359B6F1E7F6b4336022028AB1C4;
     
     
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x214e86bc50b2b13cc949e75983c9b728790cf867);
     
    F3DexternalSettingsInterface constant private extSettings = F3DexternalSettingsInterface(0xf6fcbc80a7fc48dae64156225ee5b191fdad7624);
     
     
     
     
    string constant public name = "FoMo6D";
    string constant public symbol = "F6D";
    uint256 private rndExtra_ = extSettings.getLongExtra();      
    uint256 private rndGap_ = extSettings.getLongGap();          
    bool private    affNeedName_ = extSettings.getAffNeedName(); 
    uint256 constant private rndInit_ = 1 hours;                 
    uint256 constant private rndInc_ = 30 seconds;               
    uint256 constant private rndMax_ = 12 hours;                 

    uint256 constant private keyPriceStart_ = 15000000000000000; 
    uint256 constant private keyPriceStep_   = 10000000000000;        

    uint256 private realRndMax_ = rndMax_;                
    uint256 constant private keysToReduceMaxTime_ = 10000; 
    uint256 constant private reduceMaxTimeStep_ = 60 seconds; 
    uint256 constant private minMaxTime_ = 2 hours; 

    uint256 constant private comFee_ = 2;                        
    uint256 constant private otherF3DFee_ = 1;                   
    uint256 constant private affFee_ = 15;                       
    uint256 constant private airdropFee_ = 7;                    

    uint256 constant private feesTotal_ = comFee_ + otherF3DFee_ + affFee_ + airdropFee_;

    uint256 constant private winnerFee_ = 48;                    

    uint256 constant private bigAirdrop_ = 12;                     
    uint256 constant private midAirdrop_ = 8;                     
    uint256 constant private smallAirdrop_ = 4;                     

    uint256 constant private maxEarningRate_ = 600;                 
    uint256 constant private keysLeftRate_ = 100;                   

     
     
     
     
    uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      
    uint256 public rID_;     
     
     
     
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => F3Ddatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
    mapping (uint256 => uint256) public pIDxCards0_;          
    mapping (uint256 => uint256) public pIDxCards1_;          
    mapping (uint256 => uint256) public pIDxCards2_;          
     
     
     
    mapping (uint256 => F3Ddatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
     
     
     
    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;           
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;      
     
     
     
     
    constructor()
    public
    {
         
         
         
         
         
         
         
         
        fees_[0] = F3Ddatasets.TeamFee(60,0);    
        fees_[1] = F3Ddatasets.TeamFee(60,0);    
        fees_[2] = F3Ddatasets.TeamFee(60,0);   
        fees_[3] = F3Ddatasets.TeamFee(60,0);    

         
         
        potSplit_[0] = F3Ddatasets.PotSplit(40,0);   
        potSplit_[1] = F3Ddatasets.PotSplit(40,0);    
        potSplit_[2] = F3Ddatasets.PotSplit(40,0);   
        potSplit_[3] = F3Ddatasets.PotSplit(40,0);   
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

         
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
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

     
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
    isActivated()
    isHuman()
    isWithinLimits(_eth)
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

     

     
     
     
     
     
    function getBuyPrice()
    public
    view
    returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        if (isRoundActive())
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else  
            return ( keyPriceStart_ );  
    }

     
    function isRoundActive()
    public
    view
    returns(bool)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        return _now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0));
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
    returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];


        uint256[] memory _earnings = calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd, 0, 0, 0);

        return
        (
        _pID,                                
        plyr_[_pID].name,                    
        plyrRnds_[_pID][rID_].keys,          
        plyr_[_pID].win,                     
        (plyr_[_pID].gen).add(_earnings[0]), 
        plyr_[_pID].aff,                     
        plyrRnds_[_pID][rID_].eth,           
        pIDxCards0_[_pID],                   
        pIDxCards1_[_pID],                   
        pIDxCards2_[_pID],                   
        plyr_[_pID].laff                     
        );
    }

     
     
     
     
     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (isRoundActive())
        {
             
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

         
        if (isRoundActive())
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

         
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

         
        if (_eth > 1000000000)
        {
             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

             
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                 
                if (round_[_rID].plyr != _pID && plyr_[round_[_rID].plyr].addr != owner)
                    round_[_rID].plyr = _pID;
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

                 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

             
            if (_eth >= 100000000000000000)
            {
                 
                uint256 _prize = 0;
                 
                (_refund, _availableLimit) = drawCard(_pID);
                if(pIDxCards0_[_pID] < 2 || pIDxCards2_[_pID] >= 2) {
                    pIDxCards0_[_pID] = _refund;
                    pIDxCards1_[_pID] = 0;
                    pIDxCards2_[_pID] = 0;
                } else if(pIDxCards1_[_pID] >= 2) {
                    pIDxCards2_[_pID] = _refund;
                } else if(pIDxCards0_[_pID] >= 2) {
                    pIDxCards1_[_pID] = _refund;
                }
                if(_availableLimit > 0) {
                    _prize = _eth.mul(_availableLimit);
                     
                    if(_prize > airDropPot_) _prize = airDropPot_;
                } else {
                    airDropTracker_++;
                    if (airdrop() == true)
                    {
                        if (_eth >= 10000000000000000000)
                        {
                             
                            _prize = ((airDropPot_).mul(bigAirdrop_)) / 100;
                             
                            _eventData_.compressedData += 300000000000000000000000000000000;
                        } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                             
                            _prize = ((airDropPot_).mul(midAirdrop_)) / 100;
                             
                            _eventData_.compressedData += 200000000000000000000000000000000;
                        } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                             
                            _prize = ((airDropPot_).mul(smallAirdrop_)) / 100;
                             
                            _eventData_.compressedData += 300000000000000000000000000000000;
                        }
                         
                        _eventData_.compressedData += 10000000000000000000000000000000;
                         
                        _eventData_.compressedData += _prize * 1000000000000000000000000000000000;

                         
                        airDropTracker_ = 0;
                    }
                }

                if(_prize > 0) {
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                     
                    airDropPot_ = (airDropPot_).sub(_prize);
                }
            }

             
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

             
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }
     
     
     
     
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast, uint256 _subKeys, uint256 _subEth, uint256 _ppt)
    private
    view
    returns(uint256[])
    {
        uint256[] memory result = new uint256[](4);

         
        uint256 _realKeys = ((plyrRnds_[_pID][_rIDlast].keys).sub(plyrRnds_[_pID][_rIDlast].keysOff)).sub(_subKeys);
        uint256 _investedEth = ((plyrRnds_[_pID][_rIDlast].eth).sub(plyrRnds_[_pID][_rIDlast].ethOff)).sub(_subEth);

         
        uint256 _totalEarning = (((round_[_rIDlast].mask.add(_ppt))).mul(_realKeys)) / (1000000000000000000);
        _totalEarning = _totalEarning.sub(plyrRnds_[_pID][_rIDlast].mask);

         
        if(_investedEth > 0 && _totalEarning.mul(100) / _investedEth >= maxEarningRate_) {

            result[0] = (_investedEth.mul(maxEarningRate_) / 100);
            result[0] = result[0].mul(100 - keysLeftRate_.mul(100) / maxEarningRate_) / 100; 

            result[1] = _realKeys.mul(100 - keysLeftRate_.mul(100) / maxEarningRate_) / 100; 

            result[2] = _investedEth.mul(100 - keysLeftRate_.mul(100) / maxEarningRate_) / 100; 
        } else {
            result[0] = _totalEarning;
            result[1] = 0;
            result[2] = 0;
        }

         
        result[3] = _totalEarning.sub(result[0]);

        return( result );
    }

     
    function calcKeysReceived(uint256 _rID, uint256 _eth)
    public
    view
    returns(uint256)
    {
         
        if (isRoundActive())
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

         
        if (isRoundActive())
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
            updateGenVault(_pID, plyr_[_pID].lrnd, 0, 0);

         
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

         
         
        uint256 _win = (_pot.mul(winnerFee_)) / 100;
        uint256 _com = (_pot.mul(comFee_)) / 100;
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

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

         
         
         
         
         
         
         
         
         
         
         
         

         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
        if (_p3d > 0) {
            if(address(Divies) != address(0)) {
                Divies.deposit.value(_p3d)();
            } else {
                _com = _com.add(_p3d);
                _p3d = 0;
            }
        }

         
        myWallet.transfer(_com);

         
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

     
    function updateGenVault(uint256 _pID, uint256 _rIDlast, uint256 _subKeys, uint256 _subEth)
    private
    {
        uint256[] memory _earnings = calcUnMaskedEarnings(_pID, _rIDlast, _subKeys, _subEth, 0);
        if (_earnings[0] > 0)
        {
             
            plyr_[_pID].gen = _earnings[0].add(plyr_[_pID].gen);
             
            plyrRnds_[_pID][_rIDlast].mask = _earnings[0].add(plyrRnds_[_pID][_rIDlast].mask);
        }
        if(_earnings[1] > 0) {
            plyrRnds_[_pID][_rIDlast].keysOff = _earnings[1].add(plyrRnds_[_pID][_rIDlast].keysOff);
        }
        if(_earnings[2] > 0) {
            plyrRnds_[_pID][_rIDlast].ethOff = _earnings[2].add(plyrRnds_[_pID][_rIDlast].ethOff);
            plyrRnds_[_pID][_rIDlast].mask = _earnings[2].mul(keysLeftRate_) / (maxEarningRate_.sub(keysLeftRate_));
        }

        if(_earnings[3] > 0) {
             
            round_[rID_].pot = _earnings[3].add(round_[rID_].pot);
        }
    }

     
    function updateTimer(uint256 _keys, uint256 _rID)
    private
    {
         
        uint256 _now = now;

         
        uint256 _totalKeys = _keys.add(round_[_rID].keys);
        uint256 _times10k = _totalKeys / keysToReduceMaxTime_.mul(1000000000000000000);
        realRndMax_ = rndMax_.sub(_times10k.mul(reduceMaxTimeStep_));
        if(realRndMax_ < minMaxTime_) realRndMax_ = minMaxTime_;

         
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);

         
        if (_newTime < (realRndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = realRndMax_.add(_now);
    }

     
    function airdrop()
    private
    view
    returns(bool)
    {
        uint256 rnd = randInt(1000);

        return rnd < airDropTracker_;
    }

     
    function drawCard(uint256 _pID)
    private
    view
    returns (uint256 _cardNum, uint256 _rewardNum)
    {
        uint256 _card0 = pIDxCards0_[_pID];
        uint256 _card1 = pIDxCards1_[_pID];
        uint256 _card2 = pIDxCards2_[_pID];

        uint256 card = 2 + randInt(54);

        uint256 reward = 0;

         
        if(_card0 < 2 || _card2 >= 2) {

        } else {
            uint256[] memory cardInfo = parseCard(card);
            uint256[] memory cardInfo0 = parseCard(_card0);
            uint256[] memory cardInfo1 = parseCard(_card1);

             
            if(cardInfo[0] == 4 && (cardInfo0[0] == 4 || cardInfo1[0] == 4)) {
                card = 2 + randInt(52);
             
            } else if(cardInfo[1] == 14 && cardInfo0[1] == 14 && cardInfo1[1] == 14){
                card = 2 + randInt(12);
            }

            cardInfo = parseCard(card);

            if(_card1 >= 2) {
                 
                if((cardInfo[1] == cardInfo0[1]) && (cardInfo[1] == cardInfo1[1])) {
                    reward = 66;
                } else {
                    uint256[] memory numbers = new uint256[](3);
                    numbers[0] = cardInfo0[1];
                    numbers[1] = cardInfo1[1];
                    numbers[2] = cardInfo[1];
                    numbers = sortArray(numbers);
                    if(numbers[0] == numbers[1] + 1 && numbers[1] == numbers[2] + 1) {
                        reward = 6;
                    }
                }
            } else if(_card0 >= 2) {

            }
        }
        return (card, reward);
    }

    function sortArray(uint256[] arr_)
    private
    pure
    returns (uint256 [] )
    {
        uint256 l = arr_.length;
        uint256[] memory arr = new uint256[] (l);

        for(uint i=0;i<l;i++)
        {
            arr[i] = arr_[i];
        }

        for(i =0;i<l;i++)
        {
            for(uint j =i+1;j<l;j++)
            {
                if(arr[i]<arr[j])
                {
                    uint256 temp= arr[j];
                    arr[j]=arr[i];
                    arr[i] = temp;

                }

            }
        }

        return arr;
    }

    function parseCard(uint256 _card)
    private
    pure
    returns(uint256[]) {
        uint256[] memory r = new uint256[](2);
        if(_card < 2) {
            return r;
        }
         
         
        uint256 color = (_card - 2) / 13;
        uint256 number = _card - color * 13;
        r[0] = color;
        r[1] = number;
        return r;
    }
     
    function randInt(uint256 _range)
    private
    view
    returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(

                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)

            )));
        return (seed - ((seed / _range) * _range));
    }

     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns(F3Ddatasets.EventReturns)
    {
         
        uint256 _com = _eth.mul(comFee_) / 100;
        uint256 _p3d;
         
         
         
         
         
         
         
         
         
         
         

         
        uint256 _long = _eth.mul(otherF3DFee_) / 100;
        if(address(otherF3D_) != address(0)) {
            otherF3D_.potSwap.value(_long)();
        } else {
            _com = _com.add(_long);
        }

         
        uint256 _aff = _eth.mul(affFee_) / 100;

         
         
        if (_affID != _pID && (!affNeedName_ || plyr_[_affID].name != '')) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _p3d = _aff;
        }

         
        _p3d = _p3d.add((_eth.mul(fees_[_team].p3d)) / (100));
        if (_p3d > 0)
        {
            if(address(Divies) != address(0)) {
                 
                Divies.deposit.value(_p3d)();
            } else {
                _com = _com.add(_p3d);
                _p3d = 0;
            }
             
            _eventData_.P3DAmount = _p3d.add(_eventData_.P3DAmount);
        }

         
        myWallet.transfer(_com);

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

         
        uint256 _air = (_eth.mul(airdropFee_) / 100);
        airDropPot_ = airDropPot_.add(_air);

         
        uint256 _pot = _eth.sub(((_eth.mul(feesTotal_)) / 100).add((_eth.mul(fees_[_team].p3d)) / 100));

         
        _pot = _pot.sub(_gen);

         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys, _eth);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }
     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys, uint256 _eth)
    private
    returns(uint256)
    {
        uint256 _oldKeyValue = round_[_rID].mask;
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(_oldKeyValue);

         
        updateGenVault(_pID, plyr_[_pID].lrnd, _keys, _eth);

         
         
 
 
 

        plyrRnds_[_pID][_rID].mask = (_oldKeyValue.mul(_keys) / (1000000000000000000)).add(plyrRnds_[_pID][_rID].mask);

         
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

     
    function withdrawEarnings(uint256 _pID)
    private
    returns(uint256)
    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd, 0, 0);

         
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
    onlyOwner
    public
    {
         
         

         
        require(activated_ == false, "fomo3d already activated");

         
        activated_ = true;

         
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
    function setOtherFomo(address _otherF3D)
    onlyOwner
    public
    {
         
        require(address(otherF3D_) == address(0), "silly dev, you already did that");

         
        otherF3D_ = otherFoMo3D(_otherF3D);
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
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 keysOff; 
        uint256 ethOff;  
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
        uint256 p3d;     
    }
    struct PotSplit {
        uint256 gen;     
        uint256 p3d;     
    }
}

 
 
 
 
library F3DKeysCalcLong {
    using SafeMath for *;
    uint256 constant private keyPriceStart_ = 15000000000000000;
    uint256 constant private keyPriceStep_ = 10000000000000;
     
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
        return ((((keyPriceStart_).sq()).add((keyPriceStep_).mul(2).mul(_eth))).sqrt().sub(keyPriceStart_)).mul(1000000000000000000) / (keyPriceStep_);
    }

     
    function eth(uint256 _keys)
    public
    pure
    returns(uint256)
    {
        uint256 n = _keys / (1000000000000000000);
         
         
         
        return n.mul(keyPriceStart_).add((n.sq().mul(keyPriceStep_)) / (2));
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
    function getAffNeedName() external returns(bool);
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