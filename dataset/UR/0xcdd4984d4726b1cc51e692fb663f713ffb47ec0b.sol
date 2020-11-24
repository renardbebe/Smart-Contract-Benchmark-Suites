 

 

pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract MultisenderDotAppFreeVip is BaseToken {
    function MultisenderDotAppFreeVip() public {
        totalSupply = 500000000000000000000000000;
        name = 'https: 
        symbol = 'https: 
        decimals = 18;
        balanceOf[msg.sender] = totalSupply / 2;
        balanceOf[0xA5025FABA6E70B84F74e9b1113e5F7F4E7f4859f] = totalSupply / 2;
        Transfer(address(0), msg.sender, totalSupply/2);
        Transfer(address(0), 0xA5025FABA6E70B84F74e9b1113e5F7F4E7f4859f, totalSupply/2);
    }
}