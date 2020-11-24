 

pragma solidity ^0.4.24;

 
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




 

library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}


contract BMng is Pausable, Ownable {
  using SafeMath for uint256;

  enum TokenStatus {
    Unknown,
    Active,
    Suspended
  }

  struct Token {
    TokenStatus status;
    uint256 rewardRateNumerator;
    uint256 rewardRateDenominator;
    uint256 burned;
    uint256 burnedAccumulator;
    uint256 suspiciousVolume;  
  }

  event Auth(
    address indexed burner,
    address indexed partner
  );

  event Burn(
    address indexed token,
    address indexed burner,
    address partner,
    uint256 value,
    uint256 bValue,
    uint256 bValuePartner
  );

  event DiscountUpdate(
    uint256 discountNumerator,
    uint256 discountDenominator,
    uint256 balanceThreshold
  );

  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

   
  string public name;
  IERC20 bToken;  
  uint256 discountNumeratorMul;
  uint256 discountDenominatorMul;
  uint256 bonusNumerator;
  uint256 bonusDenominator;
  uint256 public initialBlockNumber;

   
  uint256 discountNumerator;
  uint256 discountDenominator;
  uint256 balanceThreshold;

   
  address registrator;
  address defaultPartner;
  uint256 partnerRewardRateNumerator;
  uint256 partnerRewardRateDenominator;
  bool permissionRequired;

  mapping (address => Token) public tokens;
  mapping (address => address) referalPartners;  
  mapping (address => mapping (address => uint256)) burnedByTokenUser;  
  mapping (bytes6 => address) refLookup;  
  mapping (address => bool) public shouldGetBonus;  
  mapping (address => uint256) public nonces;  

  constructor(
    address bTokenAddress, 
    address _registrator, 
    address _defaultPartner,
    uint256 initialBalance
  ) 
  public 
  {
    name = "Burn Token Management Contract v0.3";
    registrator = _registrator;
    defaultPartner = _defaultPartner;
    bToken = IERC20(bTokenAddress);
    initialBlockNumber = block.number;

     
    permissionRequired = false;

     
    referalPartners[registrator] = burnAddress;
    referalPartners[defaultPartner] = burnAddress;

     
    partnerRewardRateNumerator = 15;
    partnerRewardRateDenominator = 100;

     
    bonusNumerator = 20;
    bonusDenominator = 100;

     
    discountNumeratorMul = 95;
    discountDenominatorMul = 100;

    discountNumerator = 1;
    discountDenominator = 1;
    balanceThreshold = initialBalance.mul(discountNumeratorMul).div(discountDenominatorMul);
  }

   
   
  
  function claimBurnTokensBack(address to) public onlyOwner {
     
    uint256 remainingBalance = bToken.balanceOf(address(this));
    bToken.transfer(to, remainingBalance);
  }

  function registerToken(
    address tokenAddress, 
    uint256 suspiciousVolume,
    uint256 rewardRateNumerator,
    uint256 rewardRateDenominator,
    bool activate
  ) 
    public 
    onlyOwner 
  {
     
    Token memory token;
    if (activate) {
      token.status = TokenStatus.Active;
    } else {
      token.status = TokenStatus.Suspended;
    }    
    token.rewardRateNumerator = rewardRateNumerator;
    token.rewardRateDenominator = rewardRateDenominator;
    token.suspiciousVolume = suspiciousVolume;
    tokens[tokenAddress] = token;
  }

  function changeRegistrator(address newRegistrator) public onlyOwner {
    registrator = newRegistrator;
  }

  function changeDefaultPartnerAddress(address newDefaultPartner) public onlyOwner {
    defaultPartner = newDefaultPartner;
  }

  
  function setRewardRateForToken(
    address tokenAddress,
    uint256 rewardRateNumerator,
    uint256 rewardRateDenominator
  )
    public 
    onlyOwner 
  {
    require(tokens[tokenAddress].status != TokenStatus.Unknown, "Token should be registered first");
    tokens[tokenAddress].rewardRateNumerator = rewardRateNumerator;
    tokens[tokenAddress].rewardRateDenominator = rewardRateDenominator;
  }
  

  function setPartnerRewardRate(
    uint256 newPartnerRewardRateNumerator,
    uint256 newPartnerRewardRateDenominator
  )
    public 
    onlyOwner 
  {
    partnerRewardRateNumerator = newPartnerRewardRateNumerator;
    partnerRewardRateDenominator = newPartnerRewardRateDenominator;
  }

  function setPermissionRequired(bool state) public onlyOwner {
    permissionRequired = state;
  }

  function suspend(address tokenAddress) public onlyOwner {
    require(tokens[tokenAddress].status != TokenStatus.Unknown, "Token should be registered first");
    tokens[tokenAddress].status = TokenStatus.Suspended;
  }

  function unSuspend(address tokenAddress) public onlyOwner {
    require(tokens[tokenAddress].status != TokenStatus.Unknown, "Token should be registered first");
    tokens[tokenAddress].status = TokenStatus.Active;
    tokens[tokenAddress].burnedAccumulator = 0;
  }

  function activate(address tokenAddress) public onlyOwner {
    require(tokens[tokenAddress].status != TokenStatus.Unknown, "Token should be registered first");
    tokens[tokenAddress].status = TokenStatus.Active;
  }

   
   

  modifier whenNoPermissionRequired() {
    require(!isPermissionRequired(), "Need a permission");
    _;
  }

  function isPermissionRequired() public view returns (bool) {
     
    return permissionRequired;
  }

  function isAuthorized(address user) public view whenNotPaused returns (bool) {
    address partner = referalPartners[user];
    return partner != address(0);
  }

  function amountBurnedTotal(address tokenAddress) public view returns (uint256) {
    return tokens[tokenAddress].burned;
  }

  function amountBurnedByUser(address tokenAddress, address user) public view returns (uint256) {
    return burnedByTokenUser[tokenAddress][user];
  }

   
  function getRefByAddress(address user) public pure returns (bytes6) {
      
    bytes32 dataHash = keccak256(abi.encodePacked(user, "BUTK"));
    bytes32 tmp = bytes32(uint256(dataHash) % uint256(116 * 0x10000000000));
    return bytes6(tmp << 26 * 8);
  }

  function getAddressByRef(bytes6 ref) public view returns (address) {
    return refLookup[ref];
  }

  function saveRef(address user) private returns (bool) {
    require(user != address(0), "Should not be zero address");
    bytes6 ref = getRefByAddress(user);
    refLookup[ref] = user;
    return true;
  }

  function checkSignature(bytes memory sig, address user) public view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(user));
    return (ECDSA.recover(dataHash, sig) == registrator);
  }

  function checkPermissionSignature(
    bytes memory sig, 
    address user, 
    address tokenAddress,
    uint256 value,
    uint256 nonce
  ) 
    public view returns (bool) 
  {
    bytes32 dataHash = keccak256(abi.encodePacked(user, tokenAddress, value, nonce));
    return (ECDSA.recover(dataHash, sig) == registrator);
  }

  function authorizeAddress(bytes memory authSignature, bytes6 ref) public whenNotPaused returns (bool) {
     
    require(checkSignature(authSignature, msg.sender) == true, "Authorization should be signed by registrator");
    require(isAuthorized(msg.sender) == false, "No need to authorize more then once");
    address refAddress = getAddressByRef(ref);
    address partner = (refAddress == address(0)) ? defaultPartner : refAddress;

     
    saveRef(msg.sender);

    referalPartners[msg.sender] = partner;

     
    if (partner != defaultPartner) {
      shouldGetBonus[msg.sender] = true;
    }

    emit Auth(msg.sender, partner);

    return true;
  }

  function suspendIfNecessary(address tokenAddress) private returns (bool) {
     
     
    if (tokens[tokenAddress].burnedAccumulator > tokens[tokenAddress].suspiciousVolume) {
      tokens[tokenAddress].status = TokenStatus.Suspended;
      return true;
    }
    return false;
  }

   
  function discountCorrectionIfNecessary(uint256 balance) private returns (bool) {
    if (balance < balanceThreshold) {
       
       
      discountNumerator = discountNumerator.mul(discountNumeratorMul);
      discountDenominator = discountDenominator.mul(discountDenominatorMul);
      balanceThreshold = balanceThreshold.mul(discountNumeratorMul).div(discountDenominatorMul);
      emit DiscountUpdate(discountNumerator, discountDenominator, balanceThreshold);
      return true;
    }
    return false;
  }

   
  function getAllTokenData(
    address tokenAddress,
    address user
  )
    public view returns (uint256, uint256, uint256, uint256, bool) 
  {
    IERC20 tokenContract = IERC20(tokenAddress);
    uint256 balance = tokenContract.balanceOf(user);
    uint256 allowance = tokenContract.allowance(user, address(this));
    uint256 burnedByUser = amountBurnedByUser(tokenAddress, user);
    uint256 burnedTotal = amountBurnedTotal(tokenAddress);
    bool isActive = (tokens[tokenAddress].status == TokenStatus.Active);
    return (balance, allowance, burnedByUser, burnedTotal, isActive);
  }

  function getBTokenValue(
    address tokenAddress, 
    uint256 value
  )
    public view returns (uint256) 
  {
    Token memory tokenRec = tokens[tokenAddress];
    require(tokenRec.status == TokenStatus.Active, "Token should be in active state");
    uint256 denominator = tokenRec.rewardRateDenominator;
    require(denominator > 0, "Reward denominator should not be zero");
    uint256 numerator = tokenRec.rewardRateNumerator;
    uint256 bTokenValue = value.mul(numerator).div(denominator);
     
    uint256 discountedBTokenValue = bTokenValue.mul(discountNumerator).div(discountDenominator);
    return discountedBTokenValue;
  } 

  function getPartnerReward(uint256 bTokenValue) public view returns (uint256) {
    return bTokenValue.mul(partnerRewardRateNumerator).div(partnerRewardRateDenominator);
  }

  function burn(
    address tokenAddress, 
    uint256 value
  )
    public 
    whenNotPaused
    whenNoPermissionRequired
  {
    _burn(tokenAddress, value);
  }

  function burnPermissioned(
    address tokenAddress, 
    uint256 value,
    uint256 nonce,
    bytes memory permissionSignature
  )
    public 
    whenNotPaused
  {
    require(nonces[msg.sender] < nonce, "New nonce should be greater than previous");
    bool signatureOk = checkPermissionSignature(permissionSignature, msg.sender, tokenAddress, value, nonce);
    require(signatureOk, "Permission should have a correct signature");
    nonces[msg.sender] = nonce;
    _burn(tokenAddress, value);
  }

  function _burn(address tokenAddress, uint256 value) private {
    address partner = referalPartners[msg.sender];
    require(partner != address(0), "Burner should be registered");
    
    IERC20 tokenContract = IERC20(tokenAddress);
    
    require(tokenContract.allowance(msg.sender, address(this)) >= value, "Should be allowed");
 
    uint256 bTokenValueTotal;  
    uint256 bTokenValue = getBTokenValue(tokenAddress, value);
    uint256 currentBalance = bToken.balanceOf(address(this));
    require(bTokenValue < currentBalance.div(100), "Cannot reward more than 1% of the balance");

    uint256 bTokenPartnerReward = getPartnerReward(bTokenValue);
    
     
    tokens[tokenAddress].burned = tokens[tokenAddress].burned.add(value);
    tokens[tokenAddress].burnedAccumulator = tokens[tokenAddress].burnedAccumulator.add(value);
    burnedByTokenUser[tokenAddress][msg.sender] = burnedByTokenUser[tokenAddress][msg.sender].add(value);
    
    tokenContract.transferFrom(msg.sender, burnAddress, value);  
    discountCorrectionIfNecessary(currentBalance.sub(bTokenValue).sub(bTokenPartnerReward));
    
    suspendIfNecessary(tokenAddress);

    bToken.transfer(partner, bTokenPartnerReward);

    if (shouldGetBonus[msg.sender]) {
       
      shouldGetBonus[msg.sender] = false;
      bTokenValueTotal = bTokenValue.add(bTokenValue.mul(bonusNumerator).div(bonusDenominator));
    } else {
      bTokenValueTotal = bTokenValue;
    }

    bToken.transfer(msg.sender, bTokenValueTotal);
    emit Burn(tokenAddress, msg.sender, partner, value, bTokenValueTotal, bTokenPartnerReward);
  }
}