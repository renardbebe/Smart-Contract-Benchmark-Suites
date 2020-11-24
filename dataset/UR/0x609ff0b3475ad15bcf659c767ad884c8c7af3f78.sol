 

 

pragma solidity 0.5.9;

 
 
 

interface IERC721 {


   
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);

   
   
   
   
  event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint _tokenId) external payable;

   
   
   
   
   
   
  function approve(address _approved, uint _tokenId) external payable;

   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint _tokenId, bytes calldata data) external payable;

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint _tokenId) external payable;

   
   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external;

   
   
   
   
   
  function balanceOf(address _owner) external view returns (uint);

   
   
   
   
   
  function ownerOf(uint _tokenId) external view returns (address);

   
   
   
   
  function getApproved(uint _tokenId) external view returns (address);

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

   
  function name() external view returns (string memory _name);
}

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity ^0.5.0;


 
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

    uint256[50] private ______gap;
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;


contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity 0.5.9;



 
contract MixinFunds
{
   
  address public tokenAddress;

  constructor(
    address _tokenAddress
  ) public
  {
    require(
      _tokenAddress == address(0) || IERC20(_tokenAddress).totalSupply() > 0,
      'INVALID_TOKEN'
    );
    tokenAddress = _tokenAddress;
  }

   
  function getBalance(
    address _account
  ) public view
    returns (uint)
  {
    if(tokenAddress == address(0)) {
      return _account.balance;
    } else {
      return IERC20(tokenAddress).balanceOf(_account);
    }
  }

   
  function _chargeAtLeast(
    uint _price
  ) internal
  {
    if(_price > 0) {
      if(tokenAddress == address(0)) {
        require(msg.value >= _price, 'NOT_ENOUGH_FUNDS');
      } else {
        IERC20 token = IERC20(tokenAddress);
        uint balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _price);

         
         
         
        require(token.balanceOf(address(this)) > balanceBefore, 'TRANSFER_FAILED');
      }
    }
  }

   
  function _transfer(
    address _to,
    uint _amount
  ) internal
  {
    if(_amount > 0) {
      if(tokenAddress == address(0)) {
        address(uint160(_to)).transfer(_amount);
      } else {
        IERC20 token = IERC20(tokenAddress);
        uint balanceBefore = token.balanceOf(_to);
        token.transfer(_to, _amount);

         
         
         
        require(token.balanceOf(_to) > balanceBefore, 'TRANSFER_FAILED');
      }
    }
  }
}

 

pragma solidity 0.5.9;




 
contract MixinDisableAndDestroy is
  IERC721,
  Ownable,
  MixinFunds
{
   
  bool public isAlive;

  event Destroy(
    uint balance,
    address indexed owner
  );

  event Disable();

  constructor(
  ) internal
  {
    isAlive = true;
  }

   
  modifier onlyIfAlive() {
    require(isAlive, 'LOCK_DEPRECATED');
    _;
  }

   
  function disableLock()
    external
    onlyOwner
    onlyIfAlive
  {
    emit Disable();
    isAlive = false;
  }

   
  function destroyLock()
    external
    onlyOwner
  {
    require(isAlive == false, 'DISABLE_FIRST');

    emit Destroy(address(this).balance, msg.sender);

     
    _transfer(msg.sender, getBalance(address(this)));
    selfdestruct(msg.sender);

     
     
  }

}

 

pragma solidity 0.5.9;


 

interface IUnlock {


   
  event NewLock(
    address indexed lockOwner,
    address indexed newLockAddress
  );

  event NewTokenURI(
    string tokenURI
  );

  event NewGlobalTokenSymbol(
    string tokenSymbol
  );

   
  function initialize(address _owner) external;

   
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

     
  function recordKeyPurchase(
    uint _value,
    address _referrer  
  )
    external;

     
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens  
  )
    external;

     
  function computeAvailableDiscountFor(
    address _purchaser,  
    uint _keyPrice  
  )
    external
    view
    returns (uint discount, uint tokens);

   
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

   
  function setGlobalBaseTokenURI(
    string calldata _URI
  )
    external;

   
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

   
  function setGlobalTokenSymbol(
    string calldata _symbol
  )
    external;

}

 

pragma solidity 0.5.9;






 
contract MixinLockCore is
  Ownable,
  MixinFunds,
  MixinDisableAndDestroy
{
  event PriceChanged(
    uint oldKeyPrice,
    uint keyPrice
  );

  event Withdrawal(
    address indexed sender,
    address indexed beneficiary,
    uint amount
  );

   
   
  IUnlock public unlockProtocol;

   
   
   
  uint public expirationDuration;

   
   
  uint public keyPrice;

   
  uint public maxNumberOfKeys;

   
  uint public numberOfKeysSold;

   
  address public beneficiary;

   
  modifier notSoldOut() {
    require(maxNumberOfKeys > numberOfKeysSold, 'LOCK_SOLD_OUT');
    _;
  }

  modifier onlyOwnerOrBeneficiary()
  {
    require(
      msg.sender == owner() || msg.sender == beneficiary,
      'ONLY_LOCK_OWNER_OR_BENEFICIARY'
    );
    _;
  }

  constructor(
    address _beneficiary,
    uint _expirationDuration,
    uint _keyPrice,
    uint _maxNumberOfKeys
  ) internal
  {
    require(_expirationDuration <= 100 * 365 * 24 * 60 * 60, 'MAX_EXPIRATION_100_YEARS');
    unlockProtocol = IUnlock(msg.sender);  
    beneficiary = _beneficiary;
    expirationDuration = _expirationDuration;
    keyPrice = _keyPrice;
    maxNumberOfKeys = _maxNumberOfKeys;
  }

   
  function withdraw(
    uint _amount
  ) external
    onlyOwnerOrBeneficiary
  {
    uint balance = getBalance(address(this));
    uint amount;
    if(_amount == 0 || _amount > balance)
    {
      require(balance > 0, 'NOT_ENOUGH_FUNDS');
      amount = balance;
    }
    else
    {
      amount = _amount;
    }

    emit Withdrawal(msg.sender, beneficiary, amount);
     
    _transfer(beneficiary, amount);
  }

   
  function updateKeyPrice(
    uint _keyPrice
  )
    external
    onlyOwner
    onlyIfAlive
  {
    uint oldKeyPrice = keyPrice;
    keyPrice = _keyPrice;
    emit PriceChanged(oldKeyPrice, keyPrice);
  }

   
  function updateBeneficiary(
    address _beneficiary
  ) external
    onlyOwnerOrBeneficiary
  {
    require(_beneficiary != address(0), 'INVALID_ADDRESS');
    beneficiary = _beneficiary;
  }

   
  function totalSupply()
    public
    view
    returns (uint)
  {
    return numberOfKeysSold;
  }
}

 

pragma solidity 0.5.9;




 
contract MixinKeys is
  Ownable,
  MixinLockCore
{
   
  struct Key {
    uint tokenId;
    uint expirationTimestamp;
  }

   
  event ExpireKey(uint tokenId);

   
   
   
   
  mapping (address => Key) private keyByOwner;

   
   
   
   
  mapping (uint => address) private ownerByTokenId;

   
   
  address[] public owners;

   
  modifier ownsOrHasOwnedKey(
    address _owner
  ) {
    require(
      keyByOwner[_owner].expirationTimestamp > 0, 'HAS_NEVER_OWNED_KEY'
    );
    _;
  }

   
  modifier hasValidKey(
    address _owner
  ) {
    require(
      getHasValidKey(_owner), 'KEY_NOT_VALID'
    );
    _;
  }

   
  modifier isKey(
    uint _tokenId
  ) {
    require(
      ownerByTokenId[_tokenId] != address(0), 'NO_SUCH_KEY'
    );
    _;
  }

   
  modifier onlyKeyOwner(
    uint _tokenId
  ) {
    require(
      isKeyOwner(_tokenId, msg.sender), 'ONLY_KEY_OWNER'
    );
    _;
  }

   
  function expireKeyFor(
    address _owner
  )
    public
    onlyOwner
    hasValidKey(_owner)
  {
    Key storage key = keyByOwner[_owner];
    key.expirationTimestamp = block.timestamp;  
    emit ExpireKey(key.tokenId);
  }

   
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint)
  {
    require(_owner != address(0), 'INVALID_ADDRESS');
    return getHasValidKey(_owner) ? 1 : 0;
  }

   
  function getHasValidKey(
    address _owner
  )
    public
    view
    returns (bool)
  {
    return keyByOwner[_owner].expirationTimestamp > block.timestamp;
  }

   
  function getTokenIdFor(
    address _account
  )
    external
    view
    hasValidKey(_account)
    returns (uint)
  {
    return keyByOwner[_account].tokenId;
  }

  
  function getOwnersByPage(uint _page, uint _pageSize)
    public
    view
    returns (address[] memory)
  {
    require(owners.length > 0, 'NO_OUTSTANDING_KEYS');
    uint pageSize = _pageSize;
    uint _startIndex = _page * pageSize;
    uint endOfPageIndex;

    if (_startIndex + pageSize > owners.length) {
      endOfPageIndex = owners.length;
      pageSize = owners.length - _startIndex;
    } else {
      endOfPageIndex = (_startIndex + pageSize);
    }

     
    address[] memory ownersByPage = new address[](pageSize);
    uint pageIndex = 0;

     
    for (uint i = _startIndex; i < endOfPageIndex; i++) {
      ownersByPage[pageIndex] = owners[i];
      pageIndex++;
    }

    return ownersByPage;
  }

   
  function isKeyOwner(
    uint _tokenId,
    address _owner
  ) public view
    returns (bool)
  {
    return ownerByTokenId[_tokenId] == _owner;
  }

   
  function keyExpirationTimestampFor(
    address _owner
  )
    public view
    ownsOrHasOwnedKey(_owner)
    returns (uint timestamp)
  {
    return keyByOwner[_owner].expirationTimestamp;
  }

   
  function numberOfOwners()
    public
    view
    returns (uint)
  {
    return owners.length;
  }

   
  function ownerOf(
    uint _tokenId
  )
    public view
    isKey(_tokenId)
    returns (address)
  {
    return ownerByTokenId[_tokenId];
  }

   
  function _assignNewTokenId(
    Key storage _key
  ) internal
  {
    if (_key.tokenId == 0) {
       
       
      numberOfKeysSold++;
       
      _key.tokenId = numberOfKeysSold;
    }
  }

   
  function _recordOwner(
    address _owner,
    uint _tokenId
  ) internal
  {
    if (ownerByTokenId[_tokenId] != _owner) {
       
      owners.push(_owner);
       
      ownerByTokenId[_tokenId] = _owner;
    }
  }

   
  function _getKeyFor(
    address _owner
  ) internal view
    returns (Key storage)
  {
    return keyByOwner[_owner];
  }
}

 

pragma solidity 0.5.9;





 
contract MixinApproval is
  IERC721,
  MixinDisableAndDestroy,
  MixinKeys
{
   
   
   
   
   
   
   
  mapping (uint => address) private approved;

   
   
   
  mapping (address => mapping (address => bool)) private ownerToOperatorApproved;

   
   
   
  modifier onlyKeyOwnerOrApproved(
    uint _tokenId
  ) {
    require(
      isKeyOwner(_tokenId, msg.sender) ||
        _isApproved(_tokenId, msg.sender) ||
        isApprovedForAll(ownerOf(_tokenId), msg.sender),
      'ONLY_KEY_OWNER_OR_APPROVED');
    _;
  }

   
  function approve(
    address _approved,
    uint _tokenId
  )
    external
    payable
    onlyIfAlive
    onlyKeyOwnerOrApproved(_tokenId)
  {
    require(msg.sender != _approved, 'APPROVE_SELF');

    approved[_tokenId] = _approved;
    emit Approval(ownerOf(_tokenId), _approved, _tokenId);
  }

   
  function setApprovalForAll(
    address _to,
    bool _approved
  ) external
    onlyIfAlive
  {
    require(_to != msg.sender, 'APPROVE_SELF');
    ownerToOperatorApproved[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function getApproved(
    uint _tokenId
  )
    external
    view
    returns (address)
  {
    return _getApproved(_tokenId);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view
    returns (bool)
  {
    return ownerToOperatorApproved[_owner][_operator];
  }

   
  function _isApproved(
    uint _tokenId,
    address _user
  ) internal view
    returns (bool)
  {
    return approved[_tokenId] == _user;
  }

   
  function _getApproved(
    uint _tokenId
  )
    internal
    view
    returns (address)
  {
    address approvedRecipient = approved[_tokenId];
    require(approvedRecipient != address(0), 'NONE_APPROVED');
    return approvedRecipient;
  }

   
  function _clearApproval(
    uint256 _tokenId
  ) internal
  {
    if (approved[_tokenId] != address(0)) {
      approved[_tokenId] = address(0);
    }
  }
}

 

pragma solidity 0.5.9;





 
contract MixinGrantKeys is
  IERC721,
  Ownable,
  MixinKeys
{
   
  function grantKey(
    address _recipient,
    uint _expirationTimestamp
  ) external
    onlyOwner
  {
    _grantKey(_recipient, _expirationTimestamp);
  }

   
  function grantKeys(
    address[] calldata _recipients,
    uint _expirationTimestamp
  ) external
    onlyOwner
  {
    for(uint i = 0; i < _recipients.length; i++) {
      _grantKey(_recipients[i], _expirationTimestamp);
    }
  }

   
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps
  ) external
    onlyOwner
  {
    for(uint i = 0; i < _recipients.length; i++) {
      _grantKey(_recipients[i], _expirationTimestamps[i]);
    }
  }

   
  function _grantKey(
    address _recipient,
    uint _expirationTimestamp
  ) private
  {
    require(_recipient != address(0), 'INVALID_ADDRESS');

    Key storage toKey = _getKeyFor(_recipient);
    require(_expirationTimestamp > toKey.expirationTimestamp, 'ALREADY_OWNS_KEY');

    _assignNewTokenId(toKey);
    _recordOwner(_recipient, toKey.tokenId);
    toKey.expirationTimestamp = _expirationTimestamp;

     
    emit Transfer(
      address(0),  
      _recipient,
      toKey.tokenId
    );
  }
}

 

pragma solidity 0.5.9;

 
 
 

contract UnlockUtils {

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d
  ) public
    pure
    returns (string memory _concatenatedString)
  {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    string memory abcd = new string(_ba.length + _bb.length + _bc.length + _bd.length);
    bytes memory babcd = bytes(abcd);
    uint k = 0;
    uint i = 0;
    for (i = 0; i < _ba.length; i++) {
      babcd[k++] = _ba[i];
    }
    for (i = 0; i < _bb.length; i++) {
      babcd[k++] = _bb[i];
    }
    for (i = 0; i < _bc.length; i++) {
      babcd[k++] = _bc[i];
    }
    for (i = 0; i < _bd.length; i++) {
      babcd[k++] = _bd[i];
    }
    return string(babcd);
  }

  function uint2Str(
    uint _i
  ) public
    pure
    returns (string memory _uintAsString)
  {
     
    uint c = _i;
    if (_i == 0) {
      return '0';
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (c != 0) {
      bstr[k--] = byte(uint8(48 + c % 10));
      c /= 10;
    }
    return string(bstr);
  }

  function address2Str(
    address _addr
  ) public
    pure
    returns(string memory)
  {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }
}

 

pragma solidity 0.5.9;







 
contract MixinLockMetadata is
  IERC721,
  ERC165,
  Ownable,
  MixinLockCore,
  UnlockUtils,
  MixinKeys
{
   
  string private lockName;

   
  string private lockSymbol;

   
  string private baseTokenURI;

  event NewLockSymbol(
    string symbol
  );

  constructor(
    string memory _lockName
  ) internal
  {
    lockName = _lockName;
     
     
    _registerInterface(0x5b5e139f);
  }

   
  function updateLockName(
    string calldata _lockName
  ) external
    onlyOwner
  {
    lockName = _lockName;
  }

   
  function name(
  ) external view
    returns (string memory)
  {
    return lockName;
  }

   
  function updateLockSymbol(
    string calldata _lockSymbol
  ) external
    onlyOwner
  {
    lockSymbol = _lockSymbol;
    emit NewLockSymbol(_lockSymbol);
  }

   
  function symbol()
    external view
    returns(string memory)
  {
    if(bytes(lockSymbol).length == 0) {
      return unlockProtocol.getGlobalTokenSymbol();
    } else {
      return lockSymbol;
    }
  }

   
  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external
    onlyOwner
  {
    baseTokenURI = _baseTokenURI;
  }

   
  function tokenURI(
    uint256 _tokenId
  ) external
    view
    isKey(_tokenId)
    returns(string memory)
  {
    string memory URI;
    if(bytes(baseTokenURI).length == 0) {
      URI = unlockProtocol.getGlobalBaseTokenURI();
    } else {
      URI = baseTokenURI;
    }

    return UnlockUtils.strConcat(
      URI,
      UnlockUtils.address2Str(address(this)),
      '/',
      UnlockUtils.uint2Str(_tokenId)
    );
  }
}

 

pragma solidity 0.5.9;


 
contract MixinNoFallback
{
   
  function()
    external
  {
    revert('NO_FALLBACK');
  }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity 0.5.9;







 
contract MixinPurchase is
  MixinFunds,
  MixinDisableAndDestroy,
  MixinLockCore,
  MixinKeys
{
  using SafeMath for uint;

   
  function purchaseFor(
    address _recipient
  )
    external
    payable
    onlyIfAlive
  {
    return _purchaseFor(_recipient, address(0));
  }

   
  function purchaseForFrom(
    address _recipient,
    address _referrer
  )
    external
    payable
    onlyIfAlive
    hasValidKey(_referrer)
  {
    return _purchaseFor(_recipient, _referrer);
  }

   
  function _purchaseFor(
    address _recipient,
    address _referrer
  )
    private
    notSoldOut()
  {  
    require(_recipient != address(0), 'INVALID_ADDRESS');

     
    uint discount;
    uint tokens;
    uint inMemoryKeyPrice = keyPrice;
    (discount, tokens) = unlockProtocol.computeAvailableDiscountFor(_recipient, inMemoryKeyPrice);
    uint netPrice = inMemoryKeyPrice;
    if (discount > inMemoryKeyPrice) {
      netPrice = 0;
    } else {
       
      netPrice = inMemoryKeyPrice - discount;
    }

     
    Key storage toKey = _getKeyFor(_recipient);

    if (toKey.tokenId == 0) {
       
      _assignNewTokenId(toKey);
      _recordOwner(_recipient, toKey.tokenId);
    }

    if (toKey.expirationTimestamp >= block.timestamp) {
       
      toKey.expirationTimestamp = toKey.expirationTimestamp.add(expirationDuration);
    } else {
       
       
      toKey.expirationTimestamp = block.timestamp + expirationDuration;
    }

    if (discount > 0) {
      unlockProtocol.recordConsumedDiscount(discount, tokens);
    }

    unlockProtocol.recordKeyPurchase(netPrice, _referrer);

     
    emit Transfer(
      address(0),  
      _recipient,
      numberOfKeysSold
    );

     
     
    _chargeAtLeast(netPrice);
  }
}

 

pragma solidity ^0.5.0;

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity 0.5.9;








contract MixinRefunds is
  Ownable,
  MixinFunds,
  MixinLockCore,
  MixinKeys
{
  using SafeMath for uint;

   
   
  uint public refundPenaltyNumerator = 1;
  uint public refundPenaltyDenominator = 10;

   
  mapping(address => uint) public keyOwnerToNonce;

  event CancelKey(
    uint indexed tokenId,
    address indexed owner,
    address indexed sendTo,
    uint refund
  );

  event RefundPenaltyChanged(
    uint oldRefundPenaltyNumerator,
    uint oldRefundPenaltyDenominator,
    uint refundPenaltyNumerator,
    uint refundPenaltyDenominator
  );

   
  function cancelAndRefund()
    external
  {
    _cancelAndRefund(msg.sender);
  }

   
  function cancelAndRefundFor(
    address _keyOwner,
    bytes calldata _signature
  ) external
  {
    require(
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          getCancelAndRefundApprovalHash(_keyOwner, msg.sender)
        ),
        _signature
      ) == _keyOwner, 'INVALID_SIGNATURE'
    );

    keyOwnerToNonce[_keyOwner]++;
    _cancelAndRefund(_keyOwner);
  }

   
  function incrementNonce(
  ) external
  {
    keyOwnerToNonce[msg.sender]++;
  }

   
  function updateRefundPenalty(
    uint _refundPenaltyNumerator,
    uint _refundPenaltyDenominator
  )
    external
    onlyOwner
  {
    require(_refundPenaltyDenominator != 0, 'INVALID_RATE');

    emit RefundPenaltyChanged(
      refundPenaltyNumerator,
      refundPenaltyDenominator,
      _refundPenaltyNumerator,
      _refundPenaltyDenominator
    );
    refundPenaltyNumerator = _refundPenaltyNumerator;
    refundPenaltyDenominator = _refundPenaltyDenominator;
  }

   
  function getCancelAndRefundValueFor(
    address _owner
  )
    external view
    returns (uint refund)
  {
    return _getCancelAndRefundValue(_owner);
  }

   
  function getCancelAndRefundApprovalHash(
    address _keyOwner,
    address _txSender
  ) public view
    returns (bytes32 approvalHash)
  {
    return keccak256(
      abi.encodePacked(
         
        address(this),
         
        keyOwnerToNonce[_keyOwner],
         
        _txSender
      )
    );
  }

   
  function _cancelAndRefund(
    address _keyOwner
  ) internal
  {
    Key storage key = _getKeyFor(_keyOwner);

    uint refund = _getCancelAndRefundValue(_keyOwner);

    emit CancelKey(key.tokenId, _keyOwner, msg.sender, refund);
     
     
    key.expirationTimestamp = block.timestamp;

    if (refund > 0) {
       
      _transfer(msg.sender, refund);
    }
  }

   
  function _getCancelAndRefundValue(
    address _owner
  )
    private view
    hasValidKey(_owner)
    returns (uint refund)
  {
    Key storage key = _getKeyFor(_owner);
     
    uint timeRemaining = key.expirationTimestamp - block.timestamp;
    if(timeRemaining >= expirationDuration) {
      refund = keyPrice;
    } else {
       
      refund = keyPrice.mul(timeRemaining) / expirationDuration;
    }
    uint penalty = keyPrice.mul(refundPenaltyNumerator) / refundPenaltyDenominator;
    if (refund > penalty) {
       
      refund -= penalty;
    } else {
      refund = 0;
    }
  }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity 0.5.9;









 

contract MixinTransfer is
  MixinFunds,
  MixinLockCore,
  MixinKeys,
  MixinApproval
{
  using SafeMath for uint;
  using Address for address;

  event TransferFeeChanged(
    uint oldTransferFeeNumerator,
    uint oldTransferFeeDenominator,
    uint transferFeeNumerator,
    uint transferFeeDenominator
  );

   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
   
   
  uint public transferFeeNumerator = 0;
  uint public transferFeeDenominator = 100;

   
  function transferFrom(
    address _from,
    address _recipient,
    uint _tokenId
  )
    public
    payable
    onlyIfAlive
    hasValidKey(_from)
    onlyKeyOwnerOrApproved(_tokenId)
  {
    require(_recipient != address(0), 'INVALID_ADDRESS');
    _chargeAtLeast(getTransferFee(_from));

    Key storage fromKey = _getKeyFor(_from);
    Key storage toKey = _getKeyFor(_recipient);

    uint previousExpiration = toKey.expirationTimestamp;

    if (toKey.tokenId == 0) {
      toKey.tokenId = fromKey.tokenId;
      _recordOwner(_recipient, toKey.tokenId);
    }

    if (previousExpiration <= block.timestamp) {
       
       
       
      toKey.expirationTimestamp = fromKey.expirationTimestamp;
      toKey.tokenId = fromKey.tokenId;
      _recordOwner(_recipient, _tokenId);
    } else {
       
       
      toKey.expirationTimestamp = fromKey
        .expirationTimestamp.add(previousExpiration - block.timestamp);
    }

     
    fromKey.expirationTimestamp = block.timestamp;

     
    fromKey.tokenId = 0;

     
    _clearApproval(_tokenId);

     
    emit Transfer(
      _from,
      _recipient,
      _tokenId
    );
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    external
    payable
  {
    safeTransferFrom(_from, _to, _tokenId, '');
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes memory _data
  )
    public
    payable
    onlyIfAlive
    onlyKeyOwnerOrApproved(_tokenId)
    hasValidKey(ownerOf(_tokenId))
  {
    transferFrom(_from, _to, _tokenId);
    require(_checkOnERC721Received(_from, _to, _tokenId, _data), 'NON_COMPLIANT_ERC721_RECEIVER');

  }

   
  function updateTransferFee(
    uint _transferFeeNumerator,
    uint _transferFeeDenominator
  )
    external
    onlyOwner
  {
    require(_transferFeeDenominator != 0, 'INVALID_RATE');
    emit TransferFeeChanged(
      transferFeeNumerator,
      transferFeeDenominator,
      _transferFeeNumerator,
      _transferFeeDenominator
    );
    transferFeeNumerator = _transferFeeNumerator;
    transferFeeDenominator = _transferFeeDenominator;
  }

   
  function getTransferFee(
    address _owner
  )
    public view
    hasValidKey(_owner)
    returns (uint)
  {
    Key storage key = _getKeyFor(_owner);
     
    uint timeRemaining = key.expirationTimestamp - block.timestamp;
    uint fee;
    if(timeRemaining >= expirationDuration) {
       
      fee = keyPrice;
    } else {
       
      fee = keyPrice.mul(timeRemaining) / expirationDuration;
    }
    return fee.mul(transferFeeNumerator) / transferFeeDenominator;
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

}

 

pragma solidity 0.5.9;

















 
contract PublicLock is
  IERC721,
  MixinNoFallback,
  ERC165,
  Ownable,
  ERC721Holder,
  MixinFunds,
  MixinDisableAndDestroy,
  MixinLockCore,
  MixinKeys,
  MixinLockMetadata,
  MixinGrantKeys,
  MixinPurchase,
  MixinApproval,
  MixinTransfer,
  MixinRefunds
{
  constructor(
    address _owner,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string memory _lockName
  )
    public
    MixinFunds(_tokenAddress)
    MixinLockCore(_owner, _expirationDuration, _keyPrice, _maxNumberOfKeys)
    MixinLockMetadata(_lockName)
  {
     
     
    _registerInterface(0x80ac58cd);
     
    Ownable.initialize(_owner);
  }

   
  function publicLockVersion(
  ) external pure
    returns (uint16)
  {
    return 4;
  }
}