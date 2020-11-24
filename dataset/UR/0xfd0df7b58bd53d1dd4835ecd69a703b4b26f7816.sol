 

pragma solidity ^0.4.18;

 

 
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

 

contract MziToken is MintableToken {
    string public constant name = "MziToken";
    string public constant symbol = "MZI";
    uint8 public constant decimals = 18;
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

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

contract Moozicore is Crowdsale {

    uint256 constant CAP =  1000000000000000000000000000;
    uint256 constant CAP_PRE_SALE = 166000000000000000000000000;
    uint256 constant CAP_ICO_SALE = 498000000000000000000000000;

    uint256 constant RATE_PRE_SALE_WEEK1 = 100000;
    uint256 constant RATE_PRE_SALE_WEEK2 = 95000;
    uint256 constant RATE_PRE_SALE_WEEK3 = 90000;
    uint256 constant RATE_PRE_SALE_WEEK4 = 85000;

    uint256 constant RATE_ICO_SALE_WEEK1 = 80000;
    uint256 constant RATE_ICO_SALE_WEEK2 = 75000;
    uint256 constant RATE_ICO_SALE_WEEK3 = 72500;
    uint256 constant RATE_ICO_SALE_WEEK4 = 70000;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public totalSupplyIco;

    function Moozicore (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet
    ) public 
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MziToken();
    }

     
    function validPurchase() internal constant returns (bool) {

        if (msg.value < 50000000000000000) {
            return false;
        }

        if (token.totalSupply().add(msg.value.mul(getRate())) >= CAP) {
            return false;
        }
        
        if (now >= 1517266799 && now < 1533110400) {
            return false;
        }

        if (now <= 1517266799) {
            if (token.totalSupply().add(msg.value.mul(getRate())) >= CAP_PRE_SALE) {
                return false;
            }
        }

        if (now >= 1533110400) {
            if (totalSupplyIco.add(msg.value.mul(getRate())) >= CAP_ICO_SALE) {
                return false;
            }
        }

        return super.validPurchase();
    }

     function buyTokens(address beneficiary) payable public {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(getRate());
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        if (now >= 1533110400) {
            totalSupplyIco = totalSupplyIco.add(tokens);
        }

        forwardFunds();
    }

    function getRate() public constant returns (uint256) {
        uint256 currentRate = RATE_ICO_SALE_WEEK4;

        if (now <= 1515452399) {
            currentRate = RATE_PRE_SALE_WEEK1;
        } else if (now <= 1516057199) {
            currentRate = RATE_PRE_SALE_WEEK2;
        } else if (now <= 1516661999) {
            currentRate = RATE_PRE_SALE_WEEK3;
        } else if (now <= 1517266799) {
            currentRate = RATE_PRE_SALE_WEEK4;
        } else if (now <= 1533679199) {
            currentRate = RATE_ICO_SALE_WEEK1;
        } else if (now <= 1534283999) {
            currentRate = RATE_ICO_SALE_WEEK2;
        } else if (now <= 1534888799) {
            currentRate = RATE_ICO_SALE_WEEK3;
        } else if (now <= 1535493599) {
            currentRate = RATE_ICO_SALE_WEEK4;
        }

        return currentRate;
    }

    function mintTokens(address walletToMint, uint256 t) payable public {
        require(msg.sender == wallet);
        require(token.totalSupply().add(t) < CAP);
        
        if (now <= 1517266799) {
            require(token.totalSupply().add(t) < CAP_PRE_SALE);
        }

        if (now > 1517266799) {
            require(totalSupplyIco.add(t) < CAP_ICO_SALE);
            totalSupplyIco = totalSupplyIco.add(t);
        }

        token.mint(walletToMint, t);
    }
}