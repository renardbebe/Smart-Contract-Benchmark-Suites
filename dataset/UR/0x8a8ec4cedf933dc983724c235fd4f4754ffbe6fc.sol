 

pragma solidity ^0.4.24;
 
 
 
 
interface ERC165 {
 
   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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
 
 
 
 
library AddressUtils {
 
   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
 
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
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
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
 
 
 
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
 
  bool public paused = false;
 
 
   
  modifier whenNotPaused() {
    require(!paused,"Contract is paused");
    _;
  }
 
   
  modifier whenPaused() {
    require(paused,"Contract is not paused");
    _;
  }
 
   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
 
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 
 
 
 
contract HodlEarthToken is ERC721Token, Ownable, Pausable {
  string public constant name = "HodlEarthToken";
  string public constant symbol = "HEAR";
 
  constructor() ERC721Token(name, symbol) public {
    owner = msg.sender;
  }
 
  mapping (uint256 => bytes7) public plotColours;
  mapping (uint256 => bytes32) public plotDescriptors;
 
  function calculatePlotPrice() public view returns(uint256 currentPlotPrice){
 
    if(totalSupply() < 250000){
        currentPlotPrice = 0.0004 * 1000000000000000000;
    } else currentPlotPrice = 0.001 * 1000000000000000000;
 
  }
 
  function calculateTransactionFee(uint256 _noPlots,bool _updatePlot) public pure returns(uint256 fee){
 
    uint256 plotPrice;
    plotPrice = 0.001 * 1000000000000000000;
    fee = plotPrice.div(10);
    fee = fee.mul(_noPlots);
 
    if(_updatePlot == false){
       
       uint256 minFee = 0.001 * 1000000000000000000;
       if(fee < minFee) fee = minFee;
    }
 
  }
 
  function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{
 
    super.transferFrom(_from,_to,_tokenId);
 
  }
 
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{
 
    super.safeTransferFrom(_from,_to,_tokenId);
 
  }
 
  function safeTransferFrom(address _from,address _to,uint256 _tokenId,bytes _data) public whenNotPaused{
 
    super.safeTransferFrom(_from,_to,_tokenId,_data);
 
  }
 
  function getPlot(uint256 _plotLat,uint256 _plotLng) public view returns(uint256 plotReference,bytes7 colour,bytes32 descriptor){
 
    plotReference = _generatePlotReference(_plotLat,_plotLng);
    colour = plotColours[plotReference];
    descriptor = plotDescriptors[plotReference];
 
  }
 
  function getPlotByReference(uint256 _plotReference) public view returns(bytes7 colour,bytes32 descriptor){
 
    colour = plotColours[_plotReference];
    descriptor = plotDescriptors[_plotReference];
 
  }
 
 
  function getPlots(uint256[] _plotLats,uint256[] _plotLngs) public view returns(uint256[],bytes7[],bytes32[]){
 
    uint arrayLength = _plotLats.length;
    uint256 plotReference;
    uint256[] memory plotIds = new uint[](arrayLength);
    bytes7[] memory colours = new bytes7[](arrayLength);
    bytes32[] memory descriptors = new bytes32[](arrayLength);
    for (uint i=0; i<arrayLength; i++) {
      plotReference = _generatePlotReference(_plotLats[i],_plotLngs[i]);
      plotIds[i] = plotReference;
      colours[i] =  plotColours[plotReference];
      descriptors[i] = plotDescriptors[plotReference];
 
    }
 
    return(plotIds,colours,descriptors);
  }
 
 
  function getPlotsByReference(uint256[] _plotReferences) public view returns(uint256[],bytes7[],bytes32[]){
 
    uint arrayLength = _plotReferences.length;
    uint256[] memory plotIds = new uint[](arrayLength);
    bytes7[] memory colours = new bytes7[](arrayLength);
    bytes32[] memory descriptors = new bytes32[](arrayLength);
    for (uint i=0; i<arrayLength; i++) {
      plotIds[i] = _plotReferences[i];
      colours[i] =  plotColours[_plotReferences[i]];
      descriptors[i] = plotDescriptors[_plotReferences[i]];
    }
 
    return(plotIds,colours,descriptors);
  }
 
 
  function newPlot(uint256 _plotLat,uint256 _plotLng,bytes7 _colour,bytes32 _title) public payable whenNotPaused{
 
    uint256 plotReference;
    bool validLatLng;
    uint256 plotPrice;
    uint256 transactionFee;
 
     
    plotPrice = calculatePlotPrice();
    transactionFee = calculateTransactionFee(1,false);
    if(msg.sender != owner){
        require(
            msg.value >= plotPrice + transactionFee,
            "Insufficient Eth sent."
        );
    }
 
    validLatLng = validatePlotLatLng(_plotLat,_plotLng);
    require(
        validLatLng == true,
        "Lat long is invalid"
    );
    plotReference = _generatePlotReference(_plotLat,_plotLng);
    require(
       plotColours[plotReference] == 0,
      "Plot already exists."
    );
    _addPlot(plotReference,_colour,_title);
 
  }
  function newPlots(uint256[] _plotLat,uint256[] _plotLng,bytes7[] _colours,bytes32[] _descriptors) public payable whenNotPaused{
 
    uint256 noPlots = _plotLat.length;
    bytes7 colour;
    bytes32 descriptor;
    uint256 plotReference;
    bool validLatLng;
    uint256 plotPrice;
    uint256 transactionFee;
 
    plotPrice = calculatePlotPrice();
    transactionFee = calculateTransactionFee(noPlots,false);
 
    if(msg.sender != owner){
      require(
        msg.value >= plotPrice.mul(noPlots) + transactionFee,
        "Insufficient Eth sent."
      );
    }
 
    for (uint i=0; i<noPlots; i++) {
        colour =  _colours[i];
        descriptor = _descriptors[i];
        validLatLng = validatePlotLatLng(_plotLat[i],_plotLng[i]);
        require(
           validLatLng == true,
           "Lat long is invalid"
        );
        plotReference = _generatePlotReference(_plotLat[i],_plotLng[i]);
        require(
           plotColours[plotReference] == 0,
          "Plot already exists."
        );
        _addPlot(plotReference,colour,descriptor);
    }
 
  }
 
  function _generatePlotReference(uint256 _plotLat,uint256 _plotLng) internal pure returns(uint256 plotReference){
 
    plotReference = (_plotLat * 1000000000) + _plotLng;
 
  }
 
  function _addPlot(uint256 _plotReference,bytes7 _colour,bytes32 _descriptor) private{
 
     
    plotColours[_plotReference] =  _colour;
    plotDescriptors[_plotReference] =  _descriptor;
    _mint(msg.sender, _plotReference);
  }
 
  function validatePlotLatLng(uint256 _lat,uint256 _lng) public pure returns(bool){
     
    if(_lat%5 == 0 && _lng%8 == 0) return true;
    return false;
  }
 
  function updatePlot(uint256 _plotLat,uint256 _plotLng,bytes7 _colour,bytes32 _descriptor) public payable whenNotPaused{
 
    uint256 plotReference;
    uint256 transactionFee;
 
    plotReference = _generatePlotReference(_plotLat,_plotLng);
    transactionFee = calculateTransactionFee(1,true);
 
    require(
      ownerOf(plotReference) == msg.sender,
      "Update can only be carried out by the plot owner."
    );
 
    if(msg.sender != owner){
      require(
      msg.value >= transactionFee,
          "Insufficient Eth sent."
      );
    }
    require(
      plotColours[plotReference] != 0,
      "Plot does not exist."
    );
 
 
    plotColours[plotReference] =  _colour;
    plotDescriptors[plotReference] = _descriptor;
  }
 
  function updatePlots(uint256[] _plotLat,uint256[] _plotLng,bytes7[] _colours,bytes32[] _descriptors) public payable whenNotPaused{
 
    uint256 noPlots = _plotLat.length;
    bytes7 colour;
    bytes32 descriptor;
    uint256 plotReference;
    uint256 transactionFee;
 
    transactionFee = calculateTransactionFee(noPlots,true);
 
    if(msg.sender != owner){
      require(
      msg.value >= transactionFee,
          "Insufficient Eth sent."
     );
    }
 
    for (uint i=0; i<noPlots; i++) {
        colour =  _colours[i];
        descriptor = _descriptors[i];
        plotReference = _generatePlotReference(_plotLat[i],_plotLng[i]);
        require(
            plotColours[plotReference] != 0,
            "Plot does not exist."
        );
        require(
            ownerOf(plotReference) == msg.sender,
            "Update can only be carried out by the plot owner."
        );
 
 
        plotColours[plotReference] =  colour;
        plotDescriptors[plotReference] = descriptor;
    }
  }
 
  function withdraw() public onlyOwner returns(bool) {
     owner.transfer(address(this).balance);
     return true;
  }
 
}