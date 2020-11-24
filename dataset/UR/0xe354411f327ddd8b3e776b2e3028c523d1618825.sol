 

pragma solidity 0.5.7;
contract WethDeposit {
  
  constructor() public  {
    
    uint256[3] memory transfer_in_mem;
    assembly {
      mstore(transfer_in_mem,   0x095ea7b300000000000000000000000000000000000000000000000000000000)
      mstore(add(transfer_in_mem, 4), 0x84f6451efe944ba67bedb8e0cf996fa1feb4031d)
      mstore(add(transfer_in_mem, 36), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      {
        let success := call(gas, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0, transfer_in_mem, 68, 0, 0)
        if iszero(success) {
          mstore(32, 1)
          revert(63, 1)
        }
      }
    }
  }
  
  function deposit(uint64 user_id, uint32 exchange_id) public payable  {
    
    uint256[5] memory transfer_in_mem;
    
    uint256[1] memory transfer_out_mem;
    assembly {
      if mod(callvalue, 10000000000) {
        mstore(32, 1)
        revert(63, 1)
      }
      mstore(transfer_in_mem,   0xd0e30db000000000000000000000000000000000000000000000000000000000)
      {
        let success := call(gas, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, callvalue, transfer_in_mem, 4, transfer_out_mem, 0)
        if iszero(success) {
          mstore(32, 2)
          revert(63, 1)
        }
      }
      mstore(transfer_in_mem,   0x054060bb00000000000000000000000000000000000000000000000000000000)
      mstore(add(transfer_in_mem, 4), user_id)
      mstore(add(transfer_in_mem, 36), exchange_id)
      mstore(add(transfer_in_mem, 68), 0)
      mstore(add(transfer_in_mem, 100), div(callvalue, 10000000000))
      {
        let success := call(gas, 0x84f6451efe944ba67bedb8e0cf996fa1feb4031d, 0, transfer_in_mem, 132, transfer_out_mem, 0)
        if iszero(success) {
          mstore(32, 3)
          revert(63, 1)
        }
      }
    }
  }
}