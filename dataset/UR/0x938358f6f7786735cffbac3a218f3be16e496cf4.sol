 

pragma solidity ^0.4.16;

 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
 
 
 
 
 

library SafeMath3 {

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
  }

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

   

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner);
    require(_newOwner != address(0x0));
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
 
 
 
 
 
 
 
 

contract ERC20Interface {

   

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

   

  function totalSupply() public constant returns (uint);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);

}


 
 
 
 
 

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  uint public tokensIssuedTotal = 0;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

   

   

  function totalSupply() public constant returns (uint) {
    return tokensIssuedTotal;
  }

   

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

   

  function transfer(address _to, uint _amount) public returns (bool success) {
     
    require(balances[msg.sender] >= _amount);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   

  function approve(address _spender, uint _amount) public returns (bool success) {
     
    require(balances[msg.sender] >= _amount);
      
     
    allowed[msg.sender][_spender] = _amount;
    
     
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
     
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);

     
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }

   
   

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
 
 
 
 

contract HODLwin is ERC20Token {

   
  
  
   

  string public constant name = "HODLwin";
  string public constant symbol = "WIN";
  uint8  public constant decimals = 18;

   
  
  address public wallet;
  address public adminWallet;

   

  uint public constant DATE_PRESALE_START = 1518105804;  
  uint public constant DATE_PRESALE_END   = 1523019600;  

  uint public constant DATE_ICO_START = 1523019600;  
  uint public constant DATE_ICO_END   = 1530882000;  

   
  
  uint public tokensPerEth = 1000 * 10**18;  
                                                 
  uint public constant BONUS_PRESALE      = 50; 
  uint public constant BONUS_ICO_PERIOD_ONE = 20; 
  uint public constant BONUS_ICO_PERIOD_TWO = 10; 
                                                 
     
  
  uint public constant TOKEN_SUPPLY_TOTAL = 100000000 * 10**18;  
  uint public constant TOKEN_SUPPLY_ICO   = 50000000 * 10**18;  
  uint public constant TOKEN_SUPPLY_AIR   = 50000000 * 10**18;  

  uint public constant PRESALE_ETH_CAP =  10000 ether;

  uint public constant MIN_FUNDING_GOAL =  100 * 10**18 ;  
  
  uint public constant MIN_CONTRIBUTION = 1 ether / 20;  
  uint public constant MAX_CONTRIBUTION = 10000 ether;

  uint public constant COOLDOWN_PERIOD =  1 days;
  uint public constant CLAWBACK_PERIOD = 90 days;

   

  uint public icoEtherReceived = 0;  

  uint public tokensIssuedIco   = 0;
  uint public tokensIssuedAir   = 0;
  

   
  
  mapping(address => uint) public icoEtherContributed;
  mapping(address => uint) public icoTokensReceived;

   

   mapping(address => bool) public refundClaimed;
 

   
  
  event WalletUpdated(address _newWallet);
  event AdminWalletUpdated(address _newAdminWallet);
  event TokensPerEthUpdated(uint _tokensPerEth);
  event TokensMinted(address indexed _owner, uint _tokens, uint _balance);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _etherContributed);
  event Refund(address indexed _owner, uint _amount, uint _tokens);
 

   

   

  function HODLwin () public {
    require(TOKEN_SUPPLY_ICO + TOKEN_SUPPLY_AIR == TOKEN_SUPPLY_TOTAL);
    wallet = owner;
    adminWallet = owner;
  }

   
  
  function () public payable {
    buyTokens();
  }
  
   
  
   
  
  function atNow() public constant returns (uint) {
    return now;
  }
  
   
  
  function icoThresholdReached() public constant returns (bool thresholdReached) {
     if (icoEtherReceived < MIN_FUNDING_GOAL) {
        return false; 
     }
     return true;
  }  
  
   

  function isTransferable() public constant returns (bool transferable) {
     if (!icoThresholdReached()) { 
         return false;
         }
     if (atNow() < DATE_ICO_END + COOLDOWN_PERIOD) {
          return false; 
          }
     return true;
  }
  
   
  
   

  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0x0));
    wallet = _wallet;
    WalletUpdated(wallet);
  }

   

  function setAdminWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0x0));
    adminWallet = _wallet;
    AdminWalletUpdated(adminWallet);
  }

   
  
  function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {
    require(atNow() < DATE_PRESALE_START);
    tokensPerEth = _tokensPerEth;
    TokensPerEthUpdated(_tokensPerEth);
  }

   

  function mintAirdrop(address _participant, uint _tokens) public onlyOwner {
     
    require(_tokens <= TOKEN_SUPPLY_AIR.sub(tokensIssuedAir));
    require(_tokens.mul(10) <= TOKEN_SUPPLY_AIR); 
     
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedAir = tokensIssuedAir.add(_tokens);
    tokensIssuedTotal = tokensIssuedTotal.add(_tokens);

     
    Transfer(0x0, _participant, _tokens);
    TokensMinted(_participant, _tokens, balances[_participant]);
  }

function mintMultiple(address[] _addresses, uint _tokens) public onlyOwner {
    require(msg.sender == adminWallet);
    require(_tokens.mul(10) <= TOKEN_SUPPLY_AIR); 
    for (uint i = 0; i < _addresses.length; i++) {
     mintAirdrop(_addresses[i], _tokens);
        }
    
  }  
  
   
   
  
  function ownerClawback() external onlyOwner {
    require(atNow() > DATE_ICO_END + CLAWBACK_PERIOD);
    wallet.transfer(this.balance);
  }

   

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

   

 
 
 
 
 
 
 
 
 
 
 

   
  function buyTokens() private {
    uint ts = atNow();
    bool isPresale = false;
    bool isIco = false;
    uint tokens = 0;
    
     
    require(msg.value >= MIN_CONTRIBUTION);
    
     
    require(icoEtherContributed[msg.sender].add(msg.value) <= MAX_CONTRIBUTION);

     
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) {
         isPresale = true; 
         }
    if (ts > DATE_ICO_START && ts < DATE_ICO_END) {
         isIco = true; 
         }
    if (ts > DATE_PRESALE_START && ts < DATE_ICO_END && icoEtherReceived >= PRESALE_ETH_CAP) { 
        isIco = true; 
        }
    if (ts > DATE_PRESALE_START && ts < DATE_ICO_END && icoEtherReceived >= PRESALE_ETH_CAP) {
         isPresale = false;
          }

    require(isPresale || isIco);

     
    if (isPresale) {
        require(icoEtherReceived.add(msg.value) <= PRESALE_ETH_CAP);
    }
    
     
    tokens = tokensPerEth.mul(msg.value) / 1 ether;
    
     
    if (isPresale) {
      tokens = tokens.mul(100 + BONUS_PRESALE) / 100;
    } else if (ts < DATE_ICO_START + 21 days) {
       
      tokens = tokens.mul(100 + BONUS_ICO_PERIOD_ONE) / 100;
    } else if (ts < DATE_ICO_START + 42 days) {
       
      tokens = tokens.mul(100 + BONUS_ICO_PERIOD_TWO) / 100;
    }
    
     
    require(tokensIssuedIco.add(tokens) <= TOKEN_SUPPLY_ICO );

     
    balances[msg.sender] = balances[msg.sender].add(tokens);
    icoTokensReceived[msg.sender] = icoTokensReceived[msg.sender].add(tokens);
    tokensIssuedIco = tokensIssuedIco.add(tokens);
    tokensIssuedTotal = tokensIssuedTotal.add(tokens);
    
     
    icoEtherReceived = icoEtherReceived.add(msg.value);
    icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
    
     
    Transfer(0x0, msg.sender, tokens);
    TokensIssued(msg.sender, tokens, balances[msg.sender], msg.value);

     
    if (icoThresholdReached()) {
        wallet.transfer(this.balance);
     }
  }
  
   

   

  function transfer(address _to, uint _amount) public returns (bool success) {
    require(isTransferable());
      return super.transfer(_to, _amount);
  }
  
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    require(isTransferable());
    return super.transferFrom(_from, _to, _amount);
  }
 
 
 
 
 
 
 
 
 
 
 
   

   
   

   
    
   
  
  function reclaimFunds() external {
    uint tokens;  
    uint amount;  
    
     
    require(atNow() > DATE_ICO_END && !icoThresholdReached());
    
     
    require(!refundClaimed[msg.sender]);
    
     
    require(icoEtherContributed[msg.sender] > 0);
    
     
    tokens = icoTokensReceived[msg.sender];
    amount = icoEtherContributed[msg.sender];
   
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    tokensIssuedTotal = tokensIssuedTotal.sub(tokens);
    
    refundClaimed[msg.sender] = true;
    
     
    msg.sender.transfer(amount);
    
     
    Transfer(msg.sender, 0x0, tokens);
    Refund(msg.sender, amount, tokens);
  }

  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    require(isTransferable());
  
    require(_addresses.length == _amounts.length);
    for (uint i = 0; i < _addresses.length; i++) {
     super.transfer(_addresses[i], _amounts[i]);
    }
  }  

}