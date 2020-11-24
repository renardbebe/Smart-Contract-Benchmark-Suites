 

pragma solidity ^0.4.18;

 

contract LANDStorage {

  mapping (address => uint) latestPing;

  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  mapping (address => bool) authorizedDeploy;

}

 

contract OwnableStorage {

  address public owner;

  function OwnableStorage() internal {
    owner = msg.sender;
  }

}

 

contract ProxyStorage {

   
  address public currentContract;
  address public proxyOwner;
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

 

contract Ownable is Storage {

  event OwnerUpdate(address _prevOwner, address _newOwner);

  function bytesToAddress (bytes b) pure public returns (address) {
    uint result = 0;
    for (uint i = b.length-1; i+1 > 0; i--) {
      uint c = uint(b[i]);
      uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
      result += to_inc;
    }
    return address(result);
  }

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  function initialize(bytes data) public {
    owner = bytesToAddress(data);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner);
    owner = _newOwner;
  }
}

 

contract Proxy is Storage, DelegateProxy {

  event Upgrade(address indexed newContract, bytes initializedWith);
  event OwnerUpdate(address _prevOwner, address _newOwner);

  function Proxy() public {
    proxyOwner = msg.sender;
  }

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyProxyOwner {
    require(_newOwner != proxyOwner);

    OwnerUpdate(proxyOwner, _newOwner);
    proxyOwner = _newOwner;
  }

  function upgrade(IApplication newContract, bytes data) public onlyProxyOwner {
    currentContract = newContract;
    IApplication(this).initialize(data);

    Upgrade(newContract, data);
  }

  function () payable public {
    require(currentContract != 0);  
    delegatedFwd(currentContract, msg.data);
  }
}

 

contract LANDProxy is Storage, Proxy {
}