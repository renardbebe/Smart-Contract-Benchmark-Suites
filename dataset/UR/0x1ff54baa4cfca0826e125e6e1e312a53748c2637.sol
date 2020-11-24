 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract LimeEyes {

	 
	 


	address private _dev;

	struct Artwork {
		string _title;
		address _owner;
		bool _visible;
		uint256 _basePrice;
		uint256 _purchases;
		address[] _shareholders;
		mapping (address => bool) _hasShares;
		mapping (address => uint256) _shares;
	}
	Artwork[] private _artworks;

	event ArtworkCreated(
		uint256 artworkId,
		string title,
		address owner,
		uint256 basePrice);
	event ArtworkSharesPurchased(
		uint256 artworkId,
		string title,
		address buyer,
		uint256 sharesBought);


	 
	 


	function LimeEyes() public {
		_dev = msg.sender;
	}

	modifier onlyDev() {
		require(msg.sender == _dev);
		_;
	}

	 
	 
	 
	 
	 
	function createArtwork(string title, address owner, uint256 basePrice) public onlyDev {

		require(basePrice != 0);
		_artworks.push(Artwork({
			_title: title,
			_owner: owner,
			_visible: true,
			_basePrice: basePrice,
			_purchases: 0,
			_shareholders: new address[](0)
		}));
		uint256 artworkId = _artworks.length - 1;
		Artwork storage newArtwork = _artworks[artworkId];
		newArtwork._hasShares[owner] = true;
		newArtwork._shareholders.push(owner);
		newArtwork._shares[owner] = 1;

		ArtworkCreated(artworkId, title, owner, basePrice);

	}

	 
	 
	 
	function renameArtwork(uint256 artworkId, string newTitle) public onlyDev {
		
		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];
		artwork._title = newTitle;

	}

	 
	 
	 
	 
	 
	 
	function toggleArtworkVisibility(uint256 artworkId) public onlyDev {
		
		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];
		artwork._visible = !artwork._visible;

	}

	 
	 
	 
	 
	 
	 
	 
	function withdrawAmount(uint256 amount, address toAddress) public onlyDev {

		require(amount != 0);
		require(amount <= this.balance);
		toAddress.transfer(amount);

	}

	 
	function withdrawAll(address toAddress) public onlyDev {
		toAddress.transfer(this.balance);
	}


	 
	 


	 
	 
	 
	 
	 
	 
	 
	 
	function purchaseSharesOfArtwork(uint256 artworkId) public payable {

		 
		require(msg.sender == tx.origin);

		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];

		 
		 
		require(msg.sender != artwork._owner);

		uint256 totalShares;
		uint256[3] memory prices;
		( , , , prices, totalShares, , ) = getArtwork(artworkId);
		uint256 currentPrice = prices[1];

		 
		require(msg.value >= currentPrice);

		 
		uint256 purchaseExcess = msg.value - currentPrice;
		if (purchaseExcess > 0)
			msg.sender.transfer(purchaseExcess);

		 
		 
		for (uint256 i = 0; i < artwork._shareholders.length; i++) {
			address shareholder = artwork._shareholders[i];
			if (shareholder != address(this)) {  
				shareholder.transfer((currentPrice * artwork._shares[shareholder]) / totalShares);
			}
		}

		 
		if (!artwork._hasShares[msg.sender]) {
			artwork._hasShares[msg.sender] = true;
			artwork._shareholders.push(msg.sender);
		}

		artwork._purchases++;  
		artwork._shares[msg.sender] += artwork._purchases;  
		artwork._shares[artwork._owner] = artwork._purchases + 1;  

		ArtworkSharesPurchased(artworkId, artwork._title, msg.sender, artwork._purchases);
		
	}


	 
	 


	function _exists(uint256 artworkId) private view returns (bool) {
		return artworkId < _artworks.length;
	}

	function getArtwork(uint256 artworkId) public view returns (string artworkTitle, address ownerAddress, bool isVisible, uint256[3] artworkPrices, uint256 artworkShares, uint256 artworkPurchases, uint256 artworkShareholders) {
		
		require(_exists(artworkId));

		Artwork memory artwork = _artworks[artworkId];

		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		uint256 totalShares = ((artwork._purchases + 1) * (artwork._purchases + 2)) / 2;

		 
		 
		 
		 
		uint256[3] memory prices;
		prices[0] = artwork._basePrice;
		 
		 
		 
		 
		 
		prices[1] = (prices[0] * (100 + totalShares)) / 100;
		 
		 
		 
		prices[2] = (prices[0] * (100 + totalShares + (artwork._purchases + 2))) / 100;

		return (
				artwork._title,
				artwork._owner,
				artwork._visible,
				prices,
				totalShares,
				artwork._purchases,
				artwork._shareholders.length
			);

	}

	function getAllShareholdersOfArtwork(uint256 artworkId) public view returns (address[] shareholders, uint256[] shares) {

		require(_exists(artworkId));

		Artwork storage artwork = _artworks[artworkId];

		uint256[] memory shareholderShares = new uint256[](artwork._shareholders.length);
		for (uint256 i = 0; i < artwork._shareholders.length; i++) {
			address shareholder = artwork._shareholders[i];
			shareholderShares[i] = artwork._shares[shareholder];
		}

		return (
				artwork._shareholders,
				shareholderShares
			);

	}

	function getAllArtworks() public view returns (bytes32[] titles, address[] owners, bool[] isVisible, uint256[3][] artworkPrices, uint256[] artworkShares, uint256[] artworkPurchases, uint256[] artworkShareholders) {

		bytes32[] memory allTitles = new bytes32[](_artworks.length);
		address[] memory allOwners = new address[](_artworks.length);
		bool[] memory allIsVisible = new bool[](_artworks.length);
		uint256[3][] memory allPrices = new uint256[3][](_artworks.length);
		uint256[] memory allShares = new uint256[](_artworks.length);
		uint256[] memory allPurchases = new uint256[](_artworks.length);
		uint256[] memory allShareholders = new uint256[](_artworks.length);

		for (uint256 i = 0; i < _artworks.length; i++) {
			string memory tmpTitle;
			(tmpTitle, allOwners[i], allIsVisible[i], allPrices[i], allShares[i], allPurchases[i], allShareholders[i]) = getArtwork(i);
			allTitles[i] = stringToBytes32(tmpTitle);
		}

		return (
				allTitles,
				allOwners,
				allIsVisible,
				allPrices,
				allShares,
				allPurchases,
				allShareholders
			);

	}

	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
		bytes memory tmpEmptyStringTest = bytes(source);
		if (tmpEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly {
			result := mload(add(source, 32))
		}
	}

	
	 

}