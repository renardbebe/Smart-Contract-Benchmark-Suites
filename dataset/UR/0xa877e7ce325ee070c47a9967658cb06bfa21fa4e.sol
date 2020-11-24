 

pragma solidity ^0.4.15;

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

contract Ownable {

     
    address public owner;

    address public newOwner;

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
    }

     

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
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

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
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


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
     
    require(_endTime >= _startTime);
    require(_rate > 0);
     

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
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

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract LamdenTau is MintableToken {
    string public constant name = "Lamden Tau";
    string public constant symbol = "TAU";
    uint8 public constant decimals = 18;
}

contract Presale is CappedCrowdsale, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) public whitelist;

    bool public isFinalized = false;
    event Finalized();
    
    address public team = 0xabc;
    uint256 public teamShare = 150000000 * (10 ** 18);
    
    address public seed = 0xdef;
    uint256 public seedShare = 1000000 * (10 ** 18);

    bool public hasAllocated = false;

    address public mediator = 0x0;
    
    function Presale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, address _wallet, address _tokenAddress) 
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    CappedCrowdsale(_cap)
    {
        token = LamdenTau(_tokenAddress);
    }
    
     
    function createTokenContract() internal returns (MintableToken) {
        return LamdenTau(0x0);
    }

    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= cap;
        bool valid = super.validPurchase() && withinCap && whitelist[msg.sender];
        return valid;
    }
     
    
     
    
    function finalize() onlyOwner public {
      require(mediator != 0x0);
      require(!isFinalized);
      require(hasEnded());
      
      finalization();
      Finalized();

      isFinalized = true;
    }
    
    function finalization() internal {
         
         
        token.transferOwnership(mediator);
        Mediator m = Mediator(mediator);
        m.acceptToken();
    }
     

     
    function assignMediator(address _m) public onlyOwner returns(bool) {
        mediator = _m;
        return true;
    }
    
    function whitelistUser(address _a) public onlyOwner returns(bool){
        whitelist[_a] = true;
        return whitelist[_a];
    }

    function whitelistUsers(address[] users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
    }

    function unWhitelistUser(address _a) public onlyOwner returns(bool){
        whitelist[_a] = false;
        return whitelist[_a];
    }

    function unWhitelistUsers(address[] users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = false;
        }
    }
    
    function allocateTokens() public onlyOwner returns(bool) {
        require(hasAllocated == false);
        token.mint(team, teamShare);
        token.mint(seed, seedShare);
        hasAllocated = true;
        return hasAllocated;
    }
    
    function acceptToken() public onlyOwner returns(bool) {
        token.acceptOwnership();
        return true;
    }

    function changeEndTime(uint256 _e) public onlyOwner returns(uint256) {
        require(_e > startTime);
        endTime = _e;
        return endTime;
    }

    function mintTokens(uint256 tokenAmount) public onlyOwner {
       require(!isFinalized);
       token.mint(wallet, tokenAmount);
    }
    
     
}

contract Mediator is Ownable {
    address public presale;
    LamdenTau public tau;
    address public sale;
    
    function setPresale(address p) public onlyOwner { presale = p; }
    function setTau(address t) public onlyOwner { tau = LamdenTau(t); }
    function setSale(address s) public onlyOwner { sale = s; }
    
    modifier onlyPresale {
        require(msg.sender == presale);
        _;
    }
    
    modifier onlySale {
        require(msg.sender == sale);
        _;
    }
    
    function acceptToken() public onlyPresale { tau.acceptOwnership(); }
    function passOff() public onlySale { tau.transferOwnership(sale); }
}

contract Sale is CappedCrowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;
    event Finalized();

     
    function Sale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, address _wallet, address _tokenAddress)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    CappedCrowdsale(_cap)
    {
        token = LamdenTau(_tokenAddress);
    }
     
    
     
    function createTokenContract() internal returns (MintableToken) {
        return LamdenTau(0x0);
    }
    
    function validPurchase() internal constant returns (bool) {
        super.validPurchase();
    }

    function buyTokens(address beneficiary) public payable {
        super.buyTokens(beneficiary);
    }
     

     
    function finalize() onlyOwner public {
      require(!isFinalized);
      require(hasEnded());

      finalization();
      Finalized();

      isFinalized = true;
    }
    
    function finalization() internal {
        token.finishMinting();
    }
    
    function claimToken(address _m) public onlyOwner returns(bool) {
        Mediator m = Mediator(_m);
        m.passOff();
        token.acceptOwnership();
        return true;
    }

    function changeEndTime(uint256 _e) public onlyOwner returns(uint256) {
        require(_e > startTime);
        endTime = _e;
        return endTime;
    }

    function mintTokens(uint256 tokenAmount) public onlyOwner {
       require(!isFinalized);
       token.mint(wallet, tokenAmount);
    }
     
}