 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

contract NameRegistry is Ownable {
  mapping(address => bool) registrar;

   
  event NameSet(address indexed addr, string name);
  event NameFinalized(address indexed addr, bytes32 namehash);

   
  event NameRemoved(address indexed addr, bytes32 namehash, bool forced);

   
  mapping(bytes32 => address) public namehashAddresses;

  mapping(bytes32 => bool) public namehashFinalized;

  function registerName(address addr, string name) public onlyRegistrar {
    require(bytes(name).length != 0);
    require(addr != address(0));

    bytes32 namehash = keccak256(bytes(name));
    require(namehashAddresses[namehash] == address(0));

    namehashAddresses[namehash] = addr;
    emit NameSet(addr, name);
  }

  function finalizeName(address addr, string name) public onlyRegistrar {
    require(bytes(name).length != 0);
    require(addr != address(0));

    bytes32 namehash = keccak256(bytes(name));
    require(!namehashFinalized[namehash]);

    address nameOwner = namehashAddresses[namehash];

    if (nameOwner != addr) {
      namehashAddresses[namehash] = addr;

      if (nameOwner != address(0)) {
        emit NameRemoved(nameOwner, namehash, true);
      }
      emit NameSet(addr, name);
    }

    namehashFinalized[namehash] = true;
    emit NameFinalized(addr, namehash);
  }

  function transferName(address addr, string name) public {
    require(bytes(name).length != 0);
    require(addr != address(0));

    bytes32 namehash = keccak256(bytes(name));
    require(namehashAddresses[namehash] == msg.sender);

    namehashAddresses[namehash] = addr;

    emit NameRemoved(msg.sender, namehash, false);
    emit NameSet(addr, name);
  }

  function removeName(bytes32 namehash) public {
    require(namehashAddresses[namehash] == msg.sender);
    namehashAddresses[namehash] = address(0);
    emit NameRemoved(msg.sender, namehash, false);
  }

  function addRegistrar(address addr) public onlyOwner {
    registrar[addr] = true;
  }

  function isRegistrar(address addr) public view returns(bool) {
    return registrar[addr];
  }

  function removeRegistrar(address addr) public onlyOwner {
    registrar[addr] = false;
  }

  modifier onlyRegistrar {
    require(registrar[msg.sender]);
    _;
  }
}