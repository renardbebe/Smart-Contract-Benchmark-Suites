 

pragma solidity ^0.4.19;

 
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



contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }
  
  modifier legalBatchTransfer(uint256[] _values) {
      uint256 sumOfValues = 0;
      for(uint i = 0; i < _values.length; i++) {
          sumOfValues = sumOfValues.add(_values[i]);
      }
      if(sumOfValues.mul(10 ** 8) > balanceOf(msg.sender)) {
          revert();
      }
      _;
  }
  
  function multiValueBatchTransfer(address[] _recipients, uint256[] _values) public legalBatchTransfer(_values) returns(bool){
      require(_recipients.length == _values.length && _values.length <= 100);
      for(uint i = 0; i < _recipients.length; i++) {
        balances[msg.sender] = balances[msg.sender].sub(_values[i].mul(10 ** 8));
        balances[_recipients[i]] = balances[_recipients[i]].add(_values[i].mul(10 ** 8));
        Transfer(msg.sender, _recipients[i], _values[i].mul(10 ** 8));
      }
      return true;
  }
  
  function singleValueBatchTransfer(address[] _recipients, uint256 _value) public returns(bool) {
      require(balanceOf(msg.sender) >= _recipients.length.mul(_value.mul(10 ** 8)));
      for(uint i = 0; i < _recipients.length; i++) {
        balances[msg.sender] = balances[msg.sender].sub(_value.mul(10 ** 8));
        balances[_recipients[i]] = balances[_recipients[i]].add(_value.mul(10 ** 8));
        Transfer(msg.sender, _recipients[i], _value.mul(10 ** 8));
      }
      return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract SHNZ2 is StandardToken {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    function SHNZ2() {
        name = "Shizzle Nizzle 2";
        symbol = "SHNZ2";
        decimals = 8;
        totalSupply = 100000000000e8;
        balances[0x7e826E85CbA4d3AAaa1B484f53BE01D10F527Fd6] = totalSupply;
        Transfer(address(this), 0x7e826E85CbA4d3AAaa1B484f53BE01D10F527Fd6, totalSupply);
    }
}