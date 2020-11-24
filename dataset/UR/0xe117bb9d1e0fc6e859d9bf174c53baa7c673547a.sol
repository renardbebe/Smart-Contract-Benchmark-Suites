 

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

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  address public addressTeam =  0x04cFbFa64917070d7AEECd20225782240E8976dc;
  bool public frozenAccountICO = true;
  mapping(address => uint256) balances;
  mapping (address => bool) public frozenAccount;
  function setFrozenAccountICO(bool _frozenAccountICO) public onlyOwner{
    frozenAccountICO = _frozenAccountICO;   
  }
   
  event FrozenFunds(address target, bool frozen);
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (msg.sender != owner && msg.sender != addressTeam){  
      require(!frozenAccountICO); 
    }
    require(!frozenAccount[_to]);    
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
    if (msg.sender != owner && msg.sender != addressTeam){  
      require(!frozenAccountICO); 
    }    
    require(!frozenAccount[_from]);                      
    require(!frozenAccount[_to]);                        
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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



 
contract MintableToken is StandardToken {
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

contract MahalaCoin is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Mahala Coin";
  string public constant symbol = "MHC";
  uint32 public constant decimals = 18;

   
  uint public summTeam;
  
  function MahalaCoin() public {
    summTeam =     110000000 * 1 ether;
     
    mint(addressTeam, summTeam);
	mint(owner, 70000000 * 1 ether);
  }
       
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}




 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public totalTokens;
   
  uint softcap;
   
  uint hardcap;  
  MahalaCoin public token;
   
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
    token = createTokenContract();
     
    softcap = 5000 * 1 ether; 
    hardcap = 20000 * 1 ether;  	
     
    minQuanValues = 100000000000000000;  
     
    maxQuanValues = 22 * 1 ether;  
     
     
       
    startPreSale = 1523260800; 
       
    endPreSale = startPreSale + 40 * 1 days;
  
     
       
    startIco = endPreSale;
       
    endIco = startIco + 40 * 1 days;   

     
    ratePreSale = 462;
    rateIco = 231; 
    
     
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
  
  function createTokenContract() internal returns (MahalaCoin) {
    return new MahalaCoin();
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
	    endIco = startIco + 40 * 1 days; 
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
    token.transfer(msg.sender, tokens);
    
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
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
    require(_this.balance < softcap && now > endIco);  
    token.transfer(_address, token.balanceOf(_this));
  }   
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    wallet.transfer(_this.balance);
    token.setFrozenAccountICO(false);
  }  
     
     
     
  function freezeAccount(address target, bool freeze) onlyOwner public {
    token.freezeAccount(target, freeze);
  }
     
     
     
  function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    token.mint(target, mintedAmount);
    }  
    
}