 

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
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
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

contract SOCWARECoin is StandardToken {

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    uint256 public unitsOneEthCanBuy;      
    uint256 public amountSellForOneEth;    
    uint256 public totalEthInWei;          
    address public owner;            

     
     
    function SOCWARECoin() {
        balances[msg.sender] = 100000000000000000000000000;          
        totalSupply = 100000000000000000000000000;                   
        name = "socware_net_coin";                                   
        decimals = 18;                                               
        symbol = "SNC";                                              
        unitsOneEthCanBuy = 5000;                                    
        amountSellForOneEth = 5250;                                  
        owner = msg.sender;                                          
    }

    function() payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
         
        require(balances[owner] - amount > totalSupply/10);

        balances[owner] = balances[owner] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        Transfer(owner, msg.sender, amount);  
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw(uint256 amount) onlyOwner public {
         
        require(this.balance - amount > totalEthInWei/5);
        owner.transfer(amount);
    }

    function setPrice(uint256 price) onlyOwner public {
    	amountSellForOneEth = price;
    }
     
     
    function sell(uint256 amount) public {
         
        require(this.balance >= amount/amountSellForOneEth);       
        require(balances[msg.sender] >= amount);                   
        balances[owner] = balances[owner] + amount;
        balances[msg.sender] = balances[msg.sender] - amount;
        msg.sender.transfer(amount/amountSellForOneEth);           
        Transfer(msg.sender, owner, amount);                       
    }
}