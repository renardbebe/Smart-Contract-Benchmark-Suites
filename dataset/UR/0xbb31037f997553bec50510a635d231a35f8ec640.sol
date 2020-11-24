 

pragma solidity ^0.4.13;

contract Latium {
    string public constant name = "Latium";
    string public constant symbol = "LAT";
    uint8 public constant decimals = 16;
    uint256 public constant totalSupply =
        30000000 * 10 ** uint256(decimals);

     
    address public owner;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    function Latium() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

     
    function transfer(address _to, uint256 _value) {
         
        require(_to != 0x0);
         
        require(msg.sender != _to);
         
        require(_value > 0 && balanceOf[msg.sender] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(msg.sender, _to, _value);
    }
}