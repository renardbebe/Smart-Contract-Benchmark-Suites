 

pragma solidity ^0.4.11;

 

 
 
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
 

 
contract ERC223Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  function transfer(address to, uint value, bytes data);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
 

 
  
contract ERC223ReceivingContract {
  function tokenFallback(address _from, uint _value, bytes _data);
}
 


contract ERC223BasicToken is ERC223Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  function transfer(address to, uint value, bytes data) {
     
     
    uint codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, data);
    }
    Transfer(msg.sender, to, value, data);
  }

   
   
  function transfer(address to, uint value) {
    uint codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, value, empty);
    }
    Transfer(msg.sender, to, value, empty);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
 

contract PreTgeExperty is ERC223BasicToken {

   
  string public constant name = "Pre-TGE Experty Token";
  string public constant symbol = "PEXY";
  uint8 public constant decimals = 18;

   
  uint8 public basicRate = 100;
  uint8 public preTgeBonus = 45;
  address public preTgeManager;
  address public multisigWallet;
  bool public isClosed = false;

   
  mapping(address => uint) public burnedTokens;
  
   
  function PreTgeExperty() {
    multisigWallet = 0x6fb25777000c069bf4c253b9f5f886a5144a0021;
    preTgeManager = 0x009A55A3c16953A359484afD299ebdC444200EdB;
  }

   
  function() payable {
     
    if (isClosed) throw;

    uint ethers = msg.value;

     
    uint tokens = ethers * basicRate;
    uint bonus = ethers * preTgeBonus;

     
    uint sum = tokens + bonus;
    balances[msg.sender] += sum;
    totalSupply += sum;

     
    multisigWallet.transfer(ethers);
  }

   
  function burnTokens(uint amount) {
    if (amount > balances[msg.sender]) throw;

    balances[msg.sender] = balances[msg.sender].sub(amount);
    burnedTokens[msg.sender] = burnedTokens[msg.sender].add(amount);
  }

   
  function changeBonus(uint8 _preTgeBonus) {
    if (msg.sender != preTgeManager) throw;

     
    if (_preTgeBonus > preTgeBonus) throw;

    preTgeBonus = _preTgeBonus;
  }

   
  function close() {
    if (msg.sender != preTgeManager) throw;

    isClosed = true;
  }

}