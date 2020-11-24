 

pragma solidity ^0.4.23;

 
 
 
 

pragma solidity ^0.4.23;


 
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

contract DexBrokerage is Ownable {
  using SafeMath for uint256;

  address public feeAccount;
  uint256 public makerFee;
  uint256 public takerFee;
  uint256 public inactivityReleasePeriod;
  mapping (address => bool) public approvedCurrencyTokens;
  mapping (address => uint256) public invalidOrder;
  mapping (address => mapping (address => uint256)) public tokens;
  mapping (address => bool) public admins;
  mapping (address => uint256) public lastActiveTransaction;
  mapping (bytes32 => uint256) public orderFills;
  mapping (bytes32 => bool) public withdrawn;

  event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address maker, address taker);
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);
  event MakerFeeUpdated(uint256 oldFee, uint256 newFee);
  event TakerFeeUpdated(uint256 oldFee, uint256 newFee);

  modifier onlyAdmin {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

  constructor(uint256 _makerFee, uint256 _takerFee , address _feeAccount, uint256 _inactivityReleasePeriod) public {
    owner = msg.sender;
    makerFee = _makerFee;
    takerFee = _takerFee;
    feeAccount = _feeAccount;
    inactivityReleasePeriod = _inactivityReleasePeriod;
  }

  function approveCurrencyTokenAddress(address currencyTokenAddress, bool isApproved) onlyAdmin public {
    approvedCurrencyTokens[currencyTokenAddress] = isApproved;
  }

  function invalidateOrdersBefore(address user, uint256 nonce) onlyAdmin public {
    require(nonce >= invalidOrder[user]);
    invalidOrder[user] = nonce;
  }

  function setMakerFee(uint256 _makerFee) onlyAdmin public {
     
    uint256 oldFee = makerFee;
    if (_makerFee > 10 finney) {
      _makerFee = 10 finney;
    }
    require(makerFee != _makerFee);
    makerFee = _makerFee;
    emit MakerFeeUpdated(oldFee, makerFee);
  }

  function setTakerFee(uint256 _takerFee) onlyAdmin public {
     
    uint256 oldFee = takerFee;
    if (_takerFee > 20 finney) {
      _takerFee = 20 finney;
    }
    require(takerFee != _takerFee);
    takerFee = _takerFee;
    emit TakerFeeUpdated(oldFee, takerFee);
  }

  function setInactivityReleasePeriod(uint256 expire) onlyAdmin public returns (bool) {
    require(expire <= 50000);
    inactivityReleasePeriod = expire;
    return true;
  }

  function setAdmin(address admin, bool isAdmin) onlyOwner public {
    admins[admin] = isAdmin;
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

  function withdraw(address token, uint256 amount) public returns (bool) {
    require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      require(ERC20(token).transfer(msg.sender, amount));
    }
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    return true;
  }

  function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 gasCost) onlyAdmin public returns (bool) {
     
    if (gasCost > 30 finney) gasCost = 30 finney;

    if(token == address(0)){
      require(tokens[address(0)][user] >= gasCost.add(amount));
    } else {
      require(tokens[address(0)][user] >= gasCost);
      require(tokens[token][user] >= amount);
    }

    bytes32 hash = keccak256(address(this), token, amount, user, nonce);
    require(!withdrawn[hash]);
    withdrawn[hash] = true;
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);

    if(token == address(0)){
      tokens[address(0)][user] = tokens[address(0)][user].sub(gasCost.add(amount));
      tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(gasCost);
      user.transfer(amount);
    } else {
      tokens[token][user] = tokens[token][user].sub(amount);
      tokens[address(0)][user] = tokens[address(0)][user].sub(gasCost);
      tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(gasCost);
      require(ERC20(token).transfer(user, amount));
    }
    lastActiveTransaction[user] = block.number;
    emit Withdraw(token, user, amount, tokens[token][user]);
    return true;
  }

  function balanceOf(address token, address user) view public returns (uint256) {
    return tokens[token][user];
  }

     


  function trade(uint256[11] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) onlyAdmin public returns (bool) {
    uint256 price = tradeValues[0].mul(1 ether).div(tradeValues[1]);
    require(price >= tradeValues[7].mul(1 ether).div(tradeValues[8]).sub(100000 wei));
    require(price <= tradeValues[4].mul(1 ether).div(tradeValues[3]).add(100000 wei));
    require(block.number < tradeValues[9]);
    require(block.number < tradeValues[5]);
    require(invalidOrder[tradeAddresses[2]] <= tradeValues[2]);
    require(invalidOrder[tradeAddresses[3]] <= tradeValues[6]);
    bytes32 orderHash = keccak256(address(this), tradeAddresses[0], tradeValues[7], tradeAddresses[1], tradeValues[8], tradeValues[9], tradeValues[2], tradeAddresses[2]);
    bytes32 tradeHash = keccak256(address(this), tradeAddresses[1], tradeValues[3], tradeAddresses[0], tradeValues[4], tradeValues[5], tradeValues[6], tradeAddresses[3]);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == tradeAddresses[2]);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", tradeHash), v[1], rs[2], rs[3]) == tradeAddresses[3]);
    require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[0]);
    require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= tradeValues[1]);
    if ((tradeAddresses[0] == address(0) || tradeAddresses[1] == address(0)) && tradeValues[10] > 30 finney) tradeValues[10] = 30 finney;
    if ((approvedCurrencyTokens[tradeAddresses[0]] == true || approvedCurrencyTokens[tradeAddresses[1]] == true) && tradeValues[10] > 10 ether) tradeValues[10] = 10 ether;

    if(tradeAddresses[0] == address(0) || approvedCurrencyTokens[tradeAddresses[0]] == true){

      require(orderFills[orderHash].add(tradeValues[1]) <= tradeValues[8]);
      require(orderFills[tradeHash].add(tradeValues[1]) <= tradeValues[3]);

       
      uint256 valueInTokens = tradeValues[1];

       
      tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(valueInTokens);
      tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(valueInTokens);

       
      tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[0]);
      tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(takerFee.mul(tradeValues[0]).div(1 ether));
      tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[10]);

       
      tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[0]);
      tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].sub(makerFee.mul(tradeValues[0]).div(1 ether));

       
      tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(makerFee.mul(tradeValues[0]).div(1 ether));
      tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(takerFee.mul(tradeValues[0]).div(1 ether));
      tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(tradeValues[10]);

      orderFills[orderHash] = orderFills[orderHash].add(tradeValues[1]);
      orderFills[tradeHash] = orderFills[tradeHash].add(tradeValues[1]);

    } else {

      require(orderFills[orderHash].add(tradeValues[0]) <= tradeValues[7]);
      require(orderFills[tradeHash].add(tradeValues[0]) <= tradeValues[4]);

       
      uint256 valueInEth = tradeValues[1];

       
      tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[0]);
      tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[0]);

       
      tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(valueInEth);
      tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(makerFee.mul(valueInEth).div(1 ether));

       
      tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(valueInEth);
      tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].sub(takerFee.mul(valueInEth).div(1 ether));
      tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].sub(tradeValues[10]);

       
      tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(makerFee.mul(valueInEth).div(1 ether));
      tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(takerFee.mul(valueInEth).div(1 ether));
      tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(tradeValues[10]);

      orderFills[orderHash] = orderFills[orderHash].add(tradeValues[0]);
      orderFills[tradeHash] = orderFills[tradeHash].add(tradeValues[0]);
    }

    lastActiveTransaction[tradeAddresses[2]] = block.number;
    lastActiveTransaction[tradeAddresses[3]] = block.number;

    emit Trade(tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeAddresses[2], tradeAddresses[3]);
    return true;
  }

}