 

pragma solidity 0.4.24;

contract ERC20 {
	function balanceOf(address who) public view returns (uint256);

	function transfer(address to, uint256 value) public returns (bool);

	function transferFrom(address _from, address _to, uint _value) external returns (bool);
}

contract Ownable {
	address public owner = 0x345aCaFA4314Bc2479a3aA7cCf8eb47f223C1d0e;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
}


 
contract Pausable is Ownable {
	event Pause();

	event Unpause();

	bool public paused = false;


	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenPaused() {
		require(paused);
		_;
	}

	 
	function pause() public onlyOwner whenNotPaused {
		paused = true;
		emit Pause();
	}

	 
	function unpause() public onlyOwner whenPaused {
		paused = false;
		emit Unpause();
	}
}

 
 
contract ERC721 {
	 
	function totalSupply() public view returns (uint total);

	function balanceOf(address owner) public view returns (uint balance);

	function ownerOf(uint tokenId) external view returns (address owner);

	function approve(address to, uint tokenId) external;

	function transfer(address to, uint tokenId) public;

	function transferFrom(address from, address to, uint tokenId) external;

	 
	event Transfer(address indexed from, address indexed to, uint tokenId);
	event Approval(address indexed owner, address indexed approved, uint tokenId);

	 
	function name() public view returns (string);

	function symbol() public view returns (string);

	function tokensOfOwner(address owner) external view returns (uint[] tokenIds);

	function tokenMetadata(uint tokenId, string preferredTransport) public view returns (string infoUrl);

	 
	function supportsInterface(bytes4 contractID) external view returns (bool);
}


contract ERC721Metadata {
	function getMetadata(uint tokenId, string preferredTransport) public view returns (bytes32[4] buffer, uint count);
}

contract CryptoversePreorderBonusAssets is Pausable, ERC721 {

	struct Item {
		ItemType typeId;
		ItemModel model;
		ItemManufacturer manufacturer;
		ItemRarity rarity;
		uint createTime;
		uint amount;
	}

	enum ItemType {VRCBox, VCXVault, SaiHead, SaiBody, SaiEarrings, MechHead, MechBody, MechLegs, MechRailgun, MechMachineGun, MechRocketLauncher}

	enum ItemModel {NC01, MK1, V1, V1_1, V2_1, M442_1, BG, Q3, TRFL405, BC, DES1, PlasmaS, BD, DRL, Casper, Kilo, Mega, Giga, Tera, Peta, Exa, EA}

	enum ItemManufacturer {BTC, VRC, ETH, Satoshipowered}

	enum ItemRarity {Common, Uncommon, Rare, Superior, Epic, Legendary, Unique}

	function name() public view returns (string){
		return "Cryptoverse Preorder Bonus Assets";
	}

	function symbol() public view returns (string){
		return "CPBA";
	}

	Item[] public items;

	mapping(uint => address) public itemIndexToOwner;

	mapping(address => uint) public ownershipTokenCount;

	mapping(uint => address) public itemIndexToApproved;

	function reclaimToken(ERC20 token) external onlyOwner {
		uint256 balance = token.balanceOf(this);
		token.transfer(owner, balance);
	}

	function _transfer(address from, address to, uint tokenId) internal {
		ownershipTokenCount[from]--;
		ownershipTokenCount[to]++;
		itemIndexToOwner[tokenId] = to;
		delete itemIndexToApproved[tokenId];

		emit Transfer(from, to, tokenId);
	}

	event CreateItem(uint id, ItemType typeId, ItemModel model, ItemManufacturer manufacturer, ItemRarity rarity, uint createTime, uint amount, address indexed owner);

	function createItem(ItemType typeId, ItemModel model, ItemManufacturer manufacturer, ItemRarity rarity, uint amount, address owner) internal returns (uint) {
		require(owner != address(0));

		Item memory item = Item(typeId, model, manufacturer, rarity, now, amount);

		uint newItemId = items.length;

		items.push(item);

		emit CreateItem(newItemId, typeId, model, manufacturer, rarity, now, amount, owner);

		ownershipTokenCount[owner]++;
		itemIndexToOwner[newItemId] = owner;

		return newItemId;
	}

	function tokensOfOwner(address owner) external view returns (uint[] ownerTokens) {
		uint tokenCount = balanceOf(owner);

		if (tokenCount == 0) {
			return new uint[](0);
		} else {
			ownerTokens = new uint[](tokenCount);
			uint totalItems = totalSupply();
			uint resultIndex = 0;

			for (uint itemId = 0; itemId < totalItems; itemId++) {
				if (itemIndexToOwner[itemId] == owner) {
					ownerTokens[resultIndex] = itemId;
					resultIndex++;
				}
			}

			return ownerTokens;
		}
	}

	function tokensInfoOfOwner(address owner) external view returns (uint[] ownerTokens) {
		uint tokenCount = balanceOf(owner);

		if (tokenCount == 0) {
			return new uint[](0);
		} else {
			ownerTokens = new uint[](tokenCount * 7);
			uint totalItems = totalSupply();
			uint k = 0;

			for (uint itemId = 0; itemId < totalItems; itemId++) {
				if (itemIndexToOwner[itemId] == owner) {
					Item item = items[itemId];
					ownerTokens[k++] = itemId;
					ownerTokens[k++] = uint(item.typeId);
					ownerTokens[k++] = uint(item.model);
					ownerTokens[k++] = uint(item.manufacturer);
					ownerTokens[k++] = uint(item.rarity);
					ownerTokens[k++] = item.createTime;
					ownerTokens[k++] = item.amount;
				}
			}

			return ownerTokens;
		}
	}

	function tokenInfo(uint itemId) external view returns (uint[] ownerTokens) {
		ownerTokens = new uint[](7);
		uint k = 0;

		Item item = items[itemId];
		ownerTokens[k++] = itemId;
		ownerTokens[k++] = uint(item.typeId);
		ownerTokens[k++] = uint(item.model);
		ownerTokens[k++] = uint(item.manufacturer);
		ownerTokens[k++] = uint(item.rarity);
		ownerTokens[k++] = item.createTime;
		ownerTokens[k++] = item.amount;
	}

	ERC721Metadata public erc721Metadata;

	bytes4 constant InterfaceSignature_ERC165 =
	bytes4(keccak256('supportsInterface(bytes4)'));

	bytes4 constant InterfaceSignature_ERC721 =
	bytes4(keccak256('name()')) ^
	bytes4(keccak256('symbol()')) ^
	bytes4(keccak256('totalSupply()')) ^
	bytes4(keccak256('balanceOf(address)')) ^
	bytes4(keccak256('ownerOf(uint)')) ^
	bytes4(keccak256('approve(address,uint)')) ^
	bytes4(keccak256('transfer(address,uint)')) ^
	bytes4(keccak256('transferFrom(address,address,uint)')) ^
	bytes4(keccak256('tokensOfOwner(address)')) ^
	bytes4(keccak256('tokenMetadata(uint,string)'));

	function supportsInterface(bytes4 contractID) external view returns (bool)
	{
		return ((contractID == InterfaceSignature_ERC165) || (contractID == InterfaceSignature_ERC721));
	}

	function setMetadataAddress(address contractAddress) public onlyOwner {
		erc721Metadata = ERC721Metadata(contractAddress);
	}

	function _owns(address claimant, uint tokenId) internal view returns (bool) {
		return itemIndexToOwner[tokenId] == claimant;
	}

	function _approvedFor(address claimant, uint tokenId) internal view returns (bool) {
		return itemIndexToApproved[tokenId] == claimant;
	}

	function _approve(uint tokenId, address approved) internal {
		itemIndexToApproved[tokenId] = approved;
	}

	function balanceOf(address owner) public view returns (uint count) {
		return ownershipTokenCount[owner];
	}

	function transfer(address to, uint tokenId) public {
		require(to != address(0));
		require(_owns(msg.sender, tokenId));
		require(!_owns(to, tokenId));
		_transfer(msg.sender, to, tokenId);
	}

	function approve(address to, uint tokenId) external {
		require(_owns(msg.sender, tokenId));
		_approve(tokenId, to);
		emit Approval(msg.sender, to, tokenId);
	}

	function transferFrom(address from, address to, uint tokenId) external {
		require(to != address(0));
		require(to != address(this));
		require(_approvedFor(msg.sender, tokenId));
		require(_owns(from, tokenId));
		_transfer(from, to, tokenId);
	}

	function totalSupply() public view returns (uint) {
		return items.length;
	}

	function ownerOf(uint tokenId) external view returns (address owner)   {
		owner = itemIndexToOwner[tokenId];

		require(owner != address(0));
	}

	 
	 
	 
	function _memcpy(uint _dest, uint _src, uint _len) private pure {
		 
		for (; _len >= 32; _len -= 32) {
			assembly {
				mstore(_dest, mload(_src))
			}
			_dest += 32;
			_src += 32;
		}

		 
		uint mask = 256 ** (32 - _len) - 1;
		assembly {
			let srcpart := and(mload(_src), not(mask))
			let destpart := and(mload(_dest), mask)
			mstore(_dest, or(destpart, srcpart))
		}
	}

	 
	 
	 
	function _toString(bytes32[4] _rawBytes, uint _stringLength) private pure returns (string) {
		var outputString = new string(_stringLength);
		uint outputPtr;
		uint bytesPtr;

		assembly {
			outputPtr := add(outputString, 32)
			bytesPtr := _rawBytes
		}

		_memcpy(outputPtr, bytesPtr, _stringLength);

		return outputString;
	}

	 
	 
	 
	function tokenMetadata(uint _tokenId, string _preferredTransport) public view returns (string infoUrl) {
		require(erc721Metadata != address(0));
		bytes32[4] memory buffer;
		uint count;
		(buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

		return _toString(buffer, count);
	}
}

contract CryptoversePreorder is CryptoversePreorderBonusAssets {

	ERC20 public vrc;
	ERC20 public vcx;

	address public vrcWallet;
	address public vcxWallet;

	uint public vrcCount;
	uint public vcxCount;

	uint public weiRaised;

	uint public constant minInvest = 0.1 ether;

	uint public contributorsCompleteCount;

	mapping(address => uint) public contributorBalance;
	mapping(address => bool) public contributorComplete;
	mapping(address => uint) public contributorWhiteListTime;

	uint public constant hardCap = 50000 ether;

	address[] public contributors;

	event Purchase(address indexed contributor, uint weiAmount);

	function() public payable {
		buyTokens(msg.sender);
	}

	function createSaiLimitedEdition(uint weiAmount, address contributor) private {
		createItem(ItemType.SaiHead, ItemModel.M442_1, ItemManufacturer.Satoshipowered, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.SaiBody, ItemModel.M442_1, ItemManufacturer.Satoshipowered, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.SaiEarrings, ItemModel.V1_1, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
	}

	function createSaiCollectorsEdition(uint weiAmount, address contributor) private {
		createItem(ItemType.SaiHead, ItemModel.V2_1, ItemManufacturer.Satoshipowered, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.SaiBody, ItemModel.V2_1, ItemManufacturer.Satoshipowered, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.SaiEarrings, ItemModel.V1_1, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
	}

	function createSaiFoundersEdition(uint weiAmount, address contributor) private {
		createItem(ItemType.SaiHead, ItemModel.V1, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.SaiBody, ItemModel.V1, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.SaiEarrings, ItemModel.V1_1, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
	}

	function createVRCBox(ItemModel model, uint weiAmount, address contributor) private {
		createItem(ItemType.VRCBox, model, ItemManufacturer.Satoshipowered, ItemRarity.Legendary, weiAmount, contributor);
	}

	function createVCXVault(uint weiAmount, address contributor) private {
		createItem(ItemType.VCXVault, ItemModel.EA, ItemManufacturer.Satoshipowered, ItemRarity.Unique, weiAmount, contributor);
	}

	function createMechBTC(uint weiAmount, address contributor) private {
		createItem(ItemType.MechHead, ItemModel.NC01, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.MechBody, ItemModel.NC01, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.MechLegs, ItemModel.NC01, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.MechRailgun, ItemModel.BG, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.MechMachineGun, ItemModel.BC, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
		createItem(ItemType.MechRocketLauncher, ItemModel.BD, ItemManufacturer.BTC, ItemRarity.Epic, weiAmount, contributor);
	}

	function createMechVRC(uint weiAmount, address contributor) private {
		createItem(ItemType.MechHead, ItemModel.MK1, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.MechBody, ItemModel.MK1, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.MechLegs, ItemModel.MK1, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.MechRailgun, ItemModel.Q3, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.MechMachineGun, ItemModel.DES1, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
		createItem(ItemType.MechRocketLauncher, ItemModel.DRL, ItemManufacturer.VRC, ItemRarity.Legendary, weiAmount, contributor);
	}

	function createMechETH(uint weiAmount, address contributor) private {
		createItem(ItemType.MechHead, ItemModel.V1, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.MechBody, ItemModel.V1, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.MechLegs, ItemModel.V1, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.MechRailgun, ItemModel.TRFL405, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.MechMachineGun, ItemModel.PlasmaS, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
		createItem(ItemType.MechRocketLauncher, ItemModel.Casper, ItemManufacturer.ETH, ItemRarity.Unique, weiAmount, contributor);
	}

	function buyTokens(address contributor) public whenNotPaused payable {
		require(contributor != address(0));

		uint weiAmount = msg.value;

		require(weiAmount >= minInvest);

		weiRaised += weiAmount;

		require(weiRaised <= hardCap);

		emit Purchase(contributor, weiAmount);

		if (contributorBalance[contributor] == 0) {
			contributors.push(contributor);
			contributorBalance[contributor] += weiAmount;
			contributorWhiteListTime[contributor] = now;
		} else {
			require(!contributorComplete[contributor]);
			require(weiAmount >= contributorBalance[contributor] * 99);

			bool hasBonus = (now - contributorWhiteListTime[contributor]) < 72 hours;

			contributorBalance[contributor] += weiAmount;
			sendTokens(contributorBalance[contributor], contributor, hasBonus);

			contributorComplete[contributor] = true;
			contributorsCompleteCount++;
		}
	}

	function sendTokens(uint balance, address contributor, bool hasBonus) private {

		if (balance < 40 ether) {
			createMechBTC(balance, contributor);
			createSaiLimitedEdition(balance, contributor);
			createVRCBox(ItemModel.Kilo, balance, contributor);
			createVCXVault(balance, contributor);

		} else if (balance < 100 ether) {
			createMechBTC(balance, contributor);
			createMechVRC(balance, contributor);
			createSaiLimitedEdition(balance, contributor);

			createVRCBox(ItemModel.Mega, hasBonus ? (balance * 105 / 100) : balance, contributor);
			createVCXVault(balance, contributor);

		} else if (balance < 500 ether) {
			createMechBTC(balance, contributor);
			createMechVRC(balance, contributor);
			createMechETH(balance, contributor);
			createSaiCollectorsEdition(balance, contributor);

			createVRCBox(ItemModel.Giga, hasBonus ? (balance * 110 / 100) : balance, contributor);
			createVCXVault(balance, contributor);

		} else if (balance < 1000 ether) {

			createMechBTC(balance, contributor);
			createMechVRC(balance, contributor);
			createMechETH(balance, contributor);
			createSaiCollectorsEdition(balance, contributor);

			createVRCBox(ItemModel.Tera, hasBonus ? (balance * 115 / 100) : balance, contributor);
			createVCXVault(balance, contributor);

		} else if (balance < 5000 ether) {

			createMechBTC(balance, contributor);
			createMechVRC(balance, contributor);
			createMechETH(balance, contributor);
			createSaiFoundersEdition(balance, contributor);


			createVRCBox(ItemModel.Peta, hasBonus ? (balance * 120 / 100) : balance, contributor);
			createVCXVault(balance, contributor);

		} else if (balance >= 5000 ether) {

			createMechBTC(balance, contributor);
			createMechVRC(balance, contributor);
			createMechETH(balance, contributor);
			createSaiFoundersEdition(balance, contributor);


			createVRCBox(ItemModel.Exa, hasBonus ? (balance * 135 / 100) : balance, contributor);
			createVCXVault(balance, contributor);

		}
	}

	function withdrawal(uint amount) public onlyOwner {
		owner.transfer(amount);
	}

	function contributorsCount() public view returns (uint){
		return contributors.length;
	}

	function setVRC(address _vrc, address _vrcWallet, uint _vrcCount) public onlyOwner {
		require(_vrc != address(0));
		require(_vrcWallet != address(0));
		require(_vrcCount > 0);

		vrc = ERC20(_vrc);
		vrcWallet = _vrcWallet;
		vrcCount = _vrcCount;
	}

	function setVCX(address _vcx, address _vcxWallet, uint _vcxCount) public onlyOwner {
		require(_vcx != address(0));
		require(_vcxWallet != address(0));
		require(_vcxCount > 0);

		vcx = ERC20(_vcx);
		vcxWallet = _vcxWallet;
		vcxCount = _vcxCount;
	}

	function getBoxes(address contributor) public view returns (uint[] boxes) {
		uint tokenCount = balanceOf(contributor);

		if (tokenCount == 0) {
			return new uint[](0);
		} else {
			uint[] memory _boxes = new uint[](tokenCount);
			uint totalItems = totalSupply();
			uint n = 0;

			for (uint itemId = 0; itemId < totalItems; itemId++) {
				if (itemIndexToOwner[itemId] == contributor && isBoxItemId(itemId)) {
					_boxes[n++] = itemId;
				}
			}

			boxes = new uint[](n);

			for (uint i = 0; i < n; i++) {
				boxes[i] = _boxes[i];
			}
			return boxes;
		}
	}

	function isBox(Item item) private pure returns (bool){
		return item.typeId == ItemType.VRCBox || item.typeId == ItemType.VCXVault;
	}

	function isBoxItemId(uint itemId) public view returns (bool){
		return isBox(items[itemId]);
	}

	function openBoxes(uint[] itemIds) public {
		for (uint i = 0; i < itemIds.length; i++) {
			uint itemId = itemIds[i];
			Item storage item = items[itemId];
			require(isBox(item));

			transfer(this, itemId);

			if (item.typeId == ItemType.VRCBox) {
				vrc.transferFrom(vrcWallet, msg.sender, item.amount * vrcCount / weiRaised);
			} else {
				vcx.transferFrom(vcxWallet, msg.sender, item.amount * vcxCount / weiRaised);
			}
		}
	}
}