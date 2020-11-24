 

pragma solidity ^0.4.18;  



 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract HiPrecious is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "HiPrecious";  
  string public constant SYMBOL = "HIP";  

   

   
   
  mapping (uint256 => address) public preciousIndexToOwner;

   
   
  mapping (address => uint256) private ownershipPreciousCount;

   
   
   
  mapping (uint256 => address) public preciousIndexToApproved;

   
  address public daVinciAddress;  
  address public cresusAddress;   
  
  
 function () public payable {}  

   

  struct Precious {
    string name;   
    uint256 number;  
    uint256 editionId;   
    uint256 collectionId;  
    string tokenURI;
  }

  struct Edition {
    uint256 id;
    string name;  
    uint256 worldQuantity;  
    uint256[] preciousIds;  
    uint256 collectionId;
  }

  struct Collection {
    uint256 id;
    string name;  
    uint256[] editionIds;  
  }

  Precious[] private allPreciouses;
  Edition[] private allEditions;
  Collection[] private allCollections;

   
   
  modifier onlyDaVinci() {
    require(msg.sender == daVinciAddress);
    _;
  }

   
  modifier onlyCresus() {
    require(msg.sender == cresusAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(msg.sender == daVinciAddress || msg.sender == cresusAddress);
    _;
  }

   
  function HiPrecious() public {
    daVinciAddress = msg.sender;
    cresusAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    preciousIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipPreciousCount[_owner];
  }

   
  function createContractCollection(string _name) public onlyDaVinci {
    _createCollection(_name);
  }

   
  function createContractEditionForCollection(string _name, uint256 _collectionId, uint256 _worldQuantity) public onlyDaVinci {
    _createEdition(_name, _collectionId, _worldQuantity);
  }
  
     
  function createContractPreciousForEdition(address _to, uint256 _editionId, string _tokenURI) public onlyDaVinci {
    _createPrecious(_to, _editionId, _tokenURI);
  }

   
   
  function getPrecious(uint256 _tokenId) public view returns (
    string preciousName,
    uint256 number,
    uint256 editionId,
    uint256 collectionId,
    address owner
  ) {
    Precious storage precious = allPreciouses[_tokenId];
    preciousName = precious.name;
    number = precious.number;
    editionId = precious.editionId;
    collectionId = precious.collectionId;
    owner = preciousIndexToOwner[_tokenId];
  }

   
   
  function getEdition(uint256 _editionId) public view returns (
    uint256 id,
    string editionName,
    uint256 worldQuantity,
    uint256[] preciousIds
  ) {
    Edition storage edition = allEditions[_editionId-1];
    id = edition.id;
    editionName = edition.name;
    worldQuantity = edition.worldQuantity;
    preciousIds = edition.preciousIds;
  }

   
   
  function getCollection(uint256 _collectionId) public view returns (
    uint256 id,
    string collectionName,
    uint256[] editionIds
  ) {
    Collection storage collection = allCollections[_collectionId-1];
    id = collection.id;
    collectionName = collection.name;
    editionIds = collection.editionIds;
  }


  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = preciousIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCresus {
    _payout(_to);
  }

   
   
  function setDaVinci(address _newDaVinci) public onlyDaVinci {
    require(_newDaVinci != address(0));

    daVinciAddress = _newDaVinci;
  }

   
   
  function setCresus(address _newCresus) public onlyCresus {
    require(_newCresus != address(0));

    cresusAddress = _newCresus;
  }

  function tokenURI(uint256 _tokenId) public view returns (string){
      require(_tokenId<allPreciouses.length);
      return allPreciouses[_tokenId].tokenURI;
  }
  
  function setTokenURI(uint256 _tokenId, string newURI) public onlyDaVinci{
      require(_tokenId<allPreciouses.length);
      Precious storage precious = allPreciouses[_tokenId];
      precious.tokenURI = newURI;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = preciousIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPreciouses = totalSupply();
      uint256 resultIndex = 0;

      uint256 preciousId;
      for (preciousId = 0; preciousId <= totalPreciouses; preciousId++) {
        if (preciousIndexToOwner[preciousId] == _owner) {
          result[resultIndex] = preciousId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return allPreciouses.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return preciousIndexToApproved[_tokenId] == _to;
  }

   
  function _createCollection(string _name) private onlyDaVinci{
    uint256 newCollectionId = allCollections.length+1;
    uint256[] storage newEditionIds;
    Collection memory _collection = Collection({
      id: newCollectionId,
      name: _name,
      editionIds: newEditionIds
    });

    allCollections.push(_collection);
  }

   
  function _createEdition(string _name, uint256 _collectionId, uint256 _worldQuantity) private onlyDaVinci{
    Collection storage collection = allCollections[_collectionId-1];  

    uint256 newEditionId = allEditions.length+1;
    uint256[] storage newPreciousIds;

    Edition memory _edition = Edition({
      id: newEditionId,
      name: _name,
      worldQuantity: _worldQuantity,
      preciousIds: newPreciousIds,
      collectionId: _collectionId
    });

    allEditions.push(_edition);
    collection.editionIds.push(newEditionId);
  }

   
  function _createPrecious(address _owner, uint256 _editionId, string _tokenURI) private onlyDaVinci{
    Edition storage edition = allEditions[_editionId-1];  
    
     
    require(edition.preciousIds.length < edition.worldQuantity);

     

    Precious memory _precious = Precious({
      name: edition.name,
      number: edition.preciousIds.length+1,
      editionId: _editionId,
      collectionId: edition.collectionId,
      tokenURI: _tokenURI
    });

    uint256 newPreciousId = allPreciouses.push(_precious) - 1;
    edition.preciousIds.push(newPreciousId);

     
     
    require(newPreciousId == uint256(uint32(newPreciousId)));

    emit Birth(newPreciousId, edition.name, _owner);

     
     
    _transfer(address(0), _owner, newPreciousId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == preciousIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      cresusAddress.transfer(address(this).balance);
    } else {
      _to.transfer(address(this).balance);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipPreciousCount[_to]++;
     
    preciousIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipPreciousCount[_from]--;
       
      delete preciousIndexToApproved[_tokenId];
    }

     
    emit Transfer(_from, _to, _tokenId);
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