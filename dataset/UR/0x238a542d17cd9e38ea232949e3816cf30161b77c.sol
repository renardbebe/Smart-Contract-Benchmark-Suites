 

pragma solidity ^0.4.18;
 
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
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
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


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
  
   
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
 
contract CryptoTradeCoin is PausableToken, MintableToken {

  string public constant name = "CryptoTradeCoin";
  string public constant symbol = "CTC";
  uint8 public constant decimals = 18;
}
 
contract CryptoTradeCrowdsale is Ownable {

using SafeMath for uint;

address public multisigWallet;
address public founderTokenWallet;
address public bountyTokenWallet;
uint public founderPercent;
uint public bountyPercent;
uint public startRound;
uint public periodRound;
uint public capitalization;
uint public altCapitalization;
uint public totalCapitalization;
uint public price;
uint public discountTime;
bool public isDiscountValue;
uint public targetDiscountValue1;
uint public targetDiscountValue2;
uint public targetDiscountValue3;
uint public targetDiscountValue4;
uint public targetDiscountValue5;
uint public targetDiscountValue6;
uint public targetDiscountValue7;
uint public targetDiscountValue8;
uint public targetDiscountValue9;
uint public targetDiscountValue10;

CryptoTradeCoin public token = new CryptoTradeCoin ();

function CryptoTradeCrowdsale () public {
	multisigWallet = 0xdee04DfdC6C93D51468ba5cd90457Ac0B88055FD;
	founderTokenWallet = 0x874297a0eDaB173CFdDeD1e890842A5564191D36;
	bountyTokenWallet = 0x77C99A76B3dF279a73396fE9ae0A072B428b63Fe;
	founderPercent = 10;
	bountyPercent = 5;
	startRound = 1509584400;
	periodRound = 90;
	capitalization = 3300 ether;
	altCapitalization = 0;
	totalCapitalization = 200000 ether;
	price = 1000000000000000000000000; 
	discountTime = 50;
	isDiscountValue = false;
	targetDiscountValue1 = 2    ether;
	targetDiscountValue2 = 4    ether;
	targetDiscountValue3 = 8    ether;
	targetDiscountValue4 = 16   ether;
	targetDiscountValue5 = 32   ether;
	targetDiscountValue6 = 64   ether;
	targetDiscountValue7 = 128  ether;
	targetDiscountValue8 = 256  ether;
	targetDiscountValue9 = 512  ether;
	targetDiscountValue10= 1024 ether;
	}

modifier CrowdsaleIsOn() {
	require(now >= startRound && now <= startRound + periodRound * 1 days);
	_;
	}
modifier TotalCapitalization() {
	require(multisigWallet.balance + altCapitalization <= totalCapitalization);
	_;
	}
modifier RoundCapitalization() {
	require(multisigWallet.balance + altCapitalization <= capitalization);
	_;
	}

function setMultisigWallet (address newMultisigWallet) public onlyOwner {
	require(newMultisigWallet != 0X0);
	multisigWallet = newMultisigWallet;
	}
function setFounderTokenWallet (address newFounderTokenWallet) public onlyOwner {
	require(newFounderTokenWallet != 0X0);
	founderTokenWallet = newFounderTokenWallet;
	}
function setBountyTokenWallet (address newBountyTokenWallet) public onlyOwner {
	require(newBountyTokenWallet != 0X0);
	bountyTokenWallet = newBountyTokenWallet;
	}
	
function setFounderPercent (uint newFounderPercent) public onlyOwner {
	founderPercent = newFounderPercent;
	}
function setBountyPercent (uint newBountyPercent) public onlyOwner {
	bountyPercent = newBountyPercent;
	}
	
function setStartRound (uint newStartRound) public onlyOwner {
	startRound = newStartRound;
	}
function setPeriodRound (uint newPeriodRound) public onlyOwner {
	periodRound = newPeriodRound;
	} 
	
function setCapitalization (uint newCapitalization) public onlyOwner {
	capitalization = newCapitalization;
	}
function setAltCapitalization (uint newAltCapitalization) public onlyOwner {
	altCapitalization = newAltCapitalization;
	}
function setTotalCapitalization (uint newTotalCapitalization) public onlyOwner {
	totalCapitalization = newTotalCapitalization;
	}
	
function setPrice (uint newPrice) public onlyOwner {
	price = newPrice;
	}
function setDiscountTime (uint newDiscountTime) public onlyOwner {
	discountTime = newDiscountTime;
	}
	
function setDiscountValueOn () public onlyOwner {
	require(!isDiscountValue);
	isDiscountValue = true;
	}
function setDiscountValueOff () public onlyOwner {
	require(isDiscountValue);
	isDiscountValue = false;
	}
	
function setTargetDiscountValue1  (uint newTargetDiscountValue1)  public onlyOwner {
	require(newTargetDiscountValue1 > 0);
	targetDiscountValue1 = newTargetDiscountValue1;
	}
function setTargetDiscountValue2  (uint newTargetDiscountValue2)  public onlyOwner {
	require(newTargetDiscountValue2 > 0);
	targetDiscountValue2 = newTargetDiscountValue2;
	}
function setTargetDiscountValue3  (uint newTargetDiscountValue3)  public onlyOwner {
	require(newTargetDiscountValue3 > 0);
	targetDiscountValue3 = newTargetDiscountValue3;
	}
function setTargetDiscountValue4  (uint newTargetDiscountValue4)  public onlyOwner {
	require(newTargetDiscountValue4 > 0);
	targetDiscountValue4 = newTargetDiscountValue4;
	}
function setTargetDiscountValue5  (uint newTargetDiscountValue5)  public onlyOwner {
	require(newTargetDiscountValue5 > 0);
	targetDiscountValue5 = newTargetDiscountValue5;
	}
function setTargetDiscountValue6  (uint newTargetDiscountValue6)  public onlyOwner {
	require(newTargetDiscountValue6 > 0);
	targetDiscountValue6 = newTargetDiscountValue6;
	}
function setTargetDiscountValue7  (uint newTargetDiscountValue7)  public onlyOwner {
	require(newTargetDiscountValue7 > 0);
	targetDiscountValue7 = newTargetDiscountValue7;
	}
function setTargetDiscountValue8  (uint newTargetDiscountValue8)  public onlyOwner {
	require(newTargetDiscountValue8 > 0);
	targetDiscountValue8 = newTargetDiscountValue8;
	}
function setTargetDiscountValue9  (uint newTargetDiscountValue9)  public onlyOwner {
	require(newTargetDiscountValue9 > 0);
	targetDiscountValue9 = newTargetDiscountValue9;
	}
function setTargetDiscountValue10 (uint newTargetDiscountValue10) public onlyOwner {
	require(newTargetDiscountValue10 > 0);
	targetDiscountValue10 = newTargetDiscountValue10;
	}
	
function () external payable {
	createTokens (msg.sender, msg.value);
	}

function createTokens (address recipient, uint etherDonat) internal CrowdsaleIsOn RoundCapitalization TotalCapitalization {
	require(etherDonat > 0);  
	require(recipient != 0X0);
	require(price > 0);
	multisigWallet.transfer(etherDonat);
	uint discountValue = discountValueSolution (etherDonat);
	uint bonusDiscountValue = (etherDonat.mul(price).div(1 ether)).mul(discountValue).div(100);
	uint bonusDiscountTime  = (etherDonat.mul(price).div(1 ether)).mul(discountTime).div(100);
    uint tokens = (etherDonat.mul(price).div(1 ether)).add(bonusDiscountTime).add(bonusDiscountValue);
	token.mint(recipient, tokens);
	}

function customCreateTokens(address recipient, uint etherDonat) public CrowdsaleIsOn RoundCapitalization TotalCapitalization onlyOwner {
	require(etherDonat > 0);  
	require(recipient != 0X0);
	require(price > 0);
	uint discountValue = discountValueSolution (etherDonat);
	uint bonusDiscountValue = (etherDonat.mul(price).div(1 ether)).mul(discountValue).div(100);
	uint bonusDiscountTime  = (etherDonat.mul(price).div(1 ether)).mul(discountTime).div(100);
    uint tokens = (etherDonat.mul(price).div(1 ether)).add(bonusDiscountTime).add(bonusDiscountValue);
	token.mint(recipient, tokens);
	altCapitalization += etherDonat;
	}

function retrieveTokens (address addressToken, address wallet) public onlyOwner {
	ERC20 alientToken = ERC20 (addressToken);
	alientToken.transfer(wallet, alientToken.balanceOf(this));
	}

function finishMinting () public onlyOwner {
	uint issuedTokenSupply = token.totalSupply(); 
	uint tokensFounders = issuedTokenSupply.mul(founderPercent).div(100);
	uint tokensBounty = issuedTokenSupply.mul(bountyPercent).div(100);
	token.mint(founderTokenWallet, tokensFounders);
	token.mint(bountyTokenWallet, tokensBounty);
	token.finishMinting();
	}

function setOwnerToken (address newOwnerToken) public onlyOwner {
	require(newOwnerToken != 0X0);
	token.transferOwnership(newOwnerToken); 
	}

function coefficientSolution (uint _donat) internal constant returns (uint) {  
	require(isDiscountValue);
 	uint _discountValue;
	if (_donat < targetDiscountValue1) { 
		return _discountValue = 0;
	} else if (_donat >= targetDiscountValue1 && _donat < targetDiscountValue2) { 
		return _discountValue = 2;
	} else if (_donat >= targetDiscountValue2 && _donat < targetDiscountValue3) { 
		return _discountValue = 4;
	} else if (_donat >= targetDiscountValue3 && _donat < targetDiscountValue4) { 
		return _discountValue = 6;
	} else if (_donat >= targetDiscountValue4 && _donat < targetDiscountValue5) { 
		return _discountValue = 8;
	} else if (_donat >= targetDiscountValue5 && _donat < targetDiscountValue6) { 
		return _discountValue = 10;
	} else if (_donat >= targetDiscountValue6 && _donat < targetDiscountValue7) { 
		return _discountValue = 12;
	} else if (_donat >= targetDiscountValue7 && _donat < targetDiscountValue8) { 
		return _discountValue = 14;
	} else if (_donat >= targetDiscountValue8 && _donat < targetDiscountValue9) { 
		return _discountValue = 16;
	} else if (_donat >= targetDiscountValue9 && _donat < targetDiscountValue10){ 
		return _discountValue = 18;
	} else {   
		return _discountValue = 20;
	}
   }

function discountValueSolution (uint Donat) internal constant returns (uint) {
	uint DiscountValue;
	if (!isDiscountValue) {
		DiscountValue = 0;
		return DiscountValue;
	} else {
		DiscountValue = coefficientSolution (Donat);
		return DiscountValue;
	}
   }

}