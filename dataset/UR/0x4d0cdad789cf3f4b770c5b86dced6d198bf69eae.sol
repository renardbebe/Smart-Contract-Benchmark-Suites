 

pragma solidity ^0.4.13;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

contract MigratableToken is ERC827Token {

  event Migrate(address indexed _from, address indexed _to, uint256 _value);

  address public migrator;
  address public migrationAgent;
  uint256 public totalMigrated;

  function MigratableToken(address _migrator) public {
    require(_migrator != address(0));
    migrator = _migrator;
  }

  modifier onlyMigrator() {
    require(msg.sender == migrator);
    _;
  }

  function migrate(uint256 _value) external {
    require(migrationAgent != address(0));
    require(_value != 0);
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    totalMigrated = totalMigrated.add(_value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
    Migrate(msg.sender, migrationAgent, _value);
  }

  function setMigrationAgent(address _agent) external onlyMigrator {
    require(migrationAgent == address(0));
    migrationAgent = _agent;
  }

  function setMigrationMaster(address _master) external onlyMigrator {
    require(_master != address(0));
    migrator = _master;
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract PausableToken is ERC827Token, Ownable {

  bool public transfersEnabled;

  modifier ifTransferAllowed {
    require(transfersEnabled || msg.sender == owner);
    _;
  }

   
  function PausableToken(bool _transfersEnabled) public {
    transfersEnabled = _transfersEnabled;
  }

  function setTransfersEnabled(bool _transfersEnabled) public onlyOwner {
    transfersEnabled = _transfersEnabled;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public ifTransferAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public ifTransferAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function approve(address _spender, uint256 _value) public ifTransferAllowed returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public ifTransferAllowed returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public ifTransferAllowed returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function approve(address _spender, uint256 _value, bytes _data) public ifTransferAllowed returns (bool) {
    return super.approve(_spender, _value, _data);
  }

  function transfer(address _to, uint256 _value, bytes _data) public ifTransferAllowed returns (bool) {
    return super.transfer(_to, _value, _data);
  }

  function transferFrom( address _from, address _to, uint256 _value, bytes _data) public ifTransferAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value, _data);
  }

  function increaseApproval(address _spender, uint _addedValue, bytes _data) public ifTransferAllowed returns (bool) {
    return super.increaseApproval(_spender, _addedValue, _data);
  }

  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public ifTransferAllowed returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue, _data);
  }

}

contract Permissible is Ownable {

  event PermissionAdded(address indexed permitted);
  event PermissionRemoved(address indexed permitted);

  mapping(address => bool) public permittedAddresses;

  modifier onlyPermitted() {
    require(permittedAddresses[msg.sender]);
    _;
  }

  function addPermission(address _permitted) public onlyOwner {
    permittedAddresses[_permitted] = true;
    PermissionAdded(_permitted);
  }

  function removePermission(address _permitted) public onlyOwner {
    require(permittedAddresses[_permitted]);
    permittedAddresses[_permitted] = false;
    PermissionRemoved(_permitted);
  }
}

contract HyperToken is MigratableToken, PausableToken, Permissible {

  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event ReputationChanged(address indexed _owner, int32 _amount, int32 _newRep);

   
  string public constant name = "HyperToken";
  string public constant symbol = "HPR";
  uint8 public constant decimals = 18;
   

  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));

  mapping(address => int32) public reputation;

  function HyperToken(address _migrator, bool _transfersEnabled) public 
    PausableToken(_transfersEnabled)
    MigratableToken(_migrator) {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  function changeReputation(address _owner, int32 _amount) external onlyPermitted {
    require(balances[_owner] > 0);
    int32 oldRep = reputation[_owner];
    int32 newRep = oldRep + _amount;
    if (_amount < 0) {
      require(newRep < oldRep);
    } else {
      require(newRep >= oldRep);
    }
    reputation[_owner] = newRep;
    ReputationChanged(_owner, _amount, newRep);
  }

  function reputationOf(address _owner) public view returns (int32) {
    return reputation[_owner];
  }

  function transferOwnershipAndToken(address newOwner) public onlyOwner {
    transfer(newOwner, balanceOf(owner));
    transferOwnership(newOwner);
  }

  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic token = ERC20Basic(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

}

contract MigrationAgent {

  function migrateFrom(address _from, uint256 _value) public;
}