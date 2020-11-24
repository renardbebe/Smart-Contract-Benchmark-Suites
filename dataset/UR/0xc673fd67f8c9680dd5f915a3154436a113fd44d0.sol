 

pragma solidity ^0.4.11;

 

 

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) {
     
    _from;
    _value;
    _data;
  }
}


contract FLTToken {
     
    string public constant _name = "FLTcoin";
    string public constant _symbol = "FLT";
    uint8 public constant _decimals = 8;

     
    uint256 public constant _initialSupply = 49800000000000000;

     
    address public owner;
    uint256 public _currentSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

     
    function FLTToken() {
        owner = msg.sender;
        _currentSupply = _initialSupply;
        balances[owner] = _initialSupply;
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

     
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

     
    event Burn(address indexed from, uint256 amount, uint256 currentSupply, bytes data);

     
     
    function totalSupply() constant returns (uint256 totalSupply) {
        return _initialSupply;
    }

     
    function balanceOf(address _address) constant returns (uint256 balance) {
        return balances[_address];
    }

     
    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            bytes memory empty;
            if(isContract(_to)) {
                return transferToContract(_to, _value, empty);
            } else {
                return transferToAddress(_to, _value, empty);
            }
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _allowance) returns (bool success) {
        if (_allowance <= _currentSupply) {
            allowed[msg.sender][_spender] = _allowance;
            Approval(msg.sender, _spender, _allowance);
            return true;
        } else {
            return false;
        }
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
    function name() constant returns (string name) {
        return _name;
    }

     
    function symbol() constant returns (string symbol) {
        return _symbol;
    }

     
    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

     
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            if(isContract(_to)) {
                return transferToContract(_to, _value, _data);
            } else {
                return transferToAddress(_to, _value, _data);
            }
        } else {
            return false;
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        if (_address == 0) return false;
        assembly {
            length := extcodesize(_address)
        }
        if(length > 0) {
            return true;
        } else {
            return false;
        }
    }

     
     
    function burn(uint256 _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0) {
            balances[msg.sender] -= _value;
            _currentSupply -= _value;
            Burn(msg.sender, _value, _currentSupply, _data);
            return true;
        } else {
            return false;
        }
    }

     
    function currentSupply() constant returns (uint256 currentSupply) {
        return _currentSupply;
    }

     
    function amountBurned() constant returns (uint256 amountBurned) {
        return _initialSupply - _currentSupply;
    }

     
    function () {
        throw;
    }
}