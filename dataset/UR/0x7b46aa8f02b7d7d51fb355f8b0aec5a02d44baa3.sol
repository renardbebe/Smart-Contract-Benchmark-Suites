 

pragma solidity ^0.4.2;

 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    function checkPrice() public returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_to != address(0) && balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (_to != address(0) && balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

 
contract SafeMath {
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


 
 
contract TestCoin is StandardToken, SafeMath {

     
    string constant public name = "TestCoin";
    string constant public symbol = "TEST234124";
    uint8 constant public decimals = 3;

    uint public price = 50 szabo;
    uint public priceUpdatedTime;

    address public feeAddress = 0x212fbd2077ab9681f0a6DE03ab15951B8D083E6c;

     
     
     
    function fund()
      public
      payable 
      returns (bool)
    {
      checkPrice();
      
      uint tokenCount = msg.value / price;
      uint investment = tokenCount * price;

      balances[msg.sender] += tokenCount;
      Issuance(msg.sender, tokenCount);
      totalSupply += tokenCount;

      if (msg.value > investment) {
        msg.sender.transfer(msg.value - investment);
      }
      return true;
    }

    function withdraw(uint tokenCount)
      public
      returns (bool)
    {
      checkPrice();
      if (balances[msg.sender] >= tokenCount) {
        uint tokensValue = tokenCount * price;
        balances[msg.sender] -= tokenCount;
        totalSupply -= tokenCount;
        uint fee = tokensValue / 5;
        uint withdrawal = fee * 4;
        feeAddress.transfer(fee);
        msg.sender.transfer(withdrawal);
        return true;
      } else {
        return false;
      }
    }
     
    function checkPrice() public returns (uint256)
    {
      uint timeSinceLastUpdate = now - priceUpdatedTime;
        if((now - timeSinceLastUpdate) > 1 minutes){
          priceUpdatedTime = now;
          price += price/50;
        }
        return price;
    }
    
     
    function TestCoin()
    {   
        priceUpdatedTime = now;
    }
}