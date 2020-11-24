 

pragma solidity ^0.4.11;

contract ERC20Interface {
     
    function totalSupply() constant returns (uint256);
 
     
    function balanceOf(address _owner) constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) returns (bool success);
 
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);
 
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract DatCoin is ERC20Interface {
    uint8 public constant decimals = 5;
    string public constant symbol = "DTC";
    string public constant name = "DatCoin";

    uint public _totalSupply = 10 ** 14;
    uint public _originalBuyPrice = 10 ** 10;
    uint public _minimumBuyAmount = 10 ** 17;
    uint public _thresholdOne = 9 * (10 ** 13);
    uint public _thresholdTwo = 85 * (10 ** 12);
   
     
    address public owner;
 
     
    mapping(address => uint256) balances;
 
     
    mapping(address => mapping (address => uint256)) allowed;

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier thresholdTwo() {
        if (msg.value < _minimumBuyAmount || balances[owner] <= _thresholdTwo) {
            revert();
        }
        _;
    }
 
     
    function DatCoin() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
 
     
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }
 
     
    function transfer(address _to, uint256 _amount) returns (bool) {
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
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool) {
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
 
     
     
    function approve(address _spender, uint256 _amount) returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function buy() payable thresholdTwo returns (uint256 amount) {
        uint value = msg.value;
        amount = value / _originalBuyPrice;
        
        if (balances[owner] <= _thresholdOne + amount) {
            uint temp = 0;
            if (balances[owner] > _thresholdOne)
                temp = balances[owner] - _thresholdOne;
            amount = temp + (amount - temp) * 10 / 13;
            if (balances[owner] < amount) {
                temp = (amount - balances[owner]) * (_originalBuyPrice * 13 / 10);
                msg.sender.transfer(temp);
                amount = balances[owner];
                value -= temp;
            }
        }

        owner.transfer(value);
        balances[msg.sender] += amount;
        balances[owner] -= amount;
        Transfer(owner, msg.sender, amount);
        return amount;
    }
    
     
    function withdraw() onlyOwner returns (bool) {
        return owner.send(this.balance);
    }
}