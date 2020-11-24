 

pragma solidity 0.4.18;
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
 
 
contract LRxAirdropAddressBinding is Ownable {
    mapping(address => mapping(uint8 => string)) public bindings;
    mapping(uint8 => string) public projectNameMap;
    event AddressesBound(address sender, uint8 projectId, string targetAddr);
    event AddressesUnbound(address sender, uint8 projectId);
     
    function bind(uint8 projectId, string targetAddr)
        external
    {
        require(projectId > 0);
        bindings[msg.sender][projectId] = targetAddr;
        AddressesBound(msg.sender, projectId, targetAddr);
    }
    function unbind(uint8 projectId)
        external
    {
        require(projectId > 0);
        delete bindings[msg.sender][projectId];
        AddressesUnbound(msg.sender, projectId);
    }
    function getBindingAddress(address owner, uint8 projectId)
        external
        view
        returns (string)
    {
        require(projectId > 0);
        return bindings[owner][projectId];
    }
    function setProjectName(uint8 id, string name) onlyOwner external {
        projectNameMap[id] = name;
    }
}