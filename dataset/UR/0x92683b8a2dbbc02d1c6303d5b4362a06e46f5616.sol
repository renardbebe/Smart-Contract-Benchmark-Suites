 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 


 
 
 
 
 

library SafeM {

  function add(uint a, uint b) public pure returns (uint c) {
    c = a + b;
    require( c >= a );
  }

  function sub(uint a, uint b) public pure returns (uint c) {
    require( b <= a );
    c = a - b;
  }

  function mul(uint a, uint b) public pure returns (uint c) {
    c = a * b;
    require( a == 0 || c / a == b );
  }

  function div(uint a, uint b) public pure returns (uint c) {
    c = a / b;
  }  

}


 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _to);

   

  modifier onlyOwner {
    require( msg.sender == owner );
    _;
  }

   

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    newOwner = _newOwner;
    OwnershipTransferProposed(owner, _newOwner);
  }

  function acceptOwnership() public {
    require( msg.sender == newOwner );
    owner = newOwner;
    OwnershipTransferred(owner);
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
  
  using SafeM for uint;

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


 
 
 
 
 

contract GizerTokenPresale is ERC20Token {

   
  
  uint constant E6  = 10**6;

   

  string public constant name     = "Gizer Gaming Presale Token";
  string public constant symbol   = "GZRPRE";
  uint8  public constant decimals = 6;

   
  
  address public wallet;
  address public redemptionWallet;

     
  
  uint public constant MIN_CONTRIBUTION = 1 ether / 10;  
  uint public constant MAX_CONTRIBUTION = 2300 ether;
  
   

  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 ether;
  
   
  
  uint public constant DATE_PRESALE_START = 1512050400;  
  uint public constant DATE_PRESALE_END   = 1512914400;  
  
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6;  
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6;  
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6;  
  
  uint public constant CUTOFF_PRESALE_ONE = 100;  
  uint public constant CUTOFF_PRESALE_TWO = 500;  

  uint public constant FUNDING_PRESALE_MAX = 2300 ether;

   

  uint public etherReceivedPrivate = 0;  
  uint public etherReceivedCrowd   = 0;  

  uint public tokensIssuedPrivate = 0;  
  uint public tokensIssuedCrowd   = 0;  
  uint public tokensBurnedTotal   = 0;  
  
  uint public presaleContributorCount = 0;
  
  bool public tokensFrozen = false;

   

  mapping(address => uint) public balanceEthPrivate;  
  mapping(address => uint) public balanceEthCrowd;    

  mapping(address => uint) public balancesPrivate;  
  mapping(address => uint) public balancesCrowd;    

   
  
  event WalletUpdated(address _newWallet);
  event RedemptionWalletUpdated(address _newRedemptionWallet);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedCrowd, bool indexed _isPrivateSale, uint _amount);
  event OwnerTokensBurned(uint _tokensBurned, uint _tokensBurnedTotal);
  
   

   

  function GizerTokenPresale() public {
    wallet = owner;
    redemptionWallet = owner;
  }

   
  
  function () public payable {
    buyTokens();
  }

   
  
   
  
  function atNow() public view returns (uint) {
    return now;
  }

   
  
   

  function setWallet(address _wallet) public onlyOwner {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(_wallet);
  }

   

  function setRedemptionWallet(address _wallet) public onlyOwner {
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(_wallet);
  }
  
   

  function privateSaleContribution(address _account, uint _amount) public onlyOwner {
     
    require( _account != address(0x0) );
    require( atNow() < DATE_PRESALE_END );
    require( _amount >= MIN_CONTRIBUTION );
    require( etherReceivedPrivate.add(_amount) <= PRIVATE_SALE_MAX_ETHER );
    
     
    uint tokens = TOKETH_PRESALE_ONE.mul(_amount) / 1 ether;
    
     
    issueTokens(_account, tokens, _amount, true);  
  }

   
  
  function freezeTokens() public onlyOwner {
    require( atNow() > DATE_PRESALE_END );
    tokensFrozen = true;
  }
  
   
  
  function burnOwnerTokens() public onlyOwner {
     
    require( balances[owner] > 0 );
    
     
    uint tokensBurned = balances[owner];
    balances[owner] = 0;
    tokensIssuedTotal = tokensIssuedTotal.sub(tokensBurned);
    tokensBurnedTotal = tokensBurnedTotal.add(tokensBurned);
    
     
    Transfer(owner, 0x0, tokensBurned);
    OwnerTokensBurned(tokensBurned, tokensBurnedTotal);

  }  

   

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

   

   

  function buyTokens() private {
     
    require( atNow() > DATE_PRESALE_START && atNow() < DATE_PRESALE_END );
    require( msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION );
    require( etherReceivedCrowd.add(msg.value) <= FUNDING_PRESALE_MAX );

     
    uint tokens;
    if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
       
      tokens = TOKETH_PRESALE_ONE.mul(msg.value) / 1 ether;
    } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
       
      tokens = TOKETH_PRESALE_TWO.mul(msg.value) / 1 ether;
    } else {
       
      tokens = TOKETH_PRESALE_THREE.mul(msg.value) / 1 ether;
    }
    presaleContributorCount += 1;
    
     
    issueTokens(msg.sender, tokens, msg.value, false);  
  }
  
   
  
  function issueTokens(address _account, uint _tokens, uint _amount, bool _isPrivateSale) private {
     
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedCrowd  = tokensIssuedCrowd.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    if (_isPrivateSale) {
      tokensIssuedPrivate         = tokensIssuedPrivate.add(_tokens);
      etherReceivedPrivate        = etherReceivedPrivate.add(_amount);
      balancesPrivate[_account]   = balancesPrivate[_account].add(_tokens);
      balanceEthPrivate[_account] = balanceEthPrivate[_account].add(_amount);
    } else {
      etherReceivedCrowd        = etherReceivedCrowd.add(_amount);
      balancesCrowd[_account]   = balancesCrowd[_account].add(_tokens);
      balanceEthCrowd[_account] = balanceEthCrowd[_account].add(_amount);
    }
    
     
    Transfer(0x0, _account, _tokens);
    TokensIssued(_account, _tokens, balances[_account], tokensIssuedCrowd, _isPrivateSale, _amount);

     
    if (this.balance > 0) wallet.transfer(this.balance);

  }

   

   

  function transfer(address _to, uint _amount) public returns (bool success) {
    require( _to == owner || (!tokensFrozen && _to == redemptionWallet) );
    return super.transfer(_to, _amount);
  }
  
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    require( !tokensFrozen && _to == redemptionWallet );
    return super.transferFrom(_from, _to, _amount);
  }

}