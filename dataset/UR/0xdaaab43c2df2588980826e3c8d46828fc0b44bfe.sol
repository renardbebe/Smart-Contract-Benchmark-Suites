 

pragma solidity ^ 0.4 .4;

 

 

library SafeMath {
    
	 
    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 

contract ERC20 {
     
    uint public totalSupply;

     
    function totalSupply() constant returns(uint256 supply){}

     
    function balanceOf(address who) constant returns(uint);

     
    function transfer(address to, uint value) returns(bool ok);

     
    function transferFrom(address from, address to, uint value) returns(bool ok);

     
    function approve(address spender, uint value) returns(bool ok);

     
    function allowance(address owner, address spender) constant returns(uint);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

 

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract StandardToken is ERC20, Ownable {
	using SafeMath for uint256;
    function transfer(address _to, uint256 _value) returns(bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
}

contract Tratok is StandardToken {

    function() {
        throw;
    }

     
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';

     

    function Tratok() {

         
        balances[msg.sender] = 10000000000000000;
        totalSupply = 10000000000000000;
        name = "Tratok";
        decimals = 5;
        symbol = "TRAT";
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            throw;
        }
        return true;
    }
}