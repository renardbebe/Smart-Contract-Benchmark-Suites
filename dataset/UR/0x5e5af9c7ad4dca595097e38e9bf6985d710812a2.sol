 

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 

pragma solidity ^0.4.24;

 
contract RegulatorServiceI {

   
  function check(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8);
}

 

pragma solidity ^0.4.18;




 
contract RegulatorService is RegulatorServiceI, Ownable {
   
  modifier onlyAdmins() {
    require(msg.sender == admin || msg.sender == owner);
    _;
  }

   
  struct Settings {

     
    bool locked;

     
    bool partialTransfers;

     
    mapping(address => uint256) holdingPeriod;
  }

   
  uint256 constant private YEAR = 1 years;

   
  uint8 constant private CHECK_SUCCESS = 0;
  string constant private SUCCESS_MESSAGE = 'Success';

   
  uint8 constant private CHECK_ELOCKED = 1;
  string constant private ELOCKED_MESSAGE = 'Token is locked';

   
  uint8 constant private CHECK_EDIVIS = 2;
  string constant private EDIVIS_MESSAGE = 'Token can not trade partial amounts';

   
  uint8 constant private CHECK_ESEND = 3;
  string constant private ESEND_MESSAGE = 'Sender is not allowed to send the token';

   
  uint8 constant private CHECK_ERECV = 4;
  string constant private ERECV_MESSAGE = 'Receiver is not allowed to receive the token';

  uint8 constant private CHECK_EHOLDING_PERIOD = 5;
  string constant private EHOLDING_PERIOD_MESSAGE = 'Sender is still in 12 months holding period';

  uint8 constant private CHECK_EDECIMALS = 6;
  string constant private EDECIMALS_MESSAGE = 'Transfer value must be bigger than MINIMAL_TRANSFER';

  uint256 constant public MINIMAL_TRANSFER = 1 wei;

   
  uint8 constant private PERM_SEND = 0x1;

   
  uint8 constant private PERM_RECEIVE = 0x2;

   
  address public admin;

   
  mapping(address => Settings) private settings;

   
   
   
  mapping(address => mapping(address => uint8)) private participants;

   
  event LogLockSet(address indexed token, bool locked);

   
  event LogPartialTransferSet(address indexed token, bool enabled);

   
  event LogPermissionSet(address indexed token, address indexed participant, uint8 permission);

   
  event LogTransferAdmin(address indexed oldAdmin, address indexed newAdmin);

   
  event LogHoldingPeriod(
    address indexed _token, address indexed _participant, uint256 _startDate);

  constructor() public {
    admin = msg.sender;
  }

   
  function setLocked(address _token, bool _locked) onlyOwner public {
    settings[_token].locked = _locked;

    emit LogLockSet(_token, _locked);
  }

   
  function setPartialTransfers(address _token, bool _enabled) onlyOwner public {
   settings[_token].partialTransfers = _enabled;

   emit LogPartialTransferSet(_token, _enabled);
  }

   
  function setPermission(address _token, address _participant, uint8 _permission) onlyAdmins public {
    participants[_token][_participant] = _permission;

    emit LogPermissionSet(_token, _participant, _permission);
  }

   
  function setHoldingPeriod(address _token, address _participant, uint256 _startDate) onlyAdmins public {
    settings[_token].holdingPeriod[_participant] = _startDate;

    emit LogHoldingPeriod(_token, _participant, _startDate);
  }

   
  function transferAdmin(address newAdmin) onlyOwner public {
    require(newAdmin != address(0));

    address oldAdmin = admin;
    admin = newAdmin;

    emit LogTransferAdmin(oldAdmin, newAdmin);
  }

   
  function check(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8) {
    if (settings[_token].locked) {
      return CHECK_ELOCKED;
    }

    if (participants[_token][_from] & PERM_SEND == 0) {
      return CHECK_ESEND;
    }

    if (participants[_token][_to] & PERM_RECEIVE == 0) {
      return CHECK_ERECV;
    }

    if (!settings[_token].partialTransfers && _amount % _wholeToken(_token) != 0) {
      return CHECK_EDIVIS;
    }

    if (settings[_token].holdingPeriod[_from] + YEAR >= now) {
      return CHECK_EHOLDING_PERIOD;
    }

    if (_amount < MINIMAL_TRANSFER) {
      return CHECK_EDECIMALS;
    }

    return CHECK_SUCCESS;
  }

   
  function messageForReason (uint8 _reason) public pure returns (string) {
    if (_reason == CHECK_ELOCKED) {
      return ELOCKED_MESSAGE;
    }
    
    if (_reason == CHECK_ESEND) {
      return ESEND_MESSAGE;
    }

    if (_reason == CHECK_ERECV) {
      return ERECV_MESSAGE;
    }

    if (_reason == CHECK_EDIVIS) {
      return EDIVIS_MESSAGE;
    }

    if (_reason == CHECK_EHOLDING_PERIOD) {
      return EHOLDING_PERIOD_MESSAGE;
    }

    if (_reason == CHECK_EDECIMALS) {
      return EDECIMALS_MESSAGE;
    }

    return SUCCESS_MESSAGE;
  }

   
  function _wholeToken(address _token) view private returns (uint256) {
    return uint256(10)**DetailedERC20(_token).decimals();
  }
}