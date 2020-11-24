 

pragma solidity 0.4.24;

contract Eneat {
     
    string public name;
     
    string public symbol;
     
    uint public decimals;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    mapping(address => uint256) public balanceOf;


     
    constructor (uint256 initialSupply,string tokenName, string tokenSymbol, uint8 decimalUnits) public {
         
        balanceOf[msg.sender] = initialSupply;
        name = tokenName;                                 
        symbol = tokenSymbol;                               
        decimals = decimalUnits; 
    }

     
    function transfer(address _to,uint256 _value) public {
         
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
         
        emit Transfer(msg.sender, _to, _value);
    }

}