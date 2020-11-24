 

pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)  public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant  public returns (uint);
  function transferFrom(address from, address to, uint value)  public;
  function approve(address spender, uint value)  public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32)  public {
    uint _allowance;
    _allowance = allowed[_from][msg.sender];

    require(_allowance >= _value);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value)  public {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;


   
  constructor()  public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner  public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
     
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused  public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused  public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused  public {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused  public {
    super.transferFrom(_from, _to, _value);
  }
}

 
contract BitgeneToken is PausableToken {
  using SafeMath for uint256;

  string public name = "Bitgene Token";
  string public symbol = "BGT";
  uint public decimals = 18;
  uint256 public totalSupply = 10 ** 10 * 10**uint(decimals);
  
  constructor() public {
    balances[owner] = totalSupply;        
    emit Transfer(address(0), msg.sender, totalSupply);
  }
  
	function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
	    uint cnt = _receivers.length;
	    uint256 amount = uint256(cnt).mul(_value);
	    require(cnt > 0 && cnt <= 200);
	    require(_value > 0 && balances[msg.sender] >= amount);
	
	    balances[msg.sender] = balances[msg.sender].sub(amount);
	    for (uint i = 0; i < cnt; i++) {
	        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
	        emit Transfer(msg.sender, _receivers[i], _value);
	    }
	    return true;
	}

   
  function () public payable{ revert(); }
}