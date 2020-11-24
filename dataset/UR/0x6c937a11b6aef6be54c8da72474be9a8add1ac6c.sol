 

pragma solidity 0.5.1;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


 
contract IpfsHashRecord is WhitelistAdminRole {

   
   
   
   
  event Recorded (bytes4 indexed eventSig, uint256 indexed createdAt, bytes32 ipfsHash);

   
  function writeHash(bytes4 _eventSig, bytes32 _ipfsHash) public onlyWhitelistAdmin {
    emit Recorded(_eventSig, uint256(now), _ipfsHash);
  }

   
  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    super.addWhitelistAdmin(account);
  }

   
  function renounceWhitelistAdmin() public {
    super.renounceWhitelistAdmin();
  }

   
  function isWhitelistAdmin(address account) public view returns (bool) {
    return super.isWhitelistAdmin(account);
  }
}