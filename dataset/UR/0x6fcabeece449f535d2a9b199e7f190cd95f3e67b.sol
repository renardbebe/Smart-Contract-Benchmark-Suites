 

pragma solidity ^0.4.25;

 

 
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

 

 
contract TokenCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public tokenCap;

   
  uint256 public soldTokens;

  constructor(uint256 _tokenCap) public {
    require(_tokenCap > 0, "Token Cap should be greater than zero");
    tokenCap = _tokenCap;
  }

  function tokenCapReached() public view returns (bool) {
    return soldTokens >= tokenCap;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(
      soldTokens.add(_getTokenAmount(_weiAmount)) <= tokenCap,
      "Can't sell more than token cap tokens"
    );
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    soldTokens = soldTokens.add(_getTokenAmount(_weiAmount));
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
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
     
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
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

 

 
contract TokenRecover is Ownable {

   
  function recoverERC20(
    address _tokenAddress,
    uint256 _tokens
  )
  public
  onlyOwner
  returns (bool success)
  {
    return ERC20Basic(_tokenAddress).transfer(owner, _tokens);
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

 

contract Contributions is RBAC, Ownable {
  using SafeMath for uint256;

  uint256 private constant TIER_DELETED = 999;
  string public constant ROLE_MINTER = "minter";
  string public constant ROLE_OPERATOR = "operator";

  uint256 public tierLimit;

  modifier onlyMinter () {
    checkRole(msg.sender, ROLE_MINTER);
    _;
  }

  modifier onlyOperator () {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

  uint256 public totalSoldTokens;
  mapping(address => uint256) public tokenBalances;
  mapping(address => uint256) public ethContributions;
  mapping(address => uint256) private _whitelistTier;
  address[] public tokenAddresses;
  address[] public ethAddresses;
  address[] private whitelistAddresses;

  constructor(uint256 _tierLimit) public {
    addRole(owner, ROLE_OPERATOR);
    tierLimit = _tierLimit;
  }

  function addMinter(address minter) external onlyOwner {
    addRole(minter, ROLE_MINTER);
  }

  function removeMinter(address minter) external onlyOwner {
    removeRole(minter, ROLE_MINTER);
  }

  function addOperator(address _operator) external onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

  function removeOperator(address _operator) external onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }

  function addTokenBalance(
    address _address,
    uint256 _tokenAmount
  )
    external
    onlyMinter
  {
    if (tokenBalances[_address] == 0) {
      tokenAddresses.push(_address);
    }
    tokenBalances[_address] = tokenBalances[_address].add(_tokenAmount);
    totalSoldTokens = totalSoldTokens.add(_tokenAmount);
  }

  function addEthContribution(
    address _address,
    uint256 _weiAmount
  )
    external
    onlyMinter
  {
    if (ethContributions[_address] == 0) {
      ethAddresses.push(_address);
    }
    ethContributions[_address] = ethContributions[_address].add(_weiAmount);
  }

  function setTierLimit(uint256 _newTierLimit) external onlyOperator {
    require(_newTierLimit > 0, "Tier must be greater than zero");

    tierLimit = _newTierLimit;
  }

  function addToWhitelist(
    address _investor,
    uint256 _tier
  )
    external
    onlyOperator
  {
    require(_tier == 1 || _tier == 2, "Only two tier level available");
    if (_whitelistTier[_investor] == 0) {
      whitelistAddresses.push(_investor);
    }
    _whitelistTier[_investor] = _tier;
  }

  function removeFromWhitelist(address _investor) external onlyOperator {
    _whitelistTier[_investor] = TIER_DELETED;
  }

  function whitelistTier(address _investor) external view returns (uint256) {
    return _whitelistTier[_investor] <= 2 ? _whitelistTier[_investor] : 0;
  }

  function getWhitelistedAddresses(
    uint256 _tier
  )
    external
    view
    returns (address[])
  {
    address[] memory tmp = new address[](whitelistAddresses.length);

    uint y = 0;
    if (_tier == 1 || _tier == 2) {
      uint len = whitelistAddresses.length;
      for (uint i = 0; i < len; i++) {
        if (_whitelistTier[whitelistAddresses[i]] == _tier) {
          tmp[y] = whitelistAddresses[i];
          y++;
        }
      }
    }

    address[] memory toReturn = new address[](y);

    for (uint k = 0; k < y; k++) {
      toReturn[k] = tmp[k];
    }

    return toReturn;
  }

  function isAllowedPurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    external
    view
    returns (bool)
  {
    if (_whitelistTier[_beneficiary] == 2) {
      return true;
    } else if (_whitelistTier[_beneficiary] == 1 && ethContributions[_beneficiary].add(_weiAmount) <= tierLimit) {
      return true;
    }

    return false;
  }

  function getTokenAddressesLength() external view returns (uint) {
    return tokenAddresses.length;
  }

  function getEthAddressesLength() external view returns (uint) {
    return ethAddresses.length;
  }
}

 

 




contract DefaultICO is TimedCrowdsale, TokenRecover {

  Contributions public contributions;

  uint256 public minimumContribution;
  uint256 public tierZero;

  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _rate,
    address _wallet,
    uint256 _minimumContribution,
    address _token,
    address _contributions,
    uint256 _tierZero
  )
    Crowdsale(_rate, _wallet, ERC20(_token))
    TimedCrowdsale(_openingTime, _closingTime)
    public
  {
    require(
      _contributions != address(0),
      "Contributions address can't be the zero address."
    );
    contributions = Contributions(_contributions);
    minimumContribution = _minimumContribution;
    tierZero = _tierZero;
  }

   

   
  function started() public view returns(bool) {
     
    return block.timestamp >= openingTime;
  }

  function setTierZero(uint256 _newTierZero) external onlyOwner {
    tierZero = _newTierZero;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(
      _weiAmount >= minimumContribution,
      "Can't send less than the minimum contribution"
    );

     
    if (contributions.ethContributions(_beneficiary).add(_weiAmount) > tierZero) {
      require(
        contributions.isAllowedPurchase(_beneficiary, _weiAmount),
        "Beneficiary is not allowed to purchase this amount"
      );
    }

    super._preValidatePurchase(_beneficiary, _weiAmount);
  }


   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions.addEthContribution(_beneficiary, _weiAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    super._processPurchase(_beneficiary, _tokenAmount);
    contributions.addTokenBalance(_beneficiary, _tokenAmount);
  }
}

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 
contract RBACMintableToken is MintableToken, RBAC {
   
  string public constant ROLE_MINTER = "minter";

   
  modifier hasMintPermission() {
    checkRole(msg.sender, ROLE_MINTER);
    _;
  }

   
  function addMinter(address _minter) public onlyOwner {
    addRole(_minter, ROLE_MINTER);
  }

   
  function removeMinter(address _minter) public onlyOwner {
    removeRole(_minter, ROLE_MINTER);
  }
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

 
contract ERC1363 is ERC20, ERC165 {
   

   

   
  function transferAndCall(address _to, uint256 _value) public returns (bool);

   
  function transferAndCall(address _to, uint256 _value, bytes _data) public returns (bool);  

   
  function transferFromAndCall(address _from, address _to, uint256 _value) public returns (bool);  


   
  function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public returns (bool);  

   
  function approveAndCall(address _spender, uint256 _value) public returns (bool);  

   
  function approveAndCall(address _spender, uint256 _value, bytes _data) public returns (bool);  
}

 

 
contract ERC1363Receiver {
   

   
  function onTransferReceived(address _operator, address _from, uint256 _value, bytes _data) external returns (bytes4);  
}

 

 
contract ERC1363Spender {
   

   
  function onApprovalReceived(address _owner, uint256 _value, bytes _data) external returns (bytes4);  
}

 

 







 
contract ERC1363BasicToken is SupportsInterfaceWithLookup, StandardToken, ERC1363 {  
  using AddressUtils for address;

   
  bytes4 internal constant InterfaceId_ERC1363Transfer = 0x4bbee2df;

   
  bytes4 internal constant InterfaceId_ERC1363Approve = 0xfb9ec8ce;

   
   
  bytes4 private constant ERC1363_RECEIVED = 0x88a7ca5c;

   
   
  bytes4 private constant ERC1363_APPROVED = 0x7b04a2d0;

  constructor() public {
     
    _registerInterface(InterfaceId_ERC1363Transfer);
    _registerInterface(InterfaceId_ERC1363Approve);
  }

  function transferAndCall(
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    return transferAndCall(_to, _value, "");
  }

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    returns (bool)
  {
    require(transfer(_to, _value));
    require(
      checkAndCallTransfer(
        msg.sender,
        _to,
        _value,
        _data
      )
    );
    return true;
  }

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
     
    return transferFromAndCall(_from, _to, _value, "");
  }

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    returns (bool)
  {
    require(transferFrom(_from, _to, _value));
    require(
      checkAndCallTransfer(
        _from,
        _to,
        _value,
        _data
      )
    );
    return true;
  }

  function approveAndCall(
    address _spender,
    uint256 _value
  )
    public
    returns (bool)
  {
    return approveAndCall(_spender, _value, "");
  }

  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    returns (bool)
  {
    approve(_spender, _value);
    require(
      checkAndCallApprove(
        _spender,
        _value,
        _data
      )
    );
    return true;
  }

   
  function checkAndCallTransfer(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return false;
    }
    bytes4 retval = ERC1363Receiver(_to).onTransferReceived(
      msg.sender, _from, _value, _data
    );
    return (retval == ERC1363_RECEIVED);
  }

   
  function checkAndCallApprove(
    address _spender,
    uint256 _value,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_spender.isContract()) {
      return false;
    }
    bytes4 retval = ERC1363Spender(_spender).onApprovalReceived(
      msg.sender, _value, _data
    );
    return (retval == ERC1363_APPROVED);
  }
}

 

 
contract FidelityHouseToken is DetailedERC20, RBACMintableToken, BurnableToken, ERC1363BasicToken, TokenRecover {

  uint256 public lockedUntil;
  mapping(address => uint256) internal lockedBalances;

  modifier canTransfer(address _from, uint256 _value) {
    require(
      mintingFinished,
      "Minting should be finished before transfer."
    );
    require(
      _value <= balances[_from].sub(lockedBalanceOf(_from)),
      "Can't transfer more than unlocked tokens"
    );
    _;
  }

  constructor(uint256 _lockedUntil)
    DetailedERC20("FidelityHouse Token", "FIH", 18)
    public
  {
    lockedUntil = _lockedUntil;
  }

   
  function lockedBalanceOf(address _owner) public view returns (uint256) {
     
    return block.timestamp <= lockedUntil ? lockedBalances[_owner] : 0;
  }

   
  function mintAndLock(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    lockedBalances[_to] = lockedBalances[_to].add(_amount);
    return super.mint(_to, _amount);
  }

  function transfer(
    address _to,
    uint256 _value
  )
    public
    canTransfer(msg.sender, _value)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    canTransfer(_from, _value)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }
}

 

 




 
contract TimedBonusCrowdsale is MintedCrowdsale, DefaultICO {

  uint256[] public bonusDates;
  uint256[] public bonusRates;

  function setBonusRates(
    uint256[] _bonusDates,
    uint256[] _bonusRates
  )
    external
    onlyOwner
  {
    require(
      !started(),
      "Bonus rates can be set only before the campaign start"
    );
    require(
      _bonusDates.length == 4,
      "Dates array must have 4 entries."
    );
    require(
      _bonusRates.length == 4,
      "Rates array must have 4 entries."
    );
    require(
      _bonusDates[0] < _bonusDates[1] && _bonusDates[1] < _bonusDates[2] && _bonusDates[2] < _bonusDates[3],  
      "Dates must be consecutive"
    );

    bonusDates = _bonusDates;
    bonusRates = _bonusRates;
  }

  function getCurrentBonus() public view returns (uint256) {
    uint256 bonusPercent = 0;

    if (bonusDates.length > 0) {
      if (block.timestamp < bonusDates[0]) {  
        bonusPercent = bonusRates[0];
      } else if (block.timestamp < bonusDates[1]) {  
        bonusPercent = bonusRates[1];
      } else if (block.timestamp < bonusDates[2]) {  
        bonusPercent = bonusRates[2];
      } else if (block.timestamp < bonusDates[3]) {  
        bonusPercent = bonusRates[3];
      }
    }

    return bonusPercent;
  }

   
  function _getTokenAmount(
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256)
  {
    uint256 bonusAmount = 0;
    uint256 tokenAmount = super._getTokenAmount(_weiAmount);

    uint256 bonusPercent = getCurrentBonus();

    if (bonusPercent > 0) {
      bonusAmount = tokenAmount.mul(bonusPercent).div(100);
    }

    return tokenAmount.add(bonusAmount);
  }
}

 

contract FidelityHouseICO is TokenCappedCrowdsale, TimedBonusCrowdsale {

  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _rate,
    address _wallet,
    uint256 _tokenCap,
    uint256 _minimumContribution,
    address _token,
    address _contributions,
    uint256 _tierZero
  )
    DefaultICO(
      _openingTime,
      _closingTime,
      _rate,
      _wallet,
      _minimumContribution,
      _token,
      _contributions,
      _tierZero
    )
    TokenCappedCrowdsale(_tokenCap)
    public
  {}

  function adjustTokenCap(uint256 _newTokenCap) external onlyOwner {
    require(_newTokenCap > 0, "Token Cap should be greater than zero");

    tokenCap = _newTokenCap;
  }

   
  function ended() public view returns(bool) {
    return hasClosed() || tokenCapReached();
  }
}