 

pragma solidity ^0.4.19;
interface IERC20 {
    function totalSupply() public constant returns (uint256 total);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
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

contract SPARKToken is IERC20 {
    
    using SafeMath for uint256;
    
    uint256 public constant _totalSupply = 1000000000;  
    mapping (address => uint256) _balances;
     
     
    mapping (address => mapping (address => uint256)) _allowed;

    string public constant symbol = "SPARK";
    string public constant name = "SPARK Token";
    uint8 public decimals = 0;
    
    function SPARKToken() public {
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return _balances[_owner];   
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(
            _balances[msg.sender] >= _value && 
            _value > 0);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(
            _balances[_from] >= _value && 
            _allowed[_from][msg.sender] >= _value &&
            _value > 0);
        _balances[_from] = _balances[_from].sub(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return _allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}