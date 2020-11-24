 

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

contract BST is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = "H1.0"; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public units30percentExtra;
    uint256 public units40percentExtra;
    uint256 public units50percentExtra;
    uint256 public totalEthInWei;          
    address public fundsWallet;            
    uint256 public maxHardCaphardcap;      
    uint256 private unitEthWei;
    uint private IEOEndDate;
    uint private tokenMoveableDate;
    bool private isIEOActive;

     
     
    function BST() {
        unitEthWei = 1000000000000000000;
        balances[msg.sender] = 1000000000000000;                
        totalSupply = 1000000000000000;                         
        name = "BST";                                    
        decimals = 6;                                                
        symbol = "BST";                                              
        unitsOneEthCanBuy = 5000;                                       
        units30percentExtra = 6500;
        units40percentExtra = 7000;
        units50percentExtra = 7500;
        fundsWallet = msg.sender;                                     
        maxHardCaphardcap = 20000;
        IEOEndDate = 1529020800;  
        tokenMoveableDate = 1539388800;  
        isIEOActive = isWithinIEO();
    }

    function() payable {
        if(!isWithinIEO()) {
            throw;
        }
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = 0;

        if(msg.value < convertToEther(1)) {
            amount = msg.value * unitsOneEthCanBuy;
        }else if(msg.value >= convertToEther(1) && msg.value < convertToEther(9)) {
            amount = msg.value * units30percentExtra;
        }else if(msg.value >= convertToEther(10) && msg.value <= convertToEther(99)) {
            amount = msg.value * units40percentExtra;
        }else if(msg.value >= convertToEther(100) && msg.value < convertToEther(maxHardCaphardcap)) {
            amount = msg.value * units50percentExtra;
        }else if(msg.value > convertToEther(maxHardCaphardcap)) {
            throw;
        }

        amount = amount / 1000000000000;

        if (balances[fundsWallet] < amount) {
            throw;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        
        Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);                               
    }

    function convertToEther(uint256 _value) returns (uint256 val) {
        uint256 _return = _value * unitEthWei;
        return _return;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function isWithinIEO() returns (bool success) {
        if(now > IEOEndDate) {
            return false;
        }else {
            return true;
        }
    }

    function canMovetoken() returns (bool success){
        if(now > tokenMoveableDate) {
            return true;
        }else {
            return false;
        }
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (isWithinIEO() || !canMovetoken()) {
            throw;
        }else {
            if (balances[msg.sender] >= _value && _value > 0) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
                return true;
            } else { return false; }
        }
        
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (isWithinIEO() || !canMovetoken()) {
            throw;
        }else {
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }
        
    }
}