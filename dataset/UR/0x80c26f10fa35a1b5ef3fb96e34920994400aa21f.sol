 

 


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

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

 

 
contract LockRule is IRule, Authority {

  enum Direction {
    NONE,
    RECEIVE,
    SEND,
    BOTH
  }

  struct ScheduledLock {
    Direction restriction;
    uint256 startAt;
    uint256 endAt;
    bool scheduleInverted;
  }

  mapping(address => Direction) individualPasses;
  ScheduledLock lock = ScheduledLock(
    Direction.NONE,
    0,
    0,
    false
  );

   
  function hasSendDirection(Direction _direction) public pure returns (bool) {
    return _direction == Direction.SEND || _direction == Direction.BOTH;
  }

   
  function hasReceiveDirection(Direction _direction)
    public pure returns (bool)
  {
    return _direction == Direction.RECEIVE || _direction == Direction.BOTH;
  }

   
  function restriction() public view returns (Direction) {
    return lock.restriction;
  }

   
  function scheduledStartAt() public view returns (uint256) {
    return lock.startAt;
  }

   
  function scheduledEndAt() public view returns (uint256) {
    return lock.endAt;
  }

   
  function isScheduleInverted() public view returns (bool) {
    return lock.scheduleInverted;
  }

   
  function isLocked() public view returns (bool) {
     
    return (lock.startAt <= now && lock.endAt > now)
      ? !lock.scheduleInverted : lock.scheduleInverted;
  }

   
  function individualPass(address _address)
    public view returns (Direction)
  {
    return individualPasses[_address];
  }

   
  function canSend(address _address) public view returns (bool) {
    if (isLocked() && hasSendDirection(lock.restriction)) {
      return hasSendDirection(individualPasses[_address]);
    }
    return true;
  }

   
  function canReceive(address _address) public view returns (bool) {
    if (isLocked() && hasReceiveDirection(lock.restriction)) {
      return hasReceiveDirection(individualPasses[_address]);
    }
    return true;
  }

   
  function definePass(address _address, uint256 _lock)
    public onlyAuthority returns (bool)
  {
    individualPasses[_address] = Direction(_lock);
    emit PassDefinition(_address, Direction(_lock));
    return true;
  }

   
  function defineManyPasses(address[] _addresses, uint256 _lock)
    public onlyAuthority returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(definePass(_addresses[i], _lock), "LOR01");
    }
    return true;
  }

   
  function scheduleLock(
    Direction _restriction,
    uint256 _startAt, uint256 _endAt, bool _scheduleInverted)
    public onlyAuthority returns (bool)
  {
    require(_startAt <= _endAt, "LOR02");
    lock = ScheduledLock(
      _restriction,
      _startAt,
      _endAt,
      _scheduleInverted
    );
    emit LockDefinition(
      lock.restriction, lock.startAt, lock.endAt, lock.scheduleInverted);
  }

   
  function isAddressValid(address  ) public view returns (bool) {
    return true;
  }

   
  function isTransferValid(address _from, address _to, uint256  )
    public view returns (bool)
  {
    return (canSend(_from) && canReceive(_to));
  }

  event LockDefinition(
    Direction restriction,
    uint256 startAt,
    uint256 endAt,
    bool scheduleInverted
  );
  event PassDefinition(address _address, Direction pass);
}