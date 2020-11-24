 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
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

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

   
  IERC20 private _token;

   
  address private _wallet;

   
   
   
   
  uint256 private _rate;

   
  uint256 private _weiRaised;

   
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

   
  function token() public view returns(IERC20) {
    return _token;
  }

   
  function wallet() public view returns(address) {
    return _wallet;
  }

   
  function rate() public view returns(uint256) {
    return _rate;
  }

   
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
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
    _token.safeTransfer(beneficiary, tokenAmount);
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

  uint256 private _openingTime;
  uint256 private _closingTime;

   
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

   
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

   
  function closingTime() public view returns(uint256) {
    return _closingTime;
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

 

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

   
  function withdrawTokens(address beneficiary) public {
    require(hasClosed());
    uint256 amount = _balances[beneficiary];
    require(amount > 0);
    _balances[beneficiary] = 0;
    _deliverTokens(beneficiary, amount);
  }

   
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
  }

}

 

 
contract FinalizableCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  bool private _finalized = false;

  event CrowdsaleFinalized();

   
  function finalized() public view returns (bool) {
    return _finalized;
  }

   
  function finalize() public {
    require(!_finalized);
    require(hasClosed());

    _finalization();
    emit CrowdsaleFinalized();

    _finalized = true;
  }

   
  function _finalization() internal {
  }

}

 

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

contract Whitelist is Ownable {

  mapping (address => bool) private whitelistedAddresses;

  mapping (address => bool) private admins;

  modifier onlyIfWhitelisted(address _addr) {
    require(whitelistedAddresses[_addr] == true, "Address not on the whitelist!");
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender] == true || isOwner(), "Not an admin!");
    _;
  }

  function addAdmin(address _addr)
    external
    onlyOwner
  {
    admins[_addr] = true;
  }

  function removeAdmin(address _addr)
    external
    onlyOwner
  {
    admins[_addr] = false;
  }

  function isAdmin(address _addr)
    public
    view
    returns(bool)
  {
    return admins[_addr];
  }

  function addAddressToWhitelist(address _addr)
    public
    onlyAdmins
  {
    whitelistedAddresses[_addr] = true;
  }

  function whitelist(address _addr)
    public
    view
    returns(bool)
  {
    return whitelistedAddresses[_addr];
  }

  function addAddressesToWhitelist(address[] _addrs)
    public
    onlyAdmins
  {
    for (uint256 i = 0; i < _addrs.length; i++) {
      addAddressToWhitelist(_addrs[i]);
    }
  }

  function removeAddressFromWhitelist(address _addr)
    public
    onlyAdmins
  {
    whitelistedAddresses[_addr] = false;
  }

  function removeAddressesFromWhitelist(address[] _addrs)
    public
    onlyAdmins
  {
    for (uint256 i = 0; i < _addrs.length; i++) {
      removeAddressFromWhitelist(_addrs[i]);
    }
  }
}

 

contract ClarityCrowdsale is
  Crowdsale,
  TimedCrowdsale,
  PostDeliveryCrowdsale,
  FinalizableCrowdsale,
  Whitelist
{

  address private advisorWallet;  

  uint256 private phaseOneRate;  

  uint256 private phaseTwoRate;  

  uint256 private phaseOneTokens = 10000000 * 10**18;  

  uint256 private phaseTwoTokens = 30000000 * 10**18;  

  mapping  (address => address) referrals;  

  modifier onlyFounders() {
    require(msg.sender == super.wallet() || isOwner(), "Not a founder!");
    _;
  }

  constructor(
    uint256 _phaseOneRate,
    uint256 _phaseTwoRate,
    address _advisorWallet,
    address _founderWallet,
    uint256 _openingTime,
    uint256 _closingTime,
    IERC20 _token
  )
    Crowdsale(_phaseTwoRate, _founderWallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    public
  {
      advisorWallet = _advisorWallet;
      phaseOneRate = _phaseOneRate;
      phaseTwoRate = _phaseTwoRate;
  }

   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    if (phaseOneTokens > 0) {
      uint256 tokens = weiAmount.mul(phaseOneRate);
      if (tokens > phaseOneTokens) {
        uint256 weiRemaining = tokens.sub(phaseOneTokens).div(phaseOneRate);
        tokens = phaseOneTokens.add(super._getTokenAmount(weiRemaining));
      }
      return tokens;
    }

    return super._getTokenAmount(weiAmount);
  }

   
  function _forwardFunds()
    internal
  {
    uint256 tokens;
    if (phaseOneTokens > 0) {
      tokens = msg.value.mul(phaseOneRate);
      if (tokens > phaseOneTokens) {
        uint256 weiRemaining = tokens.sub(phaseOneTokens).div(phaseOneRate);
        phaseOneTokens = 0;
        advisorWallet.transfer(msg.value.sub(weiRemaining));
        tokens = weiRemaining.mul(phaseTwoRate);
        phaseTwoTokens = phaseTwoTokens.sub(tokens);
        super.wallet().transfer(weiRemaining);
      } else {
        phaseOneTokens = phaseOneTokens.sub(tokens);
        advisorWallet.transfer(msg.value);
      }
      return;
    }

    tokens = msg.value.mul(phaseTwoRate);
    phaseTwoTokens = phaseTwoTokens.sub(tokens);
    super._forwardFunds();
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyIfWhitelisted(beneficiary)
  {
    require(tokensLeft() >= _getTokenAmount(weiAmount), "Insufficient number of tokens to complete purchase!");
    super._preValidatePurchase(beneficiary, weiAmount);
  }

   
  function _finalization()
    internal
    onlyFounders
  {
    super.token().safeTransfer(super.wallet(), tokensLeft());
    super._finalization();
  }

  function tokensLeft()
    public
    view
    returns (uint256)
  {
    return phaseOneTokens + phaseTwoTokens;
  }

  function addReferral(address beneficiary, address referrer)
    external
    onlyAdmins
    onlyIfWhitelisted(referrer)
    onlyIfWhitelisted(beneficiary)
  {
    referrals[beneficiary] = referrer;
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    if (referrals[beneficiary] != 0) {
      uint256 tokensAvailable = tokensLeft().sub(tokenAmount);
      uint256 bonus = tokenAmount.mul(15).div(100);
      if (bonus >= tokensAvailable) {
        bonus = tokensAvailable;
        phaseTwoTokens = phaseTwoTokens.sub(tokensAvailable);
      } else {
        phaseTwoTokens = phaseTwoTokens.sub(bonus);
      }

      if (bonus > 0) {
        super._processPurchase(referrals[beneficiary], bonus);
      }
    }

    super._processPurchase(beneficiary, tokenAmount);
  }
}