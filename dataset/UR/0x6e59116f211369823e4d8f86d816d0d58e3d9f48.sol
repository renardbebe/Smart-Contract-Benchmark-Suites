 

pragma solidity ^0.4.24;
 
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
 
contract MinterStorePool is PausableToken, MintableToken {

  string public constant name = "MinterStorePool";
  string public constant symbol = "MSP";
  uint8 public constant decimals = 18;
}
 
contract MinterStorePoolCrowdsale is Ownable {

using SafeMath for uint;

address public multisigWallet;
uint public startRound;
uint public periodRound;
uint public altCapitalization;
uint public totalCapitalization;

MinterStorePool public token = new MinterStorePool ();

function MinterStorePoolCrowdsale () public {
	multisigWallet = 0xdee04DfdC6C93D51468ba5cd90457Ac0B88055FD;
	startRound = 1534118340;
	periodRound = 80;
	altCapitalization = 0;
	totalCapitalization = 2000 ether;
	}

modifier CrowdsaleIsOn() {
	require(now >= startRound && now <= startRound + periodRound * 1 days);
	_;
	}
modifier TotalCapitalization() {
	require(multisigWallet.balance + altCapitalization <= totalCapitalization);
	_;
	}

function setMultisigWallet (address newMultisigWallet) public onlyOwner {
	require(newMultisigWallet != 0X0);
	multisigWallet = newMultisigWallet;
	}
	
function setStartRound (uint newStartRound) public onlyOwner {
	startRound = newStartRound;
	}
function setPeriodRound (uint newPeriodRound) public onlyOwner {
	periodRound = newPeriodRound;
	} 
function setAltCapitalization (uint newAltCapitalization) public onlyOwner {
	altCapitalization = newAltCapitalization;
	}
function setTotalCapitalization (uint newTotalCapitalization) public onlyOwner {
	totalCapitalization = newTotalCapitalization;
	}
	
function () external payable {
	createTokens (msg.sender, msg.value);
	}

function createTokens (address recipient, uint etherDonat) internal CrowdsaleIsOn TotalCapitalization {
	require(etherDonat > 0);  
	require(recipient != 0X0);
	multisigWallet.transfer(etherDonat);
    uint tokens = 10000000000000;  
	token.mint(recipient, tokens);
	}

function customCreateTokens(address recipient, uint btcDonat) public CrowdsaleIsOn TotalCapitalization onlyOwner {
	require(btcDonat > 0);  
	require(recipient != 0X0);
    uint tokens = btcDonat;
	token.mint(recipient, tokens);
	}

function retrieveTokens (address addressToken, address wallet) public onlyOwner {
	ERC20 alientToken = ERC20 (addressToken);
	alientToken.transfer(wallet, alientToken.balanceOf(this));
	}

function finishMinting () public onlyOwner {
	token.finishMinting();
	}

function setOwnerToken (address newOwnerToken) public onlyOwner {
	require(newOwnerToken != 0X0);
	token.transferOwnership(newOwnerToken); 
	}
}