 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

 

 
 
 
contract GoGlobals is Ownable, PullPayment, Destructible, Pausable {

     
    uint8 constant MAX_UINT8 = 255;

     
    enum PlayerColor {None, Black, White}

     
     
     
     
     
     
    enum BoardStatus {WaitForOpponent, InProgress, WaitingToResolve, BlackWin, WhiteWin, Draw, Canceled}

     
    uint8 constant BOARD_ROW_SIZE = 9;
    uint8 constant BOARD_SIZE = BOARD_ROW_SIZE ** 2;

     
    uint8 constant SHRINKED_BOARD_SIZE = 21;

     
    uint public WINNER_SHARE;
    uint public HOST_SHARE;
    uint public HONORABLE_LOSS_BONUS;

     
    uint  public PLAYER_TURN_SINGLE_PERIOD = 4 minutes;
    uint8 public PLAYER_START_PERIODS = 5;
    
     
    uint[] public tableStakesOptions;

     
    GoBoard[] internal allBoards;

     
    address public CFO;

     
    struct GoBoard {        
         
        uint lastUpdate;
        
         
        uint tableStakes;
        
         
        uint boardBalance;

         
        address blackAddress;
        address whiteAddress;

         
        uint8 blackPeriodsRemaining;
        uint8 whitePeriodsRemaining;

         
        bool didPassPrevTurn;
        
         
        bool isHonorableLoss;

         
        PlayerColor nextTurnColor;

         
         
        mapping(uint8=>uint8) positionToColor;

         
        BoardStatus status;
    }

     
    function GoGlobals() public Ownable() PullPayment() Destructible() {

         
        addPriceTier(0.5 ether);
        addPriceTier(1 ether);
        addPriceTier(5 ether);

         
        updateShares(950, 50, 5);
        
         
        CFO = owner;
    }

     
     
    function addPriceTier(uint price) public onlyOwner {
        tableStakesOptions.push(price);
    }

     
     
     
    function updatePriceTier(uint8 priceTier, uint price) public onlyOwner {
        tableStakesOptions[priceTier] = price;
    }

     
     
     
     
    function updateShares(uint newWinnerShare, uint newHostShare, uint newBonusShare) public onlyOwner {
        require(newWinnerShare + newHostShare == 1000);
        WINNER_SHARE = newWinnerShare;
        HOST_SHARE = newHostShare;
        HONORABLE_LOSS_BONUS = newBonusShare;
    }

     
     
    function setNewCFO(address newCFO) public onlyOwner {
        require(newCFO != 0);
        CFO = newCFO;
    }

     
     
     
    function updateGameTimes(uint secondsPerPeriod, uint8 numberOfPeriods) public onlyOwner {

        PLAYER_TURN_SINGLE_PERIOD = secondsPerPeriod;
        PLAYER_START_PERIODS = numberOfPeriods;
    }

     
    function getShares() public view returns(uint, uint, uint) {
        return (WINNER_SHARE, HOST_SHARE, HONORABLE_LOSS_BONUS);
    }
}

 

 
 
 
 
contract GoBoardMetaDetails is GoGlobals {
    
     
    event PlayerAddedToBoard(uint boardId, address playerAddress);
    
     
    event BoardStatusUpdated(uint boardId, BoardStatus newStatus);
    
     
    event PlayerWithdrawnBalance(address playerAddress);
    
     
    function getTotalNumberOfBoards() public view returns(uint) {
        return allBoards.length;
    }

     
    function getCompletedGamesStatistics() public view returns(uint, uint) {
        uint completed = 0;
        uint ethPaid = 0;
        
         
        for (uint i = 1; i <= allBoards.length; i++) {

             
            GoBoard storage board = allBoards[i - 1];
            
             
            if ((board.status == BoardStatus.BlackWin) || (board.status == BoardStatus.WhiteWin)) {
                ++completed;

                 
                ethPaid += board.tableStakes.mul(2);
            }
        }

        return (completed, ethPaid);
    }

     
    uint8 constant PAGE_SIZE = 50;

     
    modifier boardWaitingToResolve(uint boardId){
        require(allBoards[boardId].status == BoardStatus.WaitingToResolve);
        _;
    }

     
    modifier boardGameEnded(GoBoard storage board){
        require(isEndGameStatus(board.status));
        _;
    }

     
    modifier boardNotPaid(GoBoard storage board){
        require(board.boardBalance > 0);
        _;
    }

     
    modifier boardWaitingForPlayers(uint boardId){
        require(allBoards[boardId].status == BoardStatus.WaitForOpponent &&
                (allBoards[boardId].blackAddress == 0 || 
                 allBoards[boardId].whiteAddress == 0));
        _;
    }

     
     
    modifier allowedValuesOnly(uint value){
        bool didFindValue = false;
        
         
        for (uint8 i = 0; i < tableStakesOptions.length; ++ i) {
           if (value == tableStakesOptions[i])
            didFindValue = true;
        }

        require (didFindValue);
        _;
    }

     
     
     
    function isEndGameStatus(BoardStatus status) public pure returns(bool) {
        return (status == BoardStatus.BlackWin) || (status == BoardStatus.WhiteWin) || (status == BoardStatus.Draw) || (status == BoardStatus.Canceled);
    }

     
     
     
    function getBoardUpdateTime(uint boardId) public view returns(uint) {
        GoBoard storage board = allBoards[boardId];
        return (board.lastUpdate);
    }

     
     
     
    function getBoardStatus(uint boardId) public view returns(BoardStatus) {
        GoBoard storage board = allBoards[boardId];
        return (board.status);
    }

     
     
     
    function getBoardBalance(uint boardId) public view returns(uint) {
        GoBoard storage board = allBoards[boardId];
        return (board.boardBalance);
    }

     
     
     
     
    function updateBoardStatus(GoBoard storage board, uint boardId, BoardStatus newStatus) internal {    
        
         
        if (newStatus != board.status) {
            
             
            board.status = newStatus;
            
             
            board.lastUpdate = now;

             
            if (isEndGameStatus(newStatus)) {

                 
                creditBoardGameRevenues(board);
            }

             
            BoardStatusUpdated(boardId, newStatus);
        }
    }

     
     
     
    function updateBoardStatus(uint boardId, BoardStatus newStatus) internal {
        updateBoardStatus(allBoards[boardId], boardId, newStatus);
    }

     
     
     
     
    function getPlayerColor(uint boardId, address searchAddress) internal view returns (PlayerColor) {
        return (getPlayerColor(allBoards[boardId], searchAddress));
    }
    
     
     
     
     
    function getPlayerColor(GoBoard storage board, address searchAddress) internal view returns (PlayerColor) {

         
        if (board.blackAddress == searchAddress) {
            return (PlayerColor.Black);
        }

         
        if (board.whiteAddress == searchAddress) {
            return (PlayerColor.White);
        }

         
        revert();
    }

     
     
     
     
    function getPlayerAddress(uint boardId, PlayerColor color) public view returns(address) {

         
        if (color == PlayerColor.Black) {
            return allBoards[boardId].blackAddress;
        }

         
        if (color == PlayerColor.White) {
            return allBoards[boardId].whiteAddress;
        }

         
        revert();
    }

     
     
     
     
    function isPlayerOnBoard(uint boardId, address searchAddress) public view returns(bool) {
        return (isPlayerOnBoard(allBoards[boardId], searchAddress));
    }

     
     
     
     
    function isPlayerOnBoard(GoBoard storage board, address searchAddress) private view returns(bool) {
        return (board.blackAddress == searchAddress || board.whiteAddress == searchAddress);
    }

     
     
     
    function getNextTurnColor(uint boardId) public view returns(PlayerColor) {
        return allBoards[boardId].nextTurnColor;
    }

     
     
     
     
     
     
     
     
     
    function registerPlayerToBoard(uint tableStakes) external payable allowedValuesOnly(msg.value) whenNotPaused returns(uint) {
         
        require (msg.value == tableStakes);
        GoBoard storage boardToJoin;
        uint boardIDToJoin;
        
         
        (boardIDToJoin, boardToJoin) = getOrCreateWaitingBoard(tableStakes);
        
         
        bool shouldStartGame = addPlayerToBoard(boardToJoin, tableStakes);

         
        PlayerAddedToBoard(boardIDToJoin, msg.sender);

         
        if (shouldStartGame) {

             
            startBoardGame(boardToJoin, boardIDToJoin);
        }

        return boardIDToJoin;
    }

     
     
     
     
    function cancelMatch(uint boardId) external {
        
         
        GoBoard storage board = allBoards[boardId];

         
        require(isPlayerOnBoard(boardId, msg.sender));

         
        require(board.status == BoardStatus.WaitForOpponent);

         
        updateBoardStatus(board, boardId, BoardStatus.Canceled);
    }

     
     
     
    function getPlayerBoardsIDs(bool activeTurnsOnly) public view returns (uint, uint[PAGE_SIZE]) {
        uint[PAGE_SIZE] memory playerBoardIDsToReturn;
        uint numberOfPlayerBoardsToReturn = 0;
        
         
        for (uint currBoard = allBoards.length; currBoard > 0 && numberOfPlayerBoardsToReturn < PAGE_SIZE; currBoard--) {
            uint boardID = currBoard - 1;            

             
            if (isPlayerOnBoard(boardID, msg.sender)) {

                 
                if (!activeTurnsOnly || getNextTurnColor(boardID) == getPlayerColor(boardID, msg.sender)) {
                    playerBoardIDsToReturn[numberOfPlayerBoardsToReturn] = boardID;
                    ++numberOfPlayerBoardsToReturn;
                }
            }
        }

        return (numberOfPlayerBoardsToReturn, playerBoardIDsToReturn);
    }

     
     
     
    function createNewGoBoard(uint tableStakesToUse) private returns(uint, GoBoard storage) {
        GoBoard memory newBoard = GoBoard({lastUpdate: now,
                                           isHonorableLoss: false,
                                           tableStakes: tableStakesToUse,
                                           boardBalance: 0,
                                           blackAddress: 0,
                                           whiteAddress: 0,
                                           blackPeriodsRemaining: PLAYER_START_PERIODS,
                                           whitePeriodsRemaining: PLAYER_START_PERIODS,
                                           nextTurnColor: PlayerColor.None,
                                           status:BoardStatus.WaitForOpponent,
                                           didPassPrevTurn:false});

        uint boardId = allBoards.push(newBoard) - 1;
        return (boardId, allBoards[boardId]);
    }

     
     
     
    function getOrCreateWaitingBoard(uint tableStakes) private returns(uint, GoBoard storage) {
        bool wasFound = false;
        uint selectedBoardId = 0;
        GoBoard storage board;

         
        for (uint i = allBoards.length; i > 0 && !wasFound; --i) {
            board = allBoards[i - 1];

             
            if (board.tableStakes == tableStakes) {
                
                 
                if (board.status == BoardStatus.WaitForOpponent) {
                    
                     
                    wasFound = true;
                    selectedBoardId = i - 1;
                }

                 
                 
                break;
            }
        }

         
        if (!wasFound) {
            (selectedBoardId, board) = createNewGoBoard(tableStakes);
        }

        return (selectedBoardId, board);
    }

     
     
     
    function startBoardGame(GoBoard storage board, uint boardId) private {
        
         
        require(board.blackAddress != 0 && board.whiteAddress != 0);
        
         
        board.nextTurnColor = PlayerColor.Black;

         
        updateBoardStatus(board, boardId, BoardStatus.InProgress);
    }

     
     
     
     
    function addPlayerToBoard(GoBoard storage board, uint paidAmount) private returns(bool) {
        
         
        bool shouldStartTheGame = false;
        require(board.status == BoardStatus.WaitForOpponent);

         
        require(!isPlayerOnBoard(board, msg.sender));

         
        if (board.blackAddress == 0) {
            board.blackAddress = msg.sender;
        
         
        } else if (board.whiteAddress == 0) {
            board.whiteAddress = msg.sender;
        
             
            shouldStartTheGame = true;           

         
        } else {
            revert();
        }

         
        board.boardBalance += paidAmount;

        return shouldStartTheGame;
    }

     
     
     
    function getTimePeriodsUsed(uint lastUpdate) private view returns(uint8) {
        return uint8(now.sub(lastUpdate).div(PLAYER_TURN_SINGLE_PERIOD));
    }

     
     
     
     
    function getPlayerRemainingTime(uint boardId, PlayerColor color) view external returns (uint, uint, uint) {
        GoBoard storage board = allBoards[boardId];

         
        require(board.status == BoardStatus.InProgress);

         
        uint timePeriods = getPlayerTimePeriods(board, color);
        uint totalTimeRemaining = timePeriods * PLAYER_TURN_SINGLE_PERIOD;

         
        if (color == board.nextTurnColor) {

             
            uint timePeriodsUsed = getTimePeriodsUsed(board.lastUpdate);
            if (timePeriods > timePeriodsUsed) {
                timePeriods -= timePeriodsUsed;
            } else {
                timePeriods = 0;
            }

             
            uint timeUsed = (now - board.lastUpdate);
            
             
            if (totalTimeRemaining > timeUsed) {
                totalTimeRemaining -= timeUsed;
            
             
            } else {
                totalTimeRemaining = 0;
            }
        }
        
        return (timePeriods, PLAYER_TURN_SINGLE_PERIOD, totalTimeRemaining);
    }

     
     
     
     
    function updatePlayerTimePeriods(GoBoard storage board, PlayerColor color, uint8 timePeriodsUsed) internal {

         
        if (color == PlayerColor.Black) {

             
            board.blackPeriodsRemaining = board.blackPeriodsRemaining > timePeriodsUsed ? board.blackPeriodsRemaining - timePeriodsUsed : 0;
         
        } else if (color == PlayerColor.White) {
            
             
            board.whitePeriodsRemaining = board.whitePeriodsRemaining > timePeriodsUsed ? board.whitePeriodsRemaining - timePeriodsUsed : 0;

         
        } else {
            revert();
        }
    }

     
     
     
     
    function getPlayerTimePeriods(GoBoard storage board, PlayerColor color) internal view returns (uint8) {

         
        if (color == PlayerColor.Black) {
            return board.blackPeriodsRemaining;

         
        } else if (color == PlayerColor.White) {
            return board.whitePeriodsRemaining;

         
        } else {

            revert();
        }
    }

     
     
     
     
     
    function creditBoardGameRevenues(GoBoard storage board) private boardGameEnded(board) boardNotPaid(board) {
                
         
        uint updatedHostShare = HOST_SHARE;
        uint updatedLoserShare = 0;

         
        uint amountBlack = 0;
        uint amountWhite = 0;
        uint amountCFO = 0;
        uint fullAmount = 1000;

         
        if (board.status == BoardStatus.BlackWin || board.status == BoardStatus.WhiteWin) {
            
             
            if (board.isHonorableLoss) {
                
                 
                updatedHostShare = HOST_SHARE - HONORABLE_LOSS_BONUS;
                
                 
                updatedLoserShare = HONORABLE_LOSS_BONUS;
            }

             
            if (board.status == BoardStatus.BlackWin) {
                
                 
                amountBlack = board.boardBalance.mul(WINNER_SHARE).div(fullAmount);
                
                 
                amountWhite = board.boardBalance.mul(updatedLoserShare).div(fullAmount);
            }

             
            if (board.status == BoardStatus.WhiteWin) {

                 
                amountWhite = board.boardBalance.mul(WINNER_SHARE).div(fullAmount);
                
                 
                amountBlack = board.boardBalance.mul(updatedLoserShare).div(fullAmount);
            }

             
            amountCFO = board.boardBalance.mul(updatedHostShare).div(fullAmount);
        }

         
        if (board.status == BoardStatus.Draw || board.status == BoardStatus.Canceled) {
            
             
            amountCFO = 0;

             
            if (board.whiteAddress != 0) {

                 
                amountBlack = board.boardBalance.div(2);
                amountWhite = board.boardBalance.div(2);

             
            } else {
                amountBlack = board.boardBalance;
            }
        }

         
        assert(amountBlack + amountWhite + amountCFO == board.boardBalance);
        
         
        board.boardBalance = 0;

         
        asyncSend(board.blackAddress, amountBlack);
        asyncSend(board.whiteAddress, amountWhite);
        asyncSend(CFO, amountCFO);
    }

     
    function withdrawPayments() public {

         
        super.withdrawPayments();

         
        PlayerWithdrawnBalance(msg.sender);
    }
}

 

 
 
contract GoGameLogic is GoBoardMetaDetails {

     
     
    event StoneAddedToBoard(uint boardId, PlayerColor color, uint8 row, uint8 col);

     
     
    event PlayerPassedTurn(uint boardId, PlayerColor color);
    
     
     
     
     
     
     
    function updatePlayerTime(GoBoard storage board, uint boardId, PlayerColor color) private returns(bool) {

         
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == color);

         
        uint timePeriodsUsed = uint(now.sub(board.lastUpdate).div(PLAYER_TURN_SINGLE_PERIOD));

         
        if (timePeriodsUsed > 0) {

             
            updatePlayerTimePeriods(board, color, timePeriodsUsed > MAX_UINT8 ? MAX_UINT8 : uint8(timePeriodsUsed));

             
            if (getPlayerTimePeriods(board, color) == 0) {
                playerLost(board, boardId, color);
                return false;
            }
        }

        return true;
    }

     
     
     
    function checkVictoryByScore(uint boardId) external boardWaitingToResolve(boardId) {
        
        uint8 blackScore;
        uint8 whiteScore;

         
        (blackScore, whiteScore) = calculateBoardScore(boardId);

         
        BoardStatus status = BoardStatus.Draw;

         
        if (blackScore > whiteScore) {

            status = BoardStatus.BlackWin;
         
        } else if (whiteScore > blackScore) {

            status = BoardStatus.WhiteWin;
        }

         
        updateBoardStatus(boardId, status);
    }

     
     
    function passTurn(uint boardId) external {

         
        GoBoard storage board = allBoards[boardId];
        PlayerColor activeColor = getPlayerColor(board, msg.sender);

         
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == activeColor);
        
         
        if (updatePlayerTime(board, boardId, activeColor)) {

             
            if (board.didPassPrevTurn) {

                 
                board.isHonorableLoss = true;

                 
                updateBoardStatus(board, boardId, BoardStatus.WaitingToResolve);

             
            } else {

                 
                nextTurn(board);
                board.didPassPrevTurn = true;

                 
                PlayerPassedTurn(boardId, activeColor);
            }
        }
    }

     
     
    function resignFromMatch(uint boardId) external {

         
        GoBoard storage board = allBoards[boardId];
        require(board.status == BoardStatus.InProgress);

         
        PlayerColor activeColor = getPlayerColor(board, msg.sender);
                
         
        board.isHonorableLoss = true;

         
        playerLost(board, boardId, activeColor);
    }

     
     
    function claimActingPlayerOutOfTime(uint boardId) external {

         
        GoBoard storage board = allBoards[boardId];
        require(board.status == BoardStatus.InProgress);

         
        PlayerColor actingPlayerColor = getNextTurnColor(boardId);

         
        uint playerTimeRemaining = PLAYER_TURN_SINGLE_PERIOD * getPlayerTimePeriods(board, actingPlayerColor);

         
        if (playerTimeRemaining < now - board.lastUpdate) {
            playerLost(board, boardId, actingPlayerColor);
        }
    }

     
     
     
     
    function playerLost(GoBoard storage board, uint boardId, PlayerColor color) private {

         
        if (color == PlayerColor.Black) {
            updateBoardStatus(board, boardId, BoardStatus.WhiteWin);
        
         
        } else if (color == PlayerColor.White) {
            updateBoardStatus(board, boardId, BoardStatus.BlackWin);

         
        } else {
            revert();
        }
    }

     
     
    function nextTurn(GoBoard storage board) private {
        
         
        board.nextTurnColor = board.nextTurnColor == PlayerColor.Black ? PlayerColor.White : PlayerColor.Black;

         
        board.lastUpdate = now;
    }
    
     
     
     
     
     
     
    function addStoneToBoard(uint boardId, uint8 row, uint8 col) external {
        
         
        GoBoard storage board = allBoards[boardId];
        PlayerColor activeColor = getPlayerColor(board, msg.sender);

         
        require(board.status == BoardStatus.InProgress && board.nextTurnColor == activeColor);

         
        uint8 position = row * BOARD_ROW_SIZE + col;
        
         
        require(board.positionToColor[position] == 0);

         
        if (updatePlayerTime(board, boardId, activeColor)) {

             
            board.positionToColor[position] = uint8(activeColor);

             
            updateCaptures(board, position, uint8(activeColor));
            
             
            nextTurn(board);

             
            if (board.didPassPrevTurn) {
                board.didPassPrevTurn = false;
            }

             
            StoneAddedToBoard(boardId, activeColor, row, col);
        }
    }

     
     
     
     
     
    function getBoardRowDetails(uint boardId, uint8 row) external view returns (uint8[BOARD_ROW_SIZE]) {
        
         
        uint8[BOARD_ROW_SIZE] memory rowToReturn;

         
        for (uint8 col = 0; col < BOARD_ROW_SIZE; col++) {
            
            uint8 position = row * BOARD_ROW_SIZE + col;
            rowToReturn[col] = allBoards[boardId].positionToColor[position];
        }

         
        return (rowToReturn);
    }

     
     
     
     
     
    function getBoardSingleSpaceDetails(uint boardId, uint8 row, uint8 col) external view returns (uint8) {

        uint8 position = row * BOARD_ROW_SIZE + col;
        return allBoards[boardId].positionToColor[position];
    }

     
     
     
     
     
    function updateCaptures(GoBoard storage board, uint8 position, uint8 positionColor) private {

         
        uint8[BOARD_SIZE] memory group;

         
        bool isGroupCaptured;

         
        bool shouldCheckSuicide = true;

         
        uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

         
        for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {

             
            uint8 currColor = board.positionToColor[adjacentArray[currAdjacentIndex]];

             
            if (currColor != 0 && currColor != positionColor) {

                 
                (group, isGroupCaptured) = getGroup(board, adjacentArray[currAdjacentIndex], currColor);

                 
                if (isGroupCaptured) {
                    
                     
                    for (uint8 currGroupIndex = 0; currGroupIndex < BOARD_SIZE && group[currGroupIndex] < MAX_UINT8; currGroupIndex++) {

                        board.positionToColor[group[currGroupIndex]] = 0;
                    }

                     
                    shouldCheckSuicide = false;
                }
             
            } else if (currColor == 0) {

                 
                shouldCheckSuicide = false;
            }
        }

         
        if (shouldCheckSuicide) {

             
            (group, isGroupCaptured) = getGroup(board, position, positionColor);

             
            if (isGroupCaptured) {

                 
                board.positionToColor[position] = 0;
            }
        }
    }

     
     
     
     
    function setFlag(uint8[SHRINKED_BOARD_SIZE] visited, uint8 position, uint8 flag) private pure {
        visited[position / 4] |= flag << ((position % 4) * 2);
    }

     
     
     
     
     
    function isFlagSet(uint8[SHRINKED_BOARD_SIZE] visited, uint8 position, uint8 flag) private pure returns (bool) {
        return (visited[position / 4] & (flag << ((position % 4) * 2)) > 0);
    }

     
    uint8 constant FLAG_POSITION_WAS_IN_STACK = 1;
    uint8 constant FLAG_DID_VISIT_POSITION = 2;

     
     
     
     
     
     
     
     
     
     
    function getGroup(GoBoard storage board, uint8 position, uint8 positionColor) private view returns (uint8[BOARD_SIZE], bool isGroupCaptured) {

         
        uint8[BOARD_SIZE] memory groupPositions;
        uint8 groupSize = 0;
        
         
        uint8[SHRINKED_BOARD_SIZE] memory visited;

         
        uint8[BOARD_SIZE] memory stack;
        stack[0] = position;
        uint8 stackSize = 1;

         
        setFlag(visited, position, FLAG_POSITION_WAS_IN_STACK);

         
        while (stackSize > 0) {

             
            position = stack[--stackSize];
            stack[stackSize] = 0;

             
            if (!isFlagSet(visited, position, FLAG_DID_VISIT_POSITION)) {
                
                 
                setFlag(visited, position, FLAG_DID_VISIT_POSITION);

                 
                groupPositions[groupSize++] = position;

                 
                uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

                 
                for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {
                    
                     
                    uint8 currColor = board.positionToColor[adjacentArray[currAdjacentIndex]];
                    
                     
                    if (currColor == positionColor) {

                         
                        if (!isFlagSet(visited, adjacentArray[currAdjacentIndex], FLAG_POSITION_WAS_IN_STACK)) {
                            stack[stackSize++] = adjacentArray[currAdjacentIndex];
                            setFlag(visited, adjacentArray[currAdjacentIndex], FLAG_POSITION_WAS_IN_STACK);
                        }
                     
                    } else if (currColor == 0) {
                        
                        return (groupPositions, false);
                    }
                }
            }
        }

         
        if (groupSize < BOARD_SIZE) {
            groupPositions[groupSize] = MAX_UINT8;
        }
        
         
        return (groupPositions, true);
    }
    
     
    uint8 constant MAX_ADJACENT_CELLS = 4;

     
     
     
    function getAdjacentCells(uint8 position) private pure returns (uint8[MAX_ADJACENT_CELLS]) {

         
        uint8[MAX_ADJACENT_CELLS] memory returnCells = [MAX_UINT8, MAX_UINT8, MAX_UINT8, MAX_UINT8];
        uint8 adjacentCellsIndex = 0;

         
        if (position / BOARD_ROW_SIZE > 0) {
            returnCells[adjacentCellsIndex++] = position - BOARD_ROW_SIZE;
        }

         
        if (position / BOARD_ROW_SIZE < BOARD_ROW_SIZE - 1) {
            returnCells[adjacentCellsIndex++] = position + BOARD_ROW_SIZE;
        }

         
        if (position % BOARD_ROW_SIZE > 0) {
            returnCells[adjacentCellsIndex++] = position - 1;
        }

         
        if (position % BOARD_ROW_SIZE < BOARD_ROW_SIZE - 1) {
            returnCells[adjacentCellsIndex++] = position + 1;
        }

        return returnCells;
    }

     
     
     
    function calculateBoardScore(uint boardId) public view returns (uint8 blackScore, uint8 whiteScore) {

        GoBoard storage board = allBoards[boardId];
        uint8[BOARD_SIZE] memory boardEmptyGroups;
        uint8 maxEmptyGroupId;
        (boardEmptyGroups, maxEmptyGroupId) = getBoardEmptyGroups(board);
        uint8[BOARD_SIZE] memory groupsSize;
        uint8[BOARD_SIZE] memory groupsState;
        
        blackScore = 0;
        whiteScore = 0;

         
        for (uint8 position = 0; position < BOARD_SIZE; position++) {

            if (PlayerColor(board.positionToColor[position]) == PlayerColor.Black) {

                blackScore++;
            } else if (PlayerColor(board.positionToColor[position]) == PlayerColor.White) {

                whiteScore++;
            } else {

                uint8 groupId = boardEmptyGroups[position];
                groupsSize[groupId]++;

                 
                if ((groupsState[groupId] & uint8(PlayerColor.Black) == 0) || (groupsState[groupId] & uint8(PlayerColor.White) == 0)) {

                    uint8[MAX_ADJACENT_CELLS] memory adjacentArray = getAdjacentCells(position);

                     
                    for (uint8 currAdjacentIndex = 0; currAdjacentIndex < MAX_ADJACENT_CELLS && adjacentArray[currAdjacentIndex] < MAX_UINT8; currAdjacentIndex++) {

                         
                        if ((PlayerColor(board.positionToColor[adjacentArray[currAdjacentIndex]]) == PlayerColor.Black) && 
                            (groupsState[groupId] & uint8(PlayerColor.Black) == 0)) {

                            groupsState[groupId] |= uint8(PlayerColor.Black);

                         
                        } else if ((PlayerColor(board.positionToColor[adjacentArray[currAdjacentIndex]]) == PlayerColor.White) && 
                                   (groupsState[groupId] & uint8(PlayerColor.White) == 0)) {

                            groupsState[groupId] |= uint8(PlayerColor.White);
                        }
                    }
                }
            }
        }

         
        for (uint8 currGroupId = 1; currGroupId < maxEmptyGroupId; currGroupId++) {
            
             
            if ((groupsState[currGroupId] & uint8(PlayerColor.Black) > 0) &&
                (groupsState[currGroupId] & uint8(PlayerColor.White) == 0)) {

                blackScore += groupsSize[currGroupId];

             
            } else if ((groupsState[currGroupId] & uint8(PlayerColor.White) > 0) &&
                       (groupsState[currGroupId] & uint8(PlayerColor.Black) == 0)) {

                whiteScore += groupsSize[currGroupId];
            }
        }

        return (blackScore, whiteScore);
    }

     
     
     
    function getBoardEmptyGroups(GoBoard storage board) private view returns (uint8[BOARD_SIZE], uint8) {

        uint8[BOARD_SIZE] memory boardEmptyGroups;
        uint8 nextGroupId = 1;

        for (uint8 position = 0; position < BOARD_SIZE; position++) {

            PlayerColor currPositionColor = PlayerColor(board.positionToColor[position]);

            if ((currPositionColor == PlayerColor.None) && (boardEmptyGroups[position] == 0)) {

                uint8[BOARD_SIZE] memory emptyGroup;
                bool isGroupCaptured;
                (emptyGroup, isGroupCaptured) = getGroup(board, position, 0);

                for (uint8 currGroupIndex = 0; currGroupIndex < BOARD_SIZE && emptyGroup[currGroupIndex] < MAX_UINT8; currGroupIndex++) {

                    boardEmptyGroups[emptyGroup[currGroupIndex]] = nextGroupId;
                }

                nextGroupId++;
            }
        }

        return (boardEmptyGroups, nextGroupId);
    }
}