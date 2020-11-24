 

pragma solidity ^0.4.13;

 

 
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

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal  returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public  returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public  returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public  returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transfer(address _to, uint256 _value) public returns (bool) {
    return BasicToken.transfer(_to, _value);
  }

   
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

   
  function allowance(address _owner, address _spender) public  returns (uint256) {
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

 

 

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
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

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract BlockportToken is CappedToken, PausableToken {

    string public constant name                 = "Blockport Token";
    string public constant symbol               = "BPT";
    uint public constant decimals               = 18;

    function BlockportToken(uint256 _totalSupply) 
        CappedToken(_totalSupply) public {
            paused = true;
    }
}

 

contract Whitelist is Ownable {
    
    mapping(address => bool) allowedAddresses;
    uint count = 0;
    
    modifier whitelisted() {
        require(allowedAddresses[msg.sender] == true);
        _;
    }

    function addToWhitelist(address[] _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            count++;
            WhitelistUpdated(block.timestamp, "Added", _addresses[i], count);
        }        
    }

    function removeFromWhitelist(address[] _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            count--;
            WhitelistUpdated(block.timestamp, "Removed", _addresses[i], count);
        }         
    }
    
    function isWhitelisted() public whitelisted constant returns (bool) {
        return true;
    }

    function addressIsWhitelisted(address _address) public constant returns (bool) {
        return allowedAddresses[_address];
    }

    function getAddressCount() public constant returns (uint) {
        return count;
    }

    event WhitelistUpdated(uint timestamp, string operation, address indexed member, uint totalAddresses);
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal  returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasStarted() public constant returns (bool) {
    return now >= startTime;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
  function currentTime() public constant returns(uint256) { 
    return now;
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal  returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 

 
 
 
 
 
 
 
 
 
 
 
 
 

contract BlockportPresale is CappedCrowdsale, Whitelist, Pausable {

    address public tokenAddress;
    uint256 public minimalInvestmentInWei = 1.7 ether;        

    BlockportToken public bpToken;

    event InitialRateChange(uint256 rate, uint256 cap, uint256 minimalInvestment);

     
     
     
     
     
     
     
     
    function BlockportPresale(uint256 _cap, uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenAddress) 
        CappedCrowdsale(_cap) 
        Crowdsale(_startTime, _endTime, _rate, _wallet) public {
            tokenAddress = _tokenAddress;
            token = createTokenContract();
        }

     
     
     
    function createTokenContract() internal returns (MintableToken) {
        bpToken = BlockportToken(tokenAddress);
        return BlockportToken(tokenAddress);
    }

     
     
    function validPurchase() internal returns (bool) {
        bool minimalInvested = msg.value >= minimalInvestmentInWei;
        bool whitelisted = addressIsWhitelisted(msg.sender);

        return super.validPurchase() && minimalInvested && !paused && whitelisted;
    }

     
     
     
     
    function setRate(uint256 _rateInWei, uint256 _capInWei, uint256 _minimalInvestmentInWei) public onlyOwner returns (bool) { 
        require(startTime >= block.timestamp);  
        require(_rateInWei > 0);
        require(_capInWei > 0);
        require(_minimalInvestmentInWei > 0);

        rate = _rateInWei;
        cap = _capInWei;
        minimalInvestmentInWei = _minimalInvestmentInWei;

        InitialRateChange(rate, cap, minimalInvestmentInWei);
        return true;
    }

     
    function resetTokenOwnership() onlyOwner public { 
        bpToken.transferOwnership(owner);
    }
}