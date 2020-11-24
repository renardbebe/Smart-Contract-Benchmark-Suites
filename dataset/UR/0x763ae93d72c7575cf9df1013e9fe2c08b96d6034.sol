 

pragma solidity ^0.4.21;

contract BitXCoin {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        totalSupply = _initialAmount;
        balances[msg.sender] = totalSupply;
        allowed[msg.sender][msg.sender] = balances[msg.sender];
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value, uint256 _allowed) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        if (_allowed > 0) {
            allowed[msg.sender][_to] +=  _allowed;
        } else {
            allowed[msg.sender][_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[msg.sender][_from];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[msg.sender][_from] -= _value;
            allowed[msg.sender][_to] += _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _owner, address _spender, uint256 _value) public returns (bool success) {
        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}