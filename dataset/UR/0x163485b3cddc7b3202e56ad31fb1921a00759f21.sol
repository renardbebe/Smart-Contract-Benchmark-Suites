 

 

pragma solidity ^0.4.20;

contract EtherChat {
    event messageSentEvent(address indexed from, address indexed to, bytes message, bytes32 encryption);
    event addContactEvent(address indexed from, address indexed to);
    event acceptContactEvent(address indexed from, address indexed to);
    event profileUpdateEvent(address indexed from, bytes32 name, bytes32 avatarUrl);
    event blockContactEvent(address indexed from, address indexed to);
    event unblockContactEvent(address indexed from, address indexed to);
    
    enum RelationshipType {NoRelation, Requested, Connected, Blocked}
    
    struct Member {
        bytes32 publicKeyLeft;
        bytes32 publicKeyRight;
        bytes32 name;
        bytes32 avatarUrl;
        uint messageStartBlock;
        bool isMember;
    }
    
    mapping (address => mapping (address => RelationshipType)) relationships;
    mapping (address => Member) public members;
    
    function addContact(address addr) public onlyMember {
        require(relationships[msg.sender][addr] == RelationshipType.NoRelation);
        require(relationships[addr][msg.sender] == RelationshipType.NoRelation);
        
        relationships[msg.sender][addr] = RelationshipType.Requested;
        emit addContactEvent(msg.sender, addr);
    }

    function acceptContactRequest(address addr) public onlyMember {
        require(relationships[addr][msg.sender] == RelationshipType.Requested);
        
        relationships[msg.sender][addr] = RelationshipType.Connected;
        relationships[addr][msg.sender] = RelationshipType.Connected;

        emit acceptContactEvent(msg.sender, addr);
    }
    
    function join(bytes32 publicKeyLeft, bytes32 publicKeyRight) public {
        require(members[msg.sender].isMember == false);
        
        Member memory newMember = Member(publicKeyLeft, publicKeyRight, "", "", 0, true);
        members[msg.sender] = newMember;
    }
    
    function sendMessage(address to, bytes message, bytes32 encryption) public onlyMember {
        require(relationships[to][msg.sender] == RelationshipType.Connected);

        if (members[to].messageStartBlock == 0) {
            members[to].messageStartBlock = block.number;
        }
        
        emit messageSentEvent(msg.sender, to, message, encryption);
    }
    
    function blockMessagesFrom(address from) public onlyMember {
        require(relationships[msg.sender][from] == RelationshipType.Connected);

        relationships[msg.sender][from] = RelationshipType.Blocked;
        emit blockContactEvent(msg.sender, from);
    }
    
    function unblockMessagesFrom(address from) public onlyMember {
        require(relationships[msg.sender][from] == RelationshipType.Blocked);

        relationships[msg.sender][from] = RelationshipType.Connected;
        emit unblockContactEvent(msg.sender, from);
    }
    
    function updateProfile(bytes32 name, bytes32 avatarUrl) public onlyMember {
        members[msg.sender].name = name;
        members[msg.sender].avatarUrl = avatarUrl;
        emit profileUpdateEvent(msg.sender, name, avatarUrl);
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isMember == true);
        _;
    }
    
    function getRelationWith(address a) public view onlyMember returns (RelationshipType) {
        return relationships[msg.sender][a];
    }
}