 

pragma solidity ^0.4.24;
 
 
 
interface TeamJustInterface {
    function requiredSignatures() external view returns(uint256);
    function requiredDevSignatures() external view returns(uint256);
    function adminCount() external view returns(uint256);
    function devCount() external view returns(uint256);
    function adminName(address _who) external view returns(bytes32);
    function isAdmin(address _who) external view returns(bool);
    function isDev(address _who) external view returns(bool);
}
interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff) external;
    function receivePlayerNameList(uint256 _pID, bytes32 _name) external;
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
    function isDev(address _who) external view returns(bool);
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
contract TeamJust is TeamJustInterface {
    address private Jekyll_Island_Inc;
     
     
     
    MSFun.Data private msData;
    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
    function checkData(bytes32 _whatFunction) onlyAdmins() public view returns(bytes32 message_data, uint256 signature_count) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
    function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(bytes32, bytes32, bytes32) {return(this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}

     
     
     
    struct Admin {
        bool isAdmin;
        bool isDev;
        bytes32 name;
    }
    mapping (address => Admin) admins_;
    
    uint256 adminCount_;
    uint256 devCount_;
    uint256 requiredSignatures_;
    uint256 requiredDevSignatures_;
    
     
     
     
    constructor()
        public
    {
        Jekyll_Island_Inc = msg.sender;
        address inventor = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        address mantso   = 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D;
        address justo    = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        address sumpunk  = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C;
		address deployer = msg.sender;
        
        admins_[inventor] = Admin(true, true, "inventor");
        admins_[mantso]   = Admin(true, true, "mantso");
        admins_[justo]    = Admin(true, true, "justo");
        admins_[sumpunk]  = Admin(true, true, "sumpunk");
		admins_[deployer] = Admin(true, true, "deployer");
        
        adminCount_ = 5;
        devCount_ = 5;
        requiredSignatures_ = 1;
        requiredDevSignatures_ = 1;
    }
     
     
     
     
     
     
    function ()
        public
        payable
    {
        Jekyll_Island_Inc.transfer(address(this).balance);
    }


     
     
     
    modifier onlyDevs()
    {
        require(admins_[msg.sender].isDev == true, "onlyDevs failed - msg.sender is not a dev");
        _;
    }
    
    modifier onlyAdmins()
    {
        require(admins_[msg.sender].isAdmin == true, "onlyAdmins failed - msg.sender is not an admin");
        _;
    }

     
     
     
     
    function addAdmin(address _who, bytes32 _name, bool _isDev)
        public
        onlyDevs()
    {
        if (MSFun.multiSig(msData, requiredDevSignatures_, "addAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "addAdmin");
            
             
             
            if (admins_[_who].isAdmin == false) 
            { 
                
                 
                admins_[_who].isAdmin = true;
        
                 
                adminCount_ += 1;
                requiredSignatures_ += 1;
            }
            
             
             
             
            if (_isDev == true) 
            {
                 
                admins_[_who].isDev = _isDev;
                
                 
                devCount_ += 1;
                requiredDevSignatures_ += 1;
            }
        }
        
         
         
         
        admins_[_who].name = _name;
    }

     
    function removeAdmin(address _who)
        public
        onlyDevs()
    {
         
         
        require(adminCount_ > 1, "removeAdmin failed - cannot have less than 2 admins");
        require(adminCount_ >= requiredSignatures_, "removeAdmin failed - cannot have less admins than number of required signatures");
        if (admins_[_who].isDev == true)
        {
            require(devCount_ > 1, "removeAdmin failed - cannot have less than 2 devs");
            require(devCount_ >= requiredDevSignatures_, "removeAdmin failed - cannot have less devs than number of required dev signatures");
        }
        
         
        if (MSFun.multiSig(msData, requiredDevSignatures_, "removeAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "removeAdmin");
            
             
             
            if (admins_[_who].isAdmin == true) {  
                
                 
                admins_[_who].isAdmin = false;
                
                 
                adminCount_ -= 1;
                if (requiredSignatures_ > 1) 
                {
                    requiredSignatures_ -= 1;
                }
            }
            
             
            if (admins_[_who].isDev == true) {
                
                 
                admins_[_who].isDev = false;
                
                 
                devCount_ -= 1;
                if (requiredDevSignatures_ > 1) 
                {
                    requiredDevSignatures_ -= 1;
                }
            }
        }
    }

     
    function changeRequiredSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
         
        require(_howMany > 0 && _howMany <= adminCount_, "changeRequiredSignatures failed - must be between 1 and number of admins");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredSignatures");
            
             
            requiredSignatures_ = _howMany;
        }
    }
    
     
    function changeRequiredDevSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
         
        require(_howMany > 0 && _howMany <= devCount_, "changeRequiredDevSignatures failed - must be between 1 and number of devs");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredDevSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredDevSignatures");
            
             
            requiredDevSignatures_ = _howMany;
        }
    }

     
     
     
    function requiredSignatures() external view returns(uint256) {return(requiredSignatures_);}
    function requiredDevSignatures() external view returns(uint256) {return(requiredDevSignatures_);}
    function adminCount() external view returns(uint256) {return(adminCount_);}
    function devCount() external view returns(uint256) {return(devCount_);}
    function adminName(address _who) external view returns(bytes32) {return(admins_[_who].name);}
    function isAdmin(address _who) external view returns(bool) {return(admins_[_who].isAdmin);}
    function isDev(address _who) external view returns(bool) {return(admins_[_who].isDev);}
}
contract PlayerBook is PlayerBookInterface {
    using NameFilter for string;
    using SafeMath for uint256;

    address private Jekyll_Island_Inc;
    address public teamJust; 

    MSFun.Data private msData;

    function multiSigDev(bytes32 _whatFunction) private returns (bool) {return (MSFun.multiSig(msData, TeamJustInterface(teamJust).requiredDevSignatures(), _whatFunction));}

    function deleteProposal(bytes32 _whatFunction) private {MSFun.deleteProposal(msData, _whatFunction);}

    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}

    function checkData(bytes32 _whatFunction) onlyDevs() public view returns (bytes32, uint256) {return (MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}

    function checkSignersByAddress(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyDevs() public view returns (address, address, address) {return (MSFun.checkSigner(msData, _whatFunction, _signerA), MSFun.checkSigner(msData, _whatFunction, _signerB), MSFun.checkSigner(msData, _whatFunction, _signerC));}

    function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyDevs() public view returns (bytes32, bytes32, bytes32) {return (TeamJustInterface(teamJust).adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), TeamJustInterface(teamJust).adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), TeamJustInterface(teamJust).adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}
     
     
     
     
    uint256 public registrationFee_ = 10 finney;             
    mapping(uint256 => address) public games_;   
    mapping(address => bytes32) public gameNames_;           
    mapping(address => uint256) public gameIDs_;             
    uint256 public gID_;         
    uint256 public pID_;         
    mapping(address => uint256) public pIDxAddr_;           
    mapping(bytes32 => uint256) public pIDxName_;           
    mapping(uint256 => Player) public plyr_;                
    mapping(uint256 => mapping(bytes32 => bool)) public plyrNames_;  
    mapping(uint256 => mapping(uint256 => bytes32)) public plyrNameList_;  
    struct Player {
        address addr;
        bytes32 name;
        uint256 laff;
        uint256 names;
    }

    address public owner;

    function setTeam(address _teamJust) external {
        require(msg.sender == owner, 'only dev!');
        require(address(teamJust) == address(0), 'already set!');
        teamJust = _teamJust;
    }
     
     
     
     
    constructor()
    public
    {
        owner = msg.sender;
         
         
         
        plyr_[1].addr = msg.sender;
        plyr_[1].name = "wq";
        plyr_[1].names = 1;
        pIDxAddr_[msg.sender] = 1;
        pIDxName_["wq"] = 1;
        plyrNames_[1]["wq"] = true;
        plyrNameList_[1][1] = "wq";

        pID_ = 1;
        Jekyll_Island_Inc = msg.sender;
    }
     
     
     
     
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier onlyDevs()
    {
        require(TeamJustInterface(teamJust).isDev(msg.sender) == true, "msg sender is not a dev");
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
     
     
     
     
    function checkIfNameValid(string _nameStr)
    public
    view
    returns (bool)
    {
        bytes32 _name = _nameStr.nameFilter();
        if (pIDxName_[_name] == 0)
            return (true);
        else
            return (false);
    }
     
     
     
     
     
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
    isHuman()
    public
    payable
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
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

         
        registerNameCore(_pID, _addr, _affCode, _name, _isNewPlayer, _all);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
    isHuman()
    public
    payable
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
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

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
    isHuman()
    public
    payable
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
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

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);
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

         
        PlayerBookReceiverInterface(games_[_gameID]).receivePlayerInfo(_pID, _addr, plyr_[_pID].name, plyr_[_pID].laff);

         
        if (_totalNames > 1)
            for (uint256 ii = 1; ii <= _totalNames; ii++)
                PlayerBookReceiverInterface(games_[_gameID]).receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
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
            PlayerBookReceiverInterface(games_[i]).receivePlayerInfo(_pID, _addr, _name, _laff);
            if (_totalNames > 1)
                for (uint256 ii = 1; ii <= _totalNames; ii++)
                    PlayerBookReceiverInterface(games_[i]).receivePlayerNameList(_pID, plyrNameList_[_pID][ii]);
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

     
     
     
     
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer, bool _all)
    private
    {
         
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");

         
        plyr_[_pID].name = _name;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }

         
        Jekyll_Island_Inc.transfer(address(this).balance);

         
        if (_all == true)
            for (uint256 i = 1; i <= gID_; i++)
                PlayerBookReceiverInterface(games_[i]).receivePlayerInfo(_pID, _addr, _name, _affID);

         
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

    function getNameFee()
    external
    view
    returns (uint256)
    {
        return (registrationFee_);
    }

    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns (bool, uint256)
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
        bool _isNewPlayer = determinePID(_addr);

         
        uint256 _pID = pIDxAddr_[_addr];

         
         
         
        uint256 _affID = _affCode;
        if (_affID != 0 && _affID != plyr_[_pID].laff && _affID != _pID)
        {
             
            plyr_[_pID].laff = _affID;
        } else if (_affID == _pID) {
            _affID = 0;
        }

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return (_isNewPlayer, _affID);
    }

    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns (bool, uint256)
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
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

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return (_isNewPlayer, _affID);
    }

    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all)
    isRegisteredGame()
    external
    payable
    returns (bool, uint256)
    {
         
        require(msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

         
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

         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer, _all);

        return (_isNewPlayer, _affID);
    }

     
     
     
     
    function addGame(address _gameAddress, bytes32 _gameNameStr)
    onlyDevs()
    external
    {
        require(gameIDs_[_gameAddress] == 0, "derp, that games already been registered");

        if (multiSigDev("addGame") == true)
        {deleteProposal("addGame");
            gID_++;
            bytes32 _name = _gameNameStr;
            gameIDs_[_gameAddress] = gID_;
            gameNames_[_gameAddress] = _name;
            games_[gID_] = _gameAddress;

 

        }
    }

    function setRegistrationFee(uint256 _fee)
    onlyDevs()
    public
    {
        if (multiSigDev("setRegistrationFee") == true)
        {deleteProposal("setRegistrationFee");
            registrationFee_ = _fee;
        }
    }

    function isDev(address _who) external view returns(bool) {return TeamJustInterface(teamJust).isDev(_who);}

}