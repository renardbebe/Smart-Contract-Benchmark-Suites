 

pragma solidity ^0.4.24;

 

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

contract ERC20 {

     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract BasicToken is ERC20 {
    using SafeMath for uint;

    mapping (address => uint256) balances;  

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(_to != 0x0);
         
        require(balances[msg.sender] >= _value);
         
        require(balances[_to].add(_value) > balances[_to]);

        uint previousBalances = balances[msg.sender].add(balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

         
        assert(balances[msg.sender].add(balances[_to]) == previousBalances);

        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
}

contract BAIC is BasicToken {

    function () payable public {
         
         
        require(false);
    }

    string public constant name = "BAIC";
    string public constant symbol = "BAIC";
    uint256 private constant _INITIAL_SUPPLY = 21000000000;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    string public version = "BAIC 1.0";

    constructor() public {
         
        totalSupply = _INITIAL_SUPPLY * 10 ** 18;
        balances[msg.sender] = totalSupply;
    }
}