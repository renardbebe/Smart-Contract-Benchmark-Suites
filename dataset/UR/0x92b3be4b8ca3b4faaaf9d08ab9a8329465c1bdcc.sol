 

pragma solidity ^0.5.0;


 
contract Team {

    address public owner; 
   
    struct Admin {
        bool isAdmin; 
        bool isDev;
        bytes32 name; 
    }

    mapping (address => Admin) admins;

    constructor(address _owner) public {
        owner = _owner;
    }

    event OnAddAdmin(
        address indexed _address, 
        bool _isAdmin, 
        bool _isDev, 
        bytes32 _name
    );
    event OnRemoveAdmin(address indexed _address);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addAdmin(address _address, bool _isAdmin, bool _isDev, bytes32 _name) external onlyOwner() {
        admins[_address] = Admin(_isAdmin, _isDev, _name);        
        emit OnAddAdmin(_address, _isAdmin, _isDev, _name);
    }

    function removeAdmin(address _address) external onlyOwner() {
        delete admins[_address];        
        emit OnRemoveAdmin(_address);
    }

    function isOwner() external view returns (bool) {
        return owner == msg.sender;
    }

    function isAdmin(address _sender) external view returns (bool) {
        return admins[_sender].isAdmin;
    }

    function isDev(address _sender) external view returns (bool) {
        return admins[_sender].isDev;
    }

}