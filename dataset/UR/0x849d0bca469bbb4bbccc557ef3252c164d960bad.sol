 

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
  mapping (address => bool) public owners;

  event OwnershipAdded(address indexed assigner, address indexed newOwner);
  event OwnershipDeleted(address indexed assigner, address indexed deletedOwner);


   
  function Ownable() public {
    owners[msg.sender] = true;
  }


   
  modifier onlyOwner() {
    require(owners[msg.sender] == true);
    _;
  }
  
  function addOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipAdded(msg.sender, newOwner);
    owners[newOwner] = true;
  }
  
  function removeOwner(address removedOwner) onlyOwner public {
    require(removedOwner != address(0));
    OwnershipDeleted(msg.sender, removedOwner);
    delete owners[removedOwner];
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract NineetToken is PausableToken {
  string constant public name = "Nineet Token";
  string constant public symbol = "NNT";
  uint256 constant public decimals = 18;

  uint256 constant public initialSupply = 85000000 * (10**decimals);  

   
  address public initialWallet;

  function NineetToken(address _initialWallet) public {
    require (_initialWallet != 0x0);

    initialWallet = _initialWallet;

     
    totalSupply = initialSupply;
    balances[initialWallet] = initialSupply;

    addOwner(initialWallet);
  }

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public onlyOwner {
    require(_value > 0);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
}

contract NineetPresale is Pausable {
  using SafeMath for uint256;

   
  NineetToken public token;
  uint256 constant public decimals = 18;
  uint256 constant public BASE = 10**decimals;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public soldTokens;

   
  uint256 constant public soldTokensLimit = 1700000 * BASE;  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function NineetPresale(uint256 _startTime, uint256 _endTime, address _wallet) public {
     
    require(_endTime >= _startTime);
    require(_wallet != 0x0);

    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
    
    token = createTokenContract();
  }

  function createTokenContract() internal returns (NineetToken) {
    return new NineetToken(wallet);
  }
  
  function () public payable whenNotPaused {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 presalePrice = getPrice(weiAmount);
    uint256 tokens = weiAmount.div(presalePrice) * BASE;

     
    uint256 newSoldTokens = soldTokens.add(tokens);
    require(newSoldTokens <= soldTokensLimit);

     
    weiRaised = weiRaised.add(weiAmount);
    soldTokens = newSoldTokens;

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function getPrice(uint256 weiAmount) public pure returns(uint256) {
    if (weiAmount >= 20 * BASE) {  
       
      return 400000000000000;  
    } else if (weiAmount >= 10 * BASE) {  
       
      return 500000000000000;  
    } else {
       
      return 600000000000000;  
    }
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = soldTokens >= soldTokensLimit;
    return (now > endTime) || capReached;
  }

  function getTokensForPresale() public onlyOwner {
    token.transferFrom(wallet, address(this), soldTokensLimit);
  }

   
  function returnTokensToWallet() public onlyOwner {
    require (soldTokens < soldTokensLimit);
    require (now > endTime);

    token.transfer(wallet, soldTokensLimit - soldTokens);
  }

  function grantAccessForToken() public onlyOwner {
    token.addOwner(msg.sender);
  }

}