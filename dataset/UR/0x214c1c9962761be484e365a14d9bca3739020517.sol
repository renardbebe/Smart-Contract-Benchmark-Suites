 

 

 

pragma solidity ^0.4.24;

 
 
 
 
 
contract GodMode {
     
    bool public isPaused;

     
    address public god;

     
    modifier onlyGod()
    {
        require(god == msg.sender);
        _;
    }

     
     
    modifier notPaused()
    {
        require(!isPaused);
        _;
    }

     
    event GodPaused();

     
    event GodUnpaused();

    constructor() public
    {
         
        god = msg.sender;
    }

     
     
    function godChangeGod(address _newGod) public onlyGod
    {
        god = _newGod;
    }

     
    function godPause() public onlyGod
    {
        isPaused = true;

        emit GodPaused();
    }

     
    function godUnpause() public onlyGod
    {
        isPaused = false;

        emit GodUnpaused();
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthAbstractInterface {
     
    address public king;

     
    address public wayfarer;

     
    function payTaxes() public payable;
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthAuctionsAbstractInterface {
     
     
     
     
    function existingAuction(uint _x, uint _y) public view returns(bool);
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthBlindAuctionsReferencer is GodMode {
     
    address public blindAuctionsContract;

     
    modifier onlyBlindAuctionsContract()
    {
        require(blindAuctionsContract == msg.sender);
        _;
    }

     
     
     
    function godSetBlindAuctionsContract(address _blindAuctionsContract)
        public
        onlyGod
    {
        blindAuctionsContract = _blindAuctionsContract;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthOpenAuctionsReferencer is GodMode {
     
    address public openAuctionsContract;

     
    modifier onlyOpenAuctionsContract()
    {
        require(openAuctionsContract == msg.sender);
        _;
    }

     
    function godSetOpenAuctionsContract(address _openAuctionsContract)
        public
        onlyGod
    {
        openAuctionsContract = _openAuctionsContract;
    }
}

 

 

pragma solidity ^0.4.24;



 
 
 
contract KingOfEthAuctionsReferencer is
      KingOfEthBlindAuctionsReferencer
    , KingOfEthOpenAuctionsReferencer
{
     
    modifier onlyAuctionsContract()
    {
        require(blindAuctionsContract == msg.sender
             || openAuctionsContract == msg.sender);
        _;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthReferencer is GodMode {
     
    address public kingOfEthContract;

     
    modifier onlyKingOfEthContract()
    {
        require(kingOfEthContract == msg.sender);
        _;
    }

     
     
    function godSetKingOfEthContract(address _kingOfEthContract)
        public
        onlyGod
    {
        kingOfEthContract = _kingOfEthContract;
    }
}

 

 

pragma solidity ^0.4.24;





 
 
 
contract KingOfEthBoard is
      GodMode
    , KingOfEthAuctionsReferencer
    , KingOfEthReferencer
{
     
    uint public boundX1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffef;

     
    uint public boundY1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffef;

     
    uint public boundX2 = 0x800000000000000000000000000000000000000000000000000000000000000f;

     
    uint public boundY2 = 0x800000000000000000000000000000000000000000000000000000000000000f;

     
     
     
    uint public constant auctionsAvailableDivisor = 10;

     
    uint public constant kingTimeBetweenIncrease = 2 weeks;

     
    uint public constant wayfarerTimeBetweenIncrease = 3 weeks;

     
     
    uint public constant plebTimeBetweenIncrease = 4 weeks;

     
    uint public lastIncreaseTime;

     
    uint8 public nextIncreaseDirection;

     
     
    uint public auctionsRemaining;

    constructor() public
    {
         
        isPaused = true;

         
        setAuctionsAvailableForBounds();
    }

     
    event BoardSizeIncreased(
          address initiator
        , uint newBoundX1
        , uint newBoundY1
        , uint newBoundX2
        , uint newBoundY2
        , uint lastIncreaseTime
        , uint nextIncreaseDirection
        , uint auctionsRemaining
    );

     
    modifier onlyKing()
    {
        require(KingOfEthAbstractInterface(kingOfEthContract).king() == msg.sender);
        _;
    }

     
    modifier onlyWayfarer()
    {
        require(KingOfEthAbstractInterface(kingOfEthContract).wayfarer() == msg.sender);
        _;
    }

     
    function setAuctionsAvailableForBounds() private
    {
        uint boundDiffX = boundX2 - boundX1;
        uint boundDiffY = boundY2 - boundY1;

        auctionsRemaining = boundDiffX * boundDiffY / 2 / auctionsAvailableDivisor;
    }

     
     
    function increaseBoard() private
    {
         
        uint _increaseLength;

         
        if(0 == nextIncreaseDirection)
        {
            _increaseLength = boundX2 - boundX1;
            uint _updatedX2 = boundX2 + _increaseLength;

             
            if(_updatedX2 <= boundX2 || _updatedX2 <= _increaseLength)
            {
                boundX2 = ~uint(0);
            }
            else
            {
                boundX2 = _updatedX2;
            }
        }
         
        else if(1 == nextIncreaseDirection)
        {
            _increaseLength = boundY2 - boundY1;
            uint _updatedY2 = boundY2 + _increaseLength;

             
            if(_updatedY2 <= boundY2 || _updatedY2 <= _increaseLength)
            {
                boundY2 = ~uint(0);
            }
            else
            {
                boundY2 = _updatedY2;
            }
        }
         
        else if(2 == nextIncreaseDirection)
        {
            _increaseLength = boundX2 - boundX1;

             
            if(boundX1 <= _increaseLength)
            {
                boundX1 = 0;
            }
            else
            {
                boundX1 -= _increaseLength;
            }
        }
         
        else if(3 == nextIncreaseDirection)
        {
            _increaseLength = boundY2 - boundY1;

             
            if(boundY1 <= _increaseLength)
            {
                boundY1 = 0;
            }
            else
            {
                boundY1 -= _increaseLength;
            }
        }

         
        lastIncreaseTime = now;

         
        nextIncreaseDirection = (nextIncreaseDirection + 1) % 4;

         
        setAuctionsAvailableForBounds();

        emit BoardSizeIncreased(
              msg.sender
            , boundX1
            , boundY1
            , boundX2
            , boundY2
            , now
            , nextIncreaseDirection
            , auctionsRemaining
        );
    }

     
    function godStartGame() public onlyGod
    {
         
        lastIncreaseTime = now;

         
        godUnpause();
    }

     
     
    function auctionsDecrementAuctionsRemaining()
        public
        onlyAuctionsContract
    {
        auctionsRemaining -= 1;
    }

     
     
     
    function auctionsIncrementAuctionsRemaining()
        public
        onlyAuctionsContract
    {
        auctionsRemaining += 1;
    }

     
    function kingIncreaseBoard()
        public
        onlyKing
    {
         
        require(lastIncreaseTime + kingTimeBetweenIncrease < now);

        increaseBoard();
    }

     
    function wayfarerIncreaseBoard()
        public
        onlyWayfarer
    {
         
        require(lastIncreaseTime + wayfarerTimeBetweenIncrease < now);

        increaseBoard();
    }

     
    function plebIncreaseBoard() public
    {
         
        require(lastIncreaseTime + plebTimeBetweenIncrease < now);

        increaseBoard();
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthBoardReferencer is GodMode {
     
    address public boardContract;

     
    modifier onlyBoardContract()
    {
        require(boardContract == msg.sender);
        _;
    }

     
     
    function godSetBoardContract(address _boardContract)
        public
        onlyGod
    {
        boardContract = _boardContract;
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthHousesAbstractInterface {
     
     
     
     
    function ownerOf(uint _x, uint _y) public view returns(address);

     
     
     
     
    function level(uint _x, uint _y) public view returns(uint8);

     
     
     
     
    function auctionsSetOwner(uint _x, uint _y, address _owner) public;

     
     
     
     
     
    function houseRealtyTransferOwnership(
          uint _x
        , uint _y
        , address _from
        , address _to
    ) public;
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthHousesReferencer is GodMode {
     
    address public housesContract;

     
    modifier onlyHousesContract()
    {
        require(housesContract == msg.sender);
        _;
    }

     
     
    function godSetHousesContract(address _housesContract)
        public
        onlyGod
    {
        housesContract = _housesContract;
    }
}

 

 

pragma solidity ^0.4.24;










 
 
 
contract KingOfEthOpenAuctions is
      GodMode
    , KingOfEthAuctionsAbstractInterface
    , KingOfEthReferencer
    , KingOfEthBlindAuctionsReferencer
    , KingOfEthBoardReferencer
    , KingOfEthHousesReferencer
{
     
    struct Auction {
         
        uint startTime;

         
        uint winningBid;

         
        address winner;
    }

     
    mapping (uint => mapping (uint => Auction)) auctions;

     
    uint public constant bidSpan = 20 minutes;

     
     
     
    constructor(
          address _kingOfEthContract
        , address _blindAuctionsContract
        , address _boardContract
    )
        public
    {
        kingOfEthContract     = _kingOfEthContract;
        blindAuctionsContract = _blindAuctionsContract;
        boardContract         = _boardContract;

         
        isPaused = true;
    }

     
    event OpenAuctionStarted(
          uint x
        , uint y
        , address starter
        , uint startTime
    );

     
    event OpenBidPlaced(uint x, uint y, address bidder, uint amount);

     
    event OpenAuctionClosed(uint x, uint y, address newOwner, uint amount);

     
     
     
     
    function existingAuction(uint _x, uint _y) public view returns(bool)
    {
        return 0 != auctions[_x][_y].startTime;
    }

     
     
     
    function createAuction(uint _x, uint _y) public notPaused
    {
         
         
        require(0 == auctions[_x][_y].startTime);

         
        require(!KingOfEthAuctionsAbstractInterface(blindAuctionsContract).existingAuction(_x, _y));

        KingOfEthBoard _board = KingOfEthBoard(boardContract);

         
        require(0 < _board.auctionsRemaining());

         
        require(_board.boundX1() < _x);
        require(_board.boundY1() < _y);
        require(_board.boundX2() > _x);
        require(_board.boundY2() > _y);

         
        require(0x0 == KingOfEthHousesAbstractInterface(housesContract).ownerOf(_x, _y));

         
        _board.auctionsDecrementAuctionsRemaining();

        auctions[_x][_y].startTime = now;

        emit OpenAuctionStarted(_x, _y, msg.sender, now);
    }

     
     
     
     
    function placeBid(uint _x, uint _y) public payable notPaused
    {
         
        Auction storage _auction = auctions[_x][_y];

         
        require(0 != _auction.startTime);

         
        require(_auction.startTime + bidSpan > now);

         
        if(_auction.winningBid < msg.value)
        {
             
            uint    _oldWinningBid = _auction.winningBid;
            address _oldWinner     = _auction.winner;

             
            _auction.winningBid = msg.value;
            _auction.winner     = msg.sender;

             
            if(0 < _oldWinningBid) {
                _oldWinner.transfer(_oldWinningBid);
            }
        }
        else
        {
             
            msg.sender.transfer(msg.value);
        }

        emit OpenBidPlaced(_x, _y, msg.sender, msg.value);
    }

     
     
     
    function closeAuction(uint _x, uint _y) public notPaused
    {
         
        Auction storage _auction = auctions[_x][_y];

         
        require(0 != _auction.startTime);

         
        if(0x0 == _auction.winner)
        {
             
            _auction.startTime = 0;

             
            KingOfEthBoard(boardContract).auctionsIncrementAuctionsRemaining();
        }
         
        else
        {
             
             
             
             
            KingOfEthHousesAbstractInterface(housesContract).auctionsSetOwner(
                  _x
                , _y
                , _auction.winner
            );

             
            KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(_auction.winningBid)();
        }

        emit OpenAuctionClosed(_x, _y, _auction.winner, _auction.winningBid);
    }
}