 

pragma solidity ^ 0.4.16;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns(uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns(uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns(uint256);
  function transferFrom(address from, address to, uint256 value) public returns(bool);
  function approve(address spender, uint256 value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lockupable is Pausable {
  function _unlockIfPosible(address who) internal;
  function unlockAll() onlyOwner public returns(bool);
  function lockupOf(address who) public constant returns(uint256[5]);
  function distribute(address _to, uint256 _value, uint256 _amount1, uint256 _amount2, uint256 _amount3, uint256 _amount4) onlyOwner public returns(bool);
}

 
contract ERC20Token is ERC20 {
  using SafeMath for uint256;

    mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

   
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _holder) public constant returns(uint256 balance) {
    return balances[_holder];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns(bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 

contract LockupableToken is ERC20Token, Lockupable {

  uint64[] RELEASE = new uint64[](4);
  mapping(address => uint256[4]) lockups;
  mapping(uint => address) private holders;
  uint _lockupHolders;
  bool unlocked;


  function transfer(address _to, uint256 _value) public whenNotPaused returns(bool) {
    _unlockIfPosible(_to);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool) {
    _unlockIfPosible(_from);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns(bool) {
    return super.approve(_spender, _value);
  }
  function balanceOf(address _holder) public constant returns(uint256 balance) {
    uint256[5] memory amount = lockupOf(_holder);
    return amount[0];
  }
   
  function lockupOf(address who) public constant  returns(uint256[5]){
    uint256[5] memory amount;
    amount[0] = balances[who];
    for (uint i = 0; i < RELEASE.length; i++) {
      amount[i + 1] = lockups[who][i];
      if (now >= RELEASE[i]) {
        amount[0] = amount[0].add(lockups[who][i]);
        amount[i + 1] = 0;
      }
    }

    return amount;
  }
   
  function _unlockIfPosible(address who) internal{
    if (now <= RELEASE[3] || !unlocked) {
      uint256[5] memory amount = lockupOf(who);
      balances[who] = amount[0];
      for (uint i = 0; i < 4; i++) {
        lockups[who][i] = amount[i + 1];
      }
    }
  }
   
  function unlockAll() onlyOwner public returns(bool){
    if (now > RELEASE[3]) {
      for (uint i = 0; i < _lockupHolders; i++) {
        balances[holders[i]] = balances[holders[i]].add(lockups[holders[i]][0]);
        balances[holders[i]] = balances[holders[i]].add(lockups[holders[i]][1]);
        balances[holders[i]] = balances[holders[i]].add(lockups[holders[i]][2]);
        balances[holders[i]] = balances[holders[i]].add(lockups[holders[i]][3]);
        lockups[holders[i]][0] = 0;
        lockups[holders[i]][1] = 0;
        lockups[holders[i]][2] = 0;
        lockups[holders[i]][3] = 0;
      }
      unlocked = true;
    }

    return true;
  }
   
  function distribute(address _to, uint256 _value, uint256 _amount1, uint256 _amount2, uint256 _amount3, uint256 _amount4) onlyOwner public returns(bool) {
    require(_to != address(0));
    _unlockIfPosible(msg.sender);
    uint256 __total = 0;
    __total = __total.add(_amount1);
    __total = __total.add(_amount2);
    __total = __total.add(_amount3);
    __total = __total.add(_amount4);
    __total = __total.add(_value);
    balances[msg.sender] = balances[msg.sender].sub(__total);
    balances[_to] = balances[_to].add(_value);
    lockups[_to][0] = lockups[_to][0].add(_amount1);
    lockups[_to][1] = lockups[_to][1].add(_amount2);
    lockups[_to][2] = lockups[_to][2].add(_amount3);
    lockups[_to][3] = lockups[_to][3].add(_amount4);

    holders[_lockupHolders] = _to;
    _lockupHolders++;

    Transfer(msg.sender, _to, __total);
    return true;
  }


}

 
contract BBXCToken is LockupableToken {

  function () {
     
    revert();
  }

   
  string public constant name = 'Bluebelt Exchange Coin';
  string public constant symbol = 'BBXC';
  uint8 public constant decimals = 18;


   
  function BBXCToken() {
    _lockupHolders = 0;
    RELEASE[0] = 1553958000;  
    RELEASE[1] = 1556550000;  
    RELEASE[2] = 1559228400;  
    RELEASE[3] = 1567263600;  
  
    totalSupply = 200000000 * (uint256(10) ** decimals);
    unlocked = false;
    balances[msg.sender] = totalSupply;
    Transfer(address(0x0), msg.sender, totalSupply);
  }
}