 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value)public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)public  returns (bool);
  function approve(address spender, uint256 value)public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause()public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value)public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BIMGToken is StandardToken, Pausable {

  string public constant name = "BIMG";
  string public constant symbol = "BIMG";
  uint256 public constant decimals = 18;
  
   
  struct LockToken{
      uint256 amount;
      uint32  time;
  }
  struct LockTokenSet{
      LockToken[] lockList;
  }
  mapping ( address => LockTokenSet ) addressTimeLock;
  mapping ( address => bool ) lockAdminList;
  event TransferWithLockEvt(address indexed from, address indexed to, uint256 value,uint32 lockTime );
   
  constructor() public {
    totalSupply = 10 * (10 ** 8) * (10 ** 18);
    balances[msg.sender] = totalSupply;
  }
  
  function transfer(address _to, uint256 _value)public whenNotPaused returns (bool) {
    assert ( balances[msg.sender].sub( getLockAmount( msg.sender ) ) >= _value );
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value)public whenNotPaused returns (bool) {
    assert ( balances[_from].sub( getLockAmount( msg.sender ) ) >= _value );
    return super.transferFrom(_from, _to, _value);
  }
  function getLockAmount( address myaddress ) public view returns ( uint256 lockSum ) {
        uint256 lockAmount = 0;
        for( uint32 i = 0; i < addressTimeLock[myaddress].lockList.length; i ++ ){
            if( addressTimeLock[myaddress].lockList[i].time > now ){
                lockAmount += addressTimeLock[myaddress].lockList[i].amount;
            }
        }
        return lockAmount;
  }
  
  function getLockListLen( address myaddress ) public view returns ( uint256 lockAmount  ){
      return addressTimeLock[myaddress].lockList.length;
  }
  
  function getLockByIdx( address myaddress,uint32 idx ) public view returns ( uint256 lockAmount, uint32 lockTime ){
      if( idx >= addressTimeLock[myaddress].lockList.length ){
        return (0,0);          
      }
      lockAmount = addressTimeLock[myaddress].lockList[idx].amount;
      lockTime = addressTimeLock[myaddress].lockList[idx].time;
      return ( lockAmount,lockTime );
  }
  
  function transferWithLock( address _to, uint256 _value,uint32 _lockTime )public whenNotPaused {
      assert( lockAdminList[msg.sender] == true  );
      assert( _lockTime > now  );
      transfer( _to, _value );
      bool needNewLock = true;
      for( uint32 i = 0 ; i< addressTimeLock[_to].lockList.length; i ++ ){
          if( addressTimeLock[_to].lockList[i].time < now ){
              addressTimeLock[_to].lockList[i].time = _lockTime;
              addressTimeLock[_to].lockList[i].amount = _value;
              emit TransferWithLockEvt( msg.sender,_to,_value,_lockTime );
              needNewLock = false;
              break;
          }
      }
      if( needNewLock == true ){
           
          addressTimeLock[_to].lockList.length ++ ;
          addressTimeLock[_to].lockList[(addressTimeLock[_to].lockList.length-1)].time = _lockTime;
          addressTimeLock[_to].lockList[(addressTimeLock[_to].lockList.length-1)].amount = _value;
          emit TransferWithLockEvt( msg.sender,_to,_value,_lockTime);
      }
  }
  function setLockAdmin(address _to,bool canUse)public onlyOwner{
      assert( lockAdminList[_to] != canUse );
      lockAdminList[_to] = canUse;
  }
  function canUseLock()  public view returns (bool){
      return lockAdminList[msg.sender];
  }

}