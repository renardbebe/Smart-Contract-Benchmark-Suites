 

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


contract CelebrityToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoCelebrities";  
  string public constant SYMBOL = "CelebrityToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public personIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public personIndexToApproved;

   
  mapping (uint256 => uint256) private personIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Person {
    string name;
  }

  Person[] private persons;

   
   
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

   
  function CelebrityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    personIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoPerson(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address personOwner = _owner;
    if (personOwner == address(0)) {
      personOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPerson(_name, personOwner, _price);
  }

   
  function createContractPerson(string _name) public onlyCOO {
    _createPerson(_name, address(this), startingPrice);
  }

   
   
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  ) {
    Person storage person = persons[_tokenId];
    personName = person.name;
    sellingPrice = personIndexToPrice[_tokenId];
    owner = personIndexToOwner[_tokenId];
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
    owner = personIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, personIndexToPrice[_tokenId], oldOwner, newOwner, persons[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return personIndexToPrice[_tokenId];
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
    address oldOwner = personIndexToOwner[_tokenId];

     
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
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;

      uint256 personId;
      for (personId = 0; personId <= totalPersons; personId++) {
        if (personIndexToOwner[personId] == _owner) {
          result[resultIndex] = personId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return persons.length;
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
    return personIndexToApproved[_tokenId] == _to;
  }

   
  function _createPerson(string _name, address _owner, uint256 _price) private {
    Person memory _person = Person({
      name: _name
    });
    uint256 newPersonId = persons.push(_person) - 1;

     
     
    require(newPersonId == uint256(uint32(newPersonId)));

    Birth(newPersonId, _name, _owner);

    personIndexToPrice[newPersonId] = _price;

     
     
    _transfer(address(0), _owner, newPersonId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == personIndexToOwner[_tokenId];
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
     
    personIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete personIndexToApproved[_tokenId];
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

 

contract CelebrityBreederToken is ERC721 {
  
    
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);
  event Trained(address caller, uint256 tokenId, bool generation);
  event Beaten(address caller, uint256 tokenId, bool generation);
  event SiringPriceEvent(address caller, uint256 tokenId, bool generation, uint price);
  event SellingPriceEvent(address caller, uint256 tokenId, bool generation, uint price);
  event GenesInitialisedEvent(address caller, uint256 tokenId, bool generation, uint genes);
  
  CelebrityToken private CelGen0=CelebrityToken(0xbb5Ed1EdeB5149AF3ab43ea9c7a6963b3C1374F7);  
  CelebrityBreederToken private CelBetta=CelebrityBreederToken(0xdab64dc4a02225f76fccce35ab9ba53b3735c684);  
 
  string public constant NAME = "CryptoCelebrityBreederCards"; 
  string public constant SYMBOL = "CeleBreedCard"; 

  uint256 public breedingFee = 0.01 ether;
  uint256 public initialTraining = 0.00001 ether;
  uint256 public initialBeating = 0.00002 ether;
  uint256 private constant CreationLimitGen0 = 5000;
  uint256 private constant CreationLimitGen1 = 2500000;
  uint256 public constant MaxValue =  100000000 ether;
  
  mapping (uint256 => address) public personIndexToOwnerGen1;
  mapping (address => uint256) private ownershipTokenCountGen1;
  mapping (uint256 => address) public personIndexToApprovedGen1;
  mapping (uint256 => uint256) private personIndexToPriceGen1;
  mapping (uint256 => address) public ExternalAllowdContractGen0;
  mapping (uint256 => address) public ExternalAllowdContractGen1; 
  mapping (uint256 => uint256) public personIndexToSiringPrice0;
  mapping (uint256 => uint256) public personIndexToSiringPrice1;
  address public CeoAddress; 
  address public DevAddress;
  
   struct Person {
    string name;
    string surname; 
    uint64 genes; 
    uint64 birthTime;
    uint32 fatherId;
    uint32 motherId;
    uint32 readyToBreedWithId;
    uint32 trainedcount;
    uint32 beatencount;
    bool readyToBreedWithGen;
    bool gender;
    bool fatherGeneration;
    bool motherGeneration;
  }
  
  Person[] private PersonsGen0;
  Person[] private PersonsGen1;
  
    modifier onlyCEO() {
    require(msg.sender == CeoAddress);
    _;
  }

  modifier onlyDEV() {
    require(msg.sender == DevAddress);
    _;
  }
  
   modifier onlyPlayers() {
    require(ownershipTokenCountGen1[msg.sender]>0 || CelGen0.balanceOf(msg.sender)>0);
    _;
  }

   
  
  function masscreate(uint256 fromindex, uint256 toindex) external onlyCEO{ 
      string memory name; string memory surname; uint64 genes;  bool gender;
      for(uint256 i=fromindex;i<=toindex;i++)
      {
          ( name, surname, genes, , ,  , , ,  gender)=CelBetta.getPerson(i,false);
         _birthPerson(name, surname ,genes, gender, false);
      }
  }
  function CelebrityBreederToken() public { 
      CeoAddress= msg.sender;
      DevAddress= msg.sender;
  }
    function setBreedingFee(uint256 newfee) external onlyCEO{
      breedingFee=newfee;
  }
  function allowexternalContract(address _to, uint256 _tokenId,bool _tokengeneration) public { 
     
    require(_owns(msg.sender, _tokenId, _tokengeneration));
    
    if(_tokengeneration) {
        if(_addressNotNull(_to)) {
            ExternalAllowdContractGen1[_tokenId]=_to;
        }
        else {
             delete ExternalAllowdContractGen1[_tokenId];
        }
    }
    else {
       if(_addressNotNull(_to)) {
            ExternalAllowdContractGen0[_tokenId]=_to;
        }
        else {
             delete ExternalAllowdContractGen0[_tokenId];
        }
    }

  }
  
  
   
  function approve(address _to, uint256 _tokenId) public {  
     
    require(_owns(msg.sender, _tokenId, true));

    personIndexToApprovedGen1[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }
   
   
   function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCountGen1[_owner];
  }
  
    function getPerson(uint256 _tokenId,bool generation) public view returns ( string name, string surname, uint64 genes,uint64 birthTime, uint32 readyToBreedWithId, uint32 trainedcount,uint32 beatencount,bool readyToBreedWithGen, bool gender) {
    Person person;
    if(generation==false) {
        person = PersonsGen0[_tokenId];
    }
    else {
        person = PersonsGen1[_tokenId];
    }
         
    name = person.name;
    surname=person.surname;
    genes=person.genes;
    birthTime=person.birthTime;
    readyToBreedWithId=person.readyToBreedWithId;
    trainedcount=person.trainedcount;
    beatencount=person.beatencount;
    readyToBreedWithGen=person.readyToBreedWithGen;
    gender=person.gender;

  }
   function getPersonParents(uint256 _tokenId, bool generation) public view returns ( uint32 fatherId, uint32 motherId, bool fatherGeneration, bool motherGeneration) {
    Person person;
    if(generation==false) {
        person = PersonsGen0[_tokenId];
    }
    else {
        person = PersonsGen1[_tokenId];
    }
         
    fatherId=person.fatherId;
    motherId=person.motherId;
    fatherGeneration=person.fatherGeneration;
    motherGeneration=person.motherGeneration;
  }
   
   function implementsERC721() public pure returns (bool) { 
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

 
  function ownerOf(uint256 _tokenId) public view returns (address owner)
  {
    owner = personIndexToOwnerGen1[_tokenId];
    require(_addressNotNull(owner));
  }
  
   
   function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwnerGen1[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPriceGen1[_tokenId];
    personIndexToPriceGen1[_tokenId]=MaxValue;

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
     
    oldOwner.transfer(sellingPrice);
    }
    blankbreedingdata(_tokenId,true);

    TokenSold(_tokenId, sellingPrice, personIndexToPriceGen1[_tokenId], oldOwner, newOwner, PersonsGen1[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }
  
    
   function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return personIndexToPriceGen1[_tokenId];
  }

 
  function setCEO(address _newCEO) external onlyCEO {
    require(_addressNotNull(_newCEO));

    CeoAddress = _newCEO;
  }

  
 function setprice(uint256 _tokenId, uint256 _price) public {
    require(_owns(msg.sender, _tokenId, true));
    if(_price<=0 || _price>=MaxValue) {
        personIndexToPriceGen1[_tokenId]=MaxValue;
    }
    else {
        personIndexToPriceGen1[_tokenId]=_price;
    }
    SellingPriceEvent(msg.sender,_tokenId,true,_price);
 }
 
  function setDEV(address _newDEV) external onlyDEV {
    require(_addressNotNull(_newDEV));

    DevAddress = _newDEV;
  }
  
     
  function symbol() public pure returns (string) {
    return SYMBOL;
  }


   
    
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = personIndexToOwnerGen1[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approvedGen1(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }
  
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } 
    else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;

      uint256 personId;
      for (personId = 0; personId <= totalPersons; personId++) {
        if (personIndexToOwnerGen1[personId] == _owner) {
          result[resultIndex] = personId;
          resultIndex++;
        }
      }
      return result;
    }
  }
  
    
    
   function totalSupply() public view returns (uint256 total) {
    return PersonsGen1.length;
  }

    
    
  function transfer( address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId, true));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }
  
    
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_owns(_from, _tokenId, true));
    require(_approvedGen1(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }
  
   function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approvedGen1(address _to, uint256 _tokenId) private view returns (bool) {
    return personIndexToApprovedGen1[_tokenId] == _to;
  }
   
   function createPersonGen0(string _name, string _surname,uint64 _genes, bool _gender) external onlyCEO returns(uint256) {
    return _birthPerson(_name, _surname ,_genes, _gender, false);
  }
  function SetGene(uint256 tokenId,bool generation, uint64 newgene) public {
     require(_owns(msg.sender, tokenId, generation) || msg.sender==CeoAddress);
     require(newgene<=9999999999 && newgene>=10);
     Person person;  
    if (generation==false) { 
        person = PersonsGen0[tokenId];
    }
    else {
        person = PersonsGen1[tokenId];
    }
    require(person.genes<=90);
     
    uint64 _gene=newgene;
    uint64 _pointCount=0;
   
   
      for(uint i=0;i<10;i++) {
           _pointCount+=_gene%10;
           _gene=_gene/10;
      }
     
    require(_pointCount==person.genes);
           
    person.genes=newgene;
    GenesInitialisedEvent(msg.sender,tokenId,generation,newgene);
}
 
   function breed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool  _withpersongeneration, string _boyname, string _girlname) public payable {  
       require(_owns(msg.sender, _mypersonid, _mypersongeneration));
       require(CreationLimitGen1>totalSupply()+1);
    
     
    Person person;  
    if(_mypersongeneration==false) { 
        person = PersonsGen0[_mypersonid];
    }
    else {
        person = PersonsGen1[_mypersonid];
        require(person.gender==false);  
    }

    require(person.genes>90); 
    
    uint64 genes1=person.genes;
     
        if(_withpersongeneration==false) { 
        person = PersonsGen0[_withpersonid];
    }
    else {
        person = PersonsGen1[_withpersonid];
       
    }
     
   
     require(readyTobreed(_mypersonid, _mypersongeneration, _withpersonid,  _withpersongeneration));
     require(breedingFee<=msg.value);
   
    
    delete person.readyToBreedWithId;
    person.readyToBreedWithGen=false;
    
    
    
       uint64 _generatedGen;
       bool _gender; 
       (_generatedGen,_gender)=_generateGene(genes1,person.genes,_mypersonid,_withpersonid); 
       
     if(_gender) {
       _girlname=_boyname;  
     }
       uint newid=_birthPerson(_girlname, person.surname, _generatedGen, _gender, true);
            PersonsGen1[newid].fatherGeneration=_withpersongeneration;  
            PersonsGen1[newid].motherGeneration=_mypersongeneration;
            PersonsGen1[newid].fatherId=uint32(_withpersonid); 
            PersonsGen1[newid].motherId=uint32(_mypersonid);
        
        
       _payout();
  }
  
    function breedOnAuction(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool  _withpersongeneration, string _boyname, string _girlname) public payable {  
       require(_owns(msg.sender, _mypersonid, _mypersongeneration));
       require(CreationLimitGen1>totalSupply()+1);
       require(!(_mypersonid==_withpersonid && _mypersongeneration==_withpersongeneration)); 
       require(!((_mypersonid==0 && _mypersongeneration==false) || (_withpersonid==0 && _withpersongeneration==false)));  
     
    Person person;  
    if(_mypersongeneration==false) { 
        person = PersonsGen0[_mypersonid];
    }
    else {
        person = PersonsGen1[_mypersonid];
        require(person.gender==false);  
    }
    
    require(person.genes>90); 
    
    address owneroffather;
    uint256 _siringprice;
    uint64 genes1=person.genes;
     
        if(_withpersongeneration==false) { 
        person = PersonsGen0[_withpersonid];
        _siringprice=personIndexToSiringPrice0[_withpersonid];
        owneroffather=CelGen0.ownerOf(_withpersonid);
    }
    else {
        person = PersonsGen1[_withpersonid];
        _siringprice=personIndexToSiringPrice1[_withpersonid];
        owneroffather= personIndexToOwnerGen1[_withpersonid];
    }
     
   require(_siringprice>0 && _siringprice<MaxValue);
   require((breedingFee+_siringprice)<=msg.value);
    
    
 
    
       uint64 _generatedGen;
       bool _gender; 
       (_generatedGen,_gender)=_generateGene(genes1,person.genes,_mypersonid,_withpersonid); 
       
     if(_gender) {
       _girlname=_boyname;  
     }
       uint newid=_birthPerson(_girlname, person.surname, _generatedGen, _gender, true);
            PersonsGen1[newid].fatherGeneration=_withpersongeneration;  
            PersonsGen1[newid].motherGeneration=_mypersongeneration;
            PersonsGen1[newid].fatherId=uint32(_withpersonid); 
            PersonsGen1[newid].motherId=uint32(_mypersonid);
        
        
        owneroffather.transfer(_siringprice);
       _payout();
  }
 
  
  
  function prepareToBreed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool _withpersongeneration, uint256 _siringprice) external {  
      require(_owns(msg.sender, _mypersonid, _mypersongeneration)); 
      
       Person person;  
    if(_mypersongeneration==false) {
        person = PersonsGen0[_mypersonid];
        personIndexToSiringPrice0[_mypersonid]=_siringprice;
    }
    else {
        person = PersonsGen1[_mypersonid];
        
        require(person.gender==true); 
        personIndexToSiringPrice1[_mypersonid]=_siringprice;
    }
      require(person.genes>90); 

       person.readyToBreedWithId=uint32(_withpersonid); 
       person.readyToBreedWithGen=_withpersongeneration;
       SiringPriceEvent(msg.sender,_mypersonid,_mypersongeneration,_siringprice);
      
  }
  
  function readyTobreed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool _withpersongeneration) public view returns(bool) {

if (_mypersonid==_withpersonid && _mypersongeneration==_withpersongeneration)  
return false;

if((_mypersonid==0 && _mypersongeneration==false) || (_withpersonid==0 && _withpersongeneration==false))  
return false;

    Person withperson;  
    if(_withpersongeneration==false) {
        withperson = PersonsGen0[_withpersonid];
    }
    else {
        withperson = PersonsGen1[_withpersonid];
    }
   
   
   if(withperson.readyToBreedWithGen==_mypersongeneration) {
       if(withperson.readyToBreedWithId==_mypersonid) {
       return true;
   }
   }
  
    
    return false;
    
  }
  function _birthPerson(string _name, string _surname, uint64 _genes, bool _gender, bool _generation) private returns(uint256) {  
    Person memory _person = Person({
        name: _name,
        surname: _surname,
        genes: _genes,
        birthTime: uint64(now),
        fatherId: 0,
        motherId: 0,
        readyToBreedWithId: 0,
        trainedcount: 0,
        beatencount: 0,
        readyToBreedWithGen: false,
        gender: _gender,
        fatherGeneration: false,
        motherGeneration: false

        
    });
    
    uint256 newPersonId;
    if(_generation==false) {
         newPersonId = PersonsGen0.push(_person) - 1;
    }
    else {
         newPersonId = PersonsGen1.push(_person) - 1;
         personIndexToPriceGen1[newPersonId] = MaxValue;  
           
        _transfer(address(0), msg.sender, newPersonId);
        

    }

    Birth(newPersonId, _name, msg.sender);
    return newPersonId;
  }
  function _generateGene(uint64 _genes1,uint64 _genes2,uint256 _mypersonid,uint256 _withpersonid) private returns(uint64,bool) {
       uint64 _gene;
       uint64 _gene1;
       uint64 _gene2;
       uint64 _rand;
       uint256 _finalGene=0;
       bool gender=false;

       for(uint i=0;i<10;i++) {
           _gene1 =_genes1%10;
           _gene2=_genes2%10;
           _genes1=_genes1/10;
           _genes2=_genes2/10;
           _rand=uint64(keccak256(block.blockhash(block.number), i, now,_mypersonid,_withpersonid))%10000;
           
          _gene=(_gene1+_gene2)/2;
           
           if(_rand<26) {
               _gene-=3;
           }
            else if(_rand<455) {
                _gene-=2;
           }
            else if(_rand<3173) {
                _gene-=1;
           }
            else if(_rand<6827) {
                
           }
            else if(_rand<9545) {
                _gene+=1;
           }
            else if(_rand<9974) {
                _gene+=2;
           }
            else if(_rand<10000) {
                _gene+=3;
           }
           
           if(_gene>12)  
           _gene=0;
           if(_gene>9)
           _gene=9;
           
           _finalGene+=(uint(10)**i)*_gene;
       }
      
      if(uint64(keccak256(block.blockhash(block.number), 11, now,_mypersonid,_withpersonid))%2>0)
      gender=true;
      
      return(uint64(_finalGene),gender);  
  } 
  function _owns(address claimant, uint256 _tokenId,bool _tokengeneration) private view returns (bool) {
   if(_tokengeneration) {
        return ((claimant == personIndexToOwnerGen1[_tokenId]) || (claimant==ExternalAllowdContractGen1[_tokenId]));
   }
   else {
       return ((claimant == CelGen0.personIndexToOwner(_tokenId)) || (claimant==ExternalAllowdContractGen0[_tokenId]));
   }
  }
      
  function _payout() private {
    DevAddress.transfer((this.balance/10)*3);
    CeoAddress.transfer((this.balance/10)*7); 
  }
  
    
    
   function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCountGen1[_to]++;
     
    personIndexToOwnerGen1[_tokenId] = _to;

     
    if (_addressNotNull(_from)) {
      ownershipTokenCountGen1[_from]--;
       
     blankbreedingdata(_tokenId,true);
    }

     
    Transfer(_from, _to, _tokenId);
  }
  function blankbreedingdata(uint256 _personid, bool _persongeneration) private{
      Person person;
      if(_persongeneration==false) { 
        person = PersonsGen0[_personid];
        delete ExternalAllowdContractGen0[_personid];
        delete personIndexToSiringPrice0[_personid];
    }
    else {
        person = PersonsGen1[_personid];
        delete ExternalAllowdContractGen1[_personid];
        delete personIndexToSiringPrice1[_personid];
    	delete personIndexToApprovedGen1[_personid];
    }
     delete person.readyToBreedWithId;
     delete person.readyToBreedWithGen; 
  }
    function train(uint256 personid, bool persongeneration, uint8 gene) external payable onlyPlayers {
        
        require(gene>=0 && gene<10);
        uint256 trainingPrice=checkTrainingPrice(personid,persongeneration);
        require(msg.value >= trainingPrice);
         Person person; 
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
     require(person.genes>90); 
     uint gensolo=person.genes/(uint(10)**gene);
    gensolo=gensolo%10;
    require(gensolo<9);  
    
          person.genes+=uint64(10)**gene;
          person.trainedcount++;

    uint256 purchaseExcess = SafeMath.sub(msg.value, trainingPrice);
    msg.sender.transfer(purchaseExcess);
    _payout();
    Trained(msg.sender, personid, persongeneration);
    }
    
     function beat(uint256 personid, bool persongeneration, uint8 gene) external payable onlyPlayers {
        require(gene>=0 && gene<10);
        uint256 beatingPrice=checkBeatingPrice(personid,persongeneration);
        require(msg.value >= beatingPrice);
         Person person; 
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
    require(person.genes>90); 
    uint gensolo=person.genes/(uint(10)**gene);
    gensolo=gensolo%10;
    require(gensolo>0);
          person.genes-=uint64(10)**gene;
          person.beatencount++;

    uint256 purchaseExcess = SafeMath.sub(msg.value, beatingPrice);
    msg.sender.transfer(purchaseExcess);
    _payout();
    Beaten(msg.sender, personid, persongeneration);    
    }
    
    
    function checkTrainingPrice(uint256 personid, bool persongeneration) view returns (uint256) {
         Person person;
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
    uint256 _trainingprice= (uint(2)**person.trainedcount) * initialTraining;
    if (_trainingprice > 5 ether)
    _trainingprice=5 ether;
    
    return _trainingprice;
    }
    function checkBeatingPrice(uint256 personid, bool persongeneration) view returns (uint256) {
         Person person;
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    uint256 _beatingprice=(uint(2)**person.beatencount) * initialBeating;
     if (_beatingprice > 7 ether)
    _beatingprice=7 ether;
    return _beatingprice;
    } 
  
}