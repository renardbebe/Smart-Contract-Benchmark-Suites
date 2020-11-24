 

 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.21;



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.21;


 
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

 

pragma solidity ^0.4.21;




 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

pragma solidity ^0.4.21;




 
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

 

pragma solidity ^0.4.21;




 
contract StandardToken is ERC20, BasicToken {

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

}

 

pragma solidity ^0.4.21;


 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

pragma solidity ^0.4.21;




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

 

pragma solidity ^0.4.21;




 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

pragma solidity ^0.4.21;




 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

pragma solidity ^0.4.21;





 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

pragma solidity ^0.4.24;




contract BasicCrowdsale is MintedCrowdsale, FinalizableCrowdsale {
    
    uint256 public cap = 100000000 * (10 ** 18);  
    uint256 public capForSale = 71000000 * (10 ** 18);  
    uint256 public bountyTokensCap = 5000000 * (10 ** 18);  
    uint256 public reservedForTeamTokens = 29000000 * (10 ** 18);  
    uint256 public totalMintedBountyTokens;  

    uint256 public privateSaleEndDate;
    mapping (address => bool) public minters;

    uint256 constant MIN_CONTRIBUTION_AMOUNT = 10 finney;
    uint256 constant MAX_CONTRIBUTION_AMOUNT = 250 ether;

    uint256 public constant PRIVATE_SALE_CAP = 26000000 * (10 ** 18);
    uint256 public constant PRIVATE_SALE_DURATION = 24 days;  

    uint256 public constant MAIN_SALE_DURATION = 60 days;
    uint256 public mainSaleDurationExtentionLimitInDays = 120;  

    event LogFiatTokenMinted(address sender, address beficiary, uint256 amount);
    event LogFiatTokenMintedToMany(address sender, address[] beneficiaries, uint256[] amount);
    event LogBountyTokenMinted(address minter, address beneficiary, uint256 amount);
    event LogBountyTokenMintedToMany(address sender, address[] beneficiaries, uint256[] amount);
    event LogPrivateSaleExtended(uint256 extentionInDays);
    event LogMainSaleExtended(uint256 extentionInDays);
    event LogRateChanged(uint256 rate);
    event LogMinterAdded(address minterAdded);
    event LogMinterRemoved(address minterRemoved);

    constructor(uint256 _rate, address _wallet, address _token, uint256 _openingTime, uint256 _closingTime)
    Crowdsale(_rate, _wallet, ERC20(_token))
    TimedCrowdsale(_openingTime, _closingTime) public {
        privateSaleEndDate = _openingTime.add(PRIVATE_SALE_DURATION);
    }

     
    modifier onlyMinter (){
        require(minters[msg.sender]);
        _;
    }

    function buyTokens(address beneficiary) public payable {
        require(msg.value >= MIN_CONTRIBUTION_AMOUNT);
        require(msg.value <= MAX_CONTRIBUTION_AMOUNT);
        uint amount = _getTokenAmount(msg.value);
        if(now <= privateSaleEndDate) {
            require(MintableToken(token).totalSupply().add(amount) < PRIVATE_SALE_CAP);
        }
        
        require(MintableToken(token).totalSupply().add(amount) <= capForSale);
        super.buyTokens(beneficiary);
    }

    function addMinter(address _minter) public onlyOwner {
        require(_minter != address(0));
        minters[_minter] = true;
        emit LogMinterAdded(_minter);
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
        emit LogMinterRemoved(_minter);
    }

    function createFiatToken(address beneficiary, uint256 amount) public onlyMinter() returns(bool){
        require(!hasClosed());
        mintFiatToken(beneficiary, amount);
        emit LogFiatTokenMinted(msg.sender, beneficiary, amount);
        return true;
    }

    function createFiatTokenToMany(address[] beneficiaries, uint256[] amount) public onlyMinter() returns(bool){
        multiBeneficiariesValidation(beneficiaries, amount);
        for(uint i = 0; i < beneficiaries.length; i++){
            mintFiatToken(beneficiaries[i], amount[i]);
        } 
        emit LogFiatTokenMintedToMany(msg.sender, beneficiaries, amount);
        return true;
    }

    function mintFiatToken(address beneficiary, uint256 amount) internal {
        require(MintableToken(token).totalSupply().add(amount) <= capForSale);
        MintableToken(token).mint(beneficiary, amount);
    }

    function createBountyToken(address beneficiary, uint256 amount) public onlyMinter() returns (bool) {
        require(!hasClosed());
        mintBountyToken(beneficiary, amount);
        emit LogBountyTokenMinted(msg.sender, beneficiary, amount);
        return true;
    }

    function createBountyTokenToMany(address[] beneficiaries, uint256[] amount) public onlyMinter() returns (bool) {
        multiBeneficiariesValidation(beneficiaries, amount);
        for(uint i = 0; i < beneficiaries.length; i++){
            mintBountyToken(beneficiaries[i], amount[i]);
        }
        
        emit LogBountyTokenMintedToMany(msg.sender, beneficiaries, amount);
        return true;
    }

    function mintBountyToken(address beneficiary, uint256 amount) internal {
        require(MintableToken(token).totalSupply().add(amount) <= capForSale);
        require(totalMintedBountyTokens.add(amount) <= bountyTokensCap);
        MintableToken(token).mint(beneficiary, amount);
        totalMintedBountyTokens = totalMintedBountyTokens.add(amount);
    }

    function multiBeneficiariesValidation(address[] beneficiaries, uint256[] amount) internal view {
        require(!hasClosed());
        require(beneficiaries.length > 0);
        require(beneficiaries.length == amount.length);
    }

     
    function extendPrivateSaleDuration(uint256 extentionInDays) public onlyOwner returns (bool) {
        require(now <= privateSaleEndDate);
        extentionInDays = extentionInDays.mul(1 days);  
        privateSaleEndDate = privateSaleEndDate.add(extentionInDays);
        closingTime = closingTime.add(extentionInDays);
        emit LogPrivateSaleExtended(extentionInDays);
        return true;
    }

     
    function extendMainSaleDuration(uint256 extentionInDays) public onlyOwner returns (bool) {
        require(now > privateSaleEndDate);
        require(!hasClosed());
        require(mainSaleDurationExtentionLimitInDays.sub(extentionInDays) >= 0);

        uint256 extention = extentionInDays.mul(1 days);  
        mainSaleDurationExtentionLimitInDays = mainSaleDurationExtentionLimitInDays.sub(extentionInDays);  
        closingTime = closingTime.add(extention);

        emit LogMainSaleExtended(extentionInDays);
        return true;
    }

    function changeRate(uint _newRate) public onlyOwner returns (bool) {
        require(!hasClosed());
        require(_newRate != 0);
        rate = _newRate;
        emit LogRateChanged(_newRate);
        return true;
    }

     
    function finalization() internal {
        MintableToken(token).transferOwnership(owner);
        super.finalization();
    }
}

 

pragma solidity ^0.4.24;



 
contract MultipleWhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;
   
  mapping(address => bool) public whitelistManagers;

  constructor() public {
      whitelistManagers[owner] = true;
  }

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  modifier onlyWhitelistManager(){
      require(whitelistManagers[msg.sender]);
      _;
  }

   
  function addWhitelistManager(address _manager) public onlyOwner {
      require(_manager != address(0));
      whitelistManagers[_manager] = true;
  }

   

  function removeWhitelistManager(address _manager) public onlyOwner {
      whitelistManagers[_manager] = false;
  }

   
  function addToWhitelist(address _beneficiary) external onlyWhitelistManager() {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyWhitelistManager() {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyWhitelistManager() {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

pragma solidity ^0.4.24;




contract WhitelistedBasicCrowdsale is BasicCrowdsale, MultipleWhitelistedCrowdsale {


    constructor(uint256 _rate, address _wallet, address _token, uint256 _openingTime, uint256 _closingTime)
    BasicCrowdsale(_rate, _wallet, ERC20(_token), _openingTime, _closingTime)
    MultipleWhitelistedCrowdsale()
    public {
    }
}