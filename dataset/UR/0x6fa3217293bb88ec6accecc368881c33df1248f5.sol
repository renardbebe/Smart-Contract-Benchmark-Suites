 

pragma solidity ^0.4.19;

 

contract BdpBaseData {

	address public ownerAddress;

	address public managerAddress;

	address[16] public contracts;

	bool public paused = false;

	bool public setupCompleted = false;

	bytes8 public version;

}

 

library BdpContracts {

	function getBdpEntryPoint(address[16] _contracts) pure internal returns (address) {
		return _contracts[0];
	}

	function getBdpController(address[16] _contracts) pure internal returns (address) {
		return _contracts[1];
	}

	function getBdpControllerHelper(address[16] _contracts) pure internal returns (address) {
		return _contracts[3];
	}

	function getBdpDataStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[4];
	}

	function getBdpImageStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[5];
	}

	function getBdpOwnershipStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[6];
	}

	function getBdpPriceStorage(address[16] _contracts) pure internal returns (address) {
		return _contracts[7];
	}

}

 

contract BdpBase is BdpBaseData {

	modifier onlyOwner() {
		require(msg.sender == ownerAddress);
		_;
	}

	modifier onlyAuthorized() {
		require(msg.sender == ownerAddress || msg.sender == managerAddress);
		_;
	}

	modifier whileContractIsActive() {
		require(!paused && setupCompleted);
		_;
	}

	modifier storageAccessControl() {
		require(
			(! setupCompleted && (msg.sender == ownerAddress || msg.sender == managerAddress))
			|| (setupCompleted && !paused && (msg.sender == BdpContracts.getBdpEntryPoint(contracts)))
		);
		_;
	}

	function setOwner(address _newOwner) external onlyOwner {
		require(_newOwner != address(0));
		ownerAddress = _newOwner;
	}

	function setManager(address _newManager) external onlyOwner {
		require(_newManager != address(0));
		managerAddress = _newManager;
	}

	function setContracts(address[16] _contracts) external onlyOwner {
		contracts = _contracts;
	}

	function pause() external onlyAuthorized {
		paused = true;
	}

	function unpause() external onlyOwner {
		paused = false;
	}

	function setSetupCompleted() external onlyOwner {
		setupCompleted = true;
	}

	function kill() public onlyOwner {
		selfdestruct(ownerAddress);
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

 

contract BdpOwnershipStorage is BdpBase {

	using SafeMath for uint256;

	 
	mapping (uint256 => address) public tokenOwner;

	 
	mapping (uint256 => address) public tokenApprovals;

	 
	mapping (address => uint256) public ownedArea;

	 
	mapping (address => uint256[]) public ownedTokens;

	 
	mapping(uint256 => uint256) public ownedTokensIndex;

	 
	uint256[] public tokenIds;

	 
	mapping (uint256 => uint256) public tokenIdsIndex;


	function getTokenOwner(uint256 _tokenId) view public returns (address) {
		return tokenOwner[_tokenId];
	}

	function setTokenOwner(uint256 _tokenId, address _owner) public storageAccessControl {
		tokenOwner[_tokenId] = _owner;
	}

	function getTokenApproval(uint256 _tokenId) view public returns (address) {
		return tokenApprovals[_tokenId];
	}

	function setTokenApproval(uint256 _tokenId, address _to) public storageAccessControl {
		tokenApprovals[_tokenId] = _to;
	}

	function getOwnedArea(address _owner) view public returns (uint256) {
		return ownedArea[_owner];
	}

	function setOwnedArea(address _owner, uint256 _area) public storageAccessControl {
		ownedArea[_owner] = _area;
	}

	function incrementOwnedArea(address _owner, uint256 _area) public storageAccessControl returns (uint256) {
		ownedArea[_owner] = ownedArea[_owner].add(_area);
		return ownedArea[_owner];
	}

	function decrementOwnedArea(address _owner, uint256 _area) public storageAccessControl returns (uint256) {
		ownedArea[_owner] = ownedArea[_owner].sub(_area);
		return ownedArea[_owner];
	}

	function getOwnedTokensLength(address _owner) view public returns (uint256) {
		return ownedTokens[_owner].length;
	}

	function getOwnedToken(address _owner, uint256 _index) view public returns (uint256) {
		return ownedTokens[_owner][_index];
	}

	function setOwnedToken(address _owner, uint256 _index, uint256 _tokenId) public storageAccessControl {
		ownedTokens[_owner][_index] = _tokenId;
	}

	function pushOwnedToken(address _owner, uint256 _tokenId) public storageAccessControl returns (uint256) {
		ownedTokens[_owner].push(_tokenId);
		return ownedTokens[_owner].length;
	}

	function decrementOwnedTokensLength(address _owner) public storageAccessControl {
		ownedTokens[_owner].length--;
	}

	function getOwnedTokensIndex(uint256 _tokenId) view public returns (uint256) {
		return ownedTokensIndex[_tokenId];
	}

	function setOwnedTokensIndex(uint256 _tokenId, uint256 _tokenIndex) public storageAccessControl {
		ownedTokensIndex[_tokenId] = _tokenIndex;
	}

	function getTokenIdsLength() view public returns (uint256) {
		return tokenIds.length;
	}

	function getTokenIdByIndex(uint256 _index) view public returns (uint256) {
		return tokenIds[_index];
	}

	function setTokenIdByIndex(uint256 _index, uint256 _tokenId) public storageAccessControl {
		tokenIds[_index] = _tokenId;
	}

	function pushTokenId(uint256 _tokenId) public storageAccessControl returns (uint256) {
		tokenIds.push(_tokenId);
		return tokenIds.length;
	}

	function decrementTokenIdsLength() public storageAccessControl {
		tokenIds.length--;
	}

	function getTokenIdsIndex(uint256 _tokenId) view public returns (uint256) {
		return tokenIdsIndex[_tokenId];
	}

	function setTokenIdsIndex(uint256 _tokenId, uint256 _tokenIdIndex) public storageAccessControl {
		tokenIdsIndex[_tokenId] = _tokenIdIndex;
	}

	function BdpOwnershipStorage(bytes8 _version) public {
		ownerAddress = msg.sender;
		managerAddress = msg.sender;
		version = _version;
	}

}