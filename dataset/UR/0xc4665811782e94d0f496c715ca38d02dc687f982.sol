 

pragma solidity ^0.4.24;

 

 
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

 

 

library MSFun {
     
     
     
     
    struct Data 
    {
        mapping (bytes32 => ProposalData) proposal_;
    }
    struct ProposalData 
    {
         
        bytes32 msgData;
         
        uint256 count;
         
        mapping (address => bool) admin;
         
        mapping (uint256 => address) log;
    }
    
     
     
     
    function multiSig(Data storage self, uint256 _requiredSignatures, bytes32 _whatFunction)
        internal
        returns(bool) 
    {
         
         
         
        bytes32 _whatProposal = whatProposal(_whatFunction);
        
         
        uint256 _currentCount = self.proposal_[_whatProposal].count;
        
         
         
         
         
         
        address _whichAdmin = msg.sender;
        
         
         
         
        bytes32 _msgData = keccak256(msg.data);
        
         
        if (_currentCount == 0)
        {
             
            self.proposal_[_whatProposal].msgData = _msgData;
            
             
            self.proposal_[_whatProposal].admin[_whichAdmin] = true;        
            
             
             
             
            self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;  
            
             
            self.proposal_[_whatProposal].count += 1;  
            
             
             
             
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }            
         
        } else if (self.proposal_[_whatProposal].msgData == _msgData) {
             
             
            if (self.proposal_[_whatProposal].admin[_whichAdmin] == false) 
            {
                 
                self.proposal_[_whatProposal].admin[_whichAdmin] = true;        
                
                 
                self.proposal_[_whatProposal].log[_currentCount] = _whichAdmin;  
                
                 
                self.proposal_[_whatProposal].count += 1;  
            }
            
             
             
             
             
             
             
             
             
             
            if (self.proposal_[_whatProposal].count == _requiredSignatures) {
                return(true);
            }
        }
    }
    
    
     
    function deleteProposal(Data storage self, bytes32 _whatFunction)
        internal
    {
         
        bytes32 _whatProposal = whatProposal(_whatFunction);
        address _whichAdmin;
        
         
         
        for (uint256 i=0; i < self.proposal_[_whatProposal].count; i++) {
            _whichAdmin = self.proposal_[_whatProposal].log[i];
            delete self.proposal_[_whatProposal].admin[_whichAdmin];
            delete self.proposal_[_whatProposal].log[i];
        }
         
        delete self.proposal_[_whatProposal];
    }
    
     
     
     

    function whatProposal(bytes32 _whatFunction)
        private
        view
        returns(bytes32)
    {
        return(keccak256(abi.encodePacked(_whatFunction,this)));
    }
    
     
     
     
     
    function checkMsgData (Data storage self, bytes32 _whatFunction)
        internal
        view
        returns (bytes32 msg_data)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].msgData);
    }
    
     
    function checkCount (Data storage self, bytes32 _whatFunction)
        internal
        view
        returns (uint256 signature_count)
    {
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].count);
    }
    
     
    function checkSigner (Data storage self, bytes32 _whatFunction, uint256 _signer)
        internal
        view
        returns (address signer)
    {
        require(_signer > 0, "MSFun checkSigner failed - 0 not allowed");
        bytes32 _whatProposal = whatProposal(_whatFunction);
        return (self.proposal_[_whatProposal].log[_signer - 1]);
    }
}

 

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff, uint8 _level) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
}

 

 






contract PlayerBook {
    using NameFilter for string;
    using SafeMath for uint256;

    address private Community_Wallet1 = 0x00839c9d56F48E17d410E94309C91B9639D48242;
    address private Community_Wallet2 = 0x53bB6E7654155b8bdb5C4c6e41C9f47Cd8Ed1814;
    
    MSFun.Data private msData;
    function deleteProposal(bytes32 _whatFunction) private {MSFun.deleteProposal(msData, _whatFunction);}
    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
    function checkData(bytes32 _whatFunction) onlyDevs() public view returns(bytes32, uint256) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
    function checkSignersByAddress(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyDevs() public view returns(address, address, address) {return(MSFun.checkSigner(msData, _whatFunction, _signerA), MSFun.checkSigner(msData, _whatFunction, _signerB), MSFun.checkSigner(msData, _whatFunction, _signerC));}
 
 
 
 
    uint256 public registrationFee_ = 10 finney;             
    mapping(uint256 => PlayerBookReceiverInterface) public games_;   
    mapping(address => bytes32) public gameNames_;           
    mapping(address => uint256) public gameIDs_;             
    uint256 public gID_;         
    uint256 public pID_;         
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => Player) public plyr_;                
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_;  
    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
        uint256 rreward;
         
        uint256 cost;  
        uint32 round;  
        uint8 level;
    }

    event eveSuperPlayer(bytes32 _name, uint256 _pid, address _addr, uint8 _level);
    event eveResolve(uint256 _startBlockNumber, uint32 _roundNumber);
    event eveUpdate(uint256 _pID, uint32 _roundNumber, uint256 _roundCost, uint256 _cost);
    event eveDeposit(address _from, uint256 _value, uint256 _balance );
    event eveReward(uint256 _pID, uint256 _have, uint256 _reward, uint256 _vault, uint256 _allcost, uint256 _lastRefrralsVault );
    event eveWithdraw(uint256 _pID, address _addr, uint256 _reward, uint256 _balance );
    event eveSetAffID(uint256 _pID, address _addr, uint256 _laff, address _affAddr );


    mapping (uint8 => uint256) public levelValue_;

     
    uint256[] public superPlayers_;

     
    uint256[] public rankPlayers_;
    uint256[] public rankCost_;    

     
    uint256 public referralsVault_;
     
    uint256 public lastRefrralsVault_;

     
    uint256 constant public roundBlockCount_ = 5760;
     
    uint256 public startBlockNumber_;

     
    uint8 constant public rankNumbers_ = 10;
     
    uint32 public roundNumber_;

    


 
 
 
 

    constructor()
        public
    {
        levelValue_[3] = 0.003 ether;
        levelValue_[2] = 0.3 ether;
        levelValue_[1] = 1.5 ether;

         
         
         

        pID_ = 0;
        rankPlayers_.length = rankNumbers_;
        rankCost_.length = rankNumbers_;
        roundNumber_ = 0;
        startBlockNumber_ = block.number;
        referralsVault_ = 0;
        lastRefrralsVault_ =0;

        
        addSuperPlayer(0x008d20ea31021bb4C93F3051aD7763523BBb0481,"main",1);
        addSuperPlayer(0x00De30E1A0E82750ea1f96f6D27e112f5c8A352D,"go",1);

         
        addSuperPlayer(0x26042eb2f06D419093313ae2486fb40167Ba349C,"jack",1);
        addSuperPlayer(0x8d60d529c435e2A4c67FD233c49C3F174AfC72A8,"leon",1);
        addSuperPlayer(0xF9f24b9a5FcFf3542Ae3361c394AD951a8C0B3e1,"zuopiezi",1);
        addSuperPlayer(0x9ca974f2c49d68bd5958978e81151e6831290f57,"cowkeys",1);
        addSuperPlayer(0xf22978ed49631b68409a16afa8e123674115011e,"vulcan",1);
        addSuperPlayer(0x00b22a1D6CFF93831Cf2842993eFBB2181ad78de,"neo",1);
         
        addSuperPlayer(0x10a04F6b13E95Bf8cC82187536b87A8646f1Bd9d,"mydream",1);

         
        addSuperPlayer(0xce7aed496f69e2afdb99979952d9be8a38ad941d,"uking",1);
        addSuperPlayer(0x43fbedf2b2620ccfbd33d5c735b12066ff2fcdc1,"agg",1);

    }
 
 
 
 
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier onlyHaveReward() {
        require(myReward() > 0);
        _;
    }

     
    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        _;
    }

     
    modifier onlyDevs(){
        require(
             
            msg.sender == 0x00A32C09c8962AEc444ABde1991469eD0a9ccAf7 ||
            msg.sender == 0x00aBBff93b10Ece374B14abb70c4e588BA1F799F,
            "only dev"
        );
        _;
    }

     
    modifier isLevel(uint8 _level) {
        require(_level >= 0 && _level <= 3, "invalid level");
        require(msg.value >= levelValue_[_level], "sorry request price less than affiliate level");
        _;
    }
    
    modifier isRegisteredGame()
    {
        require(gameIDs_[msg.sender] != 0);
        _;
    }
 
 
 
 
     
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


 
 
 
 
    function addSuperPlayer(address _addr, bytes32 _name, uint8 _level)
        private
    {        
        pID_++;

        plyr_[pID_].addr = _addr;
        plyr_[pID_].name = _name;
        plyr_[pID_].names = 1;
        plyr_[pID_].level = _level;
        pIDxAddr_[_addr] = pID_;
        pIDxName_[_name] = pID_;
        plyrNames_[pID_][_name] = true;
        plyrNameList_[pID_][1] = _name;

        superPlayers_.push(pID_);

         
        emit eveSuperPlayer(_name,pID_,_addr,_level);        
    }
    
     
     
     
    function balances()
        public
        view
        returns(uint256)
    {
        return (address(this).balance);
    }
    
    
     
     
     
    function deposit()
        validAddress(msg.sender)
        external
        payable
        returns (bool)
    {
        if(msg.value>0){
            referralsVault_ += msg.value;

            emit eveDeposit(msg.sender, msg.value, address(this).balance);

            return true;
        }
        return false;
    }

    function updateRankBoard(uint256 _pID,uint256 _cost)
        isRegisteredGame()
        validAddress(msg.sender)    
        external
    {
        uint256 _affID = plyr_[_pID].laff;
        if(_affID<=0){
            return ;
        }

        if(_cost<=0){
            return ;
        }
         
        if(plyr_[_affID].level != 3){
            return ;
        }

        uint256 _affReward = _cost.mul(5)/100;

         
        if(  plyr_[_affID].round == roundNumber_ ){
             
            plyr_[_affID].cost += _affReward;
        }
        else{
             
            plyr_[_affID].cost = _affReward;
            plyr_[_affID].round = roundNumber_;
        }
         
        bool inBoard = false;
        for( uint8 i=0; i<rankNumbers_; i++ ){
            if(  _affID == rankPlayers_[i] ){
                 
                inBoard = true;
                rankCost_[i] = plyr_[_affID].cost;
                break;
            }
        }
        if( inBoard == false ){
             
            uint256 minCost = plyr_[_affID].cost;
            uint8 minIndex = rankNumbers_;
            for( uint8  k=0; k<rankNumbers_; k++){
                if( rankCost_[k] < minCost){
                    minIndex = k;
                    minCost = rankCost_[k];
                }            
            }
            if( minIndex != rankNumbers_ ){
                 
                rankPlayers_[minIndex] =  _affID;
                rankCost_[minIndex] = plyr_[_affID].cost;
            }
        }

        emit eveUpdate( _affID,roundNumber_,plyr_[_affID].cost,_cost);

    }

     
    function resolveRankBoard() 
         
        validAddress(msg.sender) 
        external
    {
        uint256 deltaBlockCount = block.number - startBlockNumber_;
        if( deltaBlockCount < roundBlockCount_ ){
            return;
        }
         
        startBlockNumber_ = block.number;
         
        emit eveResolve(startBlockNumber_,roundNumber_);
	   
        roundNumber_++;
         
        uint256 allCost = 0;
        for( uint8 k=0; k<rankNumbers_; k++){
            allCost += rankCost_[k];
        }

        if( allCost > 0 ){
            uint256 reward = 0;
            uint256 roundVault = referralsVault_.sub(lastRefrralsVault_);
            for( uint8 m=0; m<rankNumbers_; m++){                
                uint256 pid = rankPlayers_[m];
                if( pid>0 ){
                    reward = (roundVault.mul(8)/10).mul(rankCost_[m])/allCost;
                    lastRefrralsVault_ += reward;
                    plyr_[pid].rreward += reward;
                    emit eveReward(rankPlayers_[m],plyr_[pid].rreward, reward,referralsVault_,allCost, lastRefrralsVault_);
                }    
            }
        }
        
         
        rankPlayers_.length=0;
        rankCost_.length=0;

        rankPlayers_.length=10;
        rankCost_.length=10;
    }
    
     
    function myReward()
        public
        view
        returns(uint256)
    {
        uint256 pid = pIDxAddr_[msg.sender];
        return plyr_[pid].rreward;
    }

    function withdraw()
        onlyHaveReward()
        isHuman()
        public
    {
        address addr = msg.sender;
        uint256 pid = pIDxAddr_[addr];
        uint256 reward = plyr_[pid].rreward;
        
         
        plyr_[pid].rreward = 0;

         
        addr.transfer(reward);
        
         
        emit eveWithdraw(pIDxAddr_[addr], addr, reward, balances());
    }
 
 
 
 
    function checkIfNameValid(string _nameStr)
        public
        view
        returns(bool)
    {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0)
            return (true);
        else 
            return (false);
    }
 
 
 
 
     
    function registerNameXID(string _nameString, uint256 _affCode, bool _all, uint8 _level)
        isHuman()
        isLevel(_level)
        public
        payable 
    {
         
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
        
         
        address _addr = msg.sender;
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
         
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID) 
        {
             
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affCode = 0;
        }
        
         

        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all, _level);
    }
    
    function registerNameXaddr(string _nameString, address _affCode, bool _all, uint8 _level)
        isHuman()
        isLevel(_level)
        public
        payable 
    {
         
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
        
         
        address _addr = msg.sender;
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all, _level);
    }
    
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all, uint8 _level)
        isHuman()
        isLevel(_level)
        public
        payable 
    {
         
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
        
         
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
        
         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all, _level);
    }
    
     
    function addMeToGame(uint256 _gameID)
        isHuman()
        public
    {
        require(_gameID <= gID_, "silly player, that game doesn't exist yet");
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");
        uint256 _totalNames = plyr_[_pID].names;
        
         
        games_[_gameID].receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff, 0);
        
         
        if (_totalNames > 1)
            for (uint256 ii = 1; ii <= _totalNames; ii++)
                games_[_gameID].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
    }
    
     
    function addMeToAllGames()
        isHuman()
        public
    {
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        require(_pID != 0, "hey there buddy, you dont even have an account");
        uint256 _laff = plyr_[_pID].laff;
        uint256 _totalNames = plyr_[_pID].names;
        bytes32 _name = plyr_[_pID].name;
        
        for (uint256 i = 1; i <= gID_; i++)
        {
            games_[i].receivePlayerInfo(_pID, _addr, _name, _laff, 0);
            if (_totalNames > 1)
                for (uint256 ii = 1; ii <= _totalNames; ii++)
                    games_[i].receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
        }
                
    }
    
     
    function useMyOldName(string _nameString)
        isHuman()
        public 
    {
         
        bytes32 _name = _nameString.nameFilter();
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");
        
         
        plyr_[_pID].name = _name;
    }
    
 
 
 
 
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all, uint8 _level)
        private
    {
         
        if( pIDxName_[_name] == _pID && _pID !=0 ){
             
            if (_level >= plyr_[_pID].level ) {
                require(plyrNames_[_pID][_name] == true, "sorry that names already taken");
            }
        }
        else if (pIDxName_[_name] != 0){
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");
        }
         
        plyr_[_pID].name = _name;
        plyr_[_pID].level = _level;

        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

         
        Community_Wallet1.transfer(msg.value / 2);
        Community_Wallet2.transfer(msg.value / 2);
        
         
        if (_all == true)
            for (uint256 i = 1; i <= gID_; i++)
                games_[i].receivePlayerInfo(_pID, _addr, _name, _affID, _level);
        
         
        emit onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, msg.value, now);
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
 
 
 
 
    function getPlayerID(address _addr)
        isRegisteredGame()
        external
        returns (uint256)
    {
        determinePID(_addr);
        return (pIDxAddr_[_addr]);
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
    function getPlayerAddr(uint256 _pID)
        external
        view
        returns (address)
    {
        return (plyr_[_pID].addr);
    }
    function getPlayerLevel(uint256 _pID)
        external
        view
        returns (uint8)
    {
        return (plyr_[_pID].level);
    }
    function getNameFee()
        external
        view
        returns (uint256)
    {
        return(registrationFee_);
    }

    function setPlayerAffID(uint256 _pID,uint256 _laff)
        isRegisteredGame()
        external
    {
        plyr_[_pID].laff = _laff;

        emit eveSetAffID(_pID, plyr_[_pID].addr, _laff, plyr_[_laff].addr);
    }

    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all, uint8 _level)
        isRegisteredGame()
        isLevel(_level)
        external
        payable
        returns(bool, uint256)
    {
         
         
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
         
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID) 
        {
             
            if (plyr_[_pID].laff == 0)
                plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all, _level);
        
        return(_isNewPlayer, _affID);
    }
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all, uint8 _level)
        isRegisteredGame()
        isLevel(_level)
        external
        payable
        returns(bool, uint256)
    {
         
         
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
        uint256 _affID;
        if (_affCode != address(0) && _affCode != _addr)
        {
             
            _affID = pIDxAddr_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                if (plyr_[_pID].laff == 0)
                    plyr_[_pID].laff = _affID;
            }
        }

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all, _level);
        
        return(_isNewPlayer, _affID);
    }
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all, uint8 _level)
        isRegisteredGame()
        isLevel(_level)
        external
        payable
        returns(bool, uint256)
    {
         
         
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
        uint256 _affID;
        if (_affCode != "" && _affCode != _name)
        {
             
            _affID = pIDxName_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)
            {
                 
                if (plyr_[_pID].laff == 0)
                    plyr_[_pID].laff = _affID;
            }
        }
       
         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all, _level);
        
        return(_isNewPlayer, _affID);
    }
    
 
 
 
 
    function addGame(address _gameAddress, string _gameNameStr)
        onlyDevs()
        public
    {
        require(gameIDs_[_gameAddress] == 0, "derp, that games already been registered");


        deleteProposal("addGame");
        gID_++;
        bytes32 _name = _gameNameStr.nameFilter();
        gameIDs_[_gameAddress] = gID_;
        gameNames_[_gameAddress] = _name;
        games_[gID_] = PlayerBookReceiverInterface(_gameAddress);

        for(uint8 i=0; i<superPlayers_.length; i++){
            uint256 pid =superPlayers_[i];
            if( pid > 0 ){
                games_[gID_].receivePlayerInfo(pid, plyr_[pid].addr, plyr_[pid].name, 0, plyr_[pid].level);
            }
        }

    }
    
    function setRegistrationFee(uint256 _fee)
        onlyDevs()
        public
    {
        deleteProposal("setRegistrationFee");
        registrationFee_ = _fee;
    }
}