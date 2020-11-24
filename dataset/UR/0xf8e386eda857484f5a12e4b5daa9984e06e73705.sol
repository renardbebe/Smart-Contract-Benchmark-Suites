 

pragma solidity ^0.4.11;

 
 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
 

 
 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
}
 

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
 

 
contract StandardToken is ERC20, SafeMath {

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4) ;
     _;
  }

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSubtract(balances[_from], _value);
    allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}
 

 
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

   
  modifier whenPaused {
    require (paused) ;
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}
 

 
contract IndorseToken is SafeMath, StandardToken, Pausable {
     
    string public constant name = "Indorse Token";
    string public constant symbol = "IND";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public indSaleDeposit        = 0x0053B91E38B207C97CBff06f48a0f7Ab2Dd81449;       
    address public indSeedDeposit        = 0x0083fdFB328fC8D07E2a7933e3013e181F9798Ad;       
    address public indPresaleDeposit     = 0x007AB99FBf023Cb41b50AE7D24621729295EdBFA;       
    address public indVestingDeposit     = 0x0011349f715cf59F75F0A00185e7B1c36f55C3ab;       
    address public indCommunityDeposit   = 0x0097ec8840E682d058b24E6e19E68358d97A6E5C;       
    address public indFutureDeposit      = 0x00d1bCbCDE9Ca431f6dd92077dFaE98f94e446e4;       
    address public indInflationDeposit   = 0x00D31206E625F1f30039d1Fa472303E71317870A;       
    
    uint256 public constant indSale      = 31603785 * 10**decimals;                         
    uint256 public constant indSeed      = 3566341  * 10**decimals; 
    uint256 public constant indPreSale   = 22995270 * 10**decimals;                       
    uint256 public constant indVesting   = 28079514 * 10**decimals;  
    uint256 public constant indCommunity = 10919811 * 10**decimals;  
    uint256 public constant indFuture    = 58832579 * 10**decimals;  
    uint256 public constant indInflation = 14624747 * 10**decimals;  
   
     
    function IndorseToken()
    {
      balances[indSaleDeposit]           = indSale;                                          
      balances[indSeedDeposit]           = indSeed;                                          
      balances[indPresaleDeposit]        = indPreSale;                                       
      balances[indVestingDeposit]        = indVesting;                                       
      balances[indCommunityDeposit]      = indCommunity;                                     
      balances[indFutureDeposit]         = indFuture;                                        
      balances[indInflationDeposit]      = indInflation;                                     

      totalSupply = indSale + indSeed + indPreSale + indVesting + indCommunity + indFuture + indInflation;

      Transfer(0x0,indSaleDeposit,indSale);
      Transfer(0x0,indSeedDeposit,indSeed);
      Transfer(0x0,indPresaleDeposit,indPreSale);
      Transfer(0x0,indVestingDeposit,indVesting);
      Transfer(0x0,indCommunityDeposit,indCommunity);
      Transfer(0x0,indFutureDeposit,indFuture);
      Transfer(0x0,indInflationDeposit,indInflation);
   }

  function transfer(address _to, uint _value) whenNotPaused returns (bool success)  {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) whenNotPaused returns (bool success)  {
    return super.approve(_spender,_value);
  }
}
 

 
contract IndorseSaleContract is  Ownable,SafeMath,Pausable {
    IndorseToken    ind;

     
    uint256 public fundingStartTime = 1502193600;
    uint256 public fundingEndTime   = 1504785600;
    uint256 public totalSupply;
    address public ethFundDeposit   = 0x26967201d4D1e1aA97554838dEfA4fC4d010FF6F;       
    address public indFundDeposit   = 0x0053B91E38B207C97CBff06f48a0f7Ab2Dd81449;       
    address public indAddress       = 0xf8e386EDa857484f5a12e4B5DAa9984E06E73705;

    bool public isFinalized;                                                             
    uint256 public constant decimals = 18;                                               
    uint256 public tokenCreationCap;
    uint256 public constant tokenExchangeRate = 1000;                                    
    uint256 public constant minContribution = 0.05 ether;
    uint256 public constant maxTokens = 1 * (10 ** 6) * 10**decimals;
    uint256 public constant MAX_GAS_PRICE = 50000000000 wei;                             
 
    function IndorseSaleContract() {
        ind = IndorseToken(indAddress);
        tokenCreationCap = ind.balanceOf(indFundDeposit);
        isFinalized = false;
    }

    event MintIND(address from, address to, uint256 val);
    event LogRefund(address indexed _to, uint256 _value);

    function CreateIND(address to, uint256 val) internal returns (bool success){
        MintIND(indFundDeposit,to,val);
        return ind.transferFrom(indFundDeposit,to,val);
    }

    function () payable {    
        createTokens(msg.sender,msg.value);
    }

     
    function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
      require (tokenCreationCap > totalSupply);                                          
      require (now >= fundingStartTime);
      require (now <= fundingEndTime);
      require (_value >= minContribution);                                               
      require (!isFinalized);
      require (tx.gasprice <= MAX_GAS_PRICE);

      uint256 tokens = safeMult(_value, tokenExchangeRate);                              
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      require (ind.balanceOf(msg.sender) + tokens <= maxTokens);
      
       
      if (tokenCreationCap < checkedSupply) {        
        uint256 tokensToAllocate = safeSubtract(tokenCreationCap,totalSupply);
        uint256 tokensToRefund   = safeSubtract(tokens,tokensToAllocate);
        totalSupply = tokenCreationCap;
        uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

        require(CreateIND(_beneficiary,tokensToAllocate));                               
        msg.sender.transfer(etherToRefund);
        LogRefund(msg.sender,etherToRefund);
        ethFundDeposit.transfer(this.balance);
        return;
      }
       

      totalSupply = checkedSupply;
      require(CreateIND(_beneficiary, tokens));                                          
      ethFundDeposit.transfer(this.balance);
    }
    
     
    function finalize() external onlyOwner {
      require (!isFinalized);
       
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);                                             
    }
}