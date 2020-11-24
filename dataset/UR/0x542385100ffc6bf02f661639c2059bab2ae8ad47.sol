 

pragma solidity ^0.5.0;
contract Proxy {
    address public a;

  
  function updateImplementation(address implementation) public {
      a = implementation;
  }

  function () payable external {
    address  _impl = a;
    require(_impl != address(0));
    

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}