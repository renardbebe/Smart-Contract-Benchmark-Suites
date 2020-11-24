 

pragma solidity 0.4.23;

 

 
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
    function balanceOf(address owner_) external returns (uint);
    function transfer(address to_, uint value_) external returns (bool);
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
}

 

contract BaseAirdrop is Lockable {
    using SafeMath for uint;

    ERC20Token public token;

    mapping(address => bool) public users;

    event AirdropToken(address indexed to, uint amount);

    constructor(address _token) public {
        require(_token != address(0));
        token = ERC20Token(_token);
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s) public whenNotLocked {
        if (ecrecover(keccak256("Signed for Airdrop", address(this), address(token), msg.sender), v, r, s) != owner
            || users[msg.sender]) {
            revert();
        }
        users[msg.sender] = true;
        uint amount = getAirdropAmount(msg.sender);
        token.transfer(msg.sender, amount);
        emit AirdropToken(msg.sender, amount);
    }

    function getAirdropStatus(address user) public constant returns (bool success) {
        return users[user];
    }

    function getAirdropAmount(address user) public constant returns (uint amount);

    function withdrawTokens(address destination) public onlyOwner whenLocked {
        require(destination != address(0));
        uint balance = token.balanceOf(address(this));
        token.transfer(destination, balance);
    }
}

 

 
contract IONCAirdrop is BaseAirdrop {

    uint public constant PER_USER_AMOUNT = 20023e6;

    constructor(address _token) public BaseAirdrop(_token) {
        locked = true;
    }

     
    function() external payable {
        revert();
    }

    function getAirdropAmount(address user) public constant returns (uint amount) {
        require(user != address(0));
        return PER_USER_AMOUNT;
    }
}