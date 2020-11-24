 

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

contract MobSquads is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "MobSquads";  
  string public constant SYMBOL = "MOBS";  

  uint256 public precision = 1000000000000;  

  uint256 public hitPrice =  0.005 ether;

   

   
   
  mapping (uint256 => address) public mobsterIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public mobsterIndexToApproved;

   
  mapping (uint256 => uint256) private mobsterIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

   
  uint256 public minimumTokensBeforeSale = 13;

   
  struct Mobster {
    uint256 id;  
    string name;
    uint256 boss;  
    uint256 state;  
    uint256 dazedExipryTime;  
    uint256 buyPrice;  
  }

  Mobster[] private mobsters;
  uint256 public leadingGang;
  uint256 public leadingHitCount;
  uint256[] public gangHits;   
  uint256 public currentHitTotal;
  uint256 public lethalBonusAtHits = 200;


   
  mapping (uint256 => uint256) private bossIndexToGang;

  mapping (address => uint256) public mobsterBalances;


   
   
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

   
  function MobSquads() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    leadingHitCount = 0;
     gangHits.length++;
   
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    mobsterIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createMobster(string _name, uint256 _startPrice, uint256 _boss) public onlyCLevel {
    _createMobster(_name, address(this), _startPrice,_boss);
  }

   
   
  function getMobster(uint256 _tokenId) public view returns (
    uint256 id,
    string name,
    uint256 boss,
    uint256 sellingPrice,
    address owner,
    uint256 state,
    uint256 dazedExipryTime,
    uint256 buyPrice,
    uint256 nextPrice
  ) {
    id = _tokenId;
    Mobster storage mobster = mobsters[_tokenId];
    name = mobster.name;
    boss = mobster.boss;
    sellingPrice =mobsterIndexToPrice[_tokenId];
    owner = mobsterIndexToOwner[_tokenId];
    state = mobster.state;
    if (mobster.state==1 && now>mobster.dazedExipryTime){
        state=0;  
    }
    dazedExipryTime=mobster.dazedExipryTime;
    buyPrice=mobster.buyPrice;
    nextPrice=calculateNewPrice(_tokenId);
  }


  function setLethalBonusAtHits (uint256 _count) public onlyCLevel {
        lethalBonusAtHits = _count;
    }

    function setHitPrice (uint256 _price) public onlyCLevel {
          hitPrice = _price;
      }

   
  function hitMobster(uint256 _victim  , uint256 _hitter) public payable returns (bool){
    address mobsterOwner = mobsterIndexToOwner[_victim];
    require(msg.sender != mobsterOwner);  
    require(msg.sender==mobsterIndexToOwner[_hitter]);  

     
    if (msg.value>=hitPrice && _victim!=0 && _hitter!=0){
         
        mobsters[_victim].state=1;
        mobsters[_victim].dazedExipryTime = now + (2 * 1 minutes);

        uint256 gangNumber=SafeMath.div(mobsters[_hitter].boss,6)+1;

        gangHits[gangNumber]++;  
        currentHitTotal++;

        if  (gangHits[gangNumber]>leadingHitCount){
            leadingHitCount=gangHits[gangNumber];
            leadingGang=gangNumber;
        }

       
     if (currentHitTotal==lethalBonusAtHits){
       uint256 lethalBonus = SafeMath.mul(SafeMath.div(currentHitTotal * hitPrice,100),15);  

          
         uint256 winningMobsterIndex  = (6*(leadingGang-1))+1;  
         for (uint256 x = winningMobsterIndex;x<6+winningMobsterIndex;x++){
             if(mobsterIndexToOwner[x]!=0 && mobsterIndexToOwner[x]!=address(this)){
                         mobsterBalances[ mobsterIndexToOwner[x]]+=lethalBonus;  
              }
         }  

         currentHitTotal=0;  

          
         for (uint256 y = 0 ; y<gangHits.length;y++){
           gangHits[y]=0;
           leadingHitCount=0;
           leadingGang=0;
         }

     }  


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
    owner = mobsterIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }



   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = mobsterIndexToOwner[_tokenId];

    uint256 sellingPrice = mobsterIndexToPrice[_tokenId];
     
    require(totalSupply()>=minimumTokensBeforeSale);

     
    require(oldOwner != msg.sender);

     
    require(_addressNotNull(msg.sender));

     
    require(msg.value >= sellingPrice);

 
 
 
    uint256 contractFee = roundIt(uint256(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice,1000),35)));  

      
    if (_tokenId==0){
        uint256 poolPayment = roundIt(uint256(SafeMath.div(contractFee,5)));  
         

         
         
        uint256 winningMobsterIndex  = (6*(leadingGang-1))+2;  
        for (uint256 x = winningMobsterIndex;x<5+winningMobsterIndex;x++){
            if(mobsterIndexToOwner[x]!=0 &&  mobsterIndexToOwner[x]!=address(this)){
                        mobsterBalances[ mobsterIndexToOwner[x]]+=poolPayment;  
             }
        }

         
        for (uint256 y = 0 ; y<gangHits.length;y++){
          gangHits[y]=0;
          leadingHitCount=0;
          leadingGang=0;
        }

    }


     
    uint256 godFatherFee = 0;
    if (_tokenId!=0){
        godFatherFee = contractFee;  
    }
     
    uint256 bossFee = 0;
    if (mobsters[_tokenId].boss!=_tokenId && _tokenId!=0){
        bossFee =  roundIt(uint256(SafeMath.div(mobsters[_tokenId].buyPrice,20)));  
    }
     
    if (godFatherFee>0 && mobsterIndexToOwner[0]!=address(this)){
        mobsterIndexToOwner[0].transfer(godFatherFee);
    }

      
    if (_tokenId!=0 && bossFee>0 && mobsterIndexToOwner[mobsters[_tokenId].boss]!=address(this)){
        mobsterIndexToOwner[mobsters[_tokenId].boss].transfer(bossFee);
    }

     uint256 previousOwnerPayout = roundIt(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice, 100), 110));  

     mobsterIndexToPrice[_tokenId]  = calculateNewPrice(_tokenId);
     mobsters[_tokenId].state=0;
     mobsters[_tokenId].buyPrice=sellingPrice;

    _transfer(oldOwner, msg.sender, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(previousOwnerPayout);  
    }

    TokenSold(_tokenId, sellingPrice, mobsterIndexToPrice[_tokenId], oldOwner, msg.sender);

    if(SafeMath.sub(msg.value, sellingPrice)>0){
             msg.sender.transfer(SafeMath.sub(msg.value, sellingPrice));  
    }

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return mobsterIndexToPrice[_tokenId];
  }

  function nextPrice(uint256 _tokenId) public view returns (uint256 nPrice) {
    return calculateNewPrice(_tokenId);
  }


    function claimMobsterFunds() public {
      if (mobsterBalances[msg.sender]==0) revert();
      uint256 amount = mobsterBalances[msg.sender];
      if (amount>0){
        mobsterBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
      }
    }


 function calculateNewPrice(uint256 _tokenId) internal view returns (uint256 price){
   uint256 sellingPrice = mobsterIndexToPrice[_tokenId];
   uint256 newPrice;

    
    
   if (_tokenId==0){
         newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 117), 100));
   }
    
     
  if (mobsters[_tokenId].boss==_tokenId && _tokenId!=0){
        newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 117), 100));
   }
    
    
  if (mobsters[_tokenId].boss!=_tokenId){
        newPrice= roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 122), 100));
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
    address oldOwner = mobsterIndexToOwner[_tokenId];

     
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
      uint256 totalmobsters = totalSupply();
      uint256 resultIndex = 0;

      uint256 mobsterId;
      for (mobsterId = 0; mobsterId <= totalmobsters; mobsterId++) {
        if (mobsterIndexToOwner[mobsterId] == _owner) {
          result[resultIndex] = mobsterId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return mobsters.length;
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
    return mobsterIndexToApproved[_tokenId] == _to;
  }


   
  function _createMobster(string _name, address _owner, uint256 _price, uint256 _boss) private {

    Mobster memory _mobster = Mobster({
      name: _name,
      boss: _boss,
      state: 0,
      dazedExipryTime: 0,
      buyPrice: _price,
      id: mobsters.length-1
    });
    uint256 newMobsterId = mobsters.push(_mobster) - 1;
    mobsters[newMobsterId].id=newMobsterId;


    if (newMobsterId % 6 ==0 || newMobsterId==1)
    {
        gangHits.length++;
    }

     
     
    require(newMobsterId == uint256(uint32(newMobsterId)));

    Birth(newMobsterId, _name, _owner);

    mobsterIndexToPrice[newMobsterId] = _price;

     
     
    _transfer(address(0), _owner, newMobsterId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == mobsterIndexToOwner[_tokenId];
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
     
    mobsterIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete mobsterIndexToApproved[_tokenId];
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