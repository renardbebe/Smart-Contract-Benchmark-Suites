 

pragma solidity ^0.5.1;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract COM {

    using SafeMath for uint256;

    uint256 constant private MAX_UINT256 = 2**256 - 1;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Burn(address indexed _from, uint256 value);

    constructor(uint256 _initialSupply, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
             
        require(_to != address(0x0));
             
        require(_value > 0);
             
        require(balanceOf[msg.sender] >= _value);
             
        require(balanceOf[_to] + _value >= balanceOf[_to]);
             
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
             
        require(_to != address(0x0));
             
        require(_value > 0);
             
        require(balanceOf[msg.sender] >= _value);
             
        require(balanceOf[_to] + _value >= balanceOf[_to]);
             
             
        require(_value <= allowance[_from][msg.sender]);
             
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
             
        require(allowance[_from][msg.sender]  < MAX_UINT256);
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
             
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
             
        require(balanceOf[msg.sender] >= _value);
             
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }

}