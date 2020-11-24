 

pragma solidity 0.4.25;


interface FSForwarderInterface {
    function deposit() external payable returns(bool);
}


 
 
 
 
 
 
 
 
contract FSBook {
    using NameFilter for string;
    using SafeMath for uint256;

     
    FSForwarderInterface constant private FSKingCorp = FSForwarderInterface(0x3a2321DDC991c50518969B93d2C6B76bf5309790);

     
    uint256 public registrationFee_ = 10 finney;             
    uint256 public affiliateFee_ = 500 finney;               
    uint256 public pID_;         

     
    mapping (address => uint256) public pIDxAddr_;
     
    mapping (bytes32 => uint256) public pIDxName_;
     
    mapping (uint256 => Player) public plyr_;
     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
     
    mapping (uint256 => mapping (uint256 => bytes32)) public plyrNameList_;
     
    mapping (address => bool) public registeredGames_;


    struct Player {
        address addr;
        bytes32 name;
        bool hasAff;

        uint256 aff;
        uint256 withdrawnAff;

        uint256 laff;
        uint256 affT2;
        uint256 names;
    }


     
    constructor()
        public
    {
         
         
         
        plyr_[1].addr = 0xe0b005384df8f4d80e9a69b6210ec1929a935d97;
        plyr_[1].name = "sportking";
        plyr_[1].hasAff = true;
        plyr_[1].names = 1;
        pIDxAddr_[0xe0b005384df8f4d80e9a69b6210ec1929a935d97] = 1;
        pIDxName_["sportking"] = 1;
        plyrNames_[1]["sportking"] = true;
        plyrNameList_[1][1] = "sportking";

        pID_ = 1;
    }

     
    
     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin, "Human only");

        uint256 _codeLength;
        assembly { _codeLength := extcodesize(_addr) }
        require(_codeLength == 0, "Human only");
        _;
    }
    

     
     
    modifier onlyDevs() 
    {
         
        require(msg.sender == 0xe0b005384df8f4d80e9a69b6210ec1929a935d97 ||
            msg.sender == 0xe3ff68fb79fee1989fb67eb04e196e361ecaec3e ||
            msg.sender == 0xb914843d2e56722a2c133eff956d1f99b820d468 ||
            msg.sender == 0xc52FA2C9411fCd4f58be2d6725094689C46242f2, "msg sender is not a dev");
        _;
    }


     
    modifier isRegisteredGame() {
        require(registeredGames_[msg.sender] == true, "sender is not registered");
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
        uint256 timestamp
    );

    event onNewAffiliate
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 amountPaid,
        uint256 timestamp
    );

    event onUseOldName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 timestamp
    );

    event onGameRegistered
    (
        address indexed gameAddress,
        bool enabled,
        uint256 timestamp
    );

    event onWithdraw
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        uint256 amount,
        uint256 timestamp  
    );

     
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

     
     

    function registerNameXID(string _nameString, uint256 _affCode)
        external
        payable 
        isHuman()
    {
         
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
        
         
        address _addr = msg.sender;
        
         
        bool _isNewPlayer = determinePID(_addr);
        
         
        uint256 _pID = pIDxAddr_[_addr];
        
         
         
         
        uint256 _affID = _affCode;
        if (_affCode != 0 && _affCode != plyr_[_pID].laff && _affCode != _pID) 
        {
             
            plyr_[_pID].laff = _affCode;
        } else if (_affCode == _pID) {
            _affID = 0;
        }
        
         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }
    

    function registerNameXaddr(string _nameString, address _affCode)
        external
        payable 
        isHuman()
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
        
         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }
    

    function registerNameXname(string _nameString, bytes32 _affCode)
        external
        payable 
        isHuman()
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
        
         
        registerNameCore(_pID, _addr, _affID, _name, _isNewPlayer);
    }


    function registerAffiliate()
        external
        payable
        isHuman()
    {
         
        require (msg.value >= affiliateFee_, "umm.....  you have to pay the name fee");

         
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];

        require (_pID > 0, "you need to be registered");
        require (plyr_[_pID].hasAff == false, "already registered as affiliate");

        FSKingCorp.deposit.value(msg.value)();
        plyr_[_pID].hasAff = true;

        bytes32 _name = plyr_[_pID].name;

         
        emit onNewAffiliate(_pID, _addr, _name, msg.value, now);
    }


    function registerGame(address _contract, bool _enable)
        external
        isHuman()
        onlyDevs()
    {
        registeredGames_[_contract] = _enable;

        emit onGameRegistered(_contract, _enable, now);
    }
    
     
    function useMyOldName(string _nameString)
        external
        isHuman()
    {
         
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        
         
        require(plyrNames_[_pID][_name] == true, "umm... thats not a name you own");
        
         
        plyr_[_pID].name = _name;

        emit onUseOldName(_pID, _addr, _name, now);
    }

     
    function depositAffiliate(uint256 _pID)
        external
        payable
        isRegisteredGame()
    {
        require(plyr_[_pID].hasAff == true, "Not registered as affiliate");

        uint256 value = msg.value;
        plyr_[_pID].aff = value.add(plyr_[_pID].aff);
    }

     
    function withdraw()
        external
        isHuman()
    {
        address _addr = msg.sender;
        uint256 _pID = pIDxAddr_[_addr];
        bytes32 _name = plyr_[_pID].name;
        require(_pID != 0, "need to be registered");

        uint256 _remainValue = (plyr_[_pID].aff).sub(plyr_[_pID].withdrawnAff);
        if (_remainValue > 0) {
            plyr_[_pID].withdrawnAff = plyr_[_pID].aff;
            address(msg.sender).transfer(_remainValue);
        }

        emit onWithdraw(_pID, _addr, _name, _remainValue, now);
    }
    
     
    function registerNameCore(uint256 _pID, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer)
        private
    {
         
        if (pIDxName_[_name] != 0)
            require(plyrNames_[_pID][_name] == true, "sorry that names already taken");
        
         
        plyr_[_pID].name = _name;
        plyr_[_pID].affT2 = _affID;
        pIDxName_[_name] = _pID;
        if (plyrNames_[_pID][_name] == false)
        {
            plyrNames_[_pID][_name] = true;
            plyr_[_pID].names++;
            plyrNameList_[_pID][plyr_[_pID].names] = _name;
        }
        
         
         
         
        FSKingCorp.deposit.value(msg.value)();
        
         
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
        external
        isRegisteredGame()
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

    function setPlayerLAff(uint256 _pID, uint256 _lAff)
        external
        isRegisteredGame()
    {
        if (_pID != _lAff && plyr_[_pID].laff != _lAff) {
            plyr_[_pID].laff = _lAff;
        }
    }

    function getPlayerAffT2(uint256 _pID)
        external
        view
        returns (uint256)
    {
        return (plyr_[_pID].affT2);
    }

    function getPlayerAddr(uint256 _pID)
        external
        view
        returns (address)
    {
        return (plyr_[_pID].addr);
    }

    function getPlayerHasAff(uint256 _pID)
        external
        view
        returns (bool)
    {
        return (plyr_[_pID].hasAff);
    }

    function getNameFee()
        external
        view
        returns (uint256)
    {
        return(registrationFee_);
    }

    function getAffiliateFee()
        external
        view
        returns (uint256)
    {
        return (affiliateFee_);
    }
    
    function setRegistrationFee(uint256 _fee)
        external
        onlyDevs()
    {
        registrationFee_ = _fee;
    }

    function setAffiliateFee(uint256 _fee)
        external
        onlyDevs()
    {
        affiliateFee_ = _fee;
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