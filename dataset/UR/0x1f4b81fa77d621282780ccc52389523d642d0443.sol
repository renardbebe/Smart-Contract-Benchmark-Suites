 

pragma solidity ^0.4.4;

contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Token is SafeMath {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burned(uint amount);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (now < icoEnd + lockedPeriod && msg.sender != fundsWallet) throw;
        if (msg.sender == fundsWallet && now < icoEnd + blockPeriod && ownerNegTokens < _value) throw;  
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            if (msg.sender == fundsWallet && now < icoEnd + blockPeriod) {
                ownerNegTokens = safeSub(ownerNegTokens, _value);
            }
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (now < icoEnd + lockedPeriod && msg.sender != fundsWallet) throw;
        if (msg.sender == fundsWallet && now < icoEnd + blockPeriod && ownerNegTokens < _value) throw;
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            if (msg.sender == fundsWallet && now < icoEnd + blockPeriod) {
                ownerNegTokens = safeSub(ownerNegTokens, _value);
            }
            return true;
        } else { return false; }
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
    
    function burn(){
    	 
    	if(!burned && now> icoEnd){
    		uint256 difference = tokensToSell; 
    		balances[fundsWallet] = balances[fundsWallet] - difference;
    		totalSupply = totalSupply - difference;
    		burned = true;
    		Burned(difference);
    	}
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    uint256 public icoStart = 1520244000;
    
    uint256 public icoEnd = 1520244000 + 45 days;
    
     
    uint256 public blockPeriod = 1 years;
    
     
    uint256 public lockedPeriod = 15 days;
    
     
    uint256 public ownerNegTokens = 13500000000000000000000000;
    
     
    uint256 public ownerFreezeTokens = 13500000000000000000000000;
    
     
    uint256 public tokensToSell = 63000000000000000000000000; 
    
    bool burned = false;
    
    string public name;                   
    uint8 public decimals = 18;                
    string public symbol;                 
    string public version = 'H1.0'; 
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei = 0;          
    address public fundsWallet;
}

contract EpsToken is StandardToken {

     
     
    function EpsToken() {
        balances[msg.sender] = 90000000000000000000000000;              
        totalSupply = 90000000000000000000000000;                     
        name = "Epsilon";                                            
        symbol = "EPS";                                             
        unitsOneEthCanBuy = 28570;                                      
        fundsWallet = msg.sender;                         
    }

    function() payable{
        
        if (now < icoStart || now > icoEnd || tokensToSell <= 0) {
            return;
        }
        
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        uint256 valueInWei = msg.value;
        
        if (tokensToSell < amount) {
            amount = tokensToSell;
            valueInWei = amount / unitsOneEthCanBuy;
            msg.sender.transfer(msg.value - valueInWei);
        }
        
        tokensToSell -= amount;

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        
        
        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(valueInWei);                               
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}