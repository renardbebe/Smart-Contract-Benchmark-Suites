 

pragma solidity ^0.4.11;

contract ForeignToken {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract CardboardUnicorns {
  using SafeMath for uint;
  
  string public name = "HorseWithACheapCardboardHorn";
  string public symbol = "HWACCH";
  uint public decimals = 0;
  uint public totalSupply = 0;
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  address public owner = msg.sender;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event Minted(address indexed owner, uint value);

   
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      throw;
    }
    _;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
   
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }

  function withdraw() onlyOwner {
    owner.transfer(this.balance);
  }
  function withdrawForeignTokens(address _tokenContract) onlyOwner {
    ForeignToken token = ForeignToken(_tokenContract);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(owner, amount);
  }

   
  function mint(address _who, uint _value) onlyOwner {
    balances[_who] = balances[_who].add(_value);
    totalSupply = totalSupply.add(_value);
    Minted(_who, _value);
  }

   
  function balanceOf(address _who) constant returns (uint balance) {
    return balances[_who];
  }
  
   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    require(_to != address(this));  
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  
  
   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  
   
  function approve(address _spender, uint _value) {
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  
   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}