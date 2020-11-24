 

pragma solidity ^0.4.24;
contract MyToken {
     
    string public name;
    string public symbol;
    uint8 public decimals;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    constructor(uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
         
        if (_supply == 0) _supply = 1000000;

         
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;

         
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value) public {
         
        if (balanceOf[msg.sender] < _value) {revert();}
        if (balanceOf[_to] + _value < balanceOf[_to]) {revert();}

         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

         
        emit Transfer(msg.sender, _to, _value);
    }
}