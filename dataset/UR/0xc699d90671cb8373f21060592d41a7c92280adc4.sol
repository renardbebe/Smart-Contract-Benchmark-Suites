 

pragma solidity ^0.4.18;
 
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

contract Token {
  function totalSupply() constant public returns (uint256 supply);

  function balanceOf(address _owner) constant public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public  returns (bool success) ;
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) ;
  function approve(address _spender, uint256 _value) public  returns (bool success) ;
  function allowance(address _owner, address _spender) constant public  returns (uint256 remaining) ;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public totalTokens;
   
  uint softcap;
   
  uint hardcap;  
  Token public token;
   
  mapping(address => uint) public balances;
   
  mapping(address => uint) public balancesToken;  
   

   
  
   
     
  uint256 public startPreSale;
     
  uint256 public endPreSale;

   
     
  uint256 public startIco;
     
  uint256 public endIco;    

   
  uint256 public maxPreSale;
  uint256 public maxIco;

  uint256 public totalPreSale;
  uint256 public totalIco;
  
   
  uint256 public ratePreSale;
  uint256 public rateIco;   

   
  address public wallet;

   
  uint256 public minQuanValues; 
  uint256 public maxQuanValues; 

 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    
     
    softcap = 5000 * 1 ether; 
    hardcap = 20000 * 1 ether;  	
     
    minQuanValues = 100000000000000000;  
     
    maxQuanValues = 27 * 1 ether;  
     
     
       
    startPreSale = 1523260800; 
       
    endPreSale = 1525507200; 
  
     
       
    startIco = 1525507200; 
       
    endIco = startIco + 6 * 7 * 1 days;   

     
    ratePreSale = 382;
    rateIco = 191; 
    
     
    maxPreSale = 30000000 * 1 ether;
    maxIco =     60000000 * 1 ether;    
    
     
    wallet = 0x04cFbFa64917070d7AEECd20225782240E8976dc;
  }

  function setratePreSale(uint _ratePreSale) public onlyOwner  {
    ratePreSale = _ratePreSale;
  }
 
  function setrateIco(uint _rateIco) public onlyOwner  {
    rateIco = _rateIco;
  }   
  


   
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function setToken(address _address) public onlyOwner {
      token = Token(_address);
  }
    
   
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
     
    require(weiAmount >= minQuanValues);
     
    require(weiAmount.add(balances[msg.sender]) <= maxQuanValues);    
     
    address _this = this;
    require(hardcap > _this.balance);

     
    if (now >= startPreSale && now < endPreSale && totalPreSale < maxPreSale){
      tokens = weiAmount.mul(ratePreSale);
	  if (maxPreSale.sub(totalPreSale) <= tokens){
	    endPreSale = now;
	    startIco = now;
	    endIco = startIco + 6 * 7 * 1 days; 
	  }
      if (maxPreSale.sub(totalPreSale) < tokens){
        tokens = maxPreSale.sub(totalPreSale); 
        weiAmount = tokens.div(ratePreSale);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreSale = totalPreSale.add(tokens);
    }
       
     
    if (now >= startIco && now < endIco && totalIco < maxIco){
      tokens = weiAmount.mul(rateIco);
      if (maxIco.sub(totalIco) < tokens){
        tokens = maxIco.sub(totalIco); 
        weiAmount = tokens.div(rateIco);
        backAmount = msg.value.sub(weiAmount);
      }
      totalIco = totalIco.add(tokens);
    }        

    require(tokens > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    balancesToken[msg.sender] = balancesToken[msg.sender].add(tokens);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }
  function getToken() public{
    address _this = this;
    require(_this.balance >= softcap && now > endIco); 
    uint value = balancesToken[msg.sender];
    balancesToken[msg.sender] = 0;
    token.transfer(msg.sender, value);
  }
  
  function refund() public{
    address _this = this;
    require(_this.balance < softcap && now > endIco);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferTokenToMultisig(address _address) public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    token.transfer(_address, token.balanceOf(_this));
  }   
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    wallet.transfer(_this.balance);
  }  
}