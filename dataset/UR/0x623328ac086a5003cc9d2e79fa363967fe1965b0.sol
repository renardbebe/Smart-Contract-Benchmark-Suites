 

pragma solidity ^0.5.1;

contract Lotto {

    struct Round {
        uint entries;                
        address[] activePlayers;     
        uint256 ticketCost;          
        bool drawn;                  
        uint256 fee;                 
        bytes32 hashOfSecret;        
        bytes32 secret;              
        uint256 closesOn;            
        uint256 winner;              
        uint256 prizePool;
    }

    address payable drawer;
    uint256 public roundCount;
    mapping(address => uint256) public owed;   
    Round[] public rounds;   

    constructor () public {
        drawer = msg.sender;
        roundCount = 0;
    }

    modifier isDrawer {
        require(msg.sender==drawer);
        _;
    }
    
    function Drawer() public view returns (address _drawer){
        _drawer = drawer;
    }
    
    function createRound(uint256 _ticketCost, uint256 _fee, bytes32 _hashOfSecret, uint256 _closesOn) public isDrawer {
        require(_closesOn > block.number);
        Round memory round;
        round.ticketCost = _ticketCost;
        round.fee = _fee;
        round.hashOfSecret = _hashOfSecret;
        round.closesOn = _closesOn;
        rounds.push(round);
        roundCount++;
    }
    
    function getBlockNumber() public view returns (uint256 bn){ bn = block.number; }
    
    function buyTicket(uint256 _roundNumber) public payable {
        require(block.number < rounds[_roundNumber].closesOn);  
        require(msg.value == rounds[_roundNumber].ticketCost);
        require(!rounds[_roundNumber].drawn);
        rounds[_roundNumber].entries++;
        rounds[_roundNumber].activePlayers.push(msg.sender);
        rounds[_roundNumber].prizePool += (rounds[_roundNumber].ticketCost-rounds[_roundNumber].fee);
    }    
    
    function checkHash(bytes32 testSecret) public pure returns(bytes32 hout) { hout = sha256(abi.encodePacked(testSecret)); }
    function checkWinner(bytes32 testSecret, uint256 testEntries) public pure returns (uint256 testWinner) {
        testWinner = uint256(testSecret) % testEntries;
    }
    
    function checkRoundWinner(uint256 round) public view returns(address win){
        require(rounds[round].drawn);
        win = rounds[round].activePlayers[rounds[round].winner];
    }
    
    function drawWinner(uint256 _roundNumber, bytes32 secret) public isDrawer {
        require(rounds[_roundNumber].entries>0);
        require(block.number >= rounds[_roundNumber].closesOn);
        require(!rounds[_roundNumber].drawn);
        require(sha256(abi.encodePacked(secret))==(rounds[_roundNumber].hashOfSecret));
        uint256 winner = checkWinner(secret,rounds[_roundNumber].entries);
        rounds[_roundNumber].drawn = true;
        rounds[_roundNumber].winner = winner;
        rounds[_roundNumber].secret = secret;
        owed[rounds[_roundNumber].activePlayers[winner]] += rounds[_roundNumber].prizePool;
        drawer.transfer(rounds[_roundNumber].ticketCost*rounds[_roundNumber].entries-rounds[_roundNumber].prizePool);
    }
    
    function collectPrize() public {
        require(owed[msg.sender]>0);
        msg.sender.transfer(owed[msg.sender]);
        owed[msg.sender] = 0;
    }
    
    function sendPrize(address payable _who) public {
        require(owed[_who]>0);
        _who.transfer(owed[_who]);
        owed[_who] = 0;
    }
}