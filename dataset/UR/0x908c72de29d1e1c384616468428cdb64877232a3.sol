 

pragma solidity ^0.4.18;

 
contract ERC20 {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint256);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is ERC20 {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    uint256 public totalTokens;

    function totalSupply() public constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;        
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
    }

}

contract CoinXExchange is StandardToken {
    string public constant NAME = "CoinX Exchange";
    string public constant SYMBOL = "CXE";
    uint8 public constant DECIMALS = 0;

    function name() public constant returns (string) {
        return NAME;
    }

    function symbol() public constant returns (string) {
        return SYMBOL;
    }

    function decimals() public constant returns (uint8) {
        return DECIMALS;
    }

    function CoinXExchange() public {
        totalTokens = 1000000000;
        balances[msg.sender] = totalTokens;
    }
}