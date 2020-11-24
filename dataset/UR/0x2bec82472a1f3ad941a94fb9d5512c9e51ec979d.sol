 

pragma solidity 0.4.25;

 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
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


 
contract DividendDistributingToken is StandardToken {
  using SafeMath for uint256;

  uint256 public constant POINTS_PER_WEI = uint256(10) ** 32;

  uint256 public pointsPerToken = 0;
  mapping(address => uint256) public credits;
  mapping(address => uint256) public lastPointsPerToken;

  event DividendsDeposited(address indexed payer, uint256 amount);
  event DividendsCollected(address indexed collector, uint256 amount);

  function collectOwedDividends() public {
    creditAccount(msg.sender);

    uint256 _wei = credits[msg.sender] / POINTS_PER_WEI;

    credits[msg.sender] = 0;

    msg.sender.transfer(_wei);
    emit DividendsCollected(msg.sender, _wei);
  }

  function creditAccount(address _account) internal {
    uint256 amount = balanceOf(_account).mul(pointsPerToken.sub(lastPointsPerToken[_account]));
    credits[_account] = credits[_account].add(amount);
    lastPointsPerToken[_account] = pointsPerToken;
  }

  function deposit(uint256 _value) internal {
    pointsPerToken = pointsPerToken.add(_value.mul(POINTS_PER_WEI) / totalSupply_);
    emit DividendsDeposited(msg.sender, _value);
  }
}



contract LandRegistryInterface {
  function getProperty(string _eGrid) public view returns (address property);
}


contract LandRegistryProxyInterface {
  function owner() public view returns (address);
  function landRegistry() public view returns (LandRegistryInterface);
}


contract WhitelistInterface {
  function checkRole(address _operator, string _permission) public view;
}


contract WhitelistProxyInterface {
  function whitelist() public view returns (WhitelistInterface);
}


 
contract TokenizedProperty is Ownable, DividendDistributingToken {
  address public constant LAND_REGISTRY_PROXY_ADDRESS = 0xe72AD2A335AE18e6C7cdb6dAEB64b0330883CD56;   
  address public constant WHITELIST_PROXY_ADDRESS = 0x7223b032180CDb06Be7a3D634B1E10032111F367;   

  LandRegistryProxyInterface public registryProxy = LandRegistryProxyInterface(LAND_REGISTRY_PROXY_ADDRESS);
  WhitelistProxyInterface public whitelistProxy = WhitelistProxyInterface(WHITELIST_PROXY_ADDRESS);

  uint8 public constant decimals = 18;
  uint256 public constant NUM_TOKENS = 1000000;
  string public symbol;

  string public managementCompany;
  string public name;

  mapping(address => uint256) public lastTransferBlock;
  mapping(address => uint256) public minTransferAccepted;

  event MinTransferSet(address indexed account, uint256 minTransfer);
  event ManagementCompanySet(string managementCompany);
  event UntokenizeRequest();
  event Generic(string generic);

  modifier isValid() {
    LandRegistryInterface registry = LandRegistryInterface(registryProxy.landRegistry());
    require(registry.getProperty(name) == address(this), "invalid TokenizedProperty");
    _;
  }

  constructor(string _eGrid, string _grundstuckNumber) public {
    require(bytes(_eGrid).length > 0, "eGrid must be non-empty string");
    require(bytes(_grundstuckNumber).length > 0, "grundstuck must be non-empty string");
    name = _eGrid;
    symbol = _grundstuckNumber;

    totalSupply_ = NUM_TOKENS * (uint256(10) ** decimals);
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  function () public payable {   
    uint256 value = msg.value;
    require(value > 0, "must send wei in fallback");

    address blockimmo = registryProxy.owner();
    if (blockimmo != address(0)) {   
      uint256 fee = value / 100;
      blockimmo.transfer(fee);
      value = value.sub(fee);
    }

    deposit(value);
  }

  function setManagementCompany(string _managementCompany) public onlyOwner isValid {
    managementCompany = _managementCompany;
    emit ManagementCompanySet(managementCompany);
  }

  function untokenize() public onlyOwner isValid {
    emit UntokenizeRequest();
  }

  function emitGenericProposal(string _generic) public onlyOwner isValid {
    emit Generic(_generic);
  }

  function transfer(address _to, uint256 _value) public isValid returns (bool) {
    require(_value >= minTransferAccepted[_to], "tokens transferred less than _to's minimum accepted transfer");
    transferBookKeeping(msg.sender, _to);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isValid returns (bool) {
    require(_value >= minTransferAccepted[_to], "tokens transferred less than _to's minimum accepted transfer");
    transferBookKeeping(_from, _to);
    return super.transferFrom(_from, _to, _value);
  }

  function setMinTransfer(uint256 _amount) public {
    minTransferAccepted[msg.sender] = _amount;
    emit MinTransferSet(msg.sender, _amount);
  }

  function transferBookKeeping(address _from, address _to) internal {
    whitelistProxy.whitelist().checkRole(_to, "authorized");

    creditAccount(_from);   
    creditAccount(_to);

    lastTransferBlock[_from] = block.number;   
    lastTransferBlock[_to] = block.number;
  }
}