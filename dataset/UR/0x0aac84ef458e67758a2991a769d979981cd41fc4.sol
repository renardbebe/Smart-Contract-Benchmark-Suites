 

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

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

 

contract LimitedTransferToken is ERC20 {
   
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) throw;
   _;
  }

   
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
   return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
   return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Destructible is Ownable {
  function destroy() onlyOwner {
    selfdestruct(owner);
  }
}

contract OxToken is StandardToken, LimitedTransferToken, Ownable, Destructible {
  using SafeMath for uint;

  event OxTokenInitialized(address _owner);
  event OwnerTokensAllocated(uint _amount);
  event SaleStarted(uint _saleEndTime);

  string public name = "OxToken";
  string public symbol = "OX";

  uint public decimals = 3;
  uint public multiplier = 10**decimals;
  uint public etherRatio = SafeMath.div(1 ether, multiplier);

  uint public MAX_SUPPLY = SafeMath.mul(700000000, multiplier);  
  uint public CORPORATE_SUPPLY = SafeMath.mul(200000000, multiplier);  
  uint public BOUNTY_SUPPLY = SafeMath.mul(200000000, multiplier);  
  uint public TEAM_SUPPLY = SafeMath.mul(100000000, multiplier);  
  uint public PRICE = 3000;  
  uint public MIN_PURCHASE = 10**17;  

  uint256 public saleStartTime = 0;
  bool public ownerTokensAllocated = false;
  bool public balancesInitialized = false;

  function OxToken() {
    OxTokenInitialized(msg.sender);
  }

  function initializeBalances() public {
    if (balancesInitialized) {
      throw;
    }
    balances[owner] = CORPORATE_SUPPLY;
    totalSupply = CORPORATE_SUPPLY;
    balancesInitialized = true;
    Transfer(0x0, msg.sender, CORPORATE_SUPPLY);
  }

  function canBuyTokens() constant public returns (bool) {
     
    if (saleStartTime == 0) {
      return false;
    }
    if (getNow() > SafeMath.add(saleStartTime, 31 days)) {
      return false;
    }
    return true;
  }

  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
     
     
    if (holder == owner) {
      return balanceOf(holder);
    }
    if ((saleStartTime == 0) || canBuyTokens()) {
      return 0;
    }
    return balanceOf(holder);
  }

  function startSale() onlyOwner {
     
    if (saleStartTime != 0) {
      throw;
    }
     
    if (!balancesInitialized) {
      throw;
    }
    saleStartTime = getNow();
    SaleStarted(saleStartTime);
  }

  function () payable {
    createTokens(msg.sender);
  }

  function createTokens(address recipient) payable {

     
    if (msg.value < MIN_PURCHASE) {
      throw;
    }

     
    if (!canBuyTokens()) {
      throw;
    }

     
    uint tokens = msg.value.mul(PRICE);

     
    uint bonusPercentage = SafeMath.add(100, bonus());
    if (bonusPercentage != 100) {
      tokens = tokens.mul(percent(bonusPercentage)).div(percent(100));
    }

    tokens = tokens.div(etherRatio);

    totalSupply = totalSupply.add(tokens);

     
    if (totalSupply > MAX_SUPPLY) {
      throw;
    }

    balances[recipient] = balances[recipient].add(tokens);

     
    owner.transfer(msg.value);

  }

   
  function allocateOwnerTokens() public {

     
    if (ownerTokensAllocated) {
      throw;
    }

     
    if ((saleStartTime == 0) || canBuyTokens()) {
      throw;
    }

    ownerTokensAllocated = true;

    uint amountToAllocate = SafeMath.add(BOUNTY_SUPPLY, TEAM_SUPPLY);
    balances[msg.sender] = balances[msg.sender].add(amountToAllocate);
    totalSupply = totalSupply.add(amountToAllocate);

    Transfer(0x0, msg.sender, amountToAllocate);
    OwnerTokensAllocated(amountToAllocate);

  }

  function bonus() constant returns(uint) {

    uint elapsed = SafeMath.sub(getNow(), saleStartTime);

    if (elapsed < 1 days) return 25;
    if (elapsed < 1 weeks) return 20;
    if (elapsed < 2 weeks) return 15;
    if (elapsed < 3 weeks) return 10;
    if (elapsed < 4 weeks) return 5;

    return 0;
  }

  function percent(uint256 p) internal returns (uint256) {
    return p.mul(10**16);
  }

   
  function getNow() internal constant returns (uint256) {
    return now;
  }

}