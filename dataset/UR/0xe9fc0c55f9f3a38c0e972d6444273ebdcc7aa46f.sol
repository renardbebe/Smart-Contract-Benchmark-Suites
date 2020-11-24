 

pragma solidity ^0.4.23;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

contract Ownable {
    address internal owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        require(newOwner != address(0x0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

        return true;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Unlocked }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state != State.Refunding);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function unlock() onlyOwner public {
        require(state == State.Active);
        state = State.Unlocked;
    }

    function withdraw(address beneficiary, uint256 amount) onlyOwner public {
        require(beneficiary != 0x0);
        require(state == State.Unlocked);

        beneficiary.transfer(amount);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}

interface MintableToken {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferOwnership(address newOwner) external returns (bool);
}

 
contract BitNauticWhitelist is Ownable {
    using SafeMath for uint256;

    uint256 public usdPerEth;

    function BitNauticWhitelist(uint256 _usdPerEth) public {
        usdPerEth = _usdPerEth;
    }

    mapping(address => bool) public AMLWhitelisted;
    mapping(address => uint256) public contributionCap;

     
    function setKYCLevel(address addr, uint8 level) onlyOwner public returns (bool) {
        if (level >= 3) {
            contributionCap[addr] = 50000 ether;  
        } else if (level == 2) {
            contributionCap[addr] = SafeMath.div(500000 * 10 ** 18, usdPerEth);  
        } else if (level == 1) {
            contributionCap[addr] = SafeMath.div(3000 * 10 ** 18, usdPerEth);  
        } else {
            contributionCap[addr] = 0;
        }

        return true;
    }

    function setKYCLevelsBulk(address[] addrs, uint8[] levels) onlyOwner external returns (bool success) {
        require(addrs.length == levels.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setKYCLevel(addrs[i], levels[i]));
        }

        return true;
    }

     
    function setAMLWhitelisted(address addr, bool whitelisted) onlyOwner public returns (bool) {
        AMLWhitelisted[addr] = whitelisted;

        return true;
    }

    function setAMLWhitelistedBulk(address[] addrs, bool[] whitelisted) onlyOwner external returns (bool) {
        require(addrs.length == whitelisted.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setAMLWhitelisted(addrs[i], whitelisted[i]));
        }

        return true;
    }
}

contract NewBitNauticCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    uint256 public ICOStartTime = 1531267200;  
    uint256 public ICOEndTime = 1537056000;  

    uint256 public constant tokenBaseRate = 500;  

    bool public manualBonusActive = false;
    uint256 public manualBonus = 0;

    uint256 public constant crowdsaleSupply = 35000000 * 10 ** 18;
    uint256 public tokensSold = 0;

    uint256 public constant softCap = 2500000 * 10 ** 18;

    uint256 public teamSupply =     3000000 * 10 ** 18;  
    uint256 public bountySupply =   2500000 * 10 ** 18;  
    uint256 public reserveSupply =  5000000 * 10 ** 18;  
    uint256 public advisorSupply =  2500000 * 10 ** 18;  
    uint256 public founderSupply =  2000000 * 10 ** 18;  

     
    mapping (address => uint256) public creditOf;

     
    mapping (address => uint256) public weiInvestedBy;

     
    RefundVault private vault;

    MintableToken public token;
    BitNauticWhitelist public whitelist;

    constructor(MintableToken _token, BitNauticWhitelist _whitelist, address _beneficiary) public {
        token = _token;
        whitelist = _whitelist;
        vault = new RefundVault(_beneficiary);
    }

    function() public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

         
        require(SafeMath.add(weiInvestedBy[msg.sender], msg.value) <= whitelist.contributionCap(msg.sender));

         
        uint256 tokens = SafeMath.mul(msg.value, tokenBaseRate);
         
        tokens = tokens.add(SafeMath.mul(tokens, getCurrentBonus()).div(1000));

         
        require(SafeMath.add(tokensSold, tokens) <= crowdsaleSupply);

         
        tokensSold = SafeMath.add(tokensSold, tokens);

         
        creditOf[beneficiary] = creditOf[beneficiary].add(tokens);
        weiInvestedBy[msg.sender] = SafeMath.add(weiInvestedBy[msg.sender], msg.value);

        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

        vault.deposit.value(msg.value)(msg.sender);
    }

    function privateSale(address beneficiary, uint256 tokenAmount) onlyOwner public {
        require(beneficiary != 0x0);
        require(SafeMath.add(tokensSold, tokenAmount) <= crowdsaleSupply);  

        tokensSold = SafeMath.add(tokensSold, tokenAmount);

        assert(token.mint(beneficiary, tokenAmount));
    }

     
    function offchainSale(address beneficiary, uint256 tokenAmount) onlyOwner public {
        require(beneficiary != 0x0);
        require(SafeMath.add(tokensSold, tokenAmount) <= crowdsaleSupply);  

        tokensSold = SafeMath.add(tokensSold, tokenAmount);

         
        creditOf[beneficiary] = creditOf[beneficiary].add(tokenAmount);

        emit TokenPurchase(beneficiary, beneficiary, 0, tokenAmount);
    }

     
    function claimBitNauticTokens() public returns (bool) {
        return grantContributorTokens(msg.sender);
    }

     
    function grantContributorTokens(address contributor) public returns (bool) {
        require(creditOf[contributor] > 0);
        require(whitelist.AMLWhitelisted(contributor));
        require(now > ICOEndTime && tokensSold >= softCap);

        assert(token.mint(contributor, creditOf[contributor]));
        creditOf[contributor] = 0;

        return true;
    }

     
    function getCurrentBonus() public view returns (uint256) {
        if (manualBonusActive) return manualBonus;

        return Math.min(340, Math.max(100, (340 - (now - ICOStartTime) / (60 * 60 * 24) * 4)));
    }

    function setManualBonus(uint256 newBonus, bool isActive) onlyOwner public returns (bool) {
        manualBonus = newBonus;
        manualBonusActive = isActive;

        return true;
    }

    function setICOEndTime(uint256 newEndTime) onlyOwner public returns (bool) {
        ICOEndTime = newEndTime;

        return true;
    }

    function validPurchase() internal view returns (bool) {
        bool duringICO = ICOStartTime <= now && now <= ICOEndTime;
        bool minimumContribution = msg.value >= 0.05 ether;
        return duringICO && minimumContribution;
    }

    function hasEnded() public view returns (bool) {
        return now > ICOEndTime;
    }

    function unlockVault() onlyOwner public {
        if (tokensSold >= softCap) {
            vault.unlock();
        }
    }

    function withdraw(address beneficiary, uint256 amount) onlyOwner public {
        vault.withdraw(beneficiary, amount);
    }

    bool isFinalized = false;
    function finalizeCrowdsale() onlyOwner public {
        require(!isFinalized);
        require(now > ICOEndTime);

        if (tokensSold < softCap) {
            vault.enableRefunds();
        }

        isFinalized = true;
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(tokensSold < softCap);

        vault.refund(msg.sender);
    }

    function transferTokenOwnership(address newTokenOwner) onlyOwner public returns (bool) {
        return token.transferOwnership(newTokenOwner);
    }

    function grantBountyTokens(address beneficiary) onlyOwner public {
        require(bountySupply > 0);

        token.mint(beneficiary, bountySupply);
        bountySupply = 0;
    }

    function grantReserveTokens(address beneficiary) onlyOwner public {
        require(reserveSupply > 0);

        token.mint(beneficiary, reserveSupply);
        reserveSupply = 0;
    }

    function grantAdvisorsTokens(address beneficiary) onlyOwner public {
        require(advisorSupply > 0);

        token.mint(beneficiary, advisorSupply);
        advisorSupply = 0;
    }

    function grantFoundersTokens(address beneficiary) onlyOwner public {
        require(founderSupply > 0);

        token.mint(beneficiary, founderSupply);
        founderSupply = 0;
    }

    function grantTeamTokens(address beneficiary) onlyOwner public {
        require(teamSupply > 0);

        token.mint(beneficiary, teamSupply);
        teamSupply = 0;
    }
}