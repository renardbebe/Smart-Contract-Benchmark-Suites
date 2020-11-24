 

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

 

contract PagosToken is MintableToken {
    string public constant name = "Pagos Token";
    string public constant symbol = "PGO";
    uint8 public decimals = 18;
    bool public tradingStarted = false;

     
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

     
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) hasStartedTrading public returns (bool){
        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading public returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public hasStartedTrading returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public hasStartedTrading returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public hasStartedTrading returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
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

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal{
  }
}

 

contract PagosCrowdSale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint256 public numberOfPurchasers = 0;

     
    uint256 public maxTokenSupply = 0;

     
    string public constant version = "v1.4";

     
    address public pendingOwner;

     
    uint256 public minimumAmount = 0;

     
    address public reservedAddr;
    uint256 public reservedAmount;

     
    uint256 public ratePublicSale;
    uint256 public maxTokenSupplyPublicSale;


    function PagosCrowdSale(uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    uint256 _minimumAmount,
    uint256 _maxTokenSupply,
    address _wallet,
    address _reservedAddr,
    uint256 _reservedAmount,
    address _pendingOwner,
    uint256 _ratePublicSale,
    uint256 _maxTokenSupplyPublicSale
    )
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
    {
        require(_pendingOwner != address(0));
        require(_minimumAmount >= 0);
        require(_maxTokenSupply > 0);
        require(_reservedAmount > 0 && _reservedAmount < _maxTokenSupply);

        pendingOwner = _pendingOwner;
        minimumAmount = _minimumAmount;
        maxTokenSupply = _maxTokenSupply;

         
        reservedAddr = _reservedAddr;
        reservedAmount = _reservedAmount;

         
        ratePublicSale=_ratePublicSale;
        maxTokenSupplyPublicSale=_maxTokenSupplyPublicSale;

    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new PagosToken();
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
         
        require(validPurchase());
         
        require(owner==pendingOwner);

        uint256 weiAmount = msg.value;

         
         

         
         
        uint256 tokens = weiAmount.mul(rate);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;

        forwardFunds();
    }

     
     
    function validPurchase() internal view returns (bool) {

         
        bool minAmount = (msg.value >= minimumAmount);

         
         
        bool lessThanMaxSupply = (token.totalSupply() + msg.value.mul(rate)) <= maxTokenSupply;

         
        return super.validPurchase() && minAmount && lessThanMaxSupply;
    }

     
     
    function hasEnded() public view returns (bool) {
        bool capReached = token.totalSupply() >= maxTokenSupply;
        return super.hasEnded() || capReached;
    }

     

     
    function finalization() internal {
         
         
         
         
        uint256 remainingTokens = maxTokenSupply - token.totalSupply();

         
        token.mint(owner, remainingTokens);
        TokenPurchase(owner, owner, 0, remainingTokens);

         
        super.finalization();

         
        token.finishMinting();

         
        token.transferOwnership(owner);
    }

     
    function changeMinimumAmount(uint256 _minimumAmount) onlyOwner public {
        require(_minimumAmount > 0);
        minimumAmount = _minimumAmount;
    }

     
    function changeDates(uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

     
    function publicSaleMode() onlyOwner public returns (uint256){
        rate=ratePublicSale;
        maxTokenSupply=maxTokenSupplyPublicSale;
        return ratePublicSale;
    }


     
    function transferOwnerShipToPendingOwner() public {

         
        require(msg.sender == pendingOwner);

         
        require(owner != pendingOwner);

         
        OwnershipTransferred(owner, pendingOwner);

         
        owner = pendingOwner;

         
        runPreMint();

    }

     
     

    function runPreMint() onlyOwner private {

        token.mint(reservedAddr, reservedAmount);
        TokenPurchase(owner, reservedAddr, 0, reservedAmount);

         
        numberOfPurchasers = numberOfPurchasers + 1;
    }

}