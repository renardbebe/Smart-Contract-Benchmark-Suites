 

 

pragma solidity ^0.4.23;

contract References {

  mapping (bytes32 => address) internal references;

}

contract AuthorizedList {

    bytes32 constant PRESIDENT = keccak256("Republics President!");
    bytes32 constant STAFF_MEMBER = keccak256("Staff Member.");
    bytes32 constant AIR_DROP = keccak256("Airdrop Permission.");
    bytes32 constant INTERNAL = keccak256("Internal Authorization.");
    mapping (address => mapping(bytes32 => bool)) authorized;

}

contract Authorized is AuthorizedList {

     
     
    function Authorized() public {

       authorized[msg.sender][PRESIDENT] = true;

    }


     
     
     
    modifier ifAuthorized(address _address, bytes32 _authorization) {

       require(authorized[_address][_authorization] || authorized[_address][PRESIDENT], "Not authorized to access!");
       _;

    }

     
     
     
    function isAuthorized(address _address, bytes32 _authorization) public view returns (bool) {

       return authorized[_address][_authorization];

    }

     
     
     
    function toggleAuthorization(address _address, bytes32 _authorization) public ifAuthorized(msg.sender, PRESIDENT) {

        
       require(_address != msg.sender, "Cannot change own permissions.");

        
       if (_authorization == PRESIDENT && !authorized[_address][PRESIDENT])
           authorized[_address][STAFF_MEMBER] = false;

       authorized[_address][_authorization] = !authorized[_address][_authorization];

    }

}

contract main is References, AuthorizedList, Authorized {

  event LogicUpgrade(address indexed _oldbiz, address indexed _newbiz);
  event StorageUpgrade(address indexed _oldvars, address indexed _newvars);

  function main(address _logic, address _storage) public Authorized() {

     require(_logic != address(0), "main: Unexpectedly logic address is 0x0.");
     require(_storage != address(0), "main: Unexpectedly storage address is 0x0.");
     references[bytes32(0)] = _logic;
     references[bytes32(1)] = _storage;

  }

   
   
   
  function setReference(address _address, bytes32 _key) external ifAuthorized(msg.sender, PRESIDENT) {

     require(_address != address(0), "setReference: Unexpectedly _address is 0x0");

     if (_key == bytes32(0)) emit LogicUpgrade(references[bytes32(0)], _address);
     else emit StorageUpgrade(references[_key], _address);

     if (references[_key] != address(0))
          delete references[_key];

     references[_key] = _address;

  }

   
   
  function getReference(bytes32 _key) external view ifAuthorized(msg.sender, PRESIDENT) returns(address) {

      return references[_key];

  }

  function() external payable {

      address _target = references[bytes32(0)];
      assembly {
          let _calldata := mload(0x40)
          mstore(0x40, add(_calldata, calldatasize))
          calldatacopy(_calldata, 0x0, calldatasize)
          switch delegatecall(gas, _target, _calldata, calldatasize, 0, 0)
            case 0 { revert(0, 0) }
            default {
              let _returndata := mload(0x40)
              returndatacopy(_returndata, 0, returndatasize)
              mstore(0x40, add(_returndata, returndatasize))
              return(_returndata, returndatasize)
            }
       }
   }

}