 

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

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

}


 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
 function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

   
  IERC20 public _token;

   
  address public _wallet;

   
   
   
   
  uint256 public _rate;

   
  uint256 public _weiRaised;

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 rate, address wallet, IERC20 token) public {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.transferFrom(owner,beneficiary, tokenAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

   
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}


 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public _openingTime;
  uint256 public _closingTime;

   
  modifier onlyWhileOpen {
    require(isOpen());
    _;
  }

   
  constructor(uint256 openingTime, uint256 closingTime) public {
     
    require(openingTime >= block.timestamp);
    require(closingTime >= openingTime);

    _openingTime = openingTime;
    _closingTime = closingTime;
  }


   
  function isOpen() public view returns (bool) {
     
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > _closingTime;
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

 
contract EscrowAccountCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;
  EscrowVault public vault;
   
  function EscrowAccountCrowdsale() public {
    vault = new EscrowVault(_wallet);
  }
   
  function returnInvestoramount(address _beneficiary, uint256 _percentage) internal onlyOwner {
    vault.refund(_beneficiary);
  }

  
  function adminChargeForDebit(address _beneficiary, uint256 _adminCharge) internal onlyOwner {
    vault.debitForFailed(_beneficiary,_adminCharge);
  }

  function afterWhtelisted(address _beneficiary) internal onlyOwner{
      vault.closeAfterWhitelisted(_beneficiary);
  }
  
  function afterWhtelistedBuy(address _beneficiary) internal {
      vault.closeAfterWhitelisted(_beneficiary);
  }
   
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

 
contract EscrowVault is Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) public deposited;
  address public wallet;
  event Closed();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
   
  function EscrowVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;   
  }
   
  function deposit(address investor) onlyOwner  payable {
    deposited[investor] = deposited[investor].add(msg.value);
  }
  
   
  function closeAfterWhitelisted(address _beneficiary) onlyOwner public { 
    uint256 depositedValue = deposited[_beneficiary];
    deposited[_beneficiary] = 0;
    wallet.transfer(depositedValue);
  }
  
   
  function debitForFailed(address investor, uint256 _debit)public onlyOwner  {
     uint256 depositedValue = deposited[investor];
     depositedValue=depositedValue.sub(_debit);
     wallet.transfer(_debit);
     deposited[investor] = depositedValue;
  }
   
   
  function refund(address investor)public onlyOwner  {
    uint256 depositedValue = deposited[investor];
    investor.transfer(depositedValue);
     emit Refunded(investor, depositedValue);
     deposited[investor] = 0;
  }
}

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public _balances;

   
  function withdrawTokens() public {
   require(hasClosed());
    uint256 amount = _balances[msg.sender];
    require(amount > 0);
    _balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }
  
    
    
   function failedWhitelistForDebit(address _beneficiary,uint256 _token) internal  {
    require(_beneficiary != address(0));
    uint256 amount = _balances[_beneficiary];
    _balances[_beneficiary] = amount.sub(_token);
  }
  
    
   function failedWhitelist(address _beneficiary) internal  {
    require(_beneficiary != address(0));
    uint256 amount = _balances[_beneficiary];
    _balances[_beneficiary] = 0;
  }
  
  function getInvestorDepositAmount(address _investor) public constant returns(uint256 paid){
     return _balances[_investor];
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _balances[_beneficiary] = _balances[_beneficiary].add(_tokenAmount);
  }

}


contract BitcoinageCrowdsale is TimedCrowdsale,EscrowAccountCrowdsale,PostDeliveryCrowdsale {

 enum Stage {KYC_FAILED, KYC_SUCCESS,AML_FAILED, AML_SUCCESS} 	
   
  enum Phase {PRESALE, PUBLICSALE}
   
  Phase public phase;
 
  uint256 private constant DECIMALFACTOR = 10**uint256(18);
  uint256 public _totalSupply=200000000 * DECIMALFACTOR;
  uint256 public presale=5000000* DECIMALFACTOR;
  uint256 public publicsale=110000000* DECIMALFACTOR;
  uint256 public teamAndAdvisorsAndBountyAllocation = 12000000 * DECIMALFACTOR;
  uint256 public operatingBudgetAllocation = 5000000 * DECIMALFACTOR;
  uint256 public tokensVested = 28000000 * DECIMALFACTOR;
 
  struct whitelisted{
       Stage  stage;
 }
  uint256 public adminCharge=0.025 ether;
  uint256 public minContribAmount = 0.2 ether;  
  mapping(address => whitelisted) public whitelist;
   
  mapping (address => uint256) public investedAmountOf;
     
  uint256 public investorCount;
     
 
  event updateRate(uint256 tokenRate, uint256 time);
  
    
  
 function BitcoinageCrowdsale(uint256 _starttime, uint256 _endTime, uint256 _rate, address _wallet,IERC20 _token)
  TimedCrowdsale(_starttime,_endTime)Crowdsale(_rate, _wallet,_token)
  {
      phase = Phase.PRESALE;
  }
    
   
  function () external payable {
    buyTokens(msg.sender);
  }
  
   
  function buyTokens(address _beneficiary) public payable onlyWhileOpen{
    require(_beneficiary != address(0));
    require(validPurchase());
  
    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(_rate);
     if(phase==Phase.PRESALE){
        assert(presale>=tokens);
        presale=presale.sub(tokens);
    }else{
        assert(publicsale>=tokens);
        publicsale=publicsale.sub(tokens);
    }
    
     _forwardFunds();
         _processPurchase(_beneficiary, tokens);
    if(investedAmountOf[msg.sender] == 0) {
            
           investorCount++;
        }
         
      investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiAmount);
        
      if(whitelist[_beneficiary].stage==Stage.AML_SUCCESS){
                afterWhtelistedBuy(_beneficiary);
      }
      
  }
   
    function validPurchase() internal constant returns (bool) {
    bool minContribution = minContribAmount <= msg.value;
    return  minContribution;
  }
  


  
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary].stage==Stage.AML_SUCCESS);
    _;
  }

   
  function addToWhitelist(address _beneficiary,uint256 _stage) external onlyOwner {
     require(_beneficiary != address(0));
     if(_stage==1){
         
         failedWhitelistForDebit(_beneficiary,_rate.mul(adminCharge));
         adminChargeForDebit(_beneficiary,adminCharge);
         whitelist[_beneficiary].stage=Stage.KYC_FAILED;
         uint256 value=investedAmountOf[_beneficiary];
         value=value.sub(adminCharge);
         investedAmountOf[_beneficiary]=value;
         
     }else if(_stage==2){
         
         whitelist[_beneficiary].stage=Stage.KYC_SUCCESS;
         
     }else if(_stage==3){
         
         whitelist[_beneficiary].stage=Stage.AML_FAILED;
         returnInvestoramount(_beneficiary,adminCharge);
         failedWhitelist(_beneficiary);
         investedAmountOf[_beneficiary]=0;
         
     }else if(_stage==4){
         
         whitelist[_beneficiary].stage=Stage.AML_SUCCESS;
         afterWhtelisted( _beneficiary); 
    
     }
  }
 
   
  function withdrawTokens() public isWhitelisted(msg.sender)  {
    uint256 amount = _balances[msg.sender];
    require(amount > 0);
    _deliverTokens(msg.sender, amount);
    _balances[msg.sender] = 0;
  }
  
  
  function changeEndtime(uint256 _endTime) public onlyOwner {
    require(_endTime > 0); 
    _closingTime = _endTime;
  }
    
     
  function changeStarttime(uint256 _startTime) public onlyOwner {
    require(_startTime > 0); 
    _openingTime = _startTime;
  }
    
  
  function changeStage(uint256 _rate) public onlyOwner {
     require(_rate>0);
     _rate=_rate;
     phase=Phase.PUBLICSALE;
  }

  
  function changeRate(uint256 _rate) public onlyOwner {
    require(_rate > 0); 
    _rate = _rate;
    emit updateRate(_rate,block.timestamp);
  }
  
  
  function changeAdminCharge(uint256 _adminCharge) public onlyOwner {
     require(_adminCharge > 0);
     adminCharge=_adminCharge;
  }
  
    
  
  
    function transferTeamAndAdvisorsAndBountyAllocation  (address to, uint256 tokens) public onlyOwner {
         require (
            to != 0x0 && tokens > 0 && teamAndAdvisorsAndBountyAllocation >= tokens
         );
        _deliverTokens(to, tokens);
         teamAndAdvisorsAndBountyAllocation = teamAndAdvisorsAndBountyAllocation.sub(tokens);
    }
     
      
     
     function transferTokensVested(address to, uint256 tokens) public onlyOwner {
         require (
            to != 0x0 && tokens > 0 && tokensVested >= tokens
         );
        _deliverTokens(to, tokens);
         tokensVested = tokensVested.sub(tokens);
     }
     
       
     
     function transferOperatingBudgetAllocation(address to, uint256 tokens) public onlyOwner {
         require (
            to != 0x0 && tokens > 0 && operatingBudgetAllocation >= tokens
         );
        _deliverTokens(to, tokens);
         operatingBudgetAllocation = operatingBudgetAllocation.sub(tokens);
     }
}