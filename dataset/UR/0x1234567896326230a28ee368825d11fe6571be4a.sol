 

pragma solidity ^0.5.3;

 
 
 
 

 
interface RegistryInterface {
    function getExchangeContract() external view returns (address);
}

 
contract FixedAddress {
    address constant ProxyAddress = 0x1234567896326230a28ee368825D11fE6571Be4a;
    address constant TreasuryAddress = 0x12345678979f29eBc99E00bdc5693ddEa564cA80;
    address constant RegistryAddress = 0x12345678982cB986Dd291B50239295E3Cb10Cdf6;

    function getRegistry() internal pure returns (RegistryInterface) {
        return RegistryInterface(RegistryAddress);
    }
}

contract Proxy is FixedAddress {

  function () external payable {
       
      address _impl = getRegistry().getExchangeContract();

       
       
       
       
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