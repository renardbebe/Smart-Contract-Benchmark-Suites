 

pragma solidity ^0.4.11;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract PopeCoin is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function PopeCoin(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter
    ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        
        if (centralMinter != 0x00) {
            owner = centralMinter;
        }
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        
         
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      

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
        require(balanceOf[msg.sender] >= _value);    
        
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
    
     
    function mintToken(address _to, uint256 _value) onlyOwner {
        require(totalSupply + _value > totalSupply);  
        
        balanceOf[_to] += _value;
        totalSupply += _value;
        
         
        Transfer(0, owner, _value);
        
        if (owner != _to) {
            Transfer(owner, _to, _value);
        }
    }
}