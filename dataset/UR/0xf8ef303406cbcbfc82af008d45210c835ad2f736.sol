 

pragma solidity ^0.4.19;  

 


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

contract EtherVillains is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "EtherVillains";  
  string public constant SYMBOL = "EVIL";  

  uint256 public precision = 1000000000000;  

  uint256 private zapPrice =  0.001 ether;
  uint256 private pinchPrice =  0.002 ether;
  uint256 private guardPrice =  0.002 ether;

  uint256 private pinchPercentageReturn = 20;  

  uint256 private defaultStartingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

   

   
   
  mapping (uint256 => address) public villainIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public villainIndexToApproved;

   
  mapping (uint256 => uint256) private villainIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;


   
  struct Villain {
    uint256 id;  
    string name;
    uint256 class;  
    uint256 level;  
    uint256 numSkillActive;  
    uint256 state;  
    uint256 zappedExipryTime;  
    uint256 affectedByToken;  
    uint256 buyPrice;  
  }

  Villain[] private villains;

   
   
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

   
  function EtherVillains() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    villainIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createVillain(string _name, uint256 _startPrice, uint256 _class, uint256 _level) public onlyCLevel {
    _createVillain(_name, address(this), _startPrice,_class,_level);
  }

   
   
  function getVillain(uint256 _tokenId) public view returns (
    uint256 id,
    string villainName,
    uint256 sellingPrice,
    address owner,
    uint256 class,
    uint256 level,
    uint256 numSkillActive,
    uint256 state,
    uint256 zappedExipryTime,
    uint256 buyPrice,
    uint256 nextPrice,
    uint256 affectedByToken
  ) {
    id = _tokenId;
    Villain storage villain = villains[_tokenId];
    villainName = villain.name;
    sellingPrice =villainIndexToPrice[_tokenId];
    owner = villainIndexToOwner[_tokenId];
    class = villain.class;
    level = villain.level;
    numSkillActive = villain.numSkillActive;
    state = villain.state;
    if (villain.state==1 && now>villain.zappedExipryTime){
        state=0;  
    }
    zappedExipryTime=villain.zappedExipryTime;
    buyPrice=villain.buyPrice;
    nextPrice=calculateNewPrice(_tokenId);
    affectedByToken=villain.affectedByToken;
  }

   
  function zapVillain(uint256 _victim  , uint256 _zapper) public payable returns (bool){
    address villanOwner = villainIndexToOwner[_victim];
    require(msg.sender != villanOwner);  
    require(villains[_zapper].class==0);  
    require(msg.sender==villainIndexToOwner[_zapper]);  

    uint256 operationPrice = zapPrice;
     
    if (villainIndexToPrice[_victim]<0.01 ether){
      operationPrice=0;
    }

     
    if (msg.value>=operationPrice && villains[_victim].state<2){
         
        villains[_victim].state=1;
        villains[_victim].zappedExipryTime = now + (villains[_zapper].level * 1 minutes);
    }

  }

     
  function pinchVillain(uint256 _victim, uint256 _pincher) public payable returns (bool){
    address victimOwner = villainIndexToOwner[_victim];
    require(msg.sender != victimOwner);  
    require(msg.sender==villainIndexToOwner[_pincher]);
    require(villains[_pincher].class==1);  
    require(villains[_pincher].numSkillActive<villains[_pincher].level);

    uint256 operationPrice = pinchPrice;
     
    if (villainIndexToPrice[_victim]<0.01 ether){
      operationPrice=0;
    }

     
     
    if (msg.value>=operationPrice && villains[_victim].state==1 && now< villains[_victim].zappedExipryTime){
         
        villains[_victim].state=2;  
        villains[_victim].affectedByToken=_pincher;
        villains[_pincher].numSkillActive++;
    }
  }

   
  function guardVillain(uint256 _target, uint256 _guard) public payable returns (bool){
    require(msg.sender==villainIndexToOwner[_guard]);  
    require(villains[_guard].numSkillActive<villains[_guard].level);

    uint256 operationPrice = guardPrice;
     
    if (villainIndexToPrice[_target]<0.01 ether){
      operationPrice=0;
    }

     
    if (msg.value>=operationPrice && villains[_target].state<2){
         
        villains[_target].state=3;
        villains[_target].affectedByToken=_guard;
        villains[_guard].numSkillActive++;
    }
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
    owner = villainIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }




   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = villainIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = villainIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = roundIt(uint256(SafeMath.div(SafeMath.mul(sellingPrice, 93), 100)));  
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);


     

    villainIndexToPrice[_tokenId]  = calculateNewPrice(_tokenId);


      
      
     if (villains[_tokenId].state==2 && villains[_tokenId].affectedByToken!=0){
         uint256 profit = sellingPrice - villains[_tokenId].buyPrice;
         uint256 pinchPayment = roundIt(SafeMath.mul(SafeMath.div(profit,100),pinchPercentageReturn));

          
         address pincherTokenOwner = villainIndexToOwner[villains[_tokenId].affectedByToken];
         pincherTokenOwner.transfer(pinchPayment);
         payment = SafeMath.sub(payment,pinchPayment);  
     }

      
     if (villains[villains[_tokenId].affectedByToken].numSkillActive>0){
        villains[villains[_tokenId].affectedByToken].numSkillActive--;  
     }

     villains[_tokenId].state=0;
     villains[_tokenId].affectedByToken=0;
     villains[_tokenId].buyPrice=sellingPrice;

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, villainIndexToPrice[_tokenId], oldOwner, newOwner, villains[_tokenId].name);

    msg.sender.transfer(purchaseExcess);  
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return villainIndexToPrice[_tokenId];
  }

  function nextPrice(uint256 _tokenId) public view returns (uint256 nPrice) {
    return calculateNewPrice(_tokenId);
  }


 


 function calculateNewPrice(uint256 _tokenId) internal view returns (uint256 price){
   uint256 sellingPrice = villainIndexToPrice[_tokenId];
   uint256 newPrice;
    
   if (sellingPrice < firstStepLimit) {
      
    newPrice = roundIt(SafeMath.mul(sellingPrice, 2));
   } else if (sellingPrice < secondStepLimit) {
      
     newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 120), 100));
   } else {
      
     newPrice= roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 115), 100));
   }
   return newPrice;

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
    address oldOwner = villainIndexToOwner[_tokenId];

     
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
      uint256 totalVillains = totalSupply();
      uint256 resultIndex = 0;

      uint256 villainId;
      for (villainId = 0; villainId <= totalVillains; villainId++) {
        if (villainIndexToOwner[villainId] == _owner) {
          result[resultIndex] = villainId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return villains.length;
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
    return villainIndexToApproved[_tokenId] == _to;
  }



   
  function _createVillain(string _name, address _owner, uint256 _price, uint256 _class, uint256 _level) private {

    Villain memory _villain = Villain({
      name: _name,
      class: _class,
      level: _level,
      numSkillActive: 0,
      state: 0,
      zappedExipryTime: 0,
      affectedByToken: 0,
      buyPrice: 0,
      id: villains.length-1
    });
    uint256 newVillainId = villains.push(_villain) - 1;
    villains[newVillainId].id=newVillainId;

     
     
    require(newVillainId == uint256(uint32(newVillainId)));

    Birth(newVillainId, _name, _owner);

    villainIndexToPrice[newVillainId] = _price;

     
     
    _transfer(address(0), _owner, newVillainId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == villainIndexToOwner[_tokenId];
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
     
    villainIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete villainIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }

     
    function roundIt(uint256 amount) internal constant returns (uint256)
    {
         
        uint256 result = (amount/precision)*precision;
        return result;
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