 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.12;

contract ITwistedSisterAccessControls {
    function isWhitelisted(address account) public view returns (bool);

    function isWhitelistAdmin(address account) public view returns (bool);
}

 

pragma solidity ^0.5.12;

contract ITwistedSisterTokenCreator {
    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsHash,
        address _recipient
    ) external returns (uint256 _tokenId);
}

 

pragma solidity ^0.5.12;

contract ITwistedSisterArtistCommissionRegistry {
    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists);
    function getMaxCommission() external view returns (uint256);
}

 

pragma solidity ^0.5.12;




contract TwistedSisterArtistFundSplitter {
    using SafeMath for uint256;

    event FundSplitAndTransferred(uint256 _totalValue, address payable _recipient);

    ITwistedSisterArtistCommissionRegistry public artistCommissionRegistry;

    constructor(ITwistedSisterArtistCommissionRegistry _artistCommissionRegistry) public {
        artistCommissionRegistry = _artistCommissionRegistry;
    }

    function() external payable {
        (uint256[] memory _percentages, address payable[] memory _artists) = artistCommissionRegistry.getCommissionSplits();
        require(_percentages.length > 0, "No commissions found");

        uint256 modulo = artistCommissionRegistry.getMaxCommission();

        for (uint256 i = 0; i < _percentages.length; i++) {
            uint256 percentage = _percentages[i];
            address payable artist = _artists[i];

            uint256 valueToSend = msg.value.div(modulo).mul(percentage);
            (bool success, ) = artist.call.value(valueToSend)("");
            require(success, "Transfer failed");

            emit FundSplitAndTransferred(valueToSend, artist);
        }
    }
}

 

pragma solidity ^0.5.12;





contract TwistedSisterAuction {
    using SafeMath for uint256;

    event BidAccepted(
        uint256 indexed _round,
        uint256 _timeStamp,
        uint256 _param,
        uint256 _amount,
        address indexed _bidder
    );

    event BidderRefunded(
        uint256 indexed _round,
        uint256 _amount,
        address indexed _bidder
    );

    event RoundFinalised(
        uint256 indexed _round,
        uint256 _timestamp,
        uint256 _param,
        uint256 _highestBid,
        address _highestBidder
    );

    address payable printingFund;
    address payable auctionOwner;

    uint256 public auctionStartTime;

    uint256 public minBid = 0.02 ether;
    uint256 public currentRound = 1;
    uint256 public numOfRounds = 21;
    uint256 public roundLengthInSeconds = 0.5 days;
    uint256 constant public secondsInADay = 1 days;

     
    mapping(uint256 => uint256) public winningRoundParameter;

     
    mapping(uint256 => uint256) public highestBidFromRound;

     
    mapping(uint256 => address) public highestBidderFromRound;

    ITwistedSisterAccessControls public accessControls;
    ITwistedSisterTokenCreator public twistedTokenCreator;
    TwistedSisterArtistFundSplitter public artistFundSplitter;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedSisterAccessControls _accessControls,
                ITwistedSisterTokenCreator _twistedTokenCreator,
                TwistedSisterArtistFundSplitter _artistFundSplitter,
                address payable _printingFund,
                address payable _auctionOwner,
                uint256 _auctionStartTime) public {
        require(now < _auctionStartTime, "Auction start time is not in the future");
        accessControls = _accessControls;
        twistedTokenCreator = _twistedTokenCreator;
        artistFundSplitter = _artistFundSplitter;
        printingFund = _printingFund;
        auctionStartTime = _auctionStartTime;
        auctionOwner = _auctionOwner;
    }

    function _isWithinBiddingWindowForRound() internal view returns (bool) {
        uint256 offsetFromStartingRound = currentRound.sub(1);
        uint256 currentRoundSecondsOffsetSinceFirstRound = secondsInADay.mul(offsetFromStartingRound);
        uint256 currentRoundStartTime = auctionStartTime.add(currentRoundSecondsOffsetSinceFirstRound);
        uint256 currentRoundEndTime = currentRoundStartTime.add(roundLengthInSeconds);
        return now >= currentRoundStartTime && now <= currentRoundEndTime;
    }

    function _isBidValid(uint256 _bidValue) internal view {
        require(currentRound <= numOfRounds, "Auction has ended");
        require(_bidValue >= minBid, "The bid didn't reach the minimum bid threshold");
        require(_bidValue >= highestBidFromRound[currentRound].add(minBid), "The bid was not higher than the last");
        require(_isWithinBiddingWindowForRound(), "This round's bidding window is not open");
    }

    function _refundHighestBidder() internal {
        uint256 highestBidAmount = highestBidFromRound[currentRound];
        if (highestBidAmount > 0) {
            address highestBidder = highestBidderFromRound[currentRound];

             
            delete highestBidderFromRound[currentRound];

            (bool success, ) = highestBidder.call.value(highestBidAmount)("");
            require(success, "Failed to refund the highest bidder");

            emit BidderRefunded(currentRound, highestBidAmount, highestBidder);
        }
    }

    function _splitFundsFromHighestBid() internal {
         
        uint256 valueToSend = highestBidFromRound[currentRound.sub(1)].div(2);

        (bool pfSuccess, ) = printingFund.call.value(valueToSend)("");
        require(pfSuccess, "Failed to transfer funds to the printing fund");

        (bool fsSuccess, ) = address(artistFundSplitter).call.value(valueToSend)("");
        require(fsSuccess, "Failed to send funds to the auction fund splitter");
    }

    function bid(uint256 _parameter) external payable {
        require(_parameter > 0, "The parameter cannot be zero");
        _isBidValid(msg.value);
        _refundHighestBidder();
        highestBidFromRound[currentRound] = msg.value;
        highestBidderFromRound[currentRound] = msg.sender;
        winningRoundParameter[currentRound] = _parameter;
        emit BidAccepted(currentRound, now, winningRoundParameter[currentRound], highestBidFromRound[currentRound], highestBidderFromRound[currentRound]);
    }

    function issueTwistAndPrepNextRound(string calldata _ipfsHash) external isWhitelisted {
        require(!_isWithinBiddingWindowForRound(), "Current round still active");
        require(currentRound <= numOfRounds, "Auction has ended");

        uint256 previousRound = currentRound;
        currentRound = currentRound.add(1);

         
        if (highestBidderFromRound[previousRound] == address(0)) {
            highestBidderFromRound[previousRound] = auctionOwner;
            winningRoundParameter[previousRound] = 1;  
        }

         
        address winner = highestBidderFromRound[previousRound];
        uint256 winningRoundParam = winningRoundParameter[previousRound];
        uint256 tokenId = twistedTokenCreator.createTwisted(previousRound, winningRoundParam, _ipfsHash, winner);
        require(tokenId == previousRound, "Error minting the TWIST token");

         
        _splitFundsFromHighestBid();

        emit RoundFinalised(previousRound, now, winningRoundParam, highestBidFromRound[previousRound], winner);
    }

    function updateAuctionStartTime(uint256 _auctionStartTime) external isWhitelisted {
        auctionStartTime = _auctionStartTime;
    }

    function updateNumberOfRounds(uint256 _numOfRounds) external isWhitelisted {
        require(_numOfRounds >= currentRound, "Number of rounds can't be smaller than the number of previous");
        numOfRounds = _numOfRounds;
    }

    function updateRoundLength(uint256 _roundLengthInSeconds) external isWhitelisted {
        require(_roundLengthInSeconds < secondsInADay);
        roundLengthInSeconds = _roundLengthInSeconds;
    }

    function updateArtistFundSplitter(TwistedSisterArtistFundSplitter _artistFundSplitter) external isWhitelisted {
        artistFundSplitter = _artistFundSplitter;
    }
}