 

pragma solidity ^0.4.2;

 
 
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

contract Elements is ERC721 {

  	 
  	 
  	event Birth(uint256 tokenId, string name, address owner);

  	 
  	event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  	 
  	event Transfer(address from, address to, uint256 tokenId);

  	 

	 
	string public constant NAME = "CryptoElements";  
	string public constant SYMBOL = "CREL";  

  	uint256 private periodicStartingPrice = 5 ether;
  	uint256 private elementStartingPrice = 0.005 ether;
  	uint256 private scientistStartingPrice = 0.1 ether;
  	uint256 private specialStartingPrice = 0.05 ether;

  	uint256 private firstStepLimit =  0.05 ether;
  	uint256 private secondStepLimit = 0.75 ether;
  	uint256 private thirdStepLimit = 3 ether;

  	bool private periodicTableExists = false;

  	uint256 private elementCTR = 0;
  	uint256 private scientistCTR = 0;
  	uint256 private specialCTR = 0;

  	uint256 private constant elementSTART = 1;
  	uint256 private constant scientistSTART = 1000;
  	uint256 private constant specialSTART = 10000;

  	uint256 private constant specialLIMIT = 5000;

  	 

  	 
  	 
  	mapping (uint256 => address) public elementIndexToOwner;

  	 
  	 
  	mapping (address => uint256) private ownershipTokenCount;

  	 
  	 
  	 
  	mapping (uint256 => address) public elementIndexToApproved;

  	 
  	mapping (uint256 => uint256) private elementIndexToPrice;

  	 
  	address public ceoAddress;
  	address public cooAddress;

  	 
  	struct Element {
  		uint256 tokenId;
    	string name;
    	uint256 scientistId;
  	}

  	mapping(uint256 => Element) elements;

  	uint256[] tokens;

  	 
  	 
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

  	 
  	function Elements() public {
  	  	ceoAddress = msg.sender;
  	  	cooAddress = msg.sender;

  	  	createContractPeriodicTable("Periodic");
  	}

  	 
  	 
  	 
  	 
  	 
  	 
  	function approve(address _to, uint256 _tokenId) public {
  	  	 
  	  	require(_owns(msg.sender, _tokenId));
	
	  	elementIndexToApproved[_tokenId] = _to;
	
	  	Approval(msg.sender, _to, _tokenId);
  	}

  	 
  	 
  	 
  	function balanceOf(address _owner) public view returns (uint256 balance) {
    	return ownershipTokenCount[_owner];
  	}

  	 
  	 
  	function getElement(uint256 _tokenId) public view returns (
  		uint256 tokenId,
    	string elementName,
    	uint256 sellingPrice,
    	address owner,
    	uint256 scientistId
  	) {
    	Element storage element = elements[_tokenId];
    	tokenId = element.tokenId;
    	elementName = element.name;
    	sellingPrice = elementIndexToPrice[_tokenId];
    	owner = elementIndexToOwner[_tokenId];
    	scientistId = element.scientistId;
  	}

  	function implementsERC721() public pure returns (bool) {
    	return true;
  	}

  	 
  	 
  	 
  	function ownerOf(uint256 _tokenId) public view returns (address owner) {
    	owner = elementIndexToOwner[_tokenId];
    	require(owner != address(0));
  	}

  	function payout(address _to) public onlyCLevel {
    	_payout(_to);
  	}

  	 
  	function purchase(uint256 _tokenId) public payable {
    	address oldOwner = elementIndexToOwner[_tokenId];
    	address newOwner = msg.sender;

    	uint256 sellingPrice = elementIndexToPrice[_tokenId];
    	 
    	require(oldOwner != newOwner);
    	require(sellingPrice > 0);

    	 
    	require(_addressNotNull(newOwner));

    	 
    	require(msg.value >= sellingPrice);

    	uint256 ownerPayout = SafeMath.mul(SafeMath.div(sellingPrice, 100), 96);
    	uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    	uint256	feeOnce = SafeMath.div(SafeMath.sub(sellingPrice, ownerPayout), 4);
    	uint256 fee_for_dev = SafeMath.mul(feeOnce, 2);

    	 
    	 
    	if (oldOwner != address(this)) {
      		 
      		oldOwner.transfer(ownerPayout);
    	} else {
      		fee_for_dev = SafeMath.add(fee_for_dev, ownerPayout);
    	}

    	 
	    if (elementIndexToOwner[0] != address(this)) {
	    	elementIndexToOwner[0].transfer(feeOnce);
	    } else {
	    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
	    }

	     
	    uint256 scientistId = elements[_tokenId].scientistId;

	    if ( scientistId != scientistSTART ) {
	    	if (elementIndexToOwner[scientistId] != address(this)) {
		    	elementIndexToOwner[scientistId].transfer(feeOnce);
		    } else {
		    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
		    }
	    } else {
	    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
	    }
	        
    	if (purchaseExcess > 0) {
    		msg.sender.transfer(purchaseExcess);
    	}

    	ceoAddress.transfer(fee_for_dev);

    	_transfer(oldOwner, newOwner, _tokenId);

    	 
    	 
    	if (sellingPrice < firstStepLimit) {
      		 
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    	} else if (sellingPrice < secondStepLimit) {
      		 
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    	} else if (sellingPrice < thirdStepLimit) {
    	  	 
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 130), 100);
    	} else {
      		 
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 100);
    	}
  	}

  	function priceOf(uint256 _tokenId) public view returns (uint256 price) {
	    return elementIndexToPrice[_tokenId];
  	}

  	 
  	 
  	function setCEO(address _newCEO) public onlyCEO {
	    require(_newCEO != address(0));

    	ceoAddress = _newCEO;
  	}

  	 
  	 
  	function setCOO(address _newCOO) public onlyCEO {
    	require(_newCOO != address(0));
    	cooAddress = _newCOO;
  	}

  	 
  	 
  	 
  	function takeOwnership(uint256 _tokenId) public {
    	address newOwner = msg.sender;
    	address oldOwner = elementIndexToOwner[_tokenId];

    	 
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
      		uint256 totalElements = totalSupply();
      		uint256 resultIndex = 0;
      		uint256 elementId;
      		for (elementId = 0; elementId < totalElements; elementId++) {
      			uint256 tokenId = tokens[elementId];

		        if (elementIndexToOwner[tokenId] == _owner) {
		          result[resultIndex] = tokenId;
		          resultIndex++;
		        }
      		}
      		return result;
    	}
  	}

  	 
  	 
  	function totalSupply() public view returns (uint256 total) {
    	return tokens.length;
  	}

  	 
  	 
  	 
  	 
  	function transfer( address _to, uint256 _tokenId ) public {
   		require(_owns(msg.sender, _tokenId));
    	require(_addressNotNull(_to));
    	_transfer(msg.sender, _to, _tokenId);
  	}

  	 
  	 
  	 
  	 
  	 
  	function transferFrom( address _from, address _to, uint256 _tokenId) public {
    	require(_owns(_from, _tokenId));
    	require(_approved(_to, _tokenId));
    	require(_addressNotNull(_to));
    	_transfer(_from, _to, _tokenId);
  	}

  	 
  	 
  	function _addressNotNull(address _to) private pure returns (bool) {
    	return _to != address(0);
  	}

  	 
	function _approved(address _to, uint256 _tokenId) private view returns (bool) {
		return elementIndexToApproved[_tokenId] == _to;
	}

  	 
  	function _createElement(uint256 _id, string _name, address _owner, uint256 _price, uint256 _scientistId) private returns (string) {

    	uint256 newElementId = _id;
    	 
    	 
    	require(newElementId == uint256(uint32(newElementId)));

    	elements[_id] = Element(_id, _name, _scientistId);

    	Birth(newElementId, _name, _owner);

    	elementIndexToPrice[newElementId] = _price;

    	 
    	 
    	_transfer(address(0), _owner, newElementId);

    	tokens.push(_id);

    	return _name;
  	}


  	 
  	function createContractPeriodicTable(string _name) public onlyCEO {
  		require(periodicTableExists == false);

  		_createElement(0, _name, address(this), periodicStartingPrice, scientistSTART);
  		periodicTableExists = true;
  	}

  	 
  	function createContractElement(string _name, uint256 _scientistId) public onlyCEO {
  		require(periodicTableExists == true);

    	uint256 _id = SafeMath.add(elementCTR, elementSTART);
    	uint256 _scientistIdProcessed = SafeMath.add(_scientistId, scientistSTART);

    	_createElement(_id, _name, address(this), elementStartingPrice, _scientistIdProcessed);
    	elementCTR = SafeMath.add(elementCTR, 1);
  	}

  	 
  	function createContractScientist(string _name) public onlyCEO {
  		require(periodicTableExists == true);

  		 
  		scientistCTR = SafeMath.add(scientistCTR, 1);
    	uint256 _id = SafeMath.add(scientistCTR, scientistSTART);
    	
    	_createElement(_id, _name, address(this), scientistStartingPrice, scientistSTART);	
  	}

  	 
  	function createContractSpecial(string _name) public onlyCEO {
  		require(periodicTableExists == true);
  		require(specialCTR <= specialLIMIT);

  		 
  		specialCTR = SafeMath.add(specialCTR, 1);
    	uint256 _id = SafeMath.add(specialCTR, specialSTART);

    	_createElement(_id, _name, address(this), specialStartingPrice, scientistSTART);
    	
  	}

  	 
  	function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    	return claimant == elementIndexToOwner[_tokenId];
  	}


  	 
  	function checkPeriodic() public view returns (bool) {
  		return periodicTableExists;
  	}

  	function getTotalElements() public view returns (uint256) {
  		return elementCTR;
  	}

  	function getTotalScientists() public view returns (uint256) {
  		return scientistCTR;
  	}

  	function getTotalSpecials() public view returns (uint256) {
  		return specialCTR;
  	}

  	 
  	function changeStartingPricesLimits(uint256 _elementStartPrice, uint256 _scientistStartPrice, uint256 _specialStartPrice) public onlyCEO {
  		elementStartingPrice = _elementStartPrice;
  		scientistStartingPrice = _scientistStartPrice;
  		specialStartingPrice = _specialStartPrice;
	}

	function changeStepPricesLimits(uint256 _first, uint256 _second, uint256 _third) public onlyCEO {
		firstStepLimit = _first;
		secondStepLimit = _second;
		thirdStepLimit = _third;
	}

	 
	function changeScientistForElement(uint256 _tokenId, uint256 _scientistId) public onlyCEO {
    	Element storage element = elements[_tokenId];
    	element.scientistId = SafeMath.add(_scientistId, scientistSTART);
  	}

  	function changeElementName(uint256 _tokenId, string _name) public onlyCEO {
    	Element storage element = elements[_tokenId];
    	element.name = _name;
  	}

  	 
	function modifyTokenPrice(uint256 _tokenId, uint256 _newPrice) public payable {
	    require(_newPrice > elementStartingPrice);
	    require(elementIndexToOwner[_tokenId] == msg.sender);
	    require(_newPrice < elementIndexToPrice[_tokenId]);

	    if ( _tokenId == 0) {
	    	require(_newPrice > periodicStartingPrice);
	    } else if ( _tokenId < 1000) {
	    	require(_newPrice > elementStartingPrice);
	    } else if ( _tokenId < 10000 ) {
	    	require(_newPrice > scientistStartingPrice);
	    } else {
	    	require(_newPrice > specialStartingPrice);
	    }

	    elementIndexToPrice[_tokenId] = _newPrice;
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
  	  	 
  	  	elementIndexToOwner[_tokenId] = _to;
  	  	 
  	  	if (_from != address(0)) {
  	    	ownershipTokenCount[_from]--;
  	    	 
  	    	delete elementIndexToApproved[_tokenId];
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