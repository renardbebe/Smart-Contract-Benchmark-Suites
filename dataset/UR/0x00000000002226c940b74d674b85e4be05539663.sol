 

pragma solidity 0.5.11;  


interface DharmaUpgradeBeaconEnvoyInterface {
  function getImplementation(address beacon) external view returns (address);
}


 
contract DharmaUpgradeBeaconController {
   
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  event Upgraded(
    address indexed upgradeBeacon,
    address oldImplementation,
    bytes32 oldImplementationCodeHash,
    address newImplementation,
    bytes32 newImplementationCodeHash
  );

   
  address private _owner;

   
   
   
  mapping(address => bytes32) private _codeHashAtLastUpgrade;

   
  DharmaUpgradeBeaconEnvoyInterface private constant _UPGRADE_BEACON_ENVOY = (
    DharmaUpgradeBeaconEnvoyInterface(
      0x000000000067503c398F4c9652530DBC4eA95C02
    )
  );

   
  constructor() public {
     
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), tx.origin);
    
     
    address envoy = address(_UPGRADE_BEACON_ENVOY);
    bytes32 envoyCodeHash;
    assembly { envoyCodeHash := extcodehash(envoy)}
    require(
      envoyCodeHash == bytes32(
        0x7332d06692fd32b21bdd8b8b7a0a3f0de5cf549668cbc4498fc6cfaa453f1176
      ),
      "Upgrade Beacon Envoy runtime code is incorrect."
    );
  }

   
  function upgrade(address beacon, address implementation) external onlyOwner {
     
    require(implementation != address(0), "Must specify an implementation.");

     
    uint256 implementationSize;
    assembly { implementationSize := extcodesize(implementation) }
    require(implementationSize > 0, "Implementation must have contract code.");

     
    require(beacon != address(0), "Must specify an upgrade beacon.");

     
    uint256 beaconSize;
    assembly { beaconSize := extcodesize(beacon) }
    require(beaconSize > 0, "Upgrade beacon must have contract code.");

     
    _update(beacon, implementation);
  }

   
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

   
  function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function getImplementation(
    address beacon
  ) external view returns (address implementation) {
     
    implementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);
  }

   
  function getCodeHashAtLastUpgrade(
    address beacon
  ) external view returns (bytes32 codeHashAtLastUpgrade) {
     
    codeHashAtLastUpgrade = _codeHashAtLastUpgrade[beacon];
  }

   
  function owner() external view returns (address) {
    return _owner;
  }

   
  function isOwner() external view returns (bool) {
    return msg.sender == _owner;
  }

   
  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
  }

   
  function _update(address beacon, address implementation) private {
     
    address oldImplementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);

     
    bytes32 oldImplementationCodeHash;
    assembly { oldImplementationCodeHash := extcodehash(oldImplementation) }

     
    (bool success,) = beacon.call(abi.encode(implementation));

     
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    address newImplementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);

     
    bytes32 newImplementationCodeHash;
    assembly { newImplementationCodeHash := extcodehash(newImplementation) }

     
    _codeHashAtLastUpgrade[beacon] = newImplementationCodeHash;

     
    emit Upgraded(
      beacon,
      oldImplementation,
      oldImplementationCodeHash,
      newImplementation,
      newImplementationCodeHash
    );
  }
}