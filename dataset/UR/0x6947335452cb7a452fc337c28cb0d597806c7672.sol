 

pragma solidity ^0.4.24;


 
contract SmartWeddingContract {
	event WrittenContractProposed(uint timestamp, string ipfsHash, address wallet);
	event Signed(uint timestamp, address wallet);
	event ContractSigned(uint timestamp);
	event AssetProposed(uint timestamp, string asset, address wallet);
	event AssetAddApproved(uint timestamp, string asset, address wallet);
	event AssetAdded(uint timestamp, string asset);
	event AssetRemoveApproved(uint timestamp, string asset, address wallet);
	event AssetRemoved(uint timestamp, string asset);
	event DivorceApproved(uint timestamp, address wallet);
	event Divorced(uint timestamp);
	event FundsSent(uint timestamp, address wallet, uint amount);
	event FundsReceived(uint timestamp, address wallet, uint amount);

	bool public signed = false;
	bool public divorced = false;

	mapping (address => bool) private hasSigned;
	mapping (address => bool) private hasDivorced;

	address public husbandAddress;
	address public wifeAddress;
	string public writtenContractIpfsHash;

	struct Asset {
		string data;
		uint husbandAllocation;
		uint wifeAllocation;
		bool added;
		bool removed;
		mapping (address => bool) hasApprovedAdd;
		mapping (address => bool) hasApprovedRemove;
	}

	Asset[] public assets;

	 
	modifier onlySpouse() {
		require(msg.sender == husbandAddress || msg.sender == wifeAddress, "Sender is not a spouse!");
		_;
	}

	 
	modifier isSigned() {
		require(signed == true, "Contract has not been signed by both spouses yet!");
		_;
	}

	 
	modifier isNotDivorced() {
		require(divorced == false, "Can not be called after spouses agreed to divorce!");
		_;
	}

	 
	function isSameString(string memory string1, string memory string2) private pure returns (bool) {
		return keccak256(abi.encodePacked(string1)) != keccak256(abi.encodePacked(string2));
	}

	 
	constructor(address _husbandAddress, address _wifeAddress) public {
		require(_husbandAddress != address(0), "Husband address must not be zero!");
		require(_wifeAddress != address(0), "Wife address must not be zero!");
		require(_husbandAddress != _wifeAddress, "Husband address must not equal wife address!");

		husbandAddress = _husbandAddress;
		wifeAddress = _wifeAddress;
	}

	 
	function() external payable isSigned isNotDivorced {
		emit FundsReceived(now, msg.sender, msg.value);
	}

	 
	function proposeWrittenContract(string _writtenContractIpfsHash) external onlySpouse {
		require(signed == false, "Written contract ipfs hash can not be changed. Both spouses have already signed it!");

		 
		writtenContractIpfsHash = _writtenContractIpfsHash;

		emit WrittenContractProposed(now, _writtenContractIpfsHash, msg.sender);

		 
		if (hasSigned[husbandAddress] == true) {
			hasSigned[husbandAddress] = false;
		}
		if (hasSigned[wifeAddress] == true) {
			hasSigned[wifeAddress] = false;
		}
	}

	 
	function signContract() external onlySpouse {
		require(isSameString(writtenContractIpfsHash, ""), "Written contract ipfs hash has been proposed yet!");
		require(hasSigned[msg.sender] == false, "Spouse has already signed the contract!");

		 
		hasSigned[msg.sender] = true;

		emit Signed(now, msg.sender);

		 
		if (hasSigned[husbandAddress] && hasSigned[wifeAddress]) {
			signed = true;
			emit ContractSigned(now);
		}
	}

	 
	function pay(address _to, uint _amount) external onlySpouse isSigned isNotDivorced {
		require(_to != address(0), "Sending funds to address zero is prohibited!");
		require(_amount <= address(this).balance, "Not enough balance available!");

		 
		_to.transfer(_amount);

		emit FundsSent(now, _to, _amount);
	}

	 
	function proposeAsset(string _data, uint _husbandAllocation, uint _wifeAllocation) external onlySpouse isSigned isNotDivorced {
		require(isSameString(_data, ""), "No asset data provided!");
		require(_husbandAllocation >= 0, "Husband allocation invalid!");
		require(_wifeAllocation >= 0, "Wife allocation invalid!");
		require((_husbandAllocation + _wifeAllocation) == 100, "Total allocation must be equal to 100%!");

		 
		Asset memory newAsset = Asset({
			data: _data,
			husbandAllocation: _husbandAllocation,
			wifeAllocation: _wifeAllocation,
			added: false,
			removed: false
		});
		uint newAssetId = assets.push(newAsset);

		emit AssetProposed(now, _data, msg.sender);

		 
		Asset storage asset = assets[newAssetId - 1];

		 
		asset.hasApprovedAdd[msg.sender] = true;

		emit AssetAddApproved(now, _data, msg.sender);
	}

	 
	function approveAsset(uint _assetId) external onlySpouse isSigned isNotDivorced {
		require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");

		Asset storage asset = assets[_assetId - 1];

		require(asset.added == false, "Asset has already been added!");
		require(asset.removed == false, "Asset has already been removed!");
		require(asset.hasApprovedAdd[msg.sender] == false, "Asset has already approved by sender!");

		 
		asset.hasApprovedAdd[msg.sender] = true;

		emit AssetAddApproved(now, asset.data, msg.sender);

		 
		if (asset.hasApprovedAdd[husbandAddress] && asset.hasApprovedAdd[wifeAddress]) {
			asset.added = true;
			emit AssetAdded(now, asset.data);
		}
	}

	 
	function removeAsset(uint _assetId) external onlySpouse isSigned isNotDivorced {
		require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");

		Asset storage asset = assets[_assetId - 1];

		require(asset.added, "Asset has not been added yet!");
		require(asset.removed == false, "Asset has already been removed!");
		require(asset.hasApprovedRemove[msg.sender] == false, "Removing the asset has already been approved by the sender!");

		 
		asset.hasApprovedRemove[msg.sender] = true;

		emit AssetRemoveApproved(now, asset.data, msg.sender);

		 
		if (asset.hasApprovedRemove[husbandAddress] && asset.hasApprovedRemove[wifeAddress]) {
			asset.removed = true;
			emit AssetRemoved(now, asset.data);
		}
	}

	 
	function divorce() external onlySpouse isSigned isNotDivorced {
		require(hasDivorced[msg.sender] == false, "Sender has already approved to divorce!");

		 
		hasDivorced[msg.sender] = true;

		emit DivorceApproved(now, msg.sender);

		 
		if (hasDivorced[husbandAddress] && hasDivorced[wifeAddress]) {
			divorced = true;
			emit Divorced(now);

			 
			uint balance = address(this).balance;

			 
			if (balance != 0) {
				uint balancePerSpouse = balance / 2;

				 
				husbandAddress.transfer(balancePerSpouse);
				emit FundsSent(now, husbandAddress, balancePerSpouse);

				 
				wifeAddress.transfer(balancePerSpouse);
				emit FundsSent(now, wifeAddress, balancePerSpouse);
			}
		}
	}

	 
	function getAssetIds() external view returns (uint[]) {
		uint assetCount = assets.length;
		uint[] memory assetIds = new uint[](assetCount);

		 
		for (uint i = 1; i <= assetCount; i++) { assetIds[i - 1] = i; }

		return assetIds;
	}
}