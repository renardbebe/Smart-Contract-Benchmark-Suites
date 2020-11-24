 

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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


 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public cap;

   
  uint256 public openingTime;
  uint256 public closingTime;

  mapping (address => uint256) public contributorList;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_cap > 0);
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);
    
    rate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    openingTime = _openingTime;
    closingTime = _closingTime;  
    
    }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

     
    uint256 weiAmount;

    weiAmount = (weiRaised.add(msg.value) <= cap) ? (msg.value) : (cap.sub(weiRaised));

    _preValidatePurchase(_beneficiary, weiAmount);

    _setContributor(_beneficiary, weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

     
    if(weiAmount < msg.value){
        _beneficiary.transfer(msg.value.sub(weiAmount));
    }
    _forwardFundsWei(weiAmount);

  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(weiRaised.add(_weiAmount) <= cap);

  }

  function _setContributor(address _beneficiary, uint256 _tokenAmount) internal onlyWhileOpen {

     
    uint pibToken = _tokenAmount.mul(rate).div(10 ** 16).mul(10 ** 16);
 
  
     contributorList[_beneficiary] += pibToken;

  }

   
  function _forwardFundsWei(uint256 txAmount) internal {

    wallet.transfer(txAmount);

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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 

 
contract PibbleMain is Crowdsale, Ownable {

  uint256 public minValue;
 
  
  bool public paused = false;


  event Pause();
  event Unpause();

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

 
  function PibbleMain(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _wallet, uint256 _cap, MintableToken _token, uint256 _minValue) public
    Crowdsale(_rate, _wallet, _token, _cap, _openingTime, _closingTime)
    {
        require(_minValue >= 0);
        minValue =_minValue;
 
    }


   
  function transferTokenOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    MintableToken(token).transferOwnership(newOwner);
  }

  function buyTokens(address _beneficiary) public payable whenNotPaused {

    require( minValue <= msg.value );
 
 
    super.buyTokens(_beneficiary);
    
  }

 

  function _forwardFundsWei(uint256 txAmount) internal whenNotPaused {
    super._forwardFundsWei(txAmount);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal whenNotPaused {
 
 

  }

  function _setContributor(address _beneficiary, uint256 _tokenAmount) internal whenNotPaused {

    super._setContributor(_beneficiary,_tokenAmount);

  }

  function mintContributors(address[] contributors) public onlyOwner {

    address contributor ;
    uint tokenCount = 0;

    for (uint i = 0; i < contributors.length; i++) {
        contributor = contributors[i];
        tokenCount = contributorList[contributor];
        
         
        
        MintableToken(token).mint(contributor, tokenCount);
       
        
       delete contributorList[contributor];
    }      
      
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }

  function saleEnded() public view returns (bool) {
    return (weiRaised >= cap || now > closingTime);
  }
 
  function saleStatus() public view returns (uint, uint) {
    return (cap, weiRaised);
  } 
  
}