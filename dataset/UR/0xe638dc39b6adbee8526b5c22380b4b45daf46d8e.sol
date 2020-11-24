 

pragma solidity ^0.4.20;

 
 
 
 
 
 
 


 
 
 
 
 

library SafeMath {

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require( c >= a );
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require( b <= a );
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require( a == 0 || c / a == b );
  }

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

  mapping(address => bool) public isAdmin;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event AdminChange(address indexed _admin, bool _status);

   

  modifier onlyOwner { require( msg.sender == owner ); _; }
  modifier onlyAdmin { require( isAdmin[msg.sender] ); _; }

   

  function Owned() public {
    owner = msg.sender;
    isAdmin[owner] = true;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function addAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == false );
    isAdmin[_a] = true;
    AdminChange(_a, true);
  }

  function removeAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == true );
    isAdmin[_a] = false;
    AdminChange(_a, false);
  }
  
}


 
 
 
 
 
 

contract ERC20Interface {

   

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

   

  function totalSupply() public view returns (uint);
  function balanceOf(address _owner) public view returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint remaining);

}


 
 
 
 
 

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath for uint;

  uint public tokensIssuedTotal = 0;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

   

   

  function totalSupply() public view returns (uint) {
    return tokensIssuedTotal;
  }

   

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

   

  function transfer(address _to, uint _amount) public returns (bool success) {
     
    require( balances[msg.sender] >= _amount );

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

     
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   

  function approve(address _spender, uint _amount) public returns (bool success) {
     
    require( balances[msg.sender] >= _amount );
      
     
    allowed[msg.sender][_spender] = _amount;
    
     
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
     
    require( balances[_from] >= _amount );
    require( allowed[_from][msg.sender] >= _amount );

     
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }

   
   

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
 
 
 
 

contract GizerToken is ERC20Token {

   
  
  uint constant E6  = 10**6;

   

  string public constant name     = "Gizer Gaming Token";
  string public constant symbol   = "GZR";
  uint8  public constant decimals = 6;

   
  
  address public wallet;
  address public redemptionWallet;
  address public gizerItemsContract;

   

  uint public constant DATE_ICO_START = 1521122400;  

  uint public constant TOKEN_SUPPLY_TOTAL = 10000000 * E6;
  uint public constant TOKEN_SUPPLY_CROWD =  6112926 * E6;
  uint public constant TOKEN_SUPPLY_OWNER =  3887074 * E6;  
                                                            

  uint public constant MIN_CONTRIBUTION = 1 ether / 100;  
  
  uint public constant TOKENS_PER_ETH = 1000;
  
  uint public constant DATE_TOKENS_UNLOCKED = 1539180000;  

   
  
  uint public date_ico_end = 1523368800;  

   

  uint public tokensIssuedCrowd  = 0;
  uint public tokensIssuedOwner  = 0;
  uint public tokensIssuedLocked = 0;
  
  uint public etherReceived = 0;  

   
  
  mapping(address => uint) public etherContributed;
  mapping(address => uint) public tokensReceived;
  mapping(address => uint) public locked;
  
   
  
  event WalletUpdated(address _newWallet);
  event GizerItemsContractUpdated(address _GizerItemsContract);
  event RedemptionWalletUpdated(address _newRedemptionWallet);
  event DateIcoEndUpdated(uint _unixts);
  event TokensIssuedCrowd(address indexed _recipient, uint _tokens, uint _ether);
  event TokensIssuedOwner(address indexed _recipient, uint _tokens, bool _locked);
  event ItemsBought(address indexed _recipient, uint _lastIdx, uint _number);

   

   

  function GizerToken() public {
    require( TOKEN_SUPPLY_OWNER + TOKEN_SUPPLY_CROWD == TOKEN_SUPPLY_TOTAL );
    wallet = owner;
    redemptionWallet = owner;
  }

   
  
  function () public payable {
    buyTokens();
  }

   
  
   
  
  function atNow() public view returns (uint) {
    return now;
  }

   
  
  function tradeable() public view returns (bool) {
    if (atNow() > date_ico_end) return true ;
    return false;
  }
  
   
  
  function availableToMint() public view returns (uint available) {
    if (atNow() <= date_ico_end) {
      available = TOKEN_SUPPLY_OWNER.sub(tokensIssuedOwner);
    } else {
      available = TOKEN_SUPPLY_TOTAL.sub(tokensIssuedTotal);
    }
  }
  
   
  
  function unlockedTokens(address _account) public view returns (uint _unlockedTokens) {
    if (atNow() <= DATE_TOKENS_UNLOCKED) {
      return balances[_account] - locked[_account];
    } else {
      return balances[_account];
    }
  }

   
  
   

  function setWallet(address _wallet) public onlyOwner {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(_wallet);
  }

   

  function setRedemptionWallet(address _wallet) public onlyOwner {
    require( _wallet != address(0x0) );
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(_wallet);
  }
  
   

  function setGizerItemsContract(address _contract) public onlyOwner {
    require( _contract != address(0x0) );
    gizerItemsContract = _contract;
    GizerItemsContractUpdated(_contract);
  }
  
   

  function extendIco(uint _unixts) public onlyOwner {
    require( _unixts > date_ico_end );
    require( _unixts < 1530316800 );  
    date_ico_end = _unixts;
    DateIcoEndUpdated(_unixts);
  }
  
   

  function mintTokens(address _account, uint _tokens) public onlyOwner {
     
    require( _tokens <= availableToMint() );
    
     
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedOwner  = tokensIssuedOwner.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
     
    Transfer(0x0, _account, _tokens);
    TokensIssuedOwner(_account, _tokens, false);
  }

   

  function mintTokensLocked(address _account, uint _tokens) public onlyOwner {
     
    require( _tokens <= availableToMint() );
    
     
    balances[_account] = balances[_account].add(_tokens);
    locked[_account]   = locked[_account].add(_tokens);
    tokensIssuedOwner  = tokensIssuedOwner.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    tokensIssuedLocked = tokensIssuedLocked.add(_tokens);
    
     
    Transfer(0x0, _account, _tokens);
    TokensIssuedOwner(_account, _tokens, true);
  }  
  
   

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

   

   

  function buyTokens() private {
    
     
    require( atNow() > DATE_ICO_START && atNow() < date_ico_end );
    require( msg.value >= MIN_CONTRIBUTION );
    
     
    uint tokensAvailable = TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd);
    uint tokens = msg.value.mul(TOKENS_PER_ETH) / 10**12;
    require( tokens <= tokensAvailable );
    
     
    balances[msg.sender] = balances[msg.sender].add(tokens);
    
     
    tokensIssuedCrowd  = tokensIssuedCrowd.add(tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(tokens);
    etherReceived      = etherReceived.add(msg.value);
    
     
    etherContributed[msg.sender] = etherContributed[msg.sender].add(msg.value);
    tokensReceived[msg.sender]   = tokensReceived[msg.sender].add(tokens);
    
     
    if (this.balance > 0) wallet.transfer(this.balance);

     
    TokensIssuedCrowd(msg.sender, tokens, msg.value);
    Transfer(0x0, msg.sender, tokens);
  }

   

   

  function transfer(address _to, uint _amount) public returns (bool success) {
    require( tradeable() );
    require( unlockedTokens(msg.sender) >= _amount );
    return super.transfer(_to, _amount);
  }
  
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    require( tradeable() );
    require( unlockedTokens(_from) >= _amount ); 
    return super.transferFrom(_from, _to, _amount);
  }

   

   

  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    require( tradeable() );
    require( _addresses.length == _amounts.length );
    require( _addresses.length <= 100 );
    
     
    uint tokens_to_transfer = 0;
    for (uint i = 0; i < _addresses.length; i++) {
      tokens_to_transfer = tokens_to_transfer.add(_amounts[i]);
    }
    require( tokens_to_transfer <= unlockedTokens(msg.sender) );
    
     
    for (i = 0; i < _addresses.length; i++) {
      super.transfer(_addresses[i], _amounts[i]);
    }
  }
  
   
  
    
  
  function buyItem() public returns (uint idx) {
    super.transfer(redemptionWallet, E6);
    idx = mintItem(msg.sender);

     
    ItemsBought(msg.sender, idx, 1);
  }
  
    
  
  function buyMultipleItems(uint8 _items) public returns (uint idx) {
    
     
    require( _items > 0 && _items <= 100 );

     
    super.transfer(redemptionWallet, _items * E6);
    
     
    for (uint i = 0; i < _items; i++) {
      idx = mintItem(msg.sender);
    }

     
    ItemsBought(msg.sender, idx, _items);
  }

   
  
  function mintItem(address _owner) internal returns(uint idx) {
    GizerItemsInterface g = GizerItemsInterface(gizerItemsContract);
    idx = g.mint(_owner);
  }
  
}


 
 
 
 
 

contract GizerItemsInterface is Owned {

  function mint(address _to) public onlyAdmin returns (uint idx);

}