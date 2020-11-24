 

pragma solidity ^0.4.23;
 
contract Ownable {
  address public owner;
  
  constructor(){ 
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
   
  function transferOwnership(address _newOwner) onlyOwner {
    if (_newOwner != address(0)) {
      owner = _newOwner;
    }
  }
}

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}

contract Token {

  uint256 public totalSupply;
  function balanceOf(address _owner) constant returns (uint256 balance);

  function transfer(address _to, uint256 _value) returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  function approve(address _spender, uint256 _value) returns (bool success);

  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token ,SafeMath{

    
  modifier onlyPayloadSize(uint size) {   
     if(msg.data.length != size + 4) {
       revert();
     }
     _;
  }

   
  bool transferLock = true;
   
  modifier canTransfer() {
    if (transferLock) {
      revert();
    }
    _;
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
    
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
  }

   function approve(address _spender, uint256 _value) canTransfer returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract PAIStandardToken is StandardToken,Ownable{

   

  string public name;                    
  uint256 public decimals;               
  string public symbol;                  
  address public wallet;                 
  uint public start;                     
  uint public end;                       
  uint public deadline;                  


  uint256 public teamShare = 25;         
  uint256 public foundationShare = 25;   
  uint256 public posShare = 15;          
  uint256 public saleShare = 35;      
  
  
  address internal saleAddr;                                  
  uint256 public crowdETHTotal = 0;                  
  mapping (address => uint256) public crowdETHs;     
  uint256 public crowdPrice = 10000;                 
  uint256 public crowdTarget = 5000 ether;           
  bool public reflectSwitch = false;                 
  bool public blacklistSwitch = true;                
  mapping(address => string) public reflects;        
  

  event PurchaseSuccess(address indexed _addr, uint256 _weiAmount,uint256 _crowdsaleEth,uint256 _balance);
  event EthSweepSuccess(address indexed _addr, uint256 _value);
  event SetReflectSwitchEvent(bool _b);
  event ReflectEvent(address indexed _addr,string _paiAddr);
  event BlacklistEvent(address indexed _addr,uint256 _b);
  event SetTransferLockEvent(bool _b);
  event CloseBlacklistSwitchEvent(bool _b);

  constructor(
      address _wallet,
      uint _s,
      uint _e,
      uint _d,
      address _teamAddr,
      address _fundationAddr,
      address _saleAddr,
      address _posAddr
      ) {
      totalSupply = 2100000000000000000000000000;        
      name = "PCHAIN";                   
      decimals = 18;            
      symbol = "PAI";               
      wallet = _wallet;                    
      start = _s;                          
      end = _e;                            
      deadline = _d;                       
      saleAddr = _saleAddr;  

      balances[_teamAddr] = safeMul(safeDiv(totalSupply,100),teamShare);  
      balances[_fundationAddr] = safeMul(safeDiv(totalSupply,100),foundationShare);  
      balances[_posAddr] = safeMul(safeDiv(totalSupply,100),posShare);  
      balances[_saleAddr] = safeMul(safeDiv(totalSupply,100),saleShare) ;  
      Transfer(address(0), _teamAddr,  balances[_teamAddr]);
      Transfer(address(0), _fundationAddr,  balances[_fundationAddr]);
      Transfer(address(0), _posAddr,  balances[_posAddr]);
      Transfer(address(0), _saleAddr,  balances[_saleAddr]);
  }
   
  function setTransferLock(bool _lock) onlyOwner{
      transferLock = _lock;
      SetTransferLockEvent(_lock);
  }
   
  function closeBlacklistSwitch() onlyOwner{
    blacklistSwitch = false;
    CloseBlacklistSwitchEvent(false);
  }
   
  function setBlacklist(address _addr) onlyOwner{
      require(blacklistSwitch);
      uint256 tokenAmount = balances[_addr];              
      balances[_addr] = 0; 
      balances[saleAddr] = safeAdd(balances[saleAddr],tokenAmount);   
      Transfer(_addr, saleAddr, tokenAmount);
      BlacklistEvent(_addr,tokenAmount);
  } 

   
  function setReflectSwitch(bool _s) onlyOwner{
      reflectSwitch = _s;
      SetReflectSwitchEvent(_s);
  }
  function reflect(string _paiAddress){
      require(reflectSwitch);
      reflects[msg.sender] = _paiAddress;
      ReflectEvent(msg.sender,_paiAddress);
  }

  function purchase() payable{
      require(block.timestamp <= deadline);                                  
      require(tx.gasprice <= 60000000000);
      require(block.timestamp >= start);                                 
      uint256 weiAmount = msg.value;                                     
      require(weiAmount >= 0.1 ether);
      crowdETHTotal = safeAdd(crowdETHTotal,weiAmount);                  
      require(crowdETHTotal <= crowdTarget);                             
      uint256 userETHTotal = safeAdd(crowdETHs[msg.sender],weiAmount);   
      if(block.timestamp <= end){                                        
        require(userETHTotal <= 0.4 ether);                              
      }else{
        require(userETHTotal <= 10 ether);                               
      }      
      
      crowdETHs[msg.sender] = userETHTotal;                              

      uint256 tokenAmount = safeMul(weiAmount,crowdPrice);              
      balances[msg.sender] = safeAdd(tokenAmount,balances[msg.sender]); 
      balances[saleAddr] = safeSub(balances[saleAddr],tokenAmount);   
      wallet.transfer(weiAmount);
      Transfer(saleAddr, msg.sender, tokenAmount);
      PurchaseSuccess(msg.sender,weiAmount,crowdETHs[msg.sender],tokenAmount); 
  }

  function () payable{
      purchase();
  }
}