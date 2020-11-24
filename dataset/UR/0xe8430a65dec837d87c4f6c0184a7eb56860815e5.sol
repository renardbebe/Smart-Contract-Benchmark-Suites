 

pragma solidity ^0.4.24;

contract MUTOCoin {
    address owner;

     
    string public constant name = "MUTO";
    string public constant symbol = "MTC";
    uint8 public constant decimals = 8;
    
     
    mapping (address => uint) public balanceOf;

    event Transfer(address from, address to, uint value);

    constructor() public {
        balanceOf[msg.sender] = 200000000000000000;
    }

    function transfer(address _to, uint _value) public {
        
        address _from = msg.sender;
         
        require(_to != address(0));
         
        require(balanceOf[_from] >= _value);               

        balanceOf[_from] -= _value;                    
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function killcontract() public {
        if (owner == msg.sender)
            selfdestruct(owner);
    }
}