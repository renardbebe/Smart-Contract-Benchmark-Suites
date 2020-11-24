 

pragma solidity 0.4.24;

 

 
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

 

interface ERC20Token {
    function balanceOf(address owner_) external returns (uint);
    function allowance(address owner_, address spender_) external returns (uint);
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
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

     
    ERC20Token public token;

     
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

 

 
contract IonChainICO is BaseICO {
    using SafeMath for uint;

     
    uint internal constant ONE_TOKEN = 1e6;

     
    uint public constant ETH_TOKEN_EXCHANGE_RATIO = 125000;

     
    address public tokenHolder;

     
    uint public constant PERSONAL_CAP = 1.6 ether;

     
    uint public personalCapEndAt;

     
    mapping(address => uint) internal personalPurchases;

    constructor(address icoToken_,
            address teamWallet_,
            address tokenHolder_,
            uint lowCapWei_,
            uint hardCapWei_,
            uint lowCapTxWei_,
            uint hardCapTxWei_) public {
        require(icoToken_ != address(0) && teamWallet_ != address(0));
        token = ERC20Token(icoToken_);
        teamWallet = teamWallet_;
        tokenHolder = tokenHolder_;
        state = State.Inactive;
        lowCapWei = lowCapWei_;
        hardCapWei = hardCapWei_;
        lowCapTxWei = lowCapTxWei_;
        hardCapTxWei = hardCapTxWei_;
    }

     
    function() external payable {
        buyTokens();
    }


    function start(uint endAt_) onlyOwner public {
        uint requireTokens = hardCapWei.mul(ETH_TOKEN_EXCHANGE_RATIO).mul(ONE_TOKEN).div(1 ether);
        require(token.balanceOf(tokenHolder) >= requireTokens
            && token.allowance(tokenHolder, address(this)) >= requireTokens);
        personalCapEndAt = block.timestamp + 48 hours;
        super.start(endAt_);
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

    function buyTokens() public onlyWhitelisted payable {
        require(state == State.Active &&
            block.timestamp <= endAt &&
            msg.value >= lowCapTxWei &&
            msg.value <= hardCapTxWei &&
            collectedWei + msg.value <= hardCapWei);
        uint amountWei = msg.value;

         
        if (block.timestamp <= personalCapEndAt) {
            personalPurchases[msg.sender] = personalPurchases[msg.sender].add(amountWei);
            require(personalPurchases[msg.sender] <= PERSONAL_CAP);
        }

        uint itokens = amountWei.mul(ETH_TOKEN_EXCHANGE_RATIO).mul(ONE_TOKEN).div(1 ether);
        collectedWei = collectedWei.add(amountWei);

        emit ICOInvestment(msg.sender, amountWei, itokens, 0);
         
        token.transferFrom(tokenHolder, msg.sender, itokens);
        forwardFunds();
        touch();
    }
}