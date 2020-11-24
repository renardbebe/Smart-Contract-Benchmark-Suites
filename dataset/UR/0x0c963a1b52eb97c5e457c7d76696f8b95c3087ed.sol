 

pragma solidity ^0.5.0;

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
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
   constructor() public {
      owner = msg.sender;
    }
    
     
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
     
    function transferOwnership(address payable newOwner) public onlyOwner {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
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

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  event Vested(address beneficiary, uint256 amount);
  event Released(address beneficiary, uint256 amount);

  struct Balance {
      uint256 value;
      uint256 start;
      uint256 currentPeriod;
  }

  mapping(address => Balance) private balances;
  mapping (address => uint256) private released;
  uint256 private period;
  uint256 private duration;
  mapping (uint256 => uint256) private percentagePerPeriod;

  constructor() public {
    owner = msg.sender;
    period = 4;
    duration = 7884000;
    percentagePerPeriod[0] = 15;
    percentagePerPeriod[1] = 20;
    percentagePerPeriod[2] = 30;
    percentagePerPeriod[3] = 35;
  }
  
  function balanceOf(address _owner) public view returns(uint256) {
      return balances[_owner].value.sub(released[_owner]);
  }
     
  function vesting(address _beneficiary, uint256 _amount) public onlyOwner {
      if(balances[_beneficiary].start == 0){
          balances[_beneficiary].start = now;
      }

      balances[_beneficiary].value = balances[_beneficiary].value.add(_amount);
      emit Vested(_beneficiary, _amount);
  }
  
   
  function release(address _beneficiary) public onlyOwner {
    require(balances[_beneficiary].currentPeriod.add(1) <= period);
    require(balances[_beneficiary].value > released[_beneficiary]);
    require(balances[_beneficiary].start != 0);
    require(now >= balances[_beneficiary].start.add((balances[_beneficiary].currentPeriod.add(1) * duration)));

    uint256 amountReleasedThisPeriod = balances[_beneficiary].value.mul(percentagePerPeriod[balances[_beneficiary].currentPeriod]);
    amountReleasedThisPeriod = amountReleasedThisPeriod.div(100);
    released[_beneficiary] = released[_beneficiary].add(amountReleasedThisPeriod);
    balances[_beneficiary].currentPeriod = balances[_beneficiary].currentPeriod.add(1);

    BasicToken(owner).transfer(_beneficiary, amountReleasedThisPeriod);

    emit Released(_beneficiary, amountReleasedThisPeriod);
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
     
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
}


 
contract Configurable {
    uint256 public constant cap = 2000000000*10**18;
    uint256 public basePrice = 314815*10**16;  
    uint256 public tokensSold = 0;
    uint256 public tokensSoldInICO = 0;
    uint256 public tokensSoldInPrivateSales = 0;
    
    uint256 public constant tokenReserve = 2000000000*10**18;
    uint256 public constant tokenReserveForICO = 70000000*10**18;
    uint256 public constant tokenReserveForPrivateSales = 630000000*10**18;
    uint256 public remainingTokens = 0;
    uint256 public remainingTokensForICO = 0;
    uint256 public remainingTokensForPrivateSales = 0;

    uint256 public minTransaction = 1.76 ether;
    uint256 public maxTransaction = 29.41 ether;

    uint256 public discountUntilSales = 1176.47 ether;
    uint256 public totalSalesInEther = 0;
    mapping(address => bool) public buyerGetDiscount;
}

contract BurnableToken is BasicToken, Ownable {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
      }
      
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

 
contract CrowdsaleToken is StandardToken, Configurable, BurnableToken  {
     
     enum Stages {
        none,
        icoStart,
        icoEnd
    }
    
    bool  public haltedICO = false;
    Stages currentStage;
    TokenVesting public tokenVestingContract;
  
     
    constructor() public {
        currentStage = Stages.none;
        balances[owner] = balances[owner].add(tokenReserve);
        totalSupply_ = totalSupply_.add(tokenReserve);

        remainingTokens = cap;
        remainingTokensForICO = tokenReserveForICO;
        remainingTokensForPrivateSales = tokenReserveForPrivateSales;
        tokenVestingContract = new TokenVesting();
        emit Transfer(address(this), owner, tokenReserve);
    }
    
     
    function () external payable {
        
        require(!haltedICO);
        require(currentStage == Stages.icoStart);
        require(msg.value > 0);
        require(remainingTokensForICO > 0);
        require(minTransaction <= msg.value);
        require(maxTransaction >= msg.value);
        
        uint256 weiAmount = msg.value;  
        uint256 bonusTokens;
        uint256 tokens = weiAmount.mul(basePrice).div(1 ether);
        uint256 returnWei = 0;

         
        if (totalSalesInEther.add(weiAmount) <= discountUntilSales && !buyerGetDiscount[msg.sender]) {
            bonusTokens = tokens.div(10);

            totalSalesInEther = totalSalesInEther.add(weiAmount);
            buyerGetDiscount[msg.sender] = true;
        }
        
        if (tokensSoldInICO.add(tokens.add(bonusTokens)) > tokenReserveForICO) {
            uint256 newTokens = tokenReserveForICO.sub(tokensSoldInICO);
            bonusTokens = newTokens.sub(tokens);

            if (bonusTokens <= 0) {
                bonusTokens = 0;
            }

            tokens = newTokens.sub(bonusTokens);
            returnWei = tokens.div(basePrice).div(1 ether);
        }
        
         
        tokensSoldInICO = tokensSoldInICO.add(tokens.add(bonusTokens));
        remainingTokensForICO = tokenReserveForICO.sub(tokensSoldInICO);

        tokensSold = tokensSold.add(tokens.add(bonusTokens));  
        remainingTokens = cap.sub(tokensSold);

        if(returnWei > 0){
            msg.sender.transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        emit Transfer(address(this), msg.sender, tokens);
        owner.transfer(weiAmount); 
    }
    
    function sendPrivate(address _to, uint256 _tokens) external payable onlyOwner {
        require(_to != address(0));
        require(address(tokenVestingContract) != address(0));
        require(remainingTokensForPrivateSales > 0);
        require(tokenReserveForPrivateSales >= tokensSoldInPrivateSales.add(_tokens));

         
        tokensSoldInPrivateSales = tokensSoldInPrivateSales.add(_tokens);
        remainingTokensForPrivateSales = tokenReserveForPrivateSales.sub(tokensSoldInPrivateSales);

        tokensSold = tokensSold.add(_tokens);  
        remainingTokens = cap.sub(tokensSold);

        balances[address(tokenVestingContract)] = balances[address(tokenVestingContract)].add(_tokens);
        tokenVestingContract.vesting(_to, _tokens);

        balances[owner] = balances[owner].sub(_tokens);
        emit Transfer(address(this), address(tokenVestingContract), _tokens);
    }

    function release(address _to) external onlyOwner {
        tokenVestingContract.release(_to);
    }

     
    function startIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        currentStage = Stages.icoStart;
    }
    
    event icoHalted(address sender);
    function haltICO() public onlyOwner {
        haltedICO = true;
        emit icoHalted(msg.sender);
    }

    event icoResumed(address sender);
    function resumeICO() public onlyOwner {
        haltedICO = false;
        emit icoResumed(msg.sender);
    }

     
    function endIco() internal {
        currentStage = Stages.icoEnd;
         
        if(remainingTokens > 0)
            balances[owner] = balances[owner].add(remainingTokens);
         
        owner.transfer(address(this).balance); 
    }


     
    function finalizeIco() public onlyOwner {
        require(currentStage != Stages.icoEnd);
        endIco();
    }

    function setDiscountUntilSales(uint256 _discountUntilSales) public onlyOwner {
        discountUntilSales = _discountUntilSales;
    }
    
    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setMinTransaction(uint256 _minTransaction) public onlyOwner {
        minTransaction = _minTransaction;
    }

    function setMaxTransaction(uint256 _maxTransaction) public onlyOwner {
        maxTransaction = _maxTransaction;
    }

    function addTokenSoldInICO(uint256 _amount) public onlyOwner {
        tokensSoldInICO = tokensSoldInICO.add(_amount);
        remainingTokensForICO = tokenReserveForICO.sub(tokensSoldInICO);

        tokensSold = tokensSold.add(_amount);
        remainingTokens = cap.sub(_amount);
    }

    function addTokenSoldInPrivateSales(uint256 _amount) public onlyOwner {
        tokensSoldInPrivateSales = tokensSoldInPrivateSales.add(_amount);
        remainingTokensForPrivateSales = tokenReserveForPrivateSales.sub(tokensSoldInPrivateSales);

        tokensSold = tokensSold.add(_amount);
        remainingTokens = cap.sub(_amount);
    }
}

 
contract TokoinToken is CrowdsaleToken {
    string public constant name = "Tokoin";
    string public constant symbol = "TOKO";
    uint32 public constant decimals = 18;
}