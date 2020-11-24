 

pragma solidity ^0.4.13;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken {
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    string public votingDescription;
    uint256 public sellPrice;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public voted;  
    mapping (address => string) public votedFor;  
    mapping (address => uint256) public restFinish; 


     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event voting(address target, uint256 voteType, string votedDesc);
    
    
     
    function MyToken() {
        balanceOf[msg.sender] = 3000000;               
        totalSupply = 3000000;                         
        name = 'GamityTest3';                                    
        symbol = 'GMTEST3';                                      
        decimals = 0;                                        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] > _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                             
        Transfer(_from, _to, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
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

     
     
    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] > _value);             
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
    
    
    
    
    
    function voteFor()  returns (bool success){   
        voted[msg.sender] = 1;    
        votedFor[msg.sender] = votingDescription;    
        voting (msg.sender, 1, votingDescription);          
        return true;                                   
    }
    
    function voteAgainst()  returns (bool success){   
        voted[msg.sender] = 2;
        votedFor[msg.sender] = votingDescription;   
        voting (msg.sender, 2, votingDescription);          
        return true;                                   
    }
    
    
    
   function newVoting(string description)  returns (bool success){    
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        votingDescription=description;
        return true; 
    }
    
    
    function rest()  returns (bool success){    
        require(balanceOf[msg.sender] >= 5000);          
        balanceOf[this] += 5000;                         
        balanceOf[msg.sender] -= 5000; 
        restFinish[msg.sender] = block.timestamp + 3 days;
        return true; 
    }
    
    
    
    
    function setPrice(uint256 newSellPrice) {
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        sellPrice = newSellPrice;
    }
     

    function sell(uint amount) returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);          
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue));                 
        Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }
    
    function getTokens() returns (uint amount){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        require(balanceOf[this] >= amount);                
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
        return amount;                                     
    }
    
    function sendEther() payable returns (bool success){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        return true;                                    
    }

    
    function getEther(uint amount)  returns (bool success){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        require(msg.sender.send(amount));                  
        return true;                                   
    }
    
    
    
    
    
    
}