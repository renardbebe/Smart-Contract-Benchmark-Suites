 

pragma solidity ^0.5.7;
contract MarginSwap {
  uint256 _owner;
  uint256 _parent_address;
  uint256 _comptroller_address;
  uint256 _cEther_address;
  uint256[2**160] _compound_lookup;
  event Trade(
    address indexed trade_contract,
    address from_asset,
    address to_asset,
    uint256 input,
    uint256 output,
    uint256 input_fee
  );
  
  constructor(address owner, address parent_address, address comptroller_address, address cEther_address) public  {
    assembly {
      sstore(_owner_slot, owner)
      sstore(_parent_address_slot, parent_address)
      sstore(_comptroller_address_slot, comptroller_address)
      sstore(_cEther_address_slot, cEther_address)
      sstore(_trade_running_slot, 1)
    }
  }
  
  function () external payable  {}
  
  function lookupUnderlying(address cToken) public view 
  returns (address result) {
    assembly {
      result := sload(add(_compound_lookup_slot, cToken))
    }
  }
  
  function enterMarkets(address[] calldata cTokens) external  {
    assembly {
      if xor(caller, sload(_owner_slot)) {
        mstore(32, 0)
        revert(63, 1)
      }
      if xor(0x20, calldataload(4)) {
        mstore(32, 1)
        revert(63, 1)
      }
      let array_length := calldataload(0x24)
      let array_start := 0x44
      if xor(add(0x44, mul(0x20, array_length)), calldatasize) {
        mstore(32, 2)
        revert(63, 1)
      }
      {
        let call_input := mload(0x40)
        let call_input_size := calldatasize
        calldatacopy(call_input, 0, call_input_size)
        let res := call(gas, sload(_comptroller_address_slot), 0, call_input, call_input_size, call_input, sub(call_input_size, 4))
        if iszero(res) {
          mstore(32, 3)
          revert(63, 1)
        }
        if xor(0x20, mload(call_input)) {
          mstore(32, 4)
          revert(63, 1)
        }
        if xor(array_length, mload(add(call_input, 0x20))) {
          mstore(32, 5)
          revert(63, 1)
        }
        let has_error := 0
        for {
          let i := 0
        } lt(i, array_length) {
          i := add(i, 1)
        } {
          let value := mload(add(add(call_input, 0x40), mul(i, 0x20)))
          has_error := or(has_error, value)
        }
        if has_error {
          mstore(32, 6)
          revert(63, 1)
        }
      }
      let cEther_addr := sload(_cEther_address_slot)
      let array_end := add(array_start, mul(array_length, 0x20))
      for {
        let i := array_start
      } lt(i, array_end) {
        i := add(i, 0x20)
      } {
        let cToken_addr := calldataload(i)
        let mem_ptr := mload(0x40)
        let m_out := add(mem_ptr, 4)
        {
          mstore(m_out, 0)
          if xor(cToken_addr, cEther_addr) {
            mstore(mem_ptr,   0x6f307dc300000000000000000000000000000000000000000000000000000000)
            let res := staticcall(gas, cToken_addr, mem_ptr, 4, m_out, 32)
            if iszero(res) {
              mstore(32, 7)
              revert(63, 1)
            }
          }
        }
        let underlying_addr := mload(m_out)
        sstore(add(_compound_lookup_slot, underlying_addr), cToken_addr)
        if underlying_addr {
          mstore(mem_ptr,   0x095ea7b300000000000000000000000000000000000000000000000000000000)
          mstore(add(mem_ptr, 4), cToken_addr)
          mstore(add(mem_ptr, 0x24), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
          let mem_out := add(mem_ptr, 0x44)
          mstore(mem_out, 0)
          let res := call(gas, underlying_addr, 0, mem_ptr, 0x44, mem_out, 0x20)
          if or(iszero(res), iszero(mload(mem_out))) {
            mstore(32, 8)
            revert(63, 1)
          }
        }
      }
    }
  }
  
  function depositEth() external payable  {
    deposit(address(0x0), msg.value);
  }
  
  function deposit(address asset_address, uint256 amount) public payable  {
    
    uint256[4] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      if and(iszero(asset_address), xor(amount, callvalue)) {
        mstore(32, 1)
        revert(63, 1)
      }
      if asset_address {
        if callvalue {
          mstore(32, 2)
          revert(63, 1)
        }
        mstore(m_in,   0x23b872dd00000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), caller)
        mstore(add(m_in, 0x24), address)
        mstore(add(m_in, 0x44), amount)
        mstore(m_out, 0)
        let res := call(gas, asset_address, 0, m_in, 0x64, m_out, 0x20)
        if or(iszero(res), iszero(mload(m_out))) {
          mstore(32, 3)
          revert(63, 1)
        }
      }
    }
    depositToCompound(asset_address, amount);
  }
  
  function depositToCompound(address asset_address, uint256 amount) internal  {
    
    uint256[2] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      let c_address := sload(add(_compound_lookup_slot, asset_address))
      if iszero(c_address) {
        mstore(32, 100)
        revert(63, 1)
      }
      {
        mstore(m_in,   0x17bfdfbc00000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), address)
        let res := call(gas, c_address, 0, m_in, 36, m_out, 32)
        if iszero(res) {
          mstore(32, 101)
          revert(63, 1)
        }
      }
      let cEther_addr := sload(_cEther_address_slot)
      {
        let borrow_amount := mload(m_out)
        let to_repay := borrow_amount
        if lt(amount, to_repay) {
          to_repay := amount
        }
        if to_repay {
          mstore(m_in,   0x4e4d9fea00000000000000000000000000000000000000000000000000000000)
          let m_in_size := 4
          let wei_to_send := to_repay
          if xor(c_address, cEther_addr) {
            mstore(m_in,   0x0e75270200000000000000000000000000000000000000000000000000000000)
            mstore(add(m_in, 4), to_repay)
            m_in_size := 36
            wei_to_send := 0
          }
          let res := call(gas, c_address, wei_to_send, m_in, m_in_size, m_out, 32)
          if iszero(res) {
            mstore(32, 102)
            revert(63, 1)
          }
          switch returndatasize
            case 0 {
              if xor(c_address, cEther_addr) {
                mstore(32, 103)
                revert(63, 1)
              }
            }
            case 32 {
              if mload(m_out) {
                mstore(32, 104)
                revert(63, 1)
              }
            }
            default {
              mstore(32, 105)
              revert(63, 1)
            }
          amount := sub(amount, to_repay)
        }
      }
      {
        if amount {
          mstore(m_in,   0x1249c58b00000000000000000000000000000000000000000000000000000000)
          let m_in_size := 4
          let wei_to_send := amount
          if xor(c_address, cEther_addr) {
            mstore(m_in,   0xa0712d6800000000000000000000000000000000000000000000000000000000)
            mstore(add(m_in, 4), amount)
            m_in_size := 36
            wei_to_send := 0
          }
          let res := call(gas, c_address, wei_to_send, m_in, m_in_size, m_out, 32)
          if iszero(res) {
            mstore(32, 106)
            revert(63, 1)
          }
          switch returndatasize
            case 0 {
              if xor(c_address, cEther_addr) {
                mstore(32, 107)
                revert(63, 1)
              }
            }
            case 32 {
              if mload(m_out) {
                mstore(32, 108)
                revert(63, 1)
              }
            }
            default {
              mstore(32, 109)
              revert(63, 1)
            }
        }
      }
    }
  }
  
  function withdraw(address asset, uint256 amount, address destination) external  {
    assembly {
      if xor(caller, sload(_owner_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
    }
    _withdraw(asset, amount, destination);
  }
  
  function _withdraw(address asset, uint256 amount, address destination) internal  {
    
    uint256[2] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      let c_address := sload(add(_compound_lookup_slot, asset))
      if iszero(c_address) {
        mstore(32, 200)
        revert(63, 1)
      }
      let remaining := amount
      {
        mstore(m_in,   0x3af9e66900000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), address)
        let res := call(gas, c_address, 0, m_in, 36, m_out, 32)
        if iszero(res) {
          mstore(32, 201)
          revert(63, 1)
        }
      }
      {
        let available := mload(m_out)
        let to_redeem := available
        if lt(remaining, to_redeem) {
          to_redeem := remaining
        }
        if to_redeem {
          mstore(m_in,   0x852a12e300000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), to_redeem)
          let res := call(gas, c_address, 0, m_in, 36, m_out, 32)
          if iszero(res) {
            mstore(32, 202)
            revert(63, 1)
          }
          if mload(m_out) {
            mstore(32, 203)
            revert(63, 1)
          }
          remaining := sub(remaining, to_redeem)
        }
      }
      {
        if remaining {
          mstore(m_in,   0xc5ebeaec00000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), remaining)
          let res := call(gas, c_address, 0, m_in, 36, m_out, 32)
          if or(iszero(res), mload(m_out)) {
            mstore(32, 204)
            revert(63, 1)
          }
        }
      }
      {
        let m_in_size := 0
        let wei_to_send := amount
        let dest := destination
        if asset {
          mstore(m_in,   0xa9059cbb00000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), destination)
          mstore(add(m_in, 0x24), amount)
          dest := asset
          m_in_size := 0x44
          wei_to_send := 0
        }
        let res := call(gas, dest, wei_to_send, m_in, m_in_size, m_out, 32)
        if iszero(res) {
          mstore(32, 205)
          revert(63, 1)
        }
        if asset {
          if iszero(mload(m_out)) {
            mstore(32, 206)
            revert(63, 1)
          }
        }
      }
    }
  }
  
  function transferOut(address asset, uint256 amount, address destination) external  {
    
    uint256[3] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      if xor(caller, sload(_owner_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      let m_in_size := 0
      let wei_to_send := amount
      let dest := destination
      if asset {
        mstore(m_in,   0xa9059cbb00000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), destination)
        mstore(add(m_in, 0x24), amount)
        dest := asset
        m_in_size := 0x44
        wei_to_send := 0
      }
      let res := call(gas, dest, wei_to_send, m_in, m_in_size, m_out, 32)
      if iszero(res) {
        mstore(32, 2)
        revert(63, 1)
      }
      if asset {
        if iszero(mload(m_out)) {
          mstore(32, 3)
          revert(63, 1)
        }
      }
    }
  }
  uint256 _trade_running;
  
  function trade(address input_asset,
                 uint256 input_amount,
                 address output_asset,
                 uint256 min_output_amount,
                 address trade_contract,
                 bytes memory trade_data) public payable  {
    
    uint256[3] memory m_in;
    
    uint256[1] memory m_out;
    uint256 output_amount;
    assembly {
      if xor(caller, sload(_owner_slot)) {
        mstore(32, 0)
        revert(63, 1)
      }
      {
        if eq(sload(_trade_running_slot), 2) {
          mstore(32, 1)
          revert(63, 1)
        }
        sstore(_trade_running_slot, 2)
      }
      let capital_source := sload(_parent_address_slot)
      {
        mstore(m_in,   0x0a681c5900000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 0x04), input_asset)
        mstore(add(m_in, 0x24), input_amount)
        let res := call(gas, capital_source, 0, m_in, 0x44, 0, 0)
        if iszero(res) {
          mstore(32, 2)
          revert(63, 1)
        }
      }
      if input_asset {
        if callvalue {
          mstore(32, 3)
          revert(63, 1)
        }
        {
          mstore(m_in,   0x095ea7b300000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), trade_contract)
          mstore(add(m_in, 0x24), input_amount)
          mstore(m_out, 0)
          let res := call(gas, input_asset, 0, m_in, 0x44, m_out, 0x20)
          if or(iszero(res), iszero(mload(m_out))) {
            mstore(32, 4)
            revert(63, 1)
          }
        }
      }
      let before_balance := balance(address)
      if output_asset {
        {
          mstore(m_in,   0x70a0823100000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), caller)
          mstore(m_out, 0)
          let res := staticcall(gas, output_asset, m_in, 0x24, m_out, 0x20)
          if iszero(res) {
            mstore(32, 5)
            revert(63, 1)
          }
        }
        before_balance := mload(m_out)
      }
      {
        if iszero(extcodesize(trade_contract)) {
          mstore(32, 5)
          revert(63, 1)
        }
        let res := call(gas, trade_contract, callvalue, add(trade_data, 0x20), mload(trade_data), 0, 0)
        if iszero(res) {
          mstore(32, 7)
          revert(63, 1)
        }
      }
      {
        mstore(m_in,   0x095ea7b300000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), trade_contract)
        mstore(add(m_in, 0x24), 0)
        mstore(m_out, 0)
        let res := call(gas, input_asset, 0, m_in, 0x44, m_out, 0x20)
        if or(iszero(res), iszero(mload(m_out))) {
          mstore(32, 8)
          revert(63, 1)
        }
      }
      let after_balance := balance(address)
      if output_asset {
        {
          mstore(m_in,   0x70a0823100000000000000000000000000000000000000000000000000000000)
          mstore(add(m_in, 4), caller)
          mstore(m_out, 0)
          let res := staticcall(gas, output_asset, m_in, 0x24, m_out, 0x20)
          if iszero(res) {
            mstore(32, 9)
            revert(63, 1)
          }
        }
        after_balance := mload(m_out)
      }
      if lt(after_balance, before_balance) {
        mstore(32, 10)
        revert(63, 1)
      }
      output_amount := sub(after_balance, before_balance)
      if lt(output_amount, min_output_amount) {
        mstore(32, 11)
        revert(63, 1)
      }
    }
    depositToCompound(output_asset, output_amount);
    uint256 fee;
    uint256 return_amount;
    assembly {
      fee := div(input_amount, 200)
      return_amount := add(fee, input_amount)
    }
    _withdraw(input_asset, return_amount, address(_parent_address));
    assembly {
      sstore(_trade_running_slot, 1)
      
       
      mstore(m_in, input_asset)
      mstore(add(m_in, 32), output_asset)
      mstore(add(m_in, 64), input_amount)
      mstore(add(m_in, 96), output_amount)
      mstore(add(m_in, 128), fee)
      log2(m_in, 160,   0x4a2af5744adbfadba82ab831aea212bad92f5a70fef2079562044f423e999851, trade_contract)
    }
  }
}