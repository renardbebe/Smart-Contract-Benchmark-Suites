 

contract Administrable {
    using SafeMath for uint256;
    mapping (address => bool) private admins;
    uint256 private _nAdmin;
    uint256 private _nLimit;

    event Activated(address indexed admin);
    event Deactivated(address indexed admin);

     
    constructor() internal {
        _setAdminLimit(2);
        _activateAdmin(msg.sender);
    }

    function isAdmin() public view returns(bool) {
        return admins[msg.sender];
    }

     
    modifier onlyAdmin() {
        require(isAdmin(), "sender not admin");
        _;
    }

    function activateAdmin(address admin) external onlyAdmin {
        _activateAdmin(admin);
    }

    function deactivateAdmin(address admin) external onlyAdmin {
        _safeDeactivateAdmin(admin);
    }

    function setAdminLimit(uint256 n) external onlyAdmin {
        _setAdminLimit(n);
    }

    function _setAdminLimit(uint256 n) internal {
        require(_nLimit != n, "same limit");
        _nLimit = n;
    }

     
    function _activateAdmin(address admin) internal {
        require(admin != address(0), "invalid address");
        require(_nAdmin < _nLimit, "too many admins existed");
        require(!admins[admin], "already admin");
        admins[admin] = true;
        _nAdmin = _nAdmin.add(1);
        emit Activated(admin);
    }

     
    function _safeDeactivateAdmin(address admin) internal {
        require(_nAdmin > 1, "admin should > 1");
        _deactivateAdmin(admin);
    }

    function _deactivateAdmin(address admin) internal {
        require(admins[admin], "not admin");
        admins[admin] = false;
        _nAdmin = _nAdmin.sub(1);
        emit Deactivated(admin);
    }
}

library ErrorHandler {
    function errorHandler(bytes memory ret) internal pure {
        if (ret.length > 0) {
            byte ec = abi.decode(ret, (byte));
            if (ec != 0x00)
                revert(byteToHexString(ec));
        }
    }

    function byteToHexString(byte data) internal pure returns (string memory ret) {
        bytes memory ec = bytes("0x00");
        byte dataL = data & 0x0f;
        byte dataH = data >> 4;
        if (dataL < 0x0a)
            ec[3] = byte(uint8(ec[3]) + uint8(dataL));
        else
            ec[3] = byte(uint8(ec[3]) + uint8(dataL) + 0x27);
        if (dataH < 0x0a)
            ec[2] = byte(uint8(ec[2]) + uint8(dataH));
        else
            ec[2] = byte(uint8(ec[2]) + uint8(dataH) + 0x27);

        return string(ec);
    }
}

library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

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

library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Proxy is Ownable {
    using Address for address;

     
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x3b2ff02c0f36dba7cc1b20a669e540b974575f04ef71846d482983efb03bebb4;

    event Upgraded(address indexed implementation);

    constructor(address implementation) internal {
        assert(IMPLEMENTATION_SLOT == keccak256("dinngo.proxy.implementation"));
        _setImplementation(implementation);
    }

     
    function upgrade(address implementation) external onlyOwner {
        _setImplementation(implementation);
        emit Upgraded(implementation);
    }

     
    function _setImplementation(address implementation) internal {
        require(implementation.isContract(),
            "Implementation address should be a contract address"
        );
        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, implementation)
        }
    }

     
    function _implementation() internal view returns (address implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            implementation := sload(slot)
        }
    }
}

contract TimelockUpgradableProxy is Proxy {
     
    bytes32 private constant REGISTRATION_SLOT =
        0x90215db359d12011b32ff0c897114c39e26956599904ee846adb0dd49f782e97;
     
    bytes32 private constant TIME_SLOT =
        0xe89d1a29650bdc8a918bc762afb8ef07e10f6180e461c3fc305f9f142e5591e6;
    uint256 private constant UPGRADE_TIME = 14 days;

    event UpgradeAnnounced(address indexed implementation, uint256 time);

    constructor() internal {
        assert(REGISTRATION_SLOT == keccak256("dinngo.proxy.registration"));
        assert(TIME_SLOT == keccak256("dinngo.proxy.time"));
    }

     
    function register(address implementation) external onlyOwner {
        _registerImplementation(implementation);
        emit UpgradeAnnounced(implementation, _time());
    }

     
    function upgrade(address implementation) external {
        require(implementation == _registration());
        upgradeAnnounced();
    }

     
    function upgradeAnnounced() public onlyOwner {
        require(now >= _time());
        _setImplementation(_registration());
        emit Upgraded(_registration());
    }

     
    function _registerImplementation(address implementation) internal {
        require(implementation.isContract(),
            "Implementation address should be a contract address"
        );
        uint256 time = now + UPGRADE_TIME;

        bytes32 implSlot = REGISTRATION_SLOT;
        bytes32 timeSlot = TIME_SLOT;

        assembly {
            sstore(implSlot, implementation)
            sstore(timeSlot, time)
        }
    }

     
    function _time() internal view returns (uint256 time) {
        bytes32 slot = TIME_SLOT;

        assembly {
            time := sload(slot)
        }
    }

     
    function _registration() internal view returns (address implementation) {
        bytes32 slot = REGISTRATION_SLOT;

        assembly {
            implementation := sload(slot)
        }
    }
}

contract DinngoProxy is Ownable, Administrable, TimelockUpgradableProxy {
    using ErrorHandler for bytes;

    uint256 public processTime;

    mapping (address => mapping (address => uint256)) public balances;
    mapping (bytes32 => uint256) public orderFills;
    mapping (uint256 => address payable) public userID_Address;
    mapping (uint256 => address) public tokenID_Address;
    mapping (address => uint256) public userRanks;
    mapping (address => uint256) public tokenRanks;
    mapping (address => uint256) public lockTimes;

     
    constructor(
        address payable dinngoWallet,
        address dinngoToken,
        address impl
    ) Proxy(impl) public {
        processTime = 90 days;
        userID_Address[0] = dinngoWallet;
        userRanks[dinngoWallet] = 255;
        tokenID_Address[0] = address(0);
        tokenID_Address[1] = dinngoToken;
    }

     
    function() external payable {
        revert();
    }

     
    function addUser(uint256 id, address user) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("addUser(uint256,address)", id, user)
        );
        require(ok);
    }

     
    function removeUser(address user) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("removeUser(address)", user)
        );
        require(ok);
    }

     
    function updateUserRank(address user, uint256 rank) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("updateUserRank(address,uint256)",user, rank)
        );
        require(ok);
    }

     
    function addToken(uint256 id, address token) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("addToken(uint256,address)", id, token)
        );
        require(ok);
    }

     
    function removeToken(address token) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("removeToken(address)", token)
        );
        require(ok);
    }

     
    function updateTokenRank(address token, uint256 rank) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("updateTokenRank(address,uint256)", token, rank)
        );
        require(ok);
    }

    function activateAdmin(address admin) external onlyOwner {
        _activateAdmin(admin);
    }

    function deactivateAdmin(address admin) external onlyOwner {
        _safeDeactivateAdmin(admin);
    }

     
    function forceDeactivateAdmin(address admin) external onlyOwner {
        _deactivateAdmin(admin);
    }

    function setAdminLimit(uint256 n) external onlyOwner {
        _setAdminLimit(n);
    }

     
    function deposit() external payable {
        (bool ok,) = _implementation().delegatecall(abi.encodeWithSignature("deposit()"));
        require(ok);
    }

     
    function depositToken(address token, uint256 amount) external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("depositToken(address,uint256)", token, amount)
        );
        require(ok);
    }

     
    function withdraw(uint256 amount) external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        require(ok);
    }

     
    function withdrawToken(address token, uint256 amount) external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("withdrawToken(address,uint256)", token, amount)
        );
        require(ok);
    }

     
    function withdrawByAdmin(bytes calldata withdrawal) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("withdrawByAdmin(bytes)", withdrawal)
        );
        require(ok);
        ret.errorHandler();
    }

     
    function settle(bytes calldata orders) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("settle(bytes)", orders)
        );
        require(ok);
        ret.errorHandler();
    }

     
    function migrateByAdmin(bytes calldata migration) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("migrateByAdmin(bytes)", migration)
        );
        require(ok);
        ret.errorHandler();
    }

     
    function lock() external {
        (bool ok,) = _implementation().delegatecall(abi.encodeWithSignature("lock()"));
        require(ok);
    }

     
    function unlock() external {
        (bool ok,) = _implementation().delegatecall(abi.encodeWithSignature("unlock()"));
        require(ok);
    }

     
    function changeProcessTime(uint256 time) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("changeProcessTime(uint256)", time)
        );
        require(ok);
    }
}