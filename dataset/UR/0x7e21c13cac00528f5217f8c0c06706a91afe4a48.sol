 

pragma solidity ^0.4.24;

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
contract SeedDex {
  
  using SafeMath for uint;

   

  address public admin;  
  address constant public FicAddress = 0x0DD83B5013b2ad7094b1A7783d96ae0168f82621;   
  address public manager;  
  address public feeAccount;  
  uint public feeTakeMaker;  
  uint public feeTakeSender;  
  uint public feeTakeMakerFic;
  uint public feeTakeSenderFic;
  bool private depositingTokenFlag;  
  mapping (address => mapping (address => uint)) public tokens;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint)) public orderFills;  
  address public predecessor;  
  address public successor;  
  uint16 public version;  

   
  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address indexed user,bytes32 hash,uint amount);
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address indexed user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give, uint256 timestamp);
  event Deposit(address token, address indexed user, uint amount, uint balance);
  event Withdraw(address token, address indexed user, uint amount, uint balance);
  event FundsMigrated(address indexed user, address newContract);
  event LogEvent(string msg,bytes32 data);

   
  modifier isAdmin() {
      require(msg.sender == admin);
      _;
  }

   
  modifier isManager() {
     require(msg.sender == manager || msg.sender == admin );
      _;
  }
    
   
  function SeedDex(address admin_, address manager_, address feeAccount_, uint feeTakeMaker_, uint feeTakeSender_,  uint feeTakeMakerFic_, uint feeTakeSenderFic_,  address predecessor_) public {
    admin = admin_;
    manager = manager_;
    feeAccount = feeAccount_;
    feeTakeMaker = feeTakeMaker_;
    feeTakeSender = feeTakeSender_;
    feeTakeMakerFic = feeTakeMakerFic_;
    feeTakeSenderFic = feeTakeSenderFic_;
    depositingTokenFlag = false;
    predecessor = predecessor_;
    
    if (predecessor != address(0)) {
      version = SeedDex(predecessor).version() + 1;
    } else {
      version = 1;
    }
  }

   
  function() public {
    revert();
  }

   
  function changeAdmin(address admin_) public isAdmin {
    require(admin_ != address(0));
    admin = admin_;
  }

  
  function changeManager(address manager_) public isManager {
    require(manager_ != address(0));
    manager = manager_;
  }

   
  function changeFeeAccount(address feeAccount_) public isAdmin {
    feeAccount = feeAccount_;
  }

 
  function changeFeeTakeMaker(uint feeTakeMaker_) public isManager {
    feeTakeMaker = feeTakeMaker_;
  }
  
  function changeFeeTakeSender(uint feeTakeSender_) public isManager {
    feeTakeSender = feeTakeSender_;
  }

  function changeFeeTakeMakerFic(uint feeTakeMakerFic_) public isManager {
    feeTakeMakerFic = feeTakeMakerFic_;
  }
  
  function changeFeeTakeSenderFic(uint feeTakeSenderFic_) public isManager {
    feeTakeSenderFic = feeTakeSenderFic_;
  }
  
   
  function setSuccessor(address successor_) public isAdmin {
    require(successor_ != address(0));
    successor = successor_;
  }
  
   
   
   

   
  function deposit() public payable {
    tokens[0][msg.sender] = tokens[0][msg.sender].add(msg.value);
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

   
  function withdraw(uint amount) public {
    require(tokens[0][msg.sender] >= amount);
    tokens[0][msg.sender] = tokens[0][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

   
  function depositToken(address token, uint amount) public {
    require(token != 0);
    depositingTokenFlag = true;
    require(IERC20(token).transferFrom(msg.sender, this, amount));
    depositingTokenFlag = false;
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
 }

   
  function tokenFallback( address sender, uint amount, bytes data) public returns (bool ok) {
      if (depositingTokenFlag) {
         
        return true;
      } else {
         
         
        revert();
      }
  }
  
   
  function withdrawToken(address token, uint amount) public {
    require(token != 0);
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    require(IERC20(token).transfer(msg.sender, amount));
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

   
  function balanceOf(address token, address user) public constant returns (uint) {
    return tokens[token][user];
  }

   
   
   

   
  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    uint amount;
    orders[msg.sender][hash] = true;
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, hash, amount);
  }

   
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require((
      (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
      block.number <= expires &&
      orderFills[user][hash].add(amount) <= amountGet
    ));
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = orderFills[user][hash].add(amount);
    Trade(tokenGet, amount, tokenGive, amountGive.mul(amount) / amountGet, user, msg.sender,now);
  }
  
   
  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    
    uint feeTakeXferM = 0;
    uint feeTakeXferS = 0;
    uint feeTakeXferFicM = 0;
    uint feeTakeXferFicS = 0;
    
    feeTakeXferM = amount.mul(feeTakeMaker).div(1 ether);
    feeTakeXferS = amount.mul(feeTakeSender).div(1 ether);
    feeTakeXferFicM = amount.mul(feeTakeMakerFic).div(1 ether);
    feeTakeXferFicS = amount.mul(feeTakeSenderFic).div(1 ether);
    
    
    
    if (tokenGet == FicAddress || tokenGive == FicAddress) {
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXferFicS));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(feeTakeXferFicM));
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeTakeXferFicM);
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeTakeXferFicS);
    }
  
    else {
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXferS));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(feeTakeXferM));
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeTakeXferM);
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeTakeXferS);
    }
    
    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
  
  }

   
  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public constant returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
      )) { 
      return false;
    } else {
      return true;
    }
  }

   
  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public constant returns(uint) {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
      block.number <= expires
      )) {
      return 0;
    }
    uint[2] memory available;
    available[0] = amountGet.sub(orderFills[user][hash]);
    available[1] = tokens[tokenGive][user].mul(amountGet) / amountGive;
    if (available[0] < available[1]) {
      return available[0];
    } else {
      return available[1];
    }
  }

   
  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public constant returns(uint) {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

   
  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 hash = keccak256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require ((orders[msg.sender][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender));
    orderFills[msg.sender][hash] = amountGet;
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }


  
   
   
   
  
   
  function migrateFunds(address newContract, address[] tokens_) public {
  
    require(newContract != address(0));
    
    SeedDex newExchange = SeedDex(newContract);

     
    uint etherAmount = tokens[0][msg.sender];
    if (etherAmount > 0) {
      tokens[0][msg.sender] = 0;
      newExchange.depositForUser.value(etherAmount)(msg.sender);
    }

     
    for (uint16 n = 0; n < tokens_.length; n++) {
      address token = tokens_[n];
      require(token != address(0));  
      uint tokenAmount = tokens[token][msg.sender];
      
      if (tokenAmount != 0) {      
        require(IERC20(token).approve(newExchange, tokenAmount));
        tokens[token][msg.sender] = 0;
        newExchange.depositTokenForUser(token, tokenAmount, msg.sender);
      }
    }

    FundsMigrated(msg.sender, newContract);
  }
  
   
  function depositForUser(address user) public payable {
    require(user != address(0));
    require(msg.value > 0);
    tokens[0][user] = tokens[0][user].add(msg.value);
  }
  
   
  function depositTokenForUser(address token, uint amount, address user) public {
    require(token != address(0));
    require(user != address(0));
    require(amount > 0);
    depositingTokenFlag = true;
    require(IERC20(token).transferFrom(msg.sender, this, amount));
    depositingTokenFlag = false;
    tokens[token][user] = tokens[token][user].add(amount);
  }
  function checkshash (address tokenGet) public{
      bytes32 hash = keccak256(tokenGet);
      LogEvent('hash',hash);
  }
}