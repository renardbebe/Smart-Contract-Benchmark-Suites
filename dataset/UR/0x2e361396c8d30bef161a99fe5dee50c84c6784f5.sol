 

pragma solidity ^0.5.4;

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

     
     
    function balanceOf(address _owner) view public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract BasicToken is ERC20 {
    using SafeMath for uint;

    mapping (address => uint256) balances;  

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(_to != address(0x0));
         
        require(balances[msg.sender] >= _value);
         
        require(balances[_to].add(_value) > balances[_to]);

        uint previousBalances = balances[msg.sender].add(balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

         
        assert(balances[msg.sender].add(balances[_to]) == previousBalances);

        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }
}

contract RETO is BasicToken {

    function () external payable {
         
         
        require(false);
    }

    string public constant name = "RETO";
    string public constant symbol = "RETO";
    uint256 private constant _INITIAL_SUPPLY = 3000000000;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    string public version = "RETO 1.0";

    string public agreementPartI = "https://etherscan.io/tx/0xc4f48439bf2bd4cea5f114517ac134557c21172f85a8d4330e3bd729c951623e";
    string public agreementPartII = "https://etherscan.io/tx/0x60ad6bd67388f4f0981babc242b2b9624f1fbdd285f459c425bebdf68edb8ad6";
    string public disclaimer = "https://etherscan.io/tx/0x380e646106a465d4dd88055a2f631c8d9221cd61f9d6a59584075b67b5801439";

    constructor() public {
         
        totalSupply = _INITIAL_SUPPLY * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}