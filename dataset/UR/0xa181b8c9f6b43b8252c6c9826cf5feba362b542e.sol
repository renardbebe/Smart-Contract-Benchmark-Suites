 

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
  event Dissolved(address  owner, uint256 tokenId);
  event TransferDissolved(address indexed from, address indexed to, uint256 tokenId);
  
}


contract CryptoStamps is ERC721 {

  
   

  
   
  event stampBirth(uint256 tokenId,  address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

   
   
  event Transfer(address from, address to, uint256 tokenId);



  
   


   
  string public constant NAME = "CryptoStamps";  
  string public constant SYMBOL = "CS";  
  
   
  uint256 private firstStepLimit =  1.28 ether;
  


  
  
   



   
   
  mapping (uint256 => address) public stampIndexToOwner;
  

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public stampIndexToApproved;

   
  mapping (uint256 => uint256) private stampIndexToPrice;
  
  
  
   
  mapping(uint256 => uint256) public stampIndextotransactions;
  
   
  uint256 public totaletherstransacted;

   
  uint256 public totaltransactions;
  
   
  uint256 public stampCreatedCount;
  
  
  

  
 
 
  
   
  mapping (uint256 => bool) public stampIndextodissolved;
 
 
  
   
 mapping (uint256 => address) public dissolvedIndexToApproved;
 
  
  
  
   
  
  struct Stamp {
    uint256 birthtime;
  }
  
  

  Stamp[] private stamps;

 
 
 
 
  
  
  
   
  
   
  
  
   
  address public ceoAddress;
  address public cooAddress;
  bool private paused;
  
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

  
   
   
  
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

 
 
   
   
  
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }
  
  
  
   
  function CryptoStamps() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    paused = false;
  }

  
  
  
  
   
   
  
   
  
   
  
  
   
  function pausecontract() public onlyCLevel
  {
      paused = true;
  }
  
  
  
  function unpausecontract() public onlyCEO
  {
      paused = false;
      
  }
  
  
  
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(paused == false);
    require(_owns(msg.sender, _tokenId));

    stampIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  
  
   
   
   
  
  
  
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  
  
   
  function createStamp(address _owner,  uint256 _price) public onlyCOO {
    
    require(paused == false);
    address stampOwner = _owner;
    if (stampOwner == address(0)) {
      stampOwner = cooAddress;
    }

    require(_price >= 0);

    stampCreatedCount++;
    _createStamp( stampOwner, _price);
  }

  
 
   
  
  function getStamp(uint256 _tokenId) public view returns (
    uint256 birthtimestamp,
    uint256 sellingPrice,
    address owner
  ) {
    Stamp storage stamp = stamps[_tokenId];
    birthtimestamp = stamp.birthtime;
    sellingPrice = stampIndexToPrice[_tokenId];
    owner = stampIndexToOwner[_tokenId];
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
    owner = stampIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  
  
   
  
  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }
  
  
  
  
  
  
   
  uint256 private cut;
  
  
  
  
  function setcut(uint256 cutowner) onlyCEO public returns(uint256)
  { 
      cut = cutowner;
      return(cut);
      
  }

  
  
  
  
   
  
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = stampIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    require(stampIndextodissolved[_tokenId] == false);
    require(paused == false);
    uint256 sellingPrice = stampIndexToPrice[_tokenId];
    totaletherstransacted = totaletherstransacted + sellingPrice;

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, cut), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      stampIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), cut);
    } 
    else {
      
      stampIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), cut);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, stampIndexToPrice[_tokenId], oldOwner, newOwner);

    msg.sender.transfer(purchaseExcess);
  }

  
  
  
   
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return stampIndexToPrice[_tokenId];
  }

  
  
   
  function nextpriceOf(uint256 _tokenId) public view returns (uint256 price) {
    uint256 currentsellingPrice = stampIndexToPrice[_tokenId];
    
    if (currentsellingPrice < firstStepLimit) {
       
      return SafeMath.div(SafeMath.mul(currentsellingPrice, 200), cut);
    } 
    else {
      
      return SafeMath.div(SafeMath.mul(currentsellingPrice, 125), cut);
    }
    
  }

  
  
  
  
  
   
  
  
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  
   
   
   
  
  
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = stampIndexToOwner[_tokenId];
    require(paused == false);
     
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
      uint256 totalStamps = totalSupply();
      uint256 resultIndex = 0;

      uint256 stampId;
      for (stampId = 0; stampId <= totalStamps; stampId++) {
        if (stampIndexToOwner[stampId] == _owner) {
          result[resultIndex] = stampId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  
  
   
   
  
  
  
  function totalSupply() public view returns (uint256 total) {
    return stamps.length;
  }

   
   
   
   
  
  
  
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));
    require(paused == false);

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
  
  
   
  uint256 private num;
  
  
  
  function setnumber(uint256 number) onlyCEO public returns(uint256)
  {
      num = number;
      return num;
  }
  
  
   
   uint256 private priceatdissolution;
  
  
  
  function setdissolveprice(uint256 number) onlyCEO public returns(uint256)
  {
      priceatdissolution = number;
      return priceatdissolution;
  }
  
  
   
  address private addressatdissolution;
  
  
  
  function setdissolveaddress(address dissolveaddress) onlyCEO public returns(address)
  {
      addressatdissolution = dissolveaddress;
      return addressatdissolution;
  }
  
  
   
  function controlstampdissolution(bool control,uint256 _tokenId) onlyCEO public
  {
      stampIndextodissolved[_tokenId] = control;
      
  }
  
  
   
  function dissolve(uint256 _tokenId) public
  {   require(paused == false);
      require(stampIndexToOwner[_tokenId] == msg.sender);
      require(priceOf(_tokenId)>= priceatdissolution );
      require(stampIndextodissolved[_tokenId] == false);
      address reciever = stampIndexToOwner[_tokenId];
      
      uint256 price = priceOf(_tokenId);
      uint256 newprice = SafeMath.div(price,num);
      
      approve(addressatdissolution, _tokenId);
      transfer(addressatdissolution,_tokenId);
      stampIndextodissolved[_tokenId] = true;
      
      uint256 i;
      for(i = 0; i<num; i++)
      {
      _createStamp( reciever, newprice);
          
      }
      Dissolved(msg.sender,_tokenId);
    
  }
  
  
 address private dissolvedcontract; 
 
 
 
 
  
 
 
 function setdissolvedcontract(address dissolvedaddress) onlyCEO public returns(address)
 {
     
     dissolvedcontract = dissolvedaddress;
     return dissolvedcontract;
 }
 
  
 function transferdissolvedFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_addressNotNull(_to));
    require(msg.sender == dissolvedcontract);

    _transferdissolved(_from, _to, _tokenId);
  }
  
  


  
  
  
  
  
   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  
  
   
  
  
  
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return stampIndexToApproved[_tokenId] == _to;
  }

  
   
  
  
  function _createStamp(address _owner, uint256 _price) private {
    Stamp memory _stamp = Stamp({
      birthtime: now
    });
    uint256 newStampId = stamps.push(_stamp) - 1;

     
     
    require(newStampId == uint256(uint32(newStampId)));

    stampBirth(newStampId, _owner);

    stampIndexToPrice[newStampId] = _price;

     
     
    _transfer(address(0), _owner, newStampId);
  }

  
  
   
  
  
  
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == stampIndexToOwner[_tokenId];
  }

  
  
   
  
  
  
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  
  
  
   
  
  
  
  function _transfer(address _from, address _to, uint256 _tokenId) private {
   
    require(paused == false);
    ownershipTokenCount[_to]++;
    stampIndextotransactions[_tokenId] = stampIndextotransactions[_tokenId] + 1;
    totaltransactions++;
     
    stampIndexToOwner[_tokenId] = _to;
    

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete stampIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
  
  
  
   
  
  
  
   
  function _transferdissolved(address _from, address _to, uint256 _tokenId) private {
    
    require(stampIndextodissolved[_tokenId] == true);
    require(paused == false);
    ownershipTokenCount[_to]++;
    stampIndextotransactions[_tokenId] = stampIndextotransactions[_tokenId] + 1;
     
    stampIndexToOwner[_tokenId] = _to;
    totaltransactions++;
    

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      
    }

     
    TransferDissolved(_from, _to, _tokenId);
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