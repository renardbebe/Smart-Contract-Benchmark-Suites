 

pragma solidity ^0.4.11;

 
contract SafeMath {

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is SafeMath, Token {

    uint public lockBlock;
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(block.number >= lockBlock || isAllowedTransferDuringICO());
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(block.number >= lockBlock || isAllowedTransferDuringICO());
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract EICToken is StandardToken {

     
    string constant public name = "Entertainment Industry Coin";
    string constant public symbol = "EIC";
    uint256 constant public decimals = 18;

    function EICToken(
        uint _lockBlockPeriod)
        public
    {
        allowedTransferDuringICO.push(owner);
        totalSupply = 3125000000 * (10 ** decimals);
        balances[owner] = totalSupply;
        lockBlock = block.number + _lockBlockPeriod;
    }

    function distribute(address[] addr, uint256[] token) public onlyOwner {
         
        require(addr.length == token.length);
        allowedTransferDuringICO.push(addr[0]);
        allowedTransferDuringICO.push(addr[1]);
        for (uint i = 0; i < addr.length; i++) {
            transfer(addr[i], token[i] * (10 ** decimals));
        }
    }

}