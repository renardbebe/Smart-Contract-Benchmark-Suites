 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

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
    assert(b > 0);  
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

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

 

contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
 contract RflexCoin is StandardBurnableToken, PausableToken {
    using SafeMath for uint256;
    string public constant name = "Rflexcoin";
    string public constant symbol = "RFC";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals));

    struct lockedUserInfo{
        address lockedUserAddress;
        uint firstUnlockTime;
        uint secondUnlockTime;
        uint thirdUnlockTime;
        uint256 firstUnlockValue;
        uint256 secondUnlockValue;
        uint256 thirdUnlockValue;
    }

    mapping(address => lockedUserInfo) private lockedUserEntity;
    mapping(address => bool) private supervisorEntity;
    mapping(address => bool) private lockedWalletEntity;

    modifier onlySupervisor() {
        require(owner == msg.sender || supervisorEntity[msg.sender]);
        _;
    }

    event Unlock(
        address indexed lockedUser,
        uint lockPeriod,
        uint256 firstUnlockValue,
        uint256 secondUnlockValueUnlockValue,
        uint256 thirdUnlockValue
    );

    event PrintLog(
        address indexed sender,
        string _logName,
        uint256 _value
    );

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function transfer( address _to, uint256 _value ) public whenNotPaused returns (bool) {
        require(!isLockedWalletEntity(msg.sender));
        require(msg.sender != _to,"Check your address!!");

        uint256 availableValue = getAvailableWithdrawableCount(msg.sender, _value);
        emit PrintLog(_to, "availableResultValue", availableValue);
        require(availableValue > 0);

        return super.transfer(_to, availableValue);
    }

    function burn(uint256 _value) onlySupervisor public {
        super._burn(msg.sender, _value);
    }

    function transferToLockedBalance(
        address _to,
        uint _firstUnlockTime,
        uint256 _firstUnlockValue,
        uint _secondUnlockTime,
        uint256 _secondUnlockValue,
        uint _thirdUnlockTime,
        uint256 _thirdUnlockValue
    ) onlySupervisor whenNotPaused public returns (bool) {
        require(msg.sender != _to,"Check your address!!");
        require(_firstUnlockTime > now && _firstUnlockValue > 0, "Check your First input values!!;");

        uint256 totalLockSendCount = totalLockSendCount.add(_firstUnlockValue);

        if(_secondUnlockTime > now && _secondUnlockValue > 0){
            require(_secondUnlockTime > _firstUnlockTime, "Second Unlock time must be greater than First Unlock Time!!");

            totalLockSendCount = totalLockSendCount.add(_secondUnlockValue);
        }

        if(_thirdUnlockTime > now && _thirdUnlockValue > 0){
            require(_thirdUnlockTime > _secondUnlockTime && _secondUnlockTime > now &&  _secondUnlockValue > 0,
                    "Check your third Unlock Time or Second input values!!");
            totalLockSendCount = totalLockSendCount.add(_thirdUnlockValue);
        }

        if (transfer(_to, totalLockSendCount)) {
            lockedUserEntity[_to].lockedUserAddress = _to;
            lockedUserEntity[_to].firstUnlockTime = _firstUnlockTime;
            lockedUserEntity[_to].firstUnlockValue = _firstUnlockValue;

            if(_secondUnlockTime > now && _secondUnlockValue > 0){
                lockedUserEntity[_to].secondUnlockTime = _secondUnlockTime;
                lockedUserEntity[_to].secondUnlockValue = _secondUnlockValue;
            }

            if(_thirdUnlockTime > now && _thirdUnlockValue > 0){
                lockedUserEntity[_to].thirdUnlockTime  = _thirdUnlockTime;
                lockedUserEntity[_to].thirdUnlockValue = _thirdUnlockValue;
            }

            return true;
        }
    }

    function setLockTime(address _to, uint _time, uint256 _lockTime) onlySupervisor public returns(bool){
        require(_to !=address(0) && _time > 0 && _time < 4 && _lockTime > now);

        (   uint firstUnlockTime,
            uint secondUnlockTime,
            uint thirdUnlockTime
        ) = getLockedTimeUserInfo(_to);

        if(_time == 1 && firstUnlockTime !=0){
            if(secondUnlockTime ==0 || _lockTime < secondUnlockTime){
                lockedUserEntity[_to].firstUnlockTime = _lockTime;
                return true;
            }
        }else if(_time == 2 && secondUnlockTime !=0){
            if(_lockTime > firstUnlockTime && (thirdUnlockTime ==0 || _lockTime < thirdUnlockTime)){
                lockedUserEntity[_to].secondUnlockTime = _lockTime;
                return true;
            }
        }else if(_time == 3 && thirdUnlockTime !=0 && _lockTime > secondUnlockTime){
            lockedUserEntity[_to].thirdUnlockTime = _lockTime;
            return true;
        }
        return false;
    }

    function getLockedUserInfo(address _address) view public returns (uint,uint256,uint,uint256,uint,uint256){
        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);
        return (
                    lockedUserEntity[_address].firstUnlockTime,
                    lockedUserEntity[_address].firstUnlockValue,
                    lockedUserEntity[_address].secondUnlockTime,
                    lockedUserEntity[_address].secondUnlockValue,
                    lockedUserEntity[_address].thirdUnlockTime,
                    lockedUserEntity[_address].thirdUnlockValue
                );
    }

    function setSupervisor(address _address) onlyOwner public returns (bool){
        require(_address !=address(0) && !supervisorEntity[_address]);
        supervisorEntity[_address] = true;
        emit PrintLog(_address, "isSupervisor",  1);
        return true;
    }

    function removeSupervisor(address _address) onlyOwner public returns (bool){
        require(_address !=address(0) && supervisorEntity[_address]);
        delete supervisorEntity[_address];
        emit PrintLog(_address, "isSupervisor",  0);
        return true;
    }

    function setLockedWalletEntity(address _address) onlySupervisor public returns (bool){
        require(_address !=address(0) && !lockedWalletEntity[_address]);
        lockedWalletEntity[_address] = true;
        emit PrintLog(_address, "isLockedWalletEntity",  1);
        return true;
    }

    function removeLockedWalletEntity(address _address) onlySupervisor public returns (bool){
        require(_address !=address(0) && lockedWalletEntity[_address]);
        delete lockedWalletEntity[_address];
        emit PrintLog(_address, "isLockedWalletEntity",  0);
        return true;
    }

    function getLockedTimeUserInfo(address _address) view private returns (uint,uint,uint){
        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);
        return (
                    lockedUserEntity[_address].firstUnlockTime,
                    lockedUserEntity[_address].secondUnlockTime,
                    lockedUserEntity[_address].thirdUnlockTime
                );
    }

    function isSupervisor() view onlyOwner private returns (bool){
        return supervisorEntity[msg.sender];
    }

    function isLockedWalletEntity(address _from) view private returns (bool){
        return lockedWalletEntity[_from];
    }

    function getAvailableWithdrawableCount( address _from , uint256 _sendOrgValue) private returns (uint256) {
        uint256 availableValue = 0;

        if(lockedUserEntity[_from].lockedUserAddress == address(0)){
            availableValue = _sendOrgValue;
        }else{
                (
                    uint firstUnlockTime, uint256 firstUnlockValue,
                    uint secondUnlockTime, uint256 secondUnlockValue,
                    uint thirdUnlockTime, uint256 thirdUnlockValue
                ) = getLockedUserInfo(_from);

                if(now < firstUnlockTime) {
                    availableValue = balances[_from].sub(firstUnlockValue.add(secondUnlockValue).add(thirdUnlockValue));
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                    }
                }else if(firstUnlockTime <= now && secondUnlockTime ==0){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 1, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(firstUnlockTime <= now && secondUnlockTime !=0 && now < secondUnlockTime){
                    availableValue = balances[_from].sub(secondUnlockValue.add(thirdUnlockValue));
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                        lockedUserEntity[_from].firstUnlockValue = 0;
                        emit Unlock(_from, 1, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(secondUnlockTime !=0 && secondUnlockTime <= now && thirdUnlockTime ==0){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue =_sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 2, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(secondUnlockTime !=0 && secondUnlockTime <= now && thirdUnlockTime !=0 && now < thirdUnlockTime){
                    availableValue = balances[_from].sub(thirdUnlockValue);
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                        lockedUserEntity[_from].firstUnlockValue = 0;
                        lockedUserEntity[_from].secondUnlockValue = 0;
                        emit Unlock(_from, 2, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(thirdUnlockTime !=0 && thirdUnlockTime <= now){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else if(_sendOrgValue <= availableValue){
                        availableValue = _sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 3, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }
        }
        return availableValue;
    }

}