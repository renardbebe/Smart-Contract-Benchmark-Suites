 

pragma solidity ^0.4.19;

contract ERC20 {
   
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}








contract StandardToken is ERC20 {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

  function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
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
    
     
}




contract IdGameCoin is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0'; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public owner;                
    uint256 public endIco;
    uint256 public bonusEnds;
    uint256 public startPreIco;
    uint256 public startIco;

     
     
    function IdGameCoin() public {
        balances[msg.sender] = 30000000000000000000000000;                
        totalSupply = 30000000000000000000000000;                         
        name = "IdGameCoin";                                    
        decimals = 18;                                                
        symbol = "IDGO";                                              
        unitsOneEthCanBuy = 1000;                                       
        owner = msg.sender;                                      
        startPreIco  = now;
        startIco = 1556748000;                           
        bonusEnds = 1546293600;                             
        endIco = 1568062800;                                 
    }

    function() public payable{
        if (now <= bonusEnds) {
            require (now >= startPreIco && now <= bonusEnds);
        } else {
            require (now >= startIco && now <= endIco);
        }
        
        
        
        totalEthInWei = totalEthInWei + msg.value;
        if (now <= bonusEnds) {
            unitsOneEthCanBuy = 1200;
        } else {
            unitsOneEthCanBuy = 1000;
        }
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[owner] >= amount);

        balances[owner] = balances[owner] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        

        emit Transfer(owner, msg.sender, amount);  

         
        owner.transfer(msg.value);                               
    }
    
    function mint(address recipient, uint256 amount) public {
        
    
    require(msg.sender == owner);
    require(totalSupply + amount >= totalSupply);  

    totalSupply += amount;
    balances[recipient] += amount;
    emit Transfer(owner, recipient, amount);
}

function burn(uint256 amount) public {
    require(amount <= balances[msg.sender]);
    require(msg.sender == owner);

    totalSupply -= amount;
    balances[msg.sender] -= amount;
    emit Transfer(msg.sender, address(0), amount);
}

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}