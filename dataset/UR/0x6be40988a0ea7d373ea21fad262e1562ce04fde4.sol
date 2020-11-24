 

 

pragma solidity ^0.4.18;

 
contract WalletBasic {
    function isOwner(address owner) public returns (bool);
}

 
contract MultiOwnable {
    
    WalletBasic public wallet;
    
    event MultiOwnableWalletSet(address indexed _contract, address indexed _wallet);

    function MultiOwnable 
        (address _wallet)
        public
    {
        wallet = WalletBasic(_wallet);
        MultiOwnableWalletSet(this, wallet);
    }

     
    modifier onlyWallet() {
        require(wallet == msg.sender);
        _;
    }

     
    modifier onlyOwner() {
        require (isOwner(msg.sender));
        _;
    }

    function isOwner(address _address) 
        public
        constant
        returns(bool)
    {
         
        return wallet == _address || wallet.isOwner(_address);
    }


      

    bool public paused = false;

    event Pause();
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() 
        onlyOwner
        whenNotPaused 
        public 
    {
        paused = true;
        Pause();
    }

     
    function unpause() 
        onlyWallet
        whenPaused
        public
    {
        paused = false;
        Unpause();
    }
}

 

pragma solidity ^0.4.18;


 
contract BotManageable is MultiOwnable {
    uint256 constant MASK64 = 18446744073709551615;

     
     
     
     
     

     
    mapping (address => uint128) internal botsStartEndTime;

    event BotsStartEndTimeChange(address indexed _botAddress, uint64 _startTime, uint64 _endTime);

    function BotManageable 
        (address _wallet)
        public
        MultiOwnable(_wallet)
    { }

     
    modifier onlyBot() {
        require (isBot(msg.sender));
        _;
    }

     
    modifier onlyBotOrOwner() {
        require (isBot(msg.sender) || isOwner(msg.sender));
        _;
    }

     
    function enableBot(address _botAddress)
        onlyWallet()
        public 
    {
        uint128 botLifetime = botsStartEndTime[_botAddress];
         
        require((botLifetime >> 64) == 0 && (botLifetime & MASK64) == 0);
        botLifetime |= uint128(now) << 64;
        botsStartEndTime[_botAddress] = botLifetime;
        BotsStartEndTimeChange(_botAddress, uint64(botLifetime >> 64), uint64(botLifetime & MASK64));
    }

     
    function disableBot(address _botAddress, uint64 _fromTimeStampSeconds)
        onlyOwner()
        public 
    {
        uint128 botLifetime = botsStartEndTime[_botAddress];
         
        require((botLifetime >> 64) > 0 && (botLifetime & MASK64) == 0);
        botLifetime |= uint128(_fromTimeStampSeconds);
        botsStartEndTime[_botAddress] = botLifetime;
        BotsStartEndTimeChange(_botAddress, uint64(botLifetime >> 64), uint64(botLifetime & MASK64));
    }

     
    function isBot(address _botAddress) 
        public
        constant
        returns(bool)
    {
        return isBotAt(_botAddress, uint64(now));
    }

     

    function isBotAt(address _botAddress, uint64 _atTimeStampSeconds) 
        public
        constant 
        returns(bool)
    {
        uint128 botLifetime = botsStartEndTime[_botAddress];
        if ((botLifetime >> 64) == 0 || (botLifetime >> 64) > _atTimeStampSeconds) {
            return false;
        }
        if ((botLifetime & MASK64) == 0) {
            return true;
        }
        if (_atTimeStampSeconds < (botLifetime & MASK64)) {
            return true;
        }
        return false;
    }
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity ^0.4.18;



contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
}

contract AuctionHub is BotManageable {
    using SafeMath for uint256;

     
    
    struct TokenBalance {
        address token;
        uint256 value;
    }

    struct TokenRate {
        uint256 value;
        uint256 decimals;
    }

    struct BidderState {
        uint256 etherBalance;
        uint256 tokensBalanceInEther;
         
        TokenBalance[] tokenBalances;        
        uint256 etherBalanceInUsd;  
        uint256 tokensBalanceInUsd;  
         
    }

    struct ActionState {
        uint256 endSeconds;  
        uint256 maxTokenBidInEther;  
        uint256 minPrice;  
        
        uint256 highestBid; 
        
         
        address highestBidder;
         
         
        bool cancelled;
        bool finalized;        

        uint256 maxTokenBidInUsd;  
        uint256 highestBidInUsd;  
        address highestBidderInUsd;  
         

        mapping(address => BidderState) bidderStates;

        bytes32 item;       
    }

     
    mapping(address => ActionState) public auctionStates;
    mapping(address => TokenRate) public tokenRates;    
     
    uint256 public etherRate;

     

    event NewAction(address indexed auction, string item);
    event Bid(address indexed auction, address bidder, uint256 totalBidInEther, uint256 indexed tokensBidInEther, uint256 totalBidInUsd, uint256 indexed tokensBidInUsd);
    event TokenBid(address indexed auction, address bidder, address token, uint256 numberOfTokens);
     
     
    event NewHighestBidder(address indexed auction, address bidder, uint256 totalBid);
     
    event NewHighestBidderInUsd(address indexed auction, address bidder, uint256 totalBidInUsd);
    event TokenRateUpdate(address indexed token, uint256 rate);
    event EtherRateUpdate(uint256 rate);  
    event Withdrawal(address indexed auction, address bidder, uint256 etherAmount, uint256 tokensBidInEther);
    event Charity(address indexed auction, address bidder, uint256 etherAmount, uint256 tokensAmount);  
     
    event Finalized(address indexed auction, address highestBidder, uint256 amount);
    event FinalizedInUsd(address indexed auction, address highestBidderInUsd, uint256 amount);
    event FinalizedTokenTransfer(address indexed auction, address token, uint256 tokensBidInEther);
    event FinalizedEtherTransfer(address indexed auction, uint256 etherAmount);
    event ExtendedEndTime(address indexed auction, uint256 newEndtime);
    event Cancelled(address indexed auction);

     

    modifier onlyActive {
         
        ActionState storage auctionState = auctionStates[msg.sender];
        require (now < auctionState.endSeconds && !auctionState.cancelled);
        _;
    }

    modifier onlyBeforeEnd {
         
        ActionState storage auctionState = auctionStates[msg.sender];
        require (now < auctionState.endSeconds);
        _;
    }

    modifier onlyAfterEnd {
        ActionState storage auctionState = auctionStates[msg.sender];
        require (now > auctionState.endSeconds && auctionState.endSeconds > 0);
        _;
    }

    modifier onlyNotCancelled {
        ActionState storage auctionState = auctionStates[msg.sender];
        require (!auctionState.cancelled);
        _;
    }

     

     
    function AuctionHub 
        (address _wallet, address[] _tokens, uint256[] _rates, uint256[] _decimals, uint256 _etherRate)
        public
        BotManageable(_wallet)
    {
         
        botsStartEndTime[msg.sender] = uint128(now) << 64;

        require(_tokens.length == _rates.length);
        require(_tokens.length == _decimals.length);

         
        for (uint i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != 0x0);
            require(_rates[i] > 0);
            ERC20Basic token = ERC20Basic(_tokens[i]);
            tokenRates[token] = TokenRate(_rates[i], _decimals[i]);
            emit TokenRateUpdate(token, _rates[i]);
        }

         
        require(_etherRate > 0);
        etherRate = _etherRate;
        emit EtherRateUpdate(_etherRate);
    }

    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function createAuction(
        uint _endSeconds, 
        uint256 _maxTokenBidInEther,
        uint256 _minPrice,
        string _item
         
    )
        onlyBot
        public
        returns (address)
    {
        require (_endSeconds > now);
        require(_maxTokenBidInEther <= 1000 ether);
        require(_minPrice > 0);

        Auction auction = new Auction(this);

        ActionState storage auctionState = auctionStates[auction];

        auctionState.endSeconds = _endSeconds;
        auctionState.maxTokenBidInEther = _maxTokenBidInEther;
         
        auctionState.maxTokenBidInUsd = _maxTokenBidInEther.mul(etherRate).div(10 ** 2);
        auctionState.minPrice = _minPrice;
         
        string memory item = _item;
        auctionState.item = stringToBytes32(item);

        emit NewAction(auction, _item);
        return address(auction);
    }

    function () 
        payable
        public
    {
        throw;
         
         
         
    }

    function bid(address _bidder, uint256 _value, address _token, uint256 _tokensNumber)
         
        public
        returns (bool isHighest, bool isHighestInUsd)
    {
        ActionState storage auctionState = auctionStates[msg.sender];
         
        require (now < auctionState.endSeconds && !auctionState.cancelled);

        BidderState storage bidderState = auctionState.bidderStates[_bidder];
        
        uint256 totalBid;
        uint256 totalBidInUsd;

        if (_tokensNumber > 0) {
            (totalBid, totalBidInUsd) = tokenBid(msg.sender, _bidder,  _token, _tokensNumber);
        }else {
            require(_value > 0);

             
            (totalBid, totalBidInUsd) = (bidderState.tokensBalanceInEther, bidderState.tokensBalanceInUsd);
        }

        uint256 etherBid = bidderState.etherBalance + _value;
         
        
        bidderState.etherBalance = etherBid;      

         
        totalBid = totalBid + etherBid;
         
        

        if (totalBid > auctionState.highestBid && totalBid >= auctionState.minPrice) {
            auctionState.highestBid = totalBid;
            auctionState.highestBidder = _bidder;
             
            emit NewHighestBidder(msg.sender, _bidder, totalBid);
            if ((auctionState.endSeconds - now) < 1800) {
                 
                 
                 
                 
            }
            isHighest = true;
        }

         
        uint256 etherBidInUsd = bidderState.etherBalanceInUsd + _value.mul(etherRate).div(10 ** 2);
        bidderState.etherBalanceInUsd = etherBidInUsd;
        totalBidInUsd = totalBidInUsd + etherBidInUsd;

        if (totalBidInUsd > auctionState.highestBidInUsd && totalBidInUsd >= auctionState.minPrice.mul(etherRate).div(10 ** 2)) {
            auctionState.highestBidInUsd = totalBidInUsd;
            auctionState.highestBidderInUsd = _bidder;
             
            emit NewHighestBidderInUsd(msg.sender, _bidder, totalBidInUsd);
            if ((auctionState.endSeconds - now) < 1800) {
                 
                 
                 
                 
                auctionState.endSeconds = now + 1800;
                emit ExtendedEndTime(msg.sender, auctionState.endSeconds);
            }
            isHighestInUsd = true;
        }

        emit Bid(msg.sender, _bidder, totalBid, totalBid - etherBid, totalBidInUsd, totalBidInUsd - etherBidInUsd);        

        return (isHighest, isHighestInUsd);
    }

    function tokenBid(address _auction, address _bidder, address _token, uint256 _tokensNumber)
        internal
        returns (uint256 tokenBid, uint256 tokenBidInUsd)
    {
         
         

        ActionState storage auctionState = auctionStates[_auction];
        BidderState storage bidderState = auctionState.bidderStates[_bidder];
        
        uint256 totalBid = bidderState.tokensBalanceInEther;
        uint256 totalBidInUsd = bidderState.tokensBalanceInUsd;

        TokenRate storage tokenRate = tokenRates[_token];
        require(tokenRate.value > 0);

         
        uint256 index = bidderState.tokenBalances.length;
        for (uint i = 0; i < index; i++) {
            if (bidderState.tokenBalances[i].token == _token) {
                index = i;
                break;
            }
        }

         
        if (index == bidderState.tokenBalances.length) {
            bidderState.tokenBalances.push(TokenBalance(_token, _tokensNumber));
        } else {
             
            bidderState.tokenBalances[index].value += _tokensNumber;
        }
        
         
        
        totalBid = calcTokenTotalBid(totalBid, _token, _tokensNumber);
         
        
        totalBidInUsd = calcTokenTotalBidInUsd(totalBidInUsd, _token, _tokensNumber);

         
         

        bidderState.tokensBalanceInEther = totalBid;
        bidderState.tokensBalanceInUsd = totalBidInUsd;

         
         
        emit TokenBid(_auction, _bidder, _token, _tokensNumber);
        return (totalBid, totalBidInUsd);
    }

    function calcTokenTotalBid(uint256 totalBid, address _token, uint256 _tokensNumber)
        internal
         
        returns(uint256 _totalBid){
            TokenRate storage tokenRate = tokenRates[_token];
             
            uint256 bidInEther = _tokensNumber.mul(tokenRate.value).div(10 ** tokenRate.decimals);
             
            totalBid += bidInEther;
             
            return totalBid;
        }
    
    function calcTokenTotalBidInUsd(uint256 totalBidInUsd, address _token, uint256 _tokensNumber)
        internal
        returns(uint256 _totalBidInUsd){
            TokenRate storage tokenRate = tokenRates[_token];
            uint256 bidInUsd = _tokensNumber.mul(tokenRate.value).mul(etherRate).div(10 ** 2).div(10 ** tokenRate.decimals);
             
            totalBidInUsd += bidInUsd;
            return totalBidInUsd;
        }
   
    function totalDirectBid(address _auction, address _bidder)
        view
        public
        returns (uint256 _totalBid)
    {
        ActionState storage auctionState = auctionStates[_auction];
        BidderState storage bidderState = auctionState.bidderStates[_bidder];
        return bidderState.tokensBalanceInEther + bidderState.etherBalance;
    }

    function totalDirectBidInUsd(address _auction, address _bidder)
        view
        public
        returns (uint256 _totalBidInUsd)
    {
        ActionState storage auctionState = auctionStates[_auction];
        BidderState storage bidderState = auctionState.bidderStates[_bidder];
        return bidderState.tokensBalanceInUsd + bidderState.etherBalanceInUsd;
    }

    function setTokenRate(address _token, uint256 _tokenRate)
        onlyBot
        public
    {
        TokenRate storage tokenRate = tokenRates[_token];
        require(tokenRate.value > 0);
        tokenRate.value = _tokenRate;
        emit TokenRateUpdate(_token, _tokenRate);
    }

    function setEtherRate(uint256 _etherRate)
        onlyBot
        public
    {        
        require(_etherRate > 0);
        etherRate = _etherRate;
        emit EtherRateUpdate(_etherRate);
    }

    function withdraw(address _bidder)
        public
        returns (bool success)
    {
        ActionState storage auctionState = auctionStates[msg.sender];
        BidderState storage bidderState = auctionState.bidderStates[_bidder];

        bool sent; 

         
         
         
        require((_bidder != auctionState.highestBidderInUsd) || auctionState.cancelled);
        uint256 tokensBalanceInEther = bidderState.tokensBalanceInEther;
        uint256 tokensBalanceInUsd = bidderState.tokensBalanceInUsd;
        if (bidderState.tokenBalances.length > 0) {
            for (uint i = 0; i < bidderState.tokenBalances.length; i++) {
                uint256 tokenBidValue = bidderState.tokenBalances[i].value;
                if (tokenBidValue > 0) {
                    bidderState.tokenBalances[i].value = 0;
                    sent = Auction(msg.sender).sendTokens(bidderState.tokenBalances[i].token, _bidder, tokenBidValue);
                    require(sent);
                }
            }
            bidderState.tokensBalanceInEther = 0;
            bidderState.tokensBalanceInUsd = 0;
        } else {
            require(tokensBalanceInEther == 0);
        }

        uint256 etherBid = bidderState.etherBalance;
        if (etherBid > 0) {
            bidderState.etherBalance = 0;
            bidderState.etherBalanceInUsd = 0;
            sent = Auction(msg.sender).sendEther(_bidder, etherBid);
            require(sent);
        }

        emit Withdrawal(msg.sender, _bidder, etherBid, tokensBalanceInEther);
        
        return true;
    }

    function finalize()
         
         
        public
        returns (bool)
    {
        ActionState storage auctionState = auctionStates[msg.sender];
         
        require (!auctionState.finalized && now > auctionState.endSeconds && auctionState.endSeconds > 0 && !auctionState.cancelled);

         
        if (auctionState.highestBidder != address(0)) {
            bool sent; 
            BidderState storage bidderState = auctionState.bidderStates[auctionState.highestBidder];
            uint256 tokensBalanceInEther = bidderState.tokensBalanceInEther;
            uint256 tokensBalanceInUsd = bidderState.tokensBalanceInUsd;
            if (bidderState.tokenBalances.length > 0) {
                for (uint i = 0; i < bidderState.tokenBalances.length; i++) {
                    uint256 tokenBid = bidderState.tokenBalances[i].value;
                    if (tokenBid > 0) {
                        bidderState.tokenBalances[i].value = 0;
                        sent = Auction(msg.sender).sendTokens(bidderState.tokenBalances[i].token, wallet, tokenBid);
                        require(sent);
                        emit FinalizedTokenTransfer(msg.sender, bidderState.tokenBalances[i].token, tokenBid);
                    }
                }
                bidderState.tokensBalanceInEther = 0;
                bidderState.tokensBalanceInUsd = 0;
            } else {
                require(tokensBalanceInEther == 0);
            }
            
            uint256 etherBid = bidderState.etherBalance;
            if (etherBid > 0) {
                bidderState.etherBalance = 0;
                bidderState.etherBalanceInUsd = 0;
                sent = Auction(msg.sender).sendEther(wallet, etherBid);
                require(sent);
                emit FinalizedEtherTransfer(msg.sender, etherBid);
            }
        }

        auctionState.finalized = true;
        emit Finalized(msg.sender, auctionState.highestBidder, auctionState.highestBid);
        emit FinalizedInUsd(msg.sender, auctionState.highestBidderInUsd, auctionState.highestBidInUsd);

        return true;
    }

    function cancel()
         
        public
        returns (bool success)
    {
        ActionState storage auctionState = auctionStates[msg.sender];
         
        require (now < auctionState.endSeconds && !auctionState.cancelled);

        auctionState.cancelled = true;
        emit Cancelled(msg.sender);
        return true;
    }

}


contract Auction {

    AuctionHub public owner;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier onlyBot {
        require(owner.isBot(msg.sender));
        _;
    }

    modifier onlyNotBot {
        require(!owner.isBot(msg.sender));
        _;
    }

    function Auction(
        address _owner
    ) 
        public 
    {
        require(_owner != address(0x0));
        owner = AuctionHub(_owner);
    }

    function () 
        payable
        public
    {
        owner.bid(msg.sender, msg.value, 0x0, 0);
    }

    function bid(address _token, uint256 _tokensNumber)
        payable
        public
        returns (bool isHighest, bool isHighestInUsd)
    {
        if (_token != 0x0 && _tokensNumber > 0) {
            require(ERC20Basic(_token).transferFrom(msg.sender, this, _tokensNumber));
        }
        return owner.bid(msg.sender, msg.value, _token, _tokensNumber);
    }   

    function sendTokens(address _token, address _to, uint256 _amount)
        onlyOwner
        public
        returns (bool)
    {
        return ERC20Basic(_token).transfer(_to, _amount);
    }

    function sendEther(address _to, uint256 _amount)
        onlyOwner
        public
        returns (bool)
    {
        return _to.send(_amount);
    }

    function withdraw()
        public
        returns (bool success)
    {
        return owner.withdraw(msg.sender);
    }

    function finalize()
        onlyBot
        public
        returns (bool)
    {
        return owner.finalize();
    }

    function cancel()
        onlyBot
        public
        returns (bool success)
    {
        return  owner.cancel();
    }

    function totalDirectBid(address _bidder)
        public
        view
        returns (uint256)
    {
        return owner.totalDirectBid(this, _bidder);
    }

    function totalDirectBidInUsd(address _bidder)
        public
        view
        returns (uint256)
    {
        return owner.totalDirectBidInUsd(this, _bidder);
    }

    function maxTokenBidInEther()
        public
        view
        returns (uint256)
    {
         
         
         
        var (,maxTokenBidInEther,,,,,,,,,) = owner.auctionStates(this);
        return maxTokenBidInEther;
    }

    function maxTokenBidInUsd()
        public
        view
        returns (uint256)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
        return maxTokenBidInUsd;
    }

    function endSeconds()
        public
        view
        returns (uint256)
    {
         
         
        var (endSeconds,,,,,,,,,,) = owner.auctionStates(this);
        return endSeconds;
    }

    function item()
        public
        view
        returns (string)
    {
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
         
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = item[i];
            }
        return string(bytesArray);
    }

    function minPrice()
        public
        view
        returns (uint256)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
        return minPrice;
    }

    function cancelled()
        public
        view
        returns (bool)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
        return cancelled;
    }

    function finalized()
        public
        view
        returns (bool)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
        return finalized;
    }

    function highestBid()
        public
        view
        returns (uint256)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
         
         
        return highestBid;
    }

    function highestBidInUsd()
        public
        view
        returns (uint256)
    {
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
         
        return highestBidInUsd;
    }

    function highestBidder()
        public
        view
        returns (address)
    {
         
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
         
        return highestBidder;
    }

    
    function highestBidderInUsd()
        public
        view
        returns (address)
    {
         
         
        var (endSeconds,maxTokenBidInEther,minPrice,highestBid,highestBidder,cancelled,finalized,maxTokenBidInUsd,highestBidInUsd,highestBidderInUsd,item) = owner.auctionStates(this);
         
        return highestBidderInUsd;
    }

     


     


     
     
     
     
    
     
}

 

pragma solidity ^0.4.18;


contract TokenStarsAuctionHub is AuctionHub {
     
    address public ACE = 0x06147110022B768BA8F99A8f385df11a151A9cc8;
     
     
     
    address public TEAM = 0x1c79ab32C66aCAa1e9E81952B8AAa581B43e54E7;
     
     
     
    address public wallet = 0x0C9b07209750BbcD1d1716DA52B591f371eeBe77; 
    address[] public tokens = [ACE, TEAM];
     
     
    uint256[] public rates = [10000000000000000, 2000000000000000];
    uint256[] public decimals = [0, 4];
     
    uint256 public etherRate = 13855;

    function TokenStarsAuctionHub()
        public
        AuctionHub(wallet, tokens, rates, decimals, etherRate)
    {
    }

    function createAuction(
        address _wallet,
        uint _endSeconds, 
        uint256 _maxTokenBidInEther,
        uint256 _minPrice,
        string _item
         
    )
        onlyBot
        public
        returns (address)
    {
        require (_endSeconds > now);
        require(_maxTokenBidInEther <= 1000 ether);
        require(_minPrice > 0);

        Auction auction = new TokenStarsAuction(this);

        ActionState storage auctionState = auctionStates[auction];

        auctionState.endSeconds = _endSeconds;
        auctionState.maxTokenBidInEther = _maxTokenBidInEther;
        auctionState.minPrice = _minPrice;
         
        string memory item = _item;
        auctionState.item = stringToBytes32(item);

        NewAction(auction, _item);
        return address(auction);
    }
}

contract TokenStarsAuctionHubMock is AuctionHub {
    uint256[] public rates = [2400000000000000, 2400000000000000];
    uint256[] public decimals = [0, 4];
    uint256 public etherRate = 13855;

    function TokenStarsAuctionHubMock(address _wallet, address[] _tokens)
        public
        AuctionHub(_wallet, _tokens, rates, decimals, etherRate)
    {
    }

    function createAuction(
        uint _endSeconds, 
        uint256 _maxTokenBidInEther,
        uint256 _minPrice,
        string _item
         
    )
        onlyBot
        public
        returns (address)
    {
        require (_endSeconds > now);
        require(_maxTokenBidInEther <= 1000 ether);
        require(_minPrice > 0);

        Auction auction = new TokenStarsAuction(this);

        ActionState storage auctionState = auctionStates[auction];

        auctionState.endSeconds = _endSeconds;
        auctionState.maxTokenBidInEther = _maxTokenBidInEther;
        auctionState.maxTokenBidInUsd = _maxTokenBidInEther.mul(etherRate).div(10 ** 2);
        auctionState.minPrice = _minPrice;
         
        string memory item = _item;
        auctionState.item = stringToBytes32(item);

        NewAction(auction, _item);
        return address(auction);
    }
}

contract TokenStarsAuction is Auction {
        
    function TokenStarsAuction(
        address _owner) 
        public
        Auction(_owner)
    {
        
    }

    function bidAce(uint256 _tokensNumber)
        payable
        public
        returns (bool isHighest, bool isHighestInUsd)
    {
        return super.bid(TokenStarsAuctionHub(owner).ACE(), _tokensNumber);
    }

    function bidTeam(uint256 _tokensNumber)
        payable
        public
        returns (bool isHighest, bool isHighestInUsd)
    {
        return super.bid(TokenStarsAuctionHub(owner).TEAM(), _tokensNumber);
    }
}