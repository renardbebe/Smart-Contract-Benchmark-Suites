 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract MSPT is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "MySmartProperty Tokens";
  string public constant symbol = "MSPT";
  uint32 public constant decimals = 18;

  address public addressSupporters;
  address public addressEccles;
  address public addressJenkins;
  address public addressLeskiw;
  address public addressBilborough;

  uint public summSupporters = 1000000 * 1 ether;
  uint public summEccles = 2000000 * 1 ether;
  uint public summJenkins = 2000000 * 1 ether;
  uint public summLeskiw = 2000000 * 1 ether;
  uint public summBilborough = 3000000 * 1 ether;

  function MSPT() public {
    addressSupporters = 0x49ce9f664d9fe7774fE29F5ab17b46266e4437a4;
    addressEccles = 0xF59C5199FCd7e29b2979831e39EfBcf16b90B485;
    addressJenkins = 0x974e94C33a37e05c4cE292b43e7F50a57fAA5Bc7;
    addressLeskiw = 0x3a7e8Eb6DDAa74e58a6F3A39E3d073A9eFA22160;
    addressBilborough = 0xAabb89Ade1Fc2424b7FE837c40E214375Dcf9840;  
      
     
    balances[addressSupporters] = balances[addressSupporters].add(summSupporters);
    balances[addressEccles] = balances[addressEccles].add(summEccles);
    balances[addressJenkins] = balances[addressJenkins].add(summJenkins);
    balances[addressLeskiw] = balances[addressLeskiw].add(summLeskiw);
    balances[addressBilborough] = balances[addressBilborough].add(summBilborough);
    totalSupply = summSupporters.add(summEccles).add(summJenkins).add(summLeskiw).add(summBilborough);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  MSPT public token;
   
  uint256 public startPreICO;
  uint256 public startICO;
  uint256 public endPreICO;
  uint256 public endICO;           
  
  uint256 public maxAmountPreICO;
  uint256 public maxAmountICO;
  
  uint256 public totalPreICOAmount;
  uint256 public totalICOAmount;
  
   
  uint public mintStart1;  
  uint public mintStart2;  
  uint public mintStart3;  
  uint public mintStart4;  
  uint public mintStart5;  
  
   
  address public wallet;

   
  uint256 public ratePreICO;
  uint256 public rateICO;      

   
  uint256 public minQuanValues; 
  
   
  uint256 public totalMintAmount; 
  uint256 public allowTotalMintAmount;
  uint256 public mintAmount1;
  uint256 public mintAmount2;
  uint256 public mintAmount3;
  uint256 public mintAmount4;
  uint256 public mintAmount5;
   
  uint256 public totalTokens;
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    token = createTokenContract();
     
    totalTokens = 100000000 * 1 ether;
     
    minQuanValues = 100000000000000000;
     
    startPreICO = 1527948000;  
    endPreICO = 1530280800;  
    startICO = 1530280800;  
    endICO = startICO +  30 * 1 days;           
     
    maxAmountPreICO = 12000000  * 1 ether;
    maxAmountICO = 24000000  * 1 ether;
     
    ratePreICO = 79294;
    rateICO = 59470;
     
    mintAmount1 = 10000000 * 1 ether;
    mintAmount2 = 10000000 * 1 ether;
    mintAmount3 = 10000000 * 1 ether;
    mintAmount4 = 10000000 * 1 ether;
    mintAmount5 = 10000000 * 1 ether;
    
    mintStart1 = 1538316000;  
    mintStart2 = 1540994400;  
    mintStart3 = 1551362400;  
    mintStart4 = 1554040800;  
    mintStart5 = 1569852000;  
     
    wallet = 0x7Ac93a7A1F8304c003274512F6c46C132106FE8E;
  }
  function setRatePreICO(uint _ratePreICO) public {
    ratePreICO = _ratePreICO;
  }  
  function setRateICO(uint _rateICO) public {
    rateICO = _rateICO;
  }    
  
  function createTokenContract() internal returns (MSPT) {
    return new MSPT();
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
     
    require(weiAmount >= minQuanValues);
    if (now >= startPreICO && now < endPreICO && totalPreICOAmount < maxAmountPreICO && tokens == 0){
      tokens = weiAmount.div(100).mul(ratePreICO);
      if (maxAmountPreICO.sub(totalPreICOAmount) < tokens){
        tokens = maxAmountPreICO.sub(totalPreICOAmount); 
        weiAmount = tokens.mul(100).div(ratePreICO);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreICOAmount = totalPreICOAmount.add(tokens);
      if (totalPreICOAmount >= maxAmountPreICO){
        startICO = now;
        endICO = startICO + 30 * 1 days;
      }   
    }    
    if (now >= startICO && totalICOAmount < maxAmountICO  && tokens == 0){
      tokens = weiAmount.div(100).mul(rateICO);
      if (maxAmountICO.sub(totalICOAmount) < tokens){
        tokens = maxAmountICO.sub(totalICOAmount); 
        weiAmount = tokens.mul(100).div(rateICO);
        backAmount = msg.value.sub(weiAmount);
      }
      totalICOAmount = totalICOAmount.add(tokens);
    }     
    require(tokens > 0);
    token.mint(beneficiary, tokens);
    wallet.transfer(weiAmount);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

  function mintTokens(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_amount > 0);
    require(_to != address(0));
    if (now >= mintStart1 && now < mintStart2){
      allowTotalMintAmount = mintAmount1;  
    }
    if (now >= mintStart2 && now < mintStart3){
      allowTotalMintAmount = mintAmount1.add(mintAmount2);  
    }  
    if (now >= mintStart3 && now < mintStart4){
      allowTotalMintAmount = mintAmount1.add(mintAmount2).add(mintAmount3);  
    }       
    if (now >= mintStart4 && now < mintStart5){
      allowTotalMintAmount = mintAmount1.add(mintAmount2).add(mintAmount3).add(mintAmount4);  
    }       
    if (now >= mintStart5){
      allowTotalMintAmount = totalMintAmount.add(totalTokens.sub(token.getTotalSupply()));
    }       
    require(_amount.add(totalMintAmount) <= allowTotalMintAmount);
    token.mint(_to, _amount);
    totalMintAmount = totalMintAmount.add(_amount);
    return true;
  }
  function finishMintingTokens() onlyOwner public returns (bool) {
    token.finishMinting(); 
  }
}