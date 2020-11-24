 

pragma solidity 0.4.24;

 

 
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

    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

     
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

     
    modifier whenLocked() {
        require(locked);
        _;
    }

     
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

     
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

 

interface SNPCToken {
    function owner() external returns (address);
    function pendingOwner() external returns (address);
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
    function assignReserved(address to_, uint8 group_, uint amount_) external;
}

 

contract BaseAirdrop is Lockable {
    using SafeMath for uint;

    SNPCToken public token;

    mapping(address => bool) public users;

    event AirdropToken(address indexed to, uint amount);

    constructor(address _token) public {
        require(_token != address(0));
        token = SNPCToken(_token);
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s, uint amount) public;

    function getAirdropStatus(address user) public constant returns (bool success) {
        return users[user];
    }

    function originalHash(uint amount) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "Signed for Airdrop",
                address(this),
                address(token),
                msg.sender,
                amount
            ));
    }

    function prefixedHash(uint amount) internal view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, originalHash(amount)));
    }
}

 

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
}

 

 
contract Withdrawal is Ownable {

     
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokens(address _someToken) public onlyOwner {
        ERC20Token someToken = ERC20Token(_someToken);
        uint balance = someToken.balanceOf(address(this));
        someToken.transfer(owner, balance);
    }
}

 

 
contract SelfDestructible is Ownable {

    function selfDestruct(uint8 v, bytes32 r, bytes32 s) public onlyOwner {
        if (ecrecover(prefixedHash(), v, r, s) != owner) {
            revert();
        }
        selfdestruct(owner);
    }

    function originalHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "Signed for Selfdestruct",
                address(this),
                msg.sender
            ));
    }

    function prefixedHash() internal view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, originalHash()));
    }
}

 

 
contract SNPCAirdrop is BaseAirdrop, Withdrawal, SelfDestructible {

    constructor(address _token) public BaseAirdrop(_token) {
        locked = true;
    }

    function getTokenOwnership() public onlyOwner {
        require(token.pendingOwner() == address(this));
        token.claimOwnership();
        require(token.owner() == address(this));
    }

    function releaseTokenOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        token.transferOwnership(newOwner);
        require(token.pendingOwner() == newOwner);
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s, uint amount) public whenNotLocked {
        if (users[msg.sender] || ecrecover(prefixedHash(amount), v, r, s) != owner) {
            revert();
        }
        users[msg.sender] = true;
        token.assignReserved(msg.sender, uint8(0x2), amount);
        emit AirdropToken(msg.sender, amount);
    }

     
    function() external payable {
        revert();
    }
}