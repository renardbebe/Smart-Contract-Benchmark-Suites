 

pragma solidity 0.5.11;  


interface DharmaKeyRingFactoryV2Interface {
   
  event KeyRingDeployed(address keyRing, address userSigningKey);

  function newKeyRing(
    address userSigningKey, address targetKeyRing
  ) external returns (address keyRing);

  function newKeyRingAndAdditionalKey(
    address userSigningKey,
    address targetKeyRing,
    address additionalSigningKey,
    bytes calldata signature
  ) external returns (address keyRing);

  function newKeyRingAndDaiWithdrawal(
    address userSigningKey,
    address targetKeyRing,
    address smartWallet,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (address keyRing, bool withdrawalSuccess);

  function newKeyRingAndUSDCWithdrawal(
    address userSigningKey,
    address targetKeyRing,
    address smartWallet,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (address keyRing, bool withdrawalSuccess);

  function getNextKeyRing(
    address userSigningKey
  ) external view returns (address targetKeyRing);

  function getFirstKeyRingAdminActionID(
    address keyRing, address additionalUserSigningKey
  ) external view returns (bytes32 adminActionID);
}


interface DharmaKeyRingImplementationV0Interface {
  enum AdminActionType {
    AddStandardKey,
    RemoveStandardKey,
    SetStandardThreshold,
    AddAdminKey,
    RemoveAdminKey,
    SetAdminThreshold,
    AddDualKey,
    RemoveDualKey,
    SetDualThreshold
  }

  function takeAdminAction(
    AdminActionType adminActionType, uint160 argument, bytes calldata signatures
  ) external;

  function getVersion() external view returns (uint256 version);
}


interface DharmaSmartWalletImplementationV0Interface {
  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);
}


interface DharmaKeyRingInitializer {
  function initialize(
    uint128 adminThreshold,
    uint128 executorThreshold,
    address[] calldata keys,
    uint8[] calldata keyTypes
  ) external;
}


 
contract KeyRingUpgradeBeaconProxyV1 {
   
  address private constant _KEY_RING_UPGRADE_BEACON = address(
    0x0000000000BDA2152794ac8c76B2dc86cbA57cad
  );

   
  constructor(bytes memory initializationCalldata) public payable {
     
    (bool ok, ) = _implementation().delegatecall(initializationCalldata);
    
     
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

   
  function () external payable {
     
    _delegate(_implementation());
  }

   
  function _implementation() private view returns (address implementation) {
     
    (bool ok, bytes memory returnData) = _KEY_RING_UPGRADE_BEACON.staticcall("");
    
     
    require(ok, string(returnData));

     
    implementation = abi.decode(returnData, (address));
  }

   
  function _delegate(address implementation) private {
    assembly {
       
       
       
      calldatacopy(0, 0, calldatasize)

       
       
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

       
      returndatacopy(0, 0, returndatasize)

      switch result
       
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }
}


 
contract DharmaKeyRingFactoryV2 is DharmaKeyRingFactoryV2Interface {
   
  bytes4 private constant _INITIALIZE_SELECTOR = bytes4(0x30fc201f);

   
  address private constant _KEY_RING_UPGRADE_BEACON = address(
    0x0000000000BDA2152794ac8c76B2dc86cbA57cad
  );

   
  constructor() public {
    DharmaKeyRingInitializer initializer;
    require(
      initializer.initialize.selector == _INITIALIZE_SELECTOR,
      "Incorrect initializer selector supplied."
    );
  }

   
  function newKeyRing(
    address userSigningKey, address targetKeyRing
  ) external returns (address keyRing) {
     
    keyRing = _deployNewKeyRingIfNeeded(userSigningKey, targetKeyRing);
  }

   
  function newKeyRingAndAdditionalKey(
    address userSigningKey,
    address targetKeyRing,
    address additionalSigningKey,
    bytes calldata signature
  ) external returns (address keyRing) {
     
    keyRing = _deployNewKeyRingIfNeeded(userSigningKey, targetKeyRing);

     
    DharmaKeyRingImplementationV0Interface(keyRing).takeAdminAction(
      DharmaKeyRingImplementationV0Interface.AdminActionType.AddDualKey,
      uint160(additionalSigningKey),
      signature
    );
  }

   
  function newKeyRingAndDaiWithdrawal(
    address userSigningKey,
    address targetKeyRing,
    address smartWallet,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (address keyRing, bool withdrawalSuccess) {
     
    keyRing = _deployNewKeyRingIfNeeded(userSigningKey, targetKeyRing);

     
    withdrawalSuccess = DharmaSmartWalletImplementationV0Interface(
      smartWallet
    ).withdrawDai(
      amount, recipient, minimumActionGas, userSignature, dharmaSignature
    );
  }

   
  function newKeyRingAndUSDCWithdrawal(
    address userSigningKey,
    address targetKeyRing,
    address smartWallet,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (address keyRing, bool withdrawalSuccess) {
     
    keyRing = _deployNewKeyRingIfNeeded(userSigningKey, targetKeyRing);

     
    withdrawalSuccess = DharmaSmartWalletImplementationV0Interface(
      smartWallet
    ).withdrawUSDC(
      amount, recipient, minimumActionGas, userSignature, dharmaSignature
    );
  }

   
  function getNextKeyRing(
    address userSigningKey
  ) external view returns (address targetKeyRing) {
     
    require(userSigningKey != address(0), "No user signing key supplied.");

     
    bytes memory initializationCalldata = _constructInitializationCalldata(
      userSigningKey
    );

     
    targetKeyRing = _computeNextAddress(initializationCalldata);
  }

   
  function getFirstKeyRingAdminActionID(
    address keyRing, address additionalUserSigningKey
  ) external view returns (bytes32 adminActionID) {
    adminActionID = keccak256(
      abi.encodePacked(
        keyRing, _getKeyRingVersion(), uint256(0), additionalUserSigningKey
      )
    );
  }

   
  function _deployNewKeyRingIfNeeded(
    address userSigningKey, address expectedKeyRing
  ) internal returns (address keyRing) {
     
    uint256 size;
    assembly { size := extcodesize(expectedKeyRing) }
    if (size == 0) {
       
      bytes memory initializationCalldata = _constructInitializationCalldata(
        userSigningKey
      );

       
      keyRing = _deployUpgradeBeaconProxyInstance(initializationCalldata);

       
      emit KeyRingDeployed(keyRing, userSigningKey);
    } else {
       
       
       
       
       
       
      keyRing = expectedKeyRing;
    }
  }

   
  function _deployUpgradeBeaconProxyInstance(
    bytes memory initializationCalldata
  ) private returns (address upgradeBeaconProxyInstance) {
     
    bytes memory initCode = abi.encodePacked(
      type(KeyRingUpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );

     
    (uint256 salt, ) = _getSaltAndTarget(initCode);

     
    assembly {
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      upgradeBeaconProxyInstance := create2(   
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )

       
      if iszero(upgradeBeaconProxyInstance) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

  function _constructInitializationCalldata(
    address userSigningKey
  ) private pure returns (bytes memory initializationCalldata) {
    address[] memory keys = new address[](1);
    keys[0] = userSigningKey;

    uint8[] memory keyTypes = new uint8[](1);
    keyTypes[0] = uint8(3);  

     
    initializationCalldata = abi.encodeWithSelector(
      _INITIALIZE_SELECTOR, 1, 1, keys, keyTypes
    );
  }

   
  function _computeNextAddress(
    bytes memory initializationCalldata
  ) private view returns (address target) {
     
    bytes memory initCode = abi.encodePacked(
      type(KeyRingUpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );

     
    (, target) = _getSaltAndTarget(initCode);
  }

   
  function _getSaltAndTarget(
    bytes memory initCode
  ) private view returns (uint256 nonce, address target) {
     
    bytes32 initCodeHash = keccak256(initCode);

     
    nonce = 0;

     
    uint256 codeSize;

     
    while (true) {
      target = address(             
        uint160(                    
          uint256(                  
            keccak256(              
              abi.encodePacked(     
                bytes1(0xff),       
                address(this),      
                nonce,               
                initCodeHash        
              )
            )
          )
        )
      );

       
      assembly { codeSize := extcodesize(target) }

       
      if (codeSize == 0) {
        break;
      }

       
      nonce++;
    }
  }

   
  function _getKeyRingVersion() private view returns (uint256 version) {
     
    (bool ok, bytes memory data) = _KEY_RING_UPGRADE_BEACON.staticcall("");

     
    require(ok, string(data));

     
    require(data.length == 32, "Return data must be exactly 32 bytes.");

     
    address implementation = abi.decode(data, (address));

     
    version = DharmaKeyRingImplementationV0Interface(
      implementation
    ).getVersion();
  }
}