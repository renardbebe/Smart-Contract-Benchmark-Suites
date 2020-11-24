 

pragma solidity ^0.4.23;

 
 library SafeMath {
    
   function mul(uint256 a, uint256 b) internal returns (uint256 c) {
     if (a == 0) {
       return 0;
     }
     c = a * b;
     assert(c / a == b);
     return c;
   }

    
   function div(uint256 a, uint256 b) internal returns (uint256) {
      
      
      
     return a / b;
   }

    
   function sub(uint256 a, uint256 b) internal returns (uint256) {
     assert(b <= a);
     return a - b;
   }

    
   function add(uint256 a, uint256 b) internal returns (uint256 c) {
     c = a + b;
     assert(c >= a && c >= b);
     return c;
   }

   function assert(bool assertion) internal {
     if (!assertion) {
       revert();
     }
   }
 }

 
contract ERC20Basic {
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size.add(4)) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    require(_to != 0x0);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    require(_to != 0x0);
    uint _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract Ownable {
  address public owner;
   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
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
    if (paused) revert();
    _;
  }

   
  modifier whenPaused {
    if (!paused) revert();
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused {
    super.transferFrom(_from, _to, _value);
  }
}

 
contract CNYTokenPlus is PausableToken {
  using SafeMath for uint256;

  function () {
       
      revert();
  }

  string public name = "CNYTokenPlus";
  string public symbol = "CNYt⁺";
  uint8 public decimals = 18;
  uint public totalSupply = 100000000000000000000000000;
  string public version = 'CNYt⁺ 2.0';
   
  mapping(address => uint256) nonces;

  event Burn(address indexed burner, uint256 value);

  function CNYTokenPlus() {
      balances[msg.sender] = totalSupply;               
  }

   
  function burn(uint256 _value) onlyOwner whenNotPaused {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

   
  function transferProxy(address _from, address _to, uint256 _value, uint256 _fee,
      uint8 _v, bytes32 _r, bytes32 _s) whenNotPaused {

      require((balances[_from] >= _fee.add(_value)));
      require(balances[_to].add(_value) >= balances[_to]);
      require(balances[msg.sender].add(_fee) >= balances[msg.sender]);

      uint256 nonce = nonces[_from];
      bytes32 hash = keccak256(_from,_to,_value,_fee,nonce);
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      bytes32 prefixedHash = keccak256(prefix, hash);
      require(_from == ecrecover(prefixedHash,_v,_r,_s));

      balances[_from] = balances[_from].sub(_value.add(_fee));
      balances[_to] = balances[_to].add(_value);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      nonces[_from] = nonce.add(1);

      emit Transfer(_from, _to, _value);
      emit Transfer(_from, msg.sender, _fee);
  }
}