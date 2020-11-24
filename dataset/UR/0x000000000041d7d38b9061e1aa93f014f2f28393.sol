 

pragma solidity 0.5.11;  


 
contract CodeHashCache {
   
  mapping (address => bytes32) private _cachedHashes;

   
  function registerCodeHash(address target) external {
     
    require(_cachedHashes[target] == bytes32(0), "Target already registered.");    

     
    uint256 currentCodeSize;
    assembly { currentCodeSize := extcodesize(target) }
    require(currentCodeSize > 0, "Target currently has no runtime code.");

     
    bytes32 currentCodeHash;
    assembly { currentCodeHash := extcodehash(target) }

     
    _cachedHashes[target] = currentCodeHash;
  }

   
  function matchesRegisteredCodeHash(
    address target
  ) external view returns (bool codeHashMatchesRegisteredCodeHash) {
     
    bytes32 cachedCodeHash = _cachedHashes[target];

     
    require(cachedCodeHash != bytes32(0), "Target not yet registered.");

     
    bytes32 currentCodeHash;
    assembly { currentCodeHash := extcodehash(target) }

     
    codeHashMatchesRegisteredCodeHash = currentCodeHash == cachedCodeHash;
  }

   
  function getRegisteredCodeHash(
    address target
  ) external view returns (bytes32 registeredCodeHash) {
     
    registeredCodeHash = _cachedHashes[target];
  }
}