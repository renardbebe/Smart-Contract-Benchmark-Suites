 

pragma solidity ^0.4.2;

 
contract Owned {

     
    address owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    function changeOwner(address newOwner) onlyowner {
        owner = newOwner;
    }

     
    modifier onlyowner() {
        if (msg.sender==owner) _;
    }

     
    function kill() onlyowner {
        if (msg.sender == owner) suicide(owner);
    }
}

 
contract Gods is Owned {

     
    struct Member {
        address member;
        string name;
        string surname;
        string patronymic;
        uint birthDate;
        string birthPlace;
        string avatarHash;
        uint avatarID;
        bool approved;
        uint memberSince;
    }

     
    Member[] public members;

     
    mapping (address => uint) public memberId;

     
    mapping (uint => string) public pks;

     
    mapping (uint => string) public memberData;

     
    event MemberAdded(address member, uint id);

     
    event MemberChanged(address member, uint id);

     
    function Gods() {
         
        addMember('', '', '', 0, '', '', 0, '');
    }

     
    function addMember(string name,
        string surname,
        string patronymic,
        uint birthDate,
        string birthPlace,
        string avatarHash,
        uint avatarID,
        string data) onlyowner {
        uint id;
        address member = msg.sender;
        if (memberId[member] == 0) {
            memberId[member] = members.length;
            id = members.length++;
            members[id] = Member({
                member: member,
                name: name,
                surname: surname,
                patronymic: patronymic,
                birthDate: birthDate,
                birthPlace: birthPlace,
                avatarHash: avatarHash,
                avatarID: avatarID,
                approved: (owner == member),
                memberSince: now
            });
            memberData[id] = data;
            if (member != 0) {
                MemberAdded(member, id);
            }
        } else {
            id = memberId[member];
            Member m = members[id];
            m.approved = true;
            m.name = name;
            m.surname = surname;
            m.patronymic = patronymic;
            m.birthDate = birthDate;
            m.birthPlace = birthPlace;
            m.avatarHash = avatarHash;
            m.avatarID = avatarID;
            memberData[id] = data;
            MemberChanged(member, id);
        }
    }

     
    function getPK(uint id) onlyowner constant returns (string) {
        return pks[id];
    }

     
    function getMemberCount() constant returns (uint) {
        return members.length - 1;
    }

     
    function getMember(uint id) constant returns (
        string name,
        string surname,
        string patronymic,
        uint birthDate,
        string birthPlace,
        string avatarHash,
        uint avatarID,
        string data) {
        Member m = members[id];
        name = m.name;
        surname = m.surname;
        patronymic = m.patronymic;
        birthDate = m.birthDate;
        birthPlace = m.birthPlace;
        avatarHash = m.avatarHash;
        avatarID = m.avatarID;
        data = memberData[id];
    }
}