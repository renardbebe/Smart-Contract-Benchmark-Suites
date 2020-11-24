 

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
 
contract RoseCoin is ERC20Interface {
    uint8 public constant decimals = 5;
    string public constant symbol = "RSC";
    string public constant name = "RoseCoin";

    uint public _level = 0;
    bool public _selling = true;
    uint public _totalSupply = 10 ** 14;
    uint public _originalBuyPrice = 10 ** 10;
    uint public _minimumBuyAmount = 10 ** 17;
   
     
    address public owner;
 
     
    mapping(address => uint256) balances;
 
     
    mapping(address => mapping (address => uint256)) allowed;
    
    uint public _icoSupply = _totalSupply;
    uint[4] public ratio = [12, 10, 10, 13];
    uint[4] public threshold = [95000000000000, 85000000000000, 0, 80000000000000];

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlyNotOwner() {
        if (msg.sender == owner) {
            revert();
        }
        _;
    }

    modifier thresholdAll() {
        if (!_selling || msg.value < _minimumBuyAmount || _icoSupply <= threshold[3]) {  
            revert();
        }
        _;
    }
 
     
    function RoseCoin() {
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


    function toggleSale() onlyOwner {
        _selling = !_selling;
    }

    function setBuyPrice(uint newBuyPrice) onlyOwner {
        _originalBuyPrice = newBuyPrice;
    }
    
     
    function buy() payable onlyNotOwner thresholdAll returns (uint256 amount) {
        amount = 0;
        uint remain = msg.value / _originalBuyPrice;
        
        while (remain > 0 && _level < 3) {  
            remain = remain * ratio[_level] / ratio[_level+1];
            if (_icoSupply <= remain + threshold[_level]) {
                remain = (remain + threshold[_level] - _icoSupply) * ratio[_level+1] / ratio[_level];
                amount += _icoSupply - threshold[_level];
                _icoSupply = threshold[_level];
                _level += 1;
            }
            else {
                _icoSupply -= remain;
                amount += remain;
                remain = 0;
                break;
            }
        }
        
        if (balances[owner] < amount)
            revert();
        
        if (remain > 0) {
            remain *= _originalBuyPrice;
            msg.sender.transfer(remain);
        }
        
        balances[owner] -= amount;
        balances[msg.sender] += amount;
        owner.transfer(msg.value - remain);
        Transfer(owner, msg.sender, amount);
        return amount;
    }
    
     
    function withdraw() onlyOwner returns (bool) {
        return owner.send(this.balance);
    }
}