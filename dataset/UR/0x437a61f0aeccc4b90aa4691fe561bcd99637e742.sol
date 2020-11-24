 

pragma solidity ^0.4.24;


 
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
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
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}







 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
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
      emit Approval(owner, _to, _tokenId);
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
      emit Approval(_owner, address(0), _tokenId);
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
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}



 
contract ERC721Token is ERC721, ERC721BasicToken {
   
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







 
 
contract StrikersPlayerList is Ownable {
   
   
   
   
   
   
   
   
   
   

   
  event PlayerAdded(uint8 indexed id, string name);

   
   
  uint8 public playerCount;

   
   
   
   
  constructor() public {
    addPlayer("Lionel Messi");  
    addPlayer("Cristiano Ronaldo");  
    addPlayer("Neymar");  
    addPlayer("Mohamed Salah");  
    addPlayer("Robert Lewandowski");  
    addPlayer("Kevin De Bruyne");  
    addPlayer("Luka Modrić");  
    addPlayer("Eden Hazard");  
    addPlayer("Sergio Ramos");  
    addPlayer("Toni Kroos");  
    addPlayer("Luis Suárez");  
    addPlayer("Harry Kane");  
    addPlayer("Sergio Agüero");  
    addPlayer("Kylian Mbappé");  
    addPlayer("Gonzalo Higuaín");  
    addPlayer("David de Gea");  
    addPlayer("Antoine Griezmann");  
    addPlayer("N'Golo Kanté");  
    addPlayer("Edinson Cavani");  
    addPlayer("Paul Pogba");  
    addPlayer("Isco");  
    addPlayer("Marcelo");  
    addPlayer("Manuel Neuer");  
    addPlayer("Dries Mertens");  
    addPlayer("James Rodríguez");  
    addPlayer("Paulo Dybala");  
    addPlayer("Christian Eriksen");  
    addPlayer("David Silva");  
    addPlayer("Gabriel Jesus");  
    addPlayer("Thiago");  
    addPlayer("Thibaut Courtois");  
    addPlayer("Philippe Coutinho");  
    addPlayer("Andrés Iniesta");  
    addPlayer("Casemiro");  
    addPlayer("Romelu Lukaku");  
    addPlayer("Gerard Piqué");  
    addPlayer("Mats Hummels");  
    addPlayer("Diego Godín");  
    addPlayer("Mesut Özil");  
    addPlayer("Son Heung-min");  
    addPlayer("Raheem Sterling");  
    addPlayer("Hugo Lloris");  
    addPlayer("Radamel Falcao");  
    addPlayer("Ivan Rakitić");  
    addPlayer("Leroy Sané");  
    addPlayer("Roberto Firmino");  
    addPlayer("Sadio Mané");  
    addPlayer("Thomas Müller");  
    addPlayer("Dele Alli");  
    addPlayer("Keylor Navas");  
    addPlayer("Thiago Silva");  
    addPlayer("Raphaël Varane");  
    addPlayer("Ángel Di María");  
    addPlayer("Jordi Alba");  
    addPlayer("Medhi Benatia");  
    addPlayer("Timo Werner");  
    addPlayer("Gylfi Sigurðsson");  
    addPlayer("Nemanja Matić");  
    addPlayer("Kalidou Koulibaly");  
    addPlayer("Bernardo Silva");  
    addPlayer("Vincent Kompany");  
    addPlayer("João Moutinho");  
    addPlayer("Toby Alderweireld");  
    addPlayer("Emil Forsberg");  
    addPlayer("Mario Mandžukić");  
    addPlayer("Sergej Milinković-Savić");  
    addPlayer("Shinji Kagawa");  
    addPlayer("Granit Xhaka");  
    addPlayer("Andreas Christensen");  
    addPlayer("Piotr Zieliński");  
    addPlayer("Fyodor Smolov");  
    addPlayer("Xherdan Shaqiri");  
    addPlayer("Marcus Rashford");  
    addPlayer("Javier Hernández");  
    addPlayer("Hirving Lozano");  
    addPlayer("Hakim Ziyech");  
    addPlayer("Victor Moses");  
    addPlayer("Jefferson Farfán");  
    addPlayer("Mohamed Elneny");  
    addPlayer("Marcus Berg");  
    addPlayer("Guillermo Ochoa");  
    addPlayer("Igor Akinfeev");  
    addPlayer("Sardar Azmoun");  
    addPlayer("Christian Cueva");  
    addPlayer("Wahbi Khazri");  
    addPlayer("Keisuke Honda");  
    addPlayer("Tim Cahill");  
    addPlayer("John Obi Mikel");  
    addPlayer("Ki Sung-yueng");  
    addPlayer("Bryan Ruiz");  
    addPlayer("Maya Yoshida");  
    addPlayer("Nawaf Al Abed");  
    addPlayer("Lee Chung-yong");  
    addPlayer("Gabriel Gómez");  
    addPlayer("Naïm Sliti");  
    addPlayer("Reza Ghoochannejhad");  
    addPlayer("Mile Jedinak");  
    addPlayer("Mohammad Al-Sahlawi");  
    addPlayer("Aron Gunnarsson");  
    addPlayer("Blas Pérez");  
    addPlayer("Dani Alves");  
    addPlayer("Zlatan Ibrahimović");  
  }

   
   
  function addPlayer(string _name) public onlyOwner {
    require(playerCount < 255, "You've already added the maximum amount of players.");
    emit PlayerAdded(playerCount, _name);
    playerCount++;
  }
}


 
 
contract StrikersChecklist is StrikersPlayerList {
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

   
   
  enum DeployStep {
    WaitingForStepOne,
    WaitingForStepTwo,
    WaitingForStepThree,
    WaitingForStepFour,
    DoneInitialDeploy
  }

   
   
  enum RarityTier {
    IconicReferral,
    IconicInsert,
    Diamond,
    Gold,
    Silver,
    Bronze
  }

   
   
   
   
   
  uint16[] public tierLimits = [
    0,     
    100,   
    1000,  
    1664,  
    3328,  
    4352   
  ];

   
   
   
   
  struct ChecklistItem {
    uint8 playerId;
    RarityTier tier;
  }

   
  DeployStep public deployStep;

   
  ChecklistItem[] public originalChecklistItems;

   
  ChecklistItem[] public iconicChecklistItems;

   
  ChecklistItem[] public unreleasedChecklistItems;

   
   
   
  function _addOriginalChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    originalChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
   
   
  function _addIconicChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    iconicChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
   
   
   
  function addUnreleasedChecklistItem(uint8 _playerId, RarityTier _tier) external onlyOwner {
    require(deployStep == DeployStep.DoneInitialDeploy, "Finish deploying the Originals and Iconics sets first.");
    require(unreleasedCount() < 56, "You can't add any more checklist items.");
    require(_playerId < playerCount, "This player doesn't exist in our player list.");
    unreleasedChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
  function originalsCount() external view returns (uint256) {
    return originalChecklistItems.length;
  }

   
  function iconicsCount() public view returns (uint256) {
    return iconicChecklistItems.length;
  }

   
  function unreleasedCount() public view returns (uint256) {
    return unreleasedChecklistItems.length;
  }

   
   
   
   
   
   
   
   
   
   
   
   

   
  function deployStepOne() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepOne, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(0, RarityTier.Diamond);  
    _addOriginalChecklistItem(1, RarityTier.Diamond);  
    _addOriginalChecklistItem(2, RarityTier.Diamond);  
    _addOriginalChecklistItem(3, RarityTier.Diamond);  

     
    _addOriginalChecklistItem(4, RarityTier.Gold);  
    _addOriginalChecklistItem(5, RarityTier.Gold);  
    _addOriginalChecklistItem(6, RarityTier.Gold);  
    _addOriginalChecklistItem(7, RarityTier.Gold);  
    _addOriginalChecklistItem(8, RarityTier.Gold);  
    _addOriginalChecklistItem(9, RarityTier.Gold);  
    _addOriginalChecklistItem(10, RarityTier.Gold);  
    _addOriginalChecklistItem(11, RarityTier.Gold);  
    _addOriginalChecklistItem(12, RarityTier.Gold);  
    _addOriginalChecklistItem(13, RarityTier.Gold);  
    _addOriginalChecklistItem(14, RarityTier.Gold);  
    _addOriginalChecklistItem(15, RarityTier.Gold);  
    _addOriginalChecklistItem(16, RarityTier.Gold);  
    _addOriginalChecklistItem(17, RarityTier.Gold);  
    _addOriginalChecklistItem(18, RarityTier.Gold);  
    _addOriginalChecklistItem(19, RarityTier.Gold);  

     
    _addOriginalChecklistItem(20, RarityTier.Silver);  
    _addOriginalChecklistItem(21, RarityTier.Silver);  
    _addOriginalChecklistItem(22, RarityTier.Silver);  
    _addOriginalChecklistItem(23, RarityTier.Silver);  
    _addOriginalChecklistItem(24, RarityTier.Silver);  
    _addOriginalChecklistItem(25, RarityTier.Silver);  
    _addOriginalChecklistItem(26, RarityTier.Silver);  
    _addOriginalChecklistItem(27, RarityTier.Silver);  
    _addOriginalChecklistItem(28, RarityTier.Silver);  
    _addOriginalChecklistItem(29, RarityTier.Silver);  
    _addOriginalChecklistItem(30, RarityTier.Silver);  
    _addOriginalChecklistItem(31, RarityTier.Silver);  
    _addOriginalChecklistItem(32, RarityTier.Silver);  

     
    deployStep = DeployStep.WaitingForStepTwo;
  }

   
  function deployStepTwo() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepTwo, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(33, RarityTier.Silver);  
    _addOriginalChecklistItem(34, RarityTier.Silver);  
    _addOriginalChecklistItem(35, RarityTier.Silver);  
    _addOriginalChecklistItem(36, RarityTier.Silver);  
    _addOriginalChecklistItem(37, RarityTier.Silver);  
    _addOriginalChecklistItem(38, RarityTier.Silver);  
    _addOriginalChecklistItem(39, RarityTier.Silver);  
    _addOriginalChecklistItem(40, RarityTier.Silver);  
    _addOriginalChecklistItem(41, RarityTier.Silver);  
    _addOriginalChecklistItem(42, RarityTier.Silver);  
    _addOriginalChecklistItem(43, RarityTier.Silver);  
    _addOriginalChecklistItem(44, RarityTier.Silver);  
    _addOriginalChecklistItem(45, RarityTier.Silver);  
    _addOriginalChecklistItem(46, RarityTier.Silver);  
    _addOriginalChecklistItem(47, RarityTier.Silver);  
    _addOriginalChecklistItem(48, RarityTier.Silver);  
    _addOriginalChecklistItem(49, RarityTier.Silver);  

     
    _addOriginalChecklistItem(50, RarityTier.Bronze);  
    _addOriginalChecklistItem(51, RarityTier.Bronze);  
    _addOriginalChecklistItem(52, RarityTier.Bronze);  
    _addOriginalChecklistItem(53, RarityTier.Bronze);  
    _addOriginalChecklistItem(54, RarityTier.Bronze);  
    _addOriginalChecklistItem(55, RarityTier.Bronze);  
    _addOriginalChecklistItem(56, RarityTier.Bronze);  
    _addOriginalChecklistItem(57, RarityTier.Bronze);  
    _addOriginalChecklistItem(58, RarityTier.Bronze);  
    _addOriginalChecklistItem(59, RarityTier.Bronze);  
    _addOriginalChecklistItem(60, RarityTier.Bronze);  
    _addOriginalChecklistItem(61, RarityTier.Bronze);  
    _addOriginalChecklistItem(62, RarityTier.Bronze);  
    _addOriginalChecklistItem(63, RarityTier.Bronze);  
    _addOriginalChecklistItem(64, RarityTier.Bronze);  
    _addOriginalChecklistItem(65, RarityTier.Bronze);  

     
    deployStep = DeployStep.WaitingForStepThree;
  }

   
  function deployStepThree() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepThree, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(66, RarityTier.Bronze);  
    _addOriginalChecklistItem(67, RarityTier.Bronze);  
    _addOriginalChecklistItem(68, RarityTier.Bronze);  
    _addOriginalChecklistItem(69, RarityTier.Bronze);  
    _addOriginalChecklistItem(70, RarityTier.Bronze);  
    _addOriginalChecklistItem(71, RarityTier.Bronze);  
    _addOriginalChecklistItem(72, RarityTier.Bronze);  
    _addOriginalChecklistItem(73, RarityTier.Bronze);  
    _addOriginalChecklistItem(74, RarityTier.Bronze);  
    _addOriginalChecklistItem(75, RarityTier.Bronze);  
    _addOriginalChecklistItem(76, RarityTier.Bronze);  
    _addOriginalChecklistItem(77, RarityTier.Bronze);  
    _addOriginalChecklistItem(78, RarityTier.Bronze);  
    _addOriginalChecklistItem(79, RarityTier.Bronze);  
    _addOriginalChecklistItem(80, RarityTier.Bronze);  
    _addOriginalChecklistItem(81, RarityTier.Bronze);  
    _addOriginalChecklistItem(82, RarityTier.Bronze);  
    _addOriginalChecklistItem(83, RarityTier.Bronze);  
    _addOriginalChecklistItem(84, RarityTier.Bronze);  
    _addOriginalChecklistItem(85, RarityTier.Bronze);  
    _addOriginalChecklistItem(86, RarityTier.Bronze);  
    _addOriginalChecklistItem(87, RarityTier.Bronze);  
    _addOriginalChecklistItem(88, RarityTier.Bronze);  
    _addOriginalChecklistItem(89, RarityTier.Bronze);  
    _addOriginalChecklistItem(90, RarityTier.Bronze);  
    _addOriginalChecklistItem(91, RarityTier.Bronze);  
    _addOriginalChecklistItem(92, RarityTier.Bronze);  
    _addOriginalChecklistItem(93, RarityTier.Bronze);  
    _addOriginalChecklistItem(94, RarityTier.Bronze);  
    _addOriginalChecklistItem(95, RarityTier.Bronze);  
    _addOriginalChecklistItem(96, RarityTier.Bronze);  
    _addOriginalChecklistItem(97, RarityTier.Bronze);  
    _addOriginalChecklistItem(98, RarityTier.Bronze);  
    _addOriginalChecklistItem(99, RarityTier.Bronze);  

     
    deployStep = DeployStep.WaitingForStepFour;
  }

   
  function deployStepFour() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepFour, "You're not following the steps in order...");

     
    _addIconicChecklistItem(0, RarityTier.IconicInsert);  
    _addIconicChecklistItem(1, RarityTier.IconicInsert);  
    _addIconicChecklistItem(2, RarityTier.IconicInsert);  
    _addIconicChecklistItem(3, RarityTier.IconicInsert);  
    _addIconicChecklistItem(4, RarityTier.IconicInsert);  
    _addIconicChecklistItem(5, RarityTier.IconicInsert);  
    _addIconicChecklistItem(6, RarityTier.IconicInsert);  
    _addIconicChecklistItem(7, RarityTier.IconicInsert);  
    _addIconicChecklistItem(8, RarityTier.IconicInsert);  
    _addIconicChecklistItem(9, RarityTier.IconicInsert);  
    _addIconicChecklistItem(10, RarityTier.IconicInsert);  
    _addIconicChecklistItem(11, RarityTier.IconicInsert);  
    _addIconicChecklistItem(12, RarityTier.IconicInsert);  
    _addIconicChecklistItem(15, RarityTier.IconicInsert);  
    _addIconicChecklistItem(16, RarityTier.IconicInsert);  
    _addIconicChecklistItem(17, RarityTier.IconicReferral);  
    _addIconicChecklistItem(18, RarityTier.IconicReferral);  
    _addIconicChecklistItem(19, RarityTier.IconicInsert);  
    _addIconicChecklistItem(21, RarityTier.IconicInsert);  
    _addIconicChecklistItem(24, RarityTier.IconicInsert);  
    _addIconicChecklistItem(26, RarityTier.IconicInsert);  
    _addIconicChecklistItem(29, RarityTier.IconicReferral);  
    _addIconicChecklistItem(36, RarityTier.IconicReferral);  
    _addIconicChecklistItem(38, RarityTier.IconicReferral);  
    _addIconicChecklistItem(39, RarityTier.IconicInsert);  
    _addIconicChecklistItem(46, RarityTier.IconicInsert);  
    _addIconicChecklistItem(48, RarityTier.IconicInsert);  
    _addIconicChecklistItem(49, RarityTier.IconicReferral);  
    _addIconicChecklistItem(73, RarityTier.IconicInsert);  
    _addIconicChecklistItem(85, RarityTier.IconicInsert);  
    _addIconicChecklistItem(100, RarityTier.IconicReferral);  
    _addIconicChecklistItem(101, RarityTier.IconicReferral);  

     
    deployStep = DeployStep.DoneInitialDeploy;
  }

   
   
   
  function limitForChecklistId(uint8 _checklistId) external view returns (uint16) {
    RarityTier rarityTier;
    uint8 index;
    if (_checklistId < 100) {  
      rarityTier = originalChecklistItems[_checklistId].tier;
    } else if (_checklistId < 200) {  
      index = _checklistId - 100;
      require(index < iconicsCount(), "This Iconics checklist item doesn't exist.");
      rarityTier = iconicChecklistItems[index].tier;
    } else {  
      index = _checklistId - 200;
      require(index < unreleasedCount(), "This Unreleased checklist item doesn't exist.");
      rarityTier = unreleasedChecklistItems[index].tier;
    }
    return tierLimits[uint8(rarityTier)];
  }
}


 
 
contract StrikersBase is ERC721Token("CryptoStrikers", "STRK") {

   
  event CardMinted(uint256 cardId);

   
  struct Card {
     
     
     
    uint32 mintTime;

     
    uint8 checklistId;

     
     
     
    uint16 serialNumber;
  }

   

   
  Card[] public cards;

   
   
   
   
  mapping (uint8 => uint16) public mintedCountForChecklistId;

   
  StrikersChecklist public strikersChecklist;

   

   
   
   
   
  function cardAndChecklistIdsForOwner(address _owner) external view returns (uint256[], uint8[]) {
    uint256[] memory cardIds = ownedTokens[_owner];
    uint256 cardCount = cardIds.length;
    uint8[] memory checklistIds = new uint8[](cardCount);

    for (uint256 i = 0; i < cardCount; i++) {
      uint256 cardId = cardIds[i];
      checklistIds[i] = cards[cardId].checklistId;
    }

    return (cardIds, checklistIds);
  }

   
   
   
   
  function _mintCard(
    uint8 _checklistId,
    address _owner
  )
    internal
    returns (uint256)
  {
    uint16 mintLimit = strikersChecklist.limitForChecklistId(_checklistId);
    require(mintLimit == 0 || mintedCountForChecklistId[_checklistId] < mintLimit, "Can't mint any more of this card!");
    uint16 serialNumber = ++mintedCountForChecklistId[_checklistId];
    Card memory newCard = Card({
      mintTime: uint32(now),
      checklistId: _checklistId,
      serialNumber: serialNumber
    });
    uint256 newCardId = cards.push(newCard) - 1;
    emit CardMinted(newCardId);
    _mint(_owner, newCardId);
    return newCardId;
  }
}


contract StrikersUpdate is Ownable {

  event PickMade(address indexed user, uint8 indexed game, uint256 cardId);
  event CardUpgraded(address indexed user, uint8 indexed game, uint256 cardId);

  uint8 constant CHECKLIST_ITEM_COUNT = 132;
  uint8 constant GAME_COUNT = 8;

  mapping (uint256 => uint8) public starCountForCard;
  mapping (address => uint256[GAME_COUNT]) public picksForUser;

  struct Game {
    uint8[] acceptedChecklistIds;
    uint32 startTime;
    uint8 homeTeam;
    uint8 awayTeam;
  }

  Game[] public games;

  StrikersBase public strikersBaseContract;

  constructor(address _strikersBaseAddress) public {
    strikersBaseContract = StrikersBase(_strikersBaseAddress);

     

     
    Game memory game57;
    game57.startTime = 1530885600;
    game57.homeTeam = 31;
    game57.awayTeam = 10;
    games.push(game57);
    games[0].acceptedChecklistIds = [10, 13, 16, 17, 18, 19, 37, 41, 51];

     
    Game memory game58;
    game58.startTime = 1530900000;
    game58.homeTeam = 3;
    game58.awayTeam = 2;
    games.push(game58);
    games[1].acceptedChecklistIds = [2, 5, 7, 21, 23, 28, 30, 31, 33, 34, 45, 50, 60, 62];

     
    Game memory game60;
    game60.startTime = 1530972000;
    game60.homeTeam = 28;
    game60.awayTeam = 9;
    games.push(game60);
    games[2].acceptedChecklistIds = [11, 40, 48, 63, 72, 79];

     
    Game memory game59;
    game59.startTime = 1530986400;
    game59.homeTeam = 22;
    game59.awayTeam = 6;
    games.push(game59);
    games[3].acceptedChecklistIds = [6, 43, 64, 70, 81];

     

     
    Game memory game61;
    game61.startTime = 1531245600;
    games.push(game61);

     
    Game memory game62;
    game62.startTime = 1531332000;
    games.push(game62);

     

     
    Game memory game63;
    game63.startTime = 1531580400;
    games.push(game63);

     

     
    Game memory game64;
    game64.startTime = 1531666800;
    games.push(game64);
  }

  function updateGame(uint8 _game, uint8[] _acceptedChecklistIds, uint32 _startTime, uint8 _homeTeam, uint8 _awayTeam) external onlyOwner {
    Game storage game = games[_game];
    game.acceptedChecklistIds = _acceptedChecklistIds;
    game.startTime = _startTime;
    game.homeTeam = _homeTeam;
    game.awayTeam = _awayTeam;
  }

  function getGame(uint8 _game)
    external
    view
    returns (
    uint8[] acceptedChecklistIds,
    uint32 startTime,
    uint8 homeTeam,
    uint8 awayTeam
  ) {
    Game memory game = games[_game];
    acceptedChecklistIds = game.acceptedChecklistIds;
    startTime = game.startTime;
    homeTeam = game.homeTeam;
    awayTeam = game.awayTeam;
  }

  function makePick(uint8 _game, uint256 _cardId) external {
    Game memory game = games[_game];
    require(now < game.startTime, "This game has already started.");
    require(strikersBaseContract.ownerOf(_cardId) == msg.sender, "You don't own this card.");
    uint8 checklistId;
    (,checklistId,) = strikersBaseContract.cards(_cardId);
    require(_arrayContains(game.acceptedChecklistIds, checklistId), "This card is invalid for this game.");
    picksForUser[msg.sender][_game] = _cardId;
    emit PickMade(msg.sender, _game, _cardId);
  }

  function _arrayContains(uint8[] _array, uint8 _element) internal pure returns (bool) {
    for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == _element) {
        return true;
      }
    }

    return false;
  }

  function updateCards(uint8 _game, uint256[] _cardIds) external onlyOwner {
    for (uint256 i = 0; i < _cardIds.length; i++) {
      uint256 cardId = _cardIds[i];
      address owner = strikersBaseContract.ownerOf(cardId);
      if (picksForUser[owner][_game] == cardId) {
        starCountForCard[cardId]++;
        emit CardUpgraded(owner, _game, cardId);
      }
    }
  }

  function getPicksForUser(address _user) external view returns (uint256[GAME_COUNT]) {
    return picksForUser[_user];
  }

  function starCountsForOwner(address _owner) external view returns (uint8[]) {
    uint256[] memory cardIds;
    (cardIds,) = strikersBaseContract.cardAndChecklistIdsForOwner(_owner);
    uint256 cardCount = cardIds.length;
    uint8[] memory starCounts = new uint8[](cardCount);

    for (uint256 i = 0; i < cardCount; i++) {
      uint256 cardId = cardIds[i];
      starCounts[i] = starCountForCard[cardId];
    }

    return starCounts;
  }

  function getMintedCounts() external view returns (uint16[CHECKLIST_ITEM_COUNT]) {
    uint16[CHECKLIST_ITEM_COUNT] memory mintedCounts;

    for (uint8 i = 0; i < CHECKLIST_ITEM_COUNT; i++) {
      mintedCounts[i] = strikersBaseContract.mintedCountForChecklistId(i);
    }

    return mintedCounts;
  }
}