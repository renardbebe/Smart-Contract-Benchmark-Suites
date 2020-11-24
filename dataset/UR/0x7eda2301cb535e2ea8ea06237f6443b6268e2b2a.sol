 

 


pragma solidity ^0.4.25;  
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public view returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


 


contract CharToken is ERC721 {
   
   
  event Birth(uint256 tokenId, string wikiID_Name, address owner);
   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string wikiID_Name);
   
   
  event Transfer(address from, address to, uint256 tokenId);
   
   
  event ContractUpgrade(address newContract);
   
  event Bonus(address to, uint256 bonus);

   
   
  string public constant NAME = "CryptoChars";  
  string public constant SYMBOL = "CHARS";  
  bool private erc721Enabled = false;
  uint256 private startingPrice = 0.005 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.20 ether;
  uint256 private thirdStepLimit = 0.5 ether;

   
   
   
  mapping (uint256 => address) public charIndexToOwner;
  
   
  mapping (address => uint256) private ownershipTokenCount;
   
   
   
  mapping (uint256 => address) public charIndexToApproved;
   
  mapping (uint256 => uint256) private charIndexToPrice;
   
  mapping (address => uint256) private addressToTrxCount;
   
  address public ceoAddress;
  address public cooAddress;
  address public cfoAddress;
  uint256 public promoCreatedCount;
   
   
  uint256 public bonusUntilDate;   
  uint256 bonusFrequency;
   
  struct Char {
     
     
     
    string wikiID_Name;  
  }
  Char[] private chars; 

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }
   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }
   
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }
  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }
   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress ||
      msg.sender == cfoAddress 
    );
    _;
  }
   
  constructor() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    bonusUntilDate = now;  
    bonusFrequency = 3;  
    
     
    createContractChar("42268616_Captain Ahab",0);
    createContractChar("455401_Frankenstein",0);
    createContractChar("8670724_Dracula",0);
    createContractChar("27159_Sherlock Holmes",0);
    createContractChar("160108_Snow White",0);
    createContractChar("73453_Cinderella",0);
    createContractChar("14966133_Pinocchio",0);
    createContractChar("369427_Lemuel Gulliver",0);
    createContractChar("26171_Robin Hood",0);
    createContractChar("197889_Felix the Cat",0);
    createContractChar("382164_Wizard of Oz",0);
    createContractChar("62446_Alice",0);
    createContractChar("8237_Don Quixote",0);
    createContractChar("16808_King Arthur",0);
    createContractChar("194085_Sleeping Beauty",0);
    createContractChar("299250_Little Red Riding Hood",0);
    createContractChar("166604_Aladdin",0);
    createContractChar("7640956_Peter Pan",0);
    createContractChar("927344_Ali Baba",0);
    createContractChar("153957_Lancelot",0);
    createContractChar("235918_Dr._Jekyll_and_Mr._Hyde",0);
    createContractChar("157787_Captain_Nemo",0);
    createContractChar("933085_Moby_Dick",0);
    createContractChar("54246379_Dorian_Gray",0);
    createContractChar("55483_Robinson_Crusoe",0);
    createContractChar("380143_Black_Beauty",0);
    createContractChar("6364074_Phantom_of_the_Opera",0); 
    createContractChar("15055_Ivanhoe",0);
    createContractChar("21491685_Tarzan",0);
         
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
     
    require(_owns(msg.sender, _tokenId));

    charIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }


   
  function createContractChar(string _wikiID_Name, uint256 _price) public onlyCLevel {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);
    if (_price <= 0) {
      _price = startingPrice;
    }
    promoCreatedCount++;
    _createChar(_wikiID_Name, address(this), _price);
  }
   
   
  function getChar(uint256 _tokenId) public view returns (
    string wikiID_Name,
    uint256 sellingPrice,
    address owner
  ) {
    Char storage char = chars[_tokenId];
    wikiID_Name = char.wikiID_Name;
    sellingPrice = charIndexToPrice[_tokenId];
    owner = charIndexToOwner[_tokenId];
  }
  function changeWikiID_Name(uint256 _tokenId, string _wikiID_Name) public onlyCLevel {
    require(_tokenId < chars.length);
    chars[_tokenId].wikiID_Name = _wikiID_Name;
  }
  function changeBonusUntilDate(uint32 _days) public onlyCLevel {
       bonusUntilDate = now + (_days * 1 days);
  }
  function changeBonusFrequency(uint32 _n) public onlyCLevel {
       bonusFrequency = _n;
  }
  function overrideCharPrice(uint256 _tokenId, uint256 _price) public onlyCLevel {
    require(_price != charIndexToPrice[_tokenId]);
    require(_tokenId < chars.length);
     
    require((_owns(address(this), _tokenId)) || (  _owns(msg.sender, _tokenId)) ); 
    charIndexToPrice[_tokenId] = _price;
  }
  function changeCharPrice(uint256 _tokenId, uint256 _price) public {
    require(_owns(msg.sender, _tokenId));
    require(_tokenId < chars.length);
    require(_price != charIndexToPrice[_tokenId]);
     
    uint256 maxPrice = SafeMath.div(SafeMath.mul(charIndexToPrice[_tokenId], 1000),100);  
    uint256 minPrice = SafeMath.div(SafeMath.mul(charIndexToPrice[_tokenId], 50),100);  
    require(_price >= minPrice); 
    require(_price <= maxPrice); 
    charIndexToPrice[_tokenId] = _price; 
  }
   
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }
   
  function name() public pure returns (string) {
    return NAME;
  }
   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }
   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = charIndexToOwner[_tokenId];
    require(owner != address(0));
  }
 
 
 
  function withdrawFunds(address _to, uint256 amount) public onlyCLevel {
    _withdrawFunds(_to, amount);
  }
   
  function purchase(uint256 _tokenId, uint256 newPrice) public payable {
    address oldOwner = charIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    uint256 sellingPrice = charIndexToPrice[_tokenId];
     
    require(oldOwner != newOwner);
     
    require(_addressNotNull(newOwner));
     
    require(msg.value >= sellingPrice);
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
     
    if (newPrice >= sellingPrice) charIndexToPrice[_tokenId] = newPrice;
    else {
            if (sellingPrice < firstStepLimit) {
               
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
            } else if (sellingPrice < secondStepLimit) {
               
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
            } else if (sellingPrice < thirdStepLimit) {
               
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
            } else {
               
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 100);
            }
    }
    _transfer(oldOwner, newOwner, _tokenId);
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }
    emit TokenSold(_tokenId, sellingPrice, charIndexToPrice[_tokenId], oldOwner, newOwner,
      chars[_tokenId].wikiID_Name);
    msg.sender.transfer(purchaseExcess);
     
      if( (now < bonusUntilDate && (addressToTrxCount[newOwner] % bonusFrequency) == 0) ) 
      {
           
          uint rand = uint (keccak256(now)) % 50 ;  
          rand = rand * (sellingPrice-payment);   
          _withdrawFunds(newOwner,rand);
          emit Bonus(newOwner,rand);
      }
  }
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return charIndexToPrice[_tokenId];
  }
   
  function enableERC721() public onlyCEO {
    erc721Enabled = true;
  }
   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }
   
   
  function setCOO(address _newCOO) public onlyCOO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }
 
   
  function setCFO(address _newCFO) public onlyCFO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }
  
  
   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = charIndexToOwner[_tokenId];
      
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
      uint256 totalChars = chars.length;
      uint256 resultIndex = 0;
      uint256 t;
      for (t = 0; t <= totalChars; t++) {
        if (charIndexToOwner[t] == _owner) {
          result[resultIndex] = t;
          resultIndex++;
        }
      }
      return result;
    }
  }
   
   
  function totalSupply() public view returns (uint256 total) {
    return chars.length;
  }
   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));
    _transfer(msg.sender, _to, _tokenId);
  }
   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));
    _transfer(_from, _to, _tokenId);
  }
   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }
   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return charIndexToApproved[_tokenId] == _to;
  }
   
  function _createChar(string _wikiID_Name, address _owner, uint256 _price) private {
    Char memory _char = Char({
      wikiID_Name: _wikiID_Name
    });
    uint256 newCharId = chars.push(_char) - 1;
     
     
    require(newCharId == uint256(uint32(newCharId)));
    emit Birth(newCharId, _wikiID_Name, _owner);
    charIndexToPrice[newCharId] = _price;
     
     
    _transfer(address(0), _owner, newCharId);
  }
   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == charIndexToOwner[_tokenId];
  }
   
 
 
 
 
 
 
 
 function _withdrawFunds(address _to, uint256 amount) private {
    require(address(this).balance >= amount);
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }
   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    charIndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete charIndexToApproved[_tokenId];
    }
     
    emit Transfer(_from, _to, _tokenId);
   
  addressToTrxCount[_to]++;
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