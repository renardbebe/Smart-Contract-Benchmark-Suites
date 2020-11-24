 

pragma solidity ^0.4.16;

 
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

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

   mapping (address => mapping (address => uint256)) allowed;


    
   function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
     var _allowance = allowed[_from][msg.sender];

      
      

     balances[_to] = balances[_to].add(_value);
     balances[_from] = balances[_from].sub(_value);
     allowed[_from][msg.sender] = _allowance.sub(_value);
     Transfer(_from, _to, _value);
     return true;
   }

    
   function approve(address _spender, uint256 _value) returns (bool) {

      
      
      
      
     require((_value == 0) || (allowed[msg.sender][_spender] == 0));

     allowed[msg.sender][_spender] = _value;
     Approval(msg.sender, _spender, _value);
     return true;
   }

    
   function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
     return allowed[_owner][_spender];
   }

 }

contract MintableToken is StandardToken, Ownable {
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0X0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract WisePlat is MintableToken {
  string public name = "WisePlat Token";
  string public symbol = "WISE";
  uint256 public decimals = 18;
  address public bountyWallet = 0x0;

  bool public transferStatus = false;

   
  modifier hasStartedTransfer() {
    require(transferStatus || msg.sender == bountyWallet);
    _;
  }

   
  function startTransfer() public onlyOwner {
    transferStatus = true;
  }
   
  function stopTransfer() public onlyOwner {
    transferStatus = false;
  }

  function setbountyWallet(address _bountyWallet) public onlyOwner {
    bountyWallet = _bountyWallet;
  }

   
  function transfer(address _to, uint _value) hasStartedTransfer returns (bool){
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) hasStartedTransfer returns (bool){
    return super.transferFrom(_from, _to, _value);
  }
}

contract WisePlatSale is Ownable {
  using SafeMath for uint256;

   
  WisePlat public token;

   
  uint256 public constant startTimestamp	= 1509274800;		 
  uint256 public constant middleTimestamp	= 1511607601;		 
  uint256 public constant endTimestamp		= 1514764799;		 

   
  address public constant devWallet 		= 0x00d6F1eA4238e8d9f1C33B7500CB89EF3e91190c;
  address public constant proWallet 		= 0x6501BDA688e8AC6C9cD96dc2DFBd6bDF3e886C05;
  address public constant bountyWallet 		= 0x354FFa86F138883b880C282000B5005E867E8eE4;
  address public constant remainderWallet	= 0x656C64D5C8BADe2a56A564B12706eE89bbe486EA;
  address public constant fundsWallet		= 0x06D49e8aA90b1413A641D69c6B8AC154f5c9FE92;
 
   
  uint256 public rate						= 10;
  uint256 public constant ratePreICO		= 20;	 
  uint256 public constant rateICO			= 15;	 
  
   
  uint256 public weiRaised;

   
  uint256 public constant minContribution 		= 0.1 ether;
  uint256 public constant minContribution_mBTC 	= 10;
  uint256 public rateBTCxETH 					= 17;

   
  uint256 public constant tokensTotal		=	 10000000 * 1e18;		 
  uint256 public constant tokensCrowdsale	=	  7000000 * 1e18;		 
  uint256 public constant tokensDevelopers  =	  1900000 * 1e18;		 
  uint256 public constant tokensPromotion	=	  1000000 * 1e18;		 
  uint256 public constant tokensBounty      = 	   100000 * 1e18;		 
  uint256 public tokensRemainder;  
  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenClaim4BTC(address indexed purchaser_evt, address indexed beneficiary_evt, uint256 value_evt, uint256 amount_evt, uint256 btc_evt, uint256 rateBTCxETH_evt);
  event SaleClosed();

  function WisePlatSale() {
    token = new WisePlat();
	token.mint(devWallet, tokensDevelopers);
	token.mint(proWallet, tokensPromotion);
	token.mint(bountyWallet, tokensBounty);
	token.setbountyWallet(bountyWallet);		 
    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);
  }

   
  modifier validPurchase {
    require(now >= startTimestamp);
    require(now <= endTimestamp);
    require(msg.value >= minContribution);
    require(tokensTotal > token.totalSupply());
    _;
  }
   
  modifier validPurchase4BTC {
    require(now >= startTimestamp);
    require(now <= endTimestamp);
    require(tokensTotal > token.totalSupply());
    _;
  }

   
  function hasEnded() public constant returns (bool) {
    bool timeLimitReached = now > endTimestamp;
    bool allOffered = tokensTotal <= token.totalSupply();
    return timeLimitReached || allOffered;
  }

   
  function buyTokens(address beneficiary) payable validPurchase {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

     
	if (now < middleTimestamp) {rate = ratePreICO;} else {rate = rateICO;}
    uint256 tokens = weiAmount.mul(rate);
    
	require(token.totalSupply().add(tokens) <= tokensTotal);
	
     
    weiRaised = weiRaised.add(weiAmount);
    
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    fundsWallet.transfer(msg.value);	 
  }
  
   
  function claimTokens4mBTC(address beneficiary, uint256 mBTC) validPurchase4BTC public onlyOwner {
    require(beneficiary != 0x0);
	require(mBTC >= minContribution_mBTC);

	 
	 
     
	uint256 weiAmount = mBTC.mul(rateBTCxETH) * 1e15;	 

     
	if (now < middleTimestamp) {rate = ratePreICO;} else {rate = rateICO;}
    uint256 tokens = weiAmount.mul(rate);
    
	require(token.totalSupply().add(tokens) <= tokensTotal);
	
     
    weiRaised = weiRaised.add(weiAmount);
    
    token.mint(beneficiary, tokens);
    TokenClaim4BTC(msg.sender, beneficiary, weiAmount, tokens, mBTC, rateBTCxETH);
     
  }

   
  function startTransfers() public onlyOwner {
	token.startTransfer();
  }
  
   
  function stopTransfers() public onlyOwner {
	token.stopTransfer();
  }
  
   
  function correctExchangeRateBTCxETH(uint256 _rateBTCxETH) public onlyOwner {
	require(_rateBTCxETH != 0);
	rateBTCxETH = _rateBTCxETH;
  }
  
   
  function finishMinting() public onlyOwner {
    require(hasEnded());
    uint issuedTokenSupply = token.totalSupply();			
	tokensRemainder = tokensTotal.sub(issuedTokenSupply);
	if (tokensRemainder > 0) {token.mint(remainderWallet, tokensRemainder);}
    token.finishMinting();
    token.transferOwnership(owner);
    SaleClosed();
  }

   
  function () payable {
    buyTokens(msg.sender);
  }
  
   
  function reclaimToken(address tokenAddr) external onlyOwner {
	require(!isTokenOfferedToken(tokenAddr));
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(msg.sender, balance);
  }
  function isTokenOfferedToken(address tokenAddr) returns(bool) {
        return token == tokenAddr;
  }
 
}