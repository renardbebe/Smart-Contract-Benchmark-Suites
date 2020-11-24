 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

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

 

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract Pausable is Context, PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

 

pragma solidity ^0.5.0;



 
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
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

 

pragma solidity ^0.5.0;



contract SmartFly is WhitelistAdminRole, Pausable {

  mapping(bytes32 => Insurance[]) private insuranceList;

  enum InsuranceStatus {
    NONE,
    Active,
    FlightOnTime,
    CustomerCompensationPaid,
    CustomerCompensationWaiting
  }


  struct Insurance {
    bytes32          insuranceId;
    uint256          customerId;
    uint256          plannedDepartureTime;
    uint256          actualDepartureTime;
    InsuranceStatus  status;
  }


  event InsuranceCreation(
    bytes32         indexed flightId,
    bytes32         indexed insuranceId,
    uint256         indexed customerId,
    uint256                 plannedDepartureTime,
    uint256                 actualDepartureTime,
    InsuranceStatus         status
  );


  event InsuranceUpdate(
    bytes32         indexed flightId,
    bytes32                 insuranceId,
    uint256         indexed customerId,
    uint256                 plannedDepartureTime,
    uint256                 actualDepartureTime,
    InsuranceStatus indexed status
  );

  function getInsurancesCount (bytes32 flightId) public view onlyWhitelistAdmin whenNotPaused
    returns (uint256)
  {
    return insuranceList[flightId].length;
  }


  function addNewInsurance(
    bytes32          flightId,
    bytes32          insuranceId,
    uint256          customerId,
    uint256          plannedDepartureTime,
    uint256          actualDepartureTime
  ) public onlyWhitelistAdmin whenNotPaused {

    _addNewInsurance(flightId, insuranceId, customerId, plannedDepartureTime, actualDepartureTime, InsuranceStatus.Active);
  }


  function _addNewInsurance (
    bytes32          flightId,
    bytes32          insuranceId,
    uint256          customerId,
    uint256          plannedDepartureTime,
    uint256          actualDepartureTime,
    InsuranceStatus  status
  ) internal onlyWhitelistAdmin whenNotPaused {

    Insurance memory newInsurance;
    newInsurance.insuranceId = insuranceId;
    newInsurance.customerId = customerId;
    newInsurance.plannedDepartureTime = plannedDepartureTime;
    newInsurance.actualDepartureTime = actualDepartureTime;
    newInsurance.status = status;

    insuranceList[flightId].push(newInsurance);
    emit InsuranceCreation(flightId, insuranceId, customerId, plannedDepartureTime, actualDepartureTime, status);
  }


  function getInsuranceDetails(bytes32 flightId, uint index) public view onlyWhitelistAdmin whenNotPaused
    returns(
      bytes32          insuranceId,
      uint256          customerId,
      uint256          plannedDepartureTime,
      uint256          actualDepartureTime,
      InsuranceStatus  status)
  {

    require(insuranceList[flightId].length > 0 && (insuranceList[flightId].length - 1) >= index, "There's no Insurance on this flightId.");

    insuranceId = insuranceList[flightId][index].insuranceId;
    customerId = insuranceList[flightId][index].customerId;
    plannedDepartureTime = insuranceList[flightId][index].plannedDepartureTime;
    actualDepartureTime = insuranceList[flightId][index].actualDepartureTime;
    status = insuranceList[flightId][index].status;
  }


  function updateInsurance(
    bytes32 flightId,
    uint    index,
    bytes32 insuranceId,
    uint256 customerId,
    uint256 plannedDepartureTime,
    uint256 actualDepartureTime,
    InsuranceStatus status
  ) public onlyWhitelistAdmin whenNotPaused
    returns (bool)
  {
    require(insuranceList[flightId].length > 0 && (insuranceList[flightId].length - 1) >= index, "There's no Insurance on this flightId.");

    insuranceList[flightId][index].insuranceId = insuranceId;
    insuranceList[flightId][index].customerId = customerId;
    insuranceList[flightId][index].plannedDepartureTime = plannedDepartureTime;
    insuranceList[flightId][index].actualDepartureTime = actualDepartureTime;
    insuranceList[flightId][index].status = status;

    emit InsuranceUpdate(flightId, insuranceId, customerId, plannedDepartureTime, actualDepartureTime, status);

    return true;
  }

}