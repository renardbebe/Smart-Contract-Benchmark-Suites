 

pragma solidity ^0.4.13;
 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
     
    string public standard = 'Token 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;                          
       
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    function token(
        uint256 initialSupply,
        string name,
        uint8 decimals,
        string symbol
        )
        {
        balanceOf[msg.sender] = 33000;              
        totalSupply = initialSupply;
        name = "RomanLanskoj";                                 
        symbol = "JOB";                               
        decimals = 2;                
        }
        

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);                    
    }


    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


    function () {
        throw;      
    }
}

contract MyOffer is owned, token {

uint256 public sellPrice;
uint256 public buyPrice;
  function MyOffer (
         uint256 initialSupply,
        string name,
        uint8 decimals,
        string symbol
    ) token (initialSupply, name, decimals, symbol) {
        initialSupply = 75000;
    }


    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        if (frozenAccount[msg.sender]) throw;                
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);                    
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                                    
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;   
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

  

    function buy(uint256 amount, uint256 buyPrice) payable {
        amount = msg.value / buyPrice;                
        if (balanceOf[this] < amount) throw;               
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;      
        buyPrice = 10000;                       
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount, uint sellPrice) {
        if (balanceOf[msg.sender] < amount ) throw;        
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;     
       sellPrice = 10;          
        if (!msg.sender.send(amount * sellPrice)) {        
            throw;                                         
        } else {
            Transfer(msg.sender, this, amount);             
        }         
  
    }
}