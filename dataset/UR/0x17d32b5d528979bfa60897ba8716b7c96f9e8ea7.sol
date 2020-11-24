 

pragma solidity ^0.4.26;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 internal _totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    function MyToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply();
        name = tokenName;
        symbol = tokenSymbol;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function totalSupply() view returns(uint256)
    {
        return _totalSupply;
    }
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    function allowance(address _owner, address _spender) view returns (uint256 remaining)
    {
        remaining = _allowance[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance(_from,_to));
        _allowance[_from][_to] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}