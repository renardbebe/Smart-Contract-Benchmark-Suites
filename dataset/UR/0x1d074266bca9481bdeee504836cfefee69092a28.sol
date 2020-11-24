 

pragma solidity ^0.4.21;
pragma experimental "v0.5.0";

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract SmartInvestmentFundToken {
    using SafeMath for uint256;

     
    mapping (address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    string public name = "Smart Investment Fund Token v2";

     
    string public symbol = "XSFT";

     
    uint8 public decimals = 6;

     
    uint256 public totalSupply = 722935000000;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function SmartInvestmentFundToken (address _tokenConvertor) public {
		 
        balances[0] = totalSupply;
        allowed[0][_tokenConvertor] = totalSupply;
        emit Approval(0, _tokenConvertor, totalSupply);
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 
    
     
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

     
    function approve(address _spender, uint256 _amount) public onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) public onlyPayloadSize(2) returns (bool) {
         
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

         
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}