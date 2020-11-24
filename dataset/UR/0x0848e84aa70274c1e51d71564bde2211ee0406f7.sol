 

pragma solidity ^0.4.17;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

 
contract StandardMintableToken is ERC20, BasicToken, Ownable {

    mapping (address => mapping (address => uint256)) allowed;
  
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
  
    
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);  
        return true;
    }
    
     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}

 
 
contract SlotTicket is StandardMintableToken {

    string public name = "Slot Ticket";
    uint8 public decimals = 0;
    string public symbol = "TICKET";
    string public version = "0.6";

    function destroy() onlyOwner {
         
        selfdestruct(owner);
    }
}

 
     
contract Slot is Ownable {
    using SafeMath for uint256;

    uint8   constant public SIZE =           100;         
    uint32  constant public JACKPOT_CHANCE = 1000000;     
    uint32  constant public INACTIVITY =     160000;      
    uint256 constant public PRICE =          100 finney;
    uint256 constant public JACK_DIST =      249 finney;
    uint256 constant public DIV_DIST =       249 finney;
    uint256 constant public GAS_REFUND =     2 finney;

     
    mapping (uint => mapping (uint => address)) public participants;  
    SlotTicket public ticket;  
    uint256 public jackpotAmount;
    uint256 public gameNumber;
    uint256 public gameStartedAt;
    address public fund;  
    uint256[8] public prizes = [4 ether, 
                                2 ether,
                                1 ether, 
                                500 finney, 
                                500 finney, 
                                500 finney, 
                                500 finney, 
                                500 finney];
    uint256 counter;

    event ParticipantAdded(address indexed _participant, uint256 indexed _game, uint256 indexed _number);
    event PrizeAwarded(uint256 indexed _game , address indexed _winner, uint256 indexed _amount);
    event JackpotAwarded(uint256 indexed _game, address indexed _winner, uint256 indexed _amount);
    event GameRefunded(uint256 _game);

    function Slot(address _fundAddress) payable {  
         
        ticket = new SlotTicket();
        fund = _fundAddress;

        jackpotAmount = msg.value;
        gameNumber = 0;
        counter = 0;
        gameStartedAt = block.number;
    }

    function() payable {
         
        buyTicketsFor(msg.sender);
    }

    function buyTicketsFor(address _beneficiary) public payable {
        require(_beneficiary != 0x0);
        require(msg.value >= PRICE);

         
         
        uint256 change = msg.value%PRICE;
        uint256 numberOfTickets = msg.value.sub(change).div(PRICE);
        ticket.mint(_beneficiary, numberOfTickets);
        addParticipant(_beneficiary, numberOfTickets);

         
        msg.sender.transfer(change);
    }

     

    function addParticipant(address _participant, uint256 _numberOfTickets) private {
         

        for (uint256 i = 0; i < _numberOfTickets; i++) {
             
            participants[gameNumber][counter%SIZE] = _participant; 
            ParticipantAdded(_participant, gameNumber, counter%SIZE);

             
            if (++counter%SIZE == 0) {
                awardPrizes();
                 
                distributeRemaining();
                increaseGame();
            }
             
        }
    }
    
    function awardPrizes() private {
         
        uint256 winnerIndex = uint256(block.blockhash(block.number-1))%SIZE;

         
        uint256 jackpotNumber = uint256(block.blockhash(block.number-1))%JACKPOT_CHANCE;
        if (winnerIndex == jackpotNumber) {
            distributeJackpot(winnerIndex);
        }

         
        for (uint8 i = 0; i < prizes.length; i++) {
             
            participants[gameNumber][winnerIndex%SIZE].transfer(prizes[i]);  
            PrizeAwarded(gameNumber, participants[gameNumber][winnerIndex%SIZE], prizes[i]);

             
            winnerIndex++;
        }
    }

    function distributeJackpot(uint256 _winnerIndex) private {
        uint256 amount = jackpotAmount;
        jackpotAmount = 0;  

        participants[gameNumber][_winnerIndex].transfer(amount);
        JackpotAwarded(gameNumber,  participants[gameNumber][_winnerIndex], amount);
    }

    function distributeRemaining() private {
         
        jackpotAmount = jackpotAmount.add(JACK_DIST);    
        fund.transfer(DIV_DIST);                         
        msg.sender.transfer(GAS_REFUND);                 
    }

    function increaseGame() private {
        gameNumber++;
        gameStartedAt = block.number;
    }

     

    function spotsLeft() public constant returns (uint8 spots) {
        return SIZE - uint8(counter%SIZE);
    }

    function refundGameAfterLongInactivity() public {
        require(block.number.sub(gameStartedAt) >= INACTIVITY);
        require(counter%SIZE != 0);  
         
        
         
        uint256 _size = counter%SIZE;  
        counter -= _size;

        for (uint8 i = 0; i < _size; i++) {
             
            participants[gameNumber][i].transfer(PRICE);
        }

        GameRefunded(gameNumber);
        increaseGame();
    }

    function destroy() public onlyOwner {
        require(jackpotAmount < 25 ether);

         
         
         

        ticket.destroy();
        selfdestruct(owner);
    }
    
    function changeTicketOwner(address _newOwner) public onlyOwner {
         
         
        ticket.transferOwnership(_newOwner);
    }
    
    function changeFund(address _newFund) public onlyOwner {
        fund = _newFund;
    }
    
    function changeTicket(address _newTicket) public onlyOwner {
        ticket = SlotTicket(_newTicket);  
    }
}