 

pragma solidity ^0.4.24;

 
contract ENSResolver {
    function addr(bytes32 _node) public view returns (address);
    function setAddr(bytes32 _node, address _addr) public;
    function name(bytes32 _node) public view returns (string);
    function setName(bytes32 _node, string _name) public;
}

 
contract Owned {

     
    address public owner;

    event OwnerChanged(address indexed _newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

 
contract Managed is Owned {

     
    mapping (address => bool) public managers;

     
    modifier onlyManager {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

     
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "M: Address must not be null");
        if(managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }        
    }

     
    function revokeManager(address _manager) external onlyOwner {
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

 
contract ArgentENSResolver is Owned, Managed, ENSResolver {

    bytes4 constant SUPPORT_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;

     
    mapping (bytes32 => Record) records;

    struct Record {
        address addr;
        string name;
    }

     

    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

     

     
    function setAddr(bytes32 _node, address _addr) public onlyManager {
        records[_node].addr = _addr;
        emit AddrChanged(_node, _addr);
    }

     
    function setName(bytes32 _node, string _name) public onlyManager {
        records[_node].name = _name;
        emit NameChanged(_node, _name);
    }

     
    function addr(bytes32 _node) public view returns (address) {
        return records[_node].addr;
    }

     
    function name(bytes32 _node) public view returns (string) {
        return records[_node].name;
    }

     
    function supportsInterface(bytes4 _interfaceID) public view returns (bool) {
        return _interfaceID == SUPPORT_INTERFACE_ID || _interfaceID == ADDR_INTERFACE_ID || _interfaceID == NAME_INTERFACE_ID;
    }
}