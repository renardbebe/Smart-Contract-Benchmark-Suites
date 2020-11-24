 

pragma solidity ^0.4.19;

interface ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ChiToken is ERC20 {

     
    string public name = 'Chi';
    string public symbol = 'CHI';
    
     
    uint256 _totalSupply = 10000000000;
    
     
    uint256 public decimals = 0;

     
    mapping (address => uint256) balances;
    
     
    mapping (address => mapping (address => uint256)) allowances;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ChiToken() public {
        balances[msg.sender] = _totalSupply;
    }
    
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);

        balances[_to] += _value;
        balances[_from] -= _value;

        allowances[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
}