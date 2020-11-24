 

 

pragma solidity 0.5.7;

 
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

 

pragma solidity 0.5.7;

 
contract RedTokenAccessControl {

  event Paused();
  event Unpaused();
  event PausedUser(address indexed account);
  event UnpausedUser(address indexed account);

   
  address public ceoAddress;

   
  address public cfoAddress;

   
  address public cooAddress;

  bool public paused = false;

   
  mapping (address => bool) private pausedUsers;

   
  constructor () internal {
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
  }

   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress ||
      msg.sender == cfoAddress
    );
    _;
  }

   
  modifier onlyCEOOrCFO() {
    require(
      msg.sender == cfoAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

   
  modifier onlyCEOOrCOO() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

   
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

   
  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

   
  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

   
   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() external onlyCLevel whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() external onlyCLevel whenPaused {
    paused = false;
    emit Unpaused();
  }

   
   
  modifier whenNotPausedUser(address account) {
    require(account != address(0));
    require(!pausedUsers[account]);
    _;
  }

   
  modifier whenPausedUser(address account) {
    require(account != address(0));
    require(pausedUsers[account]);
    _;
  }

   
  function has(address account) internal view returns (bool) {
      require(account != address(0));
      return pausedUsers[account];
  }
  
   
  function _addPauseUser(address account) internal {
      require(account != address(0));
      require(!has(account));

      pausedUsers[account] = true;

      emit PausedUser(account);
  }

   
  function _unpausedUser(address account) internal {
      require(account != address(0));
      require(has(account));

      pausedUsers[account] = false;
      emit UnpausedUser(account);
  }

   
  function isPausedUser(address account) external view returns (bool) {
      return has(account);
  }

   
  function pauseUser(address account) external onlyCOO whenNotPausedUser(account) {
    _addPauseUser(account);
  }

   
  function unpauseUser(address account) external onlyCLevel whenPausedUser(account) {
    _unpausedUser(account);
  }
}

 

pragma solidity 0.5.7;



 
contract RedTokenBase is RedTokenAccessControl {
  using SafeMath for uint256;

    
  struct RedToken {
    uint256 tokenId;
    string rmsBondNo;
    uint256 bondAmount;
    uint256 listingAmount;
    uint256 collectedAmount;
    uint createdTime;
    bool isValid;
  }

   
  mapping (uint256 => mapping(address => uint256)) shareUsers;

   
  mapping (uint256 => address []) shareUsersKeys;

   
  event RedTokenCreated(
    address account, 
    uint256 tokenId, 
    string rmsBondNo, 
    uint256 bondAmount, 
    uint256 listingAmount, 
    uint256 collectedAmount, 
    uint createdTime
  );
  
   
  RedToken[] redTokens;
  
   
  function redTokenRmsBondNo(uint256 _tokenId) external view returns (string memory) {
    return redTokens[_tokenId].rmsBondNo;
  }

   
  function redTokenBondAmount(uint256 _tokenId) external view returns (uint256) {
    return redTokens[_tokenId].bondAmount;
  }

   
  function redTokenListingAmount(uint256 _tokenId) external view returns (uint256) {
    return redTokens[_tokenId].listingAmount;
  }
  
   
  function redTokenCollectedAmount(uint256 _tokenId) external view returns (uint256) {
    return redTokens[_tokenId].collectedAmount;
  }

   
  function redTokenCreatedTime(uint256 _tokenId) external view returns (uint) {
    return redTokens[_tokenId].createdTime;
  }

   
  function isValidRedToken(uint256 _tokenId) public view returns (bool) {
    return redTokens[_tokenId].isValid;
  }

   
  function redTokenInfo(uint256 _tokenId)
    external view returns (uint256, string memory, uint256, uint256, uint256, uint)
  {
    require(isValidRedToken(_tokenId));
    RedToken memory _redToken = redTokens[_tokenId];

    return (
        _redToken.tokenId,
        _redToken.rmsBondNo,
        _redToken.bondAmount,
        _redToken.listingAmount,
        _redToken.collectedAmount,
        _redToken.createdTime
    );
  }
  
   
  function redTokenInfoOfshareUsers(uint256 _tokenId) external view returns (address[] memory, uint256[] memory) {
    require(isValidRedToken(_tokenId));

    uint256 keySize = shareUsersKeys[_tokenId].length;

    address[] memory addrs   = new address[](keySize);
    uint256[] memory amounts = new uint256[](keySize);

    for (uint index = 0; index < keySize; index++) {
      addrs[index]   = shareUsersKeys[_tokenId][index];
      amounts[index] = shareUsers[_tokenId][addrs[index]];
    }
    
    return (addrs, amounts);
  }
}

 

pragma solidity 0.5.7;

 
 
 
interface ERC721 {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

pragma solidity 0.5.7;

 
interface ERC721Metadata   {
    
     
    function name() external pure returns (string memory _name);

      
    function symbol() external pure returns (string memory _symbol);

     
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

 

pragma solidity 0.5.7;

 
interface ERC721Enumerable   {
     
    function totalSupply() external view returns (uint256);

     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

 

pragma solidity 0.5.7;

interface ERC165 {
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 

pragma solidity 0.5.7;

library Strings {
   
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
  }

  function uint2str(uint i) internal pure returns (string memory) {
    if (i == 0) return "0";
    uint j = i;
    uint len;
    while (j != 0){
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0){
        bstr[k--] = byte(uint8(48 + i % 10));
        i /= 10;
    }
    return string(bstr);
  }
}

 

pragma solidity 0.5.7;

 
interface ERC721TokenReceiver {
     
	function onERC721Received(address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

 

pragma solidity 0.5.7;








 
contract RedTokenOwnership is RedTokenBase, ERC721, ERC165, ERC721Metadata, ERC721Enumerable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping (uint256 => uint256) internal ownedTokensIndex;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  event calculateShareUsers(uint256 tokenId, address owner, address from, address to, uint256 amount);
  event CollectedAmountUpdate(uint256 tokenId, address owner, uint256 amount);

   
   
  string internal constant NAME = "RedToken";
  string internal constant SYMBOL = "REDT";
  string internal tokenMetadataBaseURI = "https://doc.reditus.co.kr/?docid=";

   
  function supportsInterface(
    bytes4 interfaceID)  
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector ||  
      interfaceID == 0x5b5e139f ||  
      interfaceID == 0x80ac58cd ||  
      interfaceID == 0x780e9d63;  
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

     
   
  function name() external pure returns (string memory) {
    return NAME;
  }

   
  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

   
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory infoUrl)
  {
    if ( isValidRedToken(_tokenId) ){
      return Strings.strConcat( tokenMetadataBaseURI, Strings.uint2str(_tokenId));
    }else{
      return Strings.strConcat( tokenMetadataBaseURI, Strings.uint2str(_tokenId));
    }
  }

   
  function setTokenMetadataBaseURI(string calldata _newBaseURI) external onlyCOO {
    tokenMetadataBaseURI = _newBaseURI;
  }

   
  function totalSupply() external view returns (uint256) {
    return totalTokens;
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) external view returns (uint256[] memory) {
    require(_owner != address(0));
    return ownedTokens[_owner];
  }

   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < totalTokens);
    return _index;
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function approve(address _to, uint256 _tokenId)
    external
    payable
    whenNotPaused
    whenNotPausedUser(msg.sender)
    onlyOwnerOf(_tokenId)
  {
    require(_to != ownerOf(_tokenId));
    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;

      emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }
  }

   
  function setApprovalForAll(address _to, bool _approved)
    external
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

   
  function approveAll(address _to)
    internal
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    require(_to != msg.sender);
    require(_to != address(0));
    operatorApprovals[msg.sender][_to] = true;

    emit ApprovalForAll(msg.sender, _to, true);
  }

   
  function disapproveAll(address _to)
    internal
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    require(_to != msg.sender);
    delete operatorApprovals[msg.sender][_to];
    
    emit ApprovalForAll(msg.sender, _to, false);
  }

   
  function isSenderApprovedFor(uint256 _tokenId) public view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      getApproved(_tokenId) == msg.sender ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }
  
   
  function transfer(address _to, uint256 _tokenId)
    external
    payable
    whenNotPaused
    whenNotPausedUser(msg.sender)
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    payable
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    require(isSenderApprovedFor(_tokenId));
    _clearApprovalAndTransfer(_from, _to, _tokenId);
  }
  
   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    payable
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    require(isSenderApprovedFor(_tokenId));
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    payable
    whenNotPaused
    whenNotPausedUser(msg.sender)
  {
    require(isSenderApprovedFor(_tokenId));
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

   
  function sendAmountShareUsers(
    uint256 _tokenId, 
    address _to, 
    uint256 _amount
  ) 
    external 
    onlyCOO
    returns (bool) 
  {
    require(_to != address(0));
    return _calculateShareUsers(_tokenId, ownerOf(_tokenId), _to, _amount);
  }

   
  function sendAmountShareUsersFrom(
    uint256 _tokenId, 
    address _from, 
    address _to, 
    uint256 _amount
  ) 
    external 
    onlyCOO
    returns (bool) 
  {
    require(_to != address(0));
    return _calculateShareUsers(_tokenId, _from, _to, _amount);
  }

   
  function updateCollectedAmount(
    uint256 _tokenId, 
    uint256 _amount
  ) 
    external 
    onlyCOO 
    returns (bool) 
  {
    require(isValidRedToken(_tokenId));
    require(_amount > 0);
        
    redTokens[_tokenId].collectedAmount = redTokens[_tokenId].collectedAmount.add(_amount);
    
    emit CollectedAmountUpdate(_tokenId, ownerOf(_tokenId), _amount);
    return true;
  }

   
  function createRedToken(
    address _user, 
    string calldata _rmsBondNo, 
    uint256 _bondAmount, 
    uint256 _listingAmount
  ) 
    external 
    onlyCOO 
    returns (uint256) 
  {
    return _createRedToken(_user,_rmsBondNo,_bondAmount,_listingAmount);
  }

   
  function burnAmountByShareUser(
    uint256 _tokenId, 
    address _from, 
    uint256 _amount
  ) 
    external 
    onlyCOO 
    returns (bool) 
  {
    return _calculateShareUsers(_tokenId, _from, address(0), _amount);
  }
  
   
  function burn(
    address _owner, 
    uint256 _tokenId
  ) 
    external 
    onlyCOO 
    returns(bool) 
  {
    require(_owner != address(0));
    return _burn(_owner, _tokenId);
  }

   
  function isContract(address _addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

   
  function isShareUser(
    uint256 _tokenId, 
    address _from
  ) 
    internal  
    view 
    returns (bool) 
  {
    bool chechedUser = false;
    for (uint index = 0; index < shareUsersKeys[_tokenId].length; index++) {
      if (  shareUsersKeys[_tokenId][index] == _from ){
        chechedUser = true;
        break;
      }
    }
    return chechedUser;
  }

   
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
  {
    _clearApprovalAndTransfer(_from, _to, _tokenId);

    if (isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
    }
  }

   
  function _clearApprovalAndTransfer(
    address _from, 
    address _to, 
    uint256 _tokenId
  )
    internal 
  {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);
    require(isValidRedToken(_tokenId));
    
    address owner = ownerOf(_tokenId);

    _clearApproval(owner, _tokenId);
    _removeToken(owner, _tokenId);
    _addToken(_to, _tokenId);
    _changeTokenShareUserByOwner(owner, _to, _tokenId);

    emit Transfer(owner, _to, _tokenId);
  }

   
  function _changeTokenShareUserByOwner(
    address _from, 
    address _to, 
    uint256 _tokenId
  ) 
    internal  
  {
    uint256 amount = shareUsers[_tokenId][_from];
    delete shareUsers[_tokenId][_from];

    shareUsers[_tokenId][_to] = shareUsers[_tokenId][_to].add(amount);

    if ( !isShareUser(_tokenId, _to) ) {
      shareUsersKeys[_tokenId].push(_to);
    }
  }

   
  function _calculateShareUsers(
    uint256 _tokenId, 
    address _from, 
    address _to, 
    uint256 _amount
  ) 
    internal
    returns (bool) 
  {
    require(_from != address(0));
    require(_from != _to);
    require(_amount > 0);
    require(shareUsers[_tokenId][_from] >= _amount);
    require(isValidRedToken(_tokenId));
    
    shareUsers[_tokenId][_from] = shareUsers[_tokenId][_from].sub(_amount);
    shareUsers[_tokenId][_to] = shareUsers[_tokenId][_to].add(_amount);

    if ( !isShareUser(_tokenId, _to) ) {
      shareUsersKeys[_tokenId].push(_to);
    }

    emit calculateShareUsers(_tokenId, ownerOf(_tokenId), _from, _to, _amount);
    return true;
  }

   
  function _clearApproval(
    address _owner,
    uint256 _tokenId
  ) 
    internal 
  {
    require(ownerOf(_tokenId) == _owner);
    
    tokenApprovals[_tokenId] = address(0);

    emit Approval(_owner, address(0), _tokenId);
  }

  function _createRedToken(
    address _user, 
    string memory _rmsBondNo, 
    uint256 _bondAmount, 
    uint256 _listingAmount
  ) 
    internal 
    returns (uint256)
  {
    require(_user != address(0));
    require(bytes(_rmsBondNo).length > 0);
    require(_bondAmount > 0);
    require(_listingAmount > 0);

    uint256 _newTokenId = redTokens.length;

    RedToken memory _redToken = RedToken({
      tokenId: _newTokenId,
      rmsBondNo: _rmsBondNo,
      bondAmount: _bondAmount,
      listingAmount: _listingAmount,
      collectedAmount: 0,
      createdTime: now,
      isValid:true
    });

    redTokens.push(_redToken) - 1;

    shareUsers[_newTokenId][_user] = shareUsers[_newTokenId][_user].add(_listingAmount);
    shareUsersKeys[_newTokenId].push(_user);

    _addToken(_user, _newTokenId);

    emit RedTokenCreated(_user,
                        _redToken.tokenId,
                        _redToken.rmsBondNo,
                        _redToken.bondAmount,
                        _redToken.listingAmount,
                        _redToken.collectedAmount,
                        _redToken.createdTime);
    
    return _newTokenId;
  }
  
   
  function _addToken(
    address _to, 
    uint256 _tokenId
  ) 
    internal 
  {
    require(tokenOwner[_tokenId] == address(0));

    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function _removeToken(
    address _from, 
    uint256 _tokenId
  ) 
    internal 
  {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = address(0);
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

   
  function _burn(
    address _owner, 
    uint256 _tokenId
  ) 
    internal 
    returns(bool) 
  {
    require(ownerOf(_tokenId) == _owner);
    _clearApproval(_owner, _tokenId);
    _removeToken(_owner, _tokenId);

    redTokens[_tokenId].isValid = false;

    emit Transfer(_owner, address(0), _tokenId);
    return true;
  }
}

 

pragma solidity 0.5.7;


 
contract RedTokenCore is RedTokenOwnership{

  constructor() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
  }

  function() external {
    assert(false);
  }
}