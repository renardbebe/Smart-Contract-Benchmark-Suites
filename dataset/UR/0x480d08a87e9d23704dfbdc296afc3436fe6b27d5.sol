 

pragma solidity ^0.4.25;

contract GameBoard {

  uint8 constant public minSquareId = 1;
  uint8 constant public maxSquareId = 24;
  uint8 constant public numSquares = 24;
}

contract JackpotRules {
  using SafeMath for uint256;

  constructor() public {}

   

   
  function _winnerJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(2);
  }

   
  function _landholderJackpot(uint256 jackpot) public pure returns (uint256) {
    return (jackpot.mul(2)).div(5);
  }

   
  function _nextPotJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(20);
  }

   
  function _teamJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(20);
  }
}

library Math {
   
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

   
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

   
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
     
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

contract PullPayment {
    using SafeMath for uint256;

    mapping(address => uint256) public payments;
    uint256 public totalPayments;

     
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        payee.transfer(payment);
    }

     
    function asyncSend(address dest, uint256 amount) internal {
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }
}

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

contract TaxRules {
    using SafeMath for uint256;

    constructor() public {}

     
    function _priceToTax(uint256 price) public pure returns (uint256) {
        return price.div(10);
    }

     

     
    function _jackpotTax(uint256 tax) public pure returns (uint256) {
        return (tax.mul(2)).div(5);
    }

     
    function _totalLandholderTax(uint256 tax) public pure returns (uint256) {
        return (tax.mul(19)).div(50);
    }

     
    function _teamTax(uint256 tax, bool hasReferrer) public pure returns (uint256) {
        if (hasReferrer) {
            return (tax.mul(3)).div(25);
        } else {
            return (tax.mul(17)).div(100);
        }
    }
    
     
    function _p3dSellPercentage(uint256 tokens) public pure returns (uint256) {
        return tokens.div(4);
    }

     
    function _referrerTax(uint256 tax, bool hasReferrer)  public pure returns (uint256) {
        if (hasReferrer) {
            return tax.div(20);
        } else {
            return 0;
        }
    }

     
    function _nextPotTax(uint256 tax) public pure returns (uint256) {
        return tax.div(20);
    }
}

contract Commercializ3d is
    GameBoard,
    PullPayment,
    Ownable,
    TaxRules,
    JackpotRules {
    using SafeMath for uint256;
    using Math for uint256;

    enum Stage {
        DutchAuction,
        GameRounds
    }
    Stage public stage = Stage.DutchAuction;

    modifier atStage(Stage _stage) {
        require(
            stage == _stage,
            "Function cannot be called at this stage."
        );
        _;
    }

    constructor(uint startingStage) public {
        if (startingStage == uint(Stage.GameRounds)) {
            stage = Stage.GameRounds;
            _startGameRound();
        } else {
            _startAuction();
        }
    }

    mapping(uint8 => address) public squareToOwner;
    mapping(uint8 => uint256) public squareToPrice;
    uint256 public totalSquareValue;

    function _changeSquarePrice(uint8 squareId, uint256 newPrice) private {
        uint256 oldPrice = squareToPrice[squareId];
        squareToPrice[squareId] = newPrice;
        totalSquareValue = (totalSquareValue.sub(oldPrice)).add(newPrice);
    }

    event SquareOwnerChanged(
        uint8 indexed squareId,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 oldPrice,
        uint256 newPrice
    );

    HourglassInterface constant P3DContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    
    function _buyP3D(uint256 amount) private {
        P3DContract.buy.value(amount)(0xB111DaBb8EdD8260B5c1E471945A62bE2eE24470);
    }
    
    function _sendP3D(address to, uint256 amount) private {
        P3DContract.transfer(to, amount);
    }
    
    function getP3DBalance() view public returns(uint256) {
        return (P3DContract.balanceOf(address(this)));
    }
    
    function getDivsBalance() view public returns(uint256) {
        return (P3DContract.dividendsOf(address(this)));
    }
    
    function withdrawContractBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableBalance = contractBalance.sub(totalPayments);

         
        require(withdrawableBalance > 0);

        asyncSend(msg.sender, withdrawableBalance);
    }

    event AuctionStarted(
        uint256 startingAuctionPrice,
        uint256 endingAuctionPrice,
        uint256 auctionDuration,
        uint256 startTime
    );

    event AuctionEnded(
        uint256 endTime
    );

    uint256 constant public startingAuctionPrice = 0.1 ether;
    uint256 constant public endingAuctionPrice = 0.05 ether;
    uint256 constant public auctionDuration = 5 days;  

    uint256 public numBoughtSquares;
    uint256 public auctionStartTime;

    function buySquareAtAuction(uint8 squareId, uint256 newPrice, address referrer) public payable atStage(Stage.DutchAuction) {
        require(
            squareToOwner[squareId] == address(0) && squareToPrice[squareId] == 0,
            "This square has already been auctioned off"
        );

        uint256 tax = _priceToTax(newPrice);
        uint256 price = getSquarePriceAuction();

        require(
            msg.value >= tax.add(price),
            "Must pay the full price and tax for a square on auction"
        );

        _distributeAuctionTax(msg.value, referrer);

        squareToOwner[squareId] = msg.sender;
        _changeSquarePrice(squareId, newPrice);

        numBoughtSquares = numBoughtSquares.add(1);

        emit SquareOwnerChanged(squareId, address(0), msg.sender, price, newPrice);

        if (numBoughtSquares >= numSquares) {
            endAuction();
        }
    }

    function _distributeAuctionTax(uint256 tax, address referrer) private {
        _distributeLandholderTax(_totalLandholderTax(tax));

        uint256 totalJackpotTax = _jackpotTax(tax).add(_nextPotTax(tax));
        nextJackpot = nextJackpot.add(totalJackpotTax);

         
        bool hasReferrer = referrer != address(0);
        _buyP3D(_teamTax(tax, hasReferrer));
        asyncSend(referrer, _referrerTax(tax, hasReferrer));
    }

    function getSquarePriceAuction() public view atStage(Stage.DutchAuction) returns (uint256) {
        return endingAuctionPrice;
    }

    function endAuction() private {
        require(
            numBoughtSquares >= numSquares,
            "All squares must be purchased to end round"
        );

        stage = Stage.GameRounds;
        _startGameRound();

        emit AuctionEnded(now);
    }

    function _startAuction() private {
        auctionStartTime = now;
        numBoughtSquares = 0;

        emit AuctionStarted(startingAuctionPrice,
                            endingAuctionPrice,
                            auctionDuration,
                            auctionStartTime);
    }

    uint256 constant public startingRoundExtension = 24 hours;
    uint256 constant public halvingVolume = 10 ether;
    uint256 constant public minRoundExtension = 10 seconds;

    uint256 public roundNumber = 0;

    uint256 public curExtensionVolume;
    uint256 public curRoundExtension;

    uint256 public roundEndTime;

    uint256 public jackpot;
    uint256 public nextJackpot;

    event SquarePriceChanged(
        uint8 indexed squareId,
        address indexed owner,
        uint256 oldPrice,
        uint256 newPrice
    );

    event GameRoundStarted(
        uint256 initJackpot,
        uint256 endTime,
        uint256 roundNumber
    );

    event GameRoundExtended(
        uint256 endTime
    );

    event GameRoundEnded(
        uint256 jackpot
    );

    function roundTimeRemaining() public view atStage(Stage.GameRounds) returns (uint256)  {
        if (_roundOver()) {
            return 0;
        } else {
            return roundEndTime.sub(now);
        }
    }

    function _extendRound() private {
        roundEndTime = roundEndTime.max(now.add(curRoundExtension));

        emit GameRoundExtended(roundEndTime);
    }

    function _startGameRound() private {
        curExtensionVolume = 0 ether;
        curRoundExtension = startingRoundExtension;

        jackpot = nextJackpot;
        nextJackpot = 0;

        roundNumber = roundNumber.add(1);

        _extendRound();

        emit GameRoundStarted(jackpot, roundEndTime, roundNumber);
    }

    function _roundOver() private view returns (bool) {
        return now >= roundEndTime;
    }

    modifier duringRound() {
        require(
            !_roundOver(),
            "Round is over"
        );
        _;
    }

     
    function _logRoundExtensionVolume(uint256 amount) private {
        curExtensionVolume = curExtensionVolume.add(amount);

        if (curExtensionVolume >= halvingVolume) {
            curRoundExtension = curRoundExtension.div(2).max(minRoundExtension);
            curExtensionVolume = 0 ether;
        }
    }

    function endGameRound() public atStage(Stage.GameRounds) {
        require(
            _roundOver(),
            "Round must be over!"
        );

        _distributeJackpot();

        emit GameRoundEnded(jackpot);

        _startGameRound();
    }

    function setSquarePrice(uint8 squareId, uint256 newPrice, address referrer)
        public
        payable
        atStage(Stage.GameRounds)
        duringRound {
        require(
            squareToOwner[squareId] == msg.sender,
            "Can't set square price for a square you don't own!"
        );

        uint256 tax = _priceToTax(newPrice);

        require(
            msg.value >= tax,
            "Must pay tax on new square price!"
        );

        uint256 oldPrice = squareToPrice[squareId];
        _distributeTax(msg.value, referrer);
        _changeSquarePrice(squareId, newPrice);

         
         
        _extendRound();
        _logRoundExtensionVolume(msg.value);

        emit SquarePriceChanged(squareId, squareToOwner[squareId], oldPrice, newPrice);
    }

    function buySquare(uint8 squareId, uint256 newPrice, address referrer)
        public
        payable
        atStage(Stage.GameRounds)
        duringRound {
        address oldOwner = squareToOwner[squareId];
        require(
            oldOwner != msg.sender,
            "Can't buy a square you already own"
        );

        uint256 tax = _priceToTax(newPrice);

        uint256 oldPrice = squareToPrice[squareId];
        require(
            msg.value >= tax.add(oldPrice),
            "Must pay full price and tax for square"
        );

         
        asyncSend(oldOwner, squareToPrice[squareId]);
        squareToOwner[squareId] = msg.sender;

        uint256 actualTax = msg.value.sub(oldPrice);
        _distributeTax(actualTax, referrer);

        _changeSquarePrice(squareId, newPrice);
        _extendRound();
        _logRoundExtensionVolume(msg.value);

        emit SquareOwnerChanged(squareId, oldOwner, msg.sender, oldPrice, newPrice);
    }

    function _distributeJackpot() private {
        uint256 winnerJackpot = _winnerJackpot(jackpot);
        uint256 landholderJackpot = _landholderJackpot(jackpot);
        
         
        uint256 divs = getDivsBalance();
        if (divs > 0) {
            P3DContract.withdraw();
        }
        
         
        landholderJackpot = landholderJackpot.add(divs);
        
        _distributeWinnerAndLandholderJackpot(winnerJackpot, landholderJackpot);

        _buyP3D(_teamJackpot(jackpot));
        
        nextJackpot = nextJackpot.add(_nextPotJackpot(jackpot));
    }

    function _calculatePriceComplement(uint8 squareId) private view returns (uint256) {
        return totalSquareValue.sub(squareToPrice[squareId]);
    }

     
    function _distributeWinnerAndLandholderJackpot(uint256 winnerJackpot, uint256 landholderJackpot) private {
        uint256[] memory complements = new uint256[](numSquares + 1);  
        uint256 totalPriceComplement = 0;

        uint256 bestComplement = 0;
        uint8 lastWinningSquareId = 0;
        for (uint8 i = minSquareId; i <= maxSquareId; i++) {
            uint256 priceComplement = _calculatePriceComplement(i);

             
            if (bestComplement == 0 || priceComplement > bestComplement) {
                bestComplement = priceComplement;
                lastWinningSquareId = i;
            }

            complements[i] = priceComplement;
            totalPriceComplement = totalPriceComplement.add(priceComplement);
        }
        uint256 numWinners = 0;
        for (i = minSquareId; i <= maxSquareId; i++) {
            if (_calculatePriceComplement(i) == bestComplement) {
                numWinners++;
            }
        }
        
         
        uint256 p3dTokens = getP3DBalance();
    
         
        if (numWinners == 1) {
            asyncSend(squareToOwner[lastWinningSquareId], winnerJackpot);
            
            if (p3dTokens > 0) {
                _sendP3D(squareToOwner[lastWinningSquareId], _p3dSellPercentage(p3dTokens));
            }
        } else {
            for (i = minSquareId; i <= maxSquareId; i++) {
                if (_calculatePriceComplement(i) == bestComplement) {
                    asyncSend(squareToOwner[i], winnerJackpot.div(numWinners));
                    
                    if (p3dTokens > 0) {
                        _sendP3D(squareToOwner[i], _p3dSellPercentage(p3dTokens));
                    }
                }
            }
        }

         
        for (i = minSquareId; i <= maxSquareId; i++) {
             
            uint256 landholderAllocation = complements[i].mul(landholderJackpot).div(totalPriceComplement);

            asyncSend(squareToOwner[i], landholderAllocation);
        }
    }

    function _distributeTax(uint256 tax, address referrer) private {
        jackpot = jackpot.add(_jackpotTax(tax));

        _distributeLandholderTax(_totalLandholderTax(tax));
        nextJackpot = nextJackpot.add(_nextPotTax(tax));

         
        bool hasReferrer = referrer != address(0);
        _buyP3D(_teamTax(tax, hasReferrer));
        asyncSend(referrer, _referrerTax(tax, hasReferrer));
    }

    function _distributeLandholderTax(uint256 tax) private {
        for (uint8 square = minSquareId; square <= maxSquareId; square++) {
            if (squareToOwner[square] != address(0) && squareToPrice[square] != 0) {
                uint256 squarePrice = squareToPrice[square];
                uint256 allocation = tax.mul(squarePrice).div(totalSquareValue);

                asyncSend(squareToOwner[square], allocation);
            }
        }
    }
    
    function() payable {}
}

interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}