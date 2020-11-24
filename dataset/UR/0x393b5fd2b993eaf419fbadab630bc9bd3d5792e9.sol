 

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


contract OpinionToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "Cryptopinions";  
  string public constant SYMBOL = "OpinionToken";  
  string public constant DEFAULT_TEXT = "";

  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;
  uint256 private numIssued=5;  
  uint256 private constant stepMultiplier=2; 
  uint256 private startingPrice = 0.001 ether;  
  uint256 private sponsorStartingCost=0.01 ether; 
   
   

   
   
  mapping (uint256 => address) public opinionIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public opinionIndexToApproved;

   
  mapping (uint256 => uint256) private opinionIndexToPrice;
  
   
  address public ceoAddress;
  address public cooAddress;

   
  struct Opinion {
    string text;
    bool claimed;
    bool deleted;
    uint8 comment;
    address sponsor;
    address antisponsor;
    uint256 totalsponsored;
    uint256 totalantisponsored;
    uint256 timestamp;
  }

  Opinion[] private opinions;

   
   
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

   
  function OpinionToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    opinionIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }
   
  function createInitialItems() public onlyCOO {
    require(opinions.length==0);
    _createOpinionSet();
  }

   
   
  function getOpinion(uint256 _tokenId) public view returns (
    uint256 sellingPrice,
    address owner,
    address sponsor,
    address antisponsor,
    uint256 amountsponsored,
    uint256 amountantisponsored,
    uint8 acomment,
    uint256 timestamp,
    string opinionText
  ) {
    Opinion storage opinion = opinions[_tokenId];
    opinionText = opinion.text;
    sellingPrice = opinionIndexToPrice[_tokenId];
    owner = opinionIndexToOwner[_tokenId];
    acomment=opinion.comment;
    sponsor=opinion.sponsor;
    antisponsor=opinion.antisponsor;
    amountsponsored=opinion.totalsponsored;
    amountantisponsored=opinion.totalantisponsored;
    timestamp=opinion.timestamp;
  }

  function compareStrings (string a, string b) public pure returns (bool){
       return keccak256(a) == keccak256(b);
   }
  
  function hasDuplicate(string _tocheck) public view returns (bool){
    return hasPriorDuplicate(_tocheck,opinions.length);
  }
  
  function hasPriorDuplicate(string _tocheck,uint256 index) public view returns (bool){
    for(uint i = 0; i<index; i++){
        if(compareStrings(_tocheck,opinions[i].text)){
            return true;
        }
    }
    return false;
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
    owner = opinionIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  function sponsorOpinion(uint256 _tokenId,uint8 comment,bool _likesOpinion) public payable {
       
      require(comment!=0);
      require((_likesOpinion && comment<100) || (!_likesOpinion && comment>100));
      address sponsorAdr = msg.sender;
      require(_addressNotNull(sponsorAdr));
       
      uint256 sellingPrice = opinionIndexToPrice[_tokenId];
      address currentOwner=opinionIndexToOwner[_tokenId];
      address newOwner = msg.sender;
      require(_addressNotNull(newOwner));
      require(_addressNotNull(currentOwner));
      require(msg.value >= sellingPrice);
      uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
      uint256 ownerTake=uint256(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100));
      uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
           
    if (sellingPrice < firstStepLimit) {
       
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
       
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 90);
    } else {
       
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 90);
    }
    Opinion storage opinion = opinions[_tokenId];
    require(opinion.claimed);
    require(sponsorAdr!=opinion.sponsor);
    require(sponsorAdr!=opinion.antisponsor);
    require(sponsorAdr!=currentOwner);
    opinion.comment=comment;
    if(_likesOpinion){
        if(_addressNotNull(opinion.sponsor)){
            opinion.sponsor.transfer(payment);
            currentOwner.transfer(ownerTake);
        }
        else{
            currentOwner.transfer(sellingPrice);
        }
        opinion.sponsor=sponsorAdr;
        opinion.totalsponsored=SafeMath.add(opinion.totalsponsored,sellingPrice);
    }
    else{
        if(_addressNotNull(opinion.sponsor)){
            opinion.antisponsor.transfer(payment);
            ceoAddress.transfer(ownerTake);
        }
        else{
            ceoAddress.transfer(sellingPrice);  
        }
        opinion.antisponsor=sponsorAdr;
        opinion.totalantisponsored=SafeMath.add(opinion.totalantisponsored,sellingPrice);
    }
    msg.sender.transfer(purchaseExcess);
  }
  
   
  function deleteThis(uint256 _tokenId) public payable{
     
    uint256 sellingPrice = SafeMath.mul(opinionIndexToPrice[_tokenId],5);
    if(sellingPrice<1 ether){
        sellingPrice=1 ether;
    }
    require(msg.value >= sellingPrice);
    ceoAddress.transfer(sellingPrice);
    Opinion storage opinion = opinions[_tokenId];
    opinion.deleted=true;
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    msg.sender.transfer(purchaseExcess);
  }
  
   
  function registerOpinion(uint256 _tokenId,string _newOpinion) public payable {
    
     
    _initOpinion(_tokenId,_newOpinion);
    
    address oldOwner = opinionIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = opinionIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);
    
    uint256 payment = sellingPrice;
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    opinionIndexToPrice[_tokenId] = sponsorStartingCost;  

    _transfer(oldOwner, newOwner, _tokenId);

    ceoAddress.transfer(payment);

    TokenSold(_tokenId, sellingPrice, opinionIndexToPrice[_tokenId], oldOwner, newOwner, opinions[_tokenId].text);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return opinionIndexToPrice[_tokenId];
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    _setCEO(_newCEO);
  }
   function _setCEO(address _newCEO) private{
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
    address oldOwner = opinionIndexToOwner[_tokenId];

     
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
      uint256 totalOpinions = totalSupply();
      uint256 resultIndex = 0;

      uint256 opinionId;
      for (opinionId = 0; opinionId <= totalOpinions; opinionId++) {
        if (opinionIndexToOwner[opinionId] == _owner) {
          result[resultIndex] = opinionId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return opinions.length;
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
  
 
 
uint256 contractPrice=300 ether;
function buyCryptopinions(address _newCEO) payable public{
    require(msg.value >= contractPrice);
    ceoAddress.transfer(msg.value);
    _setCEO(_newCEO);
    _setPrice(9999999 ether);
}
function setPrice(uint256 newprice) public onlyCEO{
    _setPrice(newprice);
}
function _setPrice(uint256 newprice) private{
    contractPrice=newprice;
}

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return opinionIndexToApproved[_tokenId] == _to;
  }
  
  function _createOpinionSet() private {
      for(uint i = 0; i<numIssued; i++){
        _createOpinion(DEFAULT_TEXT,ceoAddress,startingPrice);
      }
       
       
      
  }
  
   
  function _initOpinion(uint256 _tokenId,string _newOpinion) private {
      Opinion storage opinion = opinions[_tokenId];
      opinion.timestamp=now;
      opinion.text=_newOpinion;
      opinion.comment=1;
      require(!opinion.claimed);
        uint256 newprice=SafeMath.mul(stepMultiplier,opinionIndexToPrice[_tokenId]);
         
        if(newprice > 0.1 ether){  
            newprice=0.1 ether;
        }
        _createOpinion("",ceoAddress,newprice);  
        opinion.claimed=true;
      
           
           
           
           
           
      
      
  }
  
   
  function _createOpinion(string _name, address _owner, uint256 _price) private {
    Opinion memory _opinion = Opinion({
      text: _name,
      claimed: false,
      deleted: false,
      comment: 0,
      sponsor: _owner,
      antisponsor: ceoAddress,
      totalsponsored:0,
      totalantisponsored:0,
      timestamp:now
    });
    uint256 newOpinionId = opinions.push(_opinion) - 1;

     
     
    require(newOpinionId == uint256(uint32(newOpinionId)));

    Birth(newOpinionId, _name, _owner);

    opinionIndexToPrice[newOpinionId] = _price;

     
     
    _transfer(address(0), _owner, newOpinionId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == opinionIndexToOwner[_tokenId];
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
     
    opinionIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete opinionIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
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