 

pragma solidity ^0.5.13;
 
 
 
 
 
 
 
 
contract ERC20Interface {
     
    function totalSupply() public view returns (uint256);
 
     
    function balanceOf(address _owner) public view returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
 
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
 
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);
 
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
 
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract FixedSupplyToken is ERC20Interface {
    string public constant symbol = "NOW";
    string public constant name = "Now";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 1e25;
    
     
    address public owner;
 
     
    mapping(address => uint256) balances;
 
     
    mapping(address => mapping (address => uint256)) allowed;
 
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
     
    constructor() public {
        owner = 0x9D31e30003f253563Ff108BC60B16Fdf2c93abb5;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() public view returns (uint256 total) {
        total = _totalSupply;
    }
 
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}