 

pragma solidity ^0.4.18;


contract MeridianFiftyOne {
    
    string public name = "Meridian";
    string public symbol = "MDN";
    uint8 public decimals = 8;
    
    uint256 public totalSupply = 51000000;
    uint256 public initialSupply = 51000000;

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    

     
    function MeridianFiftyOne
    (string tokenName, string tokenSymbol) 
        public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName ="Meridian";                                   
        symbol = tokenSymbol ="MDN";                               
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
     
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
}