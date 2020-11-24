 

pragma solidity ^0.4.18;

 


 
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


 
contract ERC20 {
  function name() public view returns (string);
  function symbol() public view returns (string);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC677Token {
  function transferAndCall(address receiver, uint amount, bytes data) public returns (bool success);
  function contractFallback(address to, uint value, bytes data) internal;
  function isContract(address addr) internal view returns (bool hasCode);
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


 
contract ERC677Recipient {
  function tokenFallback(address from, uint256 amount, bytes data) public returns (bool success);
}  


 
contract PonziToken is ERC20, ERC677Token {
  using SafeMath for uint256;

  enum State {
    PreSale,    
    Sale,       
    PublicUse   
  }
   
   
   
  string private constant PRE_SALE_STR = "PreSale";
  string private constant SALE_STR = "Sale";
  string private constant PUBLIC_USE_STR = "PublicUse";
  State private m_state;

  uint256 private constant DURATION_TO_ACCESS_FOR_OWNER = 144 days;
  
  uint256 private m_maxTokensPerAddress;
  uint256 private m_firstEntranceToSaleStateUNIX;
  address private m_owner;
  address private m_priceSetter;
  address private m_bank;
  uint256 private m_tokenPriceInWei;
  uint256 private m_totalSupply;
  uint256 private m_myDebtInWei;
  string private m_name;
  string private m_symbol;
  uint8 private m_decimals;
  bool private m_isFixedTokenPrice;
  
  mapping(address => mapping (address => uint256)) private m_allowed;
  mapping(address => uint256) private m_balances;
  mapping(address => uint256) private m_pendingWithdrawals;

 
 
 
  event StateChanged(address indexed who, State newState);
  event PriceChanged(address indexed who, uint newPrice, bool isFixed);
  event TokensSold(uint256 numberOfTokens, address indexed purchasedBy, uint256 indexed priceInWei);
  event Withdrawal(address indexed to, uint sumInWei);

 
 
 
  modifier atState(State state) {
    require(m_state == state);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }

  modifier onlyOwnerOrAtState(State state) {
    require(msg.sender == m_owner || m_state == state); 
    _;
  }
  
  modifier checkAccess() {
    require(m_firstEntranceToSaleStateUNIX == 0  
      || now.sub(m_firstEntranceToSaleStateUNIX) <= DURATION_TO_ACCESS_FOR_OWNER 
      || m_state != State.PublicUse
    ); 
    _;
     
     
  }
  
  modifier validRecipient(address recipient) {
    require(recipient != address(0) && recipient != address(this));
    _;
  }

 
 
 
   
  function PonziToken() public {
    m_owner = msg.sender;
    m_bank = msg.sender;
    m_state = State.PreSale;
    m_decimals = 8;
    m_name = "Ponzi";
    m_symbol = "PT";
  }

   
  function initContract() 
    public 
    onlyOwner() 
    returns (bool)
  {
    require(m_maxTokensPerAddress == 0 && m_decimals > 0);
    m_maxTokensPerAddress = uint256(1000).mul(uint256(10)**uint256(m_decimals));

    m_totalSupply = uint256(100000000).mul(uint256(10)**uint256(m_decimals));
     
    m_balances[msg.sender] = m_totalSupply.mul(uint256(70)).div(uint256(100));
     
    m_balances[address(this)] = m_totalSupply.sub(m_balances[msg.sender]);

     
    m_allowed[address(this)][m_owner] = m_balances[address(this)];
    return true;
  }

 
 
 
 
   
  function balanceOf(address owner) public view returns (uint256) {
    return m_balances[owner];
  }
  
   
  function name() public view returns (string) {
    return m_name;
  }

   
  function symbol() public view returns (string) {
    return m_symbol;
  }

   
  function decimals() public view returns (uint8) {
    return m_decimals;
  }

   
  function totalSupply() public view returns (uint256) {
    return m_totalSupply;
  }

   
  function transfer(address to, uint256 value) 
    public 
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool) 
  {
     
     
    m_balances[msg.sender] = m_balances[msg.sender].sub(value);
    m_balances[to] = m_balances[to].add(value);
    Transfer(msg.sender, to, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool) 
  {
     
     
     
    m_balances[from] = m_balances[from].sub(value);
    m_balances[to] = m_balances[to].add(value);
    m_allowed[from][msg.sender] = m_allowed[from][msg.sender].sub(value);
    Transfer(from, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
     
     
     
     
    require((value == 0) || (m_allowed[msg.sender][spender] == 0));

    m_allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

   
  function allowance(address owner, address spender) 
    public 
    view
    returns (uint256) 
  {
    return m_allowed[owner][spender];
  }
  
   
  function increaseApproval(address spender, uint addedValue) 
    public 
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
    m_allowed[msg.sender][spender] = m_allowed[msg.sender][spender].add(addedValue);
    Approval(msg.sender, spender, m_allowed[msg.sender][spender]);
    return true;
  }

    
  function decreaseApproval(address spender, uint subtractedValue) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(spender)
    returns (bool) 
  {
    uint oldValue = m_allowed[msg.sender][spender];
    if (subtractedValue > oldValue) {
      m_allowed[msg.sender][spender] = 0;
    } else {
      m_allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    Approval(msg.sender, spender, m_allowed[msg.sender][spender]);
    return true;
  }

 
 
 
   
  function transferAndCall(address to, uint256 value, bytes extraData) 
    public
    onlyOwnerOrAtState(State.PublicUse)
    validRecipient(to)
    returns (bool)
  {
     
     
    m_balances[msg.sender] = m_balances[msg.sender].sub(value);
    m_balances[to] = m_balances[to].add(value);
    Transfer(msg.sender, to, value);
    if (isContract(to)) {
      contractFallback(to, value, extraData);
      Transfer(msg.sender, to, value, extraData);
    }
    return true;
  }

   
  function transferAllAndCall(address to, bytes extraData) 
    external
    onlyOwnerOrAtState(State.PublicUse)
    returns (bool) 
  {
    return transferAndCall(to, m_balances[msg.sender], extraData);
  }
  
   
  function contractFallback(address to, uint value, bytes data)
    internal
  {
    ERC677Recipient recipient = ERC677Recipient(to);
    recipient.tokenFallback(msg.sender, value, data);
  }

   
  function isContract(address addr) internal view returns (bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length > 0;
  }
  
  
 
 
 
 
 
 
   
  function byTokens() public payable atState(State.Sale) {
     
    require(m_balances[msg.sender] < m_maxTokensPerAddress);

     
    m_tokenPriceInWei = calcTokenPriceInWei();
    
     
    require(msg.value >= m_tokenPriceInWei);
    
     
    uint256 maxAvailableTokens = m_maxTokensPerAddress.sub(m_balances[msg.sender]);
    
     
    uint256 tokensAmount = weiToTokens(msg.value, m_tokenPriceInWei);
    
    if (tokensAmount > maxAvailableTokens) {
       
       
       
      tokensAmount = maxAvailableTokens;  
       
      uint256 tokensAmountCostInWei = tokensToWei(tokensAmount, m_tokenPriceInWei);
       
      uint256 debt = msg.value.sub(tokensAmountCostInWei);
       
       
      m_pendingWithdrawals[msg.sender] = m_pendingWithdrawals[msg.sender].add(debt);
       
      m_myDebtInWei = m_myDebtInWei.add(debt);
    }
     
     
    m_balances[address(this)] = m_balances[address(this)].sub(tokensAmount);
    m_balances[msg.sender] = m_balances[msg.sender].add(tokensAmount);

     
     
     
     
     
     
    m_owner.transfer(this.balance.sub(m_myDebtInWei).mul(uint256(5)).div(uint256(100)));
     
     
    m_bank.transfer(this.balance.sub(m_myDebtInWei));
    checkValidityOfBalance();  
    Transfer(address(this), msg.sender, tokensAmount);
    TokensSold(tokensAmount, msg.sender, m_tokenPriceInWei); 
  }
  
   
  function withdraw() external {
    uint amount = m_pendingWithdrawals[msg.sender];
    require(amount > 0);
     
     
    m_pendingWithdrawals[msg.sender] = 0;
    m_myDebtInWei = m_myDebtInWei.sub(amount);
    msg.sender.transfer(amount);
    checkValidityOfBalance();  
    Withdrawal(msg.sender, amount);
  }

   
  function() public payable atState(State.Sale) {
    byTokens();
  }
    
  
 
 
 
 
   
  function pendingWithdrawals(address owner) external view returns (uint256) {
    return m_pendingWithdrawals[owner];
  }
  
   
  function state() external view returns (string stateString) {
    if (m_state == State.PreSale) {
      stateString = PRE_SALE_STR;
    } else if (m_state == State.Sale) {
      stateString = SALE_STR;
    } else if (m_state == State.PublicUse) {
      stateString = PUBLIC_USE_STR;
    }
  }
  
   
  function tokenPriceInWei() public view returns (uint256) {
    return calcTokenPriceInWei();
  }
  
   
  function bank() external view returns(address) {
    return m_bank;
  }
  
   
  function firstEntranceToSaleStateUNIX() 
    external
    view 
    returns(uint256) 
  {
    return m_firstEntranceToSaleStateUNIX;
  }
  
   
  function priceSetter() external view returns (address) {
    return m_priceSetter;
  }

 
 
 
 
    
  function disown() external atState(State.PublicUse) onlyOwner() {
    delete m_owner;
  }
  
    
  function setState(string newState) 
    external 
    onlyOwner()
    checkAccess()
  {
    if (keccak256(newState) == keccak256(PRE_SALE_STR)) {
      m_state = State.PreSale;
    } else if (keccak256(newState) == keccak256(SALE_STR)) {
      if (m_firstEntranceToSaleStateUNIX == 0) 
        m_firstEntranceToSaleStateUNIX = now;
        
      m_state = State.Sale;
    } else if (keccak256(newState) == keccak256(PUBLIC_USE_STR)) {
      m_state = State.PublicUse;
    } else {
       
      revert();
    }
    StateChanged(msg.sender, m_state);
  }

    
  function setAndFixTokenPriceInWei(uint256 newTokenPriceInWei) 
    external
    checkAccess()
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_isFixedTokenPrice = true;
    m_tokenPriceInWei = newTokenPriceInWei;
    PriceChanged(msg.sender, m_tokenPriceInWei, m_isFixedTokenPrice);
  }
  
   
  function unfixTokenPriceInWei() 
    external
    checkAccess()
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_isFixedTokenPrice = false;
    PriceChanged(msg.sender, m_tokenPriceInWei, m_isFixedTokenPrice);
  }
  
   
  function setPriceSetter(address newPriceSetter) 
    external 
    onlyOwner() 
    checkAccess()
  {
    m_priceSetter = newPriceSetter;
  }

   
  function setBank(address newBank) 
    external
    validRecipient(newBank) 
    onlyOwner()
    checkAccess()
  {
    require(newBank != address(0));
    m_bank = newBank;
  }

 
 
 
   
  function tokensToWei(uint256 tokensAmount, uint256 tokenPrice) 
    internal
    pure
    returns(uint256 weiAmount)
  {
    weiAmount = tokensAmount.mul(tokenPrice); 
  }
  
   
  function weiToTokens(uint256 weiAmount, uint256 tokenPrice) 
    internal 
    pure 
    returns(uint256 tokensAmount) 
  {
    tokensAmount = weiAmount.div(tokenPrice);
  }
 
 
 
 
   
  function calcTokenPriceInWei() 
    private 
    view 
    returns(uint256 price) 
  {
    if (m_isFixedTokenPrice) {
       
      price = m_tokenPriceInWei;
    } else {
       
      if (m_firstEntranceToSaleStateUNIX == 0) {
         
        price = 0;
      } else {
         
        uint256 day = now.sub(m_firstEntranceToSaleStateUNIX).div(1 days);
         
        price = tokenPriceInWeiForDay(day);
      }
    } 
  }
  
   
  function tokenPriceInWeiForDay(uint256 day) 
    private 
    view 
    returns(uint256 price)
  {
     
     
     
     
     
     
    
     
     
     
     
     
    
     
     

     
    if (day <= 11) 
      price = day.add(1); 
    else                  
      price = 12;
     
    price = price.mul(uint256(10**15)).div(10**uint256(m_decimals));
  }
  
   
  function checkValidityOfBalance() private view {
     
     
     
     
    assert(this.balance >= m_myDebtInWei);
  }
}