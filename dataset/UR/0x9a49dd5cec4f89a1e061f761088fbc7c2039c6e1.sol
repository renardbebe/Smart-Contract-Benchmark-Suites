 

pragma solidity ^0.4.13;

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract APRInflationToken is StandardToken, Ownable {
   
  uint256 constant RATE_DECIMALS = 7;
  uint256 constant HORIZON = 365 * 10;
  uint256 constant ONE_DAY = 86400;
  uint256 constant DAY_SCALE = 365 * 10 ** RATE_DECIMALS;
  uint256 constant START_RATE = 10 * 10 ** (RATE_DECIMALS - 2);
  uint256 constant END_RATE = 1 * 10 ** (RATE_DECIMALS - 2);
  uint256 constant ADJ_RATE = (START_RATE - END_RATE) / HORIZON;

   
  uint256 public startDate;
  uint256 public lastAdjust;

   

  event APRMintAdjusted(uint256 _newSupply, uint256 _extraSupply, uint256 _daysPassed, uint256 _rate);

   

   
  function APRInflationToken(uint _startDate) public {
    startDate = _startDate;
    lastAdjust = 0;
  }

   

   
  function aprMintAdjustment() public returns (bool) {
    uint256 extraSupply;
    uint256 day;

    for (day = lastAdjust + 1; day <= _currentDay(); day++) {
      uint256 rate = _rateFromDay(day);
      extraSupply = totalSupply_.mul(rate).div(DAY_SCALE);
      totalSupply_ = totalSupply_.add(extraSupply);
      balances[owner] = balances[owner].add(extraSupply);
       
      lastAdjust = day;
      APRMintAdjusted(totalSupply_, extraSupply, lastAdjust, rate);
    }

    return true;
  }

  function _safeSub(uint256 a, uint256 b) internal pure returns(uint256) {
    return b > a ? 0 : a.sub(b);
  }

   
  function _rateFromDay(uint256 day) internal pure returns(uint256) {
    if (day < 1) {
      return 0;
    }

    uint256 rate = _safeSub(START_RATE, (day.sub(1)).mul(ADJ_RATE));
    return END_RATE > rate ? END_RATE : rate;
  }

   
   
  function _currentDay() internal view returns(uint256) {
    return now.sub(startDate).div(ONE_DAY);
  }
}

contract DelegateCallToken is APRInflationToken {
  string public name    = 'DelegateCallToken';
  string public symbol  = 'DCT';
  uint8 public decimals = 18;

   
  uint256 public constant INITIAL_SUPPLY = 1000000000;

  function DelegateCallToken(uint256 _startDate) public
    APRInflationToken(_startDate)
  {
    owner = msg.sender;
    totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
    balances[owner] = totalSupply_;
  }
}