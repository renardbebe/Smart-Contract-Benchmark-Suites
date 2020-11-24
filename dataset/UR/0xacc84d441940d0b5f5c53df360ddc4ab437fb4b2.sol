 

pragma solidity ^0.4.10;


contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns  (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token , SafeMath {

    bool public status = true;
    modifier on() {
        require(status == true);
        _;
    }

    function transfer(address _to, uint256 _value) on returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && _to != 0X0) {
            balances[msg.sender] -= _value;
            balances[_to] = safeAdd(balances[_to],_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) on returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value);
            balances[_from] = safeSubtract(balances[_from],_value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) on constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) on returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) on constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract TurboPayToken is StandardToken {
    string public name = "TurboPayToken";
    uint8 public decimals = 18;
    string public symbol = "TBP";
    bool private init =true;
    function turnon() controller {
        status = true;
    }
    function turnoff() controller {
        status = false;
    }
    function TurboPayToken() {
        require(init==true);
        totalSupply = 120000000*10**18;
        balances[0x2e127CE2293Fb11263F3cf5C5F3E5Da68A77bDEB] = totalSupply;
        init = false;
    }
    address public controllerAdd = 0x2e127CE2293Fb11263F3cf5C5F3E5Da68A77bDEB;

    modifier controller () {
        require(msg.sender == controllerAdd);
        _;
    }
}