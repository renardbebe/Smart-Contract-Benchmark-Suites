 

pragma solidity 0.5.11;  


interface DharmaKeyRegistryInterface {
  event NewGlobalKey(address oldGlobalKey, address newGlobalKey);
  event NewSpecificKey(
    address indexed account, address oldSpecificKey, address newSpecificKey
  );

  function setGlobalKey(address globalKey, bytes calldata signature) external;
  function setSpecificKey(address account, address specificKey) external;
  function getKey() external view returns (address key);
  function getKeyForUser(address account) external view returns (address key);
  function getGlobalKey() external view returns (address globalKey);
  function getSpecificKey(address account) external view returns (address specificKey);
}


library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


 
contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

   
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

   
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


 
contract DharmaKeyRegistryV2 is TwoStepOwnable, DharmaKeyRegistryInterface {
  using ECDSA for bytes32;

   
  address private _globalKey;

   
  mapping (address => address) private _specificKeys;

   
  mapping (address => bool) private _usedKeys;

   
  constructor() public {
     
    _registerGlobalKey(tx.origin);
  }

   
  function setGlobalKey(
    address globalKey, bytes calldata signature
  ) external onlyOwner {
     
    require(globalKey != address(0), "A global key must be supplied.");

     
    bytes32 messageHash = keccak256(
      abi.encodePacked(
        address(this),
        globalKey,
        "This signature demonstrates that the supplied signing key is valid."
      )
    );

     
    address signer = messageHash.toEthSignedMessageHash().recover(signature);

     
    require(globalKey == signer, "Invalid signature for supplied global key.");

     
    _registerGlobalKey(globalKey);
  }

   
  function setSpecificKey(
    address account, address specificKey
  ) external onlyOwner {
     
    require(!_usedKeys[specificKey], "Key has been used previously.");

     
    emit NewSpecificKey(account, _specificKeys[account], specificKey);

     
    _specificKeys[account] = specificKey;

     
    _usedKeys[specificKey] = true;
  }

   
  function getKey() external view returns (address key) {
     
    key = _specificKeys[msg.sender];

     
    if (key == address(0)) {
      key = _globalKey;
    }
  }

   
  function getKeyForUser(address account) external view returns (address key) {
     
    key = _specificKeys[account];

     
    if (key == address(0)) {
      key = _globalKey;
    }
  }

   
  function getGlobalKey() external view returns (address globalKey) {
     
    globalKey = _globalKey;
  }

   
  function getSpecificKey(
    address account
  ) external view returns (address specificKey) {
     
    specificKey = _specificKeys[account];

     
    require(
      specificKey != address(0),
      "No specific key set for the provided account."
    );
  }

   
  function _registerGlobalKey(address globalKey) internal {
     
    require(!_usedKeys[globalKey], "Key has been used previously.");

     
    emit NewGlobalKey(_globalKey, globalKey);

     
    _globalKey = globalKey;

     
    _usedKeys[globalKey] = true;
  }
}