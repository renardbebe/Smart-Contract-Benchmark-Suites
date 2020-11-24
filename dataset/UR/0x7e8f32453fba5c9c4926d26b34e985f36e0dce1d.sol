 

pragma solidity 0.4.11;

contract Wolker {
  mapping (address => uint256) balances;
  mapping (address => uint256) allocations;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => mapping (address => bool)) authorized;  

   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] = safeSub(balances[msg.sender], _value);
      balances[_to] = safeAdd(balances[_to], _value);
      Transfer(msg.sender, _to, _value, balances[msg.sender], balances[_to]);
      return true;
    } else {
      throw;
    }
  }
  
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from], _value);
      allowed[_from][msg.sender] = safeSub(_allowance, _value);
      Transfer(_from, _to, _value, balances[_from], balances[_to]);
      return true;
    } else {
      throw;
    }
  }
 
   
  function totalSupply() external constant returns (uint256) {
        return generalTokens + reservedTokens;
  }
 
   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }


   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


   
   
  function authorize(address _trustee) returns (bool success) {
    authorized[msg.sender][_trustee] = true;
    Authorization(msg.sender, _trustee);
    return true;
  }

   
   
  function deauthorize(address _trustee_to_remove) returns (bool success) {
    authorized[msg.sender][_trustee_to_remove] = false;
    Deauthorization(msg.sender, _trustee_to_remove);
    return true;
  }

   
   
   
  function check_authorization(address _owner, address _trustee) constant returns (bool authorization_status) {
    return authorized[_owner][_trustee];
  }

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


   
  event Transfer(address indexed _from, address indexed _to, uint256 _value, uint from_final_tok, uint to_final_tok);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Authorization(address indexed _owner, address indexed _trustee);
  event Deauthorization(address indexed _owner, address indexed _trustee_to_remove);

  event NewOwner(address _newOwner);
  event MintEvent(uint reward_tok, address recipient);
  event LogRefund(address indexed _to, uint256 _value);
  event CreateWolk(address indexed _to, uint256 _value);
  event Vested(address indexed _to, uint256 _value);

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  modifier isOperational() {
    assert(isFinalized);
    _;
  }


   
  string  public constant name = 'Wolk Coin';
  string  public constant symbol = "WOLK";
  string  public constant version = "0.2.2";
  uint256 public constant decimals = 18;
  uint256 public constant wolkFund  =  10 * 10**1 * 10**decimals;         
  uint256 public constant tokenCreationMin =  20 * 10**1 * 10**decimals;  
  uint256 public constant tokenCreationMax = 100 * 10**5 * 10**decimals;  
  uint256 public constant tokenExchangeRate = 10000;    
  uint256 public generalTokens = wolkFund;  
  uint256 public reservedTokens; 

   
  address public owner = 0xC28dA4d42866758d0Fc49a5A3948A1f43de491e9;  
  address public multisig_owner = 0x6968a9b90245cB9bD2506B9460e3D13ED4B2FD1e;  

  bool public isFinalized = false;           
  uint public constant dust = 1000000 wei; 
  bool public fairsale_protection = true;

  
      
  uint256 public start_block;                 
  uint256 public end_block;                   
  uint256 public unlockedAt;                  
 
  uint256 public end_ts;                      


   
   
   

   
   


   
  function Wolk() 
  {
    if ( msg.sender != owner ) throw;
     
    start_block = 3841080;
    end_block = 3841580;

     
    balances[owner] = wolkFund;

     
    reservedTokens = 25 * 10**decimals;
    allocations[0x564a3f7d98Eb5B1791132F8875fef582d528d5Cf] = 20;  
    allocations[0x7f512CCFEF05F651A70Fa322Ce27F4ad79b74ffe] = 1;   
    allocations[0x9D203A36cd61b21B7C8c7Da1d8eeB13f04bb24D9] = 2;   
    allocations[0x5fcf700654B8062B709a41527FAfCda367daE7b1] = 1;   
    allocations[0xC28dA4d42866758d0Fc49a5A3948A1f43de491e9] = 1;   
    
    CreateWolk(owner, wolkFund); 
  }

   
   
  function unlock() external {
    if (now < unlockedAt) throw;
    uint256 vested = allocations[msg.sender] * 10**decimals;
    if (vested < 0 ) throw;  
    allocations[msg.sender] = 0;
    reservedTokens = safeSub(reservedTokens, vested);
    balances[msg.sender] = safeAdd(balances[msg.sender], vested); 
    Vested(msg.sender, vested);
  }

   
   
  function redeemToken() payable external {
    if (isFinalized) throw;
    if (block.number < start_block) throw;
    if (block.number > end_block) throw;
    if (msg.value <= dust) throw;
    if (tx.gasprice > 0.46 szabo && fairsale_protection) throw; 
    if (msg.value > 4 ether && fairsale_protection) throw; 

    uint256 tokens = safeMul(msg.value, tokenExchangeRate);  
    uint256 checkedSupply = safeAdd(generalTokens, tokens);
    if ( checkedSupply > tokenCreationMax) throw;  
    
      generalTokens = checkedSupply;
      balances[msg.sender] = safeAdd(balances[msg.sender], tokens);    
      CreateWolk(msg.sender, tokens);  
    
  }
  
   
   

   
  function fairsale_protectionOFF() external {
    if ( block.number - start_block < 200) throw;  
    if ( msg.sender != owner ) throw;
    fairsale_protection = false;
  }


   
  function finalize() external {
    if ( isFinalized ) throw;
    if ( msg.sender != owner ) throw;   
    if ( generalTokens < tokenCreationMin ) throw;  
    if ( block.number < end_block ) throw;  
    isFinalized = true;
    end_ts = now;
    unlockedAt = end_ts + 2 minutes;
    if ( ! multisig_owner.send(this.balance) ) throw;
  }

	function withdraw() onlyOwner{ 		
		if (this.balance == 0) throw;				
		if (generalTokens < tokenCreationMin) throw;	
        if ( ! multisig_owner.send(this.balance) ) throw;
 }
	
  function refund() external {
    if ( isFinalized ) throw; 
    if ( block.number < end_block ) throw;   
    if ( generalTokens >= tokenCreationMin ) throw;  
    if ( msg.sender == owner ) throw;
    uint256 Val = balances[msg.sender];
    balances[msg.sender] = 0;
    generalTokens = safeSub(generalTokens, Val);
    uint256 ethVal = safeDiv(Val, tokenExchangeRate);
    LogRefund(msg.sender, ethVal);
    if ( ! msg.sender.send(ethVal) ) throw;
  }
    
   
  function settleFrom(address _from, address _to, uint256 _value) isOperational() external returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
    var isPreauthorized = authorized[_from][msg.sender];
     
    if (balances[_from] >= _value && ( isPreauthorized ) && _value > 0) {
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from], _value);
      allowed[_from][msg.sender] = safeSub(_allowance, _value);
      if ( allowed[_from][msg.sender] < 0 ){
         allowed[_from][msg.sender] = 0;
      }
      Transfer(_from, _to, _value, balances[_from], balances[_to]);
      return true;
    } else {
        
      throw;
    }
  }

   
   
  modifier only_minter {
    assert(msg.sender == minter_address);
    _;
  }
  
  address public minter_address = owner;

  function mintTokens(uint reward_tok, address recipient) external payable only_minter
  {
    balances[recipient] = safeAdd(balances[recipient], reward_tok);
    generalTokens = safeAdd(generalTokens, reward_tok);
    MintEvent(reward_tok, recipient);
  }

  function changeMintingAddress(address newAddress) onlyOwner returns (bool success) { 
    minter_address = newAddress; 
    return true;
  }

  
   
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}