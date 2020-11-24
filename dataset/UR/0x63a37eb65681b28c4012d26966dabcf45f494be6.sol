 

 

pragma solidity ^0.5.8;

contract ERC20Token {
  function totalSupply() public view returns(uint);
  function balanceOf(address tokenOwner) public view returns(uint balance);
  function allowance(address tokenOwner, address spender) public view returns(uint remaining);
  function transfer(address to, uint tokens) public returns(bool success);
  function approve(address spender, uint tokens) public returns(bool success);
  function transferFrom(address from, address to, uint tokens) public returns(bool success);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
 
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

contract ShuffleRaffle is Ownable {
    using SafeMath for uint256;
    
    struct Order {
        uint48 position;
        uint48 size;
        address owner;
    }
    
    mapping(uint256 => Order[]) TicketBook;
    ERC20Token public shuf = ERC20Token(0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E);
    uint256 public RaffleNo = 1;
    uint256 public TicketPrice = 5*10**18;
    uint256 public PickerReward = 5*10**18;
    uint256 public minTickets = 9;
    uint256 public nextTicketPrice = 5*10**18;
    uint256 public nextPickerReward = 5*10**18;
    uint256 public nextminTickets = 9;
    uint256 public NextRaffle = 1574197200;
    uint256 public random_seed = 0;
    bool    public raffle_closed = false;

    event Ticket(uint256 raffle, address indexed addr, uint256 amount);
    event Winner(uint256 raffle, address indexed addr, uint256 amount, uint256 win_ticket);
    event RaffleClosed(uint256 raffle, uint256 block_number);
    event TicketPriceChanged(uint256 previousticketprice, uint256 newticketprice);
    event PickerRewardChanged(uint256 previouspickerReward, uint256 newpickerreward);
    event minTicketsChanged(uint256 previousminTickets,uint256 newmintickets);

    function TicketsOfAddress(address addr) public view returns (uint256 total_tickets) {
        uint256 _tt=0;
        for(uint256 i = 0; i<TicketBook[RaffleNo].length; i++){
            if (TicketBook[RaffleNo][i].owner == addr)
                _tt=_tt.add(TicketBook[RaffleNo][i].size);
        }
        return _tt;
    }

    function Stats() public view returns (uint256 raffle_number, uint48 total_tickets, uint256 balance, uint256 next_raffle, uint256 ticket_price, bool must_pick_winner, uint256 picker_reward, uint256 min_tickets,uint256 next_ticket_price,uint256 next_picker_reward,uint256 next_min_tickets, bool is_raffle_closed){
        bool mustPickWinner;
        uint48 TotalTickets= _find_curr_position();
        if (now>NextRaffle && TotalTickets>minTickets)
            mustPickWinner = true;
        else
            mustPickWinner = false;
        return (RaffleNo, TotalTickets, shuf.balanceOf(address(this)), NextRaffle, TicketPrice, mustPickWinner, PickerReward, minTickets, nextTicketPrice, nextPickerReward, nextminTickets, raffle_closed);
    }
    
    function BuyTicket(uint48 tickets) external returns(bool success){
        uint256 bill = uint256(tickets).mul(TicketPrice);
        uint48 TotalTickets= _find_curr_position();
        require(tickets>0);
        require(shuf.allowance(msg.sender, address(this))>=bill, "Contract not approved");
        require(shuf.balanceOf(msg.sender)>=bill , "Not enough SHUF balance.");
        if (now>NextRaffle){
             
            require(TotalTickets<=minTickets,"A winner has to be picked first");
            NextRaffle = NextRaffle.add((((now.sub(NextRaffle)).div(5 days + 12 hours)).add(1)).mul(5 days + 12 hours));
        }
        shuf.transferFrom(msg.sender, address(this), bill);

        Order memory t;
        t.size=tickets;
        t.owner=msg.sender;
        t.position=TotalTickets+tickets;
        require(t.position>=TotalTickets);
        TicketBook[RaffleNo].push(t);
        
        emit Ticket(RaffleNo, msg.sender, tickets);
        return true;
    }
    
   
    function pickWinner() external returns(bool success) {
        require(now>NextRaffle, "It's not time to pick a winner yet");
        uint256 Totaltickets =_find_curr_position(); 
        require(Totaltickets>minTickets,  "Not enough tickets to pick a winner");
        
         
        if (raffle_closed == false){
            raffle_closed = true;
            random_seed = block.number;
            emit RaffleClosed(RaffleNo, random_seed);
            shuf.transfer(msg.sender, PickerReward);
            return true;
        }

        uint256 winningticket = _random(Totaltickets);
        address winner = _find_winner(winningticket);
     
         
        shuf.transfer(msg.sender, PickerReward);
    
         
        uint256 reward = shuf.balanceOf(address(this));
        shuf.transfer(winner,reward);
        emit Winner(RaffleNo, winner, reward, winningticket);
        
         
        RaffleNo=RaffleNo.add(1);
        NextRaffle = NextRaffle.add((((now.sub(NextRaffle)).div(5 days + 12 hours)).add(1)).mul(5 days + 12 hours));
        raffle_closed = false;
        
         
        if(nextTicketPrice!=TicketPrice){
            uint256 oldticketPrice=TicketPrice;
            TicketPrice = nextTicketPrice;
            emit TicketPriceChanged(oldticketPrice, TicketPrice);
        }
        if(nextPickerReward!=PickerReward){
            uint256 oldpickerReward=PickerReward;
            PickerReward = nextPickerReward;
            emit PickerRewardChanged(oldpickerReward, PickerReward);
        }
        if(nextminTickets!=minTickets){
            uint256 oldminTickets=minTickets;
            minTickets = nextminTickets;
            emit minTicketsChanged(oldminTickets, minTickets);
        }
        
        return true;
    }
    
    function _find_curr_position() internal view returns(uint48 curr_position){
        uint256 TotalOrders= TicketBook[RaffleNo].length;
        uint48 Totaltickets=(TotalOrders>0)?TicketBook[RaffleNo][TotalOrders.sub(1)].position:0;
        return Totaltickets;
    }
    
     function _find_winner(uint256 winning_ticket)  internal view returns(address winner){
     
        uint256 L=0;
        uint256 R=TicketBook[RaffleNo].length.sub(1);
        uint256 raffleno=RaffleNo;
        
        while(L <= R){
            uint256 m = (L.add(R)).div(2);
            Order memory Am = TicketBook[raffleno][m];
            if(Am.position<winning_ticket)
                L=m.add(1);
            else if(Am.position-Am.size>=winning_ticket)
                R=m.sub(1);
            else
                return Am.owner;
        }
        return address(this);
    }
    
    function setTicketPrice(uint256 newticketprice) external onlyOwner {
        nextTicketPrice= newticketprice;
    }
    
    function setPickerReward(uint256 newpickerreward) external onlyOwner {
        nextPickerReward = newpickerreward;
    }
    
    function setminTickets(uint256 newmintickets) external onlyOwner {
        nextminTickets = newmintickets;
    }
  
    function _random(uint256 Totaltickets) internal view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(blockhash(random_seed), RaffleNo)))%Totaltickets).add(1);
    }
}