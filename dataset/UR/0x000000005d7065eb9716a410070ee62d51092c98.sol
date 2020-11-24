 

pragma solidity 0.5.11;  


contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
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


 
contract DharmaKeyRegistryV1 is Ownable {
  using ECDSA for bytes32;

   
  address private _globalKey;

   
  mapping (address => address) private _specificKeys;

   
  constructor() public {
     
    _globalKey = tx.origin;

     
    _transferOwnership(tx.origin);
  }

   
  function setGlobalKey(
    address globalKey,
    bytes calldata signature
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

     
    _globalKey = globalKey;
  }

   
  function setSpecificKey(
    address account,
    address specificKey
  ) external onlyOwner {
     
    _specificKeys[account] = specificKey;
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
}