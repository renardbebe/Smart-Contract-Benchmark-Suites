 

pragma solidity ^0.4.21;

 
library Maths {
   
  function plus(
    uint256 addendA,
    uint256 addendB
  ) public pure returns (uint256 sum) {
    sum = addendA + addendB;
  }

   
  function minus(
    uint256 minuend,
    uint256 subtrahend
  ) public pure returns (uint256 difference) {
    assert(minuend >= subtrahend);
    difference = minuend - subtrahend;
  }

   
  function mul(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    if (factorA == 0 || factorB == 0) return 0;
    product = factorA * factorB;
    assert(product / factorA == factorB);
  }

   
  function times(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    return mul(factorA, factorB);
  }

   
  function div(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    quotient = dividend / divisor;
    assert(quotient * divisor == dividend);
  }

   
  function dividedBy(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    return div(dividend, divisor);
  }

   
  function divideSafely(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient, uint256 remainder) {
    quotient = div(dividend, divisor);
    remainder = dividend % divisor;
  }

   
  function min(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a <= b ? a : b;
  }

   
  function max(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a >= b ? a : b;
  }

   
  function isLessThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a < b;
  }

   
  function isAtMost(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a <= b;
  }

   
  function isGreaterThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a > b;
  }

   
  function isAtLeast(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a >= b;
  }
}

 
contract Manageable {
  address public owner;
  address public manager;

  event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
  event ManagementChanged(address indexed previousManager, address indexed newManager);

   
  function Manageable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

   
  modifier onlyManagement() {
    require(msg.sender == owner || msg.sender == manager);
    _;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }

   
  function replaceManager(address newManager) public onlyManagement {
    require(newManager != address(0));
    emit ManagementChanged(manager, newManager);
    manager = newManager;
  }
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
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) public;
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 
contract ERC721BasicToken is ERC721Basic {
  using Maths for uint256;

   
   
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
    address holder = tokenOwner[_tokenId];
    require(holder != address(0));
    return holder;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address holder = tokenOwner[_tokenId];
    return holder != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address holder = ownerOf(_tokenId);
    require(_to != holder);
    require(msg.sender == holder || isApprovedForAll(holder, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(holder, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
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

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address holder = ownerOf(_tokenId);
    return _spender == holder || getApproved(_tokenId) == _spender || isApprovedForAll(holder, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].plus(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].minus(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!isContract(_to)) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }
}

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token() public { }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
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

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
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
    uint256 lastTokenIndex = ownedTokens[_from].length.minus(1);
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
    uint256 lastTokenIndex = allTokens.length.minus(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

contract CardToken is ERC721Token, Manageable {
  string public constant name = "Mythereum Card";
  string public constant symbol = "CARD";

  mapping (uint8 => string) public className;
  mapping (uint8 => Card[]) public cardsInEdition;
  uint8 public latestEditionReleased;

  struct Card {
    string    name;
    uint8     class;
    uint8     classVariant;
    uint256   damagePoints;
    uint256   shieldPoints;
    uint256   abilityId;
  }

  struct Ability {
    string  name;
    bool    canBeBlocked;
    uint8   blackMagicCost;
    uint8   grayMagicCost;
    uint8   whiteMagicCost;
    uint256 addedDamage;
    uint256 addedShield;
  }

  Card[] public cards;
  Ability[] public abilities;

  function isEditionAvailable(uint8 _editionNumber) public view returns (bool) {
    return _editionNumber <= latestEditionReleased;
  }

  function mintRandomCards(
    address _owner,
    uint8 _editionNumber,
    uint8 _numCards
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    for(uint8 i = 0; i < _numCards; i++) {
      Card storage card = cardsInEdition[_editionNumber][
        uint256(keccak256(now, _owner, _editionNumber, _numCards, i)) % cardsInEdition[_editionNumber].length
      ];

      _cloneCard(card, _owner);
    }
    return true;
  }

  function mintSpecificCard(
    address _owner,
    uint8   _editionNumber,
    uint256 _cardIndex
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    require(_cardIndex < cardsInEdition[_editionNumber].length);
    _cloneCard(cardsInEdition[_editionNumber][_cardIndex], _owner);
  }

  function mintSpecificCards(
    address   _owner,
    uint8     _editionNumber,
    uint256[] _cardIndexes
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    require(_cardIndexes.length > 0 && _cardIndexes.length <= 10);

    for(uint8 i = 0; i < _cardIndexes.length; i++) {
      require(_cardIndexes[i] < cardsInEdition[_editionNumber].length);
      _cloneCard(cardsInEdition[_editionNumber][_cardIndexes[i]], _owner);
    }
  }

  function improveCard(
    uint256 _tokenId,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement returns (bool) {
    require(exists(_tokenId));
    Card storage card = cards[_tokenId];
    card.damagePoints = card.damagePoints.plus(_addedDamage);
    card.shieldPoints = card.shieldPoints.plus(_addedShield);
    return true;
  }

  function destroyCard(uint256 _tokenId) public onlyManagement returns (bool) {
    require(exists(_tokenId));
    _burn(ownerOf(_tokenId), _tokenId);
    return true;
  }

  function setLatestEdition(uint8 _editionNumber) public onlyManagement {
    require(cardsInEdition[_editionNumber].length.isAtLeast(1));
    latestEditionReleased = _editionNumber;
  }

  function setTokenURI(uint256 _tokenId, string _uri) public onlyManagement {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  function addAbility(
    string  _name,
    bool    _canBeBlocked,
    uint8   _blackMagicCost,
    uint8   _grayMagicCost,
    uint8   _whiteMagicCost,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement {
    abilities.push(
      Ability(
        _name,
        _canBeBlocked,
        _blackMagicCost,
        _grayMagicCost,
        _whiteMagicCost,
        _addedDamage,
        _addedShield
      )
    );
  }

  function replaceAbility(
    uint256 _abilityId,
    string  _name,
    bool    _canBeBlocked,
    uint8   _blackMagicCost,
    uint8   _grayMagicCost,
    uint8   _whiteMagicCost,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement {
    require(_abilityId.isLessThan(abilities.length));
    abilities[_abilityId].name           = _name;
    abilities[_abilityId].canBeBlocked   = _canBeBlocked;
    abilities[_abilityId].blackMagicCost = _blackMagicCost;
    abilities[_abilityId].grayMagicCost  = _grayMagicCost;
    abilities[_abilityId].whiteMagicCost = _whiteMagicCost;
    abilities[_abilityId].addedDamage    = _addedDamage;
    abilities[_abilityId].addedShield    = _addedShield;
  }

  function addCardToEdition(
    uint8   _editionNumber,
    string  _name,
    uint8   _classId,
    uint8   _classVariant,
    uint256 _damagePoints,
    uint256 _shieldPoints,
    uint256 _abilityId
  ) public onlyManagement {
    require(_abilityId.isLessThan(abilities.length));

    cardsInEdition[_editionNumber].push(
      Card({
        name:         _name,
        class:        _classId,
        classVariant: _classVariant,
        damagePoints: _damagePoints,
        shieldPoints: _shieldPoints,
        abilityId:    _abilityId
      })
    );
  }

  function setClassName(uint8 _classId, string _name) public onlyManagement {
    className[_classId] = _name;
  }

  function _cloneCard(Card storage card, address owner) internal {
    require(card.damagePoints > 0 || card.shieldPoints > 0);
    uint256 tokenId = cards.length;
    cards.push(card);
    _mint(owner, tokenId);
  }
}