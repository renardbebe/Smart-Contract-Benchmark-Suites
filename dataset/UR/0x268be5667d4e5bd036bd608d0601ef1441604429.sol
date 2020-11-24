 

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

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

 

pragma solidity ^0.5.0;



 
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

     
    function implementationVersion() external view returns (uint256 version){
        (bool ok, bytes memory ret) = _implementation().staticcall(
            abi.encodeWithSignature("version()")
        );
        require(ok);
        assembly {
            version := mload(add(add(ret, 0x20), 0))
        }
        return version;
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;


 
 
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

 

pragma solidity 0.5.12;





 
contract DinngoProxy is Ownable, Administrable, Proxy {
    uint256 public processTime;

    mapping (address => mapping (address => uint256)) public balances;
    mapping (bytes32 => uint256) public orderFills;
    mapping (uint256 => address payable) public userID_Address;
    mapping (uint256 => address) public tokenID_Address;
    mapping (address => uint256) public nonces;
    mapping (address => uint256) public ranks;
    mapping (address => uint256) public lockTimes;

    address public walletOwner;
    address public DGOToken;
    uint8 public eventConf;

    uint256 constant public version = 2;

     
    constructor(
        address payable _walletOwner,
        address _dinngoToken,
        address _impl
    ) Proxy(_impl) public {
        processTime = 90 days;
        walletOwner = _walletOwner;
        tokenID_Address[0] = address(0);
        ranks[address(0)] = 1;
        tokenID_Address[1] = _dinngoToken;
        ranks[_dinngoToken] = 1;
        DGOToken = _dinngoToken;
        eventConf = 0xff;
    }

    function setEvent(uint8 conf) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("setEvent(uint8)", conf)
        );
        require(ok);
    }

     
    function addUser(uint256 id, address user) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("addUser(uint256,address)", id, user)
        );
        require(ok);
    }

     
    function removeUser(address user) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("remove(address)", user)
        );
        require(ok);
    }

     
    function updateUserRank(address user, uint256 rank) external onlyAdmin {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("updateRank(address,uint256)", user, rank)
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
            abi.encodeWithSignature("remove(address)", token)
        );
        require(ok);
    }

     
    function updateTokenRank(address token, uint256 rank) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("updateRank(address,uint256)", token, rank)
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

     
    function extractFee(uint256 amount) external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("extractFee(uint256)", amount)
        );
        require(ok);
    }

     
    function extractTokenFee(address token, uint256 amount) external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("extractTokenFee(address,uint256)", token, amount)
        );
        require(ok);
    }

     
    function getWalletBalance(address token) external returns (uint256 balance) {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("getWalletBalance(address)", token)
        );
        require(ok);
        balance = abi.decode(ret, (uint256));
    }

     
    function changeWalletOwner(address newOwner) external onlyOwner {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("changeWalletOwner(address)", newOwner)
        );
        require(ok);
    }

     
    function withdrawByAdmin(bytes calldata withdrawal, bytes calldata signature) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("withdrawByAdmin(bytes,bytes)", withdrawal, signature)
        );
        require(ok, string(ret));
    }

     
    function transferByAdmin(bytes calldata transferral, bytes calldata signature) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("transferByAdmin(bytes,bytes)", transferral, signature)
        );
        require(ok, string(ret));
    }

     
    function settle(bytes calldata orders, bytes calldata signature) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("settle(bytes,bytes)", orders, signature)
        );
        require(ok, string(ret));
    }

     
    function migrateByAdmin(bytes calldata migration, bytes calldata signature) external onlyAdmin {
        (bool ok, bytes memory ret) = _implementation().delegatecall(
            abi.encodeWithSignature("migrateByAdmin(bytes,bytes)", migration, signature)
        );
        require(ok, string(ret));
    }

     
    function migrateTo(address user, address token, uint256 amount) payable external {
        (bool ok,) = _implementation().delegatecall(
            abi.encodeWithSignature("migrateTo(address,address,uint256)", user, token, amount)
        );
        require(ok);
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

     
    function getTransferralHash(
        address from,
        uint8 config,
        uint32 nonce,
        address[] calldata tos,
        uint16[] calldata tokenIDs,
        uint256[] calldata amounts,
        uint256[] calldata fees
    ) external view returns (bytes32 hash) {
        (bool ok, bytes memory ret) = _implementation().staticcall(
            abi.encodeWithSignature(
                "getTransferralHash(address,uint8,uint32,address[],uint16[],uint256[],uint256[])",
                from, config, nonce, tos, tokenIDs, amounts, fees
            )
        );
        require(ok);
        hash = abi.decode(ret, (bytes32));
    }
}