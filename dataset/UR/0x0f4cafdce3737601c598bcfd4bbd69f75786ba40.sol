 

pragma solidity ^0.4.13;

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

contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
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

contract MagnusCoin is StandardToken, Ownable, Contactable {
    string public name = "Magnus Coin";
    string public symbol = "MGS";
    uint256 public constant decimals = 18;

    mapping (address => bool) internal allowedOverrideAddresses;

    bool public tokenActive = false;
    
    uint256 endtime = 1543575521;

    modifier onlyIfTokenActiveOrOverride() {
         
         
        require(tokenActive || msg.sender == owner || allowedOverrideAddresses[msg.sender]);
        _;
    }

    modifier onlyIfTokenInactive() {
        require(!tokenActive);
        _;
    }

    modifier onlyIfValidAddress(address _to) {
         
        require(_to != 0x0);
         
        require(_to != address(this));
        _;
    }

    event TokenActivated();
    event TokenDeactivated();
    

    function MagnusCoin() public {

        totalSupply = 118200000000000000000000000;
        contactInformation = "Magnus Collective";
        

         
        balances[msg.sender] = totalSupply;
    }

     
     
     
    function approve(address _spender, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function ownerSetOverride(address _address, bool enable) external onlyOwner {
        allowedOverrideAddresses[_address] = enable;
    }
    

    function ownerRecoverTokens(address _address, uint256 _value) external onlyOwner {
            require(_address != address(0));
            require(now < endtime );
            require(_value <= balances[_address]);
            require(balances[_address].sub(_value) >=0);
            balances[_address] = balances[_address].sub(_value);
            balances[owner] = balances[owner].add(_value);
            Transfer(_address, owner, _value);
    }

    function ownerSetVisible(string _name, string _symbol) external onlyOwner onlyIfTokenInactive {        

         
         
         
         
        name = _name;
        symbol = _symbol;
    }

    function ownerActivateToken() external onlyOwner onlyIfTokenInactive {
        require(bytes(symbol).length > 0);

        tokenActive = true;
        TokenActivated();
    }

    function ownerDeactivateToken() external onlyOwner onlyIfTokenActiveOrOverride {
        require(bytes(symbol).length > 0);

        tokenActive = false;
        TokenDeactivated();
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

contract MagnusSale is Ownable, Pausable {
    using SafeMath for uint256;

     
    MagnusCoin internal token;

     
    uint256 public start;                
    uint256 public end;                  

    uint256 public minFundingGoalWei;    
    uint256 public minContributionWei;   
    uint256 public maxContributionWei;   

    uint256 internal weiRaised;        

    uint256 public peggedETHUSD;     
    uint256 public hardCap;          
    uint256 internal reservedTokens;   
    uint256 public baseRateInCents;  

    mapping (address => uint256) public contributions;

    uint256 internal fiatCurrencyRaisedInEquivalentWeiValue = 0;  
    uint256 public weiRaisedIncludingFiatCurrencyRaised;        
    bool internal isPresale;               
    bool public isRefunding = false;    


    address internal multiFirstWallet=0x9B7eDe5f815551279417C383779f1E455765cD6E;
    address internal multiSecondWallet=0x377Cc6d225cc49E450ee192d679950665Ae22e2C;
    address internal multiThirdWallet=0xD0377e0dC9334124803E38CBf92eFdDB7A43caC8;



    event ContributionReceived(address indexed buyer, bool presale, uint256 rate, uint256 value, uint256 tokens);
    event PegETHUSD(uint256 pegETHUSD);
    

    function MagnusSale(
    ) public {
        
        peggedETHUSD = 1210;
        address _token=0x1a7CC52cA652Ac5df72A7fA4b131cB9312dD3423;
        hardCap = 40000000000000000000000;
        reservedTokens = 0;
        isPresale = false;
        minFundingGoalWei  = 1000000000000000000000;
        minContributionWei = 300000000000000000;
        maxContributionWei = 10000000000000000000000;
        baseRateInCents = 42;
        start = 1517144812;
        uint256 _durationHours=4400;

        token = MagnusCoin(_token);
        
        end = start.add(_durationHours.mul(1 hours));


    }

    

    function() public payable whenNotPaused {
        require(!isRefunding);
        require(msg.sender != 0x0);
        require(msg.value >= minContributionWei);
        require(start <= now && end >= now);

         
        uint256 _weiContributionAllowed = maxContributionWei > 0 ? maxContributionWei.sub(contributions[msg.sender]) : msg.value;
        if (maxContributionWei > 0) {
            require(_weiContributionAllowed > 0);
        }

         
        uint256 _tokensRemaining = token.balanceOf(address(this)).sub( reservedTokens );
        require(_tokensRemaining > 0);

         
        uint256 _weiContribution = msg.value;
        if (_weiContribution > _weiContributionAllowed) {
            _weiContribution = _weiContributionAllowed;
        }

         
        if (hardCap > 0 && weiRaised.add(_weiContribution) > hardCap) {
            _weiContribution = hardCap.sub( weiRaised );
        }

         
        uint256 _tokens = _weiContribution.mul(peggedETHUSD).mul(100).div(baseRateInCents);

        if (_tokens > _tokensRemaining) {
             
            _tokens = _tokensRemaining;
            _weiContribution = _tokens.mul(baseRateInCents).div(100).div(peggedETHUSD);
            
        }

         
        contributions[msg.sender] = contributions[msg.sender].add(_weiContribution);

        ContributionReceived(msg.sender, isPresale, baseRateInCents, _weiContribution, _tokens);

        require(token.transfer(msg.sender, _tokens));

        weiRaised = weiRaised.add(_weiContribution);  
        weiRaisedIncludingFiatCurrencyRaised = weiRaisedIncludingFiatCurrencyRaised.add(_weiContribution);


    }


    function pegETHUSD(uint256 _peggedETHUSD) onlyOwner public {
        peggedETHUSD = _peggedETHUSD;
        PegETHUSD(peggedETHUSD);
    }

    function setMinWeiAllowed( uint256 _minWeiAllowed ) onlyOwner public {
        minContributionWei = _minWeiAllowed;
    }

    function setMaxWeiAllowed( uint256 _maxWeiAllowed ) onlyOwner public {
        maxContributionWei = _maxWeiAllowed;
    }


    function setSoftCap( uint256 _softCap ) onlyOwner public {
        minFundingGoalWei = _softCap;
    }

    function setHardCap( uint256 _hardCap ) onlyOwner public {
        hardCap = _hardCap;
    }

    function peggedETHUSD() constant onlyOwner public returns(uint256) {
        return peggedETHUSD;
    }

    function hardCapETHInWeiValue() constant onlyOwner public returns(uint256) {
        return hardCap;
    }


    function totalWeiRaised() constant onlyOwner public returns(uint256) {
        return weiRaisedIncludingFiatCurrencyRaised;
    }


    function ownerTransferWeiFirstWallet(uint256 _value) external onlyOwner {
        require(multiFirstWallet != 0x0);
        require(multiFirstWallet != address(token));

         
        uint256 _amount = _value > 0 ? _value : this.balance;

        multiFirstWallet.transfer(_amount);
    }

    function ownerTransferWeiSecondWallet(uint256 _value) external onlyOwner {
        require(multiSecondWallet != 0x0);
        require(multiSecondWallet != address(token));

         
        uint256 _amount = _value > 0 ? _value : this.balance;

        multiSecondWallet.transfer(_amount);
    }

    function ownerTransferWeiThirdWallet(uint256 _value) external onlyOwner {
        require(multiThirdWallet != 0x0);
        require(multiThirdWallet != address(token));

         
        uint256 _amount = _value > 0 ? _value : this.balance;

        multiThirdWallet.transfer(_amount);
    }

    function ownerRecoverTokens(address _beneficiary) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));
        require(paused || now > end);

        uint256 _tokensRemaining = token.balanceOf(address(this));
        if (_tokensRemaining > 0) {
            token.transfer(_beneficiary, _tokensRemaining);
        }
    }

    
    function addFiatCurrencyRaised( uint256 _fiatCurrencyIncrementInEquivalentWeiValue ) onlyOwner public {
        fiatCurrencyRaisedInEquivalentWeiValue = fiatCurrencyRaisedInEquivalentWeiValue.add( _fiatCurrencyIncrementInEquivalentWeiValue);
        weiRaisedIncludingFiatCurrencyRaised = weiRaisedIncludingFiatCurrencyRaised.add(_fiatCurrencyIncrementInEquivalentWeiValue);
        
    }

    function reduceFiatCurrencyRaised( uint256 _fiatCurrencyDecrementInEquivalentWeiValue ) onlyOwner public {
        fiatCurrencyRaisedInEquivalentWeiValue = fiatCurrencyRaisedInEquivalentWeiValue.sub(_fiatCurrencyDecrementInEquivalentWeiValue);
        weiRaisedIncludingFiatCurrencyRaised = weiRaisedIncludingFiatCurrencyRaised.sub(_fiatCurrencyDecrementInEquivalentWeiValue);
    }

}