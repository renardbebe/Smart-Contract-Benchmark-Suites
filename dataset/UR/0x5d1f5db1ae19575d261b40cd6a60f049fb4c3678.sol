 

pragma solidity ^0.4.10;


contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}


contract Sponsify {
     
    string public standard = 'SPO1.0';

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    address public owner;

     
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function Sponsify(
    ) {
        balanceOf[msg.sender] = 50000000000;
         
        totalSupply = 50000000000;
         
        name = "SPONSIFY";
         
        symbol = "SPO";
         
        decimals = 2;
         

        owner=msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();
         
        if (balanceOf[msg.sender] < _value) revert();
         
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(msg.sender, _to, _value);
         
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

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();
         
        if (balanceOf[_from] < _value) revert();
         
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
         
        if (_value > allowance[_from][msg.sender]) revert();
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

}