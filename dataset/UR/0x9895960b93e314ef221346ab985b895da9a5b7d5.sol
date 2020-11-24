 

pragma solidity ^0.4.23;

 
 
interface ERC165Interface {
   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC165 is ERC165Interface {
   
   
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
}

 
 
 
interface ERC721Interface   {
   
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

   
   
   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
   
   
   
   
  function balanceOf(address _owner) external view returns (uint256);

   
   
   
   
   
  function ownerOf(uint256 _tokenId) external view returns (address);

   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
  function approve(address _approved, uint256 _tokenId) external payable;

   
   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external;

   
   
   
   
  function getApproved(uint256 _tokenId) external view returns (address);

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract ERC721 is ERC721Interface {
   
   
   
   
   
   
   
   
   
   
  bytes4 public constant InterfaceId_ERC721 = 0x80ac58cd;
}

 
 
 
interface ERC721EnumerableInterface   {
   
   
   
  function totalSupply() external view returns (uint256);

   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256);

   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract ERC721Enumerable is ERC721EnumerableInterface {
  bytes4 public constant InterfaceId_ERC721Enumerable = 0x780e9d63;
}

 
 
 
interface ERC721MetadataInterface   {
   
  function name() external view returns (string _name);

   
  function symbol() external view returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}

contract ERC721Metadata is ERC721MetadataInterface {
  bytes4 public constant InterfaceId_ERC721Metadata = 0x5b5e139f;
}

 
 
 
interface ERC721TokenReceiverInterface {
   
   
   
   
   
   
   
   
   
   
   
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

contract ERC721TokenReceiver is ERC721TokenReceiverInterface {
  bytes4 public constant InterfaceId_ERC721TokenReceiver = 0x150b7a02;
}

contract SixPillars is ERC165, ERC721, ERC721Enumerable, ERC721Metadata, ERC721TokenReceiver {
   
  event Mint(
    address indexed _owner,
    address indexed _creator,
    uint256 _inscription,
    uint256 _tokenId
  );

   
  event Burn(
    address indexed _owner,
    address indexed _creator,
    uint256 _tokenId
  );

   
  event CreatedBy(
    address indexed _creator,
    uint256 _tokenId
  );

   
  event ClearCreator(
    uint256 _tokenId
  );

   
   
  event ApprovalWithAmount(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId,
    uint256 _amount
  );

   
   
  event TransferWithAmount(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId,
    uint256 _amount
  );

  struct Token {
    uint256 id;
    uint256 inscription;
    uint256 amount;
    uint256 ownerIndex;  
    uint256 createdAt;  
    address owner;
    address creator;
    address approved;
    string uri;
  }

  Token[] internal tokens;
  mapping(uint256 => uint256) internal tokenIdToIndex;  
  uint256 internal tokenIdSeed;
  uint256 internal lastMintBlockNumber;

  mapping(address => uint256[]) internal ownerToTokensIndex;  
  mapping(address => mapping(address => bool)) internal operatorApprovals;  

  mapping(bytes4 => bool) internal supportedInterfaces;

   

   
  function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
    return supportedInterfaces[_interfaceId];
  }

  function _registerInterface(bytes4 _interfaceId) internal {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }

   

   
  function totalSupply() external view returns (uint256) {
    return tokens.length;
  }

   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    return tokenIdByIndex(_index);
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToTokensIndex[_owner].length);
    uint256 index = ownerToTokensIndex[_owner][_index];
    return tokens[index].id;
  }

  function tokenIdByIndex(uint256 _index) internal view returns (uint256) {
    require(_index < tokens.length);
    return tokens[_index].id;
  }

  function indexByTokenId(uint256 _tokenId) internal view returns (uint256) {
    uint index = tokenIdToIndex[_tokenId];
    require(index < tokens.length);
    require(tokens[index].id == _tokenId);
    return index;
  }

   

   
  function name() public view returns (string) {
    return "SixPillars";
  }

   
  function symbol() public view returns (string) {
    return "SPT";
  }

   
  function tokenURI(uint256 _tokenId) external view returns (string) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].uri;
  }

   

   
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4) {
    return InterfaceId_ERC721TokenReceiver;
  }

   

   
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToTokensIndex[_owner].length;
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address) {
    return internalOwnerOf(_tokenId);
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable {
    uint256 sendAmount = internalSafeTransferFrom(_from, _to, _tokenId, msg.value, _data);
    if (0 < sendAmount) {
      _from.transfer(sendAmount);
      emit TransferWithAmount(_from, _to, _tokenId, sendAmount);
    }
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    uint256 sendAmount = internalSafeTransferFrom(_from, _to, _tokenId, msg.value, "");
    if (0 < sendAmount) {
      _from.transfer(sendAmount);
      emit TransferWithAmount(_from, _to, _tokenId, sendAmount);
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    uint256 sendAmount = internalTransferFrom(_from, _to, _tokenId, msg.value);
    if (0 < sendAmount) {
      _from.transfer(sendAmount);
      emit TransferWithAmount(_from, _to, _tokenId, sendAmount);
    }
  }

   
  function approve(address _approved, uint256 _tokenId) external payable {
    internalApprove(_approved, _tokenId, 0);
  }

   
  function setApprovalForAll(address _operator, bool _approved) external {
    require(_operator != msg.sender);
    operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
  function getApproved(uint256 _tokenId) external view returns (address) {
    return internalGetApproved(_tokenId);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return internalIsApprovedForAll(_owner, _operator);
  }

   

  function approve(address _approved, uint256 _tokenId, uint256 _amount) external payable {
    internalApprove(_approved, _tokenId, _amount);
  }

  function amountOf(uint256 _tokenId) external view returns (uint256) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].amount;
  }

   

   
  function internalOwnerOf(uint256 _tokenId) internal view returns (address) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].owner;
  }

   
  function internalSafeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes _data) internal returns (uint256) {
    if (isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == InterfaceId_ERC721TokenReceiver, "internalSafeTransferFrom msg.sender can not approved");
    }
    return internalTransferFrom(_from, _to, _tokenId, _value);
  }

  function internalTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value) internal returns (uint256 sendAmount) {
    uint index = indexByTokenId(_tokenId);
    address owner = tokens[index].owner;
    require((_from == owner) && (_from != _to));

     
     
     
     
     
     
     
    uint256 amount = tokens[index].amount;
    tokens[index].amount = 0;
    bool canTransfer = (msg.sender == owner) || internalIsApprovedForAll(owner, msg.sender);
    if (canTransfer) {
       
      require(_value == 0);

    } else if (tokens[index].approved == msg.sender) {
      sendAmount = amount;
      canTransfer = (amount == _value);

    } else if ((tokens[index].approved == address(0)) && (0 < amount)) {
      sendAmount = amount;
      canTransfer = (amount == _value);
    }
    require(canTransfer);

     
    tokens[index].approved = address(0);

     
    transferToken(_from, _to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  function internalGetApproved(uint256 _tokenId) internal view returns (address) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].approved;
  }

  function internalIsApprovedForAll(address _owner, address _operator) internal view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  function internalApprove(address _approved, uint256 _tokenId, uint256 _amount) internal {
    uint index = indexByTokenId(_tokenId);
    address owner = tokens[index].owner;
    require(_approved != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
    tokens[index].approved = _approved;
    tokens[index].amount = _amount;
    emit Approval(owner, _approved, _tokenId);
    if (0 < _amount) {
      emit ApprovalWithAmount(owner, _approved, _tokenId, _amount);
    }
  }

   

  function addTokenTo(address _toOwner, uint256 _tokenId, uint256 _inscription, bool _isSetCreator) internal {
    uint index = tokenIdToIndex[_tokenId];
    require(_toOwner != address(0));
    if ((index == 0) && (0 < tokens.length)) {
      require(tokens[0].id != _tokenId);
    }

    index = tokens.length;

     
    uint256 ownerIndex = ownerToTokensIndex[_toOwner].length;
    ownerToTokensIndex[_toOwner].push(index);

    address creator = _isSetCreator ? msg.sender : address(0);
    Token memory tokenWithCreator = Token(_tokenId, _inscription, 0, ownerIndex, block.number, _toOwner, creator, address(0), "");
    tokens.push(tokenWithCreator);
    tokenIdToIndex[_tokenId] = index;
  }

  function removeTokenFrom(address _fromOwner, uint256 _tokenId) internal {
    uint index = indexByTokenId(_tokenId);
    require(tokens[index].owner == _fromOwner);

     
    uint256 removeTokenIndex = tokens[index].ownerIndex;
    uint256 lastTokenIndex = ownerToTokensIndex[_fromOwner].length - 1;
    if (removeTokenIndex != lastTokenIndex) {
      tokens[ownerToTokensIndex[_fromOwner][lastTokenIndex] ].ownerIndex = removeTokenIndex;
      ownerToTokensIndex[_fromOwner][removeTokenIndex] = ownerToTokensIndex[_fromOwner][lastTokenIndex];
    }
    ownerToTokensIndex[_fromOwner].length = lastTokenIndex;

     
    removeTokenIndex = index;
    lastTokenIndex = tokens.length - 1;
    if (removeTokenIndex != lastTokenIndex) {
      uint256 lastTokenId = tokens[lastTokenIndex].id;

       
      address lastTokenOwner = tokens[lastTokenIndex].owner;
      uint256 lastTokenOwnerIndex = tokens[lastTokenIndex].ownerIndex;
      ownerToTokensIndex[lastTokenOwner][lastTokenOwnerIndex] = removeTokenIndex;

       
      tokenIdToIndex[lastTokenId] = removeTokenIndex;
      tokens[removeTokenIndex] = tokens[lastTokenIndex];
    }
    tokenIdToIndex[_tokenId] = 0;
    tokens.length = lastTokenIndex;
  }

  function transferToken(address _fromOwner, address _toOwner, uint256 _tokenId) internal {
    uint index = indexByTokenId(_tokenId);
    require((_toOwner != address(0)) && (_fromOwner != _toOwner) && (tokens[index].owner == _fromOwner));

     
    uint256 removeTokenIndex = tokens[index].ownerIndex;
    uint256 lastTokenIndex = ownerToTokensIndex[_fromOwner].length - 1;

    tokens[ownerToTokensIndex[_fromOwner][lastTokenIndex] ].ownerIndex = removeTokenIndex;
    ownerToTokensIndex[_fromOwner][removeTokenIndex] = ownerToTokensIndex[_fromOwner][lastTokenIndex];
    ownerToTokensIndex[_fromOwner].length = lastTokenIndex;

     
    uint256 ownerIndex = ownerToTokensIndex[_toOwner].length;
    ownerToTokensIndex[_toOwner].push(index);
    tokens[index].owner = _toOwner;
    tokens[index].ownerIndex = ownerIndex;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

   

  constructor() public {
    _registerInterface(InterfaceId_ERC165);
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
    _registerInterface(InterfaceId_ERC721TokenReceiver);
    tokenIdSeed = 722;
    lastMintBlockNumber = 0;
  }

  function recover(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
    return ecrecover(msgHash, v, r, s);
  }

   
   
   
   
   
   
   
   
  function mint(address _to, uint256 _inscription, bool _isSetCreator) external {
    uint256 seed = tokenIdSeed;
    if ((lastMintBlockNumber != 0) && (lastMintBlockNumber < block.number)) {
      seed += (block.number - lastMintBlockNumber);
    }
    uint256 newTokenId = uint256(keccak256(abi.encodePacked(seed)));
    tokenIdSeed = newTokenId;
    lastMintBlockNumber = block.number;
    addTokenTo(_to, newTokenId, _inscription, _isSetCreator);
    emit Mint(
      _to,
      (_isSetCreator == true) ? msg.sender : address(0),
      _inscription,
      newTokenId
    );
  }

   
   
   
   
   
  function burn(uint256 _tokenId) external {
    uint index = indexByTokenId(_tokenId);
    address owner = tokens[index].owner;
    address creator = tokens[index].creator;
    require(owner == msg.sender);
    removeTokenFrom(owner, _tokenId);
    emit Burn(
      owner,
      creator,
      _tokenId
    );
  }

   
   
   
   
   
   
  function createdBy(uint256 _tokenId) external {
    uint index = indexByTokenId(_tokenId);
    address creator = tokens[index].creator;
    require(creator == address(0));
    tokens[index].creator = msg.sender;
    emit CreatedBy(
      msg.sender,
      _tokenId
    );
  }

   
   
   
   
   
   
  function clearCreator(uint256 _tokenId) external {
    uint index = indexByTokenId(_tokenId);
    address creator = tokens[index].creator;
    require(msg.sender == creator);
    tokens[index].creator = address(0);
    emit ClearCreator(_tokenId);
  }

   
   
   
  function inscription(uint256 _tokenId) external view returns(uint256) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].inscription;
  }

   
   
   
  function creator(uint256 _tokenId) external view returns(address) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].creator;
  }

   
   
   
  function createdAt(uint256 _tokenId) external view returns(uint256) {
    uint index = indexByTokenId(_tokenId);
    return tokens[index].createdAt;
  }

   
   
   
   
   
  function setTokenURI(uint256 _tokenId, string _uri) external {
    uint index = indexByTokenId(_tokenId);
    require(tokens[index].owner == msg.sender);
    tokens[index].uri = _uri;
  }

   
   
   
   
   
  function balanceOfCreator(address _creator) external view returns (uint256) {
    require(_creator != address(0));
    uint256 count = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i].creator == _creator) {
        count++;
      }
    }
    return count;
  }

   
   
   
   
   
   
   
  function tokenOfCreatorByIndex(address _creator, uint256 _index) external view returns (uint256) {
    require(_creator != address(0));
    uint256 count = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i].creator == _creator) {
        if (count == _index) {
          return tokens[i].id;
        }
        count++;
      }
    }
    revert();
  }

   
   
   
   
   
   
   
  function balanceOfOwnerAndCreator(address _owner, address _creator) external view returns (uint256) {
    require((_owner != address(0)) && (_creator != address(0)));
    uint256 balance = 0;
    for (uint256 i = 0; i < ownerToTokensIndex[_owner].length; i++) {
      uint256 index = ownerToTokensIndex[_owner][i];
      if (tokens[index].creator == _creator) {
        balance++;
      }
    }
    return balance;
  }

   
   
   
   
   
   
   
   
   
  function tokenOfOwnerAndCreatorByIndex(address _owner, address _creator, uint256 _index) external view returns (uint256) {
    require((_owner != address(0)) && (_creator != address(0)));
    uint256 count = 0;
    for (uint256 i = 0; i < ownerToTokensIndex[_owner].length; i++) {
      uint256 index = ownerToTokensIndex[_owner][i];
      if (tokens[index].creator == _creator) {
        if (count == _index) {
          return tokens[index].id;
        }
        count++;
      }
    }
    revert();
  }
}