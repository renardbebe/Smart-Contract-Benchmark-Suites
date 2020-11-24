 

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;
 
 
interface IIndexer {
  event CreateIndex(
    address indexed signerToken,
    address indexed senderToken,
    address indexAddress
  );
  event Stake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    uint256 stakeAmount
  );
  event Unstake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    uint256 stakeAmount
  );
  event AddTokenToBlacklist(
    address token
  );
  event RemoveTokenFromBlacklist(
    address token
  );
  function setLocatorWhitelist(
    address newLocatorWhitelist
  ) external;
  function createIndex(
    address signerToken,
    address senderToken
  ) external returns (address);
  function addTokenToBlacklist(
    address token
  ) external;
  function removeTokenFromBlacklist(
    address token
  ) external;
  function setIntent(
    address signerToken,
    address senderToken,
    uint256 stakingAmount,
    bytes32 locator
  ) external;
  function unsetIntent(
    address signerToken,
    address senderToken
  ) external;
  function stakingToken() external view returns (address);
  function indexes(address, address) external view returns (address);
  function tokenBlacklist(address) external view returns (bool);
  function getStakedAmount(
    address user,
    address signerToken,
    address senderToken
  ) external view returns (uint256);
  function getLocators(
    address signerToken,
    address senderToken,
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory,
    uint256[] memory,
    address
  );
}
 
 
interface ILocatorWhitelist {
  function has(
    bytes32 locator
  ) external view returns (bool);
}
 
 
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
     
    function owner() public view returns (address) {
        return _owner;
    }
     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
 
 
contract Index is Ownable {
   
  uint256 public length;
   
  address constant internal HEAD = address(uint160(2**160-1));
   
  mapping(address => Entry) public entries;
   
  struct Entry {
    bytes32 locator;
    uint256 score;
    address prev;
    address next;
  }
   
  event SetLocator(
    address indexed identifier,
    uint256 score,
    bytes32 indexed locator
  );
  event UnsetLocator(
    address indexed identifier
  );
   
  constructor() public {
     
    entries[HEAD] = Entry(bytes32(0), 0, HEAD, HEAD);
  }
   
  function setLocator(
    address identifier,
    uint256 score,
    bytes32 locator
  ) external onlyOwner {
     
    require(!_hasEntry(identifier), "ENTRY_ALREADY_EXISTS");
     
    address nextEntry = _getEntryLowerThan(score);
     
    address prevEntry = entries[nextEntry].prev;
    entries[prevEntry].next = identifier;
    entries[nextEntry].prev = identifier;
    entries[identifier] = Entry(locator, score, prevEntry, nextEntry);
     
    length = length + 1;
    emit SetLocator(identifier, score, locator);
  }
   
  function unsetLocator(
    address identifier
  ) external onlyOwner {
     
    require(_hasEntry(identifier), "ENTRY_DOES_NOT_EXIST");
     
    address prevUser = entries[identifier].prev;
    address nextUser = entries[identifier].next;
    entries[prevUser].next = nextUser;
    entries[nextUser].prev = prevUser;
     
    delete entries[identifier];
     
    length = length - 1;
    emit UnsetLocator(identifier);
  }
   
  function getScore(
    address identifier
  ) external view returns (uint256) {
    return entries[identifier].score;
  }
     
  function getLocator(
    address identifier
  ) external view returns (bytes32) {
    return entries[identifier].locator;
  }
   
  function getLocators(
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory locators,
    uint256[] memory scores,
    address nextCursor
  ) {
    address identifier;
     
    if (cursor != address(0) && cursor != HEAD) {
       
      if (!_hasEntry(cursor)) {
        return (new bytes32[](0), new uint256[](0), address(0));
      }
       
      identifier = cursor;
    } else {
      identifier = entries[HEAD].next;
    }
     
     
    uint256 size = (length < limit) ? length : limit;
    locators = new bytes32[](size);
    scores = new uint256[](size);
     
    uint256 i;
    while (i < size && identifier != HEAD) {
      locators[i] = entries[identifier].locator;
      scores[i] = entries[identifier].score;
      i = i + 1;
      identifier = entries[identifier].next;
    }
    return (locators, scores, identifier);
  }
   
  function _hasEntry(
    address identifier
  ) internal view returns (bool) {
    return entries[identifier].locator != bytes32(0);
  }
   
  function _getEntryLowerThan(
    uint256 score
  ) internal view returns (address) {
    address identifier = entries[HEAD].next;
     
    if (score == 0) {
      return HEAD;
    }
     
    while (score <= entries[identifier].score) {
      identifier = entries[identifier].next;
    }
    return identifier;
  }
}
 
 
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
 
 
 
contract Indexer is IIndexer, Ownable {
   
  IERC20 public stakingToken;
   
  mapping (address => mapping (address => Index)) public indexes;
   
  mapping (address => bool) public tokenBlacklist;
   
  address public locatorWhitelist;
   
  constructor(
    address indexerStakingToken
  ) public {
    stakingToken = IERC20(indexerStakingToken);
  }
   
  modifier indexExists(address signerToken, address senderToken) {
    require(indexes[signerToken][senderToken] != Index(0),
      "INDEX_DOES_NOT_EXIST");
    _;
  }
   
  function setLocatorWhitelist(
    address newLocatorWhitelist
  ) external onlyOwner {
    locatorWhitelist = newLocatorWhitelist;
  }
   
  function createIndex(
    address signerToken,
    address senderToken
  ) external returns (address) {
     
    if (indexes[signerToken][senderToken] == Index(0)) {
       
      indexes[signerToken][senderToken] = new Index();
      emit CreateIndex(signerToken, senderToken, address(indexes[signerToken][senderToken]));
    }
     
    return address(indexes[signerToken][senderToken]);
  }
   
  function addTokenToBlacklist(
    address token
  ) external onlyOwner {
    if (!tokenBlacklist[token]) {
      tokenBlacklist[token] = true;
      emit AddTokenToBlacklist(token);
    }
  }
   
  function removeTokenFromBlacklist(
    address token
  ) external onlyOwner {
    if (tokenBlacklist[token]) {
      tokenBlacklist[token] = false;
      emit RemoveTokenFromBlacklist(token);
    }
  }
   
  function setIntent(
    address signerToken,
    address senderToken,
    uint256 stakingAmount,
    bytes32 locator
  ) external indexExists(signerToken, senderToken) {
     
    if (locatorWhitelist != address(0)) {
      require(ILocatorWhitelist(locatorWhitelist).has(locator),
      "LOCATOR_NOT_WHITELISTED");
    }
     
    require(!tokenBlacklist[signerToken] && !tokenBlacklist[senderToken],
      "PAIR_IS_BLACKLISTED");
    bool notPreviouslySet = (indexes[signerToken][senderToken].getLocator(msg.sender) == bytes32(0));
    if (notPreviouslySet) {
       
      if (stakingAmount > 0) {
         
        require(stakingToken.transferFrom(msg.sender, address(this), stakingAmount),
          "UNABLE_TO_STAKE");
      }
       
      indexes[signerToken][senderToken].setLocator(msg.sender, stakingAmount, locator);
      emit Stake(msg.sender, signerToken, senderToken, stakingAmount);
    } else {
      uint256 oldStake = indexes[signerToken][senderToken].getScore(msg.sender);
      _updateIntent(msg.sender, signerToken, senderToken, stakingAmount, locator, oldStake);
    }
  }
   
  function unsetIntent(
    address signerToken,
    address senderToken
  ) external {
    _unsetIntent(msg.sender, signerToken, senderToken);
  }
   
  function getLocators(
    address signerToken,
    address senderToken,
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory locators,
    uint256[] memory scores,
    address nextCursor
  ) {
     
    if (tokenBlacklist[signerToken] || tokenBlacklist[senderToken]) {
      return (new bytes32[](0), new uint256[](0), address(0));
    }
     
    if (indexes[signerToken][senderToken] == Index(0)) {
      return (new bytes32[](0), new uint256[](0), address(0));
    }
    return indexes[signerToken][senderToken].getLocators(cursor, limit);
  }
   
  function getStakedAmount(
    address user,
    address signerToken,
    address senderToken
  ) public view returns (uint256 stakedAmount) {
    if (indexes[signerToken][senderToken] == Index(0)) {
      return 0;
    }
     
    return indexes[signerToken][senderToken].getScore(user);
  }
  function _updateIntent(
    address user,
    address signerToken,
    address senderToken,
    uint256 newAmount,
    bytes32 newLocator,
    uint256 oldAmount
  ) internal {
     
    if (oldAmount < newAmount) {
       
      require(stakingToken.transferFrom(user, address(this), newAmount - oldAmount),
        "UNABLE_TO_STAKE");
    }
     
    if (newAmount < oldAmount) {
       
      require(stakingToken.transfer(user, oldAmount - newAmount));
    }
     
    indexes[signerToken][senderToken].unsetLocator(user);
    indexes[signerToken][senderToken].setLocator(user, newAmount, newLocator);
    emit Stake(user, signerToken, senderToken, newAmount);
  }
   
  function _unsetIntent(
    address user,
    address signerToken,
    address senderToken
  ) internal indexExists(signerToken, senderToken) {
      
    uint256 score = indexes[signerToken][senderToken].getScore(user);
     
    indexes[signerToken][senderToken].unsetLocator(user);
    if (score > 0) {
       
      require(stakingToken.transfer(user, score));
    }
    emit Unstake(user, signerToken, senderToken, score);
  }
}