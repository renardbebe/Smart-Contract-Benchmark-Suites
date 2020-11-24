 

pragma solidity ^0.4.11;

 
contract SafeMath {

function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Phoenix is StandardToken, SafeMath {

     
    string public constant name = "Phoenix";
    string public constant symbol = "PHX";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public ethFundDeposit;       
    address public PhoenixFundDeposit;       
    address public PhoenixExchangeDeposit;       

     
    bool public isFinalized;               
    bool public saleStarted;  
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint public fourthWeek;
    uint256 public bonus;
    uint256 public constant PhoenixFund = 125 * (10**5) * 10**decimals;    
    uint256 public constant PhoenixExchangeFund = 125 * (10**5) * 10**decimals;    
    uint256 public tokenExchangeRate = 55;  
    uint256 public constant tokenCreationCap =  50 * (10**6) * 10**decimals;
    uint256 public constant tokenPreSaleCap =  375 * (10**5) * 10**decimals;


     
    event CreatePHX(address indexed _to, uint256 _value);

     
    function Phoenix()
    {
      isFinalized = false;                    
      saleStarted = false;
      PhoenixFundDeposit = '0xCA0664Cc0c1E1EE6CF4507670C9060e03f16F508';
      PhoenixExchangeDeposit = '0x7A0B7a6c058b354697fbC5E641C372E877593631';
      ethFundDeposit = '0xfF0b05152A8477A92E5774685667e32484A76f6A';
      totalSupply = PhoenixFund + PhoenixExchangeFund;
      balances[PhoenixFundDeposit] = PhoenixFund;     
      balances[PhoenixExchangeDeposit] = PhoenixExchangeFund;     
      CreatePHX(PhoenixFundDeposit, PhoenixFund);   
      CreatePHX(PhoenixExchangeDeposit, PhoenixExchangeFund);   
    }

     
    function () payable {
      bool isPreSale = true;
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
       
      if (now > firstWeek && now < secondWeek){
        tokenExchangeRate = 41;
      }
      else if (now > secondWeek && now < thirdWeek){
        tokenExchangeRate = 29;
      }
      else if (now > thirdWeek && now < fourthWeek){
        tokenExchangeRate = 25;
      }
      else if (now > fourthWeek){
        tokenExchangeRate = 18;
        isPreSale = false;
      }
       
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if(isPreSale && tokenPreSaleCap < checkedSupply) throw;
      if (tokenCreationCap < checkedSupply) throw;   
      totalSupply = checkedSupply;
       
      balances[msg.sender] += tokens;   
      CreatePHX(msg.sender, tokens);   
    }

     
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw;  
      if (totalSupply < tokenCreationCap){
        uint256 remainingTokens = safeSubtract(tokenCreationCap, totalSupply);
        uint256 checkedSupply = safeAdd(totalSupply, remainingTokens);
        if (tokenCreationCap < checkedSupply) throw;
        totalSupply = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreatePHX(msg.sender, remainingTokens);
      }
       
      if(!ethFundDeposit.send(this.balance)) throw;
      isFinalized = true;   
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != ethFundDeposit) throw;  
      firstWeek = now + 1 weeks;  
      secondWeek = firstWeek + 1 weeks;  
      thirdWeek = secondWeek + 1 weeks;  
      fourthWeek = thirdWeek + 1 weeks;  
      saleStarted = true;  
    }


}