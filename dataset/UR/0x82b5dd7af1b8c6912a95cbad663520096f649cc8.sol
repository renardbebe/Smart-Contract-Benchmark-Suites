 

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

 

contract Whitelisted is Ownable {

     
    bool public whitelistEnabled = true;

     
    mapping(address => bool) public whitelist;

    event ICOWhitelisted(address indexed addr);
    event ICOBlacklisted(address indexed addr);

    modifier onlyWhitelisted {
        require(!whitelistEnabled || whitelist[msg.sender]);
        _;
    }

     
    function whitelist(address address_) external onlyOwner {
        whitelist[address_] = true;
        emit ICOWhitelisted(address_);
    }

     
    function blacklist(address address_) external onlyOwner {
        delete whitelist[address_];
        emit ICOBlacklisted(address_);
    }

     
    function whitelisted(address address_) public view returns (bool) {
        if (whitelistEnabled) {
            return whitelist[address_];
        } else {
            return true;
        }
    }

     
    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
    }

     
    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
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

 

 
contract BaseICOToken is BaseFixedERC20Token {

     
    uint public availableSupply;

     
    address public ico;

     
    event ICOTokensInvested(address indexed to, uint amount);

     
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

     
    constructor(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

     
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        emit ICOChanged(ico);
    }

     
    function icoInvestmentWei(address to_, uint amountWei_, uint ethTokenExchangeRatio_) public returns (uint);

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }
}

 

 
contract BaseICO is Ownable, Whitelisted {

     
    enum State {

         
        Inactive,

         
         
        Active,

         
         
         
        Suspended,

         
        Terminated,

         
         
        NotCompleted,

         
         
        Completed
    }

     
    BaseICOToken public token;

     
    State public state;

     
    uint public startAt;

     
    uint public endAt;

     
    uint public lowCapWei;

     
     
    uint public hardCapWei;

     
    uint public lowCapTxWei;

     
    uint public hardCapTxWei;

     
    uint public collectedWei;

     
    uint public tokensSold;

     
    address public teamWallet;

     
    event ICOStarted(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
    event ICOResumed(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
    event ICOSuspended();
    event ICOTerminated();
    event ICONotCompleted();
    event ICOCompleted(uint collectedWei);
    event ICOInvestment(address indexed from, uint investedWei, uint tokens, uint8 bonusPct);

    modifier isSuspended() {
        require(state == State.Suspended);
        _;
    }

    modifier isActive() {
        require(state == State.Active);
        _;
    }

    constructor(address icoToken_,
        address teamWallet_,
        uint lowCapWei_,
        uint hardCapWei_,
        uint lowCapTxWei_,
        uint hardCapTxWei_) public {
        require(icoToken_ != address(0) && teamWallet_ != address(0));
        token = BaseICOToken(icoToken_);
        teamWallet = teamWallet_;
        lowCapWei = lowCapWei_;
        hardCapWei = hardCapWei_;
        lowCapTxWei = lowCapTxWei_;
        hardCapTxWei = hardCapTxWei_;
    }

     
    function start(uint endAt_) public onlyOwner {
        require(endAt_ > block.timestamp && state == State.Inactive);
        endAt = endAt_;
        startAt = block.timestamp;
        state = State.Active;
        emit ICOStarted(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
    }

     
    function suspend() public onlyOwner isActive {
        state = State.Suspended;
        emit ICOSuspended();
    }

     
    function terminate() public onlyOwner {
        require(state != State.Terminated &&
        state != State.NotCompleted &&
        state != State.Completed);
        state = State.Terminated;
        emit ICOTerminated();
    }

     
    function tune(uint endAt_,
        uint lowCapWei_,
        uint hardCapWei_,
        uint lowCapTxWei_,
        uint hardCapTxWei_) public onlyOwner isSuspended {
        if (endAt_ > block.timestamp) {
            endAt = endAt_;
        }
        if (lowCapWei_ > 0) {
            lowCapWei = lowCapWei_;
        }
        if (hardCapWei_ > 0) {
            hardCapWei = hardCapWei_;
        }
        if (lowCapTxWei_ > 0) {
            lowCapTxWei = lowCapTxWei_;
        }
        if (hardCapTxWei_ > 0) {
            hardCapTxWei = hardCapTxWei_;
        }
        require(lowCapWei <= hardCapWei && lowCapTxWei <= hardCapTxWei);
        touch();
    }

     
    function resume() public onlyOwner isSuspended {
        state = State.Active;
        emit ICOResumed(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
        touch();
    }

     
    function touch() public;

     
    function buyTokens() public payable;

     
    function forwardFunds() internal {
        teamWallet.transfer(msg.value);
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

 

 
contract ICHXICO is BaseICO, SelfDestructible, Withdrawal {
    using SafeMath for uint;

     
    uint public collectedWei;

     
    mapping (address => uint) public investments;

     
    uint public constant ETH_TOKEN_EXCHANGE_RATIO = 16700;

    constructor(address icoToken_,
                address teamWallet_,
                uint lowCapWei_,
                uint hardCapWei_,
                uint lowCapTxWei_,
                uint hardCapTxWei_) public
        BaseICO(icoToken_, teamWallet_, lowCapWei_, hardCapWei_, lowCapTxWei_, hardCapTxWei_) {
    }

     
    function() external payable {
        buyTokens();
    }

     
    function touch() public {
        if (state != State.Active && state != State.Suspended) {
            return;
        }
        if (collectedWei >= hardCapWei) {
            state = State.Completed;
            endAt = block.timestamp;
            emit ICOCompleted(collectedWei);
        } else if (block.timestamp >= endAt) {
            if (collectedWei < lowCapWei) {
                state = State.NotCompleted;
                emit ICONotCompleted();
            } else {
                state = State.Completed;
                emit ICOCompleted(collectedWei);
            }
        }
    }

    function buyTokens() public payable {
        require(state == State.Active &&
                block.timestamp < endAt &&
                msg.value >= lowCapTxWei &&
                msg.value <= hardCapTxWei &&
                collectedWei + msg.value <= hardCapWei &&
                whitelisted(msg.sender));
        uint amountWei = msg.value;

        uint iTokens = token.icoInvestmentWei(msg.sender, amountWei, ETH_TOKEN_EXCHANGE_RATIO);
        collectedWei = collectedWei.add(amountWei);
        tokensSold = tokensSold.add(iTokens);
        investments[msg.sender] = investments[msg.sender].add(amountWei);

        emit ICOInvestment(msg.sender, amountWei, iTokens, 0);
        forwardFunds();
        touch();
    }

    function getInvestments(address investor) public view returns (uint) {
        return investments[investor];
    }
}