 

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

 

 

 contract RING is StandardBurnableToken, PausableToken {

     

    using SafeMath for uint256;

    string public constant name = "RING X PLATFORM TOKEN";

    string public constant symbol = "RINGX";

    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals));

    uint constant LOCK_TOKEN_COUNT = 1000;

    

    struct LockedUserInfo{

        uint256 _releaseTime;

        uint256 _amount;

    }

 

    mapping(address => LockedUserInfo[]) private lockedUserEntity;

    mapping(address => bool) private supervisorEntity;

    mapping(address => bool) private lockedWalletEntity;

 

    modifier onlySupervisor() {

        require(owner == msg.sender || supervisorEntity[msg.sender]);

        _;

    }

 

    event Lock(address indexed holder, uint256 value, uint256 releaseTime);

    event Unlock(address indexed holder, uint256 value);

 

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

    

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {

        require(!isLockedWalletEntity(msg.sender));

        require(msg.sender != to,"Check your address!!");

        

        if (lockedUserEntity[msg.sender].length > 0 ) {

            _autoUnlock(msg.sender);            

        }

        return super.transfer(to, value);

    }

 

    function transferFrom(address from, address to, uint256 value) public whenNotPaused  returns (bool) {

        require(!isLockedWalletEntity(from) && !isLockedWalletEntity(msg.sender));

        if (lockedUserEntity[from].length > 0) {

            _autoUnlock(from);            

        }

        return super.transferFrom(from, to, value);

    }

    

    function transferWithLock(address holder, uint256 value, uint256 releaseTime) public onlySupervisor whenNotPaused returns (bool) {

        require(releaseTime > now && value > 0, "Check your values!!;");

        if(lockedUserEntity[holder].length >= LOCK_TOKEN_COUNT){

            return false;

        }

        transfer(holder, value);

        _lock(holder,value,releaseTime);

        return true;

    }

      

    function _lock(address holder, uint256 value, uint256 releaseTime) internal returns(bool) {

        balances[holder] = balances[holder].sub(value);

        lockedUserEntity[holder].push( LockedUserInfo(releaseTime, value) );

        

        emit Lock(holder, value, releaseTime);

        return true;

    }

    

    function _unlock(address holder, uint256 idx) internal returns(bool) {

        LockedUserInfo storage lockedUserInfo = lockedUserEntity[holder][idx];

        uint256 releaseAmount = lockedUserInfo._amount;

 

        delete lockedUserEntity[holder][idx];

        lockedUserEntity[holder][idx] = lockedUserEntity[holder][lockedUserEntity[holder].length.sub(1)];

        lockedUserEntity[holder].length -=1;

        

        emit Unlock(holder, releaseAmount);

        balances[holder] = balances[holder].add(releaseAmount);

        

        return true;

    }

    

    function _autoUnlock(address holder) internal returns(bool) {

        for(uint256 idx =0; idx < lockedUserEntity[holder].length ; idx++ ) {

            if (lockedUserEntity[holder][idx]._releaseTime <= now) {

                 

                if( _unlock(holder, idx) ) {

                    idx -=1;

                }

            }

        }

        return true;

    } 

    

    function setLockTime(address holder, uint idx, uint256 releaseTime) onlySupervisor public returns(bool){

        require(holder !=address(0) && idx >= 0 && releaseTime > now);

        require(lockedUserEntity[holder].length >= idx);

         

        lockedUserEntity[holder][idx]._releaseTime = releaseTime;

        return true;

    }

    

    function getLockedUserInfo(address _address) view public returns (uint256[], uint256[]){

        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);

        uint256[] memory _returnAmount = new uint256[](lockedUserEntity[_address].length);

        uint256[] memory _returnReleaseTime = new uint256[](lockedUserEntity[_address].length);

        

        for(uint i = 0; i < lockedUserEntity[_address].length; i ++){

            _returnAmount[i] = lockedUserEntity[_address][i]._amount;

            _returnReleaseTime[i] = lockedUserEntity[_address][i]._releaseTime;

        }

        return (_returnAmount, _returnReleaseTime);

    }

    

    function burn(uint256 _value) onlySupervisor public {

        super._burn(msg.sender, _value);

    }

    

    function burnFrom(address _from, uint256 _value) onlySupervisor public {

        super.burnFrom(_from, _value);

    }

    

    function balanceOf(address owner) public view returns (uint256) {

        

        uint256 totalBalance = super.balanceOf(owner);

        if( lockedUserEntity[owner].length >0 ){

            for(uint i=0; i<lockedUserEntity[owner].length;i++){

                totalBalance = totalBalance.add(lockedUserEntity[owner][i]._amount);

            }

        }

        

        return totalBalance;

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

 

    function isSupervisor(address _address) view onlyOwner public returns (bool){

        return supervisorEntity[_address];

    }

 

    function isLockedWalletEntity(address _from) view private returns (bool){

        return lockedWalletEntity[_from];

    }

 

}