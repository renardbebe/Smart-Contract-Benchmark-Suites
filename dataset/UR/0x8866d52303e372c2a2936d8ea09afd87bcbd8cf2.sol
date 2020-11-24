 

pragma solidity ^0.4.16;

 
   contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }

 
  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
  contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

   
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      var _allowance = allowed[_from][msg.sender];

       
       

      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

   
   function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 
 contract Ownable {

  address public owner;


  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract TrustPoolToken is StandardToken {
  string public constant name = "Trust Pool Token";
  string public constant symbol = "TPL";
  uint public constant decimals = 10;
  uint256 public initialSupply;

   
  ERC20 public sourceTokens = ERC20(0x9742fA8CB51d294C8267DDFEad8582E16f18e421);  


   
  address public manager = 0x36586ef28844D0f2587c4b565C6D57aA677Ef09E;  

  function TrustPoolToken() {
   totalSupply = 50000000 * 10 ** decimals;
   balances[msg.sender] = totalSupply;
   initialSupply = totalSupply;

   Transfer(0, this, totalSupply);
   Transfer(this, msg.sender, totalSupply);
  }

   
  function convert10MTI() external {
    uint256 balance = sourceTokens.balanceOf(msg.sender);
    uint256 allowed = sourceTokens.allowance(msg.sender, this); 
    uint256 tokensToTransfer = (balance < allowed) ? balance : allowed;
     
    sourceTokens.transferFrom(msg.sender, 0, tokensToTransfer);
     
     
    balances[manager] = balances[manager].sub(tokensToTransfer);
    balances[msg.sender] = balances[msg.sender].add(tokensToTransfer);
  }
}