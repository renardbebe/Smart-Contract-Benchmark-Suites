 

pragma solidity ^0.4.15;
 
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
 
 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
  
  Crowdsale crowdsale;
  
    modifier crowdsaleIsOverOrThisIsContract(){
      require(crowdsale.isCrowdsaleOver() || msg.sender == crowdsale.getContractAddress());
      _;
  }
 
   
  function transfer(address _to, uint256 _value) crowdsaleIsOverOrThisIsContract returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
 
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
  
  
  
  function StandardToken(Crowdsale x){
      crowdsale =x;
  }
  

 
   
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
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
 
 
contract MintableToken is StandardToken, Ownable {
    
     function MintableToken(Crowdsale x) StandardToken(x){
        
    }
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
 
   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_to][_to] =  allowed[_to][_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 
contract DjohniKrasavchickToken is MintableToken {
    
    string public constant name = "DjohniKrasavchickToken";
    
    string public constant symbol = "DJKR";
    
    uint32 public constant decimals = 2;
    
    function DjohniKrasavchickToken(Crowdsale x) MintableToken(x){
        
    } 
    
}
 
 
contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public myWalletForETH;
    
    uint public bountyPercent;
    
    uint public djonniPercent;
    
    uint public developerPercent;
    
    uint public bountyTokens;
    
    uint public djonniTokens;
    
    uint public developerTokens;
    
    address[] public bountyAdresses;
 
    DjohniKrasavchickToken public token = new DjohniKrasavchickToken(this);
 
    uint public start;
    
    uint public period;
 
    uint public hardcap;
 
    uint public rate;
    
    uint public softcap;
    
    bool private isHardCapWasReached = false;
    
    bool private isCrowdsaleStoped = false;
    
    mapping(address => uint) public balances;
 
    function Crowdsale() {
      myWalletForETH = 0xe4D5b0aECfeFf1A39235f49254a0f37AaA7F6cC0;
      bountyPercent = 10;
      djonniPercent = 50;
      developerPercent = 20;
      rate = 100000000;
      start = 1536858000;
      period = 14;
      hardcap = 200000000000000000;
      softcap = 50000000000000000;
    }
     
    function getContractAddress() public returns(address){
        return this;
    }
    
    function isCrowdsaleOver() public returns(bool){
        if( isCrowsdaleTimeFinished() || isHardCapReached() || isCrowdsaleStoped){
            return true;
        }
        return false;
    }
    
    function isCrowsdaleTimeFinished() internal returns(bool){
        if(now > start + period * 1 hours){
            return true;
        }
        return false;
    }
    
    function isHardCapReached() internal returns (bool){
        if(hardcap==this.balance){
            isHardCapWasReached = true;
        }
        return isHardCapWasReached;
    }
    
    function stopCrowdSaleOnlyForOwner() onlyOwner{
        if(!isCrowdsaleStoped){
         stopCrowdSale();
        }
    }
    
    function stopCrowdSale() internal{
        if(token.mintingFinished() == false){
              finishMinting();
        }
        isCrowdsaleStoped = true;
    }
 
    modifier saleIsOn() {
      require(now > start && now < start + period * 1 hours);
      _;
    }
    
    modifier crowdsaleIsOver() {
      require(isCrowdsaleOver());
      _;
    }

    modifier isUnderHardCap() {
      require(this.balance <= hardcap && !isHardCapWasReached );
      _;
    }
    
    modifier onlyOwnerOrSaleIsOver(){
        require(owner==msg.sender || isCrowdsaleOver() );
        _;
    }
 
    function refund() {
      require(this.balance < softcap && now > start + period * 1 hours);
      uint value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
    }
 
    function finishMinting() public onlyOwnerOrSaleIsOver  {
      if(this.balance > softcap) {
        myWalletForETH.transfer(this.balance);
        uint issuedTokenSupply = token.totalSupply();
        uint additionalTokens = bountyPercent+developerPercent+djonniPercent;
        uint tokens = issuedTokenSupply.mul(additionalTokens).div(100 - additionalTokens);
        token.mint(this, tokens);
        token.finishMinting();
        issuedTokenSupply = token.totalSupply();
        bountyTokens = issuedTokenSupply.div(100).mul(bountyPercent);
        developerTokens = issuedTokenSupply.div(100).mul(developerPercent);
        djonniTokens = issuedTokenSupply.div(100).mul(djonniPercent);
        token.transfer(myWalletForETH, developerTokens);
      }
    }
    
    function showThisBallance() public returns (uint){
        return this.balance;
    }

 
   function createTokens() isUnderHardCap saleIsOn payable {
      uint tokens = rate.mul(msg.value).div(1 ether);
      token.mint(this, tokens);
      token.transfer(msg.sender, tokens);
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    

 
    function() external payable {
     if(isCrowsdaleTimeFinished() && !isCrowdsaleStoped){
       stopCrowdSale();    
     }
     createTokens();
     if(isCrowdsaleOver() && !isCrowdsaleStoped){
      stopCrowdSale();
     }
    }
    
    function addBountyAdresses(address[] array) onlyOwner{
               for (uint i = 0; i < array.length; i++){
                  bountyAdresses.push(array[i]);
               }
    }
    
    function distributeBountyTokens() onlyOwner crowdsaleIsOver{
               uint amountofTokens = bountyTokens/bountyAdresses.length;
               for (uint i = 0; i < bountyAdresses.length; i++){
                  token.transfer(bountyAdresses[i], amountofTokens);
               }
               bountyTokens = 0;
    }
    
        function distributeDjonniTokens(address addr) onlyOwner crowdsaleIsOver{
                  token.transfer(addr, djonniTokens);
                  djonniTokens = 0;
              
    }
    
    
    
}