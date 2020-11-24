 

pragma solidity 0.4.21;

interface TokenToken {
    function pause() public;
    function unpause() public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function getTotalSupply() public view returns(uint);
    function finishMinting() public returns (bool);
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
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 

 

contract TeamAndAdvisorsAllocation is Ownable {
    using SafeMath for uint;

    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public tokensCreated;
    uint256 public allocatedTokens;
    uint256 private totalTeamAndAdvisorsAllocation = 4000000e18;  

    mapping (address => uint256) public teamAndAdvisorsAllocations;

    TokenToken public token;

     
    function TeamAndAdvisorsAllocation(address _token) public {
        token = TokenToken(_token);
        unlockedAt = now.add(3 days);
        canSelfDestruct = now.add(4 days);
    }

     
    function addTeamAndAdvisorsAllocation(address teamOrAdvisorsAddress, uint256 allocationValue)
    external
    onlyOwner
    returns(bool)
    {
        assert(teamAndAdvisorsAllocations[teamOrAdvisorsAddress] == 0);  

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= totalTeamAndAdvisorsAllocation);

        teamAndAdvisorsAllocations[teamOrAdvisorsAddress] = allocationValue;
        return true;
    }

     
    function unlock() external {
        assert(now >= unlockedAt);

         
        if (tokensCreated == 0) {
            tokensCreated = token.balanceOf(this);
        }

        uint256 transferAllocation = teamAndAdvisorsAllocations[msg.sender];
        teamAndAdvisorsAllocations[msg.sender] = 0;

         
        require(token.transfer(msg.sender, transferAllocation));
    }

     
    function kill() public onlyOwner {
        assert(now >= canSelfDestruct);
        uint256 balance = token.balanceOf(this);

        if (balance > 0) {
            token.transfer(owner, balance);
        }

        selfdestruct(owner);
    }
}

 

contract Whitelist is Ownable {
    mapping(address => bool) public allowedAddresses;

    event WhitelistUpdated(uint256 timestamp, string operation, address indexed member);

    function addToWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            WhitelistUpdated(now, "Added", _addresses[i]);
        }
    }

    function removeFromWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            WhitelistUpdated(now, "Removed", _addresses[i]);
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return allowedAddresses[_address];
    }
}

 

 
contract Crowdsale {
    using SafeMath for uint256;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    TokenToken public token;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(_startTime >= now);
        require(_endTime > _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }


}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }
}

 

 

contract TokenCrowdsale is FinalizableCrowdsale, Pausable {
    uint256 constant public REWARD_SHARE =                   4500000e18;  
    uint256 constant public NON_VESTED_TEAM_ADVISORS_SHARE = 37500000e18;  
    uint256 constant public PRE_CROWDSALE_CAP =              500000e18;  
    uint256 constant public PUBLIC_CROWDSALE_CAP =           7500000e18;  
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = PRE_CROWDSALE_CAP + PUBLIC_CROWDSALE_CAP;
    uint256 constant public TOTAL_TOKENS_SUPPLY =            50000000e18;  
    uint256 constant public PERSONAL_CAP =                   2500000e18;  

    address public rewardWallet;
    address public teamAndAdvisorsAllocation;

     
     
    address public remainderPurchaser;
    uint256 public remainderAmount;

    mapping (address => uint256) public trackBuyersPurchases;

     
    Whitelist public whitelist;

    event PrivateInvestorTokenPurchase(address indexed investor, uint256 tokensPurchased);
    event TokenRateChanged(uint256 previousRate, uint256 newRate);

     
    function TokenCrowdsale
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        uint256 _rate,
        address _wallet,
        address _rewardWallet
    )
    public
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {

        require(_whitelist != address(0) && _wallet != address(0) && _rewardWallet != address(0));
        whitelist = Whitelist(_whitelist);
        rewardWallet = _rewardWallet;

    }

    function setTokenContractAddress(address _token) onlyOwner {
        token = TokenToken(_token);
    }

    modifier whitelisted(address beneficiary) {
        require(whitelist.isWhitelisted(beneficiary));
        _;
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0);

        TokenRateChanged(rate, newRate);
        rate = newRate;
    }

     
    function mintTokenForPreCrowdsale(address investorsAddress, uint256 tokensPurchased)
    external
    onlyOwner
    {
        require(now < startTime && investorsAddress != address(0));
        require(token.getTotalSupply().add(tokensPurchased) <= PRE_CROWDSALE_CAP);

        token.mint(investorsAddress, tokensPurchased);
        PrivateInvestorTokenPurchase(investorsAddress, tokensPurchased);
    }

     
    function setTeamWalletAddress(address _teamAndAdvisorsAllocation) public onlyOwner {
        require(_teamAndAdvisorsAllocation != address(0x0));
        teamAndAdvisorsAllocation = _teamAndAdvisorsAllocation;
    }


     
    function buyTokens(address beneficiary)
    public
    whenNotPaused
    whitelisted(beneficiary)
    payable
    {
        require(beneficiary != address(0));
        require(msg.sender == beneficiary);
        require(validPurchase() && token.getTotalSupply() < TOTAL_TOKENS_FOR_CROWDSALE);

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

        require(trackBuyersPurchases[msg.sender].add(tokens) <= PERSONAL_CAP);

        trackBuyersPurchases[beneficiary] = trackBuyersPurchases[beneficiary].add(tokens);

         
        if (token.getTotalSupply().add(tokens) > TOTAL_TOKENS_FOR_CROWDSALE) {
            tokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.getTotalSupply());
            weiAmount = tokens.div(rate);

             
            remainderPurchaser = msg.sender;
            remainderAmount = msg.value.sub(weiAmount);
        }

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
     
    function hasEnded() public view returns (bool) {
        if (token.getTotalSupply() == TOTAL_TOKENS_FOR_CROWDSALE) {
            return true;
        }

        return super.hasEnded();
    }

     
    function finalization() internal {
         
        require(teamAndAdvisorsAllocation != address(0x0));

         
        token.mint(teamAndAdvisorsAllocation, NON_VESTED_TEAM_ADVISORS_SHARE);
        token.mint(rewardWallet, REWARD_SHARE);

        if (TOTAL_TOKENS_SUPPLY > token.getTotalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_SUPPLY.sub(token.getTotalSupply());

            token.mint(wallet, remainingTokens);
        }

        token.finishMinting();
        TokenToken(token).unpause();
        super.finalization();
    }
}