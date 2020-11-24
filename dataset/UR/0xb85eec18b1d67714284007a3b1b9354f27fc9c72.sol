 

pragma solidity 0.4.19;

 
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

contract Restriction {
    mapping (address => bool) internal accesses;

    function Restriction() public {
        accesses[msg.sender] = true;
    }

    function giveAccess(address _addr) public restricted {
        accesses[_addr] = true;
    }

    function removeAccess(address _addr) public restricted {
        delete accesses[_addr];
    }

    function hasAccess() public constant returns (bool) {
        return accesses[msg.sender];
    }

    modifier restricted() {
        require(hasAccess());
        _;
    }
}

contract DreamConstants {
    uint constant MINIMAL_DREAM = 3 ether;
    uint constant TICKET_PRICE = 0.1 ether;
    uint constant MAX_TICKETS = 2**32;
    uint constant MAX_AMOUNT = 2**32 * TICKET_PRICE;
    uint constant DREAM_K = 2;
    uint constant ACCURACY = 10**18;
    uint constant REFUND_AFTER = 90 days;
}

contract TicketHolder is Restriction, DreamConstants {
    struct Ticket {
        uint32 ticketAmount;
        uint32 playerIndex;
        uint dreamAmount;
    }

    uint64 public totalTickets;
    uint64 public maxTickets;

    mapping (address => Ticket) internal tickets;

    address[] internal players;

    function TicketHolder(uint _maxTickets) {
        maxTickets = uint64(_maxTickets);
    }

     
    function issueTickets(address _addr, uint _ticketAmount, uint _dreamAmount) public restricted {
        require(_ticketAmount <= MAX_TICKETS);
        require(totalTickets <= maxTickets);
        Ticket storage ticket = tickets[_addr];

         
        if (ticket.ticketAmount == 0) {
            require(_dreamAmount >= MINIMAL_DREAM);
            ticket.dreamAmount = _dreamAmount;
            ticket.playerIndex = uint32(players.length);
            players.push(_addr);
        }


         
        ticket.ticketAmount += uint32(_ticketAmount);
         
        require(ticket.ticketAmount >= _ticketAmount);

         
        totalTickets += uint64(_ticketAmount);
         
        require(totalTickets >= _ticketAmount);
    }

    function setWinner(address _addr) public restricted {
        Ticket storage ticket = tickets[_addr];
        require(ticket.ticketAmount != 0);
        ticket.ticketAmount = 0;
    }

    function getTickets(uint index) public constant returns (address addr, uint ticketAmount, uint dreamAmount) {
        if (players.length == 0) {
            return;
        }
        if (index > players.length - 1) {
            return;
        }

        addr = players[index];
        Ticket storage ticket = tickets[addr];
        ticketAmount = ticket.ticketAmount;
        dreamAmount = ticket.dreamAmount;
    }

    function getTicketsByAddress(address _addr) public constant returns (uint playerIndex, uint ticketAmount, uint dreamAmount) {
        Ticket storage ticket = tickets[_addr];
        playerIndex = ticket.playerIndex;
        ticketAmount = ticket.ticketAmount;
        dreamAmount = ticket.dreamAmount;
    }

    function getPlayersCount() public constant returns (uint) {
        return players.length;
    }
}

contract Fund is Restriction, DreamConstants {
    using SafeMath for uint256;

    mapping (address => uint) public balances;

    event Pay(address receiver, uint amount);
    event Refund(address receiver, uint amount);

     
    uint public totalAmount;
     
    uint internal totalPrizeAmount;
     
    uint32 internal refundDate;
     
    address internal beneficiary;

    function Fund(uint _absoluteRefundDate, address _beneficiary) public {
        refundDate = uint32(_absoluteRefundDate);
        beneficiary = _beneficiary;
    }

    function deposit(address _addr) public payable restricted {
        uint balance = balances[_addr];

        balances[_addr] = balance.add(msg.value);
        totalAmount = totalAmount.add(msg.value);
    }

    function withdraw(uint amount) public restricted {
        beneficiary.transfer(amount);
    }

     
    function pay(address _addr, uint _amountWei) public restricted {
         
        require(this.balance >= _amountWei);
        require(balances[_addr] != 0);
        delete balances[_addr];
        totalPrizeAmount = totalPrizeAmount.add(_amountWei);
         
        _addr.transfer(_amountWei);
        Pay(_addr, _amountWei);
    }

     
    function isPayed(address _addr) public constant returns (bool) {
        return balances[_addr] == 0;
    }

    function enableRefund() public restricted {
        require(refundDate > uint32(block.timestamp));
        refundDate = uint32(block.timestamp);
    }

    function refund(address _addr) public restricted {
        require(refundDate >= uint32(block.timestamp));
        require(balances[_addr] != 0);
        uint amount = refundAmount(_addr);
        delete balances[_addr];
        _addr.transfer(amount);
        Refund(_addr, amount);
    }

    function refundAmount(address _addr) public constant returns (uint) {
        uint balance = balances[_addr];
        uint restTotal = totalAmount.sub(totalPrizeAmount);
        uint share = balance.mul(ACCURACY).div(totalAmount);
        return restTotal.mul(share).div(ACCURACY);
    }
}

contract RandomOraclizeProxyI {
    function requestRandom(function (bytes32) external callback, uint _gasLimit) public payable;
    function getRandomPrice(uint _gasLimit) public constant returns (uint);
}
contract CompaniesManagerInterface {
    function processing(address player, uint amount, uint ticketCount, uint totalTickets) public;
}



contract TicketSale is Restriction, DreamConstants {
    using SafeMath for uint256;
    uint constant RANDOM_GAS = 1000000;

    TicketHolder public ticketHolder;
    Fund public fund;
    RandomOraclizeProxyI private proxy;
    CompaniesManagerInterface public companiesManager;
    bytes32[] public randomNumbers;

    uint32 public endDate;

    function TicketSale(uint _endDate, address _proxy, address _beneficiary, uint _maxTickets) public {
        require(_endDate > block.timestamp);
        require(_beneficiary != 0);
        uint refundDate = block.timestamp + REFUND_AFTER;
         
        require(_endDate < refundDate);

        ticketHolder = new TicketHolder(_maxTickets);
        ticketHolder.giveAccess(msg.sender);

        fund = new Fund(refundDate, _beneficiary);
        fund.giveAccess(msg.sender);

        endDate = uint32(_endDate);
        proxy = RandomOraclizeProxyI(_proxy);
    }

    function buyTickets(uint _dreamAmount) public payable {
        buyTicketsInternal(msg.sender, msg.value, _dreamAmount);
    }

    function buyTicketsFor(address _addr, uint _dreamAmount) public payable {
        buyTicketsInternal(_addr, msg.value, _dreamAmount);
    }

    function buyTicketsInternal(address _addr, uint _valueWei, uint _dreamAmount) internal notEnded {
        require(_valueWei >= TICKET_PRICE);
        require(checkDream(_dreamAmount));

        uint change = _valueWei % TICKET_PRICE;
        uint weiAmount = _valueWei - change;
        uint ticketCount = weiAmount.div(TICKET_PRICE);

        if (address(companiesManager) != 0) {
            uint totalTickets = ticketHolder.totalTickets();
            companiesManager.processing(_addr, weiAmount, ticketCount, totalTickets);
        }

         
        ticketHolder.issueTickets(_addr, ticketCount, _dreamAmount);

         
        fund.deposit.value(weiAmount)(_addr);

         
        if (change != 0) {
            msg.sender.transfer(change);
        }
    }

     

    function refund() public {
        fund.refund(msg.sender);
    }

     
    function payout(uint _playerIndex, uint _amountWei) public restricted ended {
        address playerAddress;
        uint ticketAmount;
        uint dreamAmount;
        (playerAddress, ticketAmount, dreamAmount) = ticketHolder.getTickets(_playerIndex);
        require(playerAddress != 0);

         
        fund.pay(playerAddress, _amountWei);
    }

     
    function isPayed(uint _playerIndex) public constant returns (bool) {
        address playerAddress;
        uint ticketAmount;
        uint dreamAmount;
        (playerAddress, ticketAmount, dreamAmount) = ticketHolder.getTickets(_playerIndex);
        require(playerAddress != 0);
        return fund.isPayed(playerAddress);
    }

     
    function finish() public restricted {
         
        if (endDate > uint32(block.timestamp)) {
            endDate = uint32(block.timestamp);
        }
    }

     
    function requestRandom() public payable restricted {
        uint price = proxy.getRandomPrice(RANDOM_GAS);
        require(msg.value >= price);
        uint change = msg.value - price;
        proxy.requestRandom.value(price)(this.random_callback, RANDOM_GAS);
        if (change > 0) {
            msg.sender.transfer(change);
        }
    }

    function random_callback(bytes32 _randomNumbers) external {
        require(msg.sender == address(proxy));
        randomNumbers.push(_randomNumbers);
    }

     
    function setCompanyManager(address _addr) public restricted {
        companiesManager = CompaniesManagerInterface(_addr);
    }

     
    function isEnded() public constant returns (bool) {
        return block.timestamp > endDate;
    }

    function checkDream(uint _dreamAmount) internal constant returns (bool) {
        return
            _dreamAmount == 0 ||
            _dreamAmount == 3 ether ||
            _dreamAmount == 5 ether ||
            _dreamAmount == 7 ether ||
            _dreamAmount == 10 ether ||
            _dreamAmount == 15 ether ||
            _dreamAmount == 20 ether ||
            _dreamAmount == 30 ether ||
            _dreamAmount == 40 ether ||
            _dreamAmount == 50 ether ||
            _dreamAmount == 75 ether ||
            _dreamAmount == 100 ether ||
            _dreamAmount == 150 ether ||
            _dreamAmount == 200 ether ||
            _dreamAmount == 300 ether ||
            _dreamAmount == 400 ether ||
            _dreamAmount == 500 ether ||
            _dreamAmount == 750 ether ||
            _dreamAmount == 1000 ether ||
            _dreamAmount == 1500 ether ||
            _dreamAmount == 2000 ether ||
            _dreamAmount == 2500 ether;
    }

    modifier notEnded() {
        require(!isEnded());
        _;
    }

    modifier ended() {
        require(isEnded());
        _;
    }

    function randomCount() public constant returns (uint) {
        return randomNumbers.length;
    }

    function getRandomPrice() public constant returns (uint) {
        return proxy.getRandomPrice(RANDOM_GAS);
    }

}