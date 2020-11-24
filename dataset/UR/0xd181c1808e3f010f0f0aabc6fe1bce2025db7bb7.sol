 

 
pragma solidity 0.4.19;
 
 
 
 
contract NameRegistry {
    uint public nextId = 0;
    mapping (uint    => Participant) public participantMap;
    mapping (address => NameInfo)    public nameInfoMap;
    mapping (bytes12 => address)     public ownerMap;
    mapping (address => string)      public nameMap;
    struct NameInfo {
        bytes12  name;
        uint[]   participantIds;
    }
    struct Participant {
        address feeRecipient;
        address signer;
        bytes12 name;
        address owner;
    }
    event NameRegistered (
        string            name,
        address   indexed owner
    );
    event NameUnregistered (
        string             name,
        address    indexed owner
    );
    event OwnershipTransfered (
        bytes12            name,
        address            oldOwner,
        address            newOwner
    );
    event ParticipantRegistered (
        bytes12           name,
        address   indexed owner,
        uint      indexed participantId,
        address           singer,
        address           feeRecipient
    );
    event ParticipantUnregistered (
        uint    participantId,
        address owner
    );
    function registerName(string name)
        external
    {
        require(isNameValid(name));
        bytes12 nameBytes = stringToBytes12(name);
        require(ownerMap[nameBytes] == 0x0);
        require(stringToBytes12(nameMap[msg.sender]) == bytes12(0x0));
        nameInfoMap[msg.sender] = NameInfo(nameBytes, new uint[](0));
        ownerMap[nameBytes] = msg.sender;
        nameMap[msg.sender] = name;
        NameRegistered(name, msg.sender);
    }
    function unregisterName(string name)
        external
    {
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        uint[] storage participantIds = nameInfo.participantIds;
        bytes12 nameBytes = stringToBytes12(name);
        require(nameInfo.name == nameBytes);
        for (uint i = participantIds.length - 1; i >= 0; i--) {
            delete participantMap[participantIds[i]];
        }
        delete nameInfoMap[msg.sender];
        delete nameMap[msg.sender];
        delete ownerMap[nameBytes];
        NameUnregistered(name, msg.sender);
    }
    function transferOwnership(address newOwner)
        external
    {
        require(newOwner != 0x0);
        require(nameInfoMap[newOwner].name.length == 0);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        string storage name = nameMap[msg.sender];
        uint[] memory participantIds = nameInfo.participantIds;
        for (uint i = 0; i < participantIds.length; i ++) {
            Participant storage p = participantMap[participantIds[i]];
            p.owner = newOwner;
        }
        delete nameInfoMap[msg.sender];
        delete nameMap[msg.sender];
        nameInfoMap[newOwner] = nameInfo;
        nameMap[newOwner] = name;
        OwnershipTransfered(nameInfo.name, msg.sender, newOwner);
    }
     
     
     
     
     
     
    function addParticipant(
        address feeRecipient,
        address singer
        )
        external
        returns (uint)
    {
        require(feeRecipient != 0x0 && singer != 0x0);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        bytes12 name = nameInfo.name;
        require(name.length > 0);
        Participant memory participant = Participant(
            feeRecipient,
            singer,
            name,
            msg.sender
        );
        uint participantId = ++nextId;
        participantMap[participantId] = participant;
        nameInfo.participantIds.push(participantId);
        ParticipantRegistered(
            name,
            msg.sender,
            participantId,
            singer,
            feeRecipient
        );
        return participantId;
    }
    function removeParticipant(uint participantId)
        external
    {
        require(msg.sender == participantMap[participantId].owner);
        NameInfo storage nameInfo = nameInfoMap[msg.sender];
        uint[] storage participantIds = nameInfo.participantIds;
        delete participantMap[participantId];
        uint len = participantIds.length;
        for (uint i = 0; i < len; i ++) {
            if (participantId == participantIds[i]) {
                participantIds[i] = participantIds[len - 1];
                participantIds.length -= 1;
            }
        }
        ParticipantUnregistered(participantId, msg.sender);
    }
    function getParticipantById(uint id)
        external
        view
        returns (address feeRecipient, address signer)
    {
        Participant storage addressSet = participantMap[id];
        feeRecipient = addressSet.feeRecipient;
        signer = addressSet.signer;
    }
    function getParticipantIds(string name, uint start, uint count)
        external
        view
        returns (uint[] idList)
    {
        bytes12 nameBytes = stringToBytes12(name);
        address owner = ownerMap[nameBytes];
        require(owner != 0x0);
        NameInfo storage nameInfo = nameInfoMap[owner];
        uint[] storage pIds = nameInfo.participantIds;
        uint len = pIds.length;
        if (start >= len) {
            return;
        }
        uint end = start + count;
        if (end > len) {
            end = len;
        }
        if (start == end) {
            return;
        }
        idList = new uint[](end - start);
        for (uint i = start; i < end; i ++) {
            idList[i - start] = pIds[i];
        }
    }
    function getOwner(string name)
        external
        view
        returns (address)
    {
        bytes12 nameBytes = stringToBytes12(name);
        return ownerMap[nameBytes];
    }
    function isNameValid(string name)
        internal
        pure
        returns (bool)
    {
        bytes memory temp = bytes(name);
        return temp.length >= 6 && temp.length <= 12;
    }
    function stringToBytes12(string str)
        internal
        pure
        returns (bytes12 result)
    {
        assembly {
            result := mload(add(str, 32))
        }
    }
}