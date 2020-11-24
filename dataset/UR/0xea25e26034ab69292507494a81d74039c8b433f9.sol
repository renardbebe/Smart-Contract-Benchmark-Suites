 

pragma solidity ^0.4.24;

 

 
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

     
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

 

 

contract ILogger {
    function addNewLoggerPermission(address addressToPermission) public;
    function emitTaskCreated(uint uuid, uint amount) public;
    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public;
    function emitNewSmartToken(address token) public;
    function emitIssuance(uint256 amount) public;
    function emitDestruction(uint256 amount) public;
    function emitTransfer(address from, address to, uint256 value) public;
    function emitApproval(address owner, address spender, uint256 value) public;
    function emitGenericLog(string messageType, string message) public;
}

 

 
contract Logger is Owned, ILogger  {

     
    event TaskCreated(address msgSender, uint _uuid, uint _amount);
    event ProjectCreated(address msgSender, uint _uuid, uint _amount, address _address);

     
     
     
    event NewSmartToken(address msgSender, address _token);
     
    event Issuance(address msgSender, uint256 _amount);
     
    event Destruction(address msgSender, uint256 _amount);
     
    event Transfer(address msgSender, address indexed _from, address indexed _to, uint256 _value);
    event Approval(address msgSender, address indexed _owner, address indexed _spender, uint256 _value);

     
    event NewCommunityAddress(address msgSender, address _newAddress);

    event GenericLog(address msgSender, string messageType, string message);
    mapping (address => bool) public permissionedAddresses;

    modifier hasLoggerPermissions(address _address) {
        require(permissionedAddresses[_address] == true);
        _;
    }

    function addNewLoggerPermission(address addressToPermission) ownerOnly public {
        permissionedAddresses[addressToPermission] = true;
    }

    function emitTaskCreated(uint uuid, uint amount) public hasLoggerPermissions(msg.sender) {
        emit TaskCreated(msg.sender, uuid, amount);
    }

    function emitProjectCreated(uint uuid, uint amount, address rewardAddress) public hasLoggerPermissions(msg.sender) {
        emit ProjectCreated(msg.sender, uuid, amount, rewardAddress);
    }

    function emitNewSmartToken(address token) public hasLoggerPermissions(msg.sender) {
        emit NewSmartToken(msg.sender, token);
    }

    function emitIssuance(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Issuance(msg.sender, amount);
    }

    function emitDestruction(uint256 amount) public hasLoggerPermissions(msg.sender) {
        emit Destruction(msg.sender, amount);
    }

    function emitTransfer(address from, address to, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Transfer(msg.sender, from, to, value);
    }

    function emitApproval(address owner, address spender, uint256 value) public hasLoggerPermissions(msg.sender) {
        emit Approval(msg.sender, owner, spender, value);
    }

    function emitGenericLog(string messageType, string message) public hasLoggerPermissions(msg.sender) {
        emit GenericLog(msg.sender, messageType, message);
    }
}