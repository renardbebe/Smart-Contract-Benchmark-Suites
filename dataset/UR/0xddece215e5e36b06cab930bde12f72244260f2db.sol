 

pragma solidity ^0.4.25;

 

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

     
    constructor() public {
        owner = msg.sender;
    }
}

contract Managed is Owned {
    mapping(address => bool) public isManager;

    modifier onlyManagers {
        require(msg.sender == owner || isManager[msg.sender], "Not authorized");
        _;
    }

    function setIsManager(address _address, bool _value) external onlyOwner {
        isManager[_address] = _value;
    }
}

contract BRNameBook is Managed {
    using SafeMath for uint256;

    address public feeRecipient = 0xFd6D4265443647C70f8D0D80356F3b22d596DA29;  

    uint256 public registrationFee = 0.1 ether;              
    uint256 public numPlayers;                               
    mapping (address => uint256) public playerIdByAddr;      
    mapping (bytes32 => uint256) public playerIdByName;      
    mapping (uint256 => Player) public playerData;           
    mapping (uint256 => mapping (bytes32 => bool)) public playerOwnsName;  
    mapping (uint256 => mapping (uint256 => bytes32)) public playerNamesList;  

    struct Player {
        address addr;
        address loomAddr;
        bytes32 name;
        uint256 lastAffiliate;
        uint256 nameCount;
    }

    constructor() public {

    }

     
    modifier onlyHumans() {
        require(msg.sender == tx.origin, "Humans only");
        _;
    }

    event NameRegistered (
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

    function nameIsValid(string _nameStr) public view returns(bool) {
        bytes32 _name = _processName(_nameStr);
        return (playerIdByName[_name] == 0);
    }

    function setRegistrationFee(uint256 _newFee) onlyManagers() external {
        registrationFee = _newFee;
    }

    function setFeeRecipient(address _feeRecipient) onlyManagers() external {
        feeRecipient = _feeRecipient;
    }

     
    function registerNameAffId(string _nameString, uint256 _affCode) onlyHumans() external payable {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bytes32 name = _processName(_nameString);

         
        address addr = msg.sender;

         
        bool isNewPlayer = _determinePlayerId(addr);

         
        uint256 playerId = playerIdByAddr[addr];

         
         
         
        uint256 affiliateId = _affCode;
        if (affiliateId != 0 && affiliateId != playerData[playerId].lastAffiliate && affiliateId != playerId) {
             
            playerData[playerId].lastAffiliate = affiliateId;
        } else if (_affCode == playerId) {
            affiliateId = 0;
        }

         
        _registerName(playerId, addr, affiliateId, name, isNewPlayer);
    }

    function registerNameAffAddress(string _nameString, address _affCode) onlyHumans() external payable {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bytes32 name = _processName(_nameString);

         
        address addr = msg.sender;

         
        bool isNewPlayer = _determinePlayerId(addr);

         
        uint256 playerId = playerIdByAddr[addr];

         
         
        uint256 affiliateId;
        if (_affCode != address(0) && _affCode != addr) {
             
            affiliateId = playerIdByAddr[_affCode];

             
            if (affiliateId != playerData[playerId].lastAffiliate) {
                 
                playerData[playerId].lastAffiliate = affiliateId;
            }
        }

         
        _registerName(playerId, addr, affiliateId, name, isNewPlayer);
    }

    function registerNameAffName(string _nameString, bytes32 _affCode) onlyHumans() public payable {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bytes32 name = _processName(_nameString);

         
        address addr = msg.sender;

         
        bool isNewPlayer = _determinePlayerId(addr);

         
        uint256 playerId = playerIdByAddr[addr];

         
         
        uint256 affiliateId;
        if (_affCode != "" && _affCode != name) {
             
            affiliateId = playerIdByName[_affCode];

             
            if (affiliateId != playerData[playerId].lastAffiliate) {
                 
                playerData[playerId].lastAffiliate = affiliateId;
            }
        }

         
        _registerName(playerId, addr, affiliateId, name, isNewPlayer);
    }

     
    function useMyOldName(string _nameString) onlyHumans() public {
         
        bytes32 name = _processName(_nameString);
        uint256 playerId = playerIdByAddr[msg.sender];

         
        require(playerOwnsName[playerId][name] == true, "Not your name");

         
        playerData[playerId].name = name;
    }


    function _registerName(uint256 _playerId, address _addr, uint256 _affID, bytes32 _name, bool _isNewPlayer) internal {
         
        if (playerIdByName[_name] != 0) {
            require(playerOwnsName[_playerId][_name] == true, "Name already taken");
        }

         
        playerData[_playerId].name = _name;
        playerIdByName[_name] = _playerId;
        if (playerOwnsName[_playerId][_name] == false) {
            playerOwnsName[_playerId][_name] = true;
            playerData[_playerId].nameCount++;
            playerNamesList[_playerId][playerData[_playerId].nameCount] = _name;
        }

         
        uint256 total = address(this).balance;
        uint256 devDirect = total.mul(375).div(1000);
        owner.call.value(devDirect)();
        feeRecipient.call.value(total.sub(devDirect))();

         
        emit NameRegistered(_playerId, _addr, _name, _isNewPlayer, _affID, playerData[_affID].addr, playerData[_affID].name, msg.value, now);
    }

    function _determinePlayerId(address _addr) internal returns (bool) {
        if (playerIdByAddr[_addr] == 0)
        {
            numPlayers++;
            playerIdByAddr[_addr] = numPlayers;
            playerData[numPlayers].addr = _addr;

             
            return true;
        } else {
            return false;
        }
    }

    function _processName(string _input) internal pure returns (bytes32) {
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

    function registerNameAffIdExternal(address _addr, bytes32 _name, uint256 _affCode)
    onlyManagers()
    external
    payable
    returns (bool, uint256)
    {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bool isNewPlayer = _determinePlayerId(_addr);

         
        uint256 playerId = playerIdByAddr[_addr];

         
         
         
        uint256 affiliateId = _affCode;
        if (affiliateId != 0 && affiliateId != playerData[playerId].lastAffiliate && affiliateId != playerId) {
             
            playerData[playerId].lastAffiliate = affiliateId;
        } else if (affiliateId == playerId) {
            affiliateId = 0;
        }

         
        _registerName(playerId, _addr, affiliateId, _name, isNewPlayer);

        return (isNewPlayer, affiliateId);
    }

    function registerNameAffAddressExternal(address _addr, bytes32 _name, address _affCode)
    onlyManagers()
    external
    payable
    returns (bool, uint256)
    {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bool isNewPlayer = _determinePlayerId(_addr);

         
        uint256 playerId = playerIdByAddr[_addr];

         
         
        uint256 affiliateId;
        if (_affCode != address(0) && _affCode != _addr)
        {
             
            affiliateId = playerIdByAddr[_affCode];

             
            if (affiliateId != playerData[playerId].lastAffiliate) {
                 
                playerData[playerId].lastAffiliate = affiliateId;
            }
        }

         
        _registerName(playerId, _addr, affiliateId, _name, isNewPlayer);

        return (isNewPlayer, affiliateId);
    }

    function registerNameAffNameExternal(address _addr, bytes32 _name, bytes32 _affCode)
    onlyManagers()
    external
    payable
    returns (bool, uint256)
    {
         
        require (msg.value >= registrationFee, "Value below the fee");

         
        bool isNewPlayer = _determinePlayerId(_addr);

         
        uint256 playerId = playerIdByAddr[_addr];

         
         
        uint256 affiliateId;
        if (_affCode != "" && _affCode != _name)
        {
             
            affiliateId = playerIdByName[_affCode];

             
            if (affiliateId != playerData[playerId].lastAffiliate) {
                 
                playerData[playerId].lastAffiliate = affiliateId;
            }
        }

         
        _registerName(playerId, _addr, affiliateId, _name, isNewPlayer);

        return (isNewPlayer, affiliateId);
    }

    function assignPlayerID(address _addr) onlyManagers() external returns (uint256) {
        _determinePlayerId(_addr);
        return playerIdByAddr[_addr];
    }

    function getPlayerID(address _addr) public view returns (uint256) {
        return playerIdByAddr[_addr];
    }

    function getPlayerName(uint256 _pID) public view returns (bytes32) {
        return playerData[_pID].name;
    }

    function getPlayerNameCount(uint256 _pID) public view returns (uint256) {
        return playerData[_pID].nameCount;
    }

    function getPlayerLastAffiliate(uint256 _pID) public view returns (uint256) {
        return playerData[_pID].lastAffiliate;
    }

    function getPlayerAddr(uint256 _pID) public view returns (address) {
        return playerData[_pID].addr;
    }

    function getPlayerLoomAddr(uint256 _pID) public view returns (address) {
        return playerData[_pID].loomAddr;
    }

    function getPlayerLoomAddrByAddr(address _addr) public view returns (address) {
        uint256 playerId = playerIdByAddr[_addr];
        if (playerId == 0) {
            return 0;
        }

        return playerData[playerId].loomAddr;
    }

    function getPlayerNames(uint256 _pID) public view returns (bytes32[]) {
        uint256 nameCount = playerData[_pID].nameCount;

        bytes32[] memory names = new bytes32[](nameCount);

        uint256 i;
        for (i = 1; i <= nameCount; i++) {
            names[i - 1] = playerNamesList[_pID][i];
        }

        return names;
    }

    function setPlayerLoomAddr(uint256 _pID, address _addr, bool _allowOverwrite) onlyManagers() external {
        require(_allowOverwrite || playerData[_pID].loomAddr == 0x0);

        playerData[_pID].loomAddr = _addr;
    }

}

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sqrt(uint256 x) internal pure returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x) internal pure returns (uint256)
    {
        return mul(x,x);
    }

     
    function pwr(uint256 x, uint256 y) internal pure returns (uint256)
    {
        if (x==0) {
            return 0;
        } else if (y==0) {
            return 1;
        } else {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return z;
        }
    }
}