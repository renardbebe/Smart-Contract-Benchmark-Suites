 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



contract CakToken is MintableToken {
    string public constant name = "Cash Account Key";
    string public constant symbol = "CAK";
    uint8 public constant decimals = 0;
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


contract CakCrowdsale is Ownable, Crowdsale {
    using SafeMath for uint256;

    enum SaleStages { Crowdsale, Finalized }
    SaleStages public currentStage;

    uint256 public constant TOKEN_CAP = 3e7;
    uint256 public totalTokensMinted;

     
     
    mapping(address => bool) public isManagers;

     
    mapping(address => bool) public isWhitelisted;

     
    event ChangedInvestorWhitelisting(address indexed investor, bool whitelisted);
    event ChangedManager(address indexed manager, bool active);
    event PresaleMinted(address indexed beneficiary, uint256 tokenAmount);
    event CakCalcAmount(uint256 tokenAmount, uint256 weiReceived, uint256 rate);
    event RefundAmount(address indexed beneficiary, uint256 refundAmount);

     
    modifier onlyManager(){
        require(isManagers[msg.sender]);
        _;
    }

    modifier onlyCrowdsaleStage() {
        require(currentStage == SaleStages.Crowdsale);
        _;
    }

     
    function CakCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
        public
    {
        setManager(msg.sender, true);
        currentStage = SaleStages.Crowdsale;
    }

     
    function batchMintPresaleTokens(address[] _toList, uint256[] _tokenList) external onlyOwner onlyCrowdsaleStage {
        require(_toList.length == _tokenList.length);

        for (uint256 i; i < _toList.length; i = i.add(1)) {
            mintPresaleTokens(_toList[i], _tokenList[i]);
        }
    }

     
    function mintPresaleTokens(address _beneficiary, uint256 _amount) public onlyOwner onlyCrowdsaleStage {
        require(_beneficiary != address(0));
        require(_amount > 0);
        require(totalTokensMinted.add(_amount) <= TOKEN_CAP);
        require(now < startTime);

        token.mint(_beneficiary, _amount);
        totalTokensMinted = totalTokensMinted.add(_amount);
        PresaleMinted(_beneficiary, _amount);
    }

      
    function buyTokens(address _beneficiary) public payable onlyCrowdsaleStage {
        require(_beneficiary != address(0));
        require(isWhitelisted[msg.sender]);
        require(validPurchase());
        require(msg.value >= rate);   

        uint256 weiAmount = msg.value;
        weiRaised = weiRaised.add(weiAmount);

         
        uint256 tokens = calcCakAmount(weiAmount);
        CakCalcAmount(tokens, weiAmount, rate);
        require(totalTokensMinted.add(tokens) <= TOKEN_CAP);

        token.mint(_beneficiary, tokens);
        totalTokensMinted = totalTokensMinted.add(tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        uint256 refundAmount = refundLeftOverWei(weiAmount, tokens);
        if (refundAmount > 0) {
            weiRaised = weiRaised.sub(refundAmount);
            msg.sender.transfer(refundAmount);
            RefundAmount(msg.sender, refundAmount);
        }

        forwardEther(refundAmount);
    }

      
    function setManager(address _manager, bool _active) public onlyOwner {
        require(_manager != address(0));
        isManagers[_manager] = _active;
        ChangedManager(_manager, _active);
    }

     
    function whiteListInvestor(address _investor) external onlyManager {
        require(_investor != address(0));
        isWhitelisted[_investor] = true;
        ChangedInvestorWhitelisting(_investor, true);
    }

     
    function batchWhiteListInvestors(address[] _investors) external onlyManager {
        address investor;

        for (uint256 c; c < _investors.length; c = c.add(1)) {
            investor = _investors[c];  
            isWhitelisted[investor] = true;
            ChangedInvestorWhitelisting(investor, true);
        }
    }

     
    function unWhiteListInvestor(address _investor) external onlyManager {
        require(_investor != address(0));
        isWhitelisted[_investor] = false;
        ChangedInvestorWhitelisting(_investor, false);
    }

     
    function finalizeSale() public onlyOwner {
         currentStage = SaleStages.Finalized;
         token.finishMinting();
    }

     
    function calcCakAmount(uint256 weiReceived) public view returns (uint256) {
        uint256 tokenAmount = weiReceived.div(rate);
        return tokenAmount;
    }

     
    function refundLeftOverWei(uint256 weiReceived, uint256 tokenAmount) internal view returns (uint256) {
        uint256 refundAmount = 0;
        uint256 weiInvested = tokenAmount.mul(rate);
        if (weiInvested < weiReceived)
            refundAmount = weiReceived.sub(weiInvested);
        return refundAmount;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new CakToken();
    }

     
    function forwardEther(uint256 refund) internal {
        wallet.transfer(msg.value.sub(refund));
    }
}