 

pragma solidity 0.4.23;

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
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


contract WikiFactory is Ownable, ERC721BasicToken {

  struct WikiPage {
      string title;
      string articleHash;  
      string imageHash;
      uint price;  
  }

  WikiPage[] public wikiPages;

   
  mapping (address => uint256[]) internal ownedTokens;
   
  mapping(uint256 => uint256) internal ownedTokensIndex;

  uint costToCreate = 40000000000000000 wei;
  function setCostToCreate(uint _fee) external onlyOwner {
    costToCreate = _fee;
  }
   

  function createWikiPage(string _title, string _articleHash, string _imageHash, uint _price) public onlyOwner returns (uint) {
    uint id = wikiPages.push(WikiPage(_title, _articleHash, _imageHash, _price)) - 1;
     
    _ownMint(id);
  }

  function paidCreateWikiPage(string _title, string _articleHash, string _imageHash, uint _price) public payable {
    require(msg.value >= costToCreate);
    uint id = wikiPages.push(WikiPage(_title, _articleHash, _imageHash, _price)) - 1;
     
    _ownMint(id);
  }

  function _ownMint(uint _id) internal {
    uint256 length = ownedTokens[msg.sender].length;
    ownedTokens[msg.sender].push(_id);
    ownedTokensIndex[_id] = length;
    _mint(msg.sender, _id);
  }

   

  function numberWikiPages() public view returns(uint) {
    return wikiPages.length;
  }

   
  function wikiAddTokenTo(address _to, uint256 _tokenId) internal {
    addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function wikiRemoveTokenFrom(address _from, uint256 _tokenId) internal {
    removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length - 1;
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }
}

contract ManageWikiPage is WikiFactory {


  event WikiPageChanged(uint id);

  mapping(uint => mapping(address => mapping(address => bool))) public collaborators;

   
  modifier canEdit(uint256 _tokenId) {
    require(isCollaboratorOrOwner(msg.sender, _tokenId));
    _;
  }

  function isCollaboratorOrOwner(address _editor, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    bool isCollaborator = collaborators[_tokenId][owner][_editor];

    return _editor == owner || isCollaborator;
  }

   
   

  function addCollaborator(uint _tokenId, address collaborator) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    collaborators[_tokenId][owner][collaborator] = true;
  }

  function removeCollaborator(uint _tokenId, address collaborator) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    collaborators[_tokenId][owner][collaborator] = false;
  }

  function setArticleHash(uint _wikiId, string _articleHash) public canEdit(_wikiId) {
    WikiPage storage wikiToChange = wikiPages[_wikiId];
    wikiToChange.articleHash = _articleHash;
    emit WikiPageChanged(_wikiId);
  }

  function setImageHash(uint _wikiId, string _imageHash) public canEdit(_wikiId) {
    WikiPage storage wikiToChange = wikiPages[_wikiId];
    wikiToChange.imageHash = _imageHash;
    emit WikiPageChanged(_wikiId);
  }

  function doublePrice(uint _wikiId) internal {
    WikiPage storage wikiToChange = wikiPages[_wikiId];
    wikiToChange.price = wikiToChange.price * 2;
    emit WikiPageChanged(_wikiId);
  }
}

contract Wikipediapp is ManageWikiPage {
  string public name = "WikiToken";
  string public symbol = "WT";

  function buyFromCurrentOwner(uint _tokenId) public payable {
    require(_tokenId < wikiPages.length);
    require(tokenOwner[_tokenId] != msg.sender);

    WikiPage storage wikiToChange = wikiPages[_tokenId];
    require(msg.value >= wikiToChange.price);

    address previousOwner = tokenOwner[_tokenId];
    if (previousOwner == address(0)) {
      previousOwner = owner;  
    }

    wikiRemoveTokenFrom(previousOwner, _tokenId);
    wikiAddTokenTo(msg.sender, _tokenId);

    previousOwner.transfer((wikiToChange.price * 95) / 100);

    doublePrice(_tokenId);
  }

  function getContractBalance() constant returns (uint){
    return this.balance;
  }

  function sendBalance() public onlyOwner {
    owner.transfer(address(this).balance);
  }
}