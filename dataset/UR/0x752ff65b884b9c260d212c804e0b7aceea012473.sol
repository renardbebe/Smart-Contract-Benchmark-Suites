 

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

 

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

     
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

     
    event Transfer(address indexed from, address indexed to, uint value);

     
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

     
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

     
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

     
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

     
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
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

 

 
contract SNPCToken is BaseFixedERC20Token, SelfDestructible, Withdrawal {
    using SafeMath for uint;

    string public constant name = "SnapCoin";

    string public constant symbol = "SNPC";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

     
    mapping(address => uint) public teamReservedBalances;

    uint public teamReservedUnlockAt;

     
    mapping(address => uint) public bountyReservedBalances;

    uint public bountyReservedUnlockAt;

     
    event ReservedTokensDistributed(address indexed to, uint8 group, uint amount);

    event TokensBurned(uint amount);

    constructor(uint totalSupplyTokens_,
            uint teamTokens_,
            uint bountyTokens_,
            uint advisorsTokens_,
            uint reserveTokens_,
            uint stackingBonusTokens_) public {
        locked = true;
        totalSupply = totalSupplyTokens_.mul(ONE_TOKEN);
        uint availableSupply = totalSupply;

        reserved[RESERVED_TEAM_GROUP] = teamTokens_.mul(ONE_TOKEN);
        reserved[RESERVED_BOUNTY_GROUP] = bountyTokens_.mul(ONE_TOKEN);
        reserved[RESERVED_ADVISORS_GROUP] = advisorsTokens_.mul(ONE_TOKEN);
        reserved[RESERVED_RESERVE_GROUP] = reserveTokens_.mul(ONE_TOKEN);
        reserved[RESERVED_STACKING_BONUS_GROUP] = stackingBonusTokens_.mul(ONE_TOKEN);
        availableSupply = availableSupply
            .sub(reserved[RESERVED_TEAM_GROUP])
            .sub(reserved[RESERVED_BOUNTY_GROUP])
            .sub(reserved[RESERVED_ADVISORS_GROUP])
            .sub(reserved[RESERVED_RESERVE_GROUP])
            .sub(reserved[RESERVED_STACKING_BONUS_GROUP]);
        teamReservedUnlockAt = block.timestamp + 365 days;  
        bountyReservedUnlockAt = block.timestamp + 91 days;  

        balances[owner] = availableSupply;
        emit Transfer(0, address(this), availableSupply);
        emit Transfer(address(this), owner, balances[owner]);
    }

     
    function() external payable {
        revert();
    }

    function burnTokens(uint amount) public {
        require(balances[msg.sender] >= amount);
        totalSupply = totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        emit TokensBurned(amount);
    }

     
    uint8 public constant RESERVED_TEAM_GROUP = 0x1;

    uint8 public constant RESERVED_BOUNTY_GROUP = 0x2;

    uint8 public constant RESERVED_ADVISORS_GROUP = 0x4;

    uint8 public constant RESERVED_RESERVE_GROUP = 0x8;

    uint8 public constant RESERVED_STACKING_BONUS_GROUP = 0x10;

     
    mapping(uint8 => uint) public reserved;

     
    function getReservedTokens(uint8 group_) public view returns (uint) {
        return reserved[group_];
    }

     
    function assignReserved(address to_, uint8 group_, uint amount_) public onlyOwner {
        require(to_ != address(0) && (group_ & 0x1F) != 0);

         
        reserved[group_] = reserved[group_].sub(amount_);
        balances[to_] = balances[to_].add(amount_);
        if (group_ == RESERVED_TEAM_GROUP) {
            teamReservedBalances[to_] = teamReservedBalances[to_].add(amount_);
        } else if (group_ == RESERVED_BOUNTY_GROUP) {
            bountyReservedBalances[to_] = bountyReservedBalances[to_].add(amount_);
        }
        emit ReservedTokensDistributed(to_, group_, amount_);
    }

     
    function teamReservedBalanceOf(address owner_) public view returns (uint) {
        return teamReservedBalances[owner_];
    }

     
    function bountyReservedBalanceOf(address owner_) public view returns (uint) {
        return bountyReservedBalances[owner_];
    }

    function getAllowedForTransferTokens(address from_) public view returns (uint) {
        uint allowed = balances[from_];

        if (teamReservedBalances[from_] > 0) {
            if (block.timestamp < teamReservedUnlockAt) {
                allowed = allowed.sub(teamReservedBalances[from_]);
            }
        }

        if (bountyReservedBalances[from_] > 0) {
            if (block.timestamp < bountyReservedUnlockAt) {
                allowed = allowed.sub(bountyReservedBalances[from_]);
            }
        }

        return allowed;
    }

    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(value_ <= getAllowedForTransferTokens(msg.sender));
        return super.transfer(to_, value_);
    }

    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(value_ <= getAllowedForTransferTokens(from_));
        return super.transferFrom(from_, to_, value_);
    }

}