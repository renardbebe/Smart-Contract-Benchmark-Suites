 

 
 
 pragma solidity ^0.4.11;

 


 


 
library SafeMath {
  function mul(uint256 a, uint256 b)  constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b)  constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b)  constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b)  constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 


 
contract StandardToken {

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  uint256 public totalSupply;

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event Pause();
  event Unpause();

  bool public paused = false;

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;


   
  function StandardToken() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function transfer(address _to, uint256 _value)  public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value)  public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value)  public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
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
 

contract CoinsOpenToken is StandardToken
{


   
  string public constant name = "COT";
  string public constant symbol = "COT";
  uint8 public constant decimals = 18;

  uint public totalSupply = 23000000000000000000000000;
  uint256 public presaleSupply = 2000000000000000000000000;
  uint256 public saleSupply = 13000000000000000000000000;
  uint256 public reserveSupply = 8000000000000000000000000;

  uint256 public saleStartTime = 1511136000;  
  uint256 public saleEndTime = 1513728000;  
  uint256 public preSaleStartTime = 1508457600;  
  uint256 public developerLock = 1500508800;

  uint256 public totalWeiRaised = 0;

  uint256 public preSaleTokenPrice = 1400;
  uint256 public saleTokenPrice = 700;

  mapping (address => uint256) lastDividend;
  mapping (uint256 =>uint256) dividendList;
  uint256 currentDividend = 0;
  uint256 dividendAmount = 0;

  struct BuyOrder {
      uint256 wether;
      address receiver;
      address payer;
      bool presale;
  }

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, bool presale);

   
  event DividendAvailable(uint amount);

   
  event SendDividend(address indexed receiver, uint amountofether);

  function() payable {
    if (msg.sender == owner) {
      giveDividend();
    } else {
      buyTokens(msg.sender);
    }
  }

  function endSale() whenNotPaused {
    require (!isInSale());
    require (saleSupply != 0);
    reserveSupply = reserveSupply.add(saleSupply);
  }

   
  function buyTokens(address _receiver) payable whenNotPaused {
    require (msg.value != 0);
    require (_receiver != 0x0);
    require (isInSale());
    bool isPresale = isInPresale();
    if (!isPresale) {
      checkPresale();
    }
    uint256 tokenPrice = saleTokenPrice;
    if (isPresale) {
      tokenPrice = preSaleTokenPrice;
    }
    uint256 tokens = (msg.value).mul(tokenPrice);
    if (isPresale) {
      if (presaleSupply < tokens) {
        msg.sender.transfer(msg.value);
        return;
      }
    } else {
      if (saleSupply < tokens) {
        msg.sender.transfer(msg.value);
        return;
      }
    }
    checkDividend(_receiver);
    TokenPurchase(msg.sender, _receiver, msg.value, tokens, isPresale);
    totalWeiRaised = totalWeiRaised.add(msg.value);
    Transfer(0x0, _receiver, tokens);
    balances[_receiver] = balances[_receiver].add(tokens);
    if (isPresale) {
      presaleSupply = presaleSupply.sub(tokens);
    } else {
      saleSupply = saleSupply.sub(tokens);
    }
  }

   
  function giveDividend() payable whenNotPaused {
    require (msg.value != 0);
    dividendAmount = dividendAmount.add(msg.value);
    dividendList[currentDividend] = (msg.value).mul(10000000000).div(totalSupply);
    currentDividend = currentDividend.add(1);
    DividendAvailable(msg.value);
  }

   
  function checkDividend(address _account) whenNotPaused {
    if (lastDividend[_account] != currentDividend) {
      if (balanceOf(_account) != 0) {
        uint256 toSend = 0;
        for (uint i = lastDividend[_account]; i < currentDividend; i++) {
          toSend += balanceOf(_account).mul(dividendList[i]).div(10000000000);
        }
        if (toSend > 0 && toSend <= dividendAmount) {
          _account.transfer(toSend);
          dividendAmount = dividendAmount.sub(toSend);
          SendDividend(_account, toSend);
        }
      }
      lastDividend[_account] = currentDividend;
    }
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    checkDividend(msg.sender);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    checkDividend(_from);
    return super.transferFrom(_from, _to, _value);
  }

   
  function isInPresale() constant returns (bool) {
    return saleStartTime > now;
  }

   
  function isInSale() constant returns (bool) {
    return saleEndTime >= now && preSaleStartTime <= now;
  }

   
  function checkPresale() internal {
    if (!isInPresale() && presaleSupply > 0) {
      saleSupply = saleSupply.add(presaleSupply);
      presaleSupply = 0;
    }
  }

   
  function distributeReserveSupply(uint256 _amount, address _receiver) onlyOwner whenNotPaused {
    require (_amount <= reserveSupply);
    require (now >= developerLock);
    checkDividend(_receiver);
    balances[_receiver] = balances[_receiver].add(_amount);
    reserveSupply.sub(_amount);
    Transfer(0x0, _receiver, _amount);
  }

   
  function withdraw(uint _amount) onlyOwner {
    require (_amount != 0);
    require (_amount < this.balance);
    (msg.sender).transfer(_amount);
  }

   
  function withdrawEverything() onlyOwner {
    (msg.sender).transfer(this.balance);
  }

}