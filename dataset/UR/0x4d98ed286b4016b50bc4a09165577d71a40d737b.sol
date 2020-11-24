 

pragma solidity ^0.4.17;

contract ETHTest01Token{
    mapping (address => uint256) balances;
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public totalSupply;
     
    mapping (address => mapping (address => uint256)) allowed;
    constructor() public {
        owner = 0xF48be01754b8FC91a48D193D0194bBd4f8e2DB6b;           
        name = "ETHTest01";                                    
        symbol = "ETHTest01";                                            
        decimals = 18;                                             
        totalSupply = 10000000000000000000000000000;                
        balances[owner] = totalSupply;
    }

     
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                  
        require(balances[_to] + _value >= balances[_to]);    
        require(_value <= allowed[_from][msg.sender]);       
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function () private {
        revert();      
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}