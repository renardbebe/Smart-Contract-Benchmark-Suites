 

 

pragma solidity ^0.4.10;

 
contract SafeMath {

     
     
     
     
     
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

contract GooglierToken is StandardToken, SafeMath {

     
    string public constant name = "Googlier Iridium";
    string public constant symbol = "GOOGI";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public ethFundDeposit;      
    address public batFundDeposit;      

     
    bool public isFinalized;               
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant batFund = 500 * (10**6) * 10**decimals;    
    uint256 public constant tokenExchangeRate = 6400;  
    uint256 public constant tokenCreationCap =  1500 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  675 * (10**6) * 10**decimals;


     
    event LogRefund(address indexed _to, uint256 _value);
    event CreateBAT(address indexed _to, uint256 _value);

     
    function GooglierToken(
        address _ethFundDeposit,
        address _batFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFinalized = false;                    
      ethFundDeposit = _ethFundDeposit;
      batFundDeposit = _batFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = batFund;
      balances[batFundDeposit] = batFund;     
      CreateBAT(batFundDeposit, batFund);   
    }

     
    function createTokens() payable external {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) throw;   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      CreateBAT(msg.sender, tokens);   
    }

     
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw;  
      if(totalSupply < tokenCreationMin) throw;       
      if(block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
       
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;   
    }

     
    function refund() external {
      if(isFinalized) throw;                        
      if (block.number <= fundingEndBlock) throw;  
      if(totalSupply >= tokenCreationMin) throw;   
      if(msg.sender == batFundDeposit) throw;     
      uint256 batVal = balances[msg.sender];
      if (batVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, batVal);  
      uint256 ethVal = batVal / tokenExchangeRate;      
      LogRefund(msg.sender, ethVal);                
      if (!msg.sender.send(ethVal)) throw;        
    }

}