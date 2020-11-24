 

 

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


contract ERC1404 is ERC20 {
     
     
     
     
     
     
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

     
     
     
     
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string);
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


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity ^0.4.24;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.4.24;




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

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




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

pragma solidity ^0.4.24;



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 

pragma solidity ^0.4.24;


 
contract ServiceRegistry is Ownable {
  address public service;

   
  event ReplaceService(address oldService, address newService);

   
  modifier withContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0);
    _;
  }

   
  constructor(address _service) public {
    service = _service;
  }

   
  function replaceService(address _service) onlyOwner withContract(_service) public {
    address oldService = service;
    service = _service;
    emit ReplaceService(oldService, service);
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

 

 

pragma solidity ^0.4.24;






 
contract RegulatedToken is DetailedERC20, MintableToken, BurnableToken {

   
  uint8 constant public RTOKEN_DECIMALS = 18;

   
  event CheckStatus(uint8 reason, address indexed spender, address indexed from, address indexed to, uint256 value);

   
  ServiceRegistry public registry;

   
  constructor(ServiceRegistry _registry, string _name, string _symbol) public
    DetailedERC20(_name, _symbol, RTOKEN_DECIMALS)
  {
    require(_registry != address(0));

    registry = _registry;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (_check(msg.sender, _to, _value)) {
      return super.transfer(_to, _value);
    } else {
      return false;
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (_check(_from, _to, _value)) {
      return super.transferFrom(_from, _to, _value);
    } else {
      return false;
    }
  }

   
  function _check(address _from, address _to, uint256 _value) private returns (bool) {
    require(_from != address(0) && _to != address(0));
    uint8 reason = _service().check(this, msg.sender, _from, _to, _value);

    emit CheckStatus(reason, msg.sender, _from, _to, _value);

    return reason == 0;
  }

   
  function _service() view public returns (RegulatorService) {
    return RegulatorService(registry.service());
  }
}

 

pragma solidity ^0.4.24;




contract RegulatedTokenERC1404 is ERC1404, RegulatedToken {
    constructor(ServiceRegistry _registry, string _name, string _symbol) public
        RegulatedToken(_registry, _name, _symbol)
    {

    }

    
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8) {
        return _service().check(this, address(0), from, to, value);
    }

    
    function messageForTransferRestriction (uint8 reason) public view returns (string) {
        return _service().messageForReason(reason);
    }
}