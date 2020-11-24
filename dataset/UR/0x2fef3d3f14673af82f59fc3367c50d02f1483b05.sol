 

 
 
 

 
contract TokenInterface {

  struct User {
    bool locked;
    uint256 balance;
    uint256 badges;
    mapping (address => uint256) allowed;
  }

  mapping (address => User) users;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

  address config;
  address owner;
  address dao;
  bool locked;

   
  uint256 public totalSupply;
  uint256 public totalBadges;

   
   
  function balanceOf(address _owner) constant returns (uint256 balance);

   
   
  function badgesOf(address _owner) constant returns (uint256 badge);

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success);

   
   
   
   
  function sendBadge(address _to, uint256 _value) returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

   
   
   
   
  function mint(address _owner, uint256 _amount) returns (bool success);

   
   
   
   
  function mintBadge(address _owner, uint256 _amount) returns (bool success);

  function registerDao(address _dao) returns (bool success);

  function registerSeller(address _tokensales) returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event SendBadge(address indexed _from, address indexed _to, uint256 _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract swap{
    address public beneficiary;
    TokenInterface public tokenObj;
    uint public price_token;
    uint256 public WEI_PER_FINNEY = 1000000000000000;
    uint public BILLION = 1000000000;
    uint public expiryDate;
    
     
    function swap(address sendEtherTo, address adddressOfToken, uint tokenPriceInFinney_1000FinneyIs_1Ether, uint durationInDays){
        beneficiary = sendEtherTo;
        tokenObj = TokenInterface(adddressOfToken);
        price_token = tokenPriceInFinney_1000FinneyIs_1Ether * WEI_PER_FINNEY;
        expiryDate = now + durationInDays * 1 days;
    }
    
     
    function(){
        if (now >= expiryDate) throw;
         
        var tokens_to_send = (msg.value * BILLION) / price_token;
        uint balance = tokenObj.balanceOf(this);
        address payee = msg.sender;
        if (balance >= tokens_to_send){
            tokenObj.transfer(msg.sender, tokens_to_send);
            beneficiary.send(msg.value);    
        } else {
            tokenObj.transfer(msg.sender, balance);
            uint amountReturned = ((tokens_to_send - balance) * price_token) / BILLION;
            payee.send(amountReturned);
            beneficiary.send(msg.value - amountReturned);
        }
    }
    
    modifier afterExpiry() { if (now >= expiryDate) _ }
    
     
    function checkExpiry() afterExpiry{
        uint balance = tokenObj.balanceOf(this);
        tokenObj.transfer(beneficiary, balance);
    }
}