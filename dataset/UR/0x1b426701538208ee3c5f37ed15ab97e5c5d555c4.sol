 

pragma solidity >=0.4.23;

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
    function balanceOf(address _owner) constant public returns  (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token , SafeMath {

    bool public status = true;
    modifier on() {
        require(status == true);
        _;
    }

    function transfer(address _to, uint256 _value) on public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);
        if (balances[msg.sender] >= _value && _value > 0 && _to != 0X0) {
            balances[msg.sender] -= _value;
            balances[_to] = safeAdd(balances[_to],_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) on public returns (bool success) {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value);
            balances[_from] = safeSubtract(balances[_from],_value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) on constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) on public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) on constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract Telecomm is StandardToken {
    string public name = "Telecomm";
    uint8 public decimals = 18;
    string public symbol = "TLM";
    bool private init =true;
    
    event Mint(address indexed to, uint value);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    
    function turnon() controller public {
        status = true;
    }
    function turnoff() controller public {
        status = false;
    }
    function Telecomm() {
        require(init==true);
        totalSupply = 1200000000*10**18;
        balances[0x32e4ba59400ede24f1545adfe51146805d099d24] = totalSupply;
        init = false;
    }
    address public controllerAddress = 0x32e4ba59400ede24f1545adfe51146805d099d24;

    modifier controller () {
        require(msg.sender == controllerAddress);
        _;
    }
    
    function mint(address _to, uint256 _amount) on controller public returns (bool) {
        totalSupply = safeAdd(totalSupply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);

        emit Mint(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function burn(uint256 _value) on public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] = safeSubtract(balances[msg.sender],_value);
        totalSupply = safeSubtract(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
   
    function freezeAccount(address target, bool freeze) on controller public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}