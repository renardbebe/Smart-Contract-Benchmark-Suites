 

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


contract CryptoPoosToken is ERC721 {

   
   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
  event ToiletPotChange();

   

   
  string public constant NAME = "CryptoPoos";  
  string public constant SYMBOL = "CryptoPoosToken";  

  uint256 private startingPrice = 0.005 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  
   
  uint256 private minFlushPrice = 0.002 ether;


   

   
   
  mapping (uint256 => address) public pooIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public pooIndexToApproved;

   
  mapping (uint256 => uint256) private pooIndexToPrice;
  
   
  address public ceoAddress;
  address public cooAddress;
  
  uint256 roundCounter;
  address lastFlusher;    
  uint256 flushedTokenId;    
  uint256 lastPotSize;  
  uint256 goldenPooId;  
  uint public lastPurchaseTime;  

   
  struct Poo {
    string name;
  }

  Poo[] private poos;

   
   
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

   
  function CryptoPoosToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
	
	createContractPoo("1");
	createContractPoo("2");
	createContractPoo("3");
	createContractPoo("4");
	createContractPoo("5");
	createContractPoo("6");
	roundCounter = 1;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    pooIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractPoo(string _name) public onlyCOO {
    _createPoo(_name, address(this), startingPrice);
  }

   
   
  function getPoo(uint256 _tokenId) public view returns (
    string pooName,
    uint256 sellingPrice,
    address owner
  ) {
    Poo storage poo = poos[_tokenId];
    pooName = poo.name;
    sellingPrice = pooIndexToPrice[_tokenId];
    owner = pooIndexToOwner[_tokenId];
  }

  function getRoundDetails() public view returns (
    uint256 currentRound,
	uint256 currentBalance,
	uint256 currentGoldenPoo,
	uint256 lastRoundReward,
    uint256 lastFlushedTokenId,
    address lastRoundFlusher,
	bool bonusWinChance,
	uint256 lowestFlushPrice
  ) {
	currentRound = roundCounter;
	currentBalance = this.balance;
	currentGoldenPoo = goldenPooId;
	lastRoundReward = lastPotSize;
	lastFlushedTokenId = flushedTokenId;
	lastRoundFlusher = lastFlusher;
	bonusWinChance = _increaseWinPotChance();
	lowestFlushPrice = minFlushPrice;
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
    owner = pooIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   function donate() public payable {
	require(msg.value >= 0.001 ether);
   }


   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = pooIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = pooIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

     
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 62), 100));
  
     
    ceoAddress.transfer(uint256(SafeMath.div(SafeMath.mul(sellingPrice, 8), 100)));

	 

     
     pooIndexToPrice[_tokenId] = uint256(SafeMath.mul(sellingPrice, 2));

    _transfer(oldOwner, newOwner, _tokenId);
	
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); 
    }

    _checkToiletFlush(false, _tokenId); 
	lastPurchaseTime = now;
	ToiletPotChange();
  }
  
   
  function tryFlush() public payable {

         
        require(msg.value >= minFlushPrice);

		 
		ceoAddress.transfer(uint256(SafeMath.div(SafeMath.mul(msg.value, 10), 100)));

        _checkToiletFlush(true, 0);
		lastPurchaseTime = now;
		ToiletPotChange();
  }
  
   
 function _checkToiletFlush(bool _manualFlush, uint256 _purchasedTokenId) private {
     
    uint256 winningChance = 25;

	 
	if(_manualFlush){
		winningChance = 50;
	}else if(_purchasedTokenId == goldenPooId){
		 
		winningChance = uint256(SafeMath.div(SafeMath.mul(winningChance, 90), 100));
	}

	 
	if(_increaseWinPotChance()){
		winningChance = uint256(SafeMath.div(winningChance,3));
	}
     
     
    if(ownershipTokenCount[msg.sender] == 0){
        winningChance = uint256(SafeMath.mul(winningChance,2));
    }
     
    uint256 flushPooIndex = rand(winningChance);
    
    if( (flushPooIndex < 6) && (flushPooIndex != goldenPooId) &&  (msg.sender != pooIndexToOwner[flushPooIndex])  ){
      lastFlusher = msg.sender;
	  flushedTokenId = flushPooIndex;
      
      _transfer(pooIndexToOwner[flushPooIndex],address(this),flushPooIndex);
      pooIndexToPrice[flushPooIndex] = startingPrice;
      
       
	  uint256 reward = uint256(SafeMath.div(SafeMath.mul(this.balance, 95), 100));
	  lastPotSize = reward;

      msg.sender.transfer(reward);  
	  goldenPooId = rand(6); 

	  roundCounter += 1;  
    }
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return pooIndexToPrice[_tokenId];
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
  function _increaseWinPotChance() constant private returns (bool) {
    if (now >= lastPurchaseTime + 120 minutes) {
         
        return true;
    }
    return false;
}

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = pooIndexToOwner[_tokenId];

     
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
      uint256 totalPoos = totalSupply();
      uint256 resultIndex = 0;

      uint256 pooId;
      for (pooId = 0; pooId <= totalPoos; pooId++) {
        if (pooIndexToOwner[pooId] == _owner) {
          result[resultIndex] = pooId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return poos.length;
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
    return pooIndexToApproved[_tokenId] == _to;
  }

   
  function _createPoo(string _name, address _owner, uint256 _price) private {
    Poo memory _poo = Poo({
      name: _name
    });
    uint256 newPooId = poos.push(_poo) - 1;

     
     
    require(newPooId == uint256(uint32(newPooId)));

    Birth(newPooId, _name, _owner);

    pooIndexToPrice[newPooId] = _price;

     
     
    _transfer(address(0), _owner, newPooId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == pooIndexToOwner[_tokenId];
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    pooIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete pooIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
  
     
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max;
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