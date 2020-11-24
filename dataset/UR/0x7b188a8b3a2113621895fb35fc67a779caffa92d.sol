 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
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

contract QOSToken is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalFrozen;
    uint256 internal unlockedAt;
    mapping(address => uint256) frozenAccount;

    address internal sellerAddr = 0x0091426938dFb8F5052F790C4bC40F65eA4aF456;
    address internal prvPlacementAddr = 0x00B76C436e0784501012e2c436b54c1DA4E82434;
    address internal communitAddr = 0x00e0916090A85258fb645d58E654492361a853fe;
    address internal develAddr = 0x0077779160989a61A24ee7D1ed0f87d217e1d30C;
    address internal fundationAddr = 0x00879858d5ed1Cf4082C1f58064565B0633A3b97;
    address internal teamAddr = 0x008A3fA7815daBbc02d7517BA083f19D5d6d2aBB;


    event Frozen(address indexed from, uint256 value);
    event UnFrozen(address indexed from, uint256 value);

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        uint256 decimalValue = 10 ** uint256(decimals);
        totalSupply_ = SafeMath.mul(4900000000, decimalValue);
        unlockedAt = now + 12 * 30 days;

        balances[sellerAddr] = SafeMath.mul(500000000, decimalValue);  
        balances[prvPlacementAddr] = SafeMath.mul(500000000, decimalValue); 
        balances[communitAddr] = SafeMath.mul(500000000, decimalValue); 
        balances[develAddr] = SafeMath.mul(900000000, decimalValue); 
        balances[fundationAddr] = SafeMath.mul(1500000000, decimalValue);  

        emit Transfer(this, sellerAddr, balances[sellerAddr]);
        emit Transfer(this, prvPlacementAddr, balances[prvPlacementAddr]);
        emit Transfer(this, communitAddr, balances[communitAddr]);
        emit Transfer(this, develAddr, balances[develAddr]);
        emit Transfer(this, fundationAddr, balances[fundationAddr]);

        frozenAccount[teamAddr] = SafeMath.mul(1000000000, decimalValue);  
        totalFrozen = frozenAccount[teamAddr];
        emit Frozen(teamAddr, totalFrozen);
    }

    function unFrozen() external {
        require(now > unlockedAt);
        require(msg.sender == teamAddr);

        uint256 frozenBalance = frozenAccount[msg.sender];
        require(frozenBalance > 0);

        uint256 nmonth = SafeMath.div(now - unlockedAt, 30 * 1 days) + 1;
        if (nmonth > 23) {
            balances[msg.sender] += frozenBalance;
            frozenAccount[msg.sender] = 0;
            emit UnFrozen(msg.sender, frozenBalance);
            return;
        }

         
        uint256 decimalValue = 10 ** uint256(decimals);
        uint256 oneMonthBalance = SafeMath.mul(4166666, decimalValue);
        uint256 unfrozenBalance = SafeMath.mul(nmonth, oneMonthBalance);
        frozenAccount[msg.sender] = totalFrozen - unfrozenBalance;
        uint256 toTransfer = frozenBalance - frozenAccount[msg.sender];

        require(toTransfer > 0);
        balances[msg.sender] += toTransfer;
        emit UnFrozen(msg.sender, toTransfer);
    }
}