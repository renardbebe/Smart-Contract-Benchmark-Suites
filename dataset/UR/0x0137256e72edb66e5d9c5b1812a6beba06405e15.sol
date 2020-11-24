 

pragma solidity ^0.5.2;

  
contract Pausable {
  event Pause();
  event Unpause();

  bool public paused = false;
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}


 
contract UpgradeabilityProxy {
   
  bytes32 private constant IMPLEMENTATION_SLOT = 0xbe2c1a60709d4c60c413b72a0999dd04a683092d060b4c9def249fa6bc842b2d;

   
  constructor(address _implementation) public {
    assert(IMPLEMENTATION_SLOT == keccak256("www.invault.io.proxy.implementation"));
    _setImplementation(_implementation);
  }

   
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

   
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
  }

   
  function _setImplementation(address newImplementation) private {
    require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


 
contract IVTProxy is UpgradeabilityProxy, Pausable {

   
  bytes32 private constant PERM_SLOT = 0x9f2b05956adf3f5dc678f8c50dd9693f2163f4bec0d0b84a13327b894102a4e5;

   
  modifier OnlyPermission() {
    require(msg.sender == _perm());
      _;
  }

   
  constructor(address _implementation, address _permission) UpgradeabilityProxy(_implementation) public {
    assert(PERM_SLOT == keccak256("www.invault.io.proxy.permission"));
    _setPermission(_permission);
  }

   
  function getPermAddress() external view whenNotPaused returns (address) {
    return _perm();
  }

   
  function getImplAddress() external view whenNotPaused returns (address) {
    return _implementation();
  }

   
  function upgradeImpl(address newImplementation) external OnlyPermission whenNotPaused returns(bool) {
    _upgradeTo(newImplementation);
    return true;
  }



   
  function upgradePerm(address newPermission) external OnlyPermission whenNotPaused returns(bool)  {
    _setPermission(newPermission);
    return true;
  }


 
  function requestUpgrade(bytes calldata _data) external onlyOwner whenNotPaused {
     address permission = _perm();
     permission.call(_data);

  }

   
  function _perm() internal view returns (address adm) {
    bytes32 slot = PERM_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

   
  function _setPermission(address newPerm) internal {

    require(AddressUtils.isContract(newPerm), "Cannot set a proxy permission to a non-contract address");

    bytes32 slot = PERM_SLOT;

    assembly {
      sstore(slot, newPerm)
    }
  }

}