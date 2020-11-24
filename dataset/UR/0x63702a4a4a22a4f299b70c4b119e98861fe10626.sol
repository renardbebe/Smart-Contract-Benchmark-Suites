 

pragma solidity ^0.5.1;


 
contract GasRefundToken  {
    uint256[] public gasRefundPool;
    
    function sponsorGas() external {
        uint256 len = gasRefundPool.length;
        uint256 refundPrice = 1;
        require(refundPrice > 0);
        gasRefundPool.length = len + 9;
        gasRefundPool[len] = refundPrice;
        gasRefundPool[len + 1] = refundPrice;
        gasRefundPool[len + 2] = refundPrice;
        gasRefundPool[len + 3] = refundPrice;
        gasRefundPool[len + 4] = refundPrice;
        gasRefundPool[len + 5] = refundPrice;
        gasRefundPool[len + 6] = refundPrice;
        gasRefundPool[len + 7] = refundPrice;
        gasRefundPool[len + 8] = refundPrice;
    }
    
    function sponsorGas2() external {
        assembly {
          let len := sload(gasRefundPool_slot)
          let off := add(gasRefundPool_slot, len)
          off := add(off, 1)
          sstore(off, 1)
          off := add(off, 1)
          sstore(off, 1)
          off := add(off, 1)
          sstore(off, 1)
          sstore(gasRefundPool_slot, add(len, 3))
        }
    }
    

    function minimumGasPriceForRefund() public view returns (uint256) {
        uint256 len = gasRefundPool.length;
        if (len > 0) {
          return gasRefundPool[len - 1] + 1;
        }
        return uint256(-1);
    }

     
    function gasRefund() public {
        uint256 len = gasRefundPool.length;
        if (len > 2 && tx.gasprice > gasRefundPool[len-1]) {
            gasRefundPool[--len] = 0;
            gasRefundPool[--len] = 0;
            gasRefundPool[--len] = 0;
            gasRefundPool.length = len;
        }   
    }
    
    function gasRefund2() public {
        assembly {
            let len := sload(gasRefundPool_slot)
            if lt(len, 3) { stop() }
            let off := add(gasRefundPool_slot, len)
            let gasMin := sload(off)
            if lt(gasprice, gasMin) { stop() }
            sstore(off, 0)
            off := sub(off, 1)
            sstore(off, 0)
            off := sub(off, 1)
            sstore(off, 0)
            sstore(gasRefundPool_slot, sub(len, 3))
        }
    }
    
    function gasRefund3() public {
        uint256 len = gasRefundPool.length;
        if (len > 2 && tx.gasprice > gasRefundPool[len-1]) {
            gasRefundPool.length = len - 3;
        }  
    }
    

     
    function remainingGasRefundPool() public view returns (uint) {
        return gasRefundPool.length;
    }
    
    function remainingGasRefundPool2() public view returns (uint length) {
        assembly {
            length := sload(gasRefundPool_slot)
        }
    }

    function remainingSponsoredTransactions() public view returns (uint) {
        return gasRefundPool.length / 3;
    }
}