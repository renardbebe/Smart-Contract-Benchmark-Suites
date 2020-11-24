 

 
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

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
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
 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}





contract FrameworkInvest is MintedCrowdsale,CappedCrowdsale,  Ownable {
  
  mapping(address => bool) public owners;

  uint8 decimals = 18;   
   
  enum CrowdsaleStage { PS_R1, PS_R2, PS_R3, PS_R4, PS_R5, PS_R6, PS_R7, ICO }
  CrowdsaleStage public stage = CrowdsaleStage.PS_R1;  
   

   
   
  uint256 public maxTokens = 100000000 * (10 ** uint256(decimals));  
  uint256 public tokensForReserve = 40000000 * (10 ** uint256(decimals));  
  uint256 public tokensForBounty = 1000000 * (10 ** uint256(decimals));  
  uint256 public totalTokensForSale = 50000000 * (10 ** uint256(decimals));  
  uint256 public totalTokensForSaleDuringPreICO = 20000000 * (10 ** uint256(decimals));  
   
  
   
   
  uint256 public DEFAULT_RATE = 500;
  uint256 public ROUND_1_PRESALE_BONUS = 175;  
  uint256 public ROUND_2_PRESALE_BONUS = 150;  
  uint256 public ROUND_3_PRESALE_BONUS = 125;  
  uint256 public ROUND_4_PRESALE_BONUS = 100;  
  uint256 public ROUND_5_PRESALE_BONUS = 75;  
  uint256 public ROUND_6_PRESALE_BONUS = 50;  
  uint256 public ROUND_7_PRESALE_BONUS = 25;  
  uint256 public ICO_BONUS = 0;

   
   
  uint256 public totalWeiRaisedDuringPreICO;
   

  bool public crowdsaleStarted = true;
  bool public crowdsalePaused = false;
   
  event EthTransferred(string text);
  event EthRefunded(string text);
  
modifier onlyOwner() {
    require(isAnOwner(msg.sender));
    _;
  }

  function addNewOwner(address _owner) public onlyOwner{
    require(_owner != address(0));
    owners[_owner]= true;
  }

  function removeOwner(address _owner) public onlyOwner{
    require(_owner != address(0));
    require(_owner != msg.sender);
    owners[_owner]= false;
  }

  function isAnOwner(address _owner) public constant returns(bool) {
     if (_owner == owner){
       return true;
     }

     return owners[_owner];
  }
  
  modifier hasMintPermission() {
    require(isAnOwner(msg.sender));
    _;
  }


  function FrameworkInvest(uint256 _rate, address _wallet, uint256 _cap, CappedToken _token) CappedCrowdsale(_cap) Crowdsale(_rate, _wallet, _token) public {
  }
  
  
   
     
    function setCrowdsaleStage(uint value) public onlyOwner {

        CrowdsaleStage _stage;

        if (uint(CrowdsaleStage.PS_R1) == value) {
          _stage = CrowdsaleStage.PS_R1;
          calculateAndSetRate(ROUND_1_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R2) == value) {
          _stage = CrowdsaleStage.PS_R2;
          calculateAndSetRate(ROUND_2_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R3) == value) {
          _stage = CrowdsaleStage.PS_R3;
          calculateAndSetRate(ROUND_3_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R4) == value) {
          _stage = CrowdsaleStage.PS_R4;
          calculateAndSetRate(ROUND_4_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R5) == value) {
          _stage = CrowdsaleStage.PS_R5;
          calculateAndSetRate(ROUND_5_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R6) == value) {
          _stage = CrowdsaleStage.PS_R6;
          calculateAndSetRate(ROUND_6_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.PS_R7) == value) {
          _stage = CrowdsaleStage.PS_R7;
          calculateAndSetRate(ROUND_7_PRESALE_BONUS);
        } else if (uint(CrowdsaleStage.ICO) == value) {
          _stage = CrowdsaleStage.ICO;
          calculateAndSetRate(ICO_BONUS);
        }

        stage = _stage;
    }

     
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }

     
    function calculateAndSetRate(uint256 _bonus) private {
        uint256 calcRate = DEFAULT_RATE + _bonus;
        setCurrentRate(calcRate);
    }
    
    function setRate(uint256 _rate) public onlyOwner {
        setCurrentRate(_rate);
    }
    
    function setCrowdSale(bool _started) public onlyOwner {
        crowdsaleStarted = _started;
    }
   
  
     
     
    function () external payable {
       require(!crowdsalePaused);
        uint256 tokensThatWillBeMintedAfterPurchase = msg.value.mul(rate);
        if ((stage != CrowdsaleStage.ICO) && (token.totalSupply() + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringPreICO)) {
          msg.sender.transfer(msg.value);  
          EthRefunded("Presale Limit Hit.");
          return;
        }

        buyTokens(msg.sender);
        EthTransferred("Transferred funds to wallet.");
        
        if (stage != CrowdsaleStage.ICO) {
            totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(msg.value);
        }
    }
  function pauseCrowdsale() public onlyOwner{
    crowdsalePaused = true;
  }
  function unPauseCrowdsale() public onlyOwner{
    crowdsalePaused = false;
  }
     
     
     

    function finish(address _reserveFund, address _bountyFund) public onlyOwner {
        if (crowdsaleStarted){
            uint256 alreadyMinted = token.totalSupply();
            require(alreadyMinted < maxTokens);

            uint256 unsoldTokens = totalTokensForSale - alreadyMinted;
            if (unsoldTokens > 0) {
                tokensForReserve = tokensForReserve + unsoldTokens;
            }
            MintableToken(token).mint(_reserveFund,tokensForReserve);
            MintableToken(token).mint(_bountyFund,tokensForBounty);
            crowdsaleStarted = false;
        }
    }
   
}