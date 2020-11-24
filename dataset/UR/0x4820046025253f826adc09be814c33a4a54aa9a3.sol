 

pragma solidity 0.5.11;  


 
contract UpgradeBeaconProxyV1 {
   
  address private constant _UPGRADE_BEACON = address(
    0x000000000026750c571ce882B17016557279ADaa
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
     
    (bool ok, bytes memory returnData) = _UPGRADE_BEACON.staticcall("");
    
     
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