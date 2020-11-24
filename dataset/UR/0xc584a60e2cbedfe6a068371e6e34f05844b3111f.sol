 

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

contract KillYourselfCoin is StandardToken {

     

    string public name;                  
    uint8 public decimals;               
    string public symbol;                
    string public version = "v1.0";      
    uint256 public unitsOneEthCanBuy;    
    uint256 public totalEthInWei;        
    uint256 public tokensIssued;         
    address public owner;                
    uint256 public availableSupply;      
    uint256 public reservedTokens;       
    bool public purchasingAllowed = false;

     
     
    function KillYourselfCoin() {
        owner = msg.sender;                                
        decimals = 18;                                     
        totalSupply = 1500000000000000000000000;           
        availableSupply = 1393800000000000000000000;       
        reservedTokens = totalSupply - availableSupply;    
        balances[owner] = totalSupply;                     

        name = "Kill Yourself Coin";                       
        symbol = "KYS";                                    
        unitsOneEthCanBuy = 6969;                          
    }

    function enablePurchasing() {
        if (msg.sender != owner) { revert(); }
        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { revert(); }
        purchasingAllowed = false;
    }

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { revert(); }

        Token token = Token(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function() payable{
         
        if (!purchasingAllowed) { revert(); }
         
        if (msg.value == 0) { revert(); }

        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[owner] - reservedTokens < amount) {
            revert();
        }

        totalEthInWei = totalEthInWei + msg.value;
        tokensIssued = tokensIssued + amount;

        balances[owner] = balances[owner] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

         
        Transfer(owner, msg.sender, amount);

         
        owner.transfer(msg.value);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}