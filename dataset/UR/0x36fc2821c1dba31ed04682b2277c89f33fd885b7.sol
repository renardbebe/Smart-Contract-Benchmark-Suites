 

pragma solidity ^0.4.18;

 

contract LANDStorage {

  mapping (address => uint) latestPing;

  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

}

 

contract AssetRegistryStorage {

  string internal _name;
  string internal _symbol;
  string internal _description;

   
  uint256 internal _count;

   
  mapping(address => uint256[]) internal _assetsOf;

   
  mapping(uint256 => address) internal _holderOf;

   
  mapping(uint256 => uint256) internal _indexOfAsset;

   
  mapping(uint256 => string) internal _assetData;

   
  mapping(address => mapping(address => bool)) internal _operators;

   
  bool internal _reentrancy;
}

 

contract OwnableStorage {

  address public owner;

  function OwnableStorage() internal {
    owner = msg.sender;
  }

}

 

contract ProxyStorage {

   
  address currentContract;

}

 

contract Storage is ProxyStorage, OwnableStorage, AssetRegistryStorage, LANDStorage {
}

 

contract DelegateProxy {
   
  function delegatedFwd(address _dst, bytes _calldata) internal {
    require(isContract(_dst));
    assembly {
      let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

       
       
      switch result case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  function isContract(address _target) constant internal returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_target) }
    return size > 0;
  }
}

 

contract IApplication {
  function initialize(bytes data) public;
}

 

contract Proxy is ProxyStorage, DelegateProxy {

  event Upgrade(address indexed newContract, bytes initializedWith);

  function upgrade(IApplication newContract, bytes data) public {
    currentContract = newContract;
    newContract.initialize(data);

    Upgrade(newContract, data);
  }

  function () payable public {
    require(currentContract != 0);  
    delegatedFwd(currentContract, msg.data);
  }
}

 

contract LANDProxy is Storage, Proxy {
}