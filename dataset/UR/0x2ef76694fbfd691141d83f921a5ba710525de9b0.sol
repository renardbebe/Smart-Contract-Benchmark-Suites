 

 
 
 
 
contract LooneyLottery {
   
  modifier owneronly {
     
    if (msg.sender != owner) {
      throw;
    }

     
    _
  }

   
  uint constant private LEHMER_MOD = 4294967291;
  uint constant private LEHMER_MUL = 279470273;
  uint constant private LEHMER_SDA = 1299709;
  uint constant private LEHMER_SDB = 7919;

   
  uint constant public CONFIG_DURATION = 24 hours;
  uint constant public CONFIG_MIN_PLAYERS  = 5;
  uint constant public CONFIG_MAX_PLAYERS  = 222;
  uint constant public CONFIG_MAX_TICKETS = 100;
  uint constant public CONFIG_PRICE = 10 finney;
  uint constant public CONFIG_FEES = 50 szabo;
  uint constant public CONFIG_RETURN = CONFIG_PRICE - CONFIG_FEES;
  uint constant public CONFIG_MIN_VALUE = CONFIG_PRICE;
  uint constant public CONFIG_MAX_VALUE = CONFIG_PRICE * CONFIG_MAX_TICKETS;

   
  address private owner = msg.sender;

   
  uint private random = uint(sha3(block.coinbase, block.blockhash(block.number - 1), now));
  uint private seeda = LEHMER_SDA;
  uint private seedb = LEHMER_SDB;

   
  uint8[22500] private tickets;
  mapping (uint => address) private players;

   
  uint public round = 1;
  uint public numplayers = 0;
  uint public numtickets = 0;
  uint public start = now;
  uint public end = start + CONFIG_DURATION;

   
  uint public txs = 0;
  uint public tktotal = 0;
  uint public turnover = 0;

   
  function LooneyLottery() {
  }

   
  function ownerWithdraw() owneronly public {
     
    uint fees = this.balance - (numtickets * CONFIG_PRICE);

     
    if (fees > 0) {
      owner.call.value(fees)();
    }
  }

   
  function randomize() private {
     
    seeda = (seeda * LEHMER_MUL) % LEHMER_MOD;

     
    random ^= uint(sha3(block.coinbase, block.blockhash(block.number - 1), seeda, seedb));

     
    seedb = (seedb * LEHMER_MUL) % LEHMER_MOD;
  }

   
  function pickWinner() private {
     
    if ((numplayers >= CONFIG_MAX_PLAYERS ) || ((numplayers >= CONFIG_MIN_PLAYERS ) && (now > end))) {
       
      uint winidx = tickets[random % numtickets];
      uint output = numtickets * CONFIG_RETURN;

       
      players[winidx].call.value(output)();
      notifyWinner(players[winidx], output);

       
      numplayers = 0;
      numtickets = 0;
      start = now;
      end = start + CONFIG_DURATION;
      round++;
    }
  }

   
  function allocateTickets(uint number) private {
     
    uint ticketmax = numtickets + number;

     
    for (uint idx = numtickets; idx < ticketmax; idx++) {
      tickets[idx] = uint8(numplayers);
    }

     
    numtickets = ticketmax;

     
    players[numplayers] = msg.sender;
    numplayers++;

     
    notifyPlayer(number);
  }

   
  function() public {
     
    if (msg.value < CONFIG_MIN_VALUE) {
      throw;
    }

     
    randomize();

     
    pickWinner();

     
    uint number = 0;

     
    if (msg.value >= CONFIG_MAX_VALUE) {
      number = CONFIG_MAX_TICKETS;
    } else {
      number = msg.value / CONFIG_PRICE;
    }

     
    uint input = number * CONFIG_PRICE;
    uint overflow = msg.value - input;

     
    turnover += input;
    tktotal += number;
    txs += 1;

     
    allocateTickets(number);

     
    if (overflow > 0) {
      msg.sender.call.value(overflow)();
    }
  }

   
  event Player(address addr, uint32 at, uint32 round, uint32 tickets, uint32 numtickets, uint tktotal, uint turnover);
  event Winner(address addr, uint32 at, uint32 round, uint32 numtickets, uint output);

   
  function notifyPlayer(uint number) private {
    Player(msg.sender, uint32(now), uint32(round), uint32(number), uint32(numtickets), tktotal, turnover);
  }

   
  function notifyWinner(address addr, uint output) private {
    Winner(addr, uint32(now), uint32(round), uint32(numtickets), output);
  }
}