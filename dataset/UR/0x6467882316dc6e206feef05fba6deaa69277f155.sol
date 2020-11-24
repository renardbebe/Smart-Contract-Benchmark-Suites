 

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

contract FAPcoin is StandardToken, SafeMath {

     
    string public constant name = "FAPcoin";
    string public constant symbol = "FAP";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public ethFundDeposit;       
    address public FAPFounder;
    address public FAPFundDeposit1;       
    address public FAPFundDeposit2;       
    address public FAPFundDeposit3;       
    address public FAPFundDeposit4;       
    address public FAPFundDeposit5;       

     
    uint public firstStage;
    uint public secondStage;
    uint public thirdStage;
    uint public fourthStage;
    bool public isFinalized;               
    bool public saleStarted;  
    uint256 public constant FAPFund = 50 * (10**6) * 10**decimals;    
    uint256 public constant FAPFounderFund = 150 * (10**6) * 10**decimals;    
    uint256 public tokenExchangeRate = 1500;  
    uint256 public constant tokenCreationCap =  500 * (10**6) * 10**decimals;


     
    event CreateFAP(address indexed _to, uint256 _value);

     
    function FAPcoin()
    {
      isFinalized = false;                    
      saleStarted = false;
      FAPFounder = '0x97F5eD1c6af0F45B605f4Ebe62Bae572B2e2198A';
      FAPFundDeposit1 = '0xF946cB03dC53Bfc13a902022C1c37eA830F8E35B';
      FAPFundDeposit2 = '0x19Eb1FE8Fdc51C0f785F455D8aB3BD22Af50cf11';
      FAPFundDeposit3 = '0xaD349885e35657956859c965670c41EE9A044b84';
      FAPFundDeposit4 = '0x4EEbfDEe9141796AaaA65b53A502A6DcFF21d397';
      FAPFundDeposit5 = '0x20a0A5759a56aDE253cf8BF3683923D7934CC84a';
      ethFundDeposit = '0x6404B11A733b8a62Bd4bf3A27d08e40DD13a5686';
      totalSupply = safeMult(FAPFund,5);
      totalSupply = safeAdd(totalSupply,FAPFounderFund);
      balances[FAPFundDeposit1] = FAPFund;     
      balances[FAPFundDeposit2] = FAPFund;     
      balances[FAPFundDeposit3] = FAPFund;     
      balances[FAPFundDeposit4] = FAPFund;     
      balances[FAPFundDeposit5] = FAPFund;     
      balances[FAPFounder] = FAPFounderFund;     
      CreateFAP(FAPFundDeposit1, FAPFund);   
      CreateFAP(FAPFundDeposit2, FAPFund);   
      CreateFAP(FAPFundDeposit3, FAPFund);   
      CreateFAP(FAPFundDeposit4, FAPFund);   
      CreateFAP(FAPFundDeposit5, FAPFund);   
      CreateFAP(FAPFounder, FAPFounderFund);   
    }

     
    function () payable {
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
       
      if (now > firstStage && now <= secondStage){
        tokenExchangeRate = 1300;
      }
      else if (now > secondStage && now <= thirdStage){
        tokenExchangeRate = 1100;
      }
      if (now > thirdStage && now <= fourthStage){
        tokenExchangeRate = 1050;
      }
      if (now > fourthStage){
        tokenExchangeRate = 1000;
      }
       
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) throw;   
      totalSupply = checkedSupply;
       
      balances[msg.sender] += tokens;   
      CreateFAP(msg.sender, tokens);   
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
        CreateFAP(msg.sender, remainingTokens);
      }
       
      if(!ethFundDeposit.send(this.balance)) throw;
      isFinalized = true;   
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != ethFundDeposit) throw;  
      firstStage = now + 15 days;  
      secondStage = firstStage + 15 days;  
      thirdStage = secondStage + 7 days;  
      fourthStage = thirdStage + 6 days;  
      saleStarted = true;  
    }


}