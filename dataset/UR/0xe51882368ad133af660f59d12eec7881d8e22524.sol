 

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

  

 

contract AuthereumProxy {
    string constant public authereumProxyVersion = "2019102500";

     
     
     
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

     
     
    constructor(address _logic) public payable {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _logic)
        }
    }

     
     
     
     
    function () external payable {
        if (msg.data.length == 0) return;
        address _implementation = implementation();

        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)

             
             
            let result := delegatecall(gas, _implementation, 0, calldatasize, 0, 0)

             
            returndatacopy(0, 0, returndatasize)

            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

     
     
    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}