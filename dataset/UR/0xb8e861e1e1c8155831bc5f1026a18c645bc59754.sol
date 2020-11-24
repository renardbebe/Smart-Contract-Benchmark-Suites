 

pragma solidity ^0.4.15;

 
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

   function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
   }
}

 
contract ERC20Token {

   uint256 public totalSupply;
   function balanceOf(address _owner) constant returns (uint256 balance);
   function transfer(address _to, uint256 _value) returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
   function approve(address _spender, uint256 _value) returns (bool success);
   function allowance(address _owner, address _spender) constant returns (uint256 remaining);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is ERC20Token {
   using SafeMath for uint256;

   mapping (address => uint256) balances;
   mapping (address => mapping (address => uint256)) allowed;

    
   function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
   }

    
   function transfer(address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));

       
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
   }

    
   function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));

      uint256 _allowance = allowed[_from][msg.sender];
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
      return true;
   }

    
   function approve(address _spender, uint256 _value) returns (bool success) {

      
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

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
   function Ownable() {
      owner = msg.sender;
   }

    
   modifier onlyOwner() {
      require(msg.sender == owner);
      _;
   }

    
   function transferOwnership(address newOwner) onlyOwner {
      require(newOwner != address(0));
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
   }
}


 
contract TokenHolder is Ownable {

     
    function transferAnyERC20Token(address _tokenAddress, uint256 _amount) onlyOwner returns (bool success) {
        return ERC20Token(_tokenAddress).transfer(owner, _amount);
    }
}


 
contract KudosToken is StandardToken, Ownable, TokenHolder {

   string public constant name = "Kudos";
   string public constant symbol = "KUDOS";
   uint8 public constant decimals = 18;
   string public constant version = "1.0";

   uint256 public constant tokenUnit = 10 ** 18;
   uint256 public constant oneBillion = 10 ** 9;
   uint256 public constant maxTokens = 10 * oneBillion * tokenUnit;

   function KudosToken() {
      totalSupply = maxTokens;
      balances[msg.sender] = maxTokens;
   }
}