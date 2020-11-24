 

pragma solidity 0.4.24;

 

 
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

 

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

 

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
}

 

contract BaseAirdrop is Lockable {
    using SafeMath for uint;

    ERC20Token public token;

    address public tokenHolder;

    mapping(address => bool) public users;

    event AirdropToken(address indexed to, uint amount);

    constructor(address _token, address _tokenHolder) public {
        require(_token != address(0) && _tokenHolder != address(0));
        token = ERC20Token(_token);
        tokenHolder = _tokenHolder;
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s, uint amount) public whenNotLocked {
        if (users[msg.sender] || ecrecover(prefixedHash(amount), v, r, s) != owner) {
            revert();
        }
        users[msg.sender] = true;
        token.transferFrom(tokenHolder, msg.sender, amount);
        emit AirdropToken(msg.sender, amount);
    }

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

 

 
contract BITOXAirdrop is BaseAirdrop {

    constructor(address _token, address _tokenHolder) public BaseAirdrop(_token, _tokenHolder) {
        locked = true;
    }

     
    function() external payable {
        revert();
    }

     
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokens(address _someToken) public onlyOwner {
        ERC20Token someToken = ERC20Token(_someToken);
        uint balance = someToken.balanceOf(this);
        someToken.transfer(owner, balance);
    }
}