 

pragma solidity 0.4.25;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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
    emit OwnershipTransferred(_owner, address(0));
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

 

 
pragma solidity 0.4.25;

 


contract MultiOwnable is Ownable {
	 
	mapping (address => bool) additionalOwners;

	 
	modifier onlyOwner() {
		 
		require(isOwner(msg.sender), "Permission denied [owner].");
		_;
	}

	 
	modifier onlyMaster() {
		 
		require(super.isOwner(), "Permission denied [master].");
		_;
	}

	 
	event OwnershipAdded (
		address indexed addedOwner
	);
	
	 
	event OwnershipRemoved (
		address indexed removedOwner
	);

  	 
	constructor() 
	Ownable()
	public
	{
		 
		address masterOwner = owner();
		 
		additionalOwners[masterOwner] = true;
	}

	 
	function isOwner(address _ownerAddressToLookup)
	public
	view
	returns (bool)
	{
		 
		return additionalOwners[_ownerAddressToLookup];
	}

	 
	function isMaster(address _masterAddressToLookup)
	public
	view
	returns (bool)
	{
		return (super.owner() == _masterAddressToLookup);
	}

	 
	function addOwner(address _ownerToAdd)
	onlyMaster
	public
	returns (bool)
	{
		 
		require(_ownerToAdd != address(0), "Invalid address specified (0x0)");
		 
		require(!isOwner(_ownerToAdd), "Address specified already in owners list.");
		 
		additionalOwners[_ownerToAdd] = true;
		emit OwnershipAdded(_ownerToAdd);
		return true;
	}

	 
	function removeOwner(address _ownerToRemove)
	onlyMaster
	public
	returns (bool)
	{
		 
		require(_ownerToRemove != super.owner(), "Permission denied [master].");
		 
		require(isOwner(_ownerToRemove), "Address specified not found in owners list.");
		 
		additionalOwners[_ownerToRemove] = false;
		emit OwnershipRemoved(_ownerToRemove);
		return true;
	}

	 
	function transferOwnership(address _newOwnership) 
	onlyMaster 
	public 
	{
		 
		require(_newOwnership != address(0), "Invalid address specified (0x0)");
		 
		require(_newOwnership != owner(), "Address specified must not match current owner address.");		
		 
		require(isOwner(_newOwnership), "Master ownership can only be transferred to an existing owner address.");
		 
		super.transferOwnership(_newOwnership);
		 
		 
		additionalOwners[_newOwnership] = true;
	}

}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
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

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

 
library SafeERC20 {

  using SafeMath for uint256;

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
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

 

 
contract Crowdsale is ReentrancyGuard {
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

   
  constructor(uint256 rate, address wallet, IERC20 token) internal {
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

   
  function buyTokens(address beneficiary) public nonReentrant payable {

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
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
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

   
  constructor(uint256 openingTime, uint256 closingTime) internal {
     
    require(openingTime >= block.timestamp);
    require(closingTime > openingTime);

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
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

 

 
contract SparkleBaseCrowdsale is MultiOwnable, Pausable, TimedCrowdsale {
	using SafeMath for uint256;

	 
	enum CrowdsaleStage { 
		preICO, 
		bonusICO, 
		mainICO
	}

 	 
	ERC20   public tokenAddress;
	uint256 public tokenRate;
	uint256 public tokenCap;
	uint256 public startTime;
	uint256 public endTime;
	address public depositWallet;
	bool    public kycRequired;	
	bool	public refundRemainingOk;

	uint256 public tokensSold;

	 
	struct OrderBook {
		uint256 weiAmount;    
		uint256 pendingTokens;  
		bool    kycVerified;    
	}

	 
	mapping(address => OrderBook) private orders;

	 
	CrowdsaleStage public crowdsaleStage = CrowdsaleStage.preICO;

	 
	event ApprovedKYCAddresses (address indexed _appovedByAddress, uint256 _numberOfApprovals);

	 
	event RevokedKYCAddresses (address indexed _revokedByAddress, uint256 _numberOfRevokals);

	 
	event TokensClaimed (address indexed _claimingAddress, uint256 _tokensClaimed);

	 
	event TokensSold(address indexed _beneficiary, uint256 _tokensSold);

	 
	event TokenRefundApprovalChanged(address indexed _approvingAddress, bool tokenBurnApproved);

	 
	event CrowdsaleStageChanged(address indexed _changingAddress, uint _newStageValue);

	 
	event CrowdsaleTokensRefunded(address indexed _refundingToAddress, uint256 _numberOfTokensBurned);

	 
	constructor(ERC20 _tokenAddress, uint256 _tokenRate, uint256 _tokenCap, uint256 _startTime, uint256 _endTime, address _depositWallet, bool _kycRequired)
	public
	Crowdsale(_tokenRate, _depositWallet, _tokenAddress)
	TimedCrowdsale(_startTime, _endTime)
	MultiOwnable()
	Pausable()
	{ 
		tokenAddress      = _tokenAddress;
		tokenRate         = _tokenRate;
		tokenCap          = _tokenCap;
		startTime         = _startTime;
		endTime           = _endTime;
		depositWallet     = _depositWallet;
		kycRequired       = _kycRequired;
		refundRemainingOk = false;
	}

	 
	function claimTokens()
	whenNotPaused
	onlyWhileOpen
	public
	{
		 
		require(msg.sender != address(0), "Invalid address specified: address(0)");
		 
		OrderBook storage order = orders[msg.sender];
		 
		require(order.kycVerified, "Address attempting to claim tokens is not KYC Verified.");
		 
		require(order.pendingTokens > 0, "Address does not have any pending tokens to claim.");
		 
		uint256 localPendingTokens = order.pendingTokens;
		 
		order.pendingTokens = 0;
		 
		_deliverTokens(msg.sender, localPendingTokens);
		 
		emit TokensClaimed(msg.sender, localPendingTokens);
	}

	 
	function getExchangeRate(uint256 _weiAmount)
	whenNotPaused
	onlyWhileOpen
	public
	view
	returns (uint256)
	{
		if (crowdsaleStage == CrowdsaleStage.preICO) {
			 
			require(_weiAmount >= 1 ether, "PreICO minimum ether required: 1 ETH.");
		}
		else if (crowdsaleStage == CrowdsaleStage.bonusICO || crowdsaleStage == CrowdsaleStage.mainICO) {
			 
			require(_weiAmount >= 500 finney, "bonusICO/mainICO minimum ether required: 0.5 ETH.");
		}

		 
		uint256 tokenAmount = _getTokenAmount(_weiAmount);
		 
		require(getRemainingTokens() >= tokenAmount, "Specified wei value woudld exceed amount of tokens remaining.");
		 
		return tokenAmount;
	}

	 
	function getRemainingTokens()
	whenNotPaused
	public
	view
	returns (uint256)
	{
		 
		return tokenCap.sub(tokensSold);
	}

	 
	function refundRemainingTokens(address _addressToRefund)
	onlyOwner
	whenNotPaused
	public
	{
		 
		require(_addressToRefund != address(0), "Specified address is invalid [0x0]");
		 
		require(hasClosed(), "Crowdsale must be finished to burn tokens.");
		 
		require(refundRemainingOk, "Crowdsale remaining token refund is disabled.");
		uint256 tempBalance = token().balanceOf(this);
		 
		_deliverTokens(_addressToRefund, tempBalance);
		 
		emit CrowdsaleTokensRefunded(_addressToRefund, tempBalance);
	}

	 
	function approveRemainingTokenRefund()
	onlyOwner
	whenNotPaused
	public
	{
		 
		require(msg.sender != address(0), "Calling address invalid [0x0]");
		 
		require(hasClosed(), "Token burn approval can only be set after crowdsale closes");
		refundRemainingOk = true;
		emit TokenRefundApprovalChanged(msg.sender, refundRemainingOk);
	}

	 
	function changeCrowdsaleStage(uint _newStageValue)
	onlyOwner
	whenNotPaused
	onlyWhileOpen
	public
	{
		 
		CrowdsaleStage _stage;
		 
		if (uint(CrowdsaleStage.preICO) == _newStageValue) {
			 
			_stage = CrowdsaleStage.preICO;
		}
		 
		else if (uint(CrowdsaleStage.bonusICO) == _newStageValue) {
			 
			_stage = CrowdsaleStage.bonusICO;
		}
		 
		else if (uint(CrowdsaleStage.mainICO) == _newStageValue) {
			 
			_stage = CrowdsaleStage.mainICO;
		}
		else {
			revert("Invalid stage selected");
		}

		 
		crowdsaleStage = _stage;
		 
		emit CrowdsaleStageChanged(msg.sender, uint(_stage));
	}

	 
	function isKYCVerified(address _addressToLookuo) 
	whenNotPaused
	onlyWhileOpen
	public
	view
	returns (bool)
	{
		 
		require(_addressToLookuo != address(0), "Invalid address specified: address(0)");
		 
		OrderBook storage order = orders[_addressToLookuo];
		 
		return order.kycVerified;
	}

	 
	function bulkApproveKYCAddresses(address[] _addressesForApproval) 
	onlyOwner
	whenNotPaused
	onlyWhileOpen
	public
	{

		 
		require(_addressesForApproval.length > 0, "Specified address array is empty");
		 
		for (uint i = 0; i <_addressesForApproval.length; i++) {
			 
			_approveKYCAddress(_addressesForApproval[i]);
		}

		 
		emit ApprovedKYCAddresses(msg.sender, _addressesForApproval.length);
	}

	 
	function bulkRevokeKYCAddresses(address[] _addressesToRevoke) 
	onlyOwner
	whenNotPaused
	onlyWhileOpen
	public
	{
		 
		require(_addressesToRevoke.length > 0, "Specified address array is empty");
		 
		for (uint i = 0; i <_addressesToRevoke.length; i++) {
			 
			_revokeKYCAddress(_addressesToRevoke[i]);
		}

		 
		emit RevokedKYCAddresses(msg.sender, _addressesToRevoke.length);
	}

	 
	function tokensPending(address _addressToLookup)
	onlyOwner
	whenNotPaused
	onlyWhileOpen
	public
	view
	returns (uint256)
	{
		 
		require(_addressToLookup != address(0), "Specified address is invalid [0x0]");
		 
		OrderBook storage order = orders[_addressToLookup];
		 
		return order.pendingTokens;
	}

	 
	function contributionAmount(address _addressToLookup)
	onlyOwner
	whenNotPaused
	onlyWhileOpen
	public
	view
	returns (uint256)
	{
		 
		require(_addressToLookup != address(0), "Specified address is Invalid [0x0]");
		 
		OrderBook storage order = orders[_addressToLookup];
		 
		return order.weiAmount;
	}

	 
	function _approveKYCAddress(address _addressToApprove) 
	onlyOwner
	internal
	{
		 
		require(_addressToApprove != address(0), "Invalid address specified: address(0)");
		 
		OrderBook storage order = orders[_addressToApprove];
		 
		order.kycVerified = true;
	}

	 
	function _revokeKYCAddress(address _addressToRevoke)
	onlyOwner
	internal
	{
		 
		require(_addressToRevoke != address(0), "Invalid address specified: address(0)");
		 
		OrderBook storage order = orders[_addressToRevoke];
		 
		order.kycVerified = false;
	}

	 
	function _rate(uint _weiAmount)
	internal
	view
	returns (uint256)
	{
		require(_weiAmount > 0, "Specified wei amoount must be > 0");

		 
		if (crowdsaleStage == CrowdsaleStage.preICO)
		{
			 
			if (_weiAmount >= 21 ether) {  
				return 480e8;
			}
			
			 
			if (_weiAmount >= 11 ether) {  
				return 460e8;
			}
			
			 
			if (_weiAmount >= 5 ether) {  
				return 440e8;
			}

		}
		else
		 
		if (crowdsaleStage == CrowdsaleStage.bonusICO)
		{
			 
			if (_weiAmount >= 21 ether) {  
				return 440e8;
			}
			else if (_weiAmount >= 11 ether) {  
				return 428e8;
			}
			else
			if (_weiAmount >= 5 ether) {  
				return 420e8;
			}

		}

		 
		return rate();
	}

	 
	function _getTokenAmount(uint256 _weiAmount)
	whenNotPaused
	internal
	view
	returns (uint256)
	{
		 
		uint256 currentRate = _rate(_weiAmount);
		 
		uint256 sparkleToBuy = currentRate.mul(_weiAmount).div(10e17);
		 
		return sparkleToBuy;
	}

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) 
	whenNotPaused
	internal
	view
	{
		 
		super._preValidatePurchase(_beneficiary, _weiAmount);
		 
		uint256 requestedTokens = getExchangeRate(_weiAmount);
		 
		uint256 tempTotalTokensSold = tokensSold;
		 
		tempTotalTokensSold.add(requestedTokens);
		 
		require(tempTotalTokensSold <= tokenCap, "Requested wei amount will exceed the max token cap and was not accepted.");
		 
		require(requestedTokens <= getRemainingTokens(), "Requested tokens would exceed tokens available and was not accepted.");
		 
		OrderBook storage order = orders[_beneficiary];
		 
		require(order.kycVerified, "Address attempting to purchase is not KYC Verified.");
		 
		order.weiAmount = order.weiAmount.add(_weiAmount);
		order.pendingTokens = order.pendingTokens.add(requestedTokens);
		 
		tokensSold = tokensSold.add(requestedTokens);
		 
		emit TokensSold(_beneficiary, requestedTokens);
	}

	 
	function _processPurchase(address _beneficiary, uint256 _tokenAmount)
	whenNotPaused
	internal
	{
		 
		 
	}

}


 

contract SparkleCrowdsale is SparkleBaseCrowdsale {

   
  address public initTokenAddress = 0x4b7aD3a56810032782Afce12d7d27122bDb96efF;
   
  uint256 public initTokenRate     = 400e8;
  uint256 public initTokenCap      = 19698000e8;
  uint256 public initStartTime     = now;
  uint256 public initEndTime       = now + 12 weeks;  
  address public initDepositWallet = 0x0926a84C83d7B88338588Dca2729b590D787FA34;
  bool public initKYCRequired      = true;

  constructor() 
	SparkleBaseCrowdsale(ERC20(initTokenAddress), initTokenRate, initTokenCap, initStartTime, initEndTime, initDepositWallet, initKYCRequired)
	public
	{
	}

}