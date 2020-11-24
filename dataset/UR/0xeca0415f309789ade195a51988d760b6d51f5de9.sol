 

pragma solidity ^0.4.11;

 
 
 
 
   
 
 
 contract ERC20Interface {
      
     function totalSupply() constant returns (uint256 totalSupply);
 
      
     function balanceOf(address _owner) constant returns (uint256 balance);
  
      
     function transfer(address _to, uint256 _value) returns (bool success);
  
      
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
      
      
      
     function approve(address _spender, uint256 _value) returns (bool success);
  
      
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
      
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
      
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }

 contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
  
 contract GreenMed is ERC20Interface {
     string public constant symbol = "GRMD";
     string public constant name = "GreenMed";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 100000000000000000000000000;
     
      
     address public owner;

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
  
      
     mapping(address => uint256) balances;
  
      
     mapping(address => mapping (address => uint256)) allowed;
  
      
     modifier onlyOwner() {
         if (msg.sender != owner) {
             throw;
         }
         _;
     }
  
      
     function GreenMed() {
         owner = msg.sender;
         balances[owner] = _totalSupply;
     }
  
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
     }
  
      
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }
  
      
     function transfer(address _to, uint256 _amount) returns (bool success) {
         if (balances[msg.sender] >= _amount 
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(msg.sender, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
      
      
      
      
     function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) returns (bool success) {
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }

      
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
     function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                 
        if (balances[this] < amount) throw;                
        balances[msg.sender] += amount;                    
        balances[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) {
        if (balances[msg.sender] < amount ) throw;         
        balances[this] += amount;                          
        balances[msg.sender] -= amount;                    
        if (!msg.sender.send(amount * sellPrice)) {         
            throw;                                          
        } else {
            Transfer(msg.sender, this, amount);             
        }               
    }
 }