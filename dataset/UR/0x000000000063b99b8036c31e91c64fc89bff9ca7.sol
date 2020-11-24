 

pragma solidity 0.5.8;  


 
contract ImmutableCreate2Factory {
   
  mapping(address => bool) private _deployed;

   
  function safeCreate2(
    bytes32 salt,
    bytes calldata initializationCode
  ) external payable containsCaller(salt) returns (address deploymentAddress) {
     
    bytes memory initCode = initializationCode;

     
    address targetDeploymentAddress = address(
      uint160(                     
        uint256(                   
          keccak256(               
            abi.encodePacked(      
              hex"ff",             
              address(this),       
              salt,                
              keccak256(           
                abi.encodePacked(
                  initCode
                )
              )
            )
          )
        )
      )
    );

     
    require(
      !_deployed[targetDeploymentAddress],
      "Invalid contract creation - contract has already been deployed."
    );

     
    assembly {                                 
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      deploymentAddress := create2(            
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )
    }

     
    require(
      deploymentAddress == targetDeploymentAddress,
      "Failed to deploy contract using provided salt and initialization code."
    );

     
    _deployed[deploymentAddress] = true;
  }

   
  function findCreate2Address(
    bytes32 salt,
    bytes calldata initCode
  ) external view returns (address deploymentAddress) {
     
    deploymentAddress = address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              hex"ff",               
              address(this),         
              salt,                  
              keccak256(             
                abi.encodePacked(
                  initCode
                )
              )
            )
          )
        )
      )
    );

     
    if (_deployed[deploymentAddress]) {
      return address(0);
    }
  }

   
  function findCreate2AddressViaHash(
    bytes32 salt,
    bytes32 initCodeHash
  ) external view returns (address deploymentAddress) {
     
    deploymentAddress = address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              hex"ff",               
              address(this),         
              salt,                  
              initCodeHash           
            )
          )
        )
      )
    );

     
    if (_deployed[deploymentAddress]) {
      return address(0);
    }
  }

   
  function hasBeenDeployed(
    address deploymentAddress
  ) external view returns (bool) {
     
    return _deployed[deploymentAddress];
  }

   
  modifier containsCaller(bytes32 salt) {
     
     
    require(
      (address(bytes20(salt)) == msg.sender) ||
      (bytes20(salt) == bytes20(0)),
      "Invalid salt - first 20 bytes of the salt must match calling address."
    );
    _;
  }
}