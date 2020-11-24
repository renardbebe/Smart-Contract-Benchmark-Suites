 

pragma solidity ^0.5.0;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
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

pragma solidity ^0.5.0;


 
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
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
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

pragma solidity ^0.5.0;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.0;

 

contract ValidationUtil {
    function requireNotEmptyAddress(address value) internal view{
        require(isAddressNotEmpty(value));
    }

    function isAddressNotEmpty(address value) internal view returns (bool result){
        return value != address(0x0);
    }
}

pragma solidity ^0.5.0;

 

contract ImpMine is Ownable, Pausable, ValidationUtil {
    using ECDSA for bytes32;

     
    address payable private _destinationWallet;

     
    mapping (bytes32 => bool) private _userUpgrades;

     
    mapping (uint => uint) private _upgradePrices;

     
    event MineUpgraded(address receiver, uint mineId, uint level, uint buyPrice);

    function upgrade(uint mineId, uint level, bytes calldata signature) external payable validDestinationWallet whenNotPaused {
         
        require(msg.value != 0);

         
        bytes32 validatingHash = keccak256(abi.encodePacked(msg.sender, mineId, level));

         
        address addressRecovered = validatingHash.toEthSignedMessageHash().recover(signature);
        require(addressRecovered == owner());

         
        require(!_userUpgrades[validatingHash]);

         
        require(_upgradePrices[level] == msg.value);

         
        _destinationWallet.transfer(msg.value);

        _userUpgrades[validatingHash] = true;

        emit MineUpgraded(msg.sender, mineId, level, msg.value);
    }

    function isUserUpgraded(address userAddress, uint mineId, uint level) public view returns (bool) {
        return _userUpgrades[keccak256(abi.encodePacked(userAddress, mineId, level))];
    }

    function setUpgradePrice(uint level, uint price) external onlyOwner {
         
        require(price != 0);

        _upgradePrices[level] = price;
    }

    function getUpgradePrice(uint level) public view returns (uint) {
        return _upgradePrices[level];
    }

    function setDestinationWallet(address payable walletAddress) external onlyOwner {
        requireNotEmptyAddress(walletAddress);

        _destinationWallet = walletAddress;
    }

    function getDestinationWallet() public view returns (address) {
        return _destinationWallet;
    }

    modifier validDestinationWallet() {
        requireNotEmptyAddress(_destinationWallet);
        _;
    }
}