 

pragma solidity ^0.4.11;
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
 
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }
   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }
   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }
}
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
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
 
contract VenusCoin is StandardToken, Ownable {
  string public constant name = "VenusCoin";
  string public constant symbol = "Venus";
  uint public constant decimals = 0;
   
  function VenusCoin() {
      totalSupply = 50000000000;
      balances[msg.sender] = totalSupply;  
  }
   
  function burn(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
}
 
contract Tokensale is Pausable {
    
    using SafeMath for uint;
    struct Beneficiar {
        uint weiReceived;  
        uint coinSent;
    }
    
     
    uint public constant MIN_ACCEPT_ETHER = 50000000000000 wei;  
     
    uint public constant COIN_PER_ETHER = 20000;  
     
     
    VenusCoin public coin;
     
    address public multisigEther;
     
    uint public etherReceived;
     
    uint public coinSentToEther;
     
    uint public startTime;
     
    mapping(address => Beneficiar) public beneficiars;
  
     
    event LogReceivedETH(address addr, uint value);
    event LogCoinsEmited(address indexed from, uint amount);
     
    function Tokensale(address _venusCoinAddress, address _to) {
        coin = VenusCoin(_venusCoinAddress);
        multisigEther = _to;
    }
     
    function() stopInEmergency payable {
        receiveETH(msg.sender);
    }
     
    function start() onlyOwner {
        if (startTime != 0) throw;  
        startTime = now ;              
    }
    
    function receiveETH(address beneficiary) internal {
        if (msg.value < MIN_ACCEPT_ETHER) throw;  
        
        uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether));  
        Beneficiar beneficiar = beneficiars[beneficiary];
        coin.transfer(beneficiary, coinToSend);  
        beneficiar.coinSent = beneficiar.coinSent.add(coinToSend);
        beneficiar.weiReceived = beneficiar.weiReceived.add(msg.value);  
        etherReceived = etherReceived.add(msg.value);  
        coinSentToEther = coinSentToEther.add(coinToSend);
         
        LogCoinsEmited(msg.sender ,coinToSend);
        LogReceivedETH(beneficiary, etherReceived); 
    }
    
     
    function bonus(uint amount) internal constant returns (uint) {
        if (now < startTime.add(2 days)) return amount.add(amount.div(10));    
        return amount;
    }
    
     
    function drain() onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
     
    function setMultisig(address addr) onlyOwner public {
        if (addr == address(0)) throw;
        multisigEther = addr;
    }
     
    function backVenusCoinOwner() onlyOwner public {
        coin.transferOwnership(owner);
    }
  
    
    
}