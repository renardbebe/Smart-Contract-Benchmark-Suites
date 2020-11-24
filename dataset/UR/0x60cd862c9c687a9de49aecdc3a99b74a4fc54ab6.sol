 

pragma solidity ^0.4.13;

contract MoonCatRescue {
  enum Modes { Inactive, Disabled, Test, Live }

  Modes public mode = Modes.Inactive;

  address owner;

  bytes16 public imageGenerationCodeMD5 = 0xdbad5c08ec98bec48490e3c196eec683;  

  string public name = "MoonCats";
  string public symbol = "?";  
  uint8 public decimals = 0;

  uint256 public totalSupply = 25600;
  uint16 public remainingCats = 25600 - 256;  
  uint16 public remainingGenesisCats = 256;  
  uint16 public rescueIndex = 0;

  bytes5[25600] public rescueOrder;

  bytes32 public searchSeed = 0x0;  

  struct AdoptionOffer {
    bool exists;
    bytes5 catId;
    address seller;
    uint price;
    address onlyOfferTo;
  }

  struct AdoptionRequest{
    bool exists;
    bytes5 catId;
    address requester;
    uint price;
  }

  mapping (bytes5 => AdoptionOffer) public adoptionOffers;
  mapping (bytes5 => AdoptionRequest) public adoptionRequests;

  mapping (bytes5 => bytes32) public catNames;
  mapping (bytes5 => address) public catOwners;
  mapping (address => uint256) public balanceOf;  
  mapping (address => uint) public pendingWithdrawals;

   

  event CatRescued(address indexed to, bytes5 indexed catId);
  event CatNamed(bytes5 indexed catId, bytes32 catName);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event CatAdopted(bytes5 indexed catId, uint price, address indexed from, address indexed to);
  event AdoptionOffered(bytes5 indexed catId, uint price, address indexed toAddress);
  event AdoptionOfferCancelled(bytes5 indexed catId);
  event AdoptionRequested(bytes5 indexed catId, uint price, address indexed from);
  event AdoptionRequestCancelled(bytes5 indexed catId);
  event GenesisCatsAdded(bytes5[16] catIds);

  function MoonCatRescue() payable {
    owner = msg.sender;
    assert((remainingCats + remainingGenesisCats) == totalSupply);
    assert(rescueOrder.length == totalSupply);
    assert(rescueIndex == 0);
  }

   
  function rescueCat(bytes32 seed) activeMode returns (bytes5) {
    require(remainingCats > 0);  
    bytes32 catIdHash = keccak256(seed, searchSeed);  
    require(catIdHash[0] | catIdHash[1] | catIdHash[2] == 0x0);  
    bytes5 catId = bytes5((catIdHash & 0xffffffff) << 216);  
    require(catOwners[catId] == 0x0);  

    rescueOrder[rescueIndex] = catId;
    rescueIndex++;

    catOwners[catId] = msg.sender;
    balanceOf[msg.sender]++;
    remainingCats--;

    CatRescued(msg.sender, catId);

    return catId;
  }

   
  function nameCat(bytes5 catId, bytes32 catName) onlyCatOwner(catId) {
    require(catNames[catId] == 0x0);  
    require(!adoptionOffers[catId].exists);  
    catNames[catId] = catName;
    CatNamed(catId, catName);
  }

   
  function makeAdoptionOffer(bytes5 catId, uint price) onlyCatOwner(catId) {
    require(price > 0);
    adoptionOffers[catId] = AdoptionOffer(true, catId, msg.sender, price, 0x0);
    AdoptionOffered(catId, price, 0x0);
  }

   
  function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) onlyCatOwner(catId) isNotSender(to){
    adoptionOffers[catId] = AdoptionOffer(true, catId, msg.sender, price, to);
    AdoptionOffered(catId, price, to);
  }

   
  function cancelAdoptionOffer(bytes5 catId) onlyCatOwner(catId) {
    adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0);
    AdoptionOfferCancelled(catId);
  }

   
  function acceptAdoptionOffer(bytes5 catId) payable {
    AdoptionOffer storage offer = adoptionOffers[catId];
    require(offer.exists);
    require(offer.onlyOfferTo == 0x0 || offer.onlyOfferTo == msg.sender);
    require(msg.value >= offer.price);
    if(msg.value > offer.price) {
      pendingWithdrawals[msg.sender] += (msg.value - offer.price);  
    }
    transferCat(catId, catOwners[catId], msg.sender, offer.price);
  }

   
  function giveCat(bytes5 catId, address to) onlyCatOwner(catId) {
    transferCat(catId, msg.sender, to, 0);
  }

   
  function makeAdoptionRequest(bytes5 catId) payable isNotSender(catOwners[catId]) {
    require(catOwners[catId] != 0x0);  
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(msg.value > 0);
    require(msg.value > existingRequest.price);


    if(existingRequest.price > 0) {
      pendingWithdrawals[existingRequest.requester] += existingRequest.price;
    }

    adoptionRequests[catId] = AdoptionRequest(true, catId, msg.sender, msg.value);
    AdoptionRequested(catId, msg.value, msg.sender);

  }

   
  function acceptAdoptionRequest(bytes5 catId) onlyCatOwner(catId) {
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(existingRequest.exists);
    address existingRequester = existingRequest.requester;
    uint existingPrice = existingRequest.price;
    adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);  
    transferCat(catId, msg.sender, existingRequester, existingPrice);
  }

   
  function cancelAdoptionRequest(bytes5 catId) {
    AdoptionRequest storage existingRequest = adoptionRequests[catId];
    require(existingRequest.exists);
    require(existingRequest.requester == msg.sender);

    uint price = existingRequest.price;

    adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);

    msg.sender.transfer(price);

    AdoptionRequestCancelled(catId);
  }


  function withdraw() {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

   

   
  function disableBeforeActivation() onlyOwner inactiveMode {
    mode = Modes.Disabled;   
  }

   
  function activate() onlyOwner inactiveMode {
    searchSeed = block.blockhash(block.number - 1);  
    mode = Modes.Live;  
  }

   
  function activateInTestMode() onlyOwner inactiveMode {  
    searchSeed = 0x5713bdf5d1c3398a8f12f881f0f03b5025b6f9c17a97441a694d5752beb92a3d;  
    mode = Modes.Test;  
  }

   
  function addGenesisCatGroup() onlyOwner activeMode {
    require(remainingGenesisCats > 0);
    bytes5[16] memory newCatIds;
    uint256 price = (17 - (remainingGenesisCats / 16)) * 300000000000000000;
    for(uint8 i = 0; i < 16; i++) {

      uint16 genesisCatIndex = 256 - remainingGenesisCats;
      bytes5 genesisCatId = (bytes5(genesisCatIndex) << 24) | 0xff00000ca7;

      newCatIds[i] = genesisCatId;

      rescueOrder[rescueIndex] = genesisCatId;
      rescueIndex++;
      balanceOf[0x0]++;
      remainingGenesisCats--;

      adoptionOffers[genesisCatId] = AdoptionOffer(true, genesisCatId, owner, price, 0x0);
    }
    GenesisCatsAdded(newCatIds);
  }


   

  function getCatIds() constant returns (bytes5[]) {
    bytes5[] memory catIds = new bytes5[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      catIds[i] = rescueOrder[i];
    }
    return catIds;
  }


  function getCatNames() constant returns (bytes32[]) {
    bytes32[] memory names = new bytes32[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      names[i] = catNames[rescueOrder[i]];
    }
    return names;
  }

  function getCatOwners() constant returns (address[]) {
    address[] memory owners = new address[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      owners[i] = catOwners[rescueOrder[i]];
    }
    return owners;
  }

  function getCatOfferPrices() constant returns (uint[]) {
    uint[] memory catOffers = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 catId = rescueOrder[i];
      if(adoptionOffers[catId].exists && adoptionOffers[catId].onlyOfferTo == 0x0) {
        catOffers[i] = adoptionOffers[catId].price;
      }
    }
    return catOffers;
  }

  function getCatRequestPrices() constant returns (uint[]) {
    uint[] memory catRequests = new uint[](rescueIndex);
    for (uint i = 0; i < rescueIndex; i++) {
      bytes5 catId = rescueOrder[i];
      catRequests[i] = adoptionRequests[catId].price;
    }
    return catRequests;
  }

  function getCatDetails(bytes5 catId) constant returns (bytes5 id,
                                                         address owner,
                                                         bytes32 name,
                                                         address onlyOfferTo,
                                                         uint offerPrice,
                                                         address requester,
                                                         uint requestPrice) {

    return (catId,
            catOwners[catId],
            catNames[catId],
            adoptionOffers[catId].onlyOfferTo,
            adoptionOffers[catId].price,
            adoptionRequests[catId].requester,
            adoptionRequests[catId].price);
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier inactiveMode() {
    require(mode == Modes.Inactive);
    _;
  }

  modifier activeMode() {
    require(mode == Modes.Live || mode == Modes.Test);
    _;
  }

  modifier onlyCatOwner(bytes5 catId) {
    require(catOwners[catId] == msg.sender);
    _;
  }

  modifier isNotSender(address a) {
    require(msg.sender != a);
    _;
  }

   
  function transferCat(bytes5 catId, address from, address to, uint price) private {
    catOwners[catId] = to;
    balanceOf[from]--;
    balanceOf[to]++;
    adoptionOffers[catId] = AdoptionOffer(false, catId, 0x0, 0, 0x0);  

    AdoptionRequest storage request = adoptionRequests[catId];  
    if(request.requester == to) {
      pendingWithdrawals[to] += request.price;
      adoptionRequests[catId] = AdoptionRequest(false, catId, 0x0, 0);
    }

    pendingWithdrawals[from] += price;

    Transfer(from, to, 1);
    CatAdopted(catId, price, from, to);
  }

}