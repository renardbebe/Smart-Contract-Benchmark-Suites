 

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
  event ChangeBalance (address from, uint256 fromBalance, address to, uint256 toBalance, uint256 seq);

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 internal seq = 0;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    ChangeBalance (_from, balances[_from], _to, balances[_to], ++seq);
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

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    ChangeBalance (address(0), 0, _to, balances[_to], ++seq);
    return true; 
  }
}

 

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  uint256[] starts;
  uint256[] ends;
  uint256[] rates;

   
  uint256 internal seq;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

  uint256 public cap;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 seq);
  
  function Crowdsale(uint256[] _startTime, uint256[] _endTime, uint256[] _rates, address _wallet, uint256 _cap) public {
     

    for (uint8 i = 0; i < starts.length; i ++) {
      require(_endTime[i] >= _startTime[i]);
      require(_rates[i] > 0);
      require(_wallet != address(0));
    }

    cap = _cap;
    starts = _startTime;
    ends = _endTime;
    rates = _rates;

     
    
    
    startTime = _startTime[0];
    endTime = _endTime[_endTime.length - 1];
    rate = _rates[0];
    wallet = _wallet;
  }

  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  function () external payable {
     
    require (msg.value >= 1000000000000000000);
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 arrayLength = starts.length;


     
    for (uint8 i = 0; i < arrayLength; i ++) {
      if (now >= starts[i] && now <= ends[i]) {
        rate = rates[i];
        break;
      }
    }    
    uint256 tokens = weiAmount.mul(rate);
    require (checkCap(tokens));

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, ++seq);

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
    uint256 tokenSupply = token.totalSupply();
    bool capReached = tokenSupply >= cap;
    bool overTime = now > endTime;
    return capReached && overTime;  
  }

  function checkCap(uint256 tokens) internal view returns (bool) {
    uint256 issuedTokens = token.totalSupply();
    return (issuedTokens.add(tokens) <= cap);
  }
}

 

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    Finalized();

    isFinalized = true;
  }
}

 

contract OMXToken is MintableToken {
    string public constant name = "OMEX";
    string public constant symbol = "OMX";
    uint8 public constant decimals = 18;

    function OMXToken () public MintableToken () {
    }


}

 

contract OMXCrowdsale is FinalizableCrowdsale {
    uint256[] start = [1514646000, 1515942000, 1516806000];
    uint256[] end = [1515941999, 1516805999, 1517669999];
    uint256[] rate = [1400, 1200, 1000];
    address companyWallet;
    address tokenAddress;

    uint256 salesCap    = 300000000000000000000000000;
    uint256 cap         = 500000000000000000000000000;

  function OMXCrowdsale(address _wallet, address _token) public 
      FinalizableCrowdsale() Crowdsale(start, end, rate, _wallet, salesCap)
  {
      companyWallet = _wallet;
      tokenAddress = _token;
      token = createTokenContract();
  }

  function createTokenContract() internal returns (MintableToken) {
      OMXToken omxInstance;
      omxInstance = OMXToken (address(tokenAddress));
      return omxInstance;
  }

  function finalize() onlyOwner public {
       
      token.mint(companyWallet, cap - token.totalSupply());
      super.finalize();
  }
}