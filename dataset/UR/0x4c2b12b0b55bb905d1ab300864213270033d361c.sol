 

pragma solidity ^0.4.18;

 

 
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

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
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
        Lock();
    }

     
    function unlock() public onlyOwner whenLocked {
        locked = false;
        Unlock();
    }
}

 

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

     
    uint public totalSupply;

    mapping(address => uint) balances;

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
        Transfer(msg.sender, to_, value_);
        return true;
    }

     
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        Transfer(from_, to_, value_);
        return true;
    }

     
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        Approval(msg.sender, spender_, value_);
        return true;
    }

     
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

 

 
contract BaseICOTokenWithBonus is BaseFixedERC20Token {

     
    uint public availableSupply;

     
    address public ico;

     
    uint public bonusUnlockAt;

     
    mapping(address => uint) public bonusBalances;

     
    event ICOTokensInvested(address indexed to, uint amount);

     
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

     
    function BaseICOTokenWithBonus(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

     
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        ICOChanged(ico);
    }

     
    function setBonusUnlockAt(uint bonusUnlockAt_) public onlyOwner {
        require(bonusUnlockAt_ > block.timestamp);
        bonusUnlockAt = bonusUnlockAt_;
    }

    function getBonusUnlockAt() public view returns (uint) {
        return bonusUnlockAt;
    }

     
    function bonusBalanceOf(address owner_) public view returns (uint) {
        return bonusBalances[owner_];
    }

     
    function icoInvestment(address to_, uint amount_, uint bonusAmount_) public onlyICO returns (uint) {
        require(isValidICOInvestment(to_, amount_));
        availableSupply = availableSupply.sub(amount_);
        balances[to_] = balances[to_].add(amount_);
        bonusBalances[to_] = bonusBalances[to_].add(bonusAmount_);
        ICOTokensInvested(to_, amount_);
        return amount_;
    }

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }

    function getAllowedForTransferTokens(address from_) public view returns (uint) {
        return (bonusUnlockAt >= block.timestamp) ? balances[from_].sub(bonusBalances[from_]) : balances[from_];
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

 

 
contract BENEFITToken is BaseICOTokenWithBonus {
    using SafeMath for uint;

    string public constant name = "Dating with Benefits";

    string public constant symbol = "BENEFIT";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    uint public constant RESERVED_RESERVE_UNLOCK_AT = 1546300800;  
    uint public constant RESERVED_COMPANY_UNLOCK_AT = 1561939200;  

     
    event ReservedTokensDistributed(address indexed to, uint8 group, uint amount);

    event TokensBurned(uint amount);

    function BENEFITToken(uint totalSupplyTokens_,
                      uint companyTokens_,
                      uint bountyTokens_,
                      uint reserveTokens_,
                      uint marketingTokens_) public BaseICOTokenWithBonus(totalSupplyTokens_ * ONE_TOKEN) {
        require(availableSupply == totalSupply);
        availableSupply = availableSupply
            .sub(companyTokens_ * ONE_TOKEN)
            .sub(bountyTokens_ * ONE_TOKEN)
            .sub(reserveTokens_ * ONE_TOKEN)
            .sub(marketingTokens_ * ONE_TOKEN);
        reserved[RESERVED_COMPANY_GROUP] = companyTokens_ * ONE_TOKEN;
        reserved[RESERVED_BOUNTY_GROUP] = bountyTokens_ * ONE_TOKEN;
        reserved[RESERVED_RESERVE_GROUP] = reserveTokens_ * ONE_TOKEN;
        reserved[RESERVED_MARKETING_GROUP] = marketingTokens_ * ONE_TOKEN;
    }

     
    function() external payable {
        revert();
    }

    function burnRemain() public onlyOwner {
        require(availableSupply > 0);
        uint burned = availableSupply;
        totalSupply = totalSupply.sub(burned);
        availableSupply = 0;

        TokensBurned(burned);
    }

     
    uint8 public constant RESERVED_COMPANY_GROUP = 0x1;

    uint8 public constant RESERVED_BOUNTY_GROUP = 0x2;

    uint8 public constant RESERVED_RESERVE_GROUP = 0x4;

    uint8 public constant RESERVED_MARKETING_GROUP = 0x8;

     
    mapping(uint8 => uint) public reserved;

     
    function getReservedTokens(uint8 group_) public view returns (uint) {
        return reserved[group_];
    }

     
    function assignReserved(address to_, uint8 group_, uint amount_) public onlyOwner {
        require(to_ != address(0) && (group_ & 0xF) != 0);
        require(group_ != RESERVED_RESERVE_GROUP
            || (group_ == RESERVED_RESERVE_GROUP && block.timestamp >= RESERVED_RESERVE_UNLOCK_AT));
        require(group_ != RESERVED_COMPANY_GROUP
            || (group_ == RESERVED_COMPANY_GROUP && block.timestamp >= RESERVED_COMPANY_UNLOCK_AT));
         
        reserved[group_] = reserved[group_].sub(amount_);
        balances[to_] = balances[to_].add(amount_);
        ReservedTokensDistributed(to_, group_, amount_);
    }
}