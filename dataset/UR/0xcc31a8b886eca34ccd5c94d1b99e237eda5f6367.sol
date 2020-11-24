 

pragma solidity ^0.4.24;

 
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


 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}





 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}


contract BToken is ERC20Burnable, ERC20Detailed {
  uint constant private INITIAL_SUPPLY = 10 * 1e24;
  
  constructor() ERC20Detailed("BurnToken", "BUTK", 18) public {
    super._mint(msg.sender, INITIAL_SUPPLY);
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
    uint256 bTokensRewarded;
    uint256 totalSupplyInit;  
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

  string public name;
  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
  address registrator;
  address defaultPartner;
  
  uint256 partnerBonusRateNumerator;
  uint256 partnerBonusRateDenominator;

  uint256 constant discountNumeratorMul = 95;
  uint256 constant discountDenominatorMul = 100;

  uint256 discountNumerator;
  uint256 discountDenominator;
  uint256 balanceThreshold;

  mapping (address => Token) public tokens;

   
  mapping (address => address) referalPartners;

   
  mapping (address => mapping (address => uint256)) burntByTokenUser;
   
  
   
  mapping (bytes8 => address) refLookup;

   
  mapping (address => bool) public shouldGetBonus;

  BToken bToken;
  uint256 public initialBlockNumber;

  constructor(
    address _bTokenAddress, 
    address _registrator, 
    address _defaultPartner,
    uint256 _initialBalance
  ) 
  public 
  {
    name = "Burn Token Management Contract v0.2";
    registrator = _registrator;
    defaultPartner = _defaultPartner;
    bToken = BToken(_bTokenAddress);
    initialBlockNumber = block.number;
     
    referalPartners[_registrator] = burnAddress;
    referalPartners[_defaultPartner] = burnAddress;
     
    partnerBonusRateNumerator = 15;  
    partnerBonusRateDenominator = 100;
    discountNumerator = 1;
    discountDenominator = 1;
    balanceThreshold = _initialBalance.mul(discountNumeratorMul).div(discountDenominatorMul);
  }

   
   
  
  function claimBurnTokensBack(address _to) public onlyOwner {
     
    uint256 remainingBalance = bToken.balanceOf(this);
    bToken.transfer(_to, remainingBalance);
  }

  function register(
    address tokenAddress, 
    uint256 totalSupply,
    uint256 _rewardRateNumerator,
    uint256 _rewardRateDenominator,
    bool activate
  ) 
    public 
    onlyOwner 
  {
    require(tokens[tokenAddress].status == TokenStatus.Unknown, "Cannot register more than one time");
    Token memory _token;
    if (activate) {
      _token.status = TokenStatus.Active;
    } else {
      _token.status = TokenStatus.Suspended;
    }    
    _token.rewardRateNumerator = _rewardRateNumerator;
    _token.rewardRateDenominator = _rewardRateDenominator;
    _token.totalSupplyInit = totalSupply;
    tokens[tokenAddress] = _token;
  }

  function changeRegistrator(address _newRegistrator) public onlyOwner {
    registrator = _newRegistrator;
  }

  function changeDefaultPartnerAddress(address _newDefaultPartner) public onlyOwner {
    defaultPartner = _newDefaultPartner;
  }

  
  function setRewardRateForToken(
    address tokenAddress,
    uint256 _rewardRateNumerator,
    uint256 _rewardRateDenominator
  )
    public 
    onlyOwner 
  {
    require(tokens[tokenAddress].status != TokenStatus.Unknown, "Token should be registered first");
    tokens[tokenAddress].rewardRateNumerator = _rewardRateNumerator;
    tokens[tokenAddress].rewardRateDenominator = _rewardRateDenominator;
  }
  

  function setPartnerBonusRate(
    uint256 _partnerBonusRateNumerator,
    uint256 _partnerBonusRateDenominator
  )
    public 
    onlyOwner 
  {
    partnerBonusRateNumerator = _partnerBonusRateNumerator;
    partnerBonusRateDenominator = _partnerBonusRateDenominator;
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

   
   

  function isAuthorized(address _who) public view whenNotPaused returns (bool) {
    address partner = referalPartners[_who];
    return partner != address(0);
  }

  function amountBurnedTotal(address token) public view returns (uint256) {
    return tokens[token].burned;
  }

  function amountBurnedByUser(address token, address _who) public view returns (uint256) {
    return burntByTokenUser[token][_who];
  }

   
  function getRefByAddress(address _who) public pure returns (bytes6) {
      
    bytes32 dataHash = keccak256(abi.encodePacked(_who, "BUTK"));
    return bytes6(uint256(dataHash) % uint256(116 * 0x10000000000));
  }

  function getAddressByRef(bytes6 ref) public view returns (address) {
    return refLookup[ref];
  }

  function saveRef(address _who) private returns (bool) {
    require(_who != address(0), "Should not be zero address");
    bytes6 ref = getRefByAddress(_who);
    refLookup[ref] = _who;
    return true;
  }

  function checkSignature(bytes sig, address _who) public view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(_who));
    return (ECDSA.recover(dataHash, sig) == registrator);
  }

  function authorizeAddress(bytes authSignature, bytes6 ref) public whenNotPaused returns (bool) {
     
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

  function suspendIfNecessary(
    address tokenAddress
  )
    private returns (bool) 
  {
     
     
    if (tokens[tokenAddress].burnedAccumulator > tokens[tokenAddress].totalSupplyInit.div(10)) {
      tokens[tokenAddress].status = TokenStatus.Suspended;
      return true;
    }
    return false;
  }

   
  function discountCorrectionIfNecessary(
    uint256 balance
  ) 
    private returns (bool)
  {
    if (balance < balanceThreshold) {
       
       
      discountNumerator = discountNumerator * discountNumeratorMul;
      discountDenominator = discountDenominator * discountDenominatorMul;
      balanceThreshold = balanceThreshold.mul(discountNumeratorMul).div(discountDenominatorMul);
      emit DiscountUpdate(discountNumerator, discountDenominator, balanceThreshold);
      return true;
    }
    return false;
  }

   
  function getAllTokenData(
    address tokenAddress,
    address _who
  )
    public view returns (uint256, uint256, uint256, uint256, bool) 
  {
    IERC20 tokenContract = IERC20(tokenAddress);
    uint256 balance = tokenContract.balanceOf(_who);
    uint256 allowance = tokenContract.allowance(_who, this);
    bool isActive = (tokens[tokenAddress].status == TokenStatus.Active);
    uint256 burnedByUser = amountBurnedByUser(tokenAddress, _who);
    uint256 burnedTotal = amountBurnedTotal(tokenAddress);
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
    return bTokenValue.mul(partnerBonusRateNumerator).div(partnerBonusRateDenominator);
  }

  function burn(
    address tokenAddress, 
    uint256 value
  ) 
    public 
    whenNotPaused 
    returns (bool) 
  {
    address partner = referalPartners[msg.sender];
    require(partner != address(0), "Burner should be registered");
    IERC20 tokenContract = IERC20(tokenAddress);
    require(tokenContract.allowance(msg.sender, this) >= value, "Should be allowed");
 
    uint256 bTokenValueFin;
    uint256 bTokenValue = getBTokenValue(tokenAddress, value);
    uint256 currentBalance = bToken.balanceOf(this);
    require(bTokenValue < currentBalance.div(100), "Cannot reward more than 1% of the balance");

    uint256 bTokenPartnerBonus = getPartnerReward(bTokenValue);
    uint256 bTokenTotal = bTokenValue.add(bTokenPartnerBonus);
    
     
    tokens[tokenAddress].burned = tokens[tokenAddress].burned.add(value);
    tokens[tokenAddress].burnedAccumulator = tokens[tokenAddress].burnedAccumulator.add(value);
    tokens[tokenAddress].bTokensRewarded = tokens[tokenAddress].bTokensRewarded.add(bTokenTotal);
    burntByTokenUser[tokenAddress][msg.sender] = burntByTokenUser[tokenAddress][msg.sender].add(value);

    tokenContract.transferFrom(msg.sender, burnAddress, value);  
    
    discountCorrectionIfNecessary(currentBalance.sub(bTokenValue).sub(bTokenPartnerBonus));
    
    suspendIfNecessary(tokenAddress);

    bToken.transfer(partner, bTokenPartnerBonus);

    if (shouldGetBonus[msg.sender]) {
       
      shouldGetBonus[msg.sender] = false;
      bTokenValueFin = bTokenValue.mul(6).div(5);  
    } else {
      bTokenValueFin = bTokenValue;
    }

    bToken.transfer(msg.sender, bTokenValueFin);
    emit Burn(tokenAddress, msg.sender, partner, value, bTokenValueFin, bTokenPartnerBonus);
  }
}