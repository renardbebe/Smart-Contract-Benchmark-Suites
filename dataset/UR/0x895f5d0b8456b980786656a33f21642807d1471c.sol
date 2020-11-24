 

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}









 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => uint256) Loanbalances;
    event transferEvent(address from, uint256 value, address to);
    event giveToken(address to, uint256 value);
    event signLoanEvent(address to);
    uint256 _totalSupply = 100000000000000000;

    address owner = 0xBc57C45AA9A71F273AaEbf54cFE835056A628F0b;

    function BasicToken() {
        balances[owner] = _totalSupply;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
   

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender].sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function loanBalanceOf(address _owner) public view returns (uint256 balance) {
        return Loanbalances[_owner];
    }

    function giveTokens(address client, uint256 value) public {
        require(msg.sender == owner);
        balances[owner] = balances[owner].sub(value);
        balances[client] = balances[client].add(value);
        Loanbalances[client] = Loanbalances[client].add(value);
        giveToken(client, value);
        Transfer(msg.sender, client, value);
    }

    function signLoan(address client) public {
        require(msg.sender == owner);
        Loanbalances[client] = balances[client];
        signLoanEvent(client);
    }

    function subLoan(address client, uint256 _value) public {
        require(msg.sender == owner);
        Loanbalances[client] = Loanbalances[client].sub(_value);
    }
}


contract customCoin is BasicToken {
  string public name = "Hive token";
  string public symbol = "HIVE";
  uint public decimals = 8;
}