 

pragma solidity ^0.4.4;

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

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
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract BrainLegitCoin is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'BL1.0'; 
    uint256 public unitsOneEthCanBuybefore;      
    uint256 public unitsOneEthCanBuyafter;      
    uint256 public totalEthInWei;          
    address public fundsWallet;           
    uint public deadline;
uint256 public ecosystemtoken;
uint public preIcoStart;
uint public preIcoEnds;
uint public Icostart;
uint public Icoends;


   
   
  uint256 public maxTokens = 1000000000000000000000000000;  
  uint256 public tokensForplutonics = 200000000000000000000000000;  
  uint256 public tokensForfortis = 150000000000000000000000000;     
  uint256 public tokensFortorch = 10000000000000000000000000;      
    uint256 public tokensForEcosystem = 10000000000000000000000000;   
  uint256 public totalTokensForSale = 450000000000000000000000000;  

     
     
    function BrainLegitCoin() {
        balances[msg.sender] = maxTokens;                
        totalSupply = maxTokens;                         
      
        name = "LegittCoin";                                    
        decimals = 18;                                                
        symbol = "LGT";                                              
        unitsOneEthCanBuybefore = 30000;                                       
       unitsOneEthCanBuyafter=15000;
        fundsWallet = msg.sender;  
   preIcoStart=now + 10080 * 1 minutes;
   preIcoEnds = now + 25920 * 1 minutes;
   Icostart = now + 27360 * 1 minutes;
   Icoends= now + 72000 * 1 minutes;
   
                         
    }

    function() payable{
       
      if(now > Icoends) throw;
      if ((balances[fundsWallet] > 300000000000000000000000000) && ((now >= preIcoStart) && (now <= preIcoEnds))){
              totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuybefore;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);
      } else if( (now >= Icostart) && (now <= Icoends)){
       totalEthInWei = totalEthInWei + msg.value;
        uint256 amountb = msg.value * unitsOneEthCanBuyafter;
        require(tokensForEcosystem >= amountb);

        tokensForEcosystem = tokensForEcosystem - amountb;
        balances[msg.sender] = balances[msg.sender] + amountb;

        Transfer(fundsWallet, msg.sender, amountb);  

         
        fundsWallet.transfer(msg.value);
      }
              
     
       
      
        
       
                                   
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}