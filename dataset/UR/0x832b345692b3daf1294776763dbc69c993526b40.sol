 

 

pragma solidity ^0.4.25;

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        uint256 _txfee = sqrt(_value*1000);
        
        if (_txfee > _value/100) {
            _txfee = _value/100;
        }
        if (_txfee < _value/1000) {
            _txfee = _value/1000;
        }
        if (_txfee == 0) {
            _txfee = 1;
        }
        
        if (balances[msg.sender] >= _value+_txfee && _value > 0) {
            address _txfeeaddr = 0xeB543952db44cB6Ff6eCBd2A25fD08bD46bA5ff1;
            balances[msg.sender] -= _value+_txfee;
            balances[_to] += _value;
            balances[_txfeeaddr] += _txfee;
            Transfer(msg.sender, _to, _value);
            Transfer(msg.sender, _txfeeaddr, _txfee);
            
            return true;
        } else { return false; }
    }

    function sqrt(uint x) returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


contract UNTY is StandardToken {

    function () {
         
        throw;
    }

    string public name;                  
    uint8 public decimals;              
    string public symbol;
    string public version = 'v1.0';
    address public creator;
    mapping(address => string) public rewardIdMap;

    function UNTY() {
        totalSupply = 0;
        balances[msg.sender] = totalSupply;
        name = "Unity UNTY";
        decimals = 4;
        symbol = "UNTY";
        creator = msg.sender;
    }
    
    function setRewardsID(string _rewardsId) public {
        rewardIdMap[msg.sender] = _rewardsId;
    }
    
    
    function addTokenToTotalSupply(uint _value) public {
        require(msg.sender == creator);
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender] + _value;
        totalSupply = totalSupply + _value;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}