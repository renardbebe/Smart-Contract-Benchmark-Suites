 

pragma solidity ^0.5.7;
contract MarginProxy {
  uint256 _code;
  uint256 _owner;
  uint256 _parent_address;
  uint256 _run_state;
  
  constructor(address owner, address parent_address) public  {
    assembly {
      sstore(_owner_slot, owner)
      sstore(_parent_address_slot, parent_address)
      sstore(_run_state_slot, 1)
    }
  }
  
  function () external payable  {
    assembly {
      calldatacopy(0, 0, calldatasize)
      let res := delegatecall(gas, sload(_code_slot), 0, calldatasize, 0, 0)
      returndatacopy(0, 0, returndatasize)
      switch res
        case 0 {
          revert(0, returndatasize)
        }
        default {
          return(0, returndatasize)
        }
    }
  }
  
  function setCode(address code_address) external  {
    assembly {
      if xor(caller, sload(_parent_address_slot)) {
        mstore(32, 1)
        revert(63, 1)
      }
      sstore(_code_slot, code_address)
    }
  }
  
  function getCode() public view 
  returns (address code_address) {
    assembly {
      code_address := sload(_code_slot)
    }
  }
  
  function getOwner() public view 
  returns (address owner_address) {
    assembly {
      owner_address := sload(_owner_slot)
    }
  }
  
  function getParent() public view 
  returns (address parent_address) {
    assembly {
      parent_address := sload(_parent_address_slot)
    }
  }
}