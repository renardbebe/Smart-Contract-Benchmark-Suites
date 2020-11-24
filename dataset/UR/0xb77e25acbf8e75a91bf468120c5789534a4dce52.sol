 

pragma solidity ^0.4.21;

 

interface ERC165 {
   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }


   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string _a, string _b, string _c) internal pure returns (string) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }

  function bytes16ToStr(bytes16 _bytes16, uint8 _start, uint8 _end) internal pure returns (string) {
    bytes memory bytesArray = new bytes(_end - _start);
    uint8 pos = 0;
    for (uint8 i = _start; i < _end; i++) {
      bytesArray[pos] = _bytes16[i];
      pos++;
    }
    return string(bytesArray);
  }
}

 

 
contract KnownOriginDigitalAsset is ERC721Token, ERC165 {
  using SafeMath for uint256;

  bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
     

  bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
     

  bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
     

  bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
     

  bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
     

   
  function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
    return ((_interfaceID == InterfaceSignature_ERC165)
    || (_interfaceID == InterfaceSignature_ERC721)
    || (_interfaceID == InterfaceSignature_ERC721Optional)
    || (_interfaceID == InterfaceSignature_ERC721Enumerable)
    || (_interfaceID == InterfaceSignature_ERC721Metadata));
  }

  struct CommissionStructure {
    uint8 curator;
    uint8 developer;
  }

  string internal tokenBaseURI = "https://ipfs.infura.io/ipfs/";

   
  address public curatorAccount;

   
  address public developerAccount;

   
  uint256 public totalPurchaseValueInWei;

   
  uint256 public totalNumberOfPurchases;

   
  uint256 public tokenIdPointer = 0;

  enum PurchaseState {Unsold, EtherPurchase, FiatPurchase}

  mapping(string => CommissionStructure) internal editionTypeToCommission;
  mapping(uint256 => PurchaseState) internal tokenIdToPurchased;

  mapping(uint256 => bytes16) internal tokenIdToEdition;
  mapping(uint256 => uint256) internal tokenIdToPriceInWei;
  mapping(uint256 => uint32) internal tokenIdToPurchaseFromTime;

  mapping(bytes16 => uint256) internal editionToEditionNumber;
  mapping(bytes16 => address) internal editionToArtistAccount;

  event PurchasedWithEther(uint256 indexed _tokenId, address indexed _buyer);

  event PurchasedWithFiat(uint256 indexed _tokenId);

  event PurchasedWithFiatReversed(uint256 indexed _tokenId);

  modifier onlyCurator() {
    require(msg.sender == curatorAccount);
    _;
  }

  modifier onlyUnsold(uint256 _tokenId) {
    require(tokenIdToPurchased[_tokenId] == PurchaseState.Unsold);
    _;
  }

  modifier onlyFiatPurchased(uint256 _tokenId) {
    require(tokenIdToPurchased[_tokenId] == PurchaseState.FiatPurchase);
    _;
  }

  modifier onlyKnownOriginOwnedToken(uint256 _tokenId) {
    require(tokenOwner[_tokenId] == curatorAccount || tokenOwner[_tokenId] == developerAccount);
    _;
  }

  modifier onlyKnownOrigin() {
    require(msg.sender == curatorAccount || msg.sender == developerAccount);
    _;
  }

  modifier onlyAfterPurchaseFromTime(uint256 _tokenId) {
    require(tokenIdToPurchaseFromTime[_tokenId] <= block.timestamp);
    _;
  }


  function KnownOriginDigitalAsset(address _curatorAccount) public ERC721Token("KnownOriginDigitalAsset", "KODA") {
    developerAccount = msg.sender;
    curatorAccount = _curatorAccount;
  }

   
  function() public payable {
    revert();
  }

   
  function mint(string _tokenURI, bytes16 _edition, uint256 _priceInWei, uint32 _auctionStartDate, address _artistAccount) external onlyKnownOrigin {
    require(_artistAccount != address(0));

    uint256 _tokenId = tokenIdPointer;

    super._mint(msg.sender, _tokenId);
    super._setTokenURI(_tokenId, _tokenURI);

    editionToArtistAccount[_edition] = _artistAccount;

    _populateTokenData(_tokenId, _edition, _priceInWei, _auctionStartDate);

    tokenIdPointer = tokenIdPointer.add(1);
  }

  function _populateTokenData(uint _tokenId, bytes16 _edition, uint256 _priceInWei, uint32 _purchaseFromTime) internal {
    tokenIdToEdition[_tokenId] = _edition;
    editionToEditionNumber[_edition] = editionToEditionNumber[_edition].add(1);
    tokenIdToPriceInWei[_tokenId] = _priceInWei;
    tokenIdToPurchaseFromTime[_tokenId] = _purchaseFromTime;
  }

   
  function burn(uint256 _tokenId) public onlyKnownOrigin onlyUnsold(_tokenId) onlyKnownOriginOwnedToken(_tokenId) {
    require(exists(_tokenId));
    super._burn(ownerOf(_tokenId), _tokenId);

    bytes16 edition = tokenIdToEdition[_tokenId];

    delete tokenIdToEdition[_tokenId];
    delete tokenIdToPriceInWei[_tokenId];
    delete tokenIdToPurchaseFromTime[_tokenId];

    editionToEditionNumber[edition] = editionToEditionNumber[edition].sub(1);
  }

   
  function setTokenURI(uint256 _tokenId, string _uri) external onlyKnownOrigin {
    require(exists(_tokenId));
    _setTokenURI(_tokenId, _uri);
  }

   
  function setPriceInWei(uint _tokenId, uint256 _priceInWei) external onlyKnownOrigin onlyUnsold(_tokenId) {
    require(exists(_tokenId));
    tokenIdToPriceInWei[_tokenId] = _priceInWei;
  }

   
  function _approvePurchaser(address _to, uint256 _tokenId) internal {
    address owner = ownerOf(_tokenId);
    require(_to != address(0));

    tokenApprovals[_tokenId] = _to;
    Approval(owner, _to, _tokenId);
  }

   
  function updateCommission(string _type, uint8 _curator, uint8 _developer) external onlyKnownOrigin {
    require(_curator > 0);
    require(_developer > 0);
    require((_curator + _developer) < 100);

    editionTypeToCommission[_type] = CommissionStructure({curator : _curator, developer : _developer});
  }

   
  function getCommissionForType(string _type) public view returns (uint8 _curator, uint8 _developer) {
    CommissionStructure storage commission = editionTypeToCommission[_type];
    return (commission.curator, commission.developer);
  }

   
  function purchaseWithEther(uint256 _tokenId) public payable onlyUnsold(_tokenId) onlyKnownOriginOwnedToken(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

    uint256 priceInWei = tokenIdToPriceInWei[_tokenId];
    require(msg.value >= priceInWei);

     
    _approvePurchaser(msg.sender, _tokenId);

     
    safeTransferFrom(curatorAccount, msg.sender, _tokenId);

     
    tokenIdToPurchased[_tokenId] = PurchaseState.EtherPurchase;

    totalPurchaseValueInWei = totalPurchaseValueInWei.add(msg.value);
    totalNumberOfPurchases = totalNumberOfPurchases.add(1);

     
    if (priceInWei > 0) {
      _applyCommission(_tokenId);
    }

    PurchasedWithEther(_tokenId, msg.sender);
  }

   
  function purchaseWithFiat(uint256 _tokenId) public onlyKnownOrigin onlyUnsold(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

     
    tokenIdToPurchased[_tokenId] = PurchaseState.FiatPurchase;

    totalNumberOfPurchases = totalNumberOfPurchases.add(1);

    PurchasedWithFiat(_tokenId);
  }

   
  function reverseFiatPurchase(uint256 _tokenId) public onlyKnownOrigin onlyFiatPurchased(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

     
    tokenIdToPurchased[_tokenId] = PurchaseState.Unsold;

    totalNumberOfPurchases = totalNumberOfPurchases.sub(1);

    PurchasedWithFiatReversed(_tokenId);
  }

   
  function _applyCommission(uint256 _tokenId) internal {
    bytes16 edition = tokenIdToEdition[_tokenId];

    string memory typeCode = getTypeFromEdition(edition);

    CommissionStructure memory commission = editionTypeToCommission[typeCode];

     
    uint curatorAccountFee = msg.value / 100 * commission.curator;
    curatorAccount.transfer(curatorAccountFee);

     
    uint developerAccountFee = msg.value / 100 * commission.developer;
    developerAccount.transfer(developerAccountFee);

     
    uint finalCommissionTotal = msg.value - (curatorAccountFee + developerAccountFee);

     
    address artistAccount = editionToArtistAccount[edition];
    artistAccount.transfer(finalCommissionTotal);
  }

   
  function assetInfo(uint _tokenId) public view returns (
    uint256 _tokId,
    address _owner,
    PurchaseState _purchaseState,
    uint256 _priceInWei,
    uint32 _purchaseFromTime
  ) {
    return (
      _tokenId,
      tokenOwner[_tokenId],
      tokenIdToPurchased[_tokenId],
      tokenIdToPriceInWei[_tokenId],
      tokenIdToPurchaseFromTime[_tokenId]
    );
  }

   
  function editionInfo(uint256 _tokenId) public view returns (
    uint256 _tokId,
    bytes16 _edition,
    uint256 _editionNumber,
    string _tokenURI,
    address _artistAccount
  ) {
    bytes16 edition = tokenIdToEdition[_tokenId];
    return (
      _tokenId,
      edition,
      editionToEditionNumber[edition],
      tokenURI(_tokenId),
      editionToArtistAccount[edition]
    );
  }

  function tokensOf(address _owner) public view returns (uint256[] _tokenIds) {
    return ownedTokens[_owner];
  }

   
  function numberOf(bytes16 _edition) public view returns (uint256) {
    return editionToEditionNumber[_edition];
  }

   
  function isPurchased(uint256 _tokenId) public view returns (PurchaseState _purchased) {
    require(exists(_tokenId));
    return tokenIdToPurchased[_tokenId];
  }

   
  function editionOf(uint256 _tokenId) public view returns (bytes16 _edition) {
    require(exists(_tokenId));
    return tokenIdToEdition[_tokenId];
  }

   
  function purchaseFromTime(uint256 _tokenId) public view returns (uint32 _purchaseFromTime) {
    require(exists(_tokenId));
    return tokenIdToPurchaseFromTime[_tokenId];
  }

   
  function priceInWei(uint256 _tokenId) public view returns (uint256 _priceInWei) {
    require(exists(_tokenId));
    return tokenIdToPriceInWei[_tokenId];
  }

   
  function getTypeFromEdition(bytes16 _edition) public pure returns (string) {
     
    return Strings.bytes16ToStr(_edition, 13, 16);
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

   
  function setTokenBaseURI(string _newBaseURI) external onlyKnownOrigin {
    tokenBaseURI = _newBaseURI;
  }

   
  function setArtistAccount(bytes16 _edition, address _artistAccount) external onlyKnownOrigin {
    require(_artistAccount != address(0));

    editionToArtistAccount[_edition] = _artistAccount;
  }
}