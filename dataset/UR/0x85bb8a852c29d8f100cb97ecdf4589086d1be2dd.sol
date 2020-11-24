 

pragma solidity ^0.5.10;

import "./wallet.sol";
import "./controllable.sol";
import "./ensResolvable.sol";

 
contract WalletDeployer is ENSResolvable, Controllable {

    event CachedWallet(Wallet _wallet);
    event DeployedWallet(Wallet _wallet, address _owner);
    event MigratedWallet(Wallet _wallet, Wallet _oldWallet, address _owner);

     
    bytes32 public constant controllerNode = 0x7f2ce995617d2816b426c5c8698c5ec2952f7a34bb10f38326f74933d5893697;
    bytes32 public constant licenceNode = 0xd0ff8bd67f6e25e4e4b010df582a36a0ee9b78e49afe6cc1cff5dd5a83040330;
    bytes32 public constant tokenWhitelistNode = 0xe84f90570f13fe09f288f2411ff9cf50da611ed0c7db7f73d48053ffc974d396;

    mapping(address => address) public deployedWallets;
    Wallet[] public cachedWallets;

    address public ens;
    uint public defaultSpendLimit;

     
    constructor(address _ens, uint _defaultSpendLimit) ENSResolvable(_ens) Controllable(controllerNode) public {
        ens = _ens;
        defaultSpendLimit = _defaultSpendLimit;
    }

     
    function() external payable {}

     
    function cacheWallet() public {
        Wallet wallet = new Wallet(address(this), true, ens, tokenWhitelistNode, controllerNode, licenceNode, defaultSpendLimit);
        cachedWallets.push(wallet);
        emit CachedWallet(wallet);
    }

     
     
    function deployWallet(address payable _owner) external onlyController {
        if (cachedWallets.length < 1) {
            cacheWallet();
        }
        Wallet wallet = cachedWallets[cachedWallets.length-1];
        cachedWallets.pop();
        wallet.transferOwnership(_owner, false);
        deployedWallets[_owner] = address(wallet);
        emit DeployedWallet(wallet, _owner);
    }

     
     
     
     
     
    function migrateWallet(address payable _owner, Wallet _oldWallet, bool _initializedSpendLimit, bool _initializedGasTopUpLimit, bool _initializedWhitelist, uint _spendLimit, uint _gasTopUpLimit, address[] calldata _whitelistedAddresses) external onlyController {
        if (cachedWallets.length < 1) {
            cacheWallet();
    	}

        Wallet  wallet = cachedWallets[cachedWallets.length-1];
        cachedWallets.pop();

        if (_initializedSpendLimit) {
            wallet.setSpendLimit(_spendLimit);
        }
        if (_initializedGasTopUpLimit) {
            wallet.setGasTopUpLimit(_gasTopUpLimit);
        }
        if (_initializedWhitelist) {
            wallet.setWhitelist(_whitelistedAddresses);
        }

        wallet.transferOwnership(_owner, false);
        deployedWallets[_owner] = address(wallet);

        emit MigratedWallet(wallet, _oldWallet, _owner);
    }

     
    function cachedWalletsCount() external view returns (uint) {
        return cachedWallets.length;
    }

}
