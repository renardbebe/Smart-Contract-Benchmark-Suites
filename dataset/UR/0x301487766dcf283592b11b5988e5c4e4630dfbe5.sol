 

pragma solidity ^0.4.24;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
   
  function totalSupply() constant public returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant public returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) public returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}

contract ReserveToken is StandardToken, SafeMath {
  address public minter;
  constructor() public {
    minter = msg.sender;
  }
  function create(address account, uint amount) public {
    if (msg.sender != minter) revert();
    balances[account] = safeAdd(balances[account], amount);
    totalSupply = safeAdd(totalSupply, amount);
  }
  function destroy(address account, uint amount) public {
    if (msg.sender != minter) revert();
    if (balances[account] < amount) revert();
    balances[account] = safeSub(balances[account], amount);
    totalSupply = safeSub(totalSupply, amount);
  }
}

contract AccountLevels {
   
   
   
   
  function accountLevel(address user) constant public returns(uint) {}
}

contract AccountLevelsTest is AccountLevels {
  mapping (address => uint) public accountLevels;

  function setAccountLevel(address user, uint level) public {
    accountLevels[user] = level;
  }

  function accountLevel(address user) constant public returns(uint) {
    return accountLevels[user];
  }
}

contract EDex is SafeMath {
  address public admin;  
  address public feeAccount;  
  address public accountLevelsAddr;  
  uint public feeMake;  
  uint public feeTake;  
  uint public feeRebate;  
  mapping (address => mapping (address => uint)) public tokens;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint)) public orderFills;  

  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor (address admin_, address feeAccount_, address accountLevelsAddr_, uint feeMake_, uint feeTake_, uint feeRebate_) public {
    admin = admin_;
    feeAccount = feeAccount_;
    accountLevelsAddr = accountLevelsAddr_;
    feeMake = feeMake_;
    feeTake = feeTake_;
    feeRebate = feeRebate_;
  }

  function () public {
    revert();
  }

  function changeAdmin(address admin_) public {
    if (msg.sender != admin) revert();
    admin = admin_;
  }

  function changeAccountLevelsAddr(address accountLevelsAddr_) public {
    if (msg.sender != admin) revert();
    accountLevelsAddr = accountLevelsAddr_;
  }

  function changeFeeAccount(address feeAccount_) public {
    if (msg.sender != admin) revert();
    feeAccount = feeAccount_;
  }

  function changeFeeMake(uint feeMake_) public {
    if (msg.sender != admin) revert();
    feeMake = feeMake_;
  }

  function changeFeeTake(uint feeTake_) public {
    if (msg.sender != admin) revert();
    feeTake = feeTake_;
  }

  function changeFeeRebate(uint feeRebate_) public {
    if (msg.sender != admin) revert();
    feeRebate = feeRebate_;
  }

  function deposit() payable public {
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount) public {
    if (tokens[0][msg.sender] < amount) revert();
    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
    if (!msg.sender.call.value(amount)()) revert();
    emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) public {
     
    if (token==0) revert();
    if (!Token(token).transferFrom(msg.sender, this, amount)) revert();
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) public {
    if (token==0) revert();
    if (tokens[token][msg.sender] < amount) revert();
    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    if (!Token(token).transfer(msg.sender, amount)) revert();
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant public returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    orders[msg.sender][hash] = true;
    emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
     
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
      block.number <= expires &&
      safeAdd(orderFills[user][hash], amount) <= amountGet
    )) revert();
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
    emit Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
    uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
    uint feeRebateXfer = 0;
    if (accountLevelsAddr != 0x0) {
      uint accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
      if (accountLevel==1) feeRebateXfer = safeMul(amount, feeRebate) / (1 ether);
      if (accountLevel==2) feeRebateXfer = feeTakeXfer;
    }
    tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
    tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(safeAdd(amount, feeRebateXfer), feeMakeXfer));
    tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
    tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
    tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant public returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant public returns(uint) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    uint available1 = safeSub(amountGet, orderFills[user][hash]);
    uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
    if (available1<available2) return available1;
    return available2;
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant public returns(uint) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == msg.sender)) revert();
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }
}