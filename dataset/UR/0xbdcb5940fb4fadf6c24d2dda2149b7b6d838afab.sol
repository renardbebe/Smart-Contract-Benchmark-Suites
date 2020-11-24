 

 
pragma solidity ^0.4.24;

library SafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EtherDelta {
  function deposit() public payable {}
  function withdrawToken(address token, uint amount) public {}
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {}
  function balanceOf(address token, address user) public view returns (uint);
}

contract Accelerator {
  function transfer(address to, uint tokens) public returns (bool success);
}

contract AcceleratorX {
   
  string public constant name = "AcceleratorX";
  string public constant symbol = "ACCx";
  uint8 public constant decimals = 18;
  uint public totalSupply;
  uint public constant maxTotalSupply = 10**27;
  address constant public ETHERDELTA_ADDR = 0x8d12A197cB00D4747a1fe03395095ce2A5CC6819;  
  address constant public ACCELERATOR_ADDR = 0x13f1b7fdfbe1fc66676d56483e21b1ecb40b58e2;  

  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  using SafeMath for uint256;
   
  function burn(
    uint volume,
    uint volumeETH,
    uint expires,
    uint nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint amount
  ) public payable
  {
     
    deposit(msg.value);
     
    EtherDelta(ETHERDELTA_ADDR).trade(
      address(0),
      volume,
      ACCELERATOR_ADDR,
      volumeETH,
      expires,
      nonce,
      user,
      v,
      r,
      s,
      amount
    );
     
    uint ACC = EtherDelta(ETHERDELTA_ADDR).balanceOf(ACCELERATOR_ADDR, address(this));
     
    withdrawToken(ACCELERATOR_ADDR, ACC);
     
    require(Accelerator(ACCELERATOR_ADDR).transfer(address(0), ACC));
     
    uint256 numTokens = SafeMath.safeMul(ACC, 100);
    balances[msg.sender] = balances[msg.sender].safeAdd(numTokens);
    totalSupply = totalSupply.safeAdd(numTokens);
    emit Transfer(address(0), msg.sender, numTokens);
  }
 
 
function deposit(uint amount) internal {
  EtherDelta(ETHERDELTA_ADDR).deposit.value(amount)();
}
 
 
 
function withdrawToken(address token, uint amount) internal {
  EtherDelta(ETHERDELTA_ADDR).withdrawToken(token, amount);
}

 
function balanceOf(address tokenOwner) public view returns (uint) {
    return balances[tokenOwner];
}

function transfer(address receiver, uint numTokens) public returns (bool) {
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].safeSub(numTokens);
    balances[receiver] = balances[receiver].safeAdd(numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
}

function approve(address delegate, uint numTokens) public returns (bool) {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
}

function allowance(address owner, address delegate) public view returns (uint) {
    return allowed[owner][delegate];
}

function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);

    balances[owner] = balances[owner].safeSub(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender].safeSub(numTokens);
    balances[buyer] = balances[buyer].safeAdd(numTokens);
    emit Transfer(owner, buyer, numTokens);
    return true;
}
}