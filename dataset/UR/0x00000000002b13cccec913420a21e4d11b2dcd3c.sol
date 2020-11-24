 

pragma solidity 0.5.6;


 
contract Metapod {
   
  event Metamorphosed(address metamorphicContract, bytes32 salt);

   
  event Cocooned(address metamorphicContract, bytes32 salt);

   
   
  bytes private constant TRANSIENT_CONTRACT_INITIALIZATION_CODE = (
    hex"58601c59585992335a6357b9f5235952fa5060403031813d03839281943ef08015602557ff5b80fd"
  );

   
  bytes32 private constant TRANSIENT_CONTRACT_INITIALIZATION_CODE_HASH = bytes32(
    0xb7d11e258d6663925ce8e43f07ba3b7792a573ecc2fd7682d01f8a70b2223294
  );

   
  bytes32 private constant EMPTY_DATA_HASH = bytes32(
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
  );

   
  bytes private _initCode;

  constructor() public {
     
     
     
     
     
    require(
      address(this) == address(0x00000000002B13cCcEC913420A21e4D11b2DCd3C),
      "Incorrect deployment address."
    );

     
    require(
      keccak256(
        abi.encodePacked(TRANSIENT_CONTRACT_INITIALIZATION_CODE)
      ) == TRANSIENT_CONTRACT_INITIALIZATION_CODE_HASH,
      "Incorrect hash for transient initialization code."
    );

     
    require(
      keccak256(abi.encodePacked(hex"")) == EMPTY_DATA_HASH,
      "Incorrect hash for empty data."
    );
  }

   
  function deploy(
    uint96 identifier,
    bytes calldata initializationCode
  ) external payable returns (address metamorphicContract) {
     
    bytes32 salt = _getSalt(identifier);

     
    _initCode = initializationCode;

     
    address vaultContract = _triggerVaultFundsRelease(salt);

     
    address transientContract;

     
    bytes memory initCode = TRANSIENT_CONTRACT_INITIALIZATION_CODE;

     
    assembly {  
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      transientContract := create2(            
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )
    }  

     
    require(transientContract != address(0), "Failed to deploy contract.");

     
    metamorphicContract = _getMetamorphicContractAddress(transientContract);

     
    _verifyPrelude(metamorphicContract, _getPrelude(vaultContract));

     
    delete _initCode;

     
    emit Metamorphosed(metamorphicContract, salt);
  }

   
  function destroy(uint96 identifier) external {
     
    bytes32 salt = _getSalt(identifier);

     
    address metamorphicContract = _getMetamorphicContractAddress(
      _getTransientContractAddress(salt)
    );

     
    metamorphicContract.call("");  

     
    emit Cocooned(metamorphicContract, salt);
  }

   
  function recover(uint96 identifier) external {
     
    bytes32 salt = _getSalt(identifier);

     
    _triggerVaultFundsRelease(salt);

     
    _initCode = abi.encodePacked(
      bytes2(0x5873),   
      msg.sender,       
      bytes13(0x905959593031856108fcf150ff)
         
    );

     
    address transientContract;

     
    bytes memory initCode = TRANSIENT_CONTRACT_INITIALIZATION_CODE;

     
    assembly {  
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      transientContract := create2(            
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )
    }  

     
    require(
      transientContract != address(0),
      "Recovery failed - ensure that the contract has been destroyed."
    );

     
    delete _initCode;
  }

   
  function getInitializationCode() external view returns (
    bytes memory initializationCode
  ) {
     
    initializationCode = _initCode;
  }

   
  function findTransientContractAddress(
    bytes32 salt
  ) external pure returns (address transientContract) {
     
    transientContract = _getTransientContractAddress(salt);
  }

   
  function findMetamorphicContractAddress(
    bytes32 salt
  ) external pure returns (address metamorphicContract) {
     
    metamorphicContract = _getMetamorphicContractAddress(
      _getTransientContractAddress(salt)
    );
  }

   
  function findVaultContractAddress(
    bytes32 salt
  ) external pure returns (address vaultContract) {
    vaultContract = _getVaultContractAddress(
      _getVaultContractInitializationCode(
        _getTransientContractAddress(salt)
      )
    );
  }

   
  function getPrelude(bytes32 salt) external pure returns (
    bytes memory prelude
  ) {
     
    prelude = _getPrelude(
      _getVaultContractAddress(
        _getVaultContractInitializationCode(
          _getTransientContractAddress(salt)
        )
      )
    );
  }  

   
  function getTransientContractInitializationCode() external pure returns (
    bytes memory transientContractInitializationCode
  ) {
     
    transientContractInitializationCode = (
      TRANSIENT_CONTRACT_INITIALIZATION_CODE
    );
  }

   
  function getTransientContractInitializationCodeHash() external pure returns (
    bytes32 transientContractInitializationCodeHash
  ) {
     
    transientContractInitializationCodeHash = (
      TRANSIENT_CONTRACT_INITIALIZATION_CODE_HASH
    );
  }

   
  function getSalt(uint96 identifier) external view returns (bytes32 salt) {
    salt = _getSalt(identifier);
  }

   
  function _getSalt(uint96 identifier) internal view returns (bytes32 salt) {
    assembly {  
      salt := or(shl(96, caller), identifier)  
    }  
  }

   
  function _getPrelude(
    address vaultContract
  ) internal pure returns (bytes memory prelude) {
    prelude = abi.encodePacked(
       
      bytes22(0x6e2b13cccec913420a21e4d11b2dcd3c3318602b5773),
      vaultContract,  
      bytes2(0xff5b)  
    );
  }

   
  function _verifyPrelude(
    address metamorphicContract,
    bytes memory prelude
  ) internal view {
     
    bytes memory runtimeHeader;

    assembly {  
       
      runtimeHeader := mload(0x40)
      mstore(0x40, add(runtimeHeader, 0x60))

       
      mstore(runtimeHeader, 44)
      extcodecopy(metamorphicContract, add(runtimeHeader, 0x20), 0, 44)
    }  

     
    require(
      keccak256(
        abi.encodePacked(prelude)
      ) == keccak256(
        abi.encodePacked(runtimeHeader)
      ),
      "Deployed runtime code does not have the required prelude."
    );
  }

   
  function _triggerVaultFundsRelease(
    bytes32 salt
  ) internal returns (address vaultContract) {
     
    address transientContract = _getTransientContractAddress(salt);

     
    bytes memory vaultContractInitCode = _getVaultContractInitializationCode(
      transientContract
    );

     
    vaultContract = _getVaultContractAddress(vaultContractInitCode);

     
    if (vaultContract.balance > 0) {
       
      bytes32 vaultContractCodeHash;

      assembly {  
        vaultContractCodeHash := extcodehash(vaultContract)
      }  

       
      if (vaultContractCodeHash == EMPTY_DATA_HASH) {
        assembly {  
          let encoded_data := add(0x20, vaultContractInitCode)  
          let encoded_size := mload(vaultContractInitCode)      
          let _ := create2(                    
            0,                                 
            encoded_data,                      
            encoded_size,                      
            0                                  
          )
        }  
       
      } else {
        vaultContract.call("");  
      }
    }
  }

   
  function _getTransientContractAddress(
    bytes32 salt
  ) internal pure returns (address transientContract) {
     
    transientContract = address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              hex"ff",               
              address(0x00000000002B13cCcEC913420A21e4D11b2DCd3C),  
              salt,                  
              TRANSIENT_CONTRACT_INITIALIZATION_CODE_HASH  
            )
          )
        )
      )
    );
  }

   
  function _getMetamorphicContractAddress(
    address transientContract
  ) internal pure returns (address metamorphicContract) {
     
    metamorphicContract = address(
      uint160(                           
        uint256(                         
          keccak256(                     
            abi.encodePacked(            
              bytes2(0xd694),            
              transientContract,         
              byte(0x01)                 
            )
          )
        )
      )
    );
  }

   
  function _getVaultContractInitializationCode(
    address transientContract
  ) internal pure returns (bytes memory vaultContractInitializationCode) {
    vaultContractInitializationCode = abi.encodePacked(
       
      bytes27(0x586e2b13cccec913420a21e4d11b2dcd3c33185857595959303173),
       
      transientContract,
       
      bytes10(0x5af160315981595939f3)
    );
  }

   
  function _getVaultContractAddress(
    bytes memory vaultContractInitializationCode
  ) internal pure returns (address vaultContract) {
     
    vaultContract = address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              byte(0xff),            
              address(0x00000000002B13cCcEC913420A21e4D11b2DCd3C),  
              bytes32(0),            
              keccak256(             
                vaultContractInitializationCode
              )
            )
          )
        )
      )
    );
  }
}