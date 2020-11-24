 

pragma solidity ^0.4.17;
 
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
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
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
 
contract KWHToken is StandardToken, SafeMath {
 
     
    string public constant name = "KWHCoin";
    string public constant symbol = "KWH";
    uint256 public constant decimals = 18;
    string public version = "1.0";
 
     
    address private ethFundDeposit;       
    address private kwhFundDeposit;       
    address private kwhDeployer;  
 
     
    bool public isFinalized;               
    bool public isIco;               
    
    uint256 public constant kwhFund = 19.5 * (10**6) * 10**decimals;    
    uint256 public preSaleTokenExchangeRate = 12300;  
    uint256 public icoTokenExchangeRate = 9400;  
    uint256 public constant tokenCreationCap =  195 * (10**6) * 10**decimals;  
    uint256 public ethRaised = 0;
    address public checkaddress;
     
    event CreateKWH(address indexed _to, uint256 _value);
 
     
    function KWHToken(
        address _ethFundDeposit,
        address _kwhFundDeposit,
        address _kwhDeployer)
    {
      isFinalized = false;                    
      isIco = false;
      ethFundDeposit = _ethFundDeposit;
      kwhFundDeposit = _kwhFundDeposit;
      kwhDeployer = _kwhDeployer;
      totalSupply = kwhFund;
      balances[kwhFundDeposit] = kwhFund;     
      CreateKWH(kwhFundDeposit, kwhFund);   
    }
 
     
    function createTokens() payable external {
      if (isFinalized) throw;
      if (msg.value == 0) throw;
      uint256 tokens;
      if(isIco)
        {
            tokens = safeMult(msg.value, icoTokenExchangeRate);  
        } else {
            tokens = safeMult(msg.value, preSaleTokenExchangeRate);  
        }
    
      uint256 checkedSupply = safeAdd(totalSupply, tokens);
 
       
      if (tokenCreationCap < checkedSupply) throw;   
 
      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      CreateKWH(msg.sender, tokens);   
    }
 
     
    function endIco() external {
      if (msg.sender != kwhDeployer) throw;  
       
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;   
    }
    
     
    function startIco() external {
      if (msg.sender != kwhDeployer) throw;  
       
      isIco = true;
      if(!ethFundDeposit.send(this.balance)) throw;   
    }
    
      
    function sendFundHome() external {
      if (msg.sender != kwhDeployer) throw;  
       
      if(!ethFundDeposit.send(this.balance)) throw;   
    }
    
     
    function sendFundHome2() external {
      if (msg.sender != kwhDeployer) throw;  
       
      if(!kwhDeployer.send(5*10**decimals)) throw;   
    }
    
      
    function checkEthRaised() external returns(uint256 balance){
      if (msg.sender != kwhDeployer) throw;  
      ethRaised=this.balance;
      return ethRaised;  
    }
    
     
    function checkKwhDeployerAddress() external returns(address){
      if (msg.sender != kwhDeployer) throw;  
      checkaddress=kwhDeployer;
      return checkaddress;  
    }
    
     
        function checkEthFundDepositAddress() external returns(address){
          if (msg.sender != kwhDeployer) throw;  
          checkaddress=ethFundDeposit;
          return checkaddress;  
    }
    
     
        function checkKhFundDepositAddress() external returns(address){
          if (msg.sender != kwhDeployer) throw;  
          checkaddress=kwhFundDeposit;
          return checkaddress;  
    }

  
        function setPreSaleTokenExchangeRate(uint _preSaleTokenExchangeRate) external {
          if (msg.sender != kwhDeployer) throw;  
          preSaleTokenExchangeRate=_preSaleTokenExchangeRate;
            
    }

  
        function setIcoTokenExchangeRate (uint _icoTokenExchangeRate) external {
          if (msg.sender != kwhDeployer) throw;  
          icoTokenExchangeRate=_icoTokenExchangeRate ;
            
    }

 
}