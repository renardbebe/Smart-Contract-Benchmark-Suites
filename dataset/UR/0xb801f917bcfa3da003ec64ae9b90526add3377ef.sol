 

pragma solidity ^0.4.24;

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
 
contract MD  {
    using SafeMath for uint256;

    string public constant name = "MD Token";
    string public constant symbol = "MD";

    uint public constant decimals = 18;

     
    uint256 _totalSupply = 3500000000 * 10**decimals;

    mapping(address => uint256) balances;  
    mapping(address => mapping (address => uint256)) allowed;

    address public owner;

    modifier ownerOnly {
      require(
            msg.sender == owner,
            "Sender not authorized."
        );
        _;
    }

    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    constructor(address _owner) public{
        owner = _owner;
        balances[owner] = _totalSupply;
        emit Transfer(0x0, _owner, _totalSupply);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
            balances[_to] = _value.add(balances[_to]);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function changeOwner(address _newowner) public ownerOnly returns (bool success) {
        owner = _newowner;
        return true;
    }

     
    function kill() public ownerOnly {
        selfdestruct(owner);
    }
}