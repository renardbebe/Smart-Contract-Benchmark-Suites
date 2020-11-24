 

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


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
contract BurnupGameAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    address public cooAddress;
    
    function BurnupGameAccessControl() public {
         
        cfoAddress = msg.sender;
    
         
        cooAddress = msg.sender;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
     
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function setCOO(address _newCOO) external onlyOwner {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
}


 
contract BurnupGameBase is BurnupGameAccessControl {
    using SafeMath for uint256;
    
    event NextGame(uint256 rows, uint256 cols, uint256 activityTimer, uint256 unclaimedTilePrice, uint256 buyoutReferralBonusPercentage, uint256 buyoutPrizePoolPercentage, uint256 buyoutDividendPercentage, uint256 buyoutFeePercentage);
    event Start(uint256 indexed gameIndex, address indexed starter, uint256 timestamp, uint256 prizePool, uint256 rows, uint256 cols, uint256 activityTimer, uint256 unclaimedTilePrice, uint256 buyoutReferralBonusPercentage, uint256 buyoutPrizePoolPercentage, uint256 buyoutDividendPercentage, uint256 buyoutFeePercentage);
    event End(uint256 indexed gameIndex, address indexed winner, uint256 indexed identifier, uint256 x, uint256 y, uint256 timestamp, uint256 prize);
    event Buyout(uint256 indexed gameIndex, address indexed player, uint256 indexed identifier, uint256 x, uint256 y, uint256 timestamp, uint256 timeoutTimestamp, uint256 newPrice, uint256 newPrizePool);
    event SpiceUpPrizePool(uint256 indexed gameIndex, address indexed spicer, uint256 spiceAdded, string message, uint256 newPrizePool);
    
     
    struct GameSettings {
        uint256 rows;  
        uint256 cols;  
        
         
        uint256 activityTimer;  
        
         
        uint256 unclaimedTilePrice;  
        
         
         
        uint256 buyoutReferralBonusPercentage;  
        
         
         
        uint256 buyoutPrizePoolPercentage;  
    
         
         
         
        uint256 buyoutDividendPercentage;  
    
         
        uint256 buyoutFeePercentage;  
    }
    
     
    struct GameState {
         
        bool gameStarted;
    
         
        uint256 gameStartTimestamp;
    
         
        mapping (uint256 => address) identifierToOwner;
        
         
        mapping (uint256 => uint256) identifierToBuyoutTimestamp;
        
         
        mapping (uint256 => uint256) identifierToBuyoutPrice;
        
         
        uint256 lastFlippedTile;
        
         
        uint256 prizePool;
    }
    
     
    mapping (uint256 => GameSettings) public gameSettings;
    
     
    mapping (uint256 => GameState) public gameStates;
    
     
    uint256 public gameIndex = 0;
    
     
    GameSettings public nextGameSettings;
    
    function BurnupGameBase() public {
         
        setNextGameSettings(
            4,  
            5,  
            3600,  
            0.01 ether,  
            750,  
            10000,  
            5000,  
            2500  
        );
    }
    
     
     
     
    function validCoordinate(uint256 x, uint256 y) public view returns(bool) {
        return x < gameSettings[gameIndex].cols && y < gameSettings[gameIndex].rows;
    }
    
     
     
     
    function coordinateToIdentifier(uint256 x, uint256 y) public view returns(uint256) {
        require(validCoordinate(x, y));
        
        return (y * gameSettings[gameIndex].cols) + x;
    }
    
     
     
     
    function identifierToCoordinate(uint256 identifier) public view returns(uint256 x, uint256 y) {
        y = identifier / gameSettings[gameIndex].cols;
        x = identifier - (y * gameSettings[gameIndex].cols);
    }
    
     
    function setNextGameSettings(
        uint256 rows,
        uint256 cols,
        uint256 activityTimer,
        uint256 unclaimedTilePrice,
        uint256 buyoutReferralBonusPercentage,
        uint256 buyoutPrizePoolPercentage,
        uint256 buyoutDividendPercentage,
        uint256 buyoutFeePercentage
    )
        public
        onlyCFO
    {
         
         
        require(2000 <= buyoutDividendPercentage && buyoutDividendPercentage <= 12500);
        
         
        require(buyoutFeePercentage <= 5000);
        
        nextGameSettings = GameSettings({
            rows: rows,
            cols: cols,
            activityTimer: activityTimer,
            unclaimedTilePrice: unclaimedTilePrice,
            buyoutReferralBonusPercentage: buyoutReferralBonusPercentage,
            buyoutPrizePoolPercentage: buyoutPrizePoolPercentage,
            buyoutDividendPercentage: buyoutDividendPercentage,
            buyoutFeePercentage: buyoutFeePercentage
        });
        
        NextGame(rows, cols, activityTimer, unclaimedTilePrice, buyoutReferralBonusPercentage, buyoutPrizePoolPercentage, buyoutDividendPercentage, buyoutFeePercentage);
    }
}


 
contract BurnupGameOwnership is BurnupGameBase {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);
    
     
    function name() public pure returns (string _deedName) {
        _deedName = "Burnup Tiles";
    }
    
     
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "BURN";
    }
    
     
     
     
    function _owns(address _owner, uint256 _identifier) internal view returns (bool) {
        return gameStates[gameIndex].identifierToOwner[_identifier] == _owner;
    }
    
     
     
     
     
    function _transfer(address _from, address _to, uint256 _identifier) internal {
         
        gameStates[gameIndex].identifierToOwner[_identifier] = _to;
        
         
        Transfer(_from, _to, _identifier);
    }
    
     
     
    function ownerOf(uint256 _identifier) external view returns (address _owner) {
        _owner = gameStates[gameIndex].identifierToOwner[_identifier];

        require(_owner != address(0));
    }
    
     
     
     
     
     
     
    function transfer(address _to, uint256 _identifier) external whenNotPaused {
         
        require(_owns(msg.sender, _identifier));
        
         
        _transfer(msg.sender, _to, _identifier);
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
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


 
contract BurnupHoldingAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
     
    mapping (address => bool) burnupGame;

    function BurnupHoldingAccessControl() public {
         
        cfoAddress = msg.sender;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyBurnupGame() {
         
        require(burnupGame[msg.sender]);
        _;
    }

     
     
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function addBurnupGame(address addr) external onlyOwner {
        burnupGame[addr] = true;
    }
    
     
     
    function removeBurnupGame(address addr) external onlyOwner {
        delete burnupGame[addr];
    }
}


 
contract BurnupHoldingReferral is BurnupHoldingAccessControl {

    event SetReferrer(address indexed referral, address indexed referrer);

     
    mapping (address => address) addressToReferrerAddress;
    
     
     
    function referrerOf(address player) public view returns (address) {
        return addressToReferrerAddress[player];
    }
    
     
     
     
    function _setReferrer(address playerAddr, address referrerAddr) internal {
        addressToReferrerAddress[playerAddr] = referrerAddr;
        
         
        SetReferrer(playerAddr, referrerAddr);
    }
}


 
contract BurnupHoldingCore is BurnupHoldingReferral, PullPayment {
    using SafeMath for uint256;
    
    address public beneficiary1;
    address public beneficiary2;
    
    function BurnupHoldingCore(address _beneficiary1, address _beneficiary2) public {
         
        cfoAddress = msg.sender;
        
         
        beneficiary1 = _beneficiary1;
        beneficiary2 = _beneficiary2;
    }
    
     
     
    function payBeneficiaries() external payable {
        uint256 paymentHalve = msg.value.div(2);
        
         
        uint256 otherPaymentHalve = msg.value.sub(paymentHalve);
        
         
        asyncSend(beneficiary1, paymentHalve);
        asyncSend(beneficiary2, otherPaymentHalve);
    }
    
     
     
    function setBeneficiary1(address addr) external onlyCFO {
        beneficiary1 = addr;
    }
    
     
     
    function setBeneficiary2(address addr) external onlyCFO {
        beneficiary2 = addr;
    }
    
     
     
     
    function setReferrer(address playerAddr, address referrerAddr) external onlyBurnupGame whenNotPaused returns(bool) {
        if (referrerOf(playerAddr) == address(0x0) && playerAddr != referrerAddr) {
             
             
            _setReferrer(playerAddr, referrerAddr);
            
             
            return true;
        }
        
         
        return false;
    }
}


 
contract BurnupGameFinance is BurnupGameOwnership, PullPayment {
     
    BurnupHoldingCore burnupHolding;
    
    function BurnupGameFinance(address burnupHoldingAddress) public {
        burnupHolding = BurnupHoldingCore(burnupHoldingAddress);
    }
    
     
     
    function _claimedSurroundingTiles(uint256 _deedId) internal view returns (uint256[] memory) {
        var (x, y) = identifierToCoordinate(_deedId);
        
         
        uint256 claimed = 0;
        
         
        uint256[] memory _tiles = new uint256[](8);
        
         
        for (int256 dx = -1; dx <= 1; dx++) {
            for (int256 dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) {
                     
                    continue;
                }
                
                uint256 nx = uint256(int256(x) + dx);
                uint256 ny = uint256(int256(y) + dy);
                
                if (nx >= gameSettings[gameIndex].cols || ny >= gameSettings[gameIndex].rows) {
                     
                    continue;
                }
                
                 
                uint256 neighborIdentifier = coordinateToIdentifier(
                    nx,
                    ny
                );
                
                if (gameStates[gameIndex].identifierToOwner[neighborIdentifier] != address(0x0)) {
                    _tiles[claimed] = neighborIdentifier;
                    claimed++;
                }
            }
        }
        
         
         
        uint256[] memory tiles = new uint256[](claimed);
        
        for (uint256 i = 0; i < claimed; i++) {
            tiles[i] = _tiles[i];
        }
        
        return tiles;
    }
    
     
     
    function nextBuyoutPrice(uint256 price) public pure returns (uint256) {
        if (price < 0.02 ether) {
            return price.mul(200).div(100);  
        } else {
            return price.mul(150).div(100);  
        }
    }
    
     
    function _assignBuyoutProceeds(
        address currentOwner,
        uint256[] memory claimedSurroundingTiles,
        uint256 fee,
        uint256 currentOwnerWinnings,
        uint256 totalDividendPerBeneficiary,
        uint256 referralBonus,
        uint256 prizePoolFunds
    )
        internal
    {
    
        if (currentOwner != 0x0) {
             
            _sendFunds(currentOwner, currentOwnerWinnings);
        } else {
             
            fee = fee.add(currentOwnerWinnings);
        }
        
         
        for (uint256 i = 0; i < claimedSurroundingTiles.length; i++) {
            address beneficiary = gameStates[gameIndex].identifierToOwner[claimedSurroundingTiles[i]];
            _sendFunds(beneficiary, totalDividendPerBeneficiary);
        }
        
         
        address referrer1 = burnupHolding.referrerOf(msg.sender);
        if (referrer1 != 0x0) {
            _sendFunds(referrer1, referralBonus);
        
            address referrer2 = burnupHolding.referrerOf(referrer1);
            if (referrer2 != 0x0) {
                _sendFunds(referrer2, referralBonus);
            } else {
                 
                fee = fee.add(referralBonus);
            }
        } else {
             
            fee = fee.add(referralBonus.mul(2));
        }
        
         
        burnupHolding.payBeneficiaries.value(fee)();
        
         
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(prizePoolFunds);
    }
    
     
     
     
     
    function _calculateAndAssignBuyoutProceeds(address currentOwner, uint256 _deedId, uint256[] memory claimedSurroundingTiles)
        internal 
        returns (uint256 price)
    {
         
        
        if (currentOwner == 0x0) {
            price = gameSettings[gameIndex].unclaimedTilePrice;
        } else {
            price = gameStates[gameIndex].identifierToBuyoutPrice[_deedId];
        }
        
         
         
        uint256 variableDividends = price.mul(gameSettings[gameIndex].buyoutDividendPercentage).div(100000);
        
         
        uint256 fee            = price.mul(gameSettings[gameIndex].buyoutFeePercentage).div(100000);
        uint256 referralBonus  = price.mul(gameSettings[gameIndex].buyoutReferralBonusPercentage).div(100000);
        uint256 prizePoolFunds = price.mul(gameSettings[gameIndex].buyoutPrizePoolPercentage).div(100000);
        
         
        uint256 currentOwnerWinnings = price.sub(fee).sub(referralBonus.mul(2)).sub(prizePoolFunds);
        
        uint256 totalDividendPerBeneficiary;
        if (claimedSurroundingTiles.length > 0) {
             
             
             
            totalDividendPerBeneficiary = variableDividends / claimedSurroundingTiles.length;
            
            currentOwnerWinnings = currentOwnerWinnings.sub(variableDividends);
             
        }
        
        _assignBuyoutProceeds(
            currentOwner,
            claimedSurroundingTiles,
            fee,
            currentOwnerWinnings,
            totalDividendPerBeneficiary,
            referralBonus,
            prizePoolFunds
        );
    }
    
     
     
     
     
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
             
             
             
             
             
            asyncSend(beneficiary, amount);
        }
    }
}


 
contract BurnupGameCore is BurnupGameFinance {
    
    function BurnupGameCore(address burnupHoldingAddress) public BurnupGameFinance(burnupHoldingAddress) {}
    
     
     
     
     
     
    function buyout(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y) public payable {
         
        _processGameEnd();
        
        if (!gameStates[gameIndex].gameStarted) {
             
            require(!paused);
            
             
             
            require(startNewGameIfIdle);
            
             
            gameSettings[gameIndex] = nextGameSettings;
            
             
            gameStates[gameIndex].gameStarted = true;
            
             
            gameStates[gameIndex].gameStartTimestamp = block.timestamp;
            
             
            Start(gameIndex, msg.sender, block.timestamp, gameStates[gameIndex].prizePool, gameSettings[gameIndex].rows, gameSettings[gameIndex].cols, gameSettings[gameIndex].activityTimer, gameSettings[gameIndex].unclaimedTilePrice, gameSettings[gameIndex].buyoutReferralBonusPercentage, gameSettings[gameIndex].buyoutPrizePoolPercentage, gameSettings[gameIndex].buyoutDividendPercentage, gameSettings[gameIndex].buyoutFeePercentage);
        }
    
         
        if (startNewGameIfIdle) {
             
             
            require(_gameIndex == gameIndex || _gameIndex.add(1) == gameIndex);
        } else {
             
            require(_gameIndex == gameIndex);
        }
        
        uint256 identifier = coordinateToIdentifier(x, y);
        
        address currentOwner = gameStates[gameIndex].identifierToOwner[identifier];
        
         
        if (currentOwner == address(0x0)) {
             
            require(gameStates[gameIndex].gameStartTimestamp.add(gameSettings[gameIndex].activityTimer) >= block.timestamp);
        } else {
             
            require(gameStates[gameIndex].identifierToBuyoutTimestamp[identifier].add(gameSettings[gameIndex].activityTimer) >= block.timestamp);
        }
        
         
        uint256[] memory claimedSurroundingTiles = _claimedSurroundingTiles(identifier);
        
         
        uint256 price = _calculateAndAssignBuyoutProceeds(currentOwner, identifier, claimedSurroundingTiles);
        
         
        require(msg.value >= price);
        
         
        _transfer(currentOwner, msg.sender, identifier);
        
         
        gameStates[gameIndex].lastFlippedTile = identifier;
        
         
        gameStates[gameIndex].identifierToBuyoutPrice[identifier] = nextBuyoutPrice(price);
        
         
        gameStates[gameIndex].identifierToBuyoutTimestamp[identifier] = block.timestamp;
        
         
        Buyout(gameIndex, msg.sender, identifier, x, y, block.timestamp, block.timestamp + gameSettings[gameIndex].activityTimer, gameStates[gameIndex].identifierToBuyoutPrice[identifier], gameStates[gameIndex].prizePool);
        
         
         
         
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
             
             
            msg.sender.transfer(excess);
        }
    }
    
     
     
     
     
     
    function buyoutAndSetReferrer(uint256 _gameIndex, bool startNewGameIfIdle, uint256 x, uint256 y, address referrerAddress) external payable {
         
        burnupHolding.setReferrer(msg.sender, referrerAddress);
    
         
        buyout(_gameIndex, startNewGameIfIdle, x, y);
    }
    
     
     
     
    function spiceUp(uint256 _gameIndex, string message) external payable {
         
        _processGameEnd();
        
         
        require(_gameIndex == gameIndex);
    
         
        require(gameStates[gameIndex].gameStarted || !paused);
        
         
        require(msg.value > 0);
        
         
        gameStates[gameIndex].prizePool = gameStates[gameIndex].prizePool.add(msg.value);
        
         
        SpiceUpPrizePool(gameIndex, msg.sender, msg.value, message, gameStates[gameIndex].prizePool);
    }
    
     
    function endGame() external {
        require(_processGameEnd());
    }
    
     
    function _processGameEnd() internal returns(bool) {
        address currentOwner = gameStates[gameIndex].identifierToOwner[gameStates[gameIndex].lastFlippedTile];
    
         
        if (!gameStates[gameIndex].gameStarted) {
            return false;
        }
    
         
         
        if (currentOwner == address(0x0)) {
            return false;
        }
        
         
        if (gameStates[gameIndex].identifierToBuyoutTimestamp[gameStates[gameIndex].lastFlippedTile].add(gameSettings[gameIndex].activityTimer) >= block.timestamp) {
            return false;
        }
        
         
        if (gameStates[gameIndex].prizePool > 0) {
            _sendFunds(currentOwner, gameStates[gameIndex].prizePool);
        }
        
         
        var (x, y) = identifierToCoordinate(gameStates[gameIndex].lastFlippedTile);
        
         
        End(gameIndex, currentOwner, gameStates[gameIndex].lastFlippedTile, x, y, gameStates[gameIndex].identifierToBuyoutTimestamp[gameStates[gameIndex].lastFlippedTile].add(gameSettings[gameIndex].activityTimer), gameStates[gameIndex].prizePool);
        
         
        gameIndex++;
        
         
        return true;
    }
}