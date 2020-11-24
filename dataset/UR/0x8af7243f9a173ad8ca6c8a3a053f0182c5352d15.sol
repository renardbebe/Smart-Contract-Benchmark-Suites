 

pragma solidity ^0.4.8;
contract Soarcoin {

    mapping (address => uint256) balances;                
    address internal owner = 0x4Bce8E9850254A86a1988E2dA79e41Bc6793640d;                 
    string public name = "Soarcoin";                      
    string public symbol = "SOAR";                        
    uint8 public decimals = 6;                            
    uint256 public totalSupply = 5000000000000000;  
           
    modifier onlyOwner()
    {
        if (msg.sender != owner) throw;
        _;
    }

    function Soarcoin() { balances[owner] = totalSupply; }    

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) returns (bool success)
    {
        if(_value <= 0) throw;                                       
        if (balances[msg.sender] < _value) throw;                    
        if (balances[_to] + _value < balances[_to]) throw;           
        balances[msg.sender] -= _value;                              
        balances[_to] += _value;                                     
        Transfer(msg.sender, _to, _value);                           
        return true;      
    }

    function mint(address _to, uint256 _value) onlyOwner
    {
    	balances[_to] += _value;
    	totalSupply += _value;
    }
}