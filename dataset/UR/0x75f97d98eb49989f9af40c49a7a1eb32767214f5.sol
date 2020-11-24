 

pragma solidity ^0.4.0;

 
 
contract PonzICO {
    address public owner;
    uint public total;
    mapping (address => uint) public invested;
    mapping (address => uint) public balances;

     
    function PonzICO() { }
    function withdraw() { }
    function reinvest() { }
    function invest() payable { }
    
}

 
 
contract VoteOnMyTeslaColor {
    address public owner;
    enum Color { SolidBlack, MidnightSilverMetallic, DeepBlueMetallic, SilverMetallic, RedMultiCoat }
    mapping (uint8 => uint32) public votes;
    mapping (address => bool) public voted;

     
    event LogVotes(Color color, uint num);
     
    event LogWinner(Color color);

     
    PonzICO ponzico = PonzICO(0x1ce7986760ADe2BF0F322f5EF39Ce0DE3bd0C82B);

     
    modifier ownerOnly() {require(msg.sender == owner); _; }
     
    modifier isValidColor(uint8 color) {require(color < uint8(5)); _; }
     
     
    modifier superAccreditedInvestor() { require(ponzico.invested(msg.sender) >= 0.1 ether && !voted[msg.sender]); _;}

     
     
     
    function VoteOnMyTeslaColor() {
        owner = msg.sender;
         
        votes[uint8(2)] = 10;
    }

     
    function vote(uint8 color)
    superAccreditedInvestor()
    isValidColor(color)
    {
         
        uint32 num = uint32(ponzico.invested(msg.sender) / (0.1 ether));
        votes[color] += num;
        voted[msg.sender] = true;
        LogVotes(Color(color), num);
    }
    
     
     
    function itsLikeChicago() payable {
        require(voted[msg.sender] && msg.value >= 1 ether);
        voted[msg.sender] = false;
    }

    function winnovate()
    ownerOnly()
    {
        Color winner = Color.SolidBlack;
        for (uint8 choice = 1; choice < 5; choice++) {
            if (votes[choice] > votes[choice-1]) {
                winner = Color(choice);
            }
        }
        LogWinner(winner);
         
        selfdestruct(owner);
    }
}