 

pragma solidity 0.5.10;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


interface IWalletDeployer {

    function deploy(address owner) external returns (address);
}

 
contract WalletManager is Ownable, Pausable {

     
    mapping(address => address) private _userVsWallet;

     
    address[] private _users;

    IWalletDeployer private _walletDeployer;

    event WalletCreated(address indexed user, address indexed wallet);

    event WalletDeployerUpdated(address indexed walletDeployer);

    constructor(address walletDeployer) public {
        require(
            walletDeployer != address(0),
            "WalletManager: Invalid wallet deployer address!!"
        );

        _walletDeployer = IWalletDeployer(walletDeployer);
    }

     
    function getWallet(address user) external view returns(address) {
        return _userVsWallet[user];
    }

     
    function getUserCount() external view returns (uint256) {
        return _users.length;
    }

     
    function getUsers() external view returns(address[] memory) {
        return _users;
    }

     
    function getWalletDeployer() external view returns(address) {
        return address(_walletDeployer);
    }

     
    function setWalletDeployer(address newWalletDeployer) external onlyOwner {
        require(
            newWalletDeployer != address(0),
            "WalletManager: Invalid wallet deployer address!!"
        );
        _walletDeployer = IWalletDeployer(newWalletDeployer);

        emit WalletDeployerUpdated(newWalletDeployer);
    }

     
    function createWallet() external whenNotPaused {
        require(
            _userVsWallet[msg.sender] == address(0),
            "WalletManager: Wallet already exist for the user!!"
        );
        address wallet = _walletDeployer.deploy(msg.sender);

        _userVsWallet[msg.sender] = wallet;
        _users.push(msg.sender);

        emit WalletCreated(msg.sender, wallet);

    }


}