 

pragma solidity ^0.4.18;

 
contract Ownable {
    address owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

 
contract SecretNote is Ownable {
    struct UserInfo {
        mapping(bytes32 => bytes32) notes;
        bytes32[] noteKeys;
        uint256 index;  
    }

    mapping(address => UserInfo) private registerUsers;
    address[] private userIndex;

    event SecretNoteUpdated(address indexed _sender, bytes32 indexed _noteKey, bool _success);

    function SecretNote() public {
    }

    function userExisted(address _user) public constant returns (bool) {
        if (userIndex.length == 0) {
            return false;
        }

        return (userIndex[registerUsers[_user].index - 1] == _user);
    }

    function () public payable {
    }

     
    function withdraw(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }

     
    function getUserCount() public view onlyOwner returns (uint256) {
        return userIndex.length;
    }

     
    function getUserAddress(uint256 _index) public view onlyOwner returns (address) {
        require(_index > 0);
        return userIndex[_index - 1];
    }

     
    function getNote(bytes32 _noteKey) public view returns (bytes32) {
        return registerUsers[msg.sender].notes[_noteKey];
    }

     
    function getNoteKeysCount() public view returns (uint256) {
        return registerUsers[msg.sender].noteKeys.length;
    }

     
    function getNoteKeyByIndex(uint256 _index) public view returns (bytes32) {
        return registerUsers[msg.sender].noteKeys[_index];
    }

     
    function setNote(bytes32 _noteKey, bytes32 _content) public payable {
        require(_noteKey != "");
        require(_content != "");

        var userAddr = msg.sender;
        var user = registerUsers[userAddr];
        if (user.notes[_noteKey] == "") {
            user.noteKeys.push(_noteKey);
        }
        user.notes[_noteKey] = _content;

        if (user.index == 0) {
            userIndex.push(userAddr);
            user.index = userIndex.length;
        }
        SecretNoteUpdated(userAddr, _noteKey, true);
    }

     
    function destroyAccount() public returns (bool) {
        var userAddr = msg.sender;
        require(userExisted(userAddr));

        uint delIndex = registerUsers[userAddr].index;
        address userToMove = userIndex[userIndex.length - 1];

        if (userToMove == userAddr) {
            delete(registerUsers[userAddr]);
            userIndex.length = 0;
            return true;
        }

        userIndex[delIndex - 1] = userToMove;
        registerUsers[userToMove].index = delIndex;
        userIndex.length--;
        delete(registerUsers[userAddr]);
        return true;
    }
}