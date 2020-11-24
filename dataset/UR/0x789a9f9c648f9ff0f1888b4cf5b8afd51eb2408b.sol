 

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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

 
contract ERC721Basic is ERC165 {
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

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
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

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
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

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
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

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
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
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1); tokenOwner[_tokenId] = address(0);
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
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
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

contract PetCemetheryToken is ERC721Token, Ownable {

  using SafeMath for *;

  enum TokenType { Default, Plot, Headstone, Decoration, PhotoVoucher }

  struct PlotPosition {
    uint32 section;
    uint8 index;
  }

  struct Plot {
    uint256 headstoneTokenId;
    bool forSale;
    uint256 price;
    uint256 photoExpirationTime;
  }

  struct Headstone {
    uint16 headstoneType;
    uint256 plotTokenId;
    string engraving;
    string petName;
    uint16 petSpecies;
    uint32 lat;
    uint32 lng;
    string extraData;
    bool flipped;
  }

  struct Decoration {
    uint16 decorationType;
    uint256 plotTokenId;
    int16 plotPositionX;
    int16 plotPositionY;
    bool flipped;
    uint256 firstAssignTime;
    uint256 latestAssignTime;
    uint256 totalAssignDuration;
  }

  struct PhotoVoucher {
    uint256 period;
  }

  struct PlotDetailsView {
    uint256 plotTokenId;
    Plot plot;
    PlotPosition plotPosition;
    Headstone headstone;
    DecorationDetailsView[] decorations;
    address owner;
    string tokenUri;
  }

  struct DecorationDetailsView {
    uint256 decorationTokenId;
    Decoration decoration;
  }

  string public baseURI;

  uint32 public sectionCounter;
  uint256 public tokenIdCounter = 1;

  mapping(uint32 => uint256[]) public plotIdByPosition;  

  mapping(uint256 => TokenType) public tokenTypes;

  mapping(uint256 => Plot) public plots;
  mapping(uint256 => Headstone) public headstones;
  mapping(uint256 => Decoration) public decorations;
  mapping(uint256 => PhotoVoucher) public photoVouchers;
  mapping(uint256 => uint256[]) public plotsDecorations;  
  mapping(uint256 => PlotPosition) public plotsPositions;

  constructor(string _baseURI) public ERC721Token("Pet Cemethery Token", "PCT") {
    baseURI = _baseURI;
  }

  function _mintSection(uint8 _size) private {
    uint32 section = sectionCounter;
    sectionCounter++;

    plotIdByPosition[section] = new uint256[](_size);

    for (uint8 i = 0; i < _size; i++) {
      _mintPlot(section, i);
    }
  }

  function _mintPlot(uint32 _section, uint8 _index) private {
    uint256 newTokenId = _getNextTokenId();
    _mint(owner, newTokenId);
    plots[newTokenId] = Plot(0, false, 0, 0);
    plotsDecorations[newTokenId] = new uint256[](0);
    plotsPositions[newTokenId] = PlotPosition(_section, _index);
    tokenTypes[newTokenId] = TokenType.Plot;
    plotIdByPosition[_section][_index] = newTokenId;
  }

  function _mintHeadstone(uint16 _headstoneType) private {
    uint256 newTokenId = _getNextTokenId();
    _mint(owner, newTokenId);
    headstones[newTokenId] = Headstone(_headstoneType, 0, "", "", 0, 0, 0, "", false);
    tokenTypes[newTokenId] = TokenType.Headstone;
  }

  function _mintDecoration(uint16 _decorationType) private {
    uint256 newTokenId = _getNextTokenId();
    _mint(owner, newTokenId);
    decorations[newTokenId] = Decoration(_decorationType, 0, 0, 0, false, 0, 0, 0);
    tokenTypes[newTokenId] = TokenType.Decoration;
  }

  function _mintPhotoVoucher(uint256 _period) private {
    uint256 newTokenId = _getNextTokenId();
    _mint(owner, newTokenId);
    photoVouchers[newTokenId] = PhotoVoucher(_period);
    tokenTypes[newTokenId] = TokenType.PhotoVoucher;
  }

  function _getNextTokenId() private returns (uint256) {
    uint256 res = tokenIdCounter;
    tokenIdCounter = tokenIdCounter.add(1);
    return res;
  }

  function _assignHeadstoneToPlot(uint256 _plotTokenId, uint256 _headstoneTokenId) private {
    _unassignHeadstoneFromPlot(_plotTokenId);
    plots[_plotTokenId].headstoneTokenId = _headstoneTokenId;
    headstones[_headstoneTokenId].plotTokenId = _plotTokenId;
  }

  function _unassignHeadstoneFromPlot(uint256 _plotTokenId) private {
    uint256 existingHeadstoneTokenId = plots[_plotTokenId].headstoneTokenId;

    if (existingHeadstoneTokenId != 0) {
      headstones[existingHeadstoneTokenId].plotTokenId = 0;
      headstones[existingHeadstoneTokenId].engraving = "";
      headstones[existingHeadstoneTokenId].petName = "";
      headstones[existingHeadstoneTokenId].petSpecies = 0;
      headstones[existingHeadstoneTokenId].lat = 0;
      headstones[existingHeadstoneTokenId].lng = 0;
      headstones[existingHeadstoneTokenId].extraData = "";
      headstones[existingHeadstoneTokenId].flipped = false;
    }

    plots[_plotTokenId].headstoneTokenId = 0;
  }

  function _assignDecorationToPlot(uint256 _plotTokenId, uint256 _decorationTokenId,
                                   int16 _plotPositionX, int16 _plotPositionY, bool _flipped) private {
    if (decorations[_decorationTokenId].plotTokenId != _plotTokenId) {
      plotsDecorations[_plotTokenId].push(_decorationTokenId);
    }
    decorations[_decorationTokenId].plotTokenId = _plotTokenId;
    decorations[_decorationTokenId].plotPositionX = _plotPositionX;
    decorations[_decorationTokenId].plotPositionY = _plotPositionY;
    decorations[_decorationTokenId].flipped = _flipped;
    if (decorations[_decorationTokenId].firstAssignTime == 0) {
      decorations[_decorationTokenId].firstAssignTime = now;
    }
    decorations[_decorationTokenId].latestAssignTime = now;
  }

  function _unassignDecorationFromPlot(uint256 _plotTokenId, uint256 _decorationTokenId) private {
    Decoration storage decoration = decorations[_decorationTokenId];
    if (decoration.plotTokenId != 0) {
      uint256 latestAssignDuration = now - decoration.latestAssignTime;
      decoration.totalAssignDuration = decoration.totalAssignDuration.add(latestAssignDuration);
    }
    decoration.plotTokenId = 0;
    decoration.plotPositionX = 0;
    decoration.plotPositionY = 0;
    decoration.flipped = false;

    for (uint256 i = 0; i < plotsDecorations[_plotTokenId].length; i++) {
      if (plotsDecorations[_plotTokenId][i] == _decorationTokenId) {
        delete plotsDecorations[_plotTokenId][i];

        if (i != plotsDecorations[_plotTokenId].length - 1) {
          plotsDecorations[_plotTokenId][i] = plotsDecorations[_plotTokenId][plotsDecorations[_plotTokenId].length-1];
        }

        plotsDecorations[_plotTokenId].length--;
        break;
      }
    }
  }

  function _unassignAllDecorationsFromPlot(uint256 _plotTokenId) private {
    for (uint256 i = 0; i < plotsDecorations[_plotTokenId].length; i++) {
      Decoration storage decoration = decorations[plotsDecorations[_plotTokenId][i]];
      decoration.plotTokenId = 0;
      decoration.plotPositionX = 0;
      decoration.plotPositionY = 0;
      decoration.flipped = false;

      uint256 latestAssignDuration = now - decoration.latestAssignTime;
      decoration.totalAssignDuration = decoration.totalAssignDuration.add(latestAssignDuration);
    }
    delete plotsDecorations[_plotTokenId];
  }

  function _offerPlot(uint256 _plotTokenId, uint256 _price) private {
    _unassignHeadstoneFromPlot(_plotTokenId);
    _unassignAllDecorationsFromPlot(_plotTokenId);

    plots[_plotTokenId].forSale = true;
    plots[_plotTokenId].price = _price;
  }

  function _cancelPlotOffer(uint256 _plotTokenId) private {
    plots[_plotTokenId].forSale = false;
    plots[_plotTokenId].price = 0;
  }

   

  function getOwnedTokens(address _address) public view returns (uint256[]) {
    return ownedTokens[_address];
  }

  function getPlotDetails(uint256 _plotTokenId) public view returns (PlotDetailsView memory) {
    Plot storage plot = plots[_plotTokenId];
    PlotPosition storage plotPosition = plotsPositions[_plotTokenId];
    Headstone storage headstone = headstones[plot.headstoneTokenId];
    uint256[] storage decorationsIds = plotsDecorations[_plotTokenId];
    DecorationDetailsView[] memory retDecorations = new DecorationDetailsView[](decorationsIds.length);
    for (uint256 j = 0; j < decorationsIds.length; j++) {
      retDecorations[j] = DecorationDetailsView(decorationsIds[j], decorations[decorationsIds[j]]);
    }
    address owner = ownerOf(_plotTokenId);
    string memory tokenUri = tokenURI(_plotTokenId);
    return PlotDetailsView(_plotTokenId, plot, plotPosition, headstone, retDecorations, owner, tokenUri);
  }

  function getSectionPlotsDetails(uint32 _section) public view returns (PlotDetailsView[] memory) {
    uint256[] storage plotsIds = plotIdByPosition[_section];
    PlotDetailsView[] memory plotsDetailsViews = new PlotDetailsView[](plotsIds.length);
    for (uint256 i = 0; i<plotsIds.length; i++) {
      plotsDetailsViews[i] = getPlotDetails(plotsIds[i]);
    }

    return plotsDetailsViews;
  }

  function plotsCount(uint32 _section) public view returns (uint256) {
    return plotIdByPosition[_section].length;
  }

  function photoExpirationTime(uint256 _plotTokenId) public view returns (uint256) {
    return plots[_plotTokenId].photoExpirationTime;
  }

   

  function prepareHeadstoneAndAssignToPlot(uint256 _plotTokenId, uint256 _headstoneTokenId,
                                           string _engraving, string _petName, uint16 _petSpecies,
                                           uint32 _lat, uint32 _lng, string _extraData, bool _flipped) public {
    prepareHeadstone(_headstoneTokenId, _engraving, _petName, _petSpecies, _lat, _lng, _extraData, _flipped);
    assignHeadstoneToPlot(_plotTokenId, _headstoneTokenId);
  }

  function prepareHeadstone(uint256 _headstoneTokenId, string _engraving,
                            string _petName, uint16 _petSpecies, uint32 _lat, uint32 _lng, string _extraData, bool _flipped) public onlyOwnerOf(_headstoneTokenId) {
    headstones[_headstoneTokenId].engraving = _engraving;
    headstones[_headstoneTokenId].petName = _petName;
    headstones[_headstoneTokenId].petSpecies = _petSpecies;
    headstones[_headstoneTokenId].lat = _lat;
    headstones[_headstoneTokenId].lng = _lng;
    headstones[_headstoneTokenId].extraData = _extraData;
    headstones[_headstoneTokenId].flipped = _flipped;
  }

  function assignHeadstoneToPlot(uint256 _plotTokenId,
                                 uint256 _headstoneTokenId) public onlyOwnerOf(_plotTokenId) onlyOwnerOf(_headstoneTokenId) {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");
    require(tokenTypes[_headstoneTokenId] == TokenType.Headstone, "Invalid headstone token ID");
    require(!plots[_plotTokenId].forSale, "Plot is offered for sale");

    _assignHeadstoneToPlot(_plotTokenId, _headstoneTokenId);
  }

  function unassignHeadstoneFromPlot(uint256 _plotTokenId) public onlyOwnerOf(_plotTokenId) {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");

    _unassignHeadstoneFromPlot(_plotTokenId);
  }

  function assignDecorationToPlot(uint256 _plotTokenId, uint256 _decorationTokenId,
                                  int16 _plotPositionX, int16 _plotPositionY, bool _flipped) public onlyOwnerOf(_plotTokenId) onlyOwnerOf(_decorationTokenId) {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");
    require(tokenTypes[_decorationTokenId] == TokenType.Decoration, "Invalid decoration token ID");
    require(!plots[_plotTokenId].forSale, "Plot is offered for sale");

    _assignDecorationToPlot(_plotTokenId, _decorationTokenId, _plotPositionX, _plotPositionY, _flipped);
  }

  function unassignDecorationFromPlot(uint256 _plotTokenId, uint256 _decorationTokenId) public onlyOwnerOf(_plotTokenId) {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");
    require(tokenTypes[_decorationTokenId] == TokenType.Decoration, "Invalid decoration token ID");

    _unassignDecorationFromPlot(_plotTokenId, _decorationTokenId);
  }

   

  function offerPlot(uint256 _plotTokenId, uint256 _price) public onlyOwnerOf(_plotTokenId) {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");

    _offerPlot(_plotTokenId, _price);
  }

  function batchOfferPlots(uint256[] _plotsTokensIds, uint256 _price) public {
    for (uint256 i = 0; i < _plotsTokensIds.length; i++) {
      offerPlot(_plotsTokensIds[i], _price);
    }
  }

  function cancelPlotOffer(uint256 _plotTokenId) public onlyOwnerOf(_plotTokenId) {
    require(plots[_plotTokenId].forSale, "Plot is offered for sale");

    _cancelPlotOffer(_plotTokenId);
  }

  function buyPlot(uint256 _plotTokenId) public payable {
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");

    address plotOwner = ownerOf(_plotTokenId);
    uint256 price = plots[_plotTokenId].price;

    require(plots[_plotTokenId].forSale, "Plot is offered for sale");
    require(msg.value == price, "Invalid tx value");
    require(msg.sender != plotOwner, "Buyer is owner");

    tokenApprovals[_plotTokenId] = msg.sender;
    safeTransferFrom(plotOwner, msg.sender, _plotTokenId);

    plotOwner.transfer(msg.value);
  }

   

  function redeemPhotoVoucher(uint256 _photoVoucherTokenId,
                              uint256 _plotTokenId) public onlyOwnerOf(_photoVoucherTokenId) onlyOwnerOf(_plotTokenId) {
    require(tokenTypes[_photoVoucherTokenId] == TokenType.PhotoVoucher, "Invalid photo voucher token ID");
    require(tokenTypes[_plotTokenId] == TokenType.Plot, "Invalid plot token ID");

    Plot storage plot = plots[_plotTokenId];
    if (plot.photoExpirationTime > now) {
      plot.photoExpirationTime = plot.photoExpirationTime.add(photoVouchers[_photoVoucherTokenId].period);
    } else {
      plot.photoExpirationTime = now.add(photoVouchers[_photoVoucherTokenId].period);
    }

    _burn(msg.sender, _photoVoucherTokenId);
    delete photoVouchers[_photoVoucherTokenId];
    delete tokenTypes[_photoVoucherTokenId];
  }

   

  function mintSections(uint8 _num, uint8 _size) public onlyOwner {
    for (uint8 i = 0; i < _num; i++) {
      _mintSection(_size);
    }
  }

  function mintHeadstones(uint8 _num, uint16 _headstoneType) public onlyOwner {
    for (uint8 i = 0; i < _num; i++) {
      _mintHeadstone(_headstoneType);
    }
  }

  function mintDecorations(uint8 _num, uint16 _decorationType) public onlyOwner {
    for (uint8 i = 0; i < _num; i++) {
      _mintDecoration(_decorationType);
    }
  }

  function mintPhotoVouchers(uint8 _num, uint256 _period) public onlyOwner {
    for (uint8 i = 0; i < _num; i++) {
      _mintPhotoVoucher(_period);
    }
  }

  function setBaseURI(string _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

   

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    ERC721BasicToken.transferFrom(_from, _to, _tokenId);

    if (tokenTypes[_tokenId] == TokenType.Plot) {
      _cancelPlotOffer(_tokenId);
      _unassignHeadstoneFromPlot(_tokenId);
      _unassignAllDecorationsFromPlot(_tokenId);
    } else if (tokenTypes[_tokenId] == TokenType.Headstone) {
      if (headstones[_tokenId].plotTokenId != 0) {
        _unassignHeadstoneFromPlot(headstones[_tokenId].plotTokenId);
      }
    } else if (tokenTypes[_tokenId] == TokenType.Decoration) {
      if (decorations[_tokenId].plotTokenId != 0) {
        _unassignDecorationFromPlot(decorations[_tokenId].plotTokenId, _tokenId);
      }
    }  
  }

  function tokenURI(uint256 _tokenId) public view returns (string) {
    return strConcat(baseURI, strConcat("/token/", uint2str(_tokenId)));
  }

   

  function strConcat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory ba = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
    return string(ba);
  }

  function uint2str(uint256 _i) internal pure returns (string) {
    if (_i == 0) return "0";
    uint j = _i;
    uint length;
    while (j != 0){
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (_i != 0){
      bstr[k--] = byte(48 + _i % 10);
      _i /= 10;
    }
    return string(bstr);
  }
}