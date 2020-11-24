 

pragma solidity ^0.4.16;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
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

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
 
contract SlotTicket is StandardToken, Ownable {

  string public name = "Slot Ticket";
  uint8 public decimals = 0;
  string public symbol = "SLOT";
  string public version = "0.1";

  event Mint(address indexed to, uint256 amount);

  function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);  
    return true;
  }

function destroy() onlyOwner {
     
    selfdestruct(owner);
  }

}

contract Slot is Ownable, Pausable {
    using SafeMath for uint256;

     
    SlotTicket public token;

     
     
     
    mapping (uint => mapping (uint => address)) participants;  
    uint256[8] prizes = [4 ether, 
                        2 ether,
                        1 ether, 
                        500 finney, 
                        500 finney, 
                        500 finney, 
                        500 finney, 
                        500 finney];
    
    uint8   constant SIZE = 100;  
    uint32  constant JACKPOT_SIZE = 1000000;  
    uint32  constant INACTIVITY = 160000;  
    uint256 constant public PRICE = 100 finney;
    
    uint256 public jackpotAmount;
    uint256 public gameNumber;
    uint256 public gameStarted;
    bool    public undestroyable;
    address wallet;
    uint256 counter;

    event ParticipantAdded(address indexed _participant, uint256 indexed _game, uint256 indexed _number);
    event PrizeAwarded(uint256 indexed _game , address indexed _winner, uint256 indexed _amount);
    event JackpotAwarded(uint256 indexed _game, address indexed _winner, uint256 indexed _amount);
    event GameRefunded(uint256 _game);

    function Slot(address _wallet) payable {
        token = new SlotTicket();
        wallet = _wallet;

        jackpotAmount = msg.value;
        gameNumber = 0;
        counter = 0;
        gameStarted = block.number;
        undestroyable = false;
    }

    function() payable {
         
        buyTicketsFor(msg.sender);
    }

    function buyTicketsFor(address beneficiary) whenNotPaused() payable {
        require(beneficiary != 0x0);
        require(msg.value >= PRICE);

         
         
        uint256 change = msg.value%PRICE;
        uint256 numberOfTickets = msg.value.sub(change).div(PRICE);
        token.mint(beneficiary, numberOfTickets);
        addParticipant(beneficiary, numberOfTickets);

         
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
    
    function rand(uint32 _size) constant private returns (uint256 randomNumber) {
       
       
       
       

        return uint256(keccak256(block.blockhash(block.number-1), block.blockhash(block.number-100)))%_size;
    }

    function awardPrizes() private {
        uint256 winnerIndex = rand(SIZE);
         
        bool jackpotWon = winnerIndex == rand(JACKPOT_SIZE); 

         
        for (uint8 i = 0; i < prizes.length; i++) {
            if (jackpotWon && i==0) {
                distributeJackpot(winnerIndex);
            }
            
            participants[gameNumber][winnerIndex%SIZE].transfer(prizes[i]);  
            PrizeAwarded(gameNumber, participants[gameNumber][winnerIndex%SIZE], prizes[i]);

             
            winnerIndex++;
        }
    }

    function distributeJackpot(uint256 _winnerIndex) private {
        participants[gameNumber][_winnerIndex].transfer(jackpotAmount);
        JackpotAwarded(gameNumber,  participants[gameNumber][_winnerIndex], jackpotAmount);
        jackpotAmount = 0;  
    }

    function distributeRemaining() private {
        jackpotAmount = jackpotAmount.add(250 finney);    
        wallet.transfer(249 finney);                      
        msg.sender.transfer(1 finney);                    
    }

    function increaseGame() private {
        gameNumber++;
        gameStarted = block.number;
    }

     

    function refundGameAfterLongInactivity() {
        require(block.number.sub(gameStarted) >= INACTIVITY);
        require(counter%SIZE != 0);  
         

        for (uint8 i = 0; i < counter%SIZE; i++) {  
            participants[gameNumber][i].transfer(PRICE);
        }

         
        counter -= counter%SIZE;
        GameRefunded(gameNumber);
        increaseGame();
    }

    function destroy() onlyOwner {
        require(!undestroyable);
         
         
        token.destroy();
        selfdestruct(owner);
    }

    function changeWallet(address _newWallet) onlyOwner {
        require(_newWallet != 0x0);
        wallet = _newWallet;
    }

    function makeUndestroyable() onlyOwner {
        undestroyable = true;
         
    }

}