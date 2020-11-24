 

pragma solidity 0.4.19;

pragma solidity ^0.4.18;


 
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
pragma solidity ^0.4.18;

pragma solidity ^0.4.18;


 
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

 

contract MigrationSource {
  function vacate(address _addr) public returns (uint256 o_balance,
                                                 uint256 o_lock_value,
                                                 uint256 o_lock_endTime,
                                                 bytes32 o_operatorId,
                                                 bytes32 o_playerId);
}

contract CashBetCoin is MigrationSource, ERC20 {
  using SafeMath for uint256;

  string public constant name = "CashBetCoin";
  string public constant symbol = "CBC";
  uint8 public constant decimals = 8;
  uint internal totalSupply_;

  address public owner;

  mapping(bytes32 => bool) public operators;
  mapping(address => User) public users;
  mapping(address => mapping(bytes32 => bool)) public employees;
  
  MigrationSource public migrateFrom;
  address public migrateTo;

  struct User {
    uint256 balance;
    uint256 lock_value;
    uint256 lock_endTime;
    bytes32 operatorId;
    bytes32 playerId;
      
    mapping(address => uint256) authorized;
  }

  modifier only_owner(){
    require(msg.sender == owner);
    _;
  }

  modifier only_employees(address _user){
    require(employees[msg.sender][users[_user].operatorId]);
    _;
  }

   
  modifier playerid_iff_operatorid(bytes32 _opId, bytes32 _playerId){
    require(_opId != bytes32(0) || _playerId == bytes32(0));
    _;
  }

   
  modifier value_less_than_unlocked_balance(address _user, uint256 _value){
    User storage user = users[_user];
    require(user.lock_endTime < block.timestamp ||
            _value <= user.balance - user.lock_value);
    require(_value <= user.balance);
    _;
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  event LockIncrease(address indexed user, uint256 amount, uint256 time);
  event LockDecrease(address indexed user, address employee,  uint256 amount, uint256 time);

  event Associate(address indexed user, address agent, bytes32 indexed operatorId, bytes32 playerId);
  
  event Burn(address indexed owner, uint256 value);

  event OptIn(address indexed owner, uint256 value);
  event Vacate(address indexed owner, uint256 value);

  event Employee(address indexed empl, bytes32 indexed operatorId, bool allowed);
  event Operator(bytes32 indexed operatorId, bool allowed);

  function CashBetCoin(uint _totalSupply) public {
    totalSupply_ = _totalSupply;
    owner = msg.sender;
    User storage user = users[owner];
    user.balance = totalSupply_;
    user.lock_value = 0;
    user.lock_endTime = 0;
    user.operatorId = bytes32(0);
    user.playerId = bytes32(0);
    Transfer(0, owner, _totalSupply);
  }

  function totalSupply() public view returns (uint256){
    return totalSupply_;
  }

  function balanceOf(address _addr) public view returns (uint256 balance) {
    return users[_addr].balance;
  }

  function transfer(address _to, uint256 _value) public value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public value_less_than_unlocked_balance(_from, _value) returns (bool success) {
    User storage user = users[_from];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    user.authorized[msg.sender] = user.authorized[msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success){
     
     
     
     
    require((_value == 0) || (users[msg.sender].authorized[_spender] == 0));
    users[msg.sender].authorized[_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _user, address _spender) public view returns (uint256){
    return users[_user].authorized[_spender];
  }

   
   
  function lockedValueOf(address _addr) public view returns (uint256 value) {
    User storage user = users[_addr];
     
    if (user.lock_endTime < block.timestamp) {
       
      return 0;
    } else {
      return user.lock_value;
    }
  }

   
   
  function lockedEndTimeOf(address _addr) public view returns (uint256 time) {
    return users[_addr].lock_endTime;
  }

   
   
   
   
   
   
   
  function increaseLock(uint256 _value, uint256 _time) public returns (bool success) {
    User storage user = users[msg.sender];

     
    if (block.timestamp < user.lock_endTime) {
       
      require(_value >= user.lock_value);
      require(_time >= user.lock_endTime);
       
      require(_value > user.lock_value || _time > user.lock_endTime);
    }

     
    require(_value <= user.balance);
    require(_time > block.timestamp);

    user.lock_value = _value;
    user.lock_endTime = _time;
    LockIncrease(msg.sender, _value, _time);
    return true;
  }

   
   
   
   
  function decreaseLock(uint256 _value, uint256 _time, address _user) public only_employees(_user) returns (bool success) {
    User storage user = users[_user];

     
    require(user.lock_endTime > block.timestamp);
     
    require(_value <= user.lock_value);
    require(_time <= user.lock_endTime);
     
    require(_value < user.lock_value || _time < user.lock_endTime);

    user.lock_value = _value;
    user.lock_endTime = _time;
    LockDecrease(_user, msg.sender, _value, _time);
    return true;
  }

  function associate(bytes32 _opId, bytes32 _playerId) public playerid_iff_operatorid(_opId, _playerId) returns (bool success) {
    User storage user = users[msg.sender];

     
     
     
    require(user.lock_value == 0 ||
            user.lock_endTime < block.timestamp ||
            user.playerId == 0);

     
    require(_opId == bytes32(0) || operators[_opId]);

    user.operatorId = _opId;
    user.playerId = _playerId;
    Associate(msg.sender, msg.sender, _opId, _playerId);
    return true;
  }

  function associationOf(address _addr) public view returns (bytes32 opId, bytes32 playerId) {
    return (users[_addr].operatorId, users[_addr].playerId);
  }

  function setAssociation(address _user, bytes32 _opId, bytes32 _playerId) public only_employees(_user) playerid_iff_operatorid(_opId, _playerId) returns (bool success) {
    User storage user = users[_user];

     
     
    require(_opId == bytes32(0) || employees[msg.sender][_opId]);
    
    user.operatorId = _opId;
    user.playerId = _playerId;
    Associate(_user, msg.sender, _opId, _playerId);
    return true;
  }
  
  function setEmployee(address _addr, bytes32 _opId, bool _allowed) public only_owner {
    employees[_addr][_opId] = _allowed;
    Employee(_addr, _opId, _allowed);
  }

  function setOperator(bytes32 _opId, bool _allowed) public only_owner {
    operators[_opId] = _allowed;
    Operator(_opId, _allowed);
  }

  function setOwner(address _addr) public only_owner {
    owner = _addr;
  }

  function burnTokens(uint256 _value) public value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

   
   
   
  function setMigrateFrom(address _addr) public only_owner {
    require(migrateFrom == MigrationSource(0));
    migrateFrom = MigrationSource(_addr);
  }

   
   
   
  function setMigrateTo(address _addr) public only_owner {
    migrateTo = _addr;
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
  function optIn() public returns (bool success) {
    require(migrateFrom != MigrationSource(0));
    User storage user = users[msg.sender];
    uint256 balance;
    uint256 lock_value;
    uint256 lock_endTime;
    bytes32 opId;
    bytes32 playerId;
    (balance, lock_value, lock_endTime, opId, playerId) =
        migrateFrom.vacate(msg.sender);

    OptIn(msg.sender, balance);
    
    user.balance = user.balance.add(balance);

    bool lockTimeIncreased = false;
    user.lock_value = user.lock_value.add(lock_value);
    if (user.lock_endTime < lock_endTime) {
      user.lock_endTime = lock_endTime;
      lockTimeIncreased = true;
    }
    if (lock_value > 0 || lockTimeIncreased) {
      LockIncrease(msg.sender, user.lock_value, user.lock_endTime);
    }

    if (user.operatorId == bytes32(0) && opId != bytes32(0)) {
      user.operatorId = opId;
      user.playerId = playerId;
      Associate(msg.sender, msg.sender, opId, playerId);
    }

    totalSupply_ = totalSupply_.add(balance);

    return true;
  }

   
   
   
   
  function vacate(address _addr) public returns (uint256 o_balance,
                                                 uint256 o_lock_value,
                                                 uint256 o_lock_endTime,
                                                 bytes32 o_opId,
                                                 bytes32 o_playerId) {
    require(msg.sender == migrateTo);
    User storage user = users[_addr];
    require(user.balance > 0);

    o_balance = user.balance;
    o_lock_value = user.lock_value;
    o_lock_endTime = user.lock_endTime;
    o_opId = user.operatorId;
    o_playerId = user.playerId;

    totalSupply_ = totalSupply_.sub(user.balance);

    user.balance = 0;
    user.lock_value = 0;
    user.lock_endTime = 0;
    user.operatorId = bytes32(0);
    user.playerId = bytes32(0);

    Vacate(_addr, o_balance);
  }

   
  function () public payable {
    revert();
  }
}