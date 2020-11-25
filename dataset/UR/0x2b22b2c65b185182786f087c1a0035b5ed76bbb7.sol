 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

contract Ethernity is StandardToken {
  string public constant name = "ETHerNity";  
  string public constant symbol = "ETY";  
  uint8 public constant decimals = 18;  

  address owner;
  mapping(address => uint) lastDate;

  constructor() public {
    owner = msg.sender;
  }

  function() public payable {
    payWithReferrer(owner);
  }

  function payWithReferrer(address _addr) public payable {
    if (_addr == owner || balances[_addr] == 0 || _addr == msg.sender)
      owner.transfer(msg.value / 5);
    else {
      owner.transfer(msg.value / 10);
      _addr.transfer(msg.value / 10);
    }
    lastDate[msg.sender] = now;

    totalSupply_ = totalSupply_.add(msg.value);
    balances[msg.sender] = balances[msg.sender].add(msg.value / 30);
  }

  function withdraw() public returns(bool) {
    return withdrawFrom(msg.sender);
  }

  function withdrawFrom(address _addr) internal returns(bool) {
    bool result =  _addr.send( balanceToWithdraw() );
    lastDate[_addr] = now;
    return result;
  }
    
  function balanceToWithdraw() public view returns(uint) {
    return balanceToWithdrawFrom(msg.sender);
  }

  function balanceToWithdrawFrom(address _addr) internal view returns(uint) {
    if (lastDate[_addr] > 0)
      return balances[_addr].mul((now - lastDate[_addr]) / 1 days);
    else
      return 0;
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
      withdraw();
      withdrawFrom(_to);
      return BasicToken.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    withdrawFrom(_from);
    withdrawFrom(_to);
    return StandardToken.transferFrom(_from, _to, _value);
  }
}