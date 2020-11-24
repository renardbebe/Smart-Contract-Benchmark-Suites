 

pragma solidity ^0.4.24;

 

contract PlayerBook {
    using NameFilter for string;
    using SafeMath for *;
    address private admin = msg.sender;
     
    uint256 public registrationFee_ = 10 finney;
    uint256 pIdx_=1;
    uint256 public pID_;         
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => LSDatasets.Player) public plyr_;    
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
     
    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    function getPlayerID(address _addr)
    public
        returns (uint256)
    {
        determinePID(_addr);
        return (pIDxAddr_[_addr]);
    }
    function getPlayerName(uint256 _pID)
    public
        view
        returns (bytes32)
    {
        return (plyr_[_pID].name);
    }
    function getPlayerLAff(uint256 _pID)
    public
        view
        returns (uint256)
    {
        return (plyr_[_pID].laff);
    }
    function getPlayerAddr(uint256 _pID)
    public
        view
        returns (address)
    {
        return (plyr_[_pID].addr);
    }
    function getNameFee()
    public
        view
        returns (uint256)
    {
        return(registrationFee_);
    }
    function determinePID(address _addr)
        private
        returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

             
            return (true);
        } else {
            return (false);
        }
    }
    function register(address _addr,uint256 _affID,bool _isSuper)  onlyOwner() public{
        bool _isNewPlayer = determinePID(_addr);
        bytes32 _name="LuckyStar";
        uint256 _pID = pIDxAddr_[_addr];
        plyr_[_pID].laff = _affID;
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;


         
        bool _isNewPlayer = determinePID(_addr);

         
        uint256 _pID = pIDxAddr_[_addr];

         
         
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
             
            _affID = pIDxName_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }

    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer)
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

         
         
        uint256 _paid=msg.value;
         
        admin.transfer(_paid);

    }
    function setSuper(address _addr,bool isSuper) 
     onlyOwner()
     public{
        uint256 _pID=pIDxAddr_[_addr];
        if(_pID!=0){
            plyr_[_pID].super=isSuper;
        }else{
            revert();
        }
    }
    
    function setRegistrationFee(uint256 _fee)
      onlyOwner()
        public{
         registrationFee_ = _fee;
    }
}

contract LuckyStar is PlayerBook {
    using SafeMath for *;
    using NameFilter for string;
    using LSKeysCalcShort for uint256;

    

 
 
 
 
    address private admin = msg.sender;

    string constant public name = "LuckyStar";
    string constant public symbol = "LuckyStar";
    uint256 constant gen_=55;
    uint256 constant bigPrize_ =30;
    uint256 public minBuyForPrize_=100 finney;
    uint256 constant private rndInit_ = 3 hours;             
    uint256 constant private rndInc_ = 1 minutes;               
    uint256 constant private rndMax_ = 6 hours;              
    uint256 constant private prizeTimeInc_= 1 days;
    uint256 constant private stopTime_=1 hours;
 
 
 
 
    uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      
    uint256 public rID_;     
 
 
 
    mapping (uint256 => uint256) public plyrOrders_;  
    mapping (uint256 => uint256) public plyrForPrizeOrders_;  
    mapping (uint256 => mapping (uint256 => LSDatasets.PlayerRounds)) public plyrRnds_;     

 
 
 
    mapping (uint256 => LSDatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
 

 
 
 
 
    constructor()
        public
    {
		pIDxAddr_[address(0xc7FcAD2Ad400299a7690d5aa6d7295F9dDB7Fc33)] = 1;
        plyr_[1].addr = address(0xc7FcAD2Ad400299a7690d5aa6d7295F9dDB7Fc33);
        plyr_[1].name = "sumpunk";
        plyr_[1].super=true;
        pIDxName_["sumpunk"] = 1;
        plyrNames_[1]["sumpunk"] = true;
        
        pIDxAddr_[address(0x2f52362c266c1Df356A2313F79E4bE4E7de281cc)] = 2;
        plyr_[2].addr = address(0x2f52362c266c1Df356A2313F79E4bE4E7de281cc);
        plyr_[2].name = "xiaokan";
        plyr_[2].super=true;
        pIDxName_["xiaokan"] = 2;
        plyrNames_[2]["xiaokan"] = true;
        
        pIDxAddr_[address(0xA97F850B019871B7a356956f8b43255988d1578a)] = 3;
        plyr_[3].addr = address(0xA97F850B019871B7a356956f8b43255988d1578a);
        plyr_[3].name = "Mr Shen";
        plyr_[3].super=true;
        pIDxName_["Mr Shen"] = 3;
        plyrNames_[3]["Mr Shen"] = true;
        
        pIDxAddr_[address(0x84408183fC70A65d378f720f4E95e4f9bD9EbeBE)] = 4;
        plyr_[4].addr = address(0x84408183fC70A65d378f720f4E95e4f9bD9EbeBE);
        plyr_[4].name = "4";
        plyr_[4].super=false;
        pIDxName_["4"] = 4;
        plyrNames_[4]["4"] = true;
        
        pIDxAddr_[address(0xa21E15d5933502DAD475daB3ed235fffFa537f85)] = 5;
        plyr_[5].addr = address(0xa21E15d5933502DAD475daB3ed235fffFa537f85);
        plyr_[5].name = "5";
        plyr_[5].super=true;
        pIDxName_["5"] = 5;
        plyrNames_[5]["5"] = true;
        
        pIDxAddr_[address(0xEb892446E9096a7e6e28B89EE416564E50504A68)] = 6;
        plyr_[6].addr = address(0xEb892446E9096a7e6e28B89EE416564E50504A68);
        plyr_[6].name = "6";
        plyr_[6].super=true;
        pIDxName_["6"] = 6;
        plyrNames_[6]["6"] = true;
        
        pIDxAddr_[address(0x75DF1440094346d4156cf4563a85dC5C564D2100)] = 7;
        plyr_[7].addr = address(0x75DF1440094346d4156cf4563a85dC5C564D2100);
        plyr_[7].name = "7";
        plyr_[7].super=true;
        pIDxName_["7"] = 7;
        plyrNames_[7]["7"] = true;
        
        pIDxAddr_[address(0xb00B860546F13268DC9Fa922B63342BC9C5a28a6)] = 8;
        plyr_[8].addr = address(0xb00B860546F13268DC9Fa922B63342BC9C5a28a6);
        plyr_[8].name = "8";
        plyr_[8].super=false;
        pIDxName_["8"] = 8;
        plyrNames_[8]["8"] = true;
        
        pIDxAddr_[address(0x9DC1bB8FDD15C9781d7D590B59E5DAFC0e37Cf3e)] = 9;
        plyr_[9].addr = address(0x9DC1bB8FDD15C9781d7D590B59E5DAFC0e37Cf3e);
        plyr_[9].name = "9";
        plyr_[9].super=false;
        pIDxName_["9"] = 9;
        plyrNames_[9]["9"] = true;
        
        pIDxAddr_[address(0x142Ba743cf9317eB54ba10c157870Af3cBb66bD3)] = 10;
        plyr_[10].addr = address(0x142Ba743cf9317eB54ba10c157870Af3cBb66bD3);
        plyr_[10].name = "10";
        plyr_[10].super=false;
        pIDxName_["10"] =10;
        plyrNames_[10]["10"] = true;
        
        pIDxAddr_[address(0x8B8F389Eb845eB0735D6eA084A3215d86Ed70344)] = 11;
        plyr_[11].addr = address(0x8B8F389Eb845eB0735D6eA084A3215d86Ed70344);
        plyr_[11].name = "11";
        plyr_[11].super=false;
        pIDxName_["11"] =11;
        plyrNames_[11]["11"] = true;
        
        pIDxAddr_[address(0x73974391d9B8Eae6F883503EffBc21E7dbAcf62c)] = 12;
        plyr_[12].addr = address(0x73974391d9B8Eae6F883503EffBc21E7dbAcf62c);
        plyr_[12].name = "12";
        plyr_[12].super=false;
        pIDxName_["12"] =12;
        plyrNames_[12]["12"] = true;
        
        pIDxAddr_[address(0xf1b9167F73847874AdD274FDFf4E1546CC184d03)] = 13;
        plyr_[13].addr = address(0xf1b9167F73847874AdD274FDFf4E1546CC184d03);
        plyr_[13].name = "13";
        plyr_[13].super=false;
        pIDxName_["13"] =13;
        plyrNames_[13]["13"] = true;
        
        pIDxAddr_[address(0x56948841d665A2903218018728979C0a8a47648A)] = 14;
        plyr_[14].addr = address(0x56948841d665A2903218018728979C0a8a47648A);
        plyr_[14].name = "14";
        plyr_[14].super=false;
        pIDxName_["14"] =14;
        plyrNames_[14]["14"] = true;
        
        pIDxAddr_[address(0x94bC531328e2b39C53B7D2EBb8461E794d7999A1)] = 15;
        plyr_[15].addr = address(0x94bC531328e2b39C53B7D2EBb8461E794d7999A1);
        plyr_[15].name = "15";
        plyr_[15].super=true;
        pIDxName_["15"] =15;
        plyrNames_[15]["15"] = true;
        
        pID_ = 15;
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
         
        LSDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        LSDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;

         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

         
         

         
        buyCore(_pID, _affCode, _team, _eventData_);
    }

    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        LSDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
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
         
        buyCore(_pID, _affID, _team, _eventData_);
    }

     
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        LSDatasets.EventReturns memory _eventData_;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;

         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

         
         

         
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        LSDatasets.EventReturns memory _eventData_;

         
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
             
            LSDatasets.EventReturns memory _eventData_;

             
			round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

			 
            _eth = withdrawEarnings(_pID,true);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

           
         
        } else {
             
            _eth = withdrawEarnings(_pID,true);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

        }
    }


 
 
 
 
     
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
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
            if (_now > round_[_rID].strt )
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt ).sub(_now) );
        else
            return(0);
    }
    
    function getDailyTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        if (_now < round_[_rID].prizeTime)
            return( (round_[_rID].prizeTime).sub(_now) );
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
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(30)) / 100 ),
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
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(gen_)) / 100).mul(1e18)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1e18)  );
    }

     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

        return
        (
             
            0,                               
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
 
 
 
 
     
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, LSDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt && _now<round_[_rID].prizeTime  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
            if(_now>(round_[_rID].prizeTime-prizeTimeInc_)&& _now<(round_[_rID].prizeTime-prizeTimeInc_+stopTime_)){
                plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
            }else{
                  core(_rID, _pID, msg.value, _affID, _team, _eventData_);
            }
         
        } else {
             
            if ((_now > round_[_rID].end||_now>round_[_rID].prizeTime) && round_[_rID].ended == false)
            {
                 
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, LSDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt && _now<round_[_rID].prizeTime  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
             
             
            if(_now>(round_[_rID].prizeTime-prizeTimeInc_)&& _now<(round_[_rID].prizeTime-prizeTimeInc_+stopTime_)){
                revert();
            }
            plyr_[_pID].gen = withdrawEarnings(_pID,false).sub(_eth);

             
            core(_rID, _pID, _eth, _affID, _team, _eventData_);

         
        } else if ((_now > round_[_rID].end||_now>round_[_rID].prizeTime) && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

        }
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, LSDatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

         
        if (round_[_rID].eth < 1e20 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1e18)
        {
            uint256 _availableLimit = (1e18).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

         
        if (_eth > 1e9)
        {

             
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);

             
            if (_keys >= 1e18)
            {
            updateTimer(_keys, _rID);

             
            if (round_[_rID].plyr != _pID)
                round_[_rID].plyr = _pID;
            if (round_[_rID].team != _team)
                round_[_rID].team = _team;

             
            _eventData_.compressedData = _eventData_.compressedData + 100;
        }

             
            if (_eth >= 1e17)
            {
            airDropTracker_++;
            if (airdrop() == true)
            {
                 
                uint256 _prize;
                if (_eth >= 1e19)
                {
                     
                    _prize = ((airDropPot_).mul(75)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                     
                    airDropPot_ = (airDropPot_).sub(_prize);

                     
                    _eventData_.compressedData += 300000000000000000000000000000000;
                } else if (_eth >= 1e18 && _eth < 1e19) {
                     
                    _prize = ((airDropPot_).mul(50)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                     
                    airDropPot_ = (airDropPot_).sub(_prize);

                     
                    _eventData_.compressedData += 200000000000000000000000000000000;
                } else if (_eth >= 1e17 && _eth < 1e18) {
                     
                    _prize = ((airDropPot_).mul(25)) / 100;
                    plyr_[_pID].win = (plyr_[_pID].win).add(_prize);

                     
                    airDropPot_ = (airDropPot_).sub(_prize);

                     
                    _eventData_.compressedData += 300000000000000000000000000000000;
                }
                 
                _eventData_.compressedData += 10000000000000000000000000000000;
                 
                _eventData_.compressedData += _prize * 1000000000000000000000000000000000;

                 
                airDropTracker_ = 0;
            }
        }

             
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].plyrCtr++;
            plyrOrders_[round_[_rID].plyrCtr] = _pID;  
            if(_eth>minBuyForPrize_){
                 round_[_rID].plyrForPrizeCtr++;
                 plyrForPrizeOrders_[round_[_rID].plyrForPrizeCtr]=_pID;
            }
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);

             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);

            checkDoubledProfit(_pID, _rID);
            checkDoubledProfit(_affID, _rID);
             
		     
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

         
        if (_now > round_[_rID].strt && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
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

         
        if (_now > round_[_rID].strt  && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else  
            return ( (_keys).eth() );
    }

     
    function determinePID(LSDatasets.EventReturns memory _eventData_)
        private
        returns (LSDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)
        {
             
            _pID = getPlayerID(msg.sender);
            bytes32 _name = getPlayerName(_pID);
            uint256 _laff = getPlayerLAff(_pID);

             
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

    
     
    function managePlayer(uint256 _pID, LSDatasets.EventReturns memory _eventData_)
        private
        returns (LSDatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }

     
    function endRound(LSDatasets.EventReturns memory _eventData_)
        private
        returns (LSDatasets.EventReturns)
    {
         
        uint256 _rID = rID_;
         uint _prizeTime=round_[rID_].prizeTime;
         
        uint256 _winPID = round_[_rID].plyr;
         

         
        uint256 _pot = round_[_rID].pot;

         
         
         
        uint256 _com = (_pot / 20);
        uint256 _res = _pot.sub(_com);
       

        uint256 _winLeftP;
         if(now>_prizeTime){
             _winLeftP=pay10WinnersDaily(_pot);
         }else{
             _winLeftP=pay10Winners(_pot);
         }
         _res=_res.sub(_pot.mul((74).sub(_winLeftP)).div(100));
         admin.transfer(_com);

         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
         
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.newPot = _res;

         
       
        if(now>_prizeTime){
            _prizeTime=nextPrizeTime();
        }
        rID_++;
        _rID++;
        round_[_rID].prizeTime=_prizeTime;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_);
        round_[_rID].pot = _res;

        return(_eventData_);
    }
    function pay10Winners(uint256 _pot) private returns(uint256){
        uint256 _left=74;
        uint256 _rID = rID_;
        uint256 _plyrCtr=round_[_rID].plyrCtr;
        if(_plyrCtr>=1){
            uint256 _win1= _pot.mul(bigPrize_).div(100); 
            plyr_[plyrOrders_[_plyrCtr]].win=_win1.add( plyr_[plyrOrders_[_plyrCtr]].win);
            _left=_left.sub(bigPrize_);
        }else{
            return(_left);
        }
        if(_plyrCtr>=2){
            uint256 _win2=_pot.div(5); 
            plyr_[plyrOrders_[_plyrCtr-1]].win=_win2.add( plyr_[plyrOrders_[_plyrCtr]-1].win);
            _left=_left.sub(20);
        }else{
            return(_left);
        }
        if(_plyrCtr>=3){
            uint256 _win3=_pot.div(10); 
            plyr_[plyrOrders_[_plyrCtr-2]].win=_win3.add( plyr_[plyrOrders_[_plyrCtr]-2].win);
            _left=_left.sub(10);
        }else{
            return(_left);
        }
        uint256 _win4=_pot.div(50); 
        for(uint256 i=_plyrCtr-3;(i>_plyrCtr-10)&&(i>0);i--){
             if(i==0)
                 return(_left);
             plyr_[plyrOrders_[i]].win=_win4.add(plyr_[plyrOrders_[i]].win);
             _left=_left.sub(2);
        }
        return(_left);
    }
    function pay10WinnersDaily(uint256 _pot) private returns(uint256){
        uint256 _left=74;
        uint256 _rID = rID_;
        uint256 _plyrForPrizeCtr=round_[_rID].plyrForPrizeCtr;
        if(_plyrForPrizeCtr>=1){
            uint256 _win1= _pot.mul(bigPrize_).div(100); 
            plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr]].win=_win1.add( plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr]].win);
            _left=_left.sub(bigPrize_);
        }else{
            return(_left);
        }
        if(_plyrForPrizeCtr>=2){
            uint256 _win2=_pot.div(5); 
            plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr-1]].win=_win2.add( plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr]-1].win);
            _left=_left.sub(20);
        }else{
            return(_left);
        }
        if(_plyrForPrizeCtr>=3){
            uint256 _win3=_pot.div(10); 
            plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr-2]].win=_win3.add( plyr_[plyrForPrizeOrders_[_plyrForPrizeCtr]-2].win);
            _left=_left.sub(10);
        }else{
            return(_left);
        }
        uint256 _win4=_pot.div(50); 
        for(uint256 i=_plyrForPrizeCtr-3;(i>_plyrForPrizeCtr-10)&&(i>0);i--){
             if(i==0)
                 return(_left);
             plyr_[plyrForPrizeOrders_[i]].win=_win4.add(plyr_[plyrForPrizeOrders_[i]].win);
             _left=_left.sub(2);
        }
        return(_left);
    }
    function nextPrizeTime() private returns(uint256){
        while(true){
            uint256 _prizeTime=round_[rID_].prizeTime;
            _prizeTime =_prizeTime.add(prizeTimeInc_);
            if(_prizeTime>now)
                return(_prizeTime);
        }
        return(round_[rID_].prizeTime.add( prizeTimeInc_));
    }

     
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
            plyrRnds_[_pID][_rIDlast].keyProfit = _earnings.add(plyrRnds_[_pID][_rIDlast].keyProfit); 
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
        uint256 seed = uint256(keccak256(abi.encodePacked(

            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)

        )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }

     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, LSDatasets.EventReturns memory _eventData_)
        private
        returns(LSDatasets.EventReturns)
    {
         
        uint256 _com = _eth / 20;

        uint256 _invest_return = 0;
        bool _isSuper=plyr_[_affID].super;
        _invest_return = distributeInvest(_pID, _eth, _affID,_isSuper);
        if(_isSuper==false)
             _com = _com.mul(2);
        _com = _com.add(_invest_return);


        plyr_[pIdx_].aff=_com.add(plyr_[pIdx_].aff);
        return(_eventData_);
    }

     
    function distributeInvest(uint256 _pID, uint256 _aff_eth, uint256 _affID,bool _isSuper)
        private
        returns(uint256)
    {

        uint256 _left=0;
        uint256 _aff;
        uint256 _aff_2;
        uint256 _aff_3;
        uint256 _affID_1;
        uint256 _affID_2;
        uint256 _affID_3;
         
        if(_isSuper==true)
            _aff = _aff_eth.mul(12).div(100);
        else
            _aff = _aff_eth.div(10);
        _aff_2 = _aff_eth.mul(3).div(100);
        _aff_3 = _aff_eth.div(100);

        _affID_1 = _affID; 
        _affID_2 = plyr_[_affID_1].laff; 
        _affID_3 = plyr_[_affID_2].laff; 

         
         
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID_1].aff = _aff.add(plyr_[_affID_1].aff);
            if(_isSuper==true){
                uint256 _affToPID=_aff_eth.mul(3).div(100);
                plyr_[_pID].aff = _affToPID.add(plyr_[_pID].aff);
            }
              
             
        } else {
            _left = _left.add(_aff);
        }

        if (_affID_2 != _pID && _affID_2 != _affID && plyr_[_affID_2].name != '') {
            plyr_[_affID_2].aff = _aff_2.add(plyr_[_affID_2].aff);
        } else {
            _left = _left.add(_aff_2);
        }

        if (_affID_3 != _pID &&  _affID_3 != _affID && plyr_[_affID_3].name != '') {
            plyr_[_affID_3].aff = _aff_3.add(plyr_[_affID_3].aff);
        } else {
            _left= _left.add(_aff_3);
        }
        return _left;
    }

    function potSwap()
        external
        payable
    {
         
        uint256 _rID = rID_ + 1;

        round_[_rID].pot = round_[_rID].pot.add(msg.value);
         
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, LSDatasets.EventReturns memory _eventData_)
        private
        returns(LSDatasets.EventReturns)
    {
         
        uint256 _gen = (_eth.mul(gen_)) / 100;

         
        uint256 _air = (_eth / 50);
        uint256 _com= (_eth / 20);
        uint256 _aff=(_eth.mul(19))/100;
        airDropPot_ = airDropPot_.add(_air);

         
         
        uint256 _pot= _eth.sub(_gen).sub(_air);
        _pot=_pot.sub(_com).sub(_aff);
         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);

         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;

        return(_eventData_);
    }

   function checkDoubledProfit(uint256 _pID, uint256 _rID)
        private
    {   
         
        uint256 _keys = plyrRnds_[_pID][_rID].keys;
        if (_keys > 0) {

            uint256 _genVault = plyr_[_pID].gen;
            uint256 _genWithdraw = plyrRnds_[_pID][_rID].genWithdraw;
            uint256 _genEarning = calcUnMaskedKeyEarnings(_pID, plyr_[_pID].lrnd);
            uint256 _doubleProfit = (plyrRnds_[_pID][_rID].eth).mul(2);
            if (_genVault.add(_genWithdraw).add(_genEarning) >= _doubleProfit)
            {
                 
                uint256 _remainProfit = _doubleProfit.sub(_genVault).sub(_genWithdraw);
                plyr_[_pID].gen = _remainProfit.add(plyr_[_pID].gen); 
                plyrRnds_[_pID][_rID].keyProfit = _remainProfit.add(plyrRnds_[_pID][_rID].keyProfit);  

                round_[_rID].keys = round_[_rID].keys.sub(_keys);
                plyrRnds_[_pID][_rID].keys = plyrRnds_[_pID][_rID].keys.sub(_keys);

                plyrRnds_[_pID][_rID].mask = 0;  
            }   
        }
    }
    function calcUnMaskedKeyEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        if (    (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1e18))  >    (plyrRnds_[_pID][_rIDlast].mask)       )
            return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1e18)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
        else
            return 0;
    }

     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         

         
        uint256 _ppt = (_gen.mul(1e18)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1e18);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1e18)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

         
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1e18)));
    }

     
    function withdrawEarnings(uint256 _pID,bool isWithdraw)
        private
        returns(uint256)
    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd);
        if (isWithdraw)
            plyrRnds_[_pID][plyr_[_pID].lrnd].genWithdraw = plyr_[_pID].gen.add(plyrRnds_[_pID][plyr_[_pID].lrnd].genWithdraw);
         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

 
 
 
 
     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(msg.sender == admin, "only admin can activate");  


         
        require(activated_ == false, "LuckyStar already activated");

         
        activated_ = true;

         
        rID_ = 1;
        round_[1].strt = now ;
        round_[1].end = now + rndInit_ ;
        round_[1].prizeTime=1536062400;
    }
    
     function setMinBuyForPrize(uint256 _min)
      onlyOwner()
        public{
         minBuyForPrize_ = _min;
    }
}

 
 
 
 
library LSDatasets {

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
        bool super;
         
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
        uint256 keyProfit;
         
        uint256 genWithdraw;
    }
    struct Round {
        uint256 plyr;    
        uint256 plyrCtr;    
        uint256 plyrForPrizeCtr; 
        uint256 prizeTime;
        uint256 team;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
    }

}

 
 
 
 
library LSKeysCalcShort {
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

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
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