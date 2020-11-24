 

pragma solidity ^0.5.7;
contract MarginParent {
  bytes constant _margin_swap_compiled = hex"608060405234801561001057600080fd5b506040516102963803806102968339818101604052604081101561003357600080fd5b81019080805190602001909291908051906020019092919050505081600155806002556001600355505061022a8061006c6000396000f3fe60806040526004361061003f5760003560e01c80633b1ca3b51461006657806380f76021146100b7578063893d20e81461010e578063ea87963414610165575b366000803760008036600080545af43d6000803e8060008114610061573d6000f35b3d6000fd5b34801561007257600080fd5b506100b56004803603602081101561008957600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506101bc565b005b3480156100c357600080fd5b506100cc6101d8565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561011a57600080fd5b506101236101e2565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561017157600080fd5b5061017a6101ec565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6002543318156101d15760016020526001603ffd5b8060005550565b6000600254905090565b6000600154905090565b6000805490509056fea265627a7a72305820c1c7f4c7bd26890e7f00477b3ef68b6d45b2399e0b5eb13676dec4ad4737583e64736f6c634300050a0032";
  address _manager_address;
  address _manager_proposed;
  address _default_code;
  uint256[2**160] _white_listed_addresses;
  uint256[2**160] _approved_margin_code;
  event MarginSetup(
    address indexed owner,
    address margin_address
  );
  
  constructor(address default_code) public payable  {
    assembly {
      sstore(_manager_address_slot, caller)
      sstore(_default_code_slot, default_code)
      sstore(add(_white_listed_addresses_slot, caller), 1)
    }
  }
  
  function () external payable  {}
  
  function approveMarginCode(address margin_code_address, bool approved) external  {
    assembly {
      if xor(caller, sload(_manager_address_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(add(_approved_margin_code_slot, margin_code_address), approved)
    }
  }
  
  function setDefautlMarginCode(address default_code) external  {
    assembly {
      if xor(caller, sload(_manager_address_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(add(_approved_margin_code_slot, default_code), 1)
      sstore(_default_code_slot, default_code)
    }
  }
  
  function setMarginCode(address margin_code_address) external  {
    address margin_contract = getMarginAddress(address(msg.sender));
    
    uint256[2] memory m_in;
    assembly {
      if iszero(extcodesize(margin_contract)) {
        mstore(32, 1)
        revert(63, 1)
      }
      let approved := sload(add(_approved_margin_code_slot, margin_code_address))
      sstore(add(_white_listed_addresses_slot, margin_contract), approved)
      {
        mstore(m_in,   0x3b1ca3b500000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 0x04), margin_code_address)
        let res := call(gas, margin_contract, 0, m_in, 0x24, 0x00, 0x00)
        if iszero(res) {
          mstore(32, 2)
          revert(63, 1)
        }
      }
    }
  }
  
  function managerPropose(address new_manager) external  {
    assembly {
      if xor(caller, sload(_manager_address_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(_manager_proposed_slot, new_manager)
    }
  }
  
  function managerSet() external  {
    assembly {
      let proposed := sload(_manager_proposed_slot)
      if xor(caller, proposed) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(add(_white_listed_addresses_slot, sload(_manager_address_slot)), 0)
      sstore(add(_white_listed_addresses_slot, proposed), 1)
      sstore(_manager_address_slot, proposed)
    }
  }
  
  function setupMargin() external 
  returns (address margin_contract) {
    bytes memory margin_swap_compiled = _margin_swap_compiled;
    
    uint256[2] memory m_in;
    assembly {
      let compiled_bytes := mload(margin_swap_compiled)
      let contract_start := add(margin_swap_compiled, 0x20)
      let cursor := add(contract_start, compiled_bytes)
      mstore(cursor, caller)
      cursor := add(cursor, 0x20)
      mstore(cursor, address)
      cursor := add(cursor, 0x20)
      mstore(0x40, cursor)
      let contract_size := sub(cursor, contract_start)
      margin_contract := create2(0, contract_start, contract_size, caller)
      if iszero(margin_contract) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(add(_white_listed_addresses_slot, margin_contract), 1)
      {
        mstore(m_in,   0x3b1ca3b500000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 0x04), sload(_default_code_slot))
        let res := call(gas, margin_contract, 0, m_in, 0x24, 0x0, 0x0)
        if iszero(res) {
          mstore(32, 2)
          revert(63, 1)
        }
      }
      
       
      mstore(m_in, margin_contract)
      log2(m_in, 32,   0xd1915076529a929900f0bed2467292f2d10fdeda6f13a14d8d793a45d7916eaf, caller)
    }
  }
  
  function isMarginSetup(address owner) public view 
  returns (address margin_contract, bool enabled) {
    margin_contract = getMarginAddress(owner);
    assembly {
      enabled := sload(add(_white_listed_addresses_slot, margin_contract))
    }
  }
  
  function getMarginAddress(address owner) public view 
  returns (address margin_contract) {
    bytes memory margin_swap_compiled = _margin_swap_compiled;
    assembly {
      let compiled_bytes := mload(margin_swap_compiled)
      let contract_start := add(margin_swap_compiled, 0x20)
      let cursor := add(contract_start, compiled_bytes)
      mstore(cursor, owner)
      cursor := add(cursor, 0x20)
      mstore(cursor, address)
      cursor := add(cursor, 0x20)
      mstore(0x40, cursor)
      let contract_size := sub(cursor, contract_start)
      let contract_hash := keccak256(contract_start, contract_size)
      mstore(margin_swap_compiled, or(shl(0xa0, 0xff), address))
      mstore(add(margin_swap_compiled, 0x20), owner)
      mstore(add(margin_swap_compiled, 0x40), contract_hash)
      let address_hash := keccak256(add(margin_swap_compiled, 11), 85)
      margin_contract := and(address_hash, 0xffffffffffffffffffffffffffffffffffffffff)
    }
  }
  
  function getCapital(address asset, uint256 amount) external  {
    
    uint256[3] memory m_in;
    
    uint256[1] memory m_out;
    assembly {
      if iszero(sload(add(_white_listed_addresses_slot, caller))) {
        mstore(32, 1)
        revert(63, 1)
      }
      let m_in_size := 0
      let wei_to_send := amount
      let dest := caller
      if asset {
        mstore(m_in,   0xa9059cbb00000000000000000000000000000000000000000000000000000000)
        mstore(add(m_in, 4), caller)
        mstore(add(m_in, 0x24), amount)
        dest := asset
        m_in_size := 0x44
        wei_to_send := 0
      }
      let result := call(gas, dest, wei_to_send, m_in, m_in_size, m_out, 32)
      if iszero(result) {
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
}