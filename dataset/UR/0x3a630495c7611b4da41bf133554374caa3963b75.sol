 

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

contract PornstarsInterface {
    function ownerOf(uint256 _id) public view returns (
        address owner
    );
    
    function totalSupply() public view returns (
        uint256 total
    );
}

contract PornSceneToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, uint[] stars, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, uint[] stars);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoPornScenes";  
  string public constant SYMBOL = "PornSceneToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 10000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public sceneIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public sceneIndexToApproved;

   
  mapping (uint256 => uint256) private sceneIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  PornstarsInterface pornstarsContract;
  uint currentAwardWinner = 85;  

  uint256 public promoCreatedCount;

   
  struct Scene {
    string name;
    uint[] stars;
  }

  Scene[] private scenes;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
  function PornSceneToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    sceneIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }
  
  function setPornstarsContractAddress(address _address) public onlyCOO {
      pornstarsContract = PornstarsInterface(_address);
  }
  
   
  function createPromoScene(address _owner, string _name, uint[] _stars, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address sceneOwner = _owner;
    if (sceneOwner == address(0)) {
      sceneOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createScene(_name, _stars, sceneOwner, _price);
  }

   
  function createContractScene(string _name, uint[] _stars) public onlyCOO {
    _createScene(_name, _stars, address(this), startingPrice);
  }

   
   
  function getScene(uint256 _tokenId) public view returns (
    string sceneName,
    uint[] stars,
    uint256 sellingPrice,
    address owner
  ) {
    Scene storage scene = scenes[_tokenId];
    sceneName = scene.name;
    stars = scene.stars;
    sellingPrice = sceneIndexToPrice[_tokenId];
    owner = sceneIndexToOwner[_tokenId];
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
    owner = sceneIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = sceneIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = sceneIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 80), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    
     
     
    Scene memory _scene = scenes[_tokenId];
    
    require(_scene.stars.length > 0);  

    uint256 holderFee = uint256(SafeMath.div(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100), _scene.stars.length));
    uint256 awardOwnerFee = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));

     
    if (sellingPrice < firstStepLimit) {
       
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 80);
    } else if (sellingPrice < secondStepLimit) {
       
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 80);
    } else {
       
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 80);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }
    
    _paySceneStarOwners(_scene, holderFee);
    _payAwardOwner(awardOwnerFee);
    
    TokenSold(_tokenId, sellingPrice, sceneIndexToPrice[_tokenId], oldOwner, newOwner, _scene.name, _scene.stars);

    msg.sender.transfer(purchaseExcess);
  }
  
  function _paySceneStarOwners(Scene _scene, uint256 fee) private {
    for (uint i = 0; i < _scene.stars.length; i++) {
        address _pornstarOwner;
        (_pornstarOwner) = pornstarsContract.ownerOf(_scene.stars[i]);
        
        if(_isGoodAddress(_pornstarOwner)) {
            _pornstarOwner.transfer(fee);
        }
    }
  }
  
  function _payAwardOwner(uint256 fee) private {
    address _awardOwner;
    (_awardOwner) = pornstarsContract.ownerOf(currentAwardWinner);
    
    if(_isGoodAddress(_awardOwner)) {
        _awardOwner.transfer(fee);
    }
  }
  
  function _isGoodAddress(address _addy) private view returns (bool) {
      if(_addy == address(pornstarsContract)) {
          return false;
      }
      
      if(_addy == address(0) || _addy == address(0x0)) {
          return false;
      }
      
      return true;
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return sceneIndexToPrice[_tokenId];
  }
  
  function starsOf(uint256 _tokenId) public view returns (uint[]) {
      return scenes[_tokenId].stars;
  }
  
   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = sceneIndexToOwner[_tokenId];

     
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
      uint256 totalscenes = totalSupply();
      uint256 resultIndex = 0;

      uint256 sceneId;
      for (sceneId = 0; sceneId <= totalscenes; sceneId++) {
        if (sceneIndexToOwner[sceneId] == _owner) {
          result[resultIndex] = sceneId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return scenes.length;
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
    return sceneIndexToApproved[_tokenId] == _to;
  }

   
  function _createScene(string _name, uint[] _stars,address _owner, uint256 _price) private {
     
    require(_stars.length > 0);
    
    for (uint i = 0; i < _stars.length; i++) {
        address _pornstarOwner;
        (_pornstarOwner) = pornstarsContract.ownerOf(_stars[i]);
        require(_pornstarOwner != address(0) || _pornstarOwner != address(0x0));
    }
      
    Scene memory _scene = Scene({
      name: _name,
      stars: _stars
    });
    uint256 newSceneId = scenes.push(_scene) - 1;

     
     
    require(newSceneId == uint256(uint32(newSceneId)));

    Birth(newSceneId, _name, _stars, _owner);

    sceneIndexToPrice[newSceneId] = _price;

     
     
    _transfer(address(0), _owner, newSceneId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == sceneIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    sceneIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete sceneIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
}

contract CryptoPornstarAward is PornSceneToken{
    event Award(uint256 currentAwardWinner, uint32 awardTime);
    
    uint nonce = 0;
    uint cooldownTime = 60;
    uint32 awardTime = uint32(now);
    
    function _triggerCooldown() internal {
        awardTime = uint32(now + cooldownTime);
    }
    
    function _isTime() internal view returns (bool) {
        return (awardTime <= now);
    }
    
    function rand(uint min, uint max) internal returns (uint) {
        nonce++;
        return uint(keccak256(nonce))%(min+max)-min;
    }

    function setCooldown(uint _newCooldown) public onlyCOO {
        require (_newCooldown > 0);
        cooldownTime = _newCooldown;
        _triggerCooldown();
    } 
    
    function getAwardTime () public view returns (uint32) {
        return awardTime;
    }
    
    function getCooldown () public view returns (uint) {
        return cooldownTime;
    }
    
    function newAward() public onlyCOO {        
        uint256 _totalPornstars;
        (_totalPornstars) = pornstarsContract.totalSupply();
        
        require(_totalPornstars > 0);
        require(_isTime());
        
        currentAwardWinner = rand(0, _totalPornstars);
        _triggerCooldown();
        
        Award(currentAwardWinner, awardTime);
    }
    
    function getCurrentAward() public view returns (uint){
        return currentAwardWinner;
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