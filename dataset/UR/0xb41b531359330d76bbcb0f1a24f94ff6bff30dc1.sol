 

pragma solidity ^0.4.13;

contract  CNet5G {
     
    string public name = "CNet5G"; 
    uint256 public decimals = 2;
    uint256 public totalSupply;
    string public symbol = "NE5G";
    event Mint(address indexed owner,uint amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function CNet5G() public {
        owner = 0x5103bA50f2324c6A80c73867d93B173d94cB11c6;
         
        balances[0x5103bA50f2324c6A80c73867d93B173d94cB11c6] = 300000000 * 10**decimals;
        totalSupply =300000000 * 10**decimals; 
    }

 function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x00);
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    address owner;


    function mint(uint amount) onlyOwner public returns(bool minted ){
        if (amount > 0){
            totalSupply += amount;
            balances[owner] += amount;
            Mint(msg.sender,amount);
            return true;
        }
        return false;
    }

    modifier onlyOwner() { 
        if (msg.sender != owner) revert(); 
        _; 
    }
    
    function setOwner(address _owner) onlyOwner public {
        balances[_owner] = balances[owner];
        balances[owner] = 0;
        owner = _owner;
    }

}