 

pragma solidity ^0.4.16;
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Token {

     
    function totalSupply() constant public returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


 
contract BitProCoinX is StandardToken, owned {



     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0';        
    uint256 public sellPrice;  
    uint256 public buyPrice;   
    uint256 remaining;
     uint public numInvestors;
  struct Investor {
    uint amount;
    address eth_address;
    bytes32 Name;
    bytes32 email;
    bytes32 message;
  }
  mapping(uint => Investor) public investors;

 
 
 

 

    function BitProCoinX(
        ) public{
        balances[msg.sender] = 1000000000000;                
        totalSupply = 1000000000000;                         
        name = "BitProCoinX";                                    
        decimals = 4;                             
        symbol = "BPCX";                                
        sellPrice = 7668200000;                          
        buyPrice =  7668200000;                          
        remaining = 0;
        numInvestors;
    }
     function() public payable{
          
         require(msg.value > 0);
        uint  amount = div(msg.value, buyPrice);                     
        require(balances[this] >= amount);                
        balances[msg.sender] += amount;                   
        balances[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
         
        numInvestors++;
          
    }
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function setPrices(uint256 newSellPriceInwei, uint256 newBuyPriceInwei) onlyOwner {
        sellPrice = div(newSellPriceInwei , (10 ** uint256(decimals)));  
        buyPrice =  div(newBuyPriceInwei , (10 ** uint256(decimals)));
    }
    function buy() payable returns (uint amount){
        require(msg.value > 0);
        amount = div(msg.value, buyPrice);                     
        require(balances[this] >= amount);                
        balances[msg.sender] += amount;                   
        balances[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
         
        numInvestors++;
        return amount;                                     
    }
    function onlyPay() payable onlyOwner{
        
        
    }

    function sell(uint amount) returns (uint revenue){
        require(balances[msg.sender] >= amount);          
        balances[this] += amount;                         
        balances[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue));                 
        Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }

    function withdraw(uint _amountInwei) onlyOwner{
        require(this.balance > _amountInwei);
      require(msg.sender == owner);
      owner.send(_amountInwei);
     
    }
     
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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