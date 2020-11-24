 

pragma solidity 0.4.19;

 
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


   
  function balanceOf(address _owner) public view returns (uint256) {
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




 
contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = true;


   
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
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




contract LMDA is PausableToken {
    
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


     
    function LMDA() public {
        name = "LaMonedaCoin";
        symbol = "LMDA";
        decimals = 18;
        totalSupply = 500000000e18;
        
        balances[owner] = totalSupply;
        Transfer(address(this), owner, totalSupply);
    }
}




contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    event AidropInvoked();
    event MainSaleActivated();
    event TokenPurchased(address recipient, uint256 tokens);
    event DeadlineExtended(uint256 daysExtended);
    event DeadlineShortened(uint256 daysShortenedBy);
    event OffChainPurchaseMade(address recipient, uint256 tokensBought);
    event TokenPriceChanged(string stage, uint256 newTokenPrice);
    event ExchangeRateChanged(string stage, uint256 newRate);
    event BonusChanged(string stage, uint256 newBonus);
    event TokensWithdrawn(address to, uint256 LMDA); 
    event TokensUnpaused();
    event ICOPaused(uint256 timeStamp);
    event ICOUnpaused(uint256 timeStamp);  
    
    address public receiverOne;
    address public receiverTwo;
    address public receiverThree;
    address public reserveAddress;
    address public teamAddress;
    
    uint256 public endTime;
    uint256 public tokenPriceForPreICO;
    uint256 public rateForPreICO;
    uint256 public tokenPriceForMainICO;
    uint256 public rateForMainICO;
    uint256 public tokenCapForPreICO;
    uint256 public tokenCapForMainICO;
    uint256 public bonusForPreICO;
    uint256 public bonusForMainICO;
    uint256 public tokensSold;
    uint256 public timePaused;
    bool public icoPaused;
    
    
    enum StateOfICO {
        PRE,
        MAIN
    }
    
    StateOfICO public stateOfICO;
    
    LMDA public lmda;

    mapping (address => uint256) public investmentOf;
    
    
     
    modifier whenNotPaused {
        require(!icoPaused);
        _;
    }
    
    
     
    function ICO() public {
        lmda = new LMDA();
        receiverOne = 0x43adebFC525FEcf9b2E91a4931E4a003a1F0d959;    
        receiverTwo = 0xB447292181296B8c7F421F1182be20640dc8Bb05;    
        receiverThree = 0x3f68b06E7C0E87828647Dbba0b5beAef3822b7Db;  
        reserveAddress = 0x7d05F660124B641b74b146E9aDA60D7D836dcCf5;
        teamAddress = 0xAD942E5085Af6a7A4C31f17ac687F8d5d7C0225C;
        lmda.transfer(reserveAddress, 90000000e18);
        lmda.transfer(teamAddress, 35500000e18);
        stateOfICO = StateOfICO.PRE;
        endTime = now.add(21 days);
        tokenPriceForPreICO = 0.00005 ether;
        rateForPreICO = 20000;
        tokenPriceForMainICO = 0.00007 ether;
        rateForMainICO = 14285;  
        tokenCapForPreICO = 144000000e18;
        tokenCapForMainICO = 374500000e18; 
        bonusForPreICO = 20;
        bonusForMainICO = 15;
        tokensSold = 0;
        icoPaused= false;
    }
    
    
     
    function airdrop(address[] _addrs, uint256[] _values) public onlyOwner {
        require(lmda.balanceOf(address(this)) >= getSumOfValues(_values));
        require(_addrs.length <= 100 && _addrs.length == _values.length);
        for(uint i = 0; i < _addrs.length; i++) {
            lmda.transfer(_addrs[i], _values[i]);
        }
        AidropInvoked();
    }
    
    
     
    function getSumOfValues(uint256[] _values) internal pure returns(uint256 sum) {
        sum = 0;
        for(uint i = 0; i < _values.length; i++) {
            sum = sum.add(_values[i]);
        }
    }
    
    
     
    function activateMainSale() public onlyOwner whenNotPaused {
        require(now >= endTime || tokensSold >= tokenCapForPreICO);
        stateOfICO = StateOfICO.MAIN;
        endTime = now.add(49 days);
        MainSaleActivated();
    }


     
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
     
    function buyTokens(address _addr) public payable whenNotPaused {
        require(now <= endTime && _addr != 0x0);
        require(lmda.balanceOf(address(this)) > 0);
        if(stateOfICO == StateOfICO.PRE && tokensSold >= tokenCapForPreICO) {
            revert();
        } else if(stateOfICO == StateOfICO.MAIN && tokensSold >= tokenCapForMainICO) {
            revert();
        }
        uint256 toTransfer = msg.value.mul(getRate().mul(getBonus())).div(100).add(getRate());
        lmda.transfer(_addr, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        investmentOf[msg.sender] = investmentOf[msg.sender].add(msg.value);
        TokenPurchased(_addr, toTransfer);
        forwardFunds();
    }
    
    
     
    function processOffChainPurchase(address _recipient, uint256 _value) public onlyOwner {
        require(lmda.balanceOf(address(this)) >= _value);
        require(_value > 0 && _recipient != 0x0);
        lmda.transfer(_recipient, _value);
        tokensSold = tokensSold.add(_value);
        OffChainPurchaseMade(_recipient, _value);
    }
    
    
     
    function forwardFunds() internal {
        if(stateOfICO == StateOfICO.PRE) {
            receiverOne.transfer(msg.value.div(2));
            receiverTwo.transfer(msg.value.div(2));
        } else {
            receiverThree.transfer(msg.value);
        }
    }
    
    
     
    function extendDeadline(uint256 _daysToExtend) public onlyOwner {
        endTime = endTime.add(_daysToExtend.mul(1 days));
        DeadlineExtended(_daysToExtend);
    }
    
    
     
    function shortenDeadline(uint256 _daysToShortenBy) public onlyOwner {
        if(now.sub(_daysToShortenBy.mul(1 days)) < endTime) {
            endTime = now;
        }
        endTime = endTime.sub(_daysToShortenBy.mul(1 days));
        DeadlineShortened(_daysToShortenBy);
    }
    
    
     
    function changeTokenPrice(uint256 _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 0);
        if(stateOfICO == StateOfICO.PRE) {
            if(tokenPriceForPreICO == _newTokenPrice) { revert(); } 
            tokenPriceForPreICO = _newTokenPrice;
            rateForPreICO = uint256(1e18).div(tokenPriceForPreICO);
            TokenPriceChanged("Pre ICO", _newTokenPrice);
        } else {
            if(tokenPriceForMainICO == _newTokenPrice) { revert(); } 
            tokenPriceForMainICO = _newTokenPrice;
            rateForMainICO = uint256(1e18).div(tokenPriceForMainICO);
            TokenPriceChanged("Main ICO", _newTokenPrice);
        }
    }
    
    
     
    function changeRateOfToken(uint256 _newRate) public onlyOwner {
        require(_newRate > 0);
        if(stateOfICO == StateOfICO.PRE) {
            if(rateForPreICO == _newRate) { revert(); }
            rateForPreICO = _newRate;
            tokenPriceForPreICO = uint256(1e18).div(rateForPreICO);
            ExchangeRateChanged("Pre ICO", _newRate);
        } else {
            if(rateForMainICO == _newRate) { revert(); }
            rateForMainICO = _newRate;
            rateForMainICO = uint256(1e18).div(rateForMainICO);
            ExchangeRateChanged("Main ICO", _newRate);
        }
    }
    
    
     
    function changeBonus(uint256 _newBonus) public onlyOwner {
        if(stateOfICO == StateOfICO.PRE) {
            if(bonusForPreICO == _newBonus) { revert(); }
            bonusForPreICO = _newBonus;
            BonusChanged("Pre ICO", _newBonus);
        } else {
            if(bonusForMainICO == _newBonus) { revert(); }
            bonusForMainICO = _newBonus;
            BonusChanged("Main ICO", _newBonus);
        }
    }
    
    
     
    function withdrawUnsoldTokens() public onlyOwner {
        TokensWithdrawn(owner, lmda.balanceOf(address(this)));
        lmda.transfer(owner, lmda.balanceOf(address(this)));
    }
    
    
     
    function unpauseToken() public onlyOwner {
        TokensUnpaused();
        lmda.unpause();
    }
    
    
     
    function transferTokenOwnership() public onlyOwner {
        lmda.transferOwnership(owner);
    }
    
    
     
    function pauseICO() public onlyOwner whenNotPaused {
        require(now < endTime);
        timePaused = now;
        icoPaused = true;
        ICOPaused(now);
    }
    
  
     
    function unpauseICO() public onlyOwner {
        endTime = endTime.add(now.sub(timePaused));
        timePaused = 0;
        ICOUnpaused(now);
    }
    
    
     
    function getTokensSold() public view returns(uint256 _tokensSold) {
        _tokensSold = tokensSold;
    }
    
    
     
    function getBonus() public view returns(uint256 _bonus) {
        if(stateOfICO == StateOfICO.PRE) { 
            _bonus = bonusForPreICO;
        } else {
            _bonus = bonusForMainICO;
        }
    }
    
    
     
    function getRate() public view returns(uint256 _exchangeRate) {
        if(stateOfICO == StateOfICO.PRE) {
            _exchangeRate = rateForPreICO;
        } else {
            _exchangeRate = rateForMainICO;
        }
    }
    
    
     
    function getTokenPrice() public view returns(uint256 _tokenPrice) {
        if(stateOfICO == StateOfICO.PRE) {
            _tokenPrice = tokenPriceForPreICO;
        } else {
            _tokenPrice = tokenPriceForMainICO;
        }
    }
}