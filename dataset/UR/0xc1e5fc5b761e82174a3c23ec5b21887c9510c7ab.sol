 

pragma solidity ^0.4.18;

contract ThisMustBeFirst {

  address public bts_address1;
  address public bts_address2;
  address public token_address;

}

contract AuthorizedList {

    bytes32 constant I_AM_ROOT = keccak256("I am root!");
    bytes32 constant STAFF_MEMBER = keccak256("Staff Member.");
    bytes32 constant ROUTER = keccak256("Router Contract.");
    mapping (address => mapping(bytes32 => bool)) authorized;
    mapping (bytes32 => bool) internal contractPermissions;

}

contract CodeTricks {

    function getCodeHash(address _addr) internal view returns (bytes32) {

        return keccak256(getCode(_addr));

    }

    function getCode(address _addr) internal view returns (bytes) {

        bytes memory code;
        assembly {
             
            let size := extcodesize(_addr)
             
            code := mload(0x40)
             
            mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
             
            mstore(code, size)
             
            extcodecopy(_addr, add(code, 0x20), 0, size)
        }
        return code;

    }

}

contract Authorized is AuthorizedList {

    function Authorized() public {

       authorized[msg.sender][I_AM_ROOT] = true;

    }

    modifier ifAuthorized(address _address, bytes32 _authorization) {

       require(authorized[_address][_authorization] || authorized[_address][I_AM_ROOT]);
       _;

    }

    function isAuthorized(address _address, bytes32 _authorization) public view returns (bool) {

       return authorized[_address][_authorization];

    }

    function toggleAuthorization(address _address, bytes32 _authorization) public ifAuthorized(msg.sender, I_AM_ROOT) {

        
       require(_address != msg.sender);

        
       if (_authorization == I_AM_ROOT && !authorized[_address][I_AM_ROOT])
           authorized[_address][STAFF_MEMBER] = false;

       authorized[_address][_authorization] = !authorized[_address][_authorization];

    }

}

contract Router is ThisMustBeFirst, AuthorizedList, CodeTricks, Authorized {

  function Router(address _token_address, address _storage_address) public Authorized() {

     require(_token_address != address(0));
     require(_storage_address != address(0));
     token_address = _token_address;
     bts_address1 = _storage_address;

      
      
      
      

  }

  function nameSuccessor(address _token_address) public ifAuthorized(msg.sender, I_AM_ROOT) {

     require(_token_address != address(0));
     token_address = _token_address;

      
      
      

  }

  function setStorage(address _storage_address) public ifAuthorized(msg.sender, I_AM_ROOT) {

     require(_storage_address != address(0));
     bts_address1 = _storage_address;

      
      
      

  }

  function setSecondaryStorage(address _storage_address) public ifAuthorized(msg.sender, I_AM_ROOT) {

     require(_storage_address != address(0));
     bts_address2 = _storage_address;

      
      
      

  }

  function swapStorage() public ifAuthorized(msg.sender, I_AM_ROOT) {

     address temp = bts_address1;
     bts_address1 = bts_address2;
     bts_address2 = temp;

  }



  function() public payable {

       
       
       
       

      var target = token_address;
      assembly {
          let _calldata := mload(0x40)
          mstore(0x40, add(_calldata, calldatasize))
          calldatacopy(_calldata, 0x0, calldatasize)
          switch delegatecall(gas, target, _calldata, calldatasize, 0, 0)
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