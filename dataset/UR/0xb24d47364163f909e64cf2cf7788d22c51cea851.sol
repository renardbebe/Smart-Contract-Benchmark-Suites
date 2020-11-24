 

pragma solidity ^0.4.25;

import "./wallet.sol";
import "./controllable.sol";

 
contract WalletDeployer is Controllable {

	event WalletCached(address wallet);
	event WalletDeployed(address wallet, address owner);

	mapping(address => address) public deployed;
	address[] public cached;

	address private ens;
	bytes32 private controllerName;
	bytes32 private oracleName;
	uint private spendLimit;

    constructor(address _ens, bytes32 _oracleName, bytes32 _controllerName, uint _spendLimit) Controllable(_ens, _controllerName) public {
		ens = _ens;
		controllerName = _controllerName;
		oracleName = _oracleName;
		spendLimit = _spendLimit;
	}

	function deployWallet(address owner) external onlyController {
		if (cached.length < 1) {
			cacheWallet();
		}
		address walletAddress = cached[cached.length-1];
		cached.length--;
		Wallet(walletAddress).transferOwnership(owner);
		deployed[owner]=walletAddress;
		emit WalletDeployed(walletAddress, owner);
	}

	function cacheWallet() public {
		address walletAddress = new Wallet(address(this), true, ens, oracleName, controllerName, spendLimit);
		cached.push(walletAddress);
		emit WalletCached(walletAddress);
	}

    function cachedContractCount() external view returns (uint) {
        return cached.length;
    }

}
