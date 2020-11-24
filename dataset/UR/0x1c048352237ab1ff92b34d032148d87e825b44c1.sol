 

 

pragma solidity ^0.4.19;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
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
contract Week {
    function get(address from_) public returns (uint256);
}

contract Token {
   
  function totalSupply() public constant returns (uint256 supply);

   
   
  function balanceOf(address _owner) public constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract StandardToken is Token {
    using SafeMath for uint256;

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {
      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}


contract LeRT_Bounty is owned {

    using SafeMath for uint256;

    address public token;

    mapping (address => uint256) public sent; 
    address[] internal extention;

    event Withdraw(address user, uint256 amount, uint256 balance);

     

    function LeRT_Bounty() public {
        token = 0x13646D839725a5E88555a694ac94696824a18332;   
    }

     
    function() payable public{
        owner.transfer(msg.value); 
    }
     
    function changeToken(address token_) onlyOwner public {
        token = token_;
    }

     
    function addExtension(address ext_) onlyOwner public {
        extention.push(ext_);
    }
    
    function withdraw(uint256 amount_) public {
        uint256 tokens;
        uint256 remain;
        tokens = _balanceOf(msg.sender);
        require(tokens.sub(sent[msg.sender]) >= amount_);
        sent[msg.sender] = sent[msg.sender].add(amount_);
        remain = tokens.sub(sent[msg.sender]);
        require(Token(token).transfer(msg.sender, amount_));
        Withdraw(msg.sender, amount_, remain);
    }

    function balanceOf(address user_) public constant returns (uint256) {
        require(extention.length > 0);
        uint256 balance;
        for (uint256 i = 0; i < extention.length; i++){
            Week eachWeek = Week(extention[i]);
            balance = balance.add(eachWeek.get(user_));
        }
        return (balance.sub(sent[user_]));
    }

    function _balanceOf(address user_) internal constant returns (uint256) {
        require(extention.length > 0);
        uint256 balance;
        for (uint256 i = 0; i < extention.length; i++){
            Week eachWeek = Week(extention[i]);
            balance = balance.add(eachWeek.get(user_));
        }
        return balance;
    }

    function balanceTotal() public constant returns (uint256){
        return Token(token).balanceOf(this);
    }
  
}