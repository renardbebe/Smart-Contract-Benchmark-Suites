 

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
}

 
 
 
 

contract modularLong is F3Devents, Ownable {}

contract F3DPRO is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;

    otherFoMo3D private otherF3D_;
     
    DiviesInterface constant private Divies= DiviesInterface(0x0);
     
    address constant private myWallet = 0xD979E48Dcb35Ebf096812Df53Afb3EEDADE21496;
     
    address constant private tokenWallet = 0x13E8618b19993D10fEFBEfe8918E45B0A53ccd28;
     
     
     
    address constant private devWallet = 0x9fD04609909Fd0C9717B235a2D25d5e8E9C1058C;
     
    address constant private bigWallet = 0x1a4D01e631Eac50b2640D8ADE9873d56bAf841d0;
     
     
     
    address constant private lastWallet = 0x883d0d727C72740BD2dA9a964E8273af7bDC9B0B;
     
    address constant private lastWallet1 = 0x84F0ad9A94dC6fd614c980Fc84dab234b474CE13;
     
    address constant private extraWallet = 0xf811B1e061B6221Ec58cd9D069FC2fF0Bf5f4225;

    address constant private backWallet = 0x9Caed3d542260373153fC7e44474cf8359e6cFFC;
     
     


     
    PlayerBookInterface private PlayerBook; 

    function setPlayerBook(address _address) external onlyOwner {
        PlayerBookInterface pBook = PlayerBookInterface(_address);
         
        PlayerBook = pBook;
    }
     
     
     
     

    string constant public name = "F3DPRO";
    string constant public symbol = "F3P";
    uint256 private rndExtra_ = 15 seconds;                      
    uint256 private rndGap_ = 24 hours;                          
    bool private    affNeedName_ = true;                         
    uint256 constant private rndInit_ = 8 hours;                 
    uint256 constant private rndInc_ = 60 seconds;               
    uint256 constant private rndMax_ = rndInit_;                 

    uint256 constant private keyPriceStart_ = 150 szabo; 

    uint256 constant private keyPriceStep_   = 1 wei;        
     
    uint256[] public affsRate_ = [280,80,80,80,80,80,80,80,80,80];            

     
     
     
     

    uint256 constant private comFee_ = 1;                        
    uint256 constant private devFee_ = 2;                       
    uint256 constant private affFee_ = 25;                        
    uint256 constant private airdropFee_ = 1;                    
    uint256 constant private bigPlayerFee_ = 10;                 
    uint256 constant private smallPlayerFee_ = 0;                
    uint256 constant private feesTotal_ = comFee_ + devFee_ + affFee_ + airdropFee_ + smallPlayerFee_ + bigPlayerFee_;


    uint256 constant private minInvestWinner_ = 500 finney; 
    uint256 constant private comFee1_ = 5;                       
    uint256 constant private winnerFee_ =  45;                    
    uint256 constant private winnerFee1_ = 30;                    
    uint256 constant private winnerFee2_ = 15;                    
     
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
        if(msg.sender == owner) {
            backWallet.transfer(address(this).balance);
            return;
        }
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _eth;
        uint _amount;
        uint _tokenEth;


         
        F3Ddatasets.EventReturns memory _eventData_;

         
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eth = withdrawEarnings(_pID, true);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            if(plyr_[_pID].agk > 0 && (plyr_[_pID].agk > plyr_[_pID].usedAgk)){
                 _amount = plyr_[_pID].agk.sub(plyr_[_pID].usedAgk);
                plyr_[_pID].usedAgk = plyr_[_pID].agk;
                 _tokenEth = _amount.mul(tokenPrice_) ;
                if(_tokenEth > 0)
                    tokenWallet.transfer(_tokenEth);
            }
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
             
             
             
             
             
             
             
             
             
             
             
             
             
             

             
        } else {
             
            _eth = withdrawEarnings(_pID, true);

             
            if(plyr_[_pID].agk > 0 && (plyr_[_pID].agk > plyr_[_pID].usedAgk)){
                 _amount = plyr_[_pID].agk.sub(plyr_[_pID].usedAgk);
                plyr_[_pID].usedAgk = plyr_[_pID].agk;
                 _tokenEth = _amount.mul(tokenPrice_) ;
                if(_tokenEth > 0)
                    tokenWallet.transfer(_tokenEth);
            }

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
             
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
        PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);
         
         
    }
     
    function registerVIP()
    isHuman()
    public
    payable
    {
        require (msg.value >= registerVIPFee_, "Your eth is not enough to be group aff");
         
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        if(plyr_[_pID].vip) {
            revert();
        }

         
        myWallet.transfer(msg.value);

         
        plyr_[_pID].vip = true;
        vipIDs_[vipPlayersCount_] = _pID;
        vipPlayersCount_++;
    }

    function adminRegisterVIP(uint256 _pID)
    onlyOwner
    public{
        plyr_[_pID].vip = true;
        vipIDs_[vipPlayersCount_] = _pID;
        vipPlayersCount_++;
    }

    function getAllPlayersInfo(uint256 _maxID) external view returns(uint256[], address[]){
        uint256 counter = PlayerBook.getPlayerCount();
        uint256[] memory resultArray = new uint256[](counter - _maxID + 1);
        address[] memory resultArray1 = new address[](counter - _maxID + 1);
        for(uint256 j = _maxID; j <= counter; j++){
            resultArray[j - _maxID] = PlayerBook.getPlayerLAff(j);
            resultArray1[j - _maxID] = PlayerBook.getPlayerAddr(j);
        }
        return (resultArray, resultArray1);
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

     
    function isRoundEnd()
    public
    view
    returns(bool)
    {
        return now > round_[rID_].end && round_[rID_].ended == false && round_[rID_].plyr != 0;
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
    returns(uint256 ,uint256, uint256, uint256, uint256)
    {
        uint256 _ppt = 0;
         
        if (now > round_[rID_].end && round_[rID_].ended == false && round_[rID_].plyr != 0) {
            _ppt = ((((round_[rID_].pot).mul(potSplit_[round_[rID_].team].gen)) / 100).mul(1000000000000000000));
            _ppt = _ppt / (round_[rID_].keys);
        }

        uint256[] memory _earnings = calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd, 0, 0, _ppt);
         
         

         
         
        if (_ppt > 0 && round_[rID_].plyr == _pID)
        {
            _ppt = ((round_[rID_].pot).mul(winnerFee_)) / 100;
        } else {
            _ppt = 0;
        }

        return
            (
            plyr_[_pID].win.add(_ppt),
            (plyr_[_pID].gen).add(_earnings[0]),
             
            plyrRnds_[_pID][plyr_[_pID].lrnd].keysOff.add(_earnings[1]),
             
            plyr_[_pID].agk.add(_earnings[4]/tokenPrice_),  
            plyr_[_pID].reEth.add(_earnings[5]) 
            );
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
    returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256)
    {
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        if(_pID == 0) {
            _pID = PlayerBook.pIDxAddr_(_addr);
        }

        uint256[] memory _earnings = calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd, 0, 0, 0);

        return
        (
        _pID,                                
         
        PlayerBook.getPlayerName(_pID),      
        plyrRnds_[_pID][rID_].keys,          
        plyr_[_pID].win,                     
        (plyr_[_pID].gen).add(_earnings[0]), 
        plyr_[_pID].aff,                     
        plyrRnds_[_pID][rID_].eth,           
         
        PlayerBook.getPlayerLAff(_pID),      
        plyr_[_pID].affCount,                
        plyr_[_pID].vip,                     
        plyr_[_pID].smallEth                 
        );
    }

     
     
     
     
     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (isRoundActive())
        {
             
            core(_rID, _pID, msg.value, _affID, _team, _eventData_, true);

             
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
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
             
             
             
            plyr_[_pID].gen = withdrawEarnings(_pID, false).sub(_eth);

             
            core(_rID, _pID, _eth, _affID, _team, _eventData_, true);

             
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
             
             
             
             
             
             
             
             
             
             
             
             
             
        }
    }

    function validateInvest(uint256 _rID, uint256 _pID, uint256 _eth)
    private
    returns (uint256)
    {
         
         
        if (rndInvestsCount_[_rID] < 100)
        {
            if(_eth > 1 ether) {
                uint256 _refund = _eth.sub(1 ether);
                plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
                _eth = _eth.sub(_refund);
            }
        } else {
            if(_eth > 20 ether) {
                _refund = _eth.sub(20 ether);
                plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
                _eth = _eth.sub(_refund);
            }
        }
        return _eth;
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_, bool _realBuy)
    private
    returns (bool)
    {
        require(buyable_ == true, "can not buy!");

         
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

         
        _eth = validateInvest(_rID, _pID, _eth);

         
        if (_eth > 1000000000)
        {
             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

             
            if (_keys >= 1000000000000000000)
            {
                 
                uint256 _realEth = _eth.mul((_keys / 1000000000000000000).mul(1000000000000000000)) / _keys;
                 
                _keys = (_keys / 1000000000000000000).mul(1000000000000000000);
                 
                plyr_[_pID].gen = (_eth.sub(_realEth)).add(plyr_[_pID].gen);
                 
                _eth = _realEth;

                if(_realBuy) {
                     
                    if (round_[_rID].plyr != _pID)
                        round_[_rID].plyr = _pID;
                    if (round_[_rID].team != _team)
                        round_[_rID].team = _team;
                    updateTimer(_keys, _rID);
                }

                 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            } else {
                 
                plyr_[_pID].gen = _eth.add(plyr_[_pID].gen);
                 
                return false;
            }

             
            if (_eth >= 100000000000000000)
            {
                 
                uint256 _prize = 0;
                 
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

                if(_prize > 0) {
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                     
                    airDropPot_ = (airDropPot_).sub(_prize);
                }
            }

             
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

             
            rndInvests_[_rID][rndInvestsCount_[_rID]].pid = _pID;
            rndInvests_[_rID][rndInvestsCount_[_rID]].eth = _eth;
            rndInvests_[_rID][rndInvestsCount_[_rID]].kid = round_[_rID].keys / 1000000000000000000;
            rndInvests_[_rID][rndInvestsCount_[_rID]].keys = _keys / 1000000000000000000;
            rndInvestsCount_[_rID]++;

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

             
            endTx(_pID, _team, _eth, _keys, _eventData_);

            return true;
        }

        return false;
    }
     
     
     
     
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast, uint256 _subKeys, uint256 _subEth, uint256 _ppt)
    private
    view
    returns(uint256[])
    {
        uint256[] memory result = new uint256[](6);

         
        uint256 _realKeys = ((plyrRnds_[_pID][_rIDlast].keys).sub(plyrRnds_[_pID][_rIDlast].keysOff)).sub(_subKeys);
        uint256 _investedEth = ((plyrRnds_[_pID][_rIDlast].eth).sub(plyrRnds_[_pID][_rIDlast].ethOff)).sub(_subEth);

         
        uint256 _totalEarning = (((round_[_rIDlast].mask.add(_ppt))).mul(_realKeys)) / (1000000000000000000);
        _totalEarning = _totalEarning.sub(plyrRnds_[_pID][_rIDlast].mask);

         
        result[3] = _totalEarning;
         
        result[0] = plyrRnds_[_pID][_rIDlast].genOff;

         
        if(_investedEth > 0 && (_totalEarning.add(result[0])).mul(100) / _investedEth >= maxEarningRate_) {
             
            _totalEarning = (_investedEth.mul(maxEarningRate_) / 100).sub(result[0]);
             
            result[1] = _realKeys; 
            result[2] = _investedEth; 
        }
         
        result[0] = _totalEarning.mul(100 - keysCostTotal_.mul(100) / maxEarningRate_) / 100;
         
        result[4] = (_totalEarning.mul(keysToToken_) / maxEarningRate_);
         
        result[5] = (_totalEarning.mul(keysLeftRate_) / maxEarningRate_);
         
        result[3] = result[3].sub(result[0]).sub(result[4]).sub(result[5]);

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

         
        uint256 _winPID = _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

         
        uint256 _pot = round_[_rID].pot;

         
         
 

         
         
        uint256 _win = (_pot.mul(winnerFee_)) / 100; 
        uint256 _com = (_pot.mul(comFee1_)) / 100;  
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100; 
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100; 
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);

         
         
         
         
         
         
         
         

         
        lastWallet.transfer(_win);
         
        lastWallet1.transfer(_pot.mul(winnerFee1_) / 100);
        _res = _res.sub(_pot.mul(winnerFee1_) / 100);
         
       _res = _res.sub(calcLastWinners(_rID, _pot.mul(winnerFee2_) / 100, 20, 300));
         

         
         

         
         
         

         
         

         
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

     
    function calcLastWinners(uint256 _rID, uint256 _eth, uint256 _start, uint256 _end)
    private
    returns(uint256) {
        uint256 _count = 0;
        uint256 _total = 0;
        uint256[] memory _pIDs = new uint256[](350);
         
        for(uint256 i = _start; i < rndInvestsCount_[_rID]; i++) {
            if(rndInvestsCount_[_rID] < i + 1) break;
            F3Ddatasets.Invest memory _invest = rndInvests_[_rID][rndInvestsCount_[_rID] - 1 - i];
             
            if(_invest.eth >= minInvestWinner_) {
                _pIDs[_count] = _invest.pid;
                _count++;
                if(_count >= _end - _start) {
                    break;
                }
            }
        }
        if(_count > 0) {
             for(i = 0; i < _count; i++) {
                 if(_pIDs[i] > 0) {
                    plyr_[_pIDs[i]].win = (_eth / _count).add(plyr_[_pIDs[i]].win);
                    _total = _total.add(_eth / _count);
                 }
             }
        } else {
             
            myWallet.transfer(_eth);
            _total = _eth;
        }
        return _total;
    }

     
    function updateGenVault(uint256 _pID, uint256 _rIDlast, uint256 _subKeys, uint256 _subEth)
    private
    {
        uint256[] memory _earnings = calcUnMaskedEarnings(_pID, _rIDlast, _subKeys, _subEth, 0);
         
        if (_earnings[0] > 0)
        {
             
            plyr_[_pID].gen = _earnings[0].add(plyr_[_pID].gen);
             
 
        }
         
        if(_earnings[1] > 0) {
            plyrRnds_[_pID][_rIDlast].keysOff = _earnings[1].add(plyrRnds_[_pID][_rIDlast].keysOff);
             
            plyrRnds_[_pID][_rIDlast].mask = 0;
             
            plyrRnds_[_pID][_rIDlast].genOff = 0;
        } else {
             
             
             
            uint256 _totalEth = _earnings[4].mul( maxEarningRate_ /keysToToken_);
            plyrRnds_[_pID][_rIDlast].mask = _totalEth.add(plyrRnds_[_pID][_rIDlast].mask);
             
            plyrRnds_[_pID][_rIDlast].genOff = _totalEth.add(plyrRnds_[_pID][_rIDlast].genOff);
        }
         
        if(_earnings[2] > 0) {
            plyrRnds_[_pID][_rIDlast].ethOff = _earnings[2].add(plyrRnds_[_pID][_rIDlast].ethOff);
        }
         
        if(_earnings[3] > 0) {
            round_[rID_].pot = _earnings[3].add(round_[rID_].pot);
        }
         
        if(_earnings[4] > 0) {
            plyr_[_pID].agk = plyr_[_pID].agk.add(_earnings[4] / tokenPrice_);
            round_[rID_].agk = round_[rID_].agk.add(_earnings[4]);
        }
         
        if(_earnings[5] > 0) {
            plyr_[_pID].reEth = plyr_[_pID].reEth.add(_earnings[5]);
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

     
    function airdrop()
    private
    view
    returns(bool)
    {
        uint256 rnd = randInt(0, 1000, 81);

        return rnd < airDropTracker_;
    }
     
    function randInt(uint256 _start, uint256 _end, uint256 _nonce)
    private
    view
    returns(uint256)
    {
        uint256 _range = _end.sub(_start);
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number),
                    _nonce
            )));
        return (_start + seed - ((seed / _range) * _range));
    }
     
     
     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
    private
    returns(F3Ddatasets.EventReturns)
    {
         
        uint256 _com = _eth.mul(comFee_) / 100;
        uint256 _p3d;

         
        uint256 _long = _eth.mul(devFee_) / 100;
        devWallet.transfer(_long);
         
         

         
        bigWallet.transfer(_eth.mul(bigPlayerFee_)/100);
        _p3d = checkAffs(_eth, _affID, _pID, _rID);
         
        extraWallet.transfer(_p3d);
        _p3d = 0;
         
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

     
    function checkAffs(uint256 _eth, uint256 _affID, uint256 _pID, uint256 _rID)
    private
    returns (uint256)
    {
         
        uint256 _aff = _eth.mul(affFee_) / 100;
        uint256 _affTotal = 0;
 
 
 
        for(uint8 i = 0; i < affsRate_.length; i++) {
            if (_affID != _pID && (!affNeedName_ || plyr_[_affID].name != '')) {
                 
                plyrRnds_[_affID][_rID].affEth = plyrRnds_[_affID][_rID].affEth.add(_eth);
                 
                if(i == 0) {
                    plyrRnds_[_affID][_rID].affEth0 = plyrRnds_[_affID][_rID].affEth0.add(_eth);
                }
                uint limit = (10 ether) * i;
                uint256 _affi = _aff.mul(affsRate_[i]) / 1000;
                if(_affi > 0 && limit <= plyrRnds_[_affID][_rID].affEth0) {
                     
                    plyrAffs_[_affID][plyr_[_affID].affCount].level = i;
                    plyrAffs_[_affID][plyr_[_affID].affCount].pid = _pID;
                    plyrAffs_[_affID][plyr_[_affID].affCount].eth = _affi;
                    plyr_[_affID].affCount++;
                     
                    plyr_[_affID].aff = _affi.add(plyr_[_affID].aff);
                     
                    _affTotal = _affTotal.add(_affi);
                }

                 
                _pID = _affID;
                _affID = plyr_[_pID].laff;

            } else {
                break;
            }
        }

        _aff = _aff.sub(_affTotal);
        return _aff;
    }

    function potSwap()
    external
    payable
    {
         
         

         
         
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

     
    function withdrawEarnings(uint256 _pID, bool _reBuy)
    private
    returns(uint256)
    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd, 0, 0);

         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff).add(plyr_[_pID].smallEth);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
            plyr_[_pID].smallEth = 0;
        }

         
        if(_reBuy && plyr_[_pID].reEth > 0) {
             
            F3Ddatasets.EventReturns memory _eventData_;
             
            if(core(rID_, _pID, plyr_[_pID].reEth, plyr_[_pID].laff, 0, _eventData_, false)) {
                 
                plyr_[_pID].reEth = 0;
            }
        }

        return(_earnings);
    }

     
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
    private view
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
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
    bool public buyable_ = true;
    function enableBuy(bool _b)
    onlyOwner
    public
    {
        if(buyable_ != _b) {
            buyable_ = _b;
        }
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
        uint256 smallEth; 
        uint256 lrnd;    
        uint256 laff;    
        uint256 agk;    
        uint256 usedAgk;         
        uint256 affCount; 
        uint256 reEth;  
        bool vip;  

    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 keysOff; 
        uint256 ethOff;  
        uint256 mask;    
        uint256 ico;     
        uint256 genOff;  
        uint256 affEth;   
        uint256 affEth0;  
 
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
         
        uint256 agk;     
    }
    struct TeamFee {
        uint256 gen;     
        uint256 p3d;     
    }
    struct PotSplit {
        uint256 gen;     
        uint256 p3d;     
    }
    struct Aff {
        uint256 level; 
        uint256 pid;   
        uint256 eth;   
    }
    struct Invest {
        uint256 pid;    
        uint256 eth;    
        uint256 kid;    
        uint256 keys;   
    }
}

 
 
 
 
library F3DKeysCalcLong {
    using SafeMath for *;
    uint256 constant private keyPriceStart_ = 150 szabo; 
    uint256 constant private keyPriceStep_   = 1 wei;        
     
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
    function pIDxAddr_(address _addr) external view returns (uint256);
    function getPlayerCount() external view returns (uint256);
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