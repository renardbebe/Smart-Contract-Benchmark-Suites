 

pragma solidity ^0.4.24;

 

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = true;
  }

   
  function remove(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = false;
  }

   
  function check(Role storage _role, address _account)
    internal
    view
  {
    require(has(_role, _account));
  }

   
  function has(Role storage _role, address _account)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_account];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function _addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function _removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

contract OwnerResolver {
    ENS public ens;

    constructor(ENS _ens) public {
        ens = _ens;
    }

    function addr(bytes32 node) public view returns(address) {
        return ens.owner(node);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x3b3b57de;
    }
}

 

pragma experimental ABIEncoderV2;




 
contract OwnedRegistrar is RBAC {
    ENS public ens;
    OwnerResolver public resolver;
    mapping(uint=>mapping(address=>bool)) public registrars;  
    mapping(bytes32=>uint) public nonces;  

    event RegistrarAdded(uint id, address registrar);
    event RegistrarRemoved(uint id, address registrar);
    event Associate(bytes32 indexed node, bytes32 indexed subnode, address indexed owner);
    event Disassociate(bytes32 indexed node, bytes32 indexed subnode);

    constructor(ENS _ens) public {
        ens = _ens;
        resolver = new OwnerResolver(_ens);
        _addRole(msg.sender, "owner");
    }

    function addRole(address addr, string role) external onlyRole("owner") {
        _addRole(addr, role);
    }

    function removeRole(address addr, string role) external onlyRole("owner") {
         
        require(keccak256(abi.encode(role)) != keccak256(abi.encode("owner")) || msg.sender != addr);
        _removeRole(addr, role);
    }

    function setRegistrar(uint id, address registrar) public onlyRole("authoriser") {
        registrars[id][registrar] = true;
        emit RegistrarAdded(id, registrar);
    }

    function unsetRegistrar(uint id, address registrar) public onlyRole("authoriser") {
        registrars[id][registrar] = false;
        emit RegistrarRemoved(id, registrar);
    }

    function associateWithSig(bytes32 node, bytes32 label, address owner, uint nonce, uint registrarId, bytes32 r, bytes32 s, uint8 v) public onlyRole("transactor") {
        bytes32 subnode = keccak256(abi.encode(node, label));
        require(nonce == nonces[subnode]);
        nonces[subnode]++;

        bytes32 sighash = keccak256(abi.encode(subnode, owner, nonce));
        address registrar = ecrecover(sighash, v, r, s);
        require(registrars[registrarId][registrar]);

        ens.setSubnodeOwner(node, label, address(this));
        if(owner == 0) {
            ens.setResolver(subnode, 0);
        } else {
            ens.setResolver(subnode, resolver);
        }
        ens.setOwner(subnode, owner);

        emit Associate(node, label, owner);
    }

    function multicall(bytes[] calls) public {
        for(uint i = 0; i < calls.length; i++) {
            require(address(this).delegatecall(calls[i]));
        }
    }
}