 

pragma solidity ^0.4.17;

contract TravelWithMeToken{
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    event Burn(address indexed from, uint256 value);

     
    function TravelWithMeToken() public{
        balanceOf[msg.sender] = 1000000000 * (10**18);  
        totalSupply = 1000000000 * (10**18);           
        name = "Travel With Me Chain";             
        symbol = "TWMC";                                
        decimals = 18;                             
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                             
        Transfer(_from, _to, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public{
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
     
    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);             
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}