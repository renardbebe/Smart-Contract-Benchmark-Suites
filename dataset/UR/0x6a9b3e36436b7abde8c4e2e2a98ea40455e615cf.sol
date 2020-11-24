 

pragma solidity ^0.4.24;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "msg.sender is not owner"
    );
    _;
  }

   
  function transferOwnership(address newOwner)
    public
    onlyOwner
    returns (bool)
  {
    if (newOwner != address(0) && newOwner != owner) {
      owner = newOwner;
      return true;
    } else {
      return false;
    }
  }
}

 
contract ERC20Basic {
  uint public _totalSupply;
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(
    address owner,
    address spender) public view returns (uint);
  function transferFrom(
    address from,
    address to,
    uint value
  )
    public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 

contract WhiteList is Ownable {
  mapping(address => bool) public whitelist;

  function addToWhitelist (address _address) public onlyOwner returns (bool) {
    whitelist[_address] = true;
    return true;
  }

  function removeFromWhitelist (address _address)
    public onlyOwner returns (bool) 
  {
    whitelist[_address] = false;
    return true;
  }
}

 
contract BasicToken is WhiteList, ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) public balances;

   
  uint public basisPointsRate = 0;
  uint public maximumFee = 0;

   
  modifier onlyPayloadSize(uint size) {
    require(
      !(msg.data.length < size + 4),
      "msg.data length is wrong"
    );
    _;
  }

   
  function transfer(address _to, uint _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    uint fee = whitelist[msg.sender]
      ? 0
      : (_value.mul(basisPointsRate)).div(10000);

    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint sendAmount = _value.sub(fee);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      emit Transfer(msg.sender, owner, fee);
      return true;
    }
    emit Transfer(msg.sender, _to, sendAmount);
    return true;
  }

     
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 { 

  mapping (address => mapping (address => uint)) public allowed;

  uint public constant MAX_UINT = 2**256 - 1;

   
  function transferFrom(
    address _from,
    address _to,
    uint
    _value
  )
    public
    onlyPayloadSize(3 * 32)
    returns (bool)
  {
    uint _allowance = allowed[_from][msg.sender];

     
     

    uint fee = whitelist[msg.sender]
      ? 0
      : (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }
    uint sendAmount = _value.sub(fee);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      emit Transfer(_from, owner, fee);
      return true;
    }
    emit Transfer(_from, _to, sendAmount);
    return true;
  }

   
  function approve(
    address _spender,
    uint _value
  )
    public
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
     
     
     
     
    require(
      !((_value != 0) && (allowed[msg.sender][_spender] != 0)),
      "Canont approve 0 as amount"
    );

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint remaining) 
  {
    return allowed[_owner][_spender];
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "paused is true");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "paused is false");
    _;
  }

   
  function pause()
    public
    onlyOwner
    whenNotPaused
    returns (bool) 
  {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause()
    public
    onlyOwner
    whenPaused
    returns (bool)
  {
    paused = false;
    emit Unpause();
    return true;
  }
}

 
contract BlackList is Ownable, BasicToken {

  mapping (address => bool) public isBlackListed;

  event DestroyedBlackFunds(address _blackListedUser, uint _balance);
  event AddedBlackList(address _user);
  event RemovedBlackList(address _user);

   
  function addBlackList (address _evilUser)
    public
    onlyOwner
    returns (bool)
  {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
    return true;
  }

   
  function removeBlackList (address _clearedUser)
    public
    onlyOwner
    returns (bool)
  {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
    return true;
  }

   
  function destroyBlackFunds (address _blackListedUser)
    public
    onlyOwner
    returns (bool)
  {
    require(isBlackListed[_blackListedUser], "User is not blacklisted");
    uint dirtyFunds = balanceOf(_blackListedUser);
    balances[_blackListedUser] = 0;
    _totalSupply -= dirtyFunds;
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    return true;
  }
}

 
contract UpgradedStandardToken is StandardToken{
   
  function transferByLegacy(
    address from,
    address to,
    uint value) public returns (bool);
  function transferFromByLegacy(
    address sender,
    address from,
    address spender,
    uint value) public returns (bool);

  function approveByLegacy(
    address from,
    address spender,
    uint value) public returns (bool);
}

 
contract BackedToken is Pausable, StandardToken, BlackList {

  string public name;
  string public symbol;
  uint public decimals;
  address public upgradedAddress;
  bool public deprecated;

   
  event Issue(uint amount);
   
  event Redeem(uint amount);
   
  event Deprecate(address newAddress);
   
  event Params(uint feeBasisPoints, uint maxFee);

   
  constructor (
    uint _initialSupply,
    string _name,
    string _symbol,
    uint _decimals
  ) public {
    _totalSupply = _initialSupply;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    balances[owner] = _initialSupply;
    deprecated = false;
  }

   
  function() public payable {
    revert("No specific function has been called");
  }

   

  function transfer(address _to, uint _value)
    public whenNotPaused returns (bool) 
  {
    require(
      !isBlackListed[msg.sender],
      "Transaction recipient is blacklisted"
    );
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
    } else {
      return super.transfer(_to, _value);
    }
  }

  function transferFrom(
    address _from,
    address _to,
    uint _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(!isBlackListed[_from], "Tokens owner is blacklisted");
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
        msg.sender,
        _from,
        _to,
        _value
      );
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

  function balanceOf(address who) public view returns (uint) {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).balanceOf(who);
    } else {
      return super.balanceOf(who);
    }
  }

  function approve(
    address _spender,
    uint _value
  ) 
    public
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
    } else {
      return super.approve(_spender, _value);
    }
  }

  function allowance(
    address _owner,
    address _spender
  )
    public
    view
    returns (uint remaining) 
  {
    if (deprecated) {
      return StandardToken(upgradedAddress).allowance(_owner, _spender);
    } else {
      return super.allowance(_owner, _spender);
    }
  }

  function totalSupply() public view returns (uint) {
    if (deprecated) {
      return StandardToken(upgradedAddress).totalSupply();
    } else {
      return _totalSupply;
    }
  }

   
  function issue(uint amount)
    public
    onlyOwner
    returns (bool)
  {
    require(
      _totalSupply + amount > _totalSupply,
      "Wrong amount to be issued referring to _totalSupply"
    );

    require(
      balances[owner] + amount > balances[owner],
      "Wrong amount to be issued referring to owner balance"
    );

    balances[owner] += amount;
    _totalSupply += amount;
    emit Issue(amount);
    return true;
  }

   
  function redeem(uint amount)
    public
    onlyOwner
    returns (bool)
  {
    require(
      _totalSupply >= amount,
      "Wrong amount to be redeemed referring to _totalSupply"
    );
    require(
      balances[owner] >= amount,
      "Wrong amount to be redeemed referring to owner balance"
    );
    _totalSupply -= amount;
    balances[owner] -= amount;
    emit Redeem(amount);
    return true;
  }

   
  function deprecate(address _upgradedAddress)
    public
    onlyOwner
    returns (bool)
  {
    deprecated = true;
    upgradedAddress = _upgradedAddress;
    emit Deprecate(_upgradedAddress);
    return true;
  }

   
  function setParams(
    uint newBasisPoints,
    uint newMaxFee
  ) 
    public
    onlyOwner 
    returns (bool) 
  {
     
    require(
      newBasisPoints < 20,
      "newBasisPoints amount bigger than hardcoded limit"
    );
    require(
      newMaxFee < 50,
      "newMaxFee amount bigger than hardcoded limit"
    );
    basisPointsRate = newBasisPoints;
    maximumFee = newMaxFee.mul(10**decimals);
    emit Params(basisPointsRate, maximumFee);
    return true;
  }

   
  function kill()
    public
    onlyOwner 
  {
    selfdestruct(owner);
  }
}