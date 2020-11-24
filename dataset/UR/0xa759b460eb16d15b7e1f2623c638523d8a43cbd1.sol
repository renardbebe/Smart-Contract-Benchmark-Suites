 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract Crowdsale {
 using SafeMath for uint256;
 using SafeERC20 for ERC20;

  
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
   token.safeTransfer(_beneficiary, _tokenAmount);
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

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

contract WhitelistedCrowdsale is Whitelist, Crowdsale {
   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyIfWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract CbntCrowdsale is TimedCrowdsale, WhitelistedCrowdsale {
 using SafeMath for uint256;


 struct FutureTransaction{
   address beneficiary;
   uint256 num;
   uint32  times;
   uint256 lastTime;
 }
 FutureTransaction[] public futureTrans;
 uint256 public oweCbnt;

 uint256[] public rateSteps;
 uint256[] public rateStepsValue;
 uint32[] public regularTransTime;
 uint32 public transTimes;

 uint256 public minInvest;

 
 constructor(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _wallet, ERC20 _token) TimedCrowdsale(_openingTime,_closingTime) Crowdsale(_rate,_wallet, _token) public {
   
    
 }

  
 function triggerTransaction(uint256 beginIdx, uint256 endIdx) public returns (bool){
   uint32 regularTime = findRegularTime();
   require(regularTime > 0 && endIdx < futureTrans.length);

   bool bRemove = false;
   uint256 i = 0;
   for(i = beginIdx; i<=endIdx && i<futureTrans.length; ){
     bRemove = false;
     if(futureTrans[i].lastTime < regularTime){   
        uint256 transNum = futureTrans[i].num;
        address beneficiary = futureTrans[i].beneficiary;
         

        futureTrans[i].lastTime = now;
        futureTrans[i].times = futureTrans[i].times - 1;
        require(futureTrans[i].times <= transTimes);

         
        if(futureTrans[i].times ==0 ){
           bRemove = true;
           futureTrans[i].beneficiary = futureTrans[futureTrans.length -1].beneficiary;
           futureTrans[i].num = futureTrans[futureTrans.length -1].num;
           futureTrans[i].lastTime = futureTrans[futureTrans.length -1].lastTime;
           futureTrans[i].times = futureTrans[futureTrans.length -1].times;
           futureTrans.length = futureTrans.length.sub(1);
        }
            
        oweCbnt = oweCbnt.sub(transNum);
        _deliverTokens(beneficiary, transNum);
     }

     if(!bRemove){
       i++;
     }
   }

   return true;

 }
 function transferBonus(address _beneficiary, uint256 _tokenAmount) public onlyOwner returns(bool){
   _deliverTokens(_beneficiary, _tokenAmount);
   return true;
 }

  
 function setMinInvest(uint256 _minInvest) public onlyOwner returns (bool){
   minInvest = _minInvest;
   return true;
 }

  
 function setTransTimes(uint32 _times) public onlyOwner returns (bool){
   transTimes = _times;
   return true;
 }

 function setRegularTransTime(uint32[] _times) public onlyOwner returns (bool){
   for (uint256 i = 0; i + 1 < _times.length; i++) {
       require(_times[i] < _times[i+1]);
   }

   regularTransTime = _times;
   return true;
 }

  
 function setRateSteps(uint256[] _steps, uint256[] _stepsValue) public onlyOwner returns (bool){
   require(_steps.length == _stepsValue.length);
   for (uint256 i = 0; i + 1 < _steps.length; i++) {
       require(_steps[i] > _steps[i+1]);
   }

   rateSteps = _steps;
   rateStepsValue = _stepsValue;
   return true;
 }

  
 function normalCheck() public view returns (bool){
   return (transTimes > 0 && regularTransTime.length > 0 && minInvest >0 && rateSteps.length >0);
 }

 function getFutureTransLength() public view returns(uint256) {
     return futureTrans.length;
 }
 function getFutureTransByIdx(uint256 _idx) public view returns(address,uint256, uint32, uint256) {
     return (futureTrans[_idx].beneficiary, futureTrans[_idx].num, futureTrans[_idx].times, futureTrans[_idx].lastTime);
 }
 function getFutureTransIdxByAddress(address _beneficiary) public view returns(uint256[]) {
     uint256 i = 0;
     uint256 num = 0;
     for(i=0; i<futureTrans.length; i++){
       if(futureTrans[i].beneficiary == _beneficiary){
           num++;
       }
     }
     uint256[] memory transList = new uint256[](num);

     uint256 idx = 0;
     for(i=0; i<futureTrans.length; i++){
       if(futureTrans[i].beneficiary == _beneficiary){
         transList[idx] = i;
         idx++;
       }
     }
     return transList;
 }

  
  
 function getCurrentRate(uint256 _weiAmount) public view returns (uint256) {
   for (uint256 i = 0; i < rateSteps.length; i++) {
       if (_weiAmount >= rateSteps[i]) {
           return rateStepsValue[i];
       }
   }
   return 0;
 }

  
 function _getTokenAmount(uint256 _weiAmount)
   internal view returns (uint256)
 {
   uint256 currentRate = getCurrentRate(_weiAmount);
   return currentRate.mul(_weiAmount).div(transTimes);
 }

  
 function _preValidatePurchase(
   address _beneficiary,
   uint256 _weiAmount
 )
   internal
 {
   require(msg.value >= minInvest);
   super._preValidatePurchase(_beneficiary, _weiAmount);
 }

  
 function _processPurchase(
   address _beneficiary,
   uint256 _tokenAmount
 )
   internal
 {
    
   FutureTransaction memory tran = FutureTransaction(_beneficiary, _tokenAmount, transTimes-1, now);  
   futureTrans.push(tran);

    
   oweCbnt = oweCbnt.add(_tokenAmount.mul(tran.times));
   super._processPurchase(_beneficiary, _tokenAmount);
 }

 function findRegularTime() internal view returns (uint32) {
   if(now < regularTransTime[0]){
     return 0;
   }

   uint256 i = 0;
   while(i<regularTransTime.length && now >= regularTransTime[i]){
     i++;
   }

   return regularTransTime[i -1];

 }

}