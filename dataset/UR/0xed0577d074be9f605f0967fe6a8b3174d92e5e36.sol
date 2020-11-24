 

pragma solidity ^0.4.23;

 


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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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

contract OptionFactory is Ownable {

    using SafeMath for uint256;

    mapping (address => bool) public admins;
    mapping(uint 
        => mapping(address 
            => mapping(address 
                => mapping(uint
                    => mapping(bool
                        => mapping(uint8 
                            => OptionToken)))))) register;

    DexBrokerage public exchangeContract;
    ERC20        public dexb;
    uint         public dexbTreshold;
    address      public dexbAddress;

     
    uint public issueFee;
    uint public executeFee;
    uint public cancelFee;

     
    uint public dexbIssueFee;
    uint public dexbExecuteFee;
    uint public dexbCancelFee;

     
    uint public HUNDERED_PERCENT = 100000;

     
    uint public MAX_FEE = HUNDERED_PERCENT.div(100);

    constructor(address _dexbAddress, uint _dexbTreshold, address _dexBrokerageAddress) public {
        dexbAddress      = _dexbAddress;
        dexb             = ERC20(_dexbAddress);
        dexbTreshold     = _dexbTreshold;
        exchangeContract = DexBrokerage(_dexBrokerageAddress);

         
        setIssueFee(300);
        setExecuteFee(300);
        setCancelFee(300);

         
        setDexbIssueFee(200);
        setDexbExecuteFee(200);
        setDexbCancelFee(200);
    }


    function getOptionAddress(
        uint expiryDate, 
        address firstToken, 
        address secondToken, 
        uint strikePrice,
        bool isCall,
        uint8 decimals) public view returns (address) {
        
        return address(register[expiryDate][firstToken][secondToken][strikePrice][isCall][decimals]);
    }

    function createOption(
        uint expiryDate, 
        address firstToken, 
        address secondToken, 
        uint minIssueAmount,
        uint strikePrice,
        bool isCall,
        uint8 decimals,
        string name) public {

        require(address(0) == getOptionAddress(
            expiryDate, firstToken, secondToken, strikePrice, isCall, decimals    
        ));

        OptionToken newOption = new OptionToken(
            this,
            firstToken,
            secondToken,
            minIssueAmount,
            expiryDate,
            strikePrice,
            isCall,
            name,
            decimals
        );

        register[expiryDate][firstToken][secondToken]
            [strikePrice][isCall][decimals] = newOption;
    }

    modifier validFeeOnly(uint fee) { 
        require (fee <= MAX_FEE); 
        _;
    }
    
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function setAdmin(address admin, bool isAdmin) onlyOwner public {
        admins[admin] = isAdmin;
    }

    function setIssueFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        issueFee = fee;
    }

    function setExecuteFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        executeFee = fee;
    }

    function setCancelFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        cancelFee = fee;
    }

    function setDexbIssueFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbIssueFee = fee;
    }

    function setDexbExecuteFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbExecuteFee = fee;
    }

    function setDexbCancelFee(uint fee) public onlyAdmin validFeeOnly(fee) {
        dexbCancelFee = fee;
    }

    function setDexbTreshold(uint treshold) public onlyAdmin {
        dexbTreshold = treshold;
    }

    function calcIssueFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbIssueFee, issueFee);
        return calcFee(feeLevel, value);
    }

    function calcExecuteFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbExecuteFee, executeFee);
        return calcFee(feeLevel, value);
    }

    function calcCancelFeeAmount(address user, uint value) public view returns (uint) {
        uint feeLevel = getFeeLevel(user, dexbCancelFee, cancelFee);
        return calcFee(feeLevel, value);
    }

    function getFeeLevel(address user, uint aboveTresholdFee, uint belowTresholdFee) internal view returns (uint) {
        if(dexb.balanceOf(user) + exchangeContract.balanceOf(dexbAddress, user) >= dexbTreshold){
            return aboveTresholdFee;
        } else {
            return belowTresholdFee;
        }
    }

    function calcFee(uint feeLevel, uint value) internal view returns (uint) {
        return value.mul(feeLevel).div(HUNDERED_PERCENT);
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
   
   
   
   

 function approveAndDeposit(DexBrokerage _exchange, uint _amount) public returns (bool success) {
    allowed[msg.sender][_exchange] = _amount;
    emit Approval(msg.sender, _exchange, _amount);
    _exchange.receiveTokenDeposit(address(this), msg.sender, _amount);
    return true;
  }

}


contract OptionToken is StandardToken {

    using SafeMath for uint256;

    OptionFactory public factory;
    ERC20  public firstToken;
    ERC20  public secondToken;
    uint   public minIssueAmount;
    uint   public expiry;
    uint   public strikePrice;
    bool   public isCall;
    string public symbol;
    uint  public decimals;

    struct Issuer {
        address addr;
        uint amount;
    }

    Issuer[] internal issuers;

    constructor(
        address _factory,
        address _firstToken,
        address _secondToken,
        uint    _minIssueAmount,
        uint    _expiry,
        uint    _strikePrice,
        bool    _isCall,
        string  _symbol,
        uint8   _decimals) public {

        require (_firstToken != _secondToken, 'Tokens should be different.');

        factory        = OptionFactory(_factory);
        firstToken     = ERC20(_firstToken);
        secondToken    = ERC20(_secondToken);
        minIssueAmount = _minIssueAmount;
        expiry         = _expiry;
        strikePrice    = _strikePrice;
        isCall         = _isCall;
        symbol         = _symbol;
        decimals       = uint(_decimals);
    }

    modifier onlyAdmin {
        require(factory.admins(msg.sender));
        _;
    }

     

    function setMinIssueAmount(uint minAmount) onlyAdmin public  {
        minIssueAmount = minAmount;
    }

    function issueWithToken(uint amount) public beforeExpiry canIssueWithToken returns (bool) {
        require(amount >= minIssueAmount);
        uint fee = factory.calcIssueFeeAmount(msg.sender, amount);
        uint amountWithoutFee = amount - fee;
        transferTokensInOnIssue(amountWithoutFee, fee);
        issue(amountWithoutFee);
        return true;
    }

    function issueWithWei() public payable beforeExpiry canIssueWithWei returns (bool) {
        require(msg.value >= minIssueAmount);
        uint fee = factory.calcIssueFeeAmount(msg.sender, msg.value);
        uint amountWithoutFee = msg.value - fee;
        factory.owner().transfer(fee);
        if(isCall){
            issue(amountWithoutFee);
        } else {
            uint amount = amountWithoutFee.mul(uint(10).pow(decimals)).div(strikePrice);
            issue(amount);
        }
        return true;
    }

    function executeWithToken(uint amount) public beforeExpiry canExecuteWithToken returns (bool) {
        transferTokensInOnExecute(amount);
        execute(amount);
        return true;
    }

    function executeWithWei() public payable beforeExpiry canExecuteWithWei {
        if(isCall){
            uint amount = msg.value.mul(uint(10).pow(decimals)).div(strikePrice);
            execute(amount);
        } else {
            execute(msg.value);
        }
    }

    function cancel(uint amount) public beforeExpiry {
        burn(msg.sender, amount);
        bool found = false;
        for (uint i = 0; i < issuers.length; i++) {
            if(issuers[i].addr == msg.sender) {
                found = true;
                issuers[i].amount = issuers[i].amount.sub(amount);
                transferTokensOrWeiOutToIssuerOnCancel(amount);
                break;
            }
        }
        require(found);
    }

    function refund() public afterExpiry {
         
        for(uint i = 0; i < issuers.length; i++) {
            if(issuers[i].amount > 0){
                transferTokensOrWeiOutToIssuerOnRefund(issuers[i].addr, issuers[i].amount);
            }
        }
    }

     
    function transferTokensInOnIssue(uint amountForContract, uint feeAmount) internal returns (bool) {
        ERC20 token;
        uint toTransferIntoContract;
        uint toTransferFee;
        if(isCall){
            token = firstToken;
            toTransferIntoContract = amountForContract;
            toTransferFee = feeAmount;
        } else {
            token = secondToken;
            toTransferIntoContract = strikePrice.mul(amountForContract).div(uint(10).pow(decimals));
            toTransferFee = strikePrice.mul(feeAmount).div(uint(10).pow(decimals));
        }
        require(token != address(0));
        require(transferTokensIn(token, toTransferIntoContract + toTransferFee));
        require(transferTokensToOwner(token, toTransferFee));
        return true;
    }

    function transferTokensInOnExecute(uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer;
        if(isCall){
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        } else {
            token = firstToken;
            toTransfer = amount;
        }
        require(token != address(0));
        require(transferTokensIn(token, toTransfer));
        return true;
    }

    function transferTokensIn(ERC20 token, uint amount) internal returns (bool) {
        require(token.transferFrom(msg.sender, this, amount));
        return true;
    }

    function transferTokensToOwner(ERC20 token, uint amount) internal returns (bool) {
        require(token.transfer(factory.owner(), amount));
        return true;
    }

    function transfer(ERC20 token, uint amount) internal returns (bool) {
        require(token.transferFrom(msg.sender, factory.owner(), amount));
        return true;
    }
    function issue(uint amount) internal returns (bool){
        mint(msg.sender, amount);
        bool found = false;
        for (uint i = 0; i < issuers.length; i++) {
            if(issuers[i].addr == msg.sender) {
                issuers[i].amount = issuers[i].amount.add(amount);
                found = true;
                break;
            }
        }

        if(!found) {
            issuers.push(Issuer(msg.sender, amount));
        }
    }

    function mint(address to, uint amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function execute(uint amount) internal returns (bool) {
        burn(msg.sender, amount);
        transferTokensOrWeiOutToSenderOnExecute(amount);
         
        uint amountToDistribute = amount;
        uint i = issuers.length - 1;
        while(amountToDistribute > 0){
            if(issuers[i].amount > 0){
                if(issuers[i].amount >= amountToDistribute){
                    transferTokensOrWeiOutToIssuerOnExecute(issuers[i].addr, amountToDistribute);
                    issuers[i].amount = issuers[i].amount.sub(amountToDistribute);
                    amountToDistribute = 0;
                } else {
                    transferTokensOrWeiOutToIssuerOnExecute(issuers[i].addr, issuers[i].amount);
                    amountToDistribute = amountToDistribute.sub(issuers[i].amount);
                    issuers[i].amount = 0;
                }
            }
            i = i - 1;
        }
        return true;
    }

    function transferTokensOrWeiOutToSenderOnExecute(uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        uint fee = factory.calcExecuteFeeAmount(msg.sender, toTransfer);
        toTransfer = toTransfer - fee;
        if(token == address(0)){
            require(msg.sender.send(toTransfer));
            if(fee > 0){
                require(factory.owner().send(fee));
            }
        } else {
            require(token.transfer(msg.sender, toTransfer));
            if(fee > 0){
                require(token.transfer(factory.owner(), fee));
            }
        }
        return true;
    }

    function transferTokensOrWeiOutToIssuerOnExecute(address issuer, uint amount) internal returns (bool) {
        ERC20 token;
        uint toTransfer;
        if(isCall){
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        } else {
            token = firstToken;
            toTransfer = amount;
        }
        if(token == address(0)){
            require(issuer.send(toTransfer));
        } else {
            require(token.transfer(issuer, toTransfer));
        }
        return true;
    }

    function burn(address from, uint256 amount) internal returns (bool) {
        require(amount <= balances[from]);
        balances[from] = balances[from].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(from, address(0), amount);
        return true;
    }

    function transferTokensOrWeiOutToIssuerOnCancel(uint amount) internal returns (bool){
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        uint fee = factory.calcCancelFeeAmount(msg.sender, toTransfer);
        toTransfer = toTransfer - fee;
        if(token == address(0)){
            require(msg.sender.send(toTransfer));
            if(fee > 0){
                require(factory.owner().send(fee));
            }
        } else {
            require(token.transfer(msg.sender, toTransfer));
            if(fee > 0){
                require(token.transfer(factory.owner(), fee));
            }
        }
        return true;
    }


    function transferTokensOrWeiOutToIssuerOnRefund(address issuer, uint amount) internal returns (bool){
        ERC20 token;
        uint toTransfer = 0;
        if(isCall){
            token = firstToken;
            toTransfer = amount;
        } else {
            token = secondToken;
            toTransfer = strikePrice.mul(amount).div(uint(10).pow(decimals));
        }
        if(token == address(0)){
            issuer.transfer(toTransfer);
        } else {
            require(token.transfer(issuer, toTransfer));
        }
        return true;
    }

     
    modifier canIssueWithWei() {
        require(
            (isCall  && firstToken == address(0)) ||
            (!isCall && secondToken == address(0))
        );
        _;
    }

    modifier canIssueWithToken() {
        require(
            (isCall  && firstToken != address(0)) ||
            (!isCall && secondToken != address(0))
        );
        _;
    }

    modifier canExecuteWithWei() {
        require(
            (isCall  && secondToken == address(0)) ||
            (!isCall && firstToken == address(0))
        );
        _;
    }

    modifier canExecuteWithToken() {
        require(
            (isCall  && secondToken != address(0)) ||
            (!isCall && firstToken != address(0))
        );
        _;
    }

    modifier beforeExpiry() {
        require (now <= expiry);
        _;
    }

    modifier afterExpiry() {
        require (now > expiry);
        _;
    }
}