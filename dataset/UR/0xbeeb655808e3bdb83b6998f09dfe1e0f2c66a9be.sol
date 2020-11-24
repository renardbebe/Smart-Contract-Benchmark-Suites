 

pragma solidity ^0.4.18;

 

contract AccountLevels {
   
   
   
   
  function accountLevel(address user) public constant returns(uint);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract SwissCryptoExchange {
  using SafeMath for uint256;

   
  address public admin;  
  address public feeAccount;  
  address public accountLevelsAddr;  
  uint256 public feeMake;  
  uint256 public feeTake;  
  uint256 public feeRebate;  
  mapping (address => mapping (address => uint256)) public tokens;  
  mapping (address => bool) public whitelistedTokens;  
  mapping (address => bool) public whitelistedUsers;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint256)) public orderFills;  

   
  event Order(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user);
  event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address get, address give);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

   
  function SwissCryptoExchange(
    address _admin,
    address _feeAccount,
    address _accountLevelsAddr,
    uint256 _feeMake,
    uint256 _feeTake,
    uint256 _feeRebate
  )
    public
  {
     
    require(_admin != 0x0);

     
    admin = _admin;
    feeAccount = _feeAccount;
    accountLevelsAddr = _accountLevelsAddr;
    feeMake = _feeMake;
    feeTake = _feeTake;
    feeRebate = _feeRebate;

     
    whitelistedTokens[0x0] = true;
  }

   
  modifier onlyAdmin() { 
    require(msg.sender == admin);
    _; 
  }

   
  function () public payable {
    revert();
  }

   
  function changeAdmin(address _admin) public onlyAdmin {
     
    require(_admin != 0x0 && admin != _admin);

     
    admin = _admin;
  }

   
  function changeAccountLevelsAddr(address _accountLevelsAddr) public onlyAdmin {
     
    accountLevelsAddr = _accountLevelsAddr;
  }

   
  function changeFeeAccount(address _feeAccount) public onlyAdmin {
     
    require(_feeAccount != 0x0);

     
    feeAccount = _feeAccount;
  }

   
  function changeFeeMake(uint256 _feeMake) public onlyAdmin {
     
    feeMake = _feeMake;
  }

   
  function changeFeeTake(uint256 _feeTake) public onlyAdmin {
     
    require(_feeTake >= feeRebate);

     
    feeTake = _feeTake;
  }

   
  function changeFeeRebate(uint256 _feeRebate) public onlyAdmin {
     
    require(_feeRebate <= feeTake);

     
    feeRebate = _feeRebate;
  }

   
  function addWhitelistedTokenAddr(address token) public onlyAdmin {
     
    require(token != 0x0 && !whitelistedTokens[token]);

     
    whitelistedTokens[token] = true;
  }

   
  function removeWhitelistedTokenAddr(address token) public onlyAdmin {
     
    require(token != 0x0 && whitelistedTokens[token]);

     
    whitelistedTokens[token] = false;
  }

   
  function addWhitelistedUserAddr(address user) public onlyAdmin {
     
    require(user != 0x0 && !whitelistedUsers[user]);

     
    whitelistedUsers[user] = true;
  }

   
  function removeWhitelistedUserAddr(address user) public onlyAdmin {
     
    require(user != 0x0 && whitelistedUsers[user]);

     
    whitelistedUsers[user] = false;
  }

   
  function deposit() public payable {
     
    require(whitelistedUsers[msg.sender]);

     
    tokens[0x0][msg.sender] = tokens[0x0][msg.sender].add(msg.value);

     
    Deposit(0x0, msg.sender, msg.value, tokens[0x0][msg.sender]);
  }

   
  function withdraw(uint256 amount) public {
     
    require(tokens[0x0][msg.sender] >= amount);
  
     
    tokens[0x0][msg.sender] = tokens[0x0][msg.sender].sub(amount);

     
    msg.sender.transfer(amount);

     
    Withdraw(0x0, msg.sender, amount, tokens[0x0][msg.sender]);
  }

   
  function depositToken(address token, uint256 amount)
    public
  {
     
     
    require(token != 0x0 && whitelistedTokens[token]);
      
     
    require(whitelistedUsers[msg.sender]);

     
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    
     
    require(ERC20(token).transferFrom(msg.sender, address(this), amount));
  
     
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

   
  function withdrawToken(address token, uint256 amount) public {
     
    require(token != 0x0);

     
    require(tokens[token][msg.sender] >= amount);

     
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    
     
    require(ERC20(token).transfer(msg.sender, amount));

     
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

   
  function balanceOf(address token, address user)
    public
    constant
    returns (uint256)
  {
    return tokens[token][user];
  }

   
  function order(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce
  )
    public
  {
     
    require(whitelistedUsers[msg.sender]);

     
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

     
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
     
    orders[msg.sender][hash] = true;

     
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

   
  function cancelOrder(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
     
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
     
    require(validateOrderHash(hash, msg.sender, v, r, s));
    
     
    orderFills[msg.sender][hash] = amountGet;

     
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

   
  function trade(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 amount 
  )
    public
  {
     
    require(whitelistedUsers[msg.sender]);

     
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

     
    require(block.number <= expires);

     
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    
     
    require(validateOrderHash(hash, user, v, r, s));

     
    require(SafeMath.add(orderFills[user][hash], amount) <= amountGet); 
    
     
    orderFills[user][hash] = orderFills[user][hash].add(amount);

     
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    
     
    Trade(tokenGet, amount, tokenGive, SafeMath.mul(amountGive, amount).div(amountGet), user, msg.sender);
  }

   
  function testTrade(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 amount,
    address sender
  )
    public
    constant
    returns(bool)
  {
     
    require(whitelistedUsers[user] && whitelistedUsers[sender]);

     
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

     
    require(tokens[tokenGet][sender] >= amount);

     
    return availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount;
  }

   
  function availableVolume(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    constant
    returns (uint256)
  {
     
    require(whitelistedUsers[user]);

     
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

     
    bytes32 hash = keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce);

     
    if (!(validateOrderHash(hash, user, v, r, s) && block.number <= expires)) {
      return 0;
    }

     
     
     
     
     
     
     
     
    if (SafeMath.sub(amountGet, orderFills[user][hash]) < SafeMath.mul(tokens[tokenGive][user], amountGet).div(amountGive)) {
      return SafeMath.sub(amountGet, orderFills[user][hash]);
    }

    return SafeMath.mul(tokens[tokenGive][user], amountGet).div(amountGive);
  }

   
  function amountFilled(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    uint256 expires,
    uint256 nonce,
    address user
  )
    public
    constant
    returns (uint256)
  {
     
    require(whitelistedUsers[user]);

     
    require(whitelistedTokens[tokenGet] && whitelistedTokens[tokenGive]);

     
    return orderFills[user][keccak256(address(this), tokenGet, amountGet, tokenGive, amountGive, expires, nonce)];
  }

     
  function tradeBalances(
    address tokenGet,
    uint256 amountGet,
    address tokenGive,
    uint256 amountGive,
    address user,
    uint256 amount
  )
    private
  {
     
    uint256 feeMakeXfer = amount.mul(feeMake).div(1 ether);
    uint256 feeTakeXfer = amount.mul(feeTake).div(1 ether);
    uint256 feeRebateXfer = 0;
    
     
    if (accountLevelsAddr != 0x0) {
      uint256 accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
      if (accountLevel == 1) {
        feeRebateXfer = amount.mul(feeRebate).div(1 ether);
      } else if (accountLevel == 2) {
        feeRebateXfer = feeTakeXfer;
      }
    }

     
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.add(feeRebateXfer).sub(feeMakeXfer));
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeMakeXfer.add(feeTakeXfer).sub(feeRebateXfer));
    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
  }

   
  function validateOrderHash(
    bytes32 hash,
    address user,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    private
    constant
    returns (bool)
  {
    return (
      orders[user][hash] ||
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user
    );
  }
}