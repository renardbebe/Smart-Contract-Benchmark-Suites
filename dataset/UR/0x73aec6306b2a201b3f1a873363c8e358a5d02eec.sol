 

pragma solidity 0.4.24;


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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract OneledgerToken is MintableToken {
    using SafeMath for uint256;

    string public name = "Oneledger Token";
    string public symbol = "OLT";
    uint8 public decimals = 18;
    bool public active = false;
     
    modifier activated() {
        require(active == true);
        _;
    }

     
    function activate() public onlyOwner {
        active = true;
    }

     
    function transfer(address to, uint256 value) public activated returns (bool) {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public activated returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

contract ICO is Ownable {
    using SafeMath for uint256;

    struct WhiteListRecord {
        uint256 offeredWei;
        uint256 lastPurchasedTimestamp;
    }

    OneledgerToken public token;
    address public wallet;  
    uint256 public rate;    
    mapping (address => WhiteListRecord) public whiteList;
    uint256 public initialTime;
    bool public saleClosed;
    uint256 public weiCap;
    uint256 public weiRaised;

    uint256 public TOTAL_TOKEN_SUPPLY = 1000000000 * (10 ** 18);

    event BuyTokens(uint256 weiAmount, uint256 rate, uint256 token, address beneficiary);
    event UpdateRate(uint256 rate);

     
    constructor(address _wallet, uint256 _rate, uint256 _startDate, uint256 _weiCap) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_weiCap.mul(_rate) <= TOTAL_TOKEN_SUPPLY);

        wallet = _wallet;
        rate = _rate;
        initialTime = _startDate;
        saleClosed = false;
        weiCap = _weiCap;
        weiRaised = 0;

        token = new OneledgerToken();
    }

     
    function() external payable {
        buyTokens();
    }

     
    function updateRate(uint256 rate_) public onlyOwner {
      require(now <= initialTime);
      rate = rate_;
      emit UpdateRate(rate);
    }

     
    function buyTokens() public payable {
        validatePurchase(msg.value);
        uint256 tokenToBuy = msg.value.mul(rate);
        whiteList[msg.sender].lastPurchasedTimestamp = now;
        weiRaised = weiRaised.add(msg.value);
        token.mint(msg.sender, tokenToBuy);
        wallet.transfer(msg.value);
        emit BuyTokens(msg.value, rate, tokenToBuy, msg.sender);
    }

     
    function addToWhiteList(address[] addresses, uint256 weiPerContributor) public onlyOwner {
        for (uint32 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = WhiteListRecord(weiPerContributor, 0);
        }
    }

     
    function mintToken(address target, uint256 tokenToMint) public onlyOwner {
      token.mint(target, tokenToMint);
    }

     
    function closeSale() public onlyOwner {
        saleClosed = true;
        token.mint(owner, TOTAL_TOKEN_SUPPLY.sub(token.totalSupply()));
        token.finishMinting();
        token.transferOwnership(owner);
    }

    function validatePurchase(uint256 weiPaid) internal view{
        require(!saleClosed);
        require(initialTime <= now);
        require(whiteList[msg.sender].offeredWei > 0);
        require(weiPaid <= weiCap.sub(weiRaised));
         
        require(now.sub(whiteList[msg.sender].lastPurchasedTimestamp) > 24 hours);
        uint256 elapsedTime = now.sub(initialTime);
         
        require(elapsedTime > 24 hours || msg.value <= whiteList[msg.sender].offeredWei);
         
        require(elapsedTime > 48 hours || msg.value <= whiteList[msg.sender].offeredWei.mul(2));
    }
}
contract OneledgerTokenVesting is Ownable{
    using SafeMath for uint256;

    event Released(uint256 amount);

     
    address public beneficiary;

    uint256 public startFrom;
    uint256 public period;
    uint256 public tokensReleasedPerPeriod;

    uint256 public elapsedPeriods;

    OneledgerToken private token;

     
    constructor(
        address _beneficiary,
        uint256 _startFrom,
        uint256 _period,
        uint256 _tokensReleasedPerPeriod,
        OneledgerToken _token
    ) public {
        require(_beneficiary != address(0));
        require(_startFrom >= now);

        beneficiary = _beneficiary;
        startFrom = _startFrom;
        period = _period;
        tokensReleasedPerPeriod = _tokensReleasedPerPeriod;
        elapsedPeriods = 0;
        token = _token;
    }

     
     function getToken() public view returns(OneledgerToken) {
       return token;
     }

     
    function release() public {
        require(msg.sender == owner || msg.sender == beneficiary);
        require(token.balanceOf(this) >= 0 && now >= startFrom);
        uint256 elapsedTime = now.sub(startFrom);
        uint256 periodsInCurrentRelease = elapsedTime.div(period).sub(elapsedPeriods);
        uint256 tokensReadyToRelease = periodsInCurrentRelease.mul(tokensReleasedPerPeriod);
        uint256 amountToTransfer = tokensReadyToRelease > token.balanceOf(this) ? token.balanceOf(this) : tokensReadyToRelease;
        require(amountToTransfer > 0);
        elapsedPeriods = elapsedPeriods.add(periodsInCurrentRelease);
        token.transfer(beneficiary, amountToTransfer);
        emit Released(amountToTransfer);
    }
}