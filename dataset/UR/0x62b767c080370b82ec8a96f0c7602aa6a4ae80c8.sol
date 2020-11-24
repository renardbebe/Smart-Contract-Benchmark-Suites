 

pragma solidity ^0.5.0;


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

contract AltiMates is WhitelistAdminRole {

  struct ATContract {
    string refNo;
    string stock;
    uint256 startDate;
    uint256 endDate;
    uint256 spotPrice;
    uint256 spRate;
    uint256 koRate;
    uint256 kiRate;
  }

  mapping(address => ATContract) public contracts;

  constructor() public {
  }

  function subscribe(address from, string calldata _refNo, string calldata _stock, uint256 _startDate, uint256 _endDate,
    uint256 _spotPrice, uint256 _spRate, uint256 _koRate, uint256 _kiRate) external onlyWhitelistAdmin {
    ATContract memory ctr  = ATContract(_refNo, _stock, _startDate, _endDate, _spotPrice, _spRate, _koRate, _kiRate);
    contracts[from] = ctr;
  }
}