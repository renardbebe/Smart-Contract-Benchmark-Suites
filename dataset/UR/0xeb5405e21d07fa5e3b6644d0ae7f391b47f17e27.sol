 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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
  )
    public;
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
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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







 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
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


 
 
contract StrikersMinting is StrikersBase, Pausable {

   
  event PulledFromCirculation(uint8 checklistId);

   
  mapping (uint8 => bool) public outOfCirculation;

   
  address public packSaleAddress;

   
   
  function setPackSaleAddress(address _address) external onlyOwner {
    packSaleAddress = _address;
  }

   
   
   
   
  function mintPackSaleCard(uint8 _checklistId, address _owner) external returns (uint256) {
    require(msg.sender == packSaleAddress, "Only the pack sale contract can mint here.");
    require(!outOfCirculation[_checklistId], "Can't mint any more of this checklist item...");
    return _mintCard(_checklistId, _owner);
  }

   
   
   
  function mintUnreleasedCard(uint8 _checklistId, address _owner) external onlyOwner {
    require(_checklistId >= 200, "You can only use this to mint unreleased cards.");
    require(!outOfCirculation[_checklistId], "Can't mint any more of this checklist item...");
    _mintCard(_checklistId, _owner);
  }

   
   
  function pullFromCirculation(uint8 _checklistId) external {
    bool ownerOrPackSale = (msg.sender == owner) || (msg.sender == packSaleAddress);
    require(ownerOrPackSale, "Only the owner or pack sale can take checklist items out of circulation.");
    require(_checklistId >= 100, "This function is reserved for Iconics and Unreleased sets.");
    outOfCirculation[_checklistId] = true;
    emit PulledFromCirculation(_checklistId);
  }
}



 
 
contract StrikersPackFactory is Pausable {

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

   

   
  event PacksLoaded(uint8 indexed saleId, uint32[] packs);

   
  event SaleStarted(uint8 saleId, uint256 packPrice, uint8 featuredChecklistItem);

   
  event StandardPackPriceChanged(uint256 packPrice);

   

   
  uint32 public constant MAX_STANDARD_SALE_PACKS = 75616;

   
  uint16 public constant PREMIUM_SALE_PACK_COUNT = 500;

   
  uint8 public constant MAX_NUMBER_OF_PREMIUM_SALES = 24;

   

   
  struct PackSale {
     
    uint8 id;

     
    uint8 featuredChecklistItem;

     
     
    uint256 packPrice;

     
    uint32[] packs;

     
     
    uint32 packsLoaded;

     
    uint32 packsSold;
  }

   

   
  StrikersMinting public mintingContract;

   
  PackSale public standardSale;

   
  PackSale public currentPremiumSale;

   
  PackSale public nextPremiumSale;

   
  uint8 public saleCount;

   

  modifier nonZeroPackPrice(uint256 _packPrice) {
    require(_packPrice > 0, "Free packs are only available through the whitelist.");
    _;
  }

   

  constructor(uint256 _packPrice) public {
     
    paused = true;
     
    setStandardPackPrice(_packPrice);
    saleCount++;
  }

   

   
   
   
  function _addPacksToSale(uint32[] _newPacks, PackSale storage _sale) internal {
    for (uint256 i = 0; i < _newPacks.length; i++) {
      _sale.packs.push(_newPacks[i]);
    }
    _sale.packsLoaded += uint32(_newPacks.length);
    emit PacksLoaded(_sale.id, _newPacks);
  }

   

   
   
  function addPacksToStandardSale(uint32[] _newPacks) external onlyOwner {
    bool tooManyPacks = standardSale.packsLoaded + _newPacks.length > MAX_STANDARD_SALE_PACKS;
    require(!tooManyPacks, "You can't add more than 75,616 packs to the Standard sale.");
    _addPacksToSale(_newPacks, standardSale);
  }

   
  function startStandardSale() external onlyOwner {
    require(standardSale.packsLoaded > 0, "You must first load some packs into the Standard sale.");
    unpause();
    emit SaleStarted(standardSale.id, standardSale.packPrice, standardSale.featuredChecklistItem);
  }

   
   
   
  function setStandardPackPrice(uint256 _packPrice) public onlyOwner nonZeroPackPrice(_packPrice) {
    standardSale.packPrice = _packPrice;
    emit StandardPackPriceChanged(_packPrice);
  }

   

   
   
   
  function createNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice == 0, "Next Premium Sale already exists.");
    require(_featuredChecklistItem >= 100, "You can't have an Originals as a featured checklist item.");
    require(saleCount <= MAX_NUMBER_OF_PREMIUM_SALES, "You can only run 24 total Premium sales.");
    nextPremiumSale.id = saleCount;
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
    saleCount++;
  }

   
   
  function addPacksToNextPremiumSale(uint32[] _newPacks) external onlyOwner {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    require(nextPremiumSale.packsLoaded + _newPacks.length <= PREMIUM_SALE_PACK_COUNT, "You can't add more than 500 packs to a Premium sale.");
    _addPacksToSale(_newPacks, nextPremiumSale);
  }

   
   
  function startNextPremiumSale() external onlyOwner {
    require(nextPremiumSale.packsLoaded == PREMIUM_SALE_PACK_COUNT, "You must add exactly 500 packs before starting this Premium sale.");
    if (currentPremiumSale.featuredChecklistItem >= 100) {
      mintingContract.pullFromCirculation(currentPremiumSale.featuredChecklistItem);
    }
    currentPremiumSale = nextPremiumSale;
    delete nextPremiumSale;
  }

   
   
   
  function modifyNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
  }
}


 
 
contract StrikersPackSaleInternal is StrikersPackFactory {

   
  event PackBought(address indexed buyer, uint256[] pack);

   
  uint8 public constant PACK_SIZE = 4;

   
  uint256 internal randNonce;

   
   
  function _buyPack(PackSale storage _sale) internal whenNotPaused {
    require(msg.sender == tx.origin, "Only EOAs are allowed to buy from the pack sale.");
    require(_sale.packs.length > 0, "The sale has no packs available for sale.");
    uint32 pack = _removeRandomPack(_sale.packs);
    uint256[] memory cards = _mintCards(pack);
    _sale.packsSold++;
    emit PackBought(msg.sender, cards);
  }

   
   
   
  function _mintCards(uint32 _pack) internal returns (uint256[]) {
    uint8 mask = 255;
    uint256[] memory newCards = new uint256[](PACK_SIZE);

    for (uint8 i = 1; i <= PACK_SIZE; i++) {
       
      uint8 shift = 32 - (i * 8);
      uint8 checklistId = uint8((_pack >> shift) & mask);
      uint256 cardId = mintingContract.mintPackSaleCard(checklistId, msg.sender);
      newCards[i-1] = cardId;
    }

    return newCards;
  }

   
   
   
  function _removeRandomPack(uint32[] storage _packs) internal returns (uint32) {
    randNonce++;
    bytes memory packed = abi.encodePacked(now, msg.sender, randNonce);
    uint256 randomIndex = uint256(keccak256(packed)) % _packs.length;
    return _removePackAtIndex(randomIndex, _packs);
  }

   
   
   
   
  function _removePackAtIndex(uint256 _index, uint32[] storage _packs) internal returns (uint32) {
     
    uint256 lastIndex = _packs.length - 1;
    require(_index <= lastIndex);
    uint32 pack = _packs[_index];
    _packs[_index] = _packs[lastIndex];
    _packs.length--;
    return pack;
  }
}


 
 
contract StrikersWhitelist is StrikersPackSaleInternal {

   
  event WhitelistAllocationIncreased(address indexed user, uint16 amount, bool premium);

   
  event WhitelistAllocationUsed(address indexed user, bool premium);

   
  uint16[2] public whitelistLimits = [
    1000,  
    500  
  ];

   
  uint16[2] public currentWhitelistCounts;

   
  mapping (address => uint8)[2] public whitelists;

   
   
   
   
  function addToWhitelistAllocation(bool _premium, address _addr, uint8 _additionalPacks) public onlyOwner {
    uint8 listIndex = _premium ? 1 : 0;
    require(currentWhitelistCounts[listIndex] + _additionalPacks <= whitelistLimits[listIndex]);
    currentWhitelistCounts[listIndex] += _additionalPacks;
    whitelists[listIndex][_addr] += _additionalPacks;
    emit WhitelistAllocationIncreased(_addr, _additionalPacks, _premium);
  }

   
   
   
  function addAddressesToWhitelist(bool _premium, address[] _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      addToWhitelistAllocation(_premium, _addrs[i], 1);
    }
  }

   
   
  function claimWhitelistPack(bool _premium) external {
    uint8 listIndex = _premium ? 1 : 0;
    require(whitelists[listIndex][msg.sender] > 0, "You have no whitelist allocation.");
     
    whitelists[listIndex][msg.sender]--;
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    _buyPack(sale);
    emit WhitelistAllocationUsed(msg.sender, _premium);
  }
}


 
 
contract StrikersReferral is StrikersWhitelist {

   
  uint16 public constant MAX_FREE_REFERRAL_PACKS = 5000;

   
  uint256 public constant PERCENT_COMMISSION = 10;

   
  uint8[] public bonusCards = [
    115,  
    127,  
    122,  
    130,  
    116,  
    123,  
    121,  
    131  
  ];

   
  event SaleAttributed(address indexed referrer, address buyer, uint256 amount);

   
  mapping (address => uint8) public bonusCardsClaimed;

   
  mapping (address => uint16) public packsBought;

   
  uint16 public freeReferralPacksClaimed;

   
  mapping (address => bool) public hasClaimedFreeReferralPack;

   
  mapping (address => uint256) public referralCommissionClaimed;

   
  mapping (address => uint256) public referralCommissionEarned;

   
  mapping (address => uint16) public referralSaleCount;

   
  mapping (address => address) public referrers;

   
  uint256 public totalCommissionOwed;

   
   
   
  function _attributeSale(address _buyer, uint256 _amount) internal {
    address referrer = referrers[_buyer];

     
     
    if (referrer == address(0) || packsBought[referrer] == 0) {
      return;
    }

    referralSaleCount[referrer]++;

     
     
    if (referralSaleCount[referrer] > bonusCards.length) {
      uint256 commission = _amount * PERCENT_COMMISSION / 100;
      totalCommissionOwed += commission;
      referralCommissionEarned[referrer] += commission;
    }

    emit SaleAttributed(referrer, _buyer, _amount);
  }

   
  function claimBonusCard() external {
    uint16 attributedSales = referralSaleCount[msg.sender];
    uint8 cardsClaimed = bonusCardsClaimed[msg.sender];
    require(attributedSales > cardsClaimed, "You have no unclaimed bonus cards.");
    require(cardsClaimed < bonusCards.length, "You have claimed all the bonus cards.");
    bonusCardsClaimed[msg.sender]++;
    uint8 bonusCardChecklistId = bonusCards[cardsClaimed];
    mintingContract.mintPackSaleCard(bonusCardChecklistId, msg.sender);
  }

   
  function claimFreeReferralPack() external {
    require(isOwedFreeReferralPack(msg.sender), "You are not eligible for a free referral pack.");
    require(freeReferralPacksClaimed < MAX_FREE_REFERRAL_PACKS, "We've already given away all the free referral packs...");
    freeReferralPacksClaimed++;
    hasClaimedFreeReferralPack[msg.sender] = true;
    _buyPack(standardSale);
  }

   
   
   
  function isOwedFreeReferralPack(address _addr) public view returns (bool) {
     
    address referrer = referrers[_addr];

     
     
    bool referrerHasBoughtPack = packsBought[referrer] > 0;

     
    return referrerHasBoughtPack && !hasClaimedFreeReferralPack[_addr];
  }

   
   
   
  function setReferrer(address _for, address _referrer) external onlyOwner {
    referrers[_for] = _referrer;
  }

   
  function withdrawCommission() external {
    uint256 commission = referralCommissionEarned[msg.sender] - referralCommissionClaimed[msg.sender];
    require(commission > 0, "You are not owed any referral commission.");
    totalCommissionOwed -= commission;
    referralCommissionClaimed[msg.sender] += commission;
    msg.sender.transfer(commission);
  }
}



 
 
contract StrikersPackSale is StrikersReferral {

   
  uint16 public constant KITTY_BURN_LIMIT = 1000;

   
  event KittyBurned(address user, uint256 kittyId);

   
  mapping (address => bool) public hasBurnedKitty;

   
  ERC721Basic public kittiesContract;

   
  uint16 public totalKittiesBurned;

   
  uint256 public totalWeiRaised;

   
  constructor(
    uint256 _standardPackPrice,
    address _kittiesContractAddress,
    address _mintingContractAddress
  )
  StrikersPackFactory(_standardPackPrice)
  public
  {
    kittiesContract = ERC721Basic(_kittiesContractAddress);
    mintingContract = StrikersMinting(_mintingContractAddress);
  }

   
   
   
  function buyFirstPackFromReferral(address _referrer, bool _premium) external payable {
    require(packsBought[msg.sender] == 0, "Only assign a referrer on a user's first purchase.");
    referrers[msg.sender] = _referrer;
    buyPackWithETH(_premium);
  }

   
   
  function buyPackWithETH(bool _premium) public payable {
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    uint256 packPrice = sale.packPrice;
    require(msg.value >= packPrice, "Insufficient ETH sent to buy this pack.");
    _buyPack(sale);
    packsBought[msg.sender]++;
    totalWeiRaised += packPrice;
     
    msg.sender.transfer(msg.value - packPrice);
    _attributeSale(msg.sender, packPrice);
  }

   
   
   
   
   
  function buyPackWithKitty(uint256 _kittyId) external {
    require(totalKittiesBurned < KITTY_BURN_LIMIT, "Stop! Think of the cats!");
    require(!hasBurnedKitty[msg.sender], "You've already burned a kitty.");
    totalKittiesBurned++;
    hasBurnedKitty[msg.sender] = true;
     
     
     
    kittiesContract.transferFrom(msg.sender, this, _kittyId);
    _buyPack(standardSale);
    emit KittyBurned(msg.sender, _kittyId);
  }

   
  function withdrawBalance() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > totalCommissionOwed, "There is no ETH for the owner to claim.");
    owner.transfer(totalBalance - totalCommissionOwed);
  }
}