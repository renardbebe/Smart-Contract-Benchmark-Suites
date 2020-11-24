 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
   
  mapping(address => uint8) permissionsList;
  
  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
    permissionsList[_address] = _sign; 
  }
  function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
    return permissionsList[_address]; 
  }  
  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(permissionsList[msg.sender] == 0);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(permissionsList[msg.sender] == 0);
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
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
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
contract BurnableByOwner is BasicToken {

  event Burn(address indexed burner, uint256 value);
  function burn(address _address, uint256 _value) public onlyOwner{
    require(_value <= balances[_address]);
     
     

    address burner = _address;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract TRND is Ownable, MintableToken, BurnableByOwner {
  using SafeMath for uint256;    
  string public constant name = "Trends";
  string public constant symbol = "TRND";
  uint32 public constant decimals = 18;
  
  address public addressPrivateSale;
  address public addressAirdrop;
  address public addressFoundersShare;
  address public addressPartnershipsAndExchanges;

  uint256 public summPrivateSale;
  uint256 public summAirdrop;
  uint256 public summFoundersShare;
  uint256 public summPartnershipsAndExchanges;
  

  function TRND() public {
    addressPrivateSale   = 0xAfB042EE51FE904F67935222744628e1Ce3F6584;
    addressFoundersShare = 0x6E3F6b1cB72B4C315d0Ae719aACbE8436638b134;
    addressPartnershipsAndExchanges  = 0xedc57Ed34370139E9f8144C7cf3D0374fa1f0eCf; 
    addressAirdrop       = 0xA1f99816B7DD6913bF8BDe68d71A1a3a6A47513B;
	
    summPrivateSale   = 5000000 * (10 ** uint256(decimals)); 
    summFoundersShare = 5000000 * (10 ** uint256(decimals));  
    summPartnershipsAndExchanges  = 7500000 * (10 ** uint256(decimals));  		    
    summAirdrop       = 2500000 * (10 ** uint256(decimals));  
     
    mint(addressPrivateSale, summPrivateSale);
    mint(addressAirdrop, summAirdrop);
    mint(addressFoundersShare, summFoundersShare);
    mint(addressPartnershipsAndExchanges, summPartnershipsAndExchanges);
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 softcap;
   
  uint256 hardcapPreICO; 
  uint256 hardcapMainSale;  
  TRND public token;
   
  mapping(address => uint) public balances;

   
   
  uint256 public startIcoPreICO;  
  uint256 public startIcoPreICO2ndRound;  
  uint256 public startIcoMainSale;  
   
  uint256 public endIcoPreICO; 
  uint256 public endIcoMainSale;   

   
  uint256 public totalSoldTokens;
  uint256 public minPurchasePreICO;     
  
   
  uint256 public rateIcoPreICO;
  uint256 public rateIcoMainSale;

   
  uint256 public unconfirmedSum;
  mapping(address => uint) public unconfirmedSumAddr;

   
  address public wallet;
  
  bool isTesting;
  
 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
     
    token = createTokenContract();
     
    softcap            = 20000000 * 1 ether; 
    hardcapPreICO      =  5000000 * 1 ether; 
    hardcapMainSale    = 75000000 * 1 ether; 
	
     
    minPurchasePreICO      = 100000000000000000;
    
     
    startIcoPreICO   = 1530435600;         
    startIcoPreICO2ndRound = 1531731600;   
    endIcoPreICO     = 1533027600;         
    startIcoMainSale = 1534323600;         
    endIcoMainSale   = 1538557200;         

     
    rateIcoPreICO = 2933;
     
    rateIcoMainSale = 2200;

     
    wallet = 0xca5EdAE100d4D262DC3Ec2dE96FD9943Ea659d04;
  }


 
  function contractBalanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

 
  function tokenBalanceOf(address _owner) public view returns (uint256) {
    return token.balanceOf(_owner);
  }

  function setStartIcoPreICO(uint256 _startIcoPreICO) public onlyOwner  { 
     
    require(_startIcoPreICO < endIcoPreICO);
     
    require(now < startIcoPreICO);  
	  startIcoPreICO   = _startIcoPreICO;
  }

  function setStartIcoPreICO2ndRound(uint256 _startIcoPreICO2ndRound) public onlyOwner  { 
     
    require(_startIcoPreICO2ndRound > startIcoPreICO && _startIcoPreICO2ndRound < endIcoPreICO);
     
    require(now < startIcoPreICO);
	  startIcoPreICO2ndRound   = _startIcoPreICO2ndRound;
  }

  function setEndIcoPreICO(uint256 _endIcoPreICO) public onlyOwner  {     
	 
    require(startIcoPreICO < _endIcoPreICO && _endIcoPreICO < startIcoMainSale);
     
    require(now < startIcoPreICO);
	  endIcoPreICO   = _endIcoPreICO;
  }
  
  function setStartIcoMainICO(uint256 _startIcoMainSale) public onlyOwner  { 
     
    require(endIcoPreICO < _startIcoMainSale && _startIcoMainSale < endIcoMainSale);
     
    require(now < startIcoPreICO);
	  startIcoMainSale   = _startIcoMainSale;
  }
  
  function setEndIcoMainICO(uint256 _endIcoMainSale) public onlyOwner  { 
     
    require(startIcoMainSale < _endIcoMainSale);
     
    require(now < startIcoPreICO);
	  endIcoMainSale   = _endIcoMainSale;
  }
  
   
  function setIcoDates(
                  uint256 _startIcoPreICO,
                  uint256 _startIcoPreICO2ndRound,
                  uint256 _endIcoPreICO,
                  uint256 _startIcoMainSale,
                  uint256 _endIcoMainSale
    ) public onlyOwner  { 
     
    require(_startIcoPreICO < _startIcoPreICO2ndRound);
    require(_startIcoPreICO2ndRound < _endIcoPreICO);
    require(_endIcoPreICO <= _startIcoMainSale);
    require(_startIcoMainSale < _endIcoMainSale);
     
    require(now < startIcoPreICO); 

	  startIcoPreICO   = _startIcoPreICO;
	  startIcoPreICO2ndRound = _startIcoPreICO2ndRound;
    endIcoPreICO = _endIcoPreICO;
    startIcoMainSale = _startIcoMainSale;
	  endIcoMainSale = _endIcoMainSale;
  }
  function setRateIcoPreICO(uint256 _rateIcoPreICO) public onlyOwner  {
    rateIcoPreICO = _rateIcoPreICO;
  }   
  
  function setRateIcoMainSale(uint _rateIcoMainSale) public onlyOwner  {
    rateIcoMainSale = _rateIcoMainSale;
  }
       
   
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (TRND) {
    return new TRND();
  }
  
  function getRateIcoWithBonus() public view returns (uint256) {
    return getRateIcoWithBonusByDate(now);
  }    

   
  function getRateIcoWithBonusByDate(uint256 _date) public view returns (uint256) {
    uint256 bonus;
	  uint256 rateICO;
     
    if (_date >= startIcoPreICO && _date < endIcoPreICO){
      rateICO = rateIcoPreICO;
    }  

     
    if (_date >= startIcoMainSale  && _date < endIcoMainSale){
      rateICO = rateIcoMainSale;
    }  

     
     
     
    if (_date >= startIcoPreICO && _date < startIcoPreICO2ndRound){
      bonus = 300;  
    } else if (_date >= startIcoPreICO2ndRound && _date < endIcoPreICO){
      bonus = 200;  
    } else if (_date >= startIcoMainSale) {
       
      uint256 daysSinceMainIcoStarted = (_date - startIcoMainSale) / 86400;
      bonus = 100 - (2 * daysSinceMainIcoStarted);  
      if (bonus < 0) {  
        bonus = 0;
      }
    }

    return rateICO + rateICO.mul(bonus).div(1000);
  }    

   
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    uint256 rate;
    uint hardCap;
    require(beneficiary != address(0));
    rate = getRateIcoWithBonus();
     
    hardCap = hardcapPreICO;
    if (now >= startIcoPreICO && now < endIcoPreICO && totalSoldTokens < hardCap){
	    require(weiAmount >= minPurchasePreICO);
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalSoldTokens) < tokens){
        tokens = hardCap.sub(totalSoldTokens); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
    }  
     
    hardCap = hardcapMainSale.add(hardcapPreICO);
    if (now >= startIcoMainSale  && now < endIcoMainSale  && totalSoldTokens < hardCap){
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalSoldTokens) < tokens){
        tokens = hardCap.sub(totalSoldTokens); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
    }         
    require(tokens > 0);
    totalSoldTokens = totalSoldTokens.add(tokens);
    balances[msg.sender] = balances[msg.sender].add(weiAmount);
    token.mint(msg.sender, tokens);
	  unconfirmedSum = unconfirmedSum.add(tokens);
	  unconfirmedSumAddr[msg.sender] = unconfirmedSumAddr[msg.sender].add(tokens);
	  token.SetPermissionsList(beneficiary, 1);
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

  function refund() public{
    require(totalSoldTokens.sub(unconfirmedSum) < softcap && now > endIcoMainSale);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
     
    require(now < startIcoMainSale || (totalSoldTokens.sub(unconfirmedSum) >= softcap && now > endIcoMainSale));  
    wallet.transfer(_this.balance);
  } 
  
  function refundUnconfirmed() public{
     
    require(now > endIcoMainSale + 24*60*60);
    require(balances[msg.sender] > 0);
    require(token.GetPermissionsList(msg.sender) == 1);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
    
    uint uvalue = unconfirmedSumAddr[msg.sender];
    unconfirmedSumAddr[msg.sender] = 0;
    token.burn(msg.sender, uvalue );
    
  } 
  
  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
      uint8 sign;
      sign = token.GetPermissionsList(_address);
      token.SetPermissionsList(_address, _sign);
      if (_sign == 0){
          if (sign != _sign){  
			      unconfirmedSum = unconfirmedSum.sub(unconfirmedSumAddr[_address]);
			      unconfirmedSumAddr[_address] = 0;
          }
      }
   }
   
   function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
     return token.GetPermissionsList(_address); 
   }   
   
   function pause() onlyOwner public {
     token.pause();
   }

   function unpause() onlyOwner public {
     token.unpause();
   }
    
}