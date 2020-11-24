 

 


 

 
library BytesDeserializer {

   
  function slice32(bytes b, uint offset) constant returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function sliceAddress(bytes b, uint offset) constant returns (address) {
    bytes32 out;

    for (uint i = 0; i < 20; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
    }
    return address(uint(out));
  }

   
  function slice16(bytes b, uint offset) constant returns (bytes16) {
    bytes16 out;

    for (uint i = 0; i < 16; i++) {
      out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function slice4(bytes b, uint offset) constant returns (bytes4) {
    bytes4 out;

    for (uint i = 0; i < 4; i++) {
      out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

   
  function slice2(bytes b, uint offset) constant returns (bytes2) {
    bytes2 out;

    for (uint i = 0; i < 2; i++) {
      out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }



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




 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
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


interface InvestorToken {
  function transferInvestorTokens(address, uint256);
}

 
 
contract Exchange is RBAC {
    using SafeMath for uint256;
    using BytesDeserializer for bytes;

     
     
    string public constant ROLE_FORCED = "forced";
    string public constant ROLE_TRANSFER_TOKENS = "transfer tokens";
    string public constant ROLE_TRANSFER_INVESTOR_TOKENS = "transfer investor tokens";
    string public constant ROLE_CLAIM = "claim";
    string public constant ROLE_WITHDRAW = "withdraw";
    string public constant ROLE_TRADE = "trade";
    string public constant ROLE_CHANGE_DELAY = "change delay";
    string public constant ROLE_SET_FEEACCOUNT = "set feeaccount";
    string public constant ROLE_TOKEN_WHITELIST = "token whitelist user";


     
    mapping(bytes32 => bool) public withdrawn;
     
    mapping(bytes32 => bool) public transferred;
     
    mapping(address => bool) public tokenWhitelist;
     
    mapping(address => uint256) public tokensTotal;
     
    mapping(address => mapping(address => uint256)) public balanceOf;
     
    mapping (bytes32 => uint256) public orderFilled;
     
    address public feeAccount;
     
     
     
    uint256 public delay;

     
    event TokenWhitelistUpdated(address token, bool status);
     
    event FeeAccountChanged(address newFeeAccocunt);
     
    event DelayChanged(uint256 newDelay);
     
    event Deposited(address token, address who, uint256 amount, uint256 balance);
     
    event Forced(address token, address who, uint256 amount);
     
    event Withdrawn(address token, address who, uint256 amount, uint256 balance);
     
    event Requested(address token, address who, uint256 amount, uint256 index);
     
    event TransferredInvestorTokens(address, address, address, uint256);
     
    event TransferredTokens(address, address, address, uint256, uint256, uint256);
     
    event OrderExecuted(
        bytes32 orderHash,
        address maker,
        address baseToken,
        address quoteToken,
        address feeToken,
        uint256 baseAmountFilled,
        uint256 quoteAmountFilled,
        uint256 feePaid,
        uint256 baseTokenBalance,
        uint256 quoteTokenBalance,
        uint256 feeTokenBalance
    );

     
    struct Withdrawal {
      address user;
      address token;
      uint256 amount;
      uint256 createdAt;
      bool executed;
    }

     
     
    Withdrawal[] withdrawals;

    enum OrderType {Buy, Sell}

     
     
     
    struct Order {
      OrderType orderType;
      address maker;
      address baseToken;
      address quoteToken;
      address feeToken;
      uint256 amount;
      uint256 priceNumerator;
      uint256 priceDenominator;
      uint256 feeNumerator;
      uint256 feeDenominator;
      uint256 expiresAt;
      uint256 nonce;
    }

     
     
    function Exchange(uint256 _delay) {
      delay = _delay;

      feeAccount = msg.sender;
      addRole(msg.sender, ROLE_FORCED);
      addRole(msg.sender, ROLE_TRANSFER_TOKENS);
      addRole(msg.sender, ROLE_TRANSFER_INVESTOR_TOKENS);
      addRole(msg.sender, ROLE_CLAIM);
      addRole(msg.sender, ROLE_WITHDRAW);
      addRole(msg.sender, ROLE_TRADE);
      addRole(msg.sender, ROLE_CHANGE_DELAY);
      addRole(msg.sender, ROLE_SET_FEEACCOUNT);
      addRole(msg.sender, ROLE_TOKEN_WHITELIST);
    }

     
     
     
    function updateTokenWhitelist(address token, bool status) external onlyRole(ROLE_TOKEN_WHITELIST) {
      tokenWhitelist[token] = status;

      TokenWhitelistUpdated(token, status);
    }


     
     
    function setFeeAccount(address _feeAccount) external onlyRole(ROLE_SET_FEEACCOUNT) {
      feeAccount = _feeAccount;

      FeeAccountChanged(feeAccount);
    }

     
     
    function setDelay(uint256 _delay) external onlyRole(ROLE_CHANGE_DELAY) {
      require(_delay < 2 weeks);
      delay = _delay;

      DelayChanged(delay);
    }

     
     
     
     
     
     
    function depositTokens(ERC20 token, uint256 amount) external returns(bool) {
      depositInternal(token, amount);
      require(token.transferFrom(msg.sender, this, amount));
      return true;
    }

     
     
     
    function depositEthers() external payable returns(bool) {
      depositInternal(address(0), msg.value);
      return true;
    }

     
     
     
     
     
     
     
     
     
    function withdrawAdmin(ERC20 token, address user, uint256 amount, uint256 fee, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external onlyRole(ROLE_WITHDRAW) {
      bytes32 hash = keccak256(this, token, user, amount, fee, nonce);
      require(withdrawn[hash] == false);
      require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
      withdrawn[hash] = true;

      withdrawInternal(token, user, amount, fee);
    }

     
     
     
     
    function withdrawForced(ERC20 token, address user, uint256 amount) external onlyRole(ROLE_FORCED) {
      Forced(token, user, amount);
      withdrawInternal(token, user, amount, 0);
    }

     
     
     
     
    function withdrawRequest(ERC20 token, uint256 amount) external returns(uint256) {
      uint256 index = withdrawals.length;
      withdrawals.push(Withdrawal(msg.sender, address(token), amount, now, false));

      Requested(token, msg.sender, amount, index);
      return index;
    }

     
     
    function withdrawUser(uint256 index) external {
      require((withdrawals[index].createdAt.add(delay)) < now);
      require(withdrawals[index].executed == false);
      require(withdrawals[index].user == msg.sender);

      withdrawals[index].executed = true;
      withdrawInternal(withdrawals[index].token, withdrawals[index].user, withdrawals[index].amount, 0);
    }

     
     
     
     
     
     
     
     
     
     
     
    function transferTokens(ERC20 token, address from, address to, uint256 amount, uint256 fee, uint256 nonce, uint256 expires, uint8 v, bytes32 r, bytes32 s) external onlyRole(ROLE_TRANSFER_TOKENS) {
      bytes32 hash = keccak256(this, token, from, to, amount, fee, nonce, expires);
      require(expires >= now);
      require(transferred[hash] == false);
      require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == from);

      balanceOf[address(token)][from] = balanceOf[address(token)][from].sub(amount.add(fee));
      balanceOf[address(token)][feeAccount] = balanceOf[address(token)][feeAccount].add(fee);
      balanceOf[address(token)][to] = balanceOf[address(token)][to].add(amount);
      TransferredTokens(token, from, to, amount, fee, nonce);
    }

     
     
     
     
    function transferInvestorTokens(InvestorToken token, address to, uint256 amount) external onlyRole(ROLE_TRANSFER_INVESTOR_TOKENS) {
      token.transferInvestorTokens(to, amount);
      TransferredInvestorTokens(msg.sender, token, to, amount);
    }

     
     
    function claimExtra(ERC20 token) external onlyRole(ROLE_CLAIM) {
      uint256 totalBalance = token.balanceOf(this);
      token.transfer(feeAccount, totalBalance.sub(tokensTotal[token]));
    }

     
     
     
     
     
     
     
     
     
    function trade(bytes _left, uint8 leftV, bytes32 leftR, bytes32 leftS, bytes _right, uint8 rightV, bytes32 rightR, bytes32 rightS) external {
      checkRole(msg.sender, ROLE_TRADE);  

      Order memory left;
      Order memory right;

      left.maker = _left.sliceAddress(0);
      left.baseToken = _left.sliceAddress(20);
      left.quoteToken = _left.sliceAddress(40);
      left.feeToken = _left.sliceAddress(60);
      left.amount = uint256(_left.slice32(80));
      left.priceNumerator = uint256(_left.slice32(112));
      left.priceDenominator = uint256(_left.slice32(144));
      left.feeNumerator = uint256(_left.slice32(176));
      left.feeDenominator = uint256(_left.slice32(208));
      left.expiresAt = uint256(_left.slice32(240));
      left.nonce = uint256(_left.slice32(272));
      if (_left.slice2(304) == 0) {
          left.orderType = OrderType.Sell;
      } else {
          left.orderType = OrderType.Buy;
      }

      right.maker = _right.sliceAddress(0);
      right.baseToken = _right.sliceAddress(20);
      right.quoteToken = _right.sliceAddress(40);
      right.feeToken = _right.sliceAddress(60);
      right.amount = uint256(_right.slice32(80));
      right.priceNumerator = uint256(_right.slice32(112));
      right.priceDenominator = uint256(_right.slice32(144));
      right.feeNumerator = uint256(_right.slice32(176));
      right.feeDenominator = uint256(_right.slice32(208));
      right.expiresAt = uint256(_right.slice32(240));
      right.nonce = uint256(_right.slice32(272));
      if (_right.slice2(304) == 0) {
          right.orderType = OrderType.Sell;
      } else {
          right.orderType = OrderType.Buy;
      }

      bytes32 leftHash = getOrderHash(left);
      bytes32 rightHash = getOrderHash(right);
      address leftSigner = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", leftHash), leftV, leftR, leftS);
      address rightSigner = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", rightHash), rightV, rightR, rightS);

      require(leftSigner == left.maker);
      require(rightSigner == right.maker);

      tradeInternal(left, leftHash, right, rightHash);
    }

     
     
     
     
     
    function tradeInternal(Order left, bytes32 leftHash, Order right, bytes32 rightHash) internal {
      uint256 priceNumerator;
      uint256 priceDenominator;
      uint256 leftAmountRemaining;
      uint256 rightAmountRemaining;
      uint256 amountBaseFilled;
      uint256 amountQuoteFilled;
      uint256 leftFeePaid;
      uint256 rightFeePaid;

      require(left.expiresAt > now);
      require(right.expiresAt > now);

      require(left.baseToken == right.baseToken);
      require(left.quoteToken == right.quoteToken);

      require(left.baseToken != left.quoteToken);

      require((left.orderType == OrderType.Sell && right.orderType == OrderType.Buy) || (left.orderType == OrderType.Buy && right.orderType == OrderType.Sell));

      require(left.amount > 0);
      require(left.priceNumerator > 0);
      require(left.priceDenominator > 0);
      require(right.amount > 0);
      require(right.priceNumerator > 0);
      require(right.priceDenominator > 0);

      require(left.feeDenominator > 0);
      require(right.feeDenominator > 0);

      require(left.amount % left.priceDenominator == 0);
      require(left.amount % right.priceDenominator == 0);
      require(right.amount % left.priceDenominator == 0);
      require(right.amount % right.priceDenominator == 0);

      if (left.orderType == OrderType.Buy) {
        require((left.priceNumerator.mul(right.priceDenominator)) >= (right.priceNumerator.mul(left.priceDenominator)));
      } else {
        require((left.priceNumerator.mul(right.priceDenominator)) <= (right.priceNumerator.mul(left.priceDenominator)));
      }

      priceNumerator = left.priceNumerator;
      priceDenominator = left.priceDenominator;

      leftAmountRemaining = left.amount.sub(orderFilled[leftHash]);
      rightAmountRemaining = right.amount.sub(orderFilled[rightHash]);

      require(leftAmountRemaining > 0);
      require(rightAmountRemaining > 0);

      if (leftAmountRemaining < rightAmountRemaining) {
        amountBaseFilled = leftAmountRemaining;
      } else {
        amountBaseFilled = rightAmountRemaining;
      }
      amountQuoteFilled = amountBaseFilled.mul(priceNumerator).div(priceDenominator);

      leftFeePaid = calculateFee(amountQuoteFilled, left.feeNumerator, left.feeDenominator);
      rightFeePaid = calculateFee(amountQuoteFilled, right.feeNumerator, right.feeDenominator);

      if (left.orderType == OrderType.Buy) {
        checkBalances(left.maker, left.baseToken, left.quoteToken, left.feeToken, amountBaseFilled, amountQuoteFilled, leftFeePaid);
        checkBalances(right.maker, right.quoteToken, right.baseToken, right.feeToken, amountQuoteFilled, amountBaseFilled, rightFeePaid);

        balanceOf[left.baseToken][left.maker] = balanceOf[left.baseToken][left.maker].add(amountBaseFilled);
        balanceOf[left.quoteToken][left.maker] = balanceOf[left.quoteToken][left.maker].sub(amountQuoteFilled);
        balanceOf[right.baseToken][right.maker] = balanceOf[right.baseToken][right.maker].sub(amountBaseFilled);
        balanceOf[right.quoteToken][right.maker] = balanceOf[right.quoteToken][right.maker].add(amountQuoteFilled);
      } else {
        checkBalances(left.maker, left.quoteToken, left.baseToken, left.feeToken, amountQuoteFilled, amountBaseFilled, leftFeePaid);
        checkBalances(right.maker, right.baseToken, right.quoteToken, right.feeToken, amountBaseFilled, amountQuoteFilled, rightFeePaid);

        balanceOf[left.baseToken][left.maker] = balanceOf[left.baseToken][left.maker].sub(amountBaseFilled);
        balanceOf[left.quoteToken][left.maker] = balanceOf[left.quoteToken][left.maker].add(amountQuoteFilled);
        balanceOf[right.baseToken][right.maker] = balanceOf[right.baseToken][right.maker].add(amountBaseFilled);
        balanceOf[right.quoteToken][right.maker] = balanceOf[right.quoteToken][right.maker].sub(amountQuoteFilled);
      }

      if (leftFeePaid > 0) {
        balanceOf[left.feeToken][left.maker] = balanceOf[left.feeToken][left.maker].sub(leftFeePaid);
        balanceOf[left.feeToken][feeAccount] = balanceOf[left.feeToken][feeAccount].add(leftFeePaid);
      }

      if (rightFeePaid > 0) {
        balanceOf[right.feeToken][right.maker] = balanceOf[right.feeToken][right.maker].sub(rightFeePaid);
        balanceOf[right.feeToken][feeAccount] = balanceOf[right.feeToken][feeAccount].add(rightFeePaid);
      }

      orderFilled[leftHash] = orderFilled[leftHash].add(amountBaseFilled);
      orderFilled[rightHash] = orderFilled[rightHash].add(amountBaseFilled);

      emitOrderExecutedEvent(left, leftHash, amountBaseFilled, amountQuoteFilled, leftFeePaid);
      emitOrderExecutedEvent(right, rightHash, amountBaseFilled, amountQuoteFilled, rightFeePaid);
    }

     
     
     
     
     
    function calculateFee(uint256 amountFilled, uint256 feeNumerator, uint256 feeDenominator) public returns(uint256) {
      return (amountFilled.mul(feeNumerator).div(feeDenominator));
    }

     
     
     
     
     
    function withdrawInternal(address token, address user, uint256 amount, uint256 fee) internal {
      require(amount > 0);
      require(balanceOf[token][user] >= amount.add(fee));

      balanceOf[token][user] = balanceOf[token][user].sub(amount.add(fee));
      balanceOf[token][feeAccount] = balanceOf[token][feeAccount].add(fee);
      tokensTotal[token] = tokensTotal[token].sub(amount);

      if (token == address(0)) {
          user.transfer(amount);
      } else {
          require(ERC20(token).transfer(user, amount));
      }

      Withdrawn(token, user, amount, balanceOf[token][user]);
    }

     
     
     
     
    function depositInternal(address token, uint256 amount) internal {
      require(tokenWhitelist[address(token)]);

      balanceOf[token][msg.sender] = balanceOf[token][msg.sender].add(amount);
      tokensTotal[token] = tokensTotal[token].add(amount);

      Deposited(token, msg.sender, amount, balanceOf[token][msg.sender]);
    }

     
     
     
     
     
     
    function emitOrderExecutedEvent(
      Order order,
      bytes32 orderHash,
      uint256 amountBaseFilled,
      uint256 amountQuoteFilled,
      uint256 feePaid
    ) private {
      uint256 baseTokenBalance = balanceOf[order.baseToken][order.maker];
      uint256 quoteTokenBalance = balanceOf[order.quoteToken][order.maker];
      uint256 feeTokenBalance = balanceOf[order.feeToken][order.maker];
      OrderExecuted(
          orderHash,
          order.maker,
          order.baseToken,
          order.quoteToken,
          order.feeToken,
          amountBaseFilled,
          amountQuoteFilled,
          feePaid,
          baseTokenBalance,
          quoteTokenBalance,
          feeTokenBalance
      );
    }

     
     
     
    function getOrderHash(Order order) private returns(bytes32) {
        return keccak256(
            this,
            order.orderType,
            order.maker,
            order.baseToken,
            order.quoteToken,
            order.feeToken,
            order.amount,
            order.priceNumerator,
            order.priceDenominator,
            order.feeNumerator,
            order.feeDenominator,
            order.expiresAt,
            order.nonce
        );
    }

     
     
     
     
     
     
     
     
    function checkBalances(address addr, address boughtToken, address soldToken, address feeToken, uint256 boughtAmount, uint256 soldAmount, uint256 feeAmount) private {
      if (feeToken == soldToken) {
        require (balanceOf[soldToken][addr] >= (soldAmount.add(feeAmount)));
      } else {
        if (feeToken == boughtToken) {
          require (balanceOf[feeToken][addr].add(boughtAmount) >= feeAmount);
        } else {
          require (balanceOf[feeToken][addr] >= feeAmount);
        }
        require (balanceOf[soldToken][addr] >= soldAmount);
      }
    }
}