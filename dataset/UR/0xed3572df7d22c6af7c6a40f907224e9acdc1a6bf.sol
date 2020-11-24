 

pragma solidity ^0.4.2;

 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
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
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
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
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
 
contract eXtremehoDLCoin is StandardToken, SafeMath {

     
    string constant public name = "eXtreme hoDL Coin";
    string constant public symbol = "XDL";
    uint8 constant public decimals = 0;
    
    uint private init_sellPrice = 2 wei;
     
    uint public sellPrice;
    uint public buyPrice;

    function buy_value() private returns (uint) { return (init_sellPrice ** totalSupply); }
    
    function sell_value() private returns (uint){ 
        if (totalSupply>0){
            return (init_sellPrice ** (totalSupply-1));
            }
        else {
            return 0;
        }
    }
    
    function update_prices() private{
        sellPrice = sell_value();
        buyPrice = buy_value();
    }
    
     
    address public founder = 0x0803882f6c7fc348EBc2d25F3E8Fa13df25ceDFa;

     
     
     
    function fund() public payable returns (bool){
        uint investment = 0;
        uint tokenCount = 0;
        while ((msg.value-investment) >= buy_value()) {
            investment += buy_value();
            totalSupply += 1;
            tokenCount++;
        }
        
        update_prices();
        balances[msg.sender] += tokenCount;
        Issuance(msg.sender, tokenCount);
        
        if (msg.value > investment) {
            msg.sender.transfer(msg.value - investment);
        }
        return true;
    }

    function withdraw(uint withdrawRequest) public returns (bool){
        require (totalSupply > 0);
        uint tokenCount = withdrawRequest;
        uint withdrawal = 0;
        
        if (balances[msg.sender] >= tokenCount) {
            while (sell_value() > 0 && tokenCount > 0){
                withdrawal += sell_value();
                tokenCount -= 1;
                totalSupply -= 1;
            }
            update_prices();
            balances[msg.sender] -= (withdrawRequest-tokenCount);
            msg.sender.transfer(withdrawal);
            return true;
        } else {
            return false;
        }
    }

     
    function eXtremehoDLCoin()
    {   
        update_prices();
    }
}