 

 
pragma solidity ^0.4.23;

 
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
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

   
  function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a ** b;
    require(c >= a);
    return c;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
 
 

contract DexPayments is Ownable {
  using SafeMath for uint256;

  address public feeAccount;
  uint256 public inactivityReleasePeriod;
  mapping (address => mapping (address => uint256)) public tokens;
  mapping (address => uint256) public lastActiveTransaction;
  mapping (address => bool) public hardWithdrawRequested;
  mapping (address => bool) public admins;
  mapping (bytes32 => bool) public withdrawn;
  mapping (bytes32 => uint256) public orderFills;

  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Payment(uint256 amountToPay, uint256 paymentNonce, uint256 orderExpires, address paymentToken, address merchant, address customer);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);
  event RequestHardWithdraw(address user, bool request);
  event ProcessingFeeUpdated(uint256 oldFee, uint256 newFee);

  modifier onlyAdmin {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

  constructor(address _feeAccount, uint256 _inactivityReleasePeriod) public {
    owner = msg.sender;
    feeAccount = _feeAccount;
    inactivityReleasePeriod = _inactivityReleasePeriod;
  }

  function requestHardWithdraw(bool request) public {
    require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
    hardWithdrawRequested[msg.sender] = request;
    lastActiveTransaction[msg.sender] = block.number;
    emit RequestHardWithdraw(msg.sender, request);
  }

  function withdraw(address token, uint256 amount) public returns (bool) {
    require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
    require(tokens[token][msg.sender] >= amount);
    require(hardWithdrawRequested[msg.sender] == true);

    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      require(ERC20(token).transfer(msg.sender, amount));
    }
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    return true;
  }

  function setInactivityReleasePeriod(uint256 expire) onlyAdmin public returns (bool) {
    require(expire <= 100000);
    require(expire >= 6000);
    inactivityReleasePeriod = expire;
    return true;
  }

  function setAdmin(address admin, bool isAdmin) onlyOwner public {
    admins[admin] = isAdmin;
  }

  function setFeeAccount(address newFeeAccount) onlyOwner public {
    feeAccount = newFeeAccount;
  }

  function depositToken(address token, uint256 amount) public {
    receiveTokenDeposit(token, msg.sender, amount);
  }

  function receiveTokenDeposit(address token, address from, uint256 amount) public {
    tokens[token][from] = tokens[token][from].add(amount);
    lastActiveTransaction[from] = block.number;
    require(ERC20(token).transferFrom(from, address(this), amount));
    emit Deposit(token, from, amount, tokens[token][from]);
  }

  function deposit() payable public {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    lastActiveTransaction[msg.sender] = block.number;
    emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

  function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 gasCost) onlyAdmin public returns (bool) {
     
    require(gasCost <= amount);

     
    if(token == address(0)){
      require(tokens[address(0)][user] >= gasCost.add(amount));
    } else {
      require(tokens[token][user] >= gasCost.add(amount));
    }

    bytes32 hash = keccak256(address(this), token, amount, user, nonce, gasCost);
    require(!withdrawn[hash]);
    withdrawn[hash] = true;
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);

    if(token == address(0)){
      tokens[address(0)][user] = tokens[address(0)][user].sub(gasCost.add(amount));
      tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(gasCost);
      user.transfer(amount);
    } else {
      tokens[token][user] = tokens[token][user].sub(gasCost.add(amount));
      tokens[token][feeAccount] = tokens[token][feeAccount].add(gasCost);
      require(ERC20(token).transfer(user, amount));
    }
    lastActiveTransaction[user] = block.number;
    emit Withdraw(token, user, amount, tokens[token][user]);
    return true;
  }

  function balanceOf(address token, address user) view public returns (uint256) {
    return tokens[token][user];
  }

     

  function sendPayment(uint256[4] paymentValues, address[3] paymentAddresses, uint8 v, bytes32[2] rs) onlyAdmin public returns (bool) {
     
    require(block.number < paymentValues[2]);
    bytes32 paymentHash = keccak256(address(this), paymentValues[0], paymentValues[1], paymentValues[2], paymentValues[3], paymentAddresses[0], paymentAddresses[1]);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", paymentHash), v, rs[0], rs[1]) == paymentAddresses[2]);

     
    require(tokens[paymentAddresses[0]][paymentAddresses[2]] >= paymentValues[0]);

     
    require(paymentValues[3] <= paymentValues[0]);

     
    require(orderFills[paymentHash].add(paymentValues[0]) <= paymentValues[0]);

     
    tokens[paymentAddresses[0]][paymentAddresses[2]] = tokens[paymentAddresses[0]][paymentAddresses[2]].sub(paymentValues[0]);
    tokens[paymentAddresses[0]][paymentAddresses[1]] = tokens[paymentAddresses[0]][paymentAddresses[1]].add(paymentValues[0]);

     
    tokens[paymentAddresses[0]][paymentAddresses[1]] = tokens[paymentAddresses[0]][paymentAddresses[1]].sub(paymentValues[3]);
    tokens[paymentAddresses[0]][feeAccount] = tokens[paymentAddresses[0]][feeAccount].add(paymentValues[3]);

    orderFills[paymentHash] = orderFills[paymentHash].add(paymentValues[0]);

    emit Payment(paymentValues[0], paymentValues[1], paymentValues[2], paymentAddresses[0], paymentAddresses[1], paymentAddresses[2]);

    lastActiveTransaction[paymentAddresses[1]] = block.number;
    lastActiveTransaction[paymentAddresses[2]] = block.number;

    return true;
  }

}