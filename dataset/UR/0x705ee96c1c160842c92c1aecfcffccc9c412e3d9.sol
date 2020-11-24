 

pragma solidity ^0.4.15;

contract ERC20Interface {
     
    function totalSupply() constant returns (uint256 tS);
 
     
    function balanceOf(address _owner) constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) returns (bool success);
 
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);
 
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
    function burnExcess(uint256 _value) returns (bool success);

     
    function burnPoll(uint256 _value) returns (bool success);
 
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);
}
 
contract POLLToken is ERC20Interface {

    string public constant symbol = "POLL";
    string public constant name = "ClearPoll Token";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 10000000 * 10 ** uint256(decimals);
    
    address public owner;
    
    bool public excessTokensBurnt = false;

    uint256 public pollCompleted = 0;
    
    uint256 public pollBurnInc = 100 * 10 ** uint256(decimals);

    uint256 public pollBurnQty = 0;

    bool public pollBurnCompleted = false;

    uint256 public pollBurnQtyMax;

    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;

     
    function () payable {
      if (msg.value > 0) {
          if (!owner.send(msg.value)) revert();
      }
    }

    function POLLToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

     
    function totalSupply() constant returns (uint256 tS) {
        tS = _totalSupply;
    }
 
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
     
     
     
     
     
     
    function transferFrom(
        address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function burnExcess(uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value && msg.sender == owner && !excessTokensBurnt);
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        Burn(msg.sender, _value);
        pollBurnQtyMax = totalSupply() / 10;
        excessTokensBurnt = true;
        return true;
    }   

     
    function burnPoll(uint256 _value) public returns (bool success) {    	
        require(msg.sender == owner && excessTokensBurnt && _value > pollCompleted && !pollBurnCompleted);
        uint256 burnQty;
        if ((_value * pollBurnInc) <= pollBurnQtyMax) {
            burnQty = (_value-pollCompleted) * pollBurnInc;
            balances[msg.sender] -= burnQty;
            _totalSupply -= burnQty;
            Burn(msg.sender, burnQty);
            pollBurnQty += burnQty;
            pollCompleted = _value;
            if (pollBurnQty == pollBurnQtyMax) pollBurnCompleted = true;
            return true;
        } else if (pollBurnQty < pollBurnQtyMax) {
			burnQty = pollBurnQtyMax - pollBurnQty;
            balances[msg.sender] -= burnQty;
            _totalSupply -= burnQty;
            Burn(msg.sender, burnQty);
            pollBurnQty += burnQty;
            pollCompleted = _value;
            pollBurnCompleted = true;
            return true;
        } else {
            return false;
        }
    }

}