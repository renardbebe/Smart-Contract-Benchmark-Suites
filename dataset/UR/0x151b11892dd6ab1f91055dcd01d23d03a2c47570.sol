 

pragma solidity ^0.4.18;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ServiceLocator is Ownable {

    struct Registry {
         
        address addr;
         
        uint256 updated;
         
        uint32 ttl; 
    }

    mapping (bytes32 => Registry) registry;
    mapping (address => string) ptr;

     
    event Set(string namespace, address registryAddr, uint32 ttl);
    event Remove(string namespace);

     
    function get(string _namespace) constant public returns (address) {
        Registry storage r = registry[keccak256(_namespace)];
        
        if (r.ttl > 0 && r.updated + r.ttl < now) {
            return address(0);
        }
        return r.addr;
    }

     
    function getNamespace(address _addr) constant public returns (string) {
        string storage ns = ptr[_addr];

        Registry storage r = registry[keccak256(ns)];
        if (r.ttl > 0 && r.updated + r.ttl < now) {
            return "";
        }
        return ns;
    }

     
    function set(string _namespace, address _addr, uint32 _ttl) onlyOwner public {
        require(isContract(_addr));

        registry[keccak256(_namespace)] = Registry({
            addr: _addr,
            updated: now,
            ttl: _ttl
        });

         
        ptr[_addr] = _namespace;
        
        Set(_namespace, _addr, _ttl);
    }

     
    function remove(string _namespace) onlyOwner public {
        bytes32 h = keccak256(_namespace);

        delete ptr[ registry[h].addr ];
        delete registry[ h ];
        
        Remove(_namespace);
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}