 

pragma solidity ^0.4.24;


 
contract ERC721Receiver {

	 
	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	 
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


 
contract PixelConMarket is ERC721Receiver {

	 
	uint8 private constant LOCK_NONE = 0;
	uint8 private constant LOCK_NO_LISTING = 1;
	uint8 private constant LOCK_REMOVE_ONLY = 2;

	 
	uint256 private constant WEI_PER_GWEI = 1000000000;
	uint256 private constant FEE_RATIO = 100000;


	 
	 
	 

	 
	struct Listing {
		uint64 startAmount;  
		uint64 endAmount;  
		uint64 startDate;
		uint64 duration;
		 
		address seller;
		uint32 sellerIndex;
		uint64 forSaleIndex;
	}


	 
	 
	 

	 
	uint32 internal devFee;  
	uint32 internal priceUpdateInterval;  
	uint32 internal startDateRoundValue;  
	uint32 internal durationRoundValue;  
	uint64 internal maxDuration;  
	uint64 internal minDuration;  
	uint256 internal maxPrice;  
	uint256 internal minPrice;  

	 
	PixelCons internal pixelconsContract;
	address internal admin;
	uint8 internal systemLock;

	 

	 
	mapping(address => uint64[]) internal sellerPixelconIndexes;

	 
	mapping(uint64 => Listing) internal marketPixelconListings;

	 
	uint64[] internal forSalePixelconIndexes;


	 
	 
	 

	 
	event Create(uint64 indexed _tokenIndex, address indexed _seller, uint256 _startPrice, uint256 _endPrice, uint64 _duration);
	event Purchase(uint64 indexed _tokenIndex, address indexed _buyer, uint256 _price);
	event Remove(uint64 indexed _tokenIndex, address indexed _operator);


	 
	 
	 

	 
	modifier onlyAdmin {
		require(msg.sender == admin, "Only the admin can call this function");
		_;
	}

	 
	modifier validAddress(address _address) {
		require(_address != address(0), "Invalid address");
		_;
	}


	 
	 
	 

	 
	constructor(address _admin, address _pixelconContract) public 
	{
		require(_admin != address(0), "Invalid address");
		require(_pixelconContract != address(0), "Invalid address");
		admin = _admin;
		pixelconsContract = PixelCons(_pixelconContract);
		systemLock = LOCK_REMOVE_ONLY;

		 
		devFee = 1000;
		priceUpdateInterval = 1 * 60 * 60;
		startDateRoundValue = 5 * 60;
		durationRoundValue = 5 * 60;
		maxDuration = 30 * 24 * 60 * 60;
		minDuration = 1 * 24 * 60 * 60;
		maxPrice = 100000000000000000000;
		minPrice = 1000000000000000;
	}

	 
	function adminChange(address _newAdmin) public onlyAdmin validAddress(_newAdmin) 
	{
		admin = _newAdmin;
	}

	 
	function adminSetLock(bool _lock, bool _allowPurchase) public onlyAdmin 
	{
		if (_lock) {
			if (_allowPurchase) systemLock = LOCK_NO_LISTING;
			else systemLock = LOCK_REMOVE_ONLY;
		} else {
			systemLock = LOCK_NONE;
		}
	}

	 
	function adminSetDetails(uint32 _devFee, uint32 _priceUpdateInterval, uint32 _startDateRoundValue, uint32 _durationRoundValue,
		uint64 _maxDuration, uint64 _minDuration, uint256 _maxPrice, uint256 _minPrice) public onlyAdmin 
	{
		devFee = _devFee;
		priceUpdateInterval = _priceUpdateInterval;
		startDateRoundValue = _startDateRoundValue;
		durationRoundValue = _durationRoundValue;
		maxDuration = _maxDuration;
		minDuration = _minDuration;
		maxPrice = _maxPrice;
		minPrice = _minPrice;
	}

	 
	function adminWithdraw(address _to) public onlyAdmin validAddress(_to) 
	{
		_to.transfer(address(this).balance);
	}

	 
	function adminClose(address _to) public onlyAdmin validAddress(_to) 
	{
		require(forSalePixelconIndexes.length == uint256(0), "Cannot close with active listings");
		selfdestruct(_to);
	}


	 
	 
	 

	 
	function getMarketDetails() public view returns(uint32, uint32, uint32, uint32, uint64, uint64, uint256, uint256) 
	{
		return (devFee, priceUpdateInterval, startDateRoundValue, durationRoundValue, maxDuration, minDuration, maxPrice, minPrice);
	}

	 

	 
	function makeListing(address _seller, uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint256 _duration) internal 
	{
		require(_startPrice <= maxPrice, "Start price is higher than the max allowed");
		require(_startPrice >= minPrice, "Start price is lower than the min allowed");
		require(_endPrice <= maxPrice, "End price is higher than the max allowed");
		require(_endPrice >= minPrice, "End price is lower than the min allowed");

		 
		_startPrice = _startPrice / WEI_PER_GWEI;
		_endPrice = _endPrice / WEI_PER_GWEI;
		require(_endPrice > uint256(0), "End price cannot be zero (gwei)");
		require(_startPrice >= _endPrice, "Start price is lower than the end price");
		require(_startPrice < uint256(2 ** 64), "Start price is out of bounds");
		require(_endPrice < uint256(2 ** 64), "End price is out of bounds");

		 
		uint256 startDate = (now / uint256(startDateRoundValue)) * uint256(startDateRoundValue);
		require(startDate < uint256(2 ** 64), "Start date is out of bounds");

		 
		_duration = (_duration / uint256(durationRoundValue)) * uint256(durationRoundValue);
		require(_duration > uint256(0), "Duration cannot be zero");
		require(_duration <= uint256(maxDuration), "Duration is higher than the max allowed");
		require(_duration >= uint256(minDuration), "Duration is lower than the min allowed");

		 
		uint64 pixelconIndex = pixelconsContract.getTokenIndex(_tokenId);

		 
		Listing storage listing = marketPixelconListings[pixelconIndex];
		listing.startAmount = uint64(_startPrice);
		listing.endAmount = uint64(_endPrice);
		listing.startDate = uint64(startDate);
		listing.duration = uint64(_duration);
		listing.seller = _seller;

		 
		uint64[] storage sellerTokens = sellerPixelconIndexes[_seller];
		uint sellerTokensIndex = sellerTokens.length;
		uint forSaleIndex = forSalePixelconIndexes.length;
		require(sellerTokensIndex < uint256(2 ** 32 - 1), "Max number of market listings has been exceeded for seller");
		require(forSaleIndex < uint256(2 ** 64 - 1), "Max number of market listings has been exceeded");
		listing.sellerIndex = uint32(sellerTokensIndex);
		listing.forSaleIndex = uint64(forSaleIndex);
		sellerTokens.length++;
		sellerTokens[sellerTokensIndex] = pixelconIndex;
		forSalePixelconIndexes.length++;
		forSalePixelconIndexes[forSaleIndex] = pixelconIndex;
		emit Create(pixelconIndex, _seller, _startPrice, _endPrice, uint64(_duration));
	}

	 
	function exists(uint64 _pixelconIndex) public view returns(bool) 
	{
		return (marketPixelconListings[_pixelconIndex].seller != address(0));
	}

	 
	function totalListings() public view returns(uint256) 
	{
		return forSalePixelconIndexes.length;
	}

	 
	function getListing(uint64 _pixelconIndex) public view returns(address _seller, uint256 _startPrice, uint256 _endPrice, uint256 _currPrice,
		uint64 _startDate, uint64 _duration, uint64 _timeLeft) 
	{
		Listing storage listing = marketPixelconListings[_pixelconIndex];
		require(listing.seller != address(0), "Market listing does not exist");

		 
		_seller = listing.seller;
		_startPrice = uint256(listing.startAmount) * WEI_PER_GWEI;
		_endPrice = uint256(listing.endAmount) * WEI_PER_GWEI;
		_currPrice = calcCurrentPrice(uint256(listing.startAmount), uint256(listing.endAmount), uint256(listing.startDate), uint256(listing.duration));
		_startDate = listing.startDate;
		_duration = listing.duration;
		_timeLeft = calcTimeLeft(uint256(listing.startDate), uint256(listing.duration));
	}

	 
	function removeListing(uint64 _pixelconIndex) public 
	{
		Listing storage listing = marketPixelconListings[_pixelconIndex];
		require(listing.seller != address(0), "Market listing does not exist");
		require(msg.sender == listing.seller || msg.sender == admin, "Insufficient permissions");

		 
		uint256 tokenId = pixelconsContract.tokenByIndex(_pixelconIndex);
		address seller = listing.seller;

		 
		clearListingData(seller, _pixelconIndex);

		 
		pixelconsContract.transferFrom(address(this), seller, tokenId);
		emit Remove(_pixelconIndex, msg.sender);
	}

	 
	function purchase(address _to, uint64 _pixelconIndex) public payable validAddress(_to) 
	{
		Listing storage listing = marketPixelconListings[_pixelconIndex];
		require(systemLock != LOCK_REMOVE_ONLY, "Market is currently locked");
		require(listing.seller != address(0), "Market listing does not exist");
		require(listing.seller != msg.sender, "Seller cannot purchase their own listing");

		 
		uint256 currPrice = calcCurrentPrice(uint256(listing.startAmount), uint256(listing.endAmount), uint256(listing.startDate), uint256(listing.duration));
		require(currPrice != uint256(0), "Market listing has expired");
		require(msg.value >= currPrice + (currPrice * uint256(devFee)) / FEE_RATIO, "Insufficient value sent");

		 
		uint256 tokenId = pixelconsContract.tokenByIndex(_pixelconIndex);
		address seller = listing.seller;

		 
		clearListingData(seller, _pixelconIndex);

		 
		pixelconsContract.transferFrom(address(this), _to, tokenId);
		seller.transfer(currPrice);
		emit Purchase(_pixelconIndex, msg.sender, currPrice);
	}

	 

	 
	function getBasicData(uint64[] _indexes) public view returns(uint64[], address[], uint256[], uint64[]) 
	{
		uint64[] memory tokenIndexes = new uint64[](_indexes.length);
		address[] memory sellers = new address[](_indexes.length);
		uint256[] memory currPrices = new uint256[](_indexes.length);
		uint64[] memory timeLeft = new uint64[](_indexes.length);

		for (uint i = 0; i < _indexes.length; i++) {
			Listing storage listing = marketPixelconListings[_indexes[i]];
			if (listing.seller != address(0)) {
				 
				tokenIndexes[i] = _indexes[i];
				sellers[i] = listing.seller;
				currPrices[i] = calcCurrentPrice(uint256(listing.startAmount), uint256(listing.endAmount), uint256(listing.startDate), uint256(listing.duration));
				timeLeft[i] = calcTimeLeft(uint256(listing.startDate), uint256(listing.duration));
			} else {
				 
				tokenIndexes[i] = 0;
				sellers[i] = 0;
				currPrices[i] = 0;
				timeLeft[i] = 0;
			}
		}
		return (tokenIndexes, sellers, currPrices, timeLeft);
	}

	 
	function getForSeller(address _seller) public view validAddress(_seller) returns(uint64[]) 
	{
		return sellerPixelconIndexes[_seller];
	}

	 
	function getAllListings() public view returns(uint64[]) 
	{
		return forSalePixelconIndexes;
	}

	 
	function getListingsInRange(uint64 _startIndex, uint64 _endIndex) public view returns(uint64[])
	{
		require(_startIndex <= totalListings(), "Start index is out of bounds");
		require(_endIndex <= totalListings(), "End index is out of bounds");
		require(_startIndex <= _endIndex, "End index is less than the start index");

		uint64 length = _endIndex - _startIndex;
		uint64[] memory indexes = new uint64[](length);
		for (uint i = 0; i < length; i++)	{
			indexes[i] = forSalePixelconIndexes[_startIndex + i];
		}
		return indexes;
	}


	 
	 
	 

	 
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4) 
	{
		 
		require(systemLock == LOCK_NONE, "Market is currently locked");
		require(msg.sender == address(pixelconsContract), "Market only accepts transfers from the PixelCons contract");
		require(_tokenId != uint256(0), "Invalid token ID");
		require(_operator != address(0), "Invalid operator address");
		require(_from != address(0), "Invalid from address");

		 
		require(_data.length == 32 * 3, "Incorrectly formatted data");
		uint256 startPrice;
		uint256 endPrice;
		uint256 duration;
		assembly {
			startPrice := mload(add(_data, 0x20))
			endPrice := mload(add(_data, 0x40))
			duration := mload(add(_data, 0x60))
		}

		 
		makeListing(_from, _tokenId, startPrice, endPrice, duration);

		 
		return ERC721_RECEIVED;
	}


	 
	 
	 

	 
	function clearListingData(address _seller, uint64 _pixelconIndex) internal 
	{
		Listing storage listing = marketPixelconListings[_pixelconIndex];

		 
		uint64[] storage sellerTokens = sellerPixelconIndexes[_seller];
		uint64 replacementSellerTokenIndex = sellerTokens[sellerTokens.length - 1];
		delete sellerTokens[sellerTokens.length - 1];
		sellerTokens.length--;
		if (listing.sellerIndex < sellerTokens.length) {
			 
			sellerTokens[listing.sellerIndex] = replacementSellerTokenIndex;
			marketPixelconListings[replacementSellerTokenIndex].sellerIndex = listing.sellerIndex;
		}

		 
		uint64 replacementForSaleTokenIndex = forSalePixelconIndexes[forSalePixelconIndexes.length - 1];
		delete forSalePixelconIndexes[forSalePixelconIndexes.length - 1];
		forSalePixelconIndexes.length--;
		if (listing.forSaleIndex < forSalePixelconIndexes.length) {
			 
			forSalePixelconIndexes[listing.forSaleIndex] = replacementForSaleTokenIndex;
			marketPixelconListings[replacementForSaleTokenIndex].forSaleIndex = listing.forSaleIndex;
		}

		 
		delete marketPixelconListings[_pixelconIndex];
	}

	 
	function calcCurrentPrice(uint256 _startAmount, uint256 _endAmount, uint256 _startDate, uint256 _duration) internal view returns(uint256) 
	{
		uint256 timeDelta = now - _startDate;
		if (timeDelta > _duration) return uint256(0);

		timeDelta = timeDelta / uint256(priceUpdateInterval);
		uint256 durationTotal = _duration / uint256(priceUpdateInterval);
		return (_startAmount - ((_startAmount - _endAmount) * timeDelta) / durationTotal) * WEI_PER_GWEI;
	}

	 
	function calcTimeLeft(uint256 _startDate, uint256 _duration) internal view returns(uint64) 
	{
		uint256 timeDelta = now - _startDate;
		if (timeDelta > _duration) return uint64(0);

		return uint64(_duration - timeDelta);
	}
}


 
contract PixelCons {

	 
	function transferFrom(address _from, address _to, uint256 _tokenId) public;
	
	 
	function getTokenIndex(uint256 _tokenId) public view returns(uint64);

	 
	function tokenByIndex(uint256 _tokenIndex) public view returns(uint256);
}