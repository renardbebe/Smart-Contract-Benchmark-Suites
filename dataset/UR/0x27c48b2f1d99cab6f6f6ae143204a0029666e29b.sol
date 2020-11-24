 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ClockAuctionBase {
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  ) external;

  function isSaleAuction() public returns (bool);
}

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 
library AddressUtils {
   
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_account) }
    return size > 0;
  }
}

contract CardBase is Ownable {
  bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
  bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;

   
   
   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
    return (
      (_interfaceID == InterfaceSignature_ERC165) ||
      (_interfaceID == InterfaceSignature_ERC721) ||
      (_interfaceID == InterfaceId_ERC721Exists)
    );
  }
}

contract CardMint is CardBase {

  using AddressUtils for address;

   
  event TemplateMint(uint256 _templateId);
   
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

   
  struct Template {
    uint256 generation;
    uint256 category;
    uint256 variation;
    string name;
  }

   
   
  address public minter;

  Template[] internal templates;
   
  uint256[] internal cards;

   
  mapping (uint256 => uint256) internal templateIdToMintLimit;
   
  mapping (uint256 => uint256) internal templateIdToMintCount;
   
  mapping (uint256 => address) internal cardIdToOwner;
   
  mapping (address => uint256) internal ownerToCardCount;
   
  mapping (uint256 => address) internal cardIdToApproved;
   
  mapping (address => mapping (address => bool)) internal operatorToApprovals;

   
  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

   
   
  function _addTokenTo(address _to, uint256 _tokenId) internal {
    require(cardIdToOwner[_tokenId] == address(0));
    ownerToCardCount[_to] = ownerToCardCount[_to] + 1;
    cardIdToOwner[_tokenId] = _to;
  }

   
  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }

  function mintTemplate(
    uint256 _mintLimit,
    uint256 _generation,
    uint256 _category,
    uint256 _variation,
    string _name
  ) external onlyOwner {
    require(_mintLimit > 0);

    uint256 newTemplateId = templates.push(Template({
      generation: _generation,
      category: _category,
      variation: _variation,
      name: _name
    })) - 1;
    templateIdToMintLimit[newTemplateId] = _mintLimit;

    emit TemplateMint(newTemplateId);
  }

  function mintCard(
    uint256 _templateId,
    address _owner
  ) external onlyMinter {
    require(templateIdToMintCount[_templateId] < templateIdToMintLimit[_templateId]);
    templateIdToMintCount[_templateId] = templateIdToMintCount[_templateId] + 1;

    uint256 newCardId = cards.push(_templateId) - 1;
    _addTokenTo(_owner, newCardId);

    emit Transfer(0, _owner, newCardId);
  }

  function mintCards(
    uint256[] _templateIds,
    address _owner
  ) external onlyMinter {
    uint256 mintCount = _templateIds.length;
    uint256 templateId;

    for (uint256 i = 0; i < mintCount; ++i) {
      templateId = _templateIds[i];

      require(templateIdToMintCount[templateId] < templateIdToMintLimit[templateId]);
      templateIdToMintCount[templateId] = templateIdToMintCount[templateId] + 1;

      uint256 newCardId = cards.push(templateId) - 1;
      cardIdToOwner[newCardId] = _owner;

      emit Transfer(0, _owner, newCardId);
    }

     
    ownerToCardCount[_owner] = ownerToCardCount[_owner] + mintCount;
  }
}

contract CardOwnership is CardMint {

   
   
  function _approve(address _owner, address _approved, uint256 _tokenId) internal {
    cardIdToApproved[_tokenId] = _approved;
    emit Approval(_owner, _approved, _tokenId);
  }

  function _clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (cardIdToApproved[_tokenId] != address(0)) {
      cardIdToApproved[_tokenId] = address(0);
    }
  }

  function _removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownerToCardCount[_from] = ownerToCardCount[_from] - 1;
    cardIdToOwner[_tokenId] = address(0);
  }

   
  function approve(address _to, uint256 _tokenId) external {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _approve(owner, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));
    require(_to != address(this));

    _clearApproval(_from, _tokenId);
    _removeTokenFrom(_from, _tokenId);
    _addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) public {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == 0x150b7a02);
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  ) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function setApprovalForAll(address _operator, bool _approved) public {
    require(_operator != msg.sender);
    require(_operator != address(0));
    operatorToApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return cardIdToApproved[_tokenId];
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }

  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = cardIdToOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = cardIdToOwner[_tokenId];
    return owner != address(0);
  }
}

contract CardAuction is CardOwnership {

  ClockAuctionBase public saleAuction;

  function setSaleAuction(address _address) external onlyOwner {
    ClockAuctionBase candidateContract = ClockAuctionBase(_address);
    require(candidateContract.isSaleAuction());
    saleAuction = candidateContract;
  }

  function createSaleAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  ) external {
    require(saleAuction != address(0));
    require(msg.sender == cardIdToOwner[_tokenId]);

    _approve(msg.sender, saleAuction, _tokenId);
    saleAuction.createAuction(
        _tokenId,
        _startingPrice,
        _endingPrice,
        _duration,
        msg.sender
    );
  }
}

contract CardTreasury is CardAuction {

   
   
  function getTemplate(uint256 _templateId)
    external
    view
    returns (
      uint256 generation,
      uint256 category,
      uint256 variation,
      string name
    )
  {
    require(_templateId < templates.length);

    Template storage template = templates[_templateId];

    generation = template.generation;
    category = template.category;
    variation = template.variation;
    name = template.name;
  }

  function getCard(uint256 _cardId)
    external
    view
    returns (
      uint256 generation,
      uint256 category,
      uint256 variation,
      string name
    )
  {
    require(_cardId < cards.length);

    uint256 templateId = cards[_cardId];
    Template storage template = templates[templateId];

    generation = template.generation;
    category = template.category;
    variation = template.variation;
    name = template.name;
  }

  function templateIdOf(uint256 _cardId) external view returns (uint256) {
    require(_cardId < cards.length);
    return cards[_cardId];
  }

  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownerToCardCount[_owner];
  }

  function templateSupply() external view returns (uint256) {
    return templates.length;
  }

  function totalSupply() external view returns (uint256) {
    return cards.length;
  }

  function mintLimitByTemplate(uint256 _templateId) external view returns(uint256) {
    require(_templateId < templates.length);
    return templateIdToMintLimit[_templateId];
  }

  function mintCountByTemplate(uint256 _templateId) external view returns(uint256) {
    require(_templateId < templates.length);
    return templateIdToMintCount[_templateId];
  }

  function name() external pure returns (string) {
    return "Battlebound";
  }

  function symbol() external pure returns (string) {
    return "BB";
  }

  function tokensOfOwner(address _owner) external view returns (uint256[]) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;

      for (uint256 cardId = 0; cardId < cards.length; ++cardId) {
        if (cardIdToOwner[cardId] == _owner) {
          result[resultIndex] = cardId;
          ++resultIndex;
        }
      }

      return result;
    }
  }

  function templatesOfOwner(address _owner) external view returns (uint256[]) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;

      for (uint256 cardId = 0; cardId < cards.length; ++cardId) {
        if (cardIdToOwner[cardId] == _owner) {
          uint256 templateId = cards[cardId];
          result[resultIndex] = templateId;
          ++resultIndex;
        }
      }

      return result;
    }
  }

  function variationsOfOwner(address _owner) external view returns (uint256[]) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;

      for (uint256 cardId = 0; cardId < cards.length; ++cardId) {
        if (cardIdToOwner[cardId] == _owner) {
          uint256 templateId = cards[cardId];
          Template storage template = templates[templateId];
          result[resultIndex] = template.variation;
          ++resultIndex;
        }
      }

      return result;
    }
  }
}