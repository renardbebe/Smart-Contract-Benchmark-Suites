 

pragma solidity 0.5.11;  


 
contract IndestructibleRegistry {
   
  mapping (address => bool) private _definitelyIndestructible;

   
  function registerAsIndestructible(address target) external {
     
    require(
      !_isPotentiallyDestructible(target),
      "Supplied target is potentially destructible."
    );

     
    _definitelyIndestructible[target] = true;
  }

   
  function isRegisteredAsIndestructible(
    address target
  ) external view returns (bool registeredAsIndestructible) {
    registeredAsIndestructible = _definitelyIndestructible[target];
  }

   
  function isPotentiallyDestructible(
    address target
  ) external view returns (bool potentiallyDestructible) {
    potentiallyDestructible = _isPotentiallyDestructible(target);
  }

   
  function _isPotentiallyDestructible(
    address target
  ) internal view returns (bool potentiallyDestructible) {
     
    uint256 size;
    assembly { size := extcodesize(target) }
    require(size > 0, "No code at target.");
    
     
    uint256 dataStart;
    bytes memory extcode = new bytes(size);
    assembly {
      dataStart := add(extcode, 0x20)
      extcodecopy(target, dataStart, 0, size)
    }
    uint256 dataEnd = dataStart + size;
    require (dataEnd > dataStart, "SafeMath: addition overflow.");
    
     
    bool reachable = true;
    uint256 op;
    for (uint256 i = dataStart; i < dataEnd; i++) {
       
      assembly { op := shr(0xf8, mload(i)) }
      
       
      if (reachable) {
         
        if (
          op == 254 ||  
          op == 243 ||  
          op == 253 ||  
          op == 86  ||  
          op == 0       
        ) {
          reachable = false;
          continue;
        }

         
        if (op > 95 && op < 128) {  
          i += (op - 95);
          continue;
        }
        
         
        if (
          op == 242 ||  
          op == 244 ||  
          op == 255     
        ) {
          return true;  
        }
      } else if (op == 91) {  
         
        reachable = true;
      }
    }
  }
}