 

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

     
     
     
    mapping (uint => address) participants;
    uint256[] prizes = [4 ether, 
                        2 ether,
                        1 ether, 
                        500 finney, 
                        500 finney, 
                        500 finney, 
                        500 finney, 
                        500 finney];
    uint8 counter = 0;

    uint8   constant SIZE = 100;  
    uint32  constant JACKPOT_SIZE = 1000000;  
    uint256 constant PRICE = 100 finney;
    
    uint256 jackpot = 0;
    uint256 gameNumber = 0;
    address wallet;

    event PrizeAwarded(uint256 game, address winner, uint256 amount);
    event JackpotAwarded(uint256 game, address winner, uint256 amount);

    function Slot(address _wallet) {
        token = new SlotTicket();
        wallet = _wallet;
    }

    function() payable {
         
        buyTicketsFor(msg.sender);
    }

    function buyTicketsFor(address beneficiary) whenNotPaused() payable {
        require(beneficiary != 0x0);
        require(msg.value >= PRICE);
        require(msg.value/PRICE <= 255);  
         
        
         
         
        uint8 numberOfTickets = uint8(msg.value/PRICE); 
        token.mint(beneficiary, numberOfTickets);
        addParticipant(beneficiary, numberOfTickets);

         
         
        msg.sender.transfer(msg.value%PRICE);

    }

    function addParticipant(address _participant, uint8 _numberOfTickets) private {
         
         
         

        for (uint8 i = 0; i < _numberOfTickets; i++) {
            participants[counter] = _participant;

             
            if (counter % (SIZE-1) == 0) { 
                 
                awardPrizes(uint256(_participant)); 
            } 
            
            counter++;

             
        }
        
    }
    
    function rand(uint32 _size, uint256 _seed) constant private returns (uint32 randomNumber) {
       
       
       

        return uint32(sha3(block.blockhash(block.number-1), _seed))%_size;
    }

    function awardPrizes(uint256 _seed) private {
        uint32 winningNumber = rand(SIZE-1, _seed);  
        bool jackpotWon = winningNumber == rand(JACKPOT_SIZE-1, _seed);  

         
        uint256 start = gameNumber.mul(SIZE);
        uint256 end = start + SIZE;

        uint256 winnerIndex = start.add(winningNumber);

        for (uint8 i = 0; i < prizes.length; i++) {
            
            if (jackpotWon && i==0) { distributeJackpot(winnerIndex); }

            if (winnerIndex+i > end) {
               
                winnerIndex -= SIZE;
            }

            participants[winnerIndex+i].transfer(prizes[i]);  
            
            PrizeAwarded(gameNumber,  participants[winnerIndex+i], prizes[i]);
        }
        
         
        jackpot = jackpot.add(245 finney);   
        wallet.transfer(245 finney);         
        msg.sender.transfer(10 finney);      

        gameNumber++;
    }

    function distributeJackpot(uint256 _winnerIndex) {
        participants[_winnerIndex].transfer(jackpot);
        JackpotAwarded(gameNumber,  participants[_winnerIndex], jackpot);
        jackpot = 0;  
    }

    function destroy() onlyOwner {
         
        token.destroy();
        selfdestruct(owner);
  }

    function changeWallet(address _newWallet) onlyOwner {
        require(_newWallet != 0x0);
        wallet = _newWallet;
  }

}