 

pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}



 
contract BitplusToken is MintableToken {

  string public name = "BitplusToken";
  string public symbol = "BPNT";
  uint256 public decimals = 18;

   
  function BitplusToken() {
    totalSupply = 0;
  }

}


 

contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  BitplusToken public token;

   
  uint256 public startBlock;
  uint256 public endBlock;

   
  address public wallet;
  
   
  uint256 public usdRate;

   
  uint256 public tokenPriceInCents;

   
  uint256 public weiRaised;
  
   
  bool public saleOpened = false;

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _usdRate,uint256 _tokenPriceInCents, address _wallet) {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_usdRate > 0);
    require(_tokenPriceInCents > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startBlock = _startBlock;
    endBlock = _endBlock;
    usdRate = _usdRate;
    tokenPriceInCents = _tokenPriceInCents;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (BitplusToken) {
    return new BitplusToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 updatedWeiRaised = weiRaised.add(weiAmount);

	 
	uint256 centsAmount = weiAmount.div(usdRate) * 1 ether;
	
     
    uint256 tokens = centsAmount.div(tokenPriceInCents);

     
    weiRaised = updatedWeiRaised;

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock && current <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && saleOpened;
  }

   
  function hasEnded() public constant returns (bool) {
    return (block.number > endBlock) && saleOpened;
  }
  
  function setTokenPrice(uint256 newPrice) public onlyOwner {
      tokenPriceInCents = newPrice;
  }
  
  function setUsdConversionRate(uint256 newUsdRate) public onlyOwner {
      usdRate = newUsdRate;
  }
  
  function closeSale() public onlyOwner {
      saleOpened = false;
  }
  
  function openSale() public onlyOwner {
      saleOpened = true;
  }

}

contract BitplusCrowdsale is Crowdsale  {
  using SafeMath for uint256;
  event CrowdsaleMintFinished();

  uint256 public cap;

  function BitplusCrowdsale(uint256 _cap, uint256 _startBlock, uint256 _endBlock, uint256 _usdRate, uint256 _tokenPriceInCents, address _wallet) Crowdsale(_startBlock, _endBlock, _usdRate, _tokenPriceInCents, _wallet) {
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }
  
   
   
  function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
      return token.mint(_to, _amount);
  }
  
  function changeTokenOwner(address _to) public onlyOwner {
      token.transferOwnership(_to);
  }

   
   
  function forwardFunds() public onlyOwner {
    wallet.transfer(this.balance);
  }  
  
   
  function finishMinting() onlyOwner returns (bool) {
    return token.finishMinting();
  }  
  
}