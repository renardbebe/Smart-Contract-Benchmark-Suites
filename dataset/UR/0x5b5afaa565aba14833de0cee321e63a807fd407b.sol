 

pragma solidity ^0.4.16;

 
 
 
 
 
 
 


 
 
 
 
 
 
 
 

library SafeMath3 {

  function mul(uint a, uint b) internal constant returns (uint c) {
    c = a * b;
    assert( a == 0 || c / a == b );
  }

  function sub(uint a, uint b) internal constant returns (uint) {
    assert( b <= a );
    return a - b;
  }

  function add(uint a, uint b) internal constant returns (uint c) {
    c = a + b;
    assert( c >= a );
  }

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

   

  modifier onlyOwner {
    require( msg.sender == owner );
    _;
  }

   

  function Owned() {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
 
 
 
 
 

contract ERC20Interface {

   

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

   

  function totalSupply() constant returns (uint);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);

}


 
 
 
 
 

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  uint public tokensIssuedTotal = 0;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

   

   

  function totalSupply() constant returns (uint) {
    return tokensIssuedTotal;
  }

   

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

   

  function transfer(address _to, uint _amount) returns (bool success) {
     
    require( balances[msg.sender] >= _amount );

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

     
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   

  function approve(address _spender, uint _amount) returns (bool success) {
     
    require ( balances[msg.sender] >= _amount );
      
     
    allowed[msg.sender][_spender] = _amount;
    
     
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
   

  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
     
    require( balances[_from] >= _amount );
    require( allowed[_from][msg.sender] >= _amount );

     
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }

   
   

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
 
 
 
 

contract TulipMania is ERC20Token {

   
  
  uint constant E6 = 10**6;
  
   

  string public constant name     = "Tulip Mania";
  string public constant symbol   = "BULB";
  uint8  public constant decimals = 6;

   
  
  address public wallet;
  address public adminWallet;

   

  uint public constant DATE_PRESALE_START = 1510758000;  
  uint public constant DATE_PRESALE_END   = 1511362800;  

  uint public constant DATE_ICO_START = 1511362801;  
  uint public constant DATE_ICO_END   = 1513868400;  

   
  
  uint public tokensPerEth = 336 * E6;
  uint public constant BONUS_PRESALE = 100;

     
  
  uint public constant TOKEN_SUPPLY_TOTAL = 10000000 * E6;  
  uint public constant TOKEN_SUPPLY_ICO   = 8500000 * E6;  
  uint public constant TOKEN_SUPPLY_MKT   =  1500000 * E6;  

  uint public constant PRESALE_ETH_CAP =  750 ether;

  uint public constant MIN_CONTRIBUTION = 1 ether / 500;  
  uint public constant MAX_CONTRIBUTION = 300 ether;

  uint public constant COOLDOWN_PERIOD =  2 days;
  uint public constant CLAWBACK_PERIOD = 2 days;

   

  uint public icoEtherReceived = 0;  

  uint public tokensIssuedIco   = 0;
  uint public tokensIssuedMkt   = 0;
  
  uint public tokensClaimedAirdrop = 0;
  
   
  
  mapping(address => uint) public icoEtherContributed;
  mapping(address => uint) public icoTokensReceived;

   
   
   
  
  mapping(address => bool) public airdropClaimed;
  mapping(address => bool) public refundClaimed;
  mapping(address => bool) public locked;

   
  
  event WalletUpdated(address _newWallet);
  event AdminWalletUpdated(address _newAdminWallet);
  event TokensPerEthUpdated(uint _tokensPerEth);
  event TokensMinted(address indexed _owner, uint _tokens, uint _balance);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _etherContributed);
  event Refund(address indexed _owner, uint _amount, uint _tokens);
  event Airdrop(address indexed _owner, uint _amount, uint _balance);
  event LockRemoved(address indexed _participant);

   

   

  function TulipMania() {
    require( TOKEN_SUPPLY_ICO + TOKEN_SUPPLY_MKT == TOKEN_SUPPLY_TOTAL );
    wallet = owner;
    adminWallet = owner;
  }

   
  
  function () payable {
    buyTokens();
  }
  
   
  
   
  
  function atNow() constant returns (uint) {
    return now;
  }
  
   

  function isTransferable() constant returns (bool transferable) {
     if ( atNow() < DATE_ICO_END + COOLDOWN_PERIOD ) return false;
     return true;
  }
  
   

   

  function removeLock(address _participant) {
    require( msg.sender == adminWallet || msg.sender == owner );
    locked[_participant] = false;
    LockRemoved(_participant);
  }

  function removeLockMultiple(address[] _participants) {
    require( msg.sender == adminWallet || msg.sender == owner );
    for (uint i = 0; i < _participants.length; i++) {
      locked[_participants[i]] = false;
      LockRemoved(_participants[i]);
    }
  }

   
  
   

  function setWallet(address _wallet) onlyOwner {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(wallet);
  }

   

  function setAdminWallet(address _wallet) onlyOwner {
    require( _wallet != address(0x0) );
    adminWallet = _wallet;
    AdminWalletUpdated(adminWallet);
  }

   
  
  function updateTokensPerEth(uint _tokensPerEth) onlyOwner {
    require( atNow() < DATE_PRESALE_START );
    tokensPerEth = _tokensPerEth;
    TokensPerEthUpdated(_tokensPerEth);
  }

   

  function mintMarketing(address _participant, uint _tokens) onlyOwner {
     
    require( _tokens <= TOKEN_SUPPLY_MKT.sub(tokensIssuedMkt) );
    
     
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedMkt        = tokensIssuedMkt.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
     
    locked[_participant] = true;
    
     
    Transfer(0x0, _participant, _tokens);
    TokensMinted(_participant, _tokens, balances[_participant]);
  }

   
   
  
  function ownerClawback() external onlyOwner {
    require( atNow() > DATE_ICO_END + CLAWBACK_PERIOD );
    wallet.transfer(this.balance);
  }

   

  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

   

   

  function buyTokens() private {
    uint ts = atNow();
    bool isPresale = false;
    bool isIco = false;
    uint tokens = 0;
    
     
    require( msg.value >= MIN_CONTRIBUTION );
    
     
    require( icoEtherContributed[msg.sender].add(msg.value) <= MAX_CONTRIBUTION );

     
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) isPresale = true;  
    if (ts > DATE_ICO_START && ts < DATE_ICO_END) isIco = true;  
    require( isPresale || isIco );

     
    if (isPresale) require( icoEtherReceived.add(msg.value) <= PRESALE_ETH_CAP );
    
     
    tokens = tokensPerEth.mul(msg.value) / 1 ether;
    
     
    if (isPresale) {
      tokens = tokens.mul(100 + BONUS_PRESALE) / 100;
    }
    
     
    require( tokensIssuedIco.add(tokens) <= TOKEN_SUPPLY_ICO );

     
    balances[msg.sender]          = balances[msg.sender].add(tokens);
    icoTokensReceived[msg.sender] = icoTokensReceived[msg.sender].add(tokens);
    tokensIssuedIco               = tokensIssuedIco.add(tokens);
    tokensIssuedTotal             = tokensIssuedTotal.add(tokens);
    
     
    icoEtherReceived                = icoEtherReceived.add(msg.value);
    icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
     
    locked[msg.sender] = true;
    
     
    Transfer(0x0, msg.sender, tokens);
    TokensIssued(msg.sender, tokens, balances[msg.sender], msg.value);

    wallet.transfer(this.balance);
  }
  
   

   

  function transfer(address _to, uint _amount) returns (bool success) {
    require( isTransferable() );
    require( locked[msg.sender] == false );
    require( locked[_to] == false );
    return super.transfer(_to, _amount);
  }
  
   

  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
    require( isTransferable() );
    require( locked[_from] == false );
    require( locked[_to] == false );
    return super.transferFrom(_from, _to, _amount);
  }

   

   
   

   
    
   
  
  function reclaimFunds() external {
    uint tokens;  
    uint amount;  
    
     
    require( atNow() > DATE_ICO_END);
    
     
    require( !refundClaimed[msg.sender] );
    
     
    require( icoEtherContributed[msg.sender] > 0 );
    
     
    tokens = icoTokensReceived[msg.sender];
    amount = icoEtherContributed[msg.sender];

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    tokensIssuedTotal    = tokensIssuedTotal.sub(tokens);
    
    refundClaimed[msg.sender] = true;
    
     
    msg.sender.transfer(amount);
    
     
    Transfer(msg.sender, 0x0, tokens);
    Refund(msg.sender, amount, tokens);
  }

   
    

  function claimAirdrop() external {
    doAirdrop(msg.sender);
  }

  function adminClaimAirdrop(address _participant) external {
    require( msg.sender == adminWallet );
    doAirdrop(_participant);
  }

  function adminClaimAirdropMultiple(address[] _addresses) external {
    require( msg.sender == adminWallet );
    for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i]);
  }  
  
  function doAirdrop(address _participant) internal {
    uint airdrop = computeAirdrop(_participant);

    require( airdrop > 0 );

     
    airdropClaimed[_participant] = true;
    balances[_participant] = balances[_participant].add(airdrop);
    tokensIssuedTotal      = tokensIssuedTotal.add(airdrop);
    tokensClaimedAirdrop   = tokensClaimedAirdrop.add(airdrop);
    
     
    Airdrop(_participant, airdrop, balances[_participant]);
    Transfer(0x0, _participant, airdrop);
  }

   
   
  
   
   
      
  function computeAirdrop(address _participant) constant returns (uint airdrop) {
     
    if ( atNow() < DATE_ICO_END ) return 0;
    
     
    if( airdropClaimed[_participant] ) return 0;

     
    if( icoTokensReceived[_participant] == 0 ) return 0;
    
     
    uint tokens = icoTokensReceived[_participant];
    uint newBalance = tokens.mul(TOKEN_SUPPLY_ICO) / tokensIssuedIco;
    airdrop = newBalance - tokens;
  }  

   
   

  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    require( isTransferable() );
    require( locked[msg.sender] == false );
    require( _addresses.length == _amounts.length );
    for (uint i = 0; i < _addresses.length; i++) {
      if (locked[_addresses[i]] == false) super.transfer(_addresses[i], _amounts[i]);
    }
  }  

}