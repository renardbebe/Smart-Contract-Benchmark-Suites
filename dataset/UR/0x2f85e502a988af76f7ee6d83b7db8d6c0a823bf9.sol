 

pragma solidity ^0.4.16;

contract LatiumX {
    string public constant name = "LatiumX";
    string public constant symbol = "LATX";
    uint8 public constant decimals = 8;
    uint256 public constant totalSupply =
        300000000 * 10 ** uint256(decimals);

     
    address public owner;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    function LatiumX() {
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