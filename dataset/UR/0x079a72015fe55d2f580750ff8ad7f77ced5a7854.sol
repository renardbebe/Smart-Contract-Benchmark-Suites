 

 
 

pragma solidity >=0.5.0 <0.6.0;

 
contract Proxy {
    constructor(bytes memory constructData, address contractLogic) public {
         
        assembly {  
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }

        if (constructData.length == 0) {
            return;
        }

        (bool success, bytes memory _) = contractLogic.delegatecall(constructData);  
        require(success, "Construction failed");
    }

     
    function implementation() public view returns (address) {
        address contractLogic;
        assembly {  
           contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
        }
        return contractLogic;
    }

     
    function() external payable {
        assembly {  
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize)
            let success := delegatecall(sub(gas, 10000), contractLogic, 0x0, calldatasize, 0, 0)
            let retSz := returndatasize
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

     
    function proxyType() public pure returns (uint256) {
        return 1;
    }
}