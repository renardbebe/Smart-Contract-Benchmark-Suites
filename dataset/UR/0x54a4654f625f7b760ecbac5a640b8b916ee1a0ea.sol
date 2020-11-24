 

 

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




 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
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


 
contract Burnable is StandardToken {

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


 
contract Ownable is Burnable {

  address public owner;
  address public ownerCandidate;

   
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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    ownerCandidate = _newOwner;
  }

   
  function acceptOwnership() public {
    _acceptOwnership();
  }

   
  function _acceptOwnership() internal {
    require(msg.sender == ownerCandidate);
    emit OwnershipTransferred(owner, ownerCandidate);
    owner = ownerCandidate;
    ownerCandidate = address(0);
  }

   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }

}

 

pragma solidity ^0.4.24;



 
contract Administrable is Ownable {

  using SafeERC20 for ERC20Basic;
  
   
  mapping (address => bool) admins;

   
  address[] adminAudit;

   
  bool allowAdmins = true;

    
  event AdminAdded(address addedBy, address admin);

   
  event AdminRemoved(address removedBy, address admin);

   
  modifier onlyAdmin {
    require(isCurrentAciveAdmin(msg.sender));
    _;
  }

   
  function enableAdmins() public onlyOwner {
    require(allowAdmins == false);
    allowAdmins = true;
  }

   
  function disableAdmins() public onlyOwner {
    require(allowAdmins);
    allowAdmins = false;
  }

   
  function isCurrentAdmin(address _address) public view returns (bool) {
    if(_address == owner)
      return true;
    else
      return admins[_address];
  }

   
  function isCurrentAciveAdmin(address _address) public view returns (bool) {
    if(_address == owner)
      return true;
    else
      return allowAdmins && admins[_address];
  }

   
  function isCurrentOrPastAdmin(address _address) public view returns (bool) {
    for (uint256 i = 0; i < adminAudit.length; i++)
      if (adminAudit[i] == _address)
        return true;
    return false;
  }

   
  function addAdmin(address _address) public onlyOwner {
    require(admins[_address] == false);
    admins[_address] = true;
    emit AdminAdded(msg.sender, _address);
    adminAudit.length++;
    adminAudit[adminAudit.length - 1] = _address;
  }

   
  function removeAdmin(address _address) public onlyOwner {
    require(_address != msg.sender);
    require(admins[_address]);
    admins[_address] = false;
    emit AdminRemoved(msg.sender, _address);
  }

   
  function reclaimToken(ERC20Basic _token) external onlyAdmin {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(msg.sender, balance);
  }

}

 

pragma solidity ^0.4.24;


 
contract Pausable is Administrable {
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

   
  function pause() public onlyAdmin whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyAdmin whenPaused {
    paused = false;
    emit Unpause();
  }

}

 

pragma solidity ^0.4.24;


contract Rento is Pausable {

  using SafeMath for uint256;

  string public name = "Rento";
  string public symbol = "RTO";
  uint8 public decimals = 8;

   
  uint256 public constant UNIT      = 100000000;

  uint256 constant INITIAL_SUPPLY   = 600000000 * UNIT;

  uint256 constant SALE_SUPPLY      = 264000000 * UNIT;
  uint256 internal SALE_SENT        = 0;

  uint256 constant OWNER_SUPPLY     = 305000000 * UNIT;
  uint256 internal OWNER_SENT       = 0;

  uint256 constant BOUNTY_SUPPLY    = 6000000 * UNIT;
  uint256 internal BOUNTY_SENT      = 0;

  uint256 constant ADVISORS_SUPPLY  = 25000000 * UNIT;
  uint256 internal ADVISORS_SENT    = 0;

  struct Stage {
     uint8 cents;
     uint256 limit;
  } 

  Stage[] stages;

   
  mapping(uint => uint256) rates;

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    stages.push(Stage( 2, 0));
    stages.push(Stage( 6, 26400000 * UNIT));
    stages.push(Stage( 6, 52800000 * UNIT));
    stages.push(Stage(12, 158400000 * UNIT));
    stages.push(Stage(12, SALE_SUPPLY));
  }


   
  function sellWithCents(address _to, uint256 _value) public
    onlyAdmin whenNotPaused
    returns (bool success) {
      return _sellWithCents(_to, _value);
  }

   
  function sellWithCentsArray(address[] _dests, uint256[] _values) public
    onlyAdmin whenNotPaused
    returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++)
        if(!_sellWithCents(_dests[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }

   
  function _sellWithCents(address _to, uint256 _value) internal
    onlyAdmin whenNotPaused
    returns (bool) {
      require(_to != address(0) && _value > 0);
      uint256 tokens_left = 0;
      uint256 tokens_right = 0;
      uint256 price_left = 0;
      uint256 price_right = 0;
      uint256 tokens;
      uint256 i_r = 0;
      uint256 i = 0;
      while (i < stages.length) {
        if(SALE_SENT >= stages[i].limit) {
          if(i == stages.length-1) {
            i_r = i;
          } else {
            i_r = i + 1;
          }
          price_left = uint(stages[i].cents);
          price_right = uint(stages[i_r].cents);
        }
        i += 1;
      }
      if(price_left <= 0) {
        revert();
        return false;
      }
      tokens_left = _value.mul(UNIT).div(price_left);
      if(SALE_SENT.add(tokens_left) <= stages[i_r].limit) {
        tokens = tokens_left;
      } else {
        tokens_left = stages[i_r].limit.sub(SALE_SENT);
        tokens_right = UNIT.mul(_value.sub((tokens_left.mul(price_left)).div(UNIT))).div(price_right);
      }
      tokens = tokens_left.add(tokens_right);
      if(SALE_SENT.add(tokens) > SALE_SUPPLY) {
        revert();
        return false;
      }
      balances[_to] = balances[_to].add(tokens);
      SALE_SENT = SALE_SENT.add(tokens);
      emit Transfer(this, _to, tokens);
      return true;
  }

   
  function sellDirect(address _to, uint256 _value) public
    onlyAdmin whenNotPaused
      returns (bool success) {
        require(_to != address(0) && _value > 0 && SALE_SENT.add(_value) <= SALE_SUPPLY);
        balances[_to] = balances[_to].add(_value);
        SALE_SENT = SALE_SENT.add(_value);
        emit Transfer(this, _to, _value);
        return true;
  }

   
  function sellDirectArray(address[] _dests, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++) {
         if(_values[i] <= 0 || !sellDirect(_dests[i], _values[i])) {
            revert();
            return false;
         }
      }
      return true;
  }


   
  function transferOwnerTokens(uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_value > 0 && OWNER_SENT.add(_value) <= OWNER_SUPPLY);
      balances[owner] = balances[owner].add(_value);
      OWNER_SENT = OWNER_SENT.add(_value);
      emit Transfer(this, owner, _value);
      return true;
  }

   
  function transferBountyTokens(address _to, uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to != address(0) && _value > 0 && BOUNTY_SENT.add(_value) <= BOUNTY_SUPPLY);
      balances[_to] = balances[_to].add(_value);
      BOUNTY_SENT = BOUNTY_SENT.add(_value);
      emit Transfer(this, _to, _value);
      return true;
  }

   
  function transferBountyTokensArray(address[] _to, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to.length == _values.length);
      for (uint32 i = 0; i < _to.length; i++)
        if(!transferBountyTokens(_to[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }
    
   
  function transferAdvisorsTokens(address _to, uint256 _value) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to != address(0) && _value > 0 && ADVISORS_SENT.add(_value) <= ADVISORS_SUPPLY);
      balances[_to] = balances[_to].add(_value);
      ADVISORS_SENT = ADVISORS_SENT.add(_value);
      emit Transfer(this, _to, _value);
      return true;
  }
    
   
  function transferAdvisorsTokensArray(address[] _to, uint256[] _values) public
    onlyAdmin whenNotPaused returns (bool success) {
      require(_to.length == _values.length);
      for (uint32 i = 0; i < _to.length; i++)
        if(!transferAdvisorsTokens(_to[i], _values[i])) {
          revert();
          return false;
        }
      return true;
  }

   
  function soldTokensSent() external view returns (uint256) {
    return SALE_SENT;
  }
  function soldTokensAvailable() external view returns (uint256) {
    return SALE_SUPPLY.sub(SALE_SENT);
  }

  function ownerTokensSent() external view returns (uint256) {
    return OWNER_SENT;
  }
  function ownerTokensAvailable() external view returns (uint256) {
    return OWNER_SUPPLY.sub(OWNER_SENT);
  }

  function bountyTokensSent() external view returns (uint256) {
    return BOUNTY_SENT;
  }
  function bountyTokensAvailable() external view returns (uint256) {
    return BOUNTY_SUPPLY.sub(BOUNTY_SENT);
  }

  function advisorsTokensSent() external view returns (uint256) {
    return ADVISORS_SENT;
  }
  function advisorsTokensAvailable() external view returns (uint256) {
    return ADVISORS_SUPPLY.sub(ADVISORS_SENT);
  }

   
  function transferArray(address[] _dests, uint256[] _values) public returns (bool success) {
      require(_dests.length == _values.length);
      for (uint32 i = 0; i < _dests.length; i++) {
        if(_values[i] > balances[msg.sender] || msg.sender == _dests[i] || _dests[i] == address(0)) {
          revert();
          return false;
        }
        balances[msg.sender] = balances[msg.sender].sub(_values[i]);
        balances[_dests[i]] = balances[_dests[i]].add(_values[i]);
        emit Transfer(msg.sender, _dests[i], _values[i]);
      }
      return true;
  }

}