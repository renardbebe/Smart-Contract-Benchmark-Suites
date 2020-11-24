 

pragma solidity ^0.4.21;

 

interface Bankroll {

     

     
    function credit(address _customerAddress, uint256 amount) external returns (uint256);

     
    function debit(address _customerAddress, uint256 amount) external returns (uint256);

     
    function withdraw(address _customerAddress) external returns (uint256);

     
    function balanceOf(address _customerAddress) external view returns (uint256);

     
    function statsOf(address _customerAddress) external view returns (uint256[8]);


     

     
    function deposit() external payable;

     
    function depositBy(address _customerAddress) external payable;

     
    function houseProfit(uint256 amount)  external;


     
    function netEthereumBalance() external view returns (uint256);


     
    function totalEthereumBalance() external view returns (uint256);

}

 

 
contract SessionQueue {

    mapping(uint256 => address) private queue;
    uint256 private first = 1;
    uint256 private last = 0;

     
    function enqueue(address data) internal {
        last += 1;
        queue[last] = data;
    }

     
    function available() internal view returns (bool) {
        return last >= first;
    }

     
    function depth() internal view returns (uint256) {
        return last - first + 1;
    }

     
    function dequeue() internal returns (address data) {
        require(last >= first);
         

        data = queue[first];

        delete queue[first];
        first += 1;
    }

     
    function peek() internal view returns (address data) {
        require(last >= first);
         

        data = queue[first];
    }
}

 

 
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

 

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

 

 





contract Dice is Whitelist, SessionQueue {

    using SafeMath for uint;

     
    modifier betIsValid(uint _betSize, uint _playerNumber) {
        bool result = ((((_betSize * (100 - _playerNumber.sub(1))) / (_playerNumber.sub(1)) + _betSize)) * houseEdge / houseEdgeDivisor) - _betSize > maxProfit || _betSize < minBet || _playerNumber < minNumber || _playerNumber > maxNumber;
        require(!result);
        _;
    }

     
    modifier gameIsActive {
        require(!gamePaused);
        _;
    }


     

    event  onSessionOpen(
        uint indexed id,
        uint block,
        uint futureBlock,
        address player,
        uint wager,
        uint rollUnder,
        uint profit
    );

    event onSessionClose(
        uint indexed id,
        uint block,
        uint futureBlock,
        uint futureHash,
        uint seed,
        address player,
        uint wager,
        uint rollUnder,
        uint dieRoll,
        uint payout,
        bool timeout
    );

    event onCredit(address player, uint amount);
    event onWithdraw(address player, uint amount);

     

    struct Session {
        uint id;
        uint block;
        uint futureBlock;
        uint futureHash;
        address player;
        uint wager;
        uint dieRoll;
        uint seed;
        uint rollUnder;
        uint profit;
        uint payout;
        bool complete;
        bool timeout;

    }

    struct Stats {
        uint rolls;
        uint wagered;
        uint profit;
        uint wins;
        uint loss;
    }

     
    uint constant public maxProfitDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    uint constant public maxNumber = 99;
    uint constant public minNumber = 2;
    uint constant public futureDelta = 2;
    uint internal  sessionProcessingCap = 3;
    bool public gamePaused;
    bool public payoutsPaused;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint maxPendingPayouts;
    uint public minBet;
    uint public totalSessions;
    uint public totalBets;
    uint public totalWon;
    uint public totalWagered;
    uint private seed;

     

    mapping(address => Session) sessions;
    mapping(address => Stats) stats;

    mapping(bytes32 => bytes32) playerBetId;
    mapping(bytes32 => uint) playerBetValue;
    mapping(bytes32 => uint) playerTempBetValue;
    mapping(bytes32 => uint) playerDieResult;
    mapping(bytes32 => uint) playerNumber;
    mapping(address => uint) playerPendingWithdrawals;
    mapping(bytes32 => uint) playerProfit;
    mapping(bytes32 => uint) playerTempReward;

     
    Bankroll public bankroll;



    constructor() public {
         
        ownerSetHouseEdge(990);
         
        ownerSetMaxProfitAsPercentOfHouse(10000);
         
        ownerSetMinBet(10000000000000000);
    }

     
    function updateBankrollAddress(address bankrollAddress) onlyOwner public {
        bankroll = Bankroll(bankrollAddress);
        setMaxProfit();
    }

    function contractBalance() internal view returns (uint256){
        return bankroll.netEthereumBalance();
    }

     

    function play(uint rollUnder) payable public {

         
        bankroll.depositBy.value(msg.value)(msg.sender);

         
        rollDice(rollUnder, msg.value);
    }


     

    function playWithVault(uint rollUnder, uint wager) public {
         
        require(bankroll.balanceOf(msg.sender) >= wager);

         
        bankroll.debit(msg.sender, wager);

         
        rollDice(rollUnder, wager);
    }


     
    function rollDice(uint rollUnder, uint wager) internal gameIsActive betIsValid(wager, rollUnder)
    {

         
        processSessions();

        Session memory session = sessions[msg.sender];

         
        require(block.number != session.block, "Only one roll can be played at a time");

         
        if (session.block != 0 && !session.complete) {
            require(completeSession(msg.sender), "Only one roll can be played at a time");
        }

         
        totalSessions += 1;

         
        session.complete = false;
        session.timeout = false;
        session.payout = 0;

        session.block = block.number;
        session.futureBlock = block.number + futureDelta;
        session.player = msg.sender;
        session.rollUnder = rollUnder;
        session.wager = wager;

        session.profit = profit(rollUnder, wager);

        session.id = generateSessionId(session);

         
        sessions[msg.sender] = session;

         
        maxPendingPayouts = maxPendingPayouts.add(session.profit);

         
        require(maxPendingPayouts < contractBalance(), "Reached maximum wagers supported");

         
        totalBets += 1;

         
        totalWagered += session.wager;


         
        queueSession(session);

         
        stats[session.player].rolls += 1;
        stats[session.player].wagered += session.wager;

         
        emit  onSessionOpen(session.id, session.block, session.futureBlock, session.player, session.wager, session.rollUnder, session.profit);
    }

     
    function queueSession(Session session) internal {
        enqueue(session.player);

    }

     
    function processSessions() internal {
        uint256 count = 0;
        address session;

        while (available() && count < sessionProcessingCap) {

             
            session = peek();

            if (sessions[session].complete || completeSession(session)) {
                dequeue();
                count++;
            } else {
                break;
            }
        }
    }


     
    function closeSession() public {

        Session memory session = sessions[msg.sender];

         
        if (session.block != 0 && !session.complete) {
            require(completeSession(msg.sender), "Only one roll can be played at a time");
        }
    }




     
    function random(Session session) private returns (uint256, uint256, uint256){
        uint blockHash = uint256(blockhash(session.futureBlock));
        seed = uint256(keccak256(abi.encodePacked(seed, blockHash, session.id)));
        return (seed, blockHash, seed % maxNumber);
    }

    function profit(uint rollUnder, uint wager) public view returns (uint) {

        return ((((wager * (100 - (rollUnder.sub(1)))) / (rollUnder.sub(1)) + wager)) * houseEdge / houseEdgeDivisor) - wager;
    }

     
    function generateSessionId(Session session) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, blockhash(block.number - 1), totalSessions, session.player, session.wager, session.rollUnder, session.profit)));
    }


     
    function completeSession(address _customer) private returns (bool)
    {

        Session memory session = sessions[_customer];


         
        if (!(block.number > session.futureBlock)) {
            return false;
        }


         
         
        if (block.number - session.futureBlock > 256) {
            session.timeout = true;
            session.dieRoll = 100;
        } else {
            (session.seed, session.futureHash, session.dieRoll) = random(session);
            session.timeout = false;
        }

         
        maxPendingPayouts = maxPendingPayouts.sub(session.profit);


         
        if (session.dieRoll < session.rollUnder) {

             
            totalWon = totalWon.add(session.profit);

             
            session.payout = session.profit.add(session.wager);

             
            stats[session.player].profit += session.profit;
            stats[session.player].wins += 1;


             

            bankroll.credit(session.player, session.payout);

        }

         
        else {

             

            bankroll.houseProfit(session.wager);

             
            stats[session.player].loss += 1;

        }

         
        setMaxProfit();

         
        closeSession(session);

        return true;

    }

     
    function closeSession(Session session) internal {

        session.complete = true;

         
        sessions[session.player] = session;
        emit onSessionClose(session.id, session.block, session.futureBlock, session.futureHash, session.seed, session.player, session.wager, session.rollUnder, session.dieRoll, session.payout, session.timeout);

    }

     

    function isMining() public view returns (bool) {
        Session memory session = sessions[msg.sender];

         
        return session.block != 0 && !session.complete && block.number <= session.futureBlock;
    }

     
    function withdraw() public
    {

         
        closeSession();
        bankroll.withdraw(msg.sender);
    }

     
    function balanceOf(address player) public view returns (uint) {
        return bankroll.balanceOf(player);
    }

     
    function statsOf(address player) public view returns (uint256[5]){
        Stats memory s = stats[player];
        uint256[5] memory statArray = [s.rolls, s.wagered, s.profit, s.wins, s.loss];
        return statArray;
    }

     
    function lastSession(address player) public view returns (address, uint[7], bytes32[3], bool[2]) {
        Session memory s = sessions[player];
        return (s.player, [s.block, s.futureBlock, s.wager, s.dieRoll, s.rollUnder, s.profit, s.payout], [bytes32(s.id), bytes32(s.futureHash), bytes32(s.seed)], [s.complete, s.timeout]);
    }

     
    function setMaxProfit() internal {
        if (address(bankroll) != address(0)) {
            maxProfit = (contractBalance() * maxProfitAsPercentOfHouse) / maxProfitDivisor;
        }
    }


     
    function ownerSetHouseEdge(uint newHouseEdge) public
    onlyOwner
    {
        houseEdge = newHouseEdge;
    }

     
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
    onlyOwner
    {
         
        require(newMaxProfitAsPercent <= 10000, "Maximum bet exceeded");
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

     
    function ownerSetMinBet(uint newMinimumBet) public
    onlyOwner
    {
        minBet = newMinimumBet;
    }

     
    function ownerSetProcessingCap(uint cap) public onlyOwner {
        sessionProcessingCap = cap;
    }

     
    function ownerPauseGame(bool newStatus) public
    onlyOwner
    {
        gamePaused = newStatus;
    }

}