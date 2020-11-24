 

pragma solidity ^0.4.21;

 
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
  function totalSupply() public constant returns (uint);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint size) {
      require(!(msg.data.length < (size * 32 + 4)));
      _;
  }

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
     
     
     
     
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}


contract UpgradedStandardToken is StandardToken {
   
   
  uint public _totalSupply;
  function transferByLegacy(address from, address to, uint value) public returns (bool);
  function transferFromByLegacy(address sender, address from, address spender, uint value) public returns (bool);
  function approveByLegacy(address from, address spender, uint value) public returns (bool);
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

contract StandardTokenWithFees is StandardToken, Ownable {

   
  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;
  uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
  uint256 constant MAX_SETTABLE_FEE = 50;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint public _totalSupply;

  uint public constant MAX_UINT = 2**256 - 1;

  function calcFee(uint _value) constant public returns (uint) {
    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    return fee;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    uint fee = calcFee(_value);
    uint sendAmount = _value.sub(fee);

    super.transfer(_to, sendAmount);
    if (fee > 0) {
      super.transfer(owner, fee);
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    uint fee = calcFee(_value);
    uint sendAmount = _value.sub(fee);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (allowed[_from][msg.sender] < MAX_UINT) {
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    }
    emit Transfer(_from, _to, sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      emit Transfer(_from, owner, fee);
    }
    return true;
  }

  function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
     
    require(newBasisPoints < MAX_SETTABLE_BASIS_POINTS);
    require(newMaxFee < MAX_SETTABLE_FEE);

    basisPointsRate = newBasisPoints;
    maximumFee = newMaxFee.mul(uint(10)**decimals);

    emit Params(basisPointsRate, maximumFee);
  }

   
  event Params(uint feeBasisPoints, uint maxFee);
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


contract BlackList is Ownable {

   
  function getBlackListStatus(address _maker) external constant returns (bool) {
    return isBlackListed[_maker];
  }

  mapping (address => bool) public isBlackListed;

  function addBlackList (address _evilUser) public onlyOwner {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList (address _clearedUser) public onlyOwner {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  event AddedBlackList(address indexed _user);

  event RemovedBlackList(address indexed _user);
}

contract ElementiumToken is Pausable, StandardTokenWithFees, BlackList {

  address public upgradedAddress;
  bool public deprecated;

   
   
   
   
   
   
   
  constructor(uint _initialSupply, string _name, string _symbol, uint8 _decimals) public {
    _totalSupply = _initialSupply;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    balances[owner] = _initialSupply;
    deprecated = false;
  }

   
  function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
    require(!isBlackListed[msg.sender]);
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
    } else {
      return super.transfer(_to, _value);
    }
  }

   
  function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
    require(!isBlackListed[_from]);
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

   
  function balanceOf(address who) public constant returns (uint) {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).balanceOf(who);
    } else {
      return super.balanceOf(who);
    }
  }

   
  function oldBalanceOf(address who) public constant returns (uint) {
    if (deprecated) {
      return super.balanceOf(who);
    }
  }

   
  function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
    } else {
      return super.approve(_spender, _value);
    }
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    if (deprecated) {
      return StandardToken(upgradedAddress).allowance(_owner, _spender);
    } else {
      return super.allowance(_owner, _spender);
    }
  }

   
  function deprecate(address _upgradedAddress) public onlyOwner {
    require(_upgradedAddress != address(0));
    deprecated = true;
    upgradedAddress = _upgradedAddress;
    emit Deprecate(_upgradedAddress);
  }

   
  function totalSupply() public constant returns (uint) {
    if (deprecated) {
      return StandardToken(upgradedAddress).totalSupply();
    } else {
      return _totalSupply;
    }
  }

   
   
   
   
  function issue(uint amount) public onlyOwner {
    balances[owner] = balances[owner].add(amount);
    _totalSupply = _totalSupply.add(amount);
    emit Issue(amount);
    emit Transfer(address(0), owner, amount);
  }

   
   
   
   
   
  function redeem(uint amount) public onlyOwner {
    _totalSupply = _totalSupply.sub(amount);
    balances[owner] = balances[owner].sub(amount);
    emit Redeem(amount);
    emit Transfer(owner, address(0), amount);
  }

  function destroyBlackFunds (address _blackListedUser) public onlyOwner {
    require(isBlackListed[_blackListedUser]);
    uint dirtyFunds = balanceOf(_blackListedUser);
    balances[_blackListedUser] = 0;
    _totalSupply = _totalSupply.sub(dirtyFunds);
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }

  event DestroyedBlackFunds(address indexed _blackListedUser, uint _balance);

   
  event Issue(uint amount);

   
  event Redeem(uint amount);

   
  event Deprecate(address newAddress);
}