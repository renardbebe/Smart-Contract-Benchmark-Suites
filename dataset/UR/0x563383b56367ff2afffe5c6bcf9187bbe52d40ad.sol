 

pragma solidity ^0.4.8;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event FrozenFunds(address target, uint256 frozen);

     
    function MyToken() {
        balanceOf[msg.sender] = 3330000000000;               
        totalSupply = 3330000000000;                         
        name = 'Hubcoin';                                    
        symbol = 'HUB';                                      
        decimals = 6;                                        
    }

     
    function transfer(address _to, uint256 _value) {
        uint forbiddenPremine =  1501545600 - block.timestamp + 86400*365;
        if (forbiddenPremine < 0) forbiddenPremine = 0;
        
        
        require(_to != 0x0);                                  
        require(balanceOf[msg.sender] > _value + frozenAccount[msg.sender] * forbiddenPremine / (86400*365) );     
        require(balanceOf[_to] + _value > balanceOf[_to]);    
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
        uint forbiddenPremine =  1501545600 - block.timestamp + 86400*365;        
        if (forbiddenPremine < 0) forbiddenPremine = 0;   
        
        require(_to != 0x0);                                 
        require(balanceOf[_from] > _value + frozenAccount[_from] * forbiddenPremine / (86400*365) );     
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        require(_value < allowance[_from][msg.sender]);      
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] > _value);             
        balanceOf[msg.sender] -= _value;                     
        totalSupply -= _value;                               
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] > _value);                 
        require(_value < allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                         
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
    
    function freezeAccount(address target, uint256 freeze) {
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        require(block.timestamp < 1502036759 + 3600*10);
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
}