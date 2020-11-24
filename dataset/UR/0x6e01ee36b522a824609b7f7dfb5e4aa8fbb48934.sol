 

 

pragma solidity ^0.4.6;

 
contract StandardToken {
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function transfer(address _to, uint256 _value) returns(bool success) {
        if(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
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

}

 
contract HumanStandardToken is StandardToken {
    string public name;  
    uint8 public decimals;  
    string public symbol;  
    string public version;  
}

 
contract EthToken is HumanStandardToken {
     
    function EthToken() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = 'ETH Token';
        decimals = 18;
        symbol = 'Ξ';
        version = '0.2';
    }

    event LogCreateToken(address indexed _from, uint256 _value);
    event LogRedeemToken(address indexed _from, uint256 _value);

     
    function createToken() payable returns(bool success) {
        if(msg.value == 0) {
            throw;
        }
        if((balances[msg.sender] + msg.value) > balances[msg.sender] && (totalSupply + msg.value) > totalSupply) {
            totalSupply += msg.value;
            balances[msg.sender] += msg.value;
            LogCreateToken(msg.sender, msg.value);
            return true;
        } else {
            throw;
        }
    }

     
    function redeemToken(uint256 _tokens) returns(bool success) {
        if(this.balance < totalSupply) {
            throw;
        }
        if(_tokens == 0) {
            throw;
        }
        if(balances[msg.sender] >= _tokens && totalSupply >= _tokens) {
            balances[msg.sender] -= _tokens;
            totalSupply -= _tokens;
            if(msg.sender.send(_tokens)) {
                LogRedeemToken(msg.sender, _tokens);
                return true;
            } else {
                throw;
            }
        } else {
            throw;
        }
    }

    function() payable {
        createToken();
    }
}