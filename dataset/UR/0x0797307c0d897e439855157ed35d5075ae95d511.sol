 

pragma solidity ^0.4.24;

 

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
  address public owner;
  address public coowner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
    coowner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == coowner);
    _;
  }

   

    function setOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(coowner, newOwner);
        coowner = newOwner;
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

contract CrowdsaleToken is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

 constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_.sub(balances[address(0)]);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Burnable is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

  function burn(address account, uint256 value) internal {
    require(account != address(0));
    totalSupply_ = totalSupply_.sub(value);
    balances[account] = balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
   
  function burnFrom(address account, uint256 value) internal {
    allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
    burn(account, value);
  }

}


 

contract MSG is Ownable, Pausable, Burnable, CrowdsaleToken {
    using SafeMath for uint256;

    string name = "MoreStamps Global Token";
    string symbol = "MSG";
    uint8 decimals = 18;

     
    bool crowdsaleConcluded = false;

     
    uint256 public startTime;
    uint256 public switchTime;
    uint256 public endTime;

     
    uint256 minimumInvestPreSale = 10E17;
    uint256 minimumInvestCrowdSale = 5E17;

     
    uint256 public preSaleBonus = 15;
    uint256 public crowdSaleBonus = 10;

     
    address public wallet;

     
    uint256 public preSaleRate = 1986;
    uint256 public crowdSaleRate = 1420;

     
    uint256 public preSaleLimit = 20248800E18;
    uint256 public crowdSaleLimit = 73933200E18;

     
    uint256 public weiRaised;
    uint256 public tokensSold;
    
     
    address STRATEGIC_PARTNERS_WALLET = 0x19CFB0E3F83831b726273b81760AE556600785Ec;

     
    bool tokensAllocated = false;

    uint256 public contributors = 0;
    mapping(address => uint256) public contributions;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    constructor() 
        CrowdsaleToken(name, symbol, decimals) public {
    
        totalSupply_ = 156970000E18;
        
         
        balances[this] = totalSupply_;

        startTime = 1543622400;
        switchTime = 1547596800;
        endTime = 1550275200;

        wallet = msg.sender;
    }

     
    function () external whenNotPaused payable {
        buyTokens(msg.sender);
    }

    function envokeTokenAllocation() public onlyOwner {
        require(!tokensAllocated);
        this.transfer(STRATEGIC_PARTNERS_WALLET, 62788000E18);  
        tokensAllocated = true;
    }

     
    function buyTokens(address _beneficiary) public whenNotPaused payable returns (uint256) {
        require(!hasEnded());
        require(_beneficiary != address(0));
        require(validPurchase());
        require(minimumInvest(msg.value));

        address beneficiary = _beneficiary;
        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);

         
        bool isLess = false;
        if (!hasEnoughTokensLeft(weiAmount)) {
            isLess = true;

            uint256 percentOfValue = tokensLeft().mul(100).div(tokens);
            require(percentOfValue <= 100);

            tokens = tokens.mul(percentOfValue).div(100);
            weiAmount = weiAmount.mul(percentOfValue).div(100);

             
            beneficiary.transfer(msg.value.sub(weiAmount));
        }

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

         
        if(contributions[beneficiary] == 0) {
            contributors = contributors.add(1);
        }

         
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

         
        this.transfer(beneficiary, tokens);

         
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        return (tokens);
    }

     


    function setRate(uint256 _preSaleRate, uint256 _crowdSaleRate) onlyOwner public {
      require(_preSaleRate >= 0);
      require(_crowdSaleRate >= 0);
      preSaleRate = _preSaleRate;
      crowdSaleRate = _crowdSaleRate;
    }

    function setBonus(uint256 _preSaleBonus, uint256 _crowdSaleBonus) onlyOwner public {
      require(_preSaleBonus >= 0);
      require(_crowdSaleBonus >= 0);
      preSaleBonus = _preSaleBonus;
      crowdSaleBonus = _crowdSaleBonus;
    }

    function setMinInvestment(uint256 _investmentPreSale, uint256 _investmentCrowdSale) onlyOwner public {
      require(_investmentPreSale > 0);
      require(_investmentCrowdSale > 0);
      minimumInvestPreSale = _investmentPreSale;
      minimumInvestCrowdSale = _investmentCrowdSale;
    }

    function changeEndTime(uint256 _endTime) onlyOwner public {
        require(_endTime > startTime);
        endTime = _endTime;
    }

    function changeSwitchTime(uint256 _switchTime) onlyOwner public {
        require(endTime > _switchTime);
        require(_switchTime > startTime);
        switchTime = _switchTime;
    }

    function changeStartTime(uint256 _startTime) onlyOwner public {
        require(endTime > _startTime);
        startTime = _startTime;
    }

    function setWallet(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

     

    function endSale() onlyOwner public {
       
      crowdsaleConcluded = true;
    }

    function resumeSale() onlyOwner public {
       
      crowdsaleConcluded = false;
    }

     

    function evacuateTokens(uint256 _amount) external onlyOwner {
        owner.transfer(_amount);
    }

    function manualTransfer(ERC20 _tokenInstance, uint256 _tokens, address beneficiary) external onlyOwner returns (bool success) {
        tokensSold = tokensSold.add(_tokens);
        _tokenInstance.transfer(beneficiary, _tokens);
        return true;
    }

     

     
    function hasEnded() public view returns (bool) {
        return now > endTime || this.balanceOf(this) == 0 || crowdsaleConcluded;
    }

    function getBaseAmount(uint256 _weiAmount) public view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return _weiAmount.mul(currentRate);
    }

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = getBaseAmount(_weiAmount);
        uint256 percentage = getCurrentBonus();
        if (percentage > 0) {
            tokens = tokens.add(tokens.mul(percentage).div(100));
        }

        assert(tokens > 0);
        return (tokens);
    }

     
    function forwardFunds(uint256 _amount) external onlyOwner {
        wallet.transfer(_amount);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function minimumInvest(uint256 _weiAmount) internal view returns (bool) {
        uint256 currentMinimum = getCurrentMinimum();
        if(_weiAmount >= currentMinimum) return true;
        return false;
    }

    function getCurrentMinimum() public view returns (uint256) {
        if(now >= startTime && now <= switchTime) return minimumInvestPreSale;
        if(now >= switchTime && now <= endTime) return minimumInvestCrowdSale;        
        return 0;        
    }

    function getCurrentRate() public view returns (uint256) {
        if(now >= startTime && now <= switchTime) return preSaleRate;
        if(now >= switchTime && now <= endTime) return crowdSaleRate;        
        return 0;
    }

    function getCurrentBonus() public view returns (uint256) {
        if(now >= startTime && now <= switchTime) return preSaleBonus;
        if(now >= switchTime && now <= endTime) return crowdSaleBonus;        
        return 0;
    }

    function tokensLeft() public view returns (uint256) {
        if(now >= startTime && now <= switchTime) return this.balanceOf(this).sub(crowdSaleLimit);
        if(now >= switchTime && now <= endTime) return this.balanceOf(this);
        return 0;
    }

    function hasEnoughTokensLeft(uint256 _weiAmount) public payable returns (bool) {
        return tokensLeft().sub(_weiAmount) >= getBaseAmount(_weiAmount);
    }
}