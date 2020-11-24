 

 
 
pragma solidity ^0.4.18;

contract Token {
     
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract StandardToken is Token {

    function transfer(address _to, uint _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}

contract Owned {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address _owner) public onlyOwner {
        require(_owner != 0x0);
        owner = _owner;
    }
}

contract VankiaToken is StandardToken, Owned {
    string public constant name = "Vankia Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "VNT";

    event Burnt(address indexed from, uint amount);

    function VankiaToken() public {
        totalSupply = (10 ** 9) * (10 ** uint(decimals));
        balances[msg.sender] = totalSupply;
    }

    function withdraw(uint _amount) public onlyOwner {
        owner.transfer(_amount);
    }

     
    function burn(uint _amount) public {
        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        
        Burnt(msg.sender, _amount);
        Transfer(msg.sender, 0x0, _amount);
    }

     
    function() public payable {}
}