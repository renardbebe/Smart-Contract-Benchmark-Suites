 

pragma solidity ^0.4.23;


 
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



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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




contract Distributable {

  using SafeMath for uint256;

  bool public distributed;
   
  address[] public partners = [
  0xb68342f2f4dd35d93b88081b03a245f64331c95c,
  0x16CCc1e68D2165fb411cE5dae3556f823249233e,
  0x8E176EDA10b41FA072464C29Eb10CfbbF4adCd05,  
  0x7c387c57f055993c857067A0feF6E81884656Cb0,  
  0x4F21c073A9B8C067818113829053b60A6f45a817,  
  0xcB4b6B7c4a72754dEb99bB72F1274129D9C0A109,  
  0x7BF84E0244c05A11c57984e8dF7CC6481b8f4258,  
  0x20D2F4Be237F4320386AaaefD42f68495C6A3E81,  
  0x12BEA633B83aA15EfF99F68C2E7e14f2709802A9,  
  0xC1a29a165faD532520204B480D519686B8CB845B,  
  0xf5f5Eb6Ab1411935b321042Fa02a433FcbD029AC,  
  0xaBff978f03d5ca81B089C5A2Fc321fB8152DC8f1];  

  address[] public partnerFixedAmount = [
  0xA482D998DA4d361A6511c6847562234077F09748,
  0xFa92F80f8B9148aDFBacC66aA7bbE6e9F0a0CD0e
  ];

  mapping(address => uint256) public percentages;
  mapping(address => uint256) public fixedAmounts;

  constructor() public{
    percentages[0xb68342f2f4dd35d93b88081b03a245f64331c95c] = 40;
    percentages[0x16CCc1e68D2165fb411cE5dae3556f823249233e] = 5;
    percentages[0x8E176EDA10b41FA072464C29Eb10CfbbF4adCd05] = 100;  
    percentages[0x7c387c57f055993c857067A0feF6E81884656Cb0] = 50;  
    percentages[0x4F21c073A9B8C067818113829053b60A6f45a817] = 10;  

    percentages[0xcB4b6B7c4a72754dEb99bB72F1274129D9C0A109] = 20;  
    percentages[0x7BF84E0244c05A11c57984e8dF7CC6481b8f4258] = 20;  
    percentages[0x20D2F4Be237F4320386AaaefD42f68495C6A3E81] = 20;  
    percentages[0x12BEA633B83aA15EfF99F68C2E7e14f2709802A9] = 20;  

    percentages[0xC1a29a165faD532520204B480D519686B8CB845B] = 30;  
    percentages[0xf5f5Eb6Ab1411935b321042Fa02a433FcbD029AC] = 30;  

    percentages[0xaBff978f03d5ca81B089C5A2Fc321fB8152DC8f1] = 52;  

    fixedAmounts[0xA482D998DA4d361A6511c6847562234077F09748] = 886228 * 10**16;
    fixedAmounts[0xFa92F80f8B9148aDFBacC66aA7bbE6e9F0a0CD0e] = 697 ether;
  }
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







 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}





contract SolidToken is MintableToken {

  string public constant name = "SolidToken";
  string public constant symbol = "SOLID";
  uint8  public constant decimals = 18;

  uint256 constant private DECIMAL_PLACES = 10 ** 18;
  uint256 constant SUPPLY_CAP = 4000000 * DECIMAL_PLACES;

  bool public transfersEnabled = false;
  uint256 public transferEnablingDate;


   
  function setTransferEnablingDate(uint256 date) public onlyOwner returns(bool success) {
    transferEnablingDate = date;
    return true;
  }


   
  function enableTransfer() public {
    require(transferEnablingDate != 0 && now >= transferEnablingDate);
    transfersEnabled = true;
  }



   
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= SUPPLY_CAP);
    require(super.mint(_to, _amount));
    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(transfersEnabled, "Tranfers are disabled");
    require(super.transfer(_to, _value));
    return true;
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(transfersEnabled, "Tranfers are disabled");
    require(super.transferFrom(_from, _to, _value));
    return true;
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


contract TokenSale is MintedCrowdsale, WhitelistedCrowdsale, Pausable, Distributable {

   
  mapping(address => uint256) public contributions;
  Stages public currentStage;

   
  uint256 constant MINIMUM_CONTRIBUTION = 0.5 ether;   
  uint256 constant MAXIMUM_CONTRIBUTION = 100 ether;   
  uint256 constant BONUS_PERCENT = 250;                 
  uint256 constant TOKENS_ON_SALE_PERCENT = 600;        
  uint256 constant BONUSSALE_MAX_DURATION = 30 days ;
  uint256 constant MAINSALE_MAX_DURATION = 62 days;
  uint256 constant TOKEN_RELEASE_DELAY = 182 days;
  uint256 constant HUNDRED_PERCENT = 1000;             

   
  uint256 public bonussale_Cap = 14400 ether;
  uint256 public bonussale_TokenCap = 1200000 ether;

  uint256 public bonussale_StartDate;
  uint256 public bonussale_EndDate;
  uint256 public bonussale_TokesSold;
  uint256 public bonussale_WeiRaised;

   
  uint256 public mainSale_Cap = 18000 ether;
  uint256 public mainSale_TokenCap = 1200000 ether;

  uint256 public mainSale_StartDate;
  uint256 public mainSale_EndDate;
  uint256 public mainSale_TokesSold;
  uint256 public mainSale_WeiRaised;


   
  uint256 private changeDue;
  bool private capReached;

  enum Stages{
    SETUP,
    READY,
    BONUSSALE,
    MAINSALE,
    FINALIZED
  }

   

   
  modifier atStage(Stages _currentStage){
      require(currentStage == _currentStage);
      _;
  }

   
  modifier timedTransition(){
    if(currentStage == Stages.READY && now >= bonussale_StartDate){
      currentStage = Stages.BONUSSALE;
    }
    if(currentStage == Stages.BONUSSALE && now > bonussale_EndDate){
      finalizePresale();
    }
    if(currentStage == Stages.MAINSALE && now > mainSale_EndDate){
      finalizeSale();
    }
    _;
  }


   

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public Crowdsale(_rate,_wallet,_token) {
    require(_rate == 15);
    currentStage = Stages.SETUP;
  }


   

   
  function setupSale(uint256 initialDate, address tokenAddress) onlyOwner atStage(Stages.SETUP) public {
    bonussale_StartDate = initialDate;
    bonussale_EndDate = bonussale_StartDate + BONUSSALE_MAX_DURATION;
    token = ERC20(tokenAddress);

    require(SolidToken(tokenAddress).totalSupply() == 0, "Tokens have already been distributed");
    require(SolidToken(tokenAddress).owner() == address(this), "Token has the wrong ownership");

    currentStage = Stages.READY;
  }


   

   
  function getCurrentCap() public view returns(uint256 cap){
    cap = bonussale_Cap;
    if(currentStage == Stages.MAINSALE){
      cap = mainSale_Cap;
    }
  }

   
  function getRaisedForCurrentStage() public view returns(uint256 raised){
    raised = bonussale_WeiRaised;
    if(currentStage == Stages.MAINSALE)
      raised = mainSale_WeiRaised;
  }

   
  function saleOpen() public timedTransition whenNotPaused returns(bool open) {
    open = ((now >= bonussale_StartDate && now < bonussale_EndDate) ||
           (now >= mainSale_StartDate && now <   mainSale_EndDate)) &&
           (currentStage == Stages.BONUSSALE || currentStage == Stages.MAINSALE);
  }



   

   
  function distributeTokens() public onlyOwner atStage(Stages.FINALIZED) {
    require(!distributed);
    distributed = true;

    uint256 totalTokens = (bonussale_TokesSold.add(mainSale_TokesSold)).mul(HUNDRED_PERCENT).div(TOKENS_ON_SALE_PERCENT);  
    for(uint i = 0; i < partners.length; i++){
      uint256 amount = percentages[partners[i]].mul(totalTokens).div(HUNDRED_PERCENT);
      _deliverTokens(partners[i], amount);
    }
    for(uint j = 0; j < partnerFixedAmount.length; j++){
      _deliverTokens(partnerFixedAmount[j], fixedAmounts[partnerFixedAmount[j]]);
    }
    require(SolidToken(token).finishMinting());
  }

   
  function finalizePresale() atStage(Stages.BONUSSALE) internal{
    bonussale_EndDate = now;
    mainSale_StartDate = now;
    mainSale_EndDate = mainSale_StartDate + MAINSALE_MAX_DURATION;
    mainSale_TokenCap = mainSale_TokenCap.add(bonussale_TokenCap.sub(bonussale_TokesSold));
    mainSale_Cap = mainSale_Cap.add(bonussale_Cap.sub(weiRaised.sub(changeDue)));
    currentStage = Stages.MAINSALE;
  }

   
  function finalizeSale() atStage(Stages.MAINSALE) internal {
    mainSale_EndDate = now;
    require(SolidToken(token).setTransferEnablingDate(now + TOKEN_RELEASE_DELAY));
    currentStage = Stages.FINALIZED;
  }

   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) isWhitelisted(_beneficiary) internal {
    require(_beneficiary == msg.sender);
    require(saleOpen(), "Sale is Closed");

     
    uint256 acceptedValue = _weiAmount;
    uint256 currentCap = getCurrentCap();
    uint256 raised = getRaisedForCurrentStage();

    if(contributions[_beneficiary].add(acceptedValue) > MAXIMUM_CONTRIBUTION){
      changeDue = (contributions[_beneficiary].add(acceptedValue)).sub(MAXIMUM_CONTRIBUTION);
      acceptedValue = acceptedValue.sub(changeDue);
    }

    if(raised.add(acceptedValue) >= currentCap){
      changeDue = changeDue.add(raised.add(acceptedValue).sub(currentCap));
      acceptedValue = _weiAmount.sub(changeDue);
      capReached = true;
    }
    require(capReached || contributions[_beneficiary].add(acceptedValue) >= MINIMUM_CONTRIBUTION ,"Contribution below minimum");
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 amount) {
    amount = (_weiAmount.sub(changeDue)).mul(HUNDRED_PERCENT).div(rate);  
    if(currentStage == Stages.BONUSSALE){
      amount = amount.add(amount.mul(BONUS_PERCENT).div(HUNDRED_PERCENT));  
    }
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    if(currentStage == Stages.MAINSALE && capReached) finalizeSale();
    if(currentStage == Stages.BONUSSALE && capReached) finalizePresale();


     
    changeDue = 0;
    capReached = false;

  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    uint256 tokenAmount = _getTokenAmount(_weiAmount);

    if(currentStage == Stages.BONUSSALE){
      bonussale_TokesSold = bonussale_TokesSold.add(tokenAmount);
      bonussale_WeiRaised = bonussale_WeiRaised.add(_weiAmount.sub(changeDue));
    } else {
      mainSale_TokesSold = mainSale_TokesSold.add(tokenAmount);
      mainSale_WeiRaised = mainSale_WeiRaised.add(_weiAmount.sub(changeDue));
    }

    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount).sub(changeDue);
    weiRaised = weiRaised.sub(changeDue);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value.sub(changeDue));
    msg.sender.transfer(changeDue);  
  }

}