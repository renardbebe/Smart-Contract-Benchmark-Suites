 

pragma solidity ^0.4.0;

contract XPeerChain{
     
     
     
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public isStop;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
         
        if (_supply == 0) _supply = 1000000;
	    totalSupply = _supply;
         
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
         
        decimals = _decimals;
        owner = msg.sender;
        isStop = false;
    }

     
    function transfer(address _to, uint256 _value) public {
         
        require (balanceOf[msg.sender] > _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require (!isStop);

         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

         
        emit Transfer(msg.sender, _to, _value);
    }

    function stopContract(bool stop) public {
        require (msg.sender == owner);
        isStop = stop;
    }
}