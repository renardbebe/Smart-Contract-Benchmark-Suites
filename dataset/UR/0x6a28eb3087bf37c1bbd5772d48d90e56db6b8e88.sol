 

pragma solidity ^0.4.19;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function claimdram() public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EOSDRAM is ERC20Interface {
    string public constant symbol = "DRAM";
    string public constant name = "EOS DRAM";
    uint8 public constant decimals = 4;

    uint256 _totalSupply = 0;
     
    uint256 _airdropAmount = 200 * 10000;
     
    uint256 _maxSupply = 67108864 * 10000;

    mapping(address => uint256) balances;
    mapping(address => bool) claimeddram;

     
    mapping(address => mapping (address => uint256)) allowed;

    address public owner;
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }
    
    function EOSDRAM() public {
        owner = msg.sender;
        claimeddram[msg.sender] = true;
         
        balances[msg.sender] = 7108864 * 10000;
        _totalSupply = balances[msg.sender];
        Transfer(0, owner, 71088640000);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function totalSupply() constant public returns (uint256 supply) {
        return _totalSupply;
    }

     
    function balance() constant public returns (uint256) {
            return balances[msg.sender];
    }

     
    function balanceOf(address _address) constant public returns (uint256) {
        return balances[_address];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
 
        if (balances[msg.sender] >= _amount
            && _amount > 0) {
             if (balances[_to] + _amount > balances[_to]) {
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(msg.sender, _to, _amount);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            if (balances[_to] + _amount > balances[_to]) {
                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(_from, _to, _amount);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function claimdram() public returns (bool success) {
        if (_totalSupply < _maxSupply && !claimeddram[msg.sender]) {
            claimeddram[msg.sender] = true;
            balances[msg.sender] += _airdropAmount;
            _totalSupply += _airdropAmount;
            Transfer(0, msg.sender, _airdropAmount);
            return true;
        } else {
            return false;
            }
    }

}