 

pragma solidity ^0.4.18;

 

contract Vitaluck {
    
     
    address ceoAddress = 0x46d9112533ef677059c430E515775e358888e38b;
    address cfoAddress = 0x23a49A9930f5b562c6B1096C3e6b5BEc133E8B2E;
    string MagicKey;
    uint256 minBetValue = 50000000000000000;
    uint256 currentJackpot;
    
    modifier onlyCeo() {
        require (msg.sender == ceoAddress);
        _;
    }
    
     
     
     
    
    event NewPlay(address player, uint number, bool won);

     
     
     

    struct Bet {
        uint number;             
        bool isWinner;           
        address player;          
        uint32 timestamp;        
        uint256 JackpotWon;      
    }
    Bet[] bets;

    mapping (address => uint) public ownerBetsCount;     

     
    uint totalTickets;           
    uint256 amountWon;           
    uint256 amountPlayed;        

     
    uint cooldownTime = 1 days;

     
    address currentWinningAddress;
    uint currentWinningNumber;
    uint currentResetTimer;

     
    uint randomNumber = 178;
    uint randomNumber2;
    
    function() public payable { 
        Play();
    }
    
     
    function Play() public payable {
         
        require(msg.value >= minBetValue);
        
         
        if(totalTickets == 0) {
             
            totalTickets++;
            currentJackpot = currentJackpot + msg.value;
            return;
        }

        uint _thisJackpot = currentJackpot;
         
        uint _finalRandomNumber = 0;
        
         
        currentJackpot = currentJackpot + msg.value;
        
         
         
        _finalRandomNumber = (uint(now) - 1 * randomNumber * randomNumber2 + uint(now))%1000 + 1;
        randomNumber = _finalRandomNumber;

         
        amountPlayed = amountPlayed + msg.value;
        totalTickets++;
        ownerBetsCount[msg.sender]++;

         
        uint256 MsgValue10Percent = msg.value / 10;
        cfoAddress.transfer(MsgValue10Percent);
        
        
         
        currentJackpot = currentJackpot - MsgValue10Percent;

         
        if(_finalRandomNumber > currentWinningNumber) {
            
             
            currentResetTimer = now + cooldownTime;

             
            uint256 JackpotWon = _thisJackpot;
            
            msg.sender.transfer(JackpotWon);
            
             
            currentJackpot = currentJackpot - JackpotWon;
        
             
            amountWon = amountWon + JackpotWon;
            currentWinningNumber = _finalRandomNumber;
            currentWinningAddress = msg.sender;

             
            bets.push(Bet(_finalRandomNumber, true, msg.sender, uint32(now), JackpotWon));
            NewPlay(msg.sender, _finalRandomNumber, true);
            
             
            if(_finalRandomNumber >= 900) {
                 
                currentWinningAddress = address(this);
                currentWinningNumber = 1;
            }
        } else {
             
            currentWinningAddress.transfer(MsgValue10Percent);
        
             
            currentJackpot = currentJackpot - MsgValue10Percent;
        
             
            bets.push(Bet(_finalRandomNumber, false, msg.sender, uint32(now), 0));
            NewPlay(msg.sender, _finalRandomNumber, false);
        }
    }
    
    function TestRandomNumber() public view returns (uint, uint, uint) {
        uint _randomNumber1;
        uint _randomNumber2;
        uint _randomNumber3;
        
        _randomNumber1 = (uint(now) - 1 * randomNumber * randomNumber2 + uint(now))%1000 + 1;
        _randomNumber2 = (uint(now) - 2 * _randomNumber1 * randomNumber2 + uint(now))%1000 + 1;
        _randomNumber3 = (uint(now) - 3 * _randomNumber2 * randomNumber2 + uint(now))%1000 + 1;
        
        return(_randomNumber1,_randomNumber2,_randomNumber3);
    }

     
    function manuallyResetGame() public onlyCeo {
         
        require(currentResetTimer < now);

         
        uint256 JackpotWon = currentJackpot - minBetValue;
        currentWinningAddress.transfer(JackpotWon);
        
         
        currentJackpot = currentJackpot - JackpotWon;

         
        amountWon = amountWon + JackpotWon;

         
        currentWinningAddress = address(this);
        currentWinningNumber = 1;
    }

     
    function GetCurrentNumbers() public view returns(uint, uint256, uint) {
        uint _currentJackpot = currentJackpot;
        return(currentWinningNumber, _currentJackpot, bets.length);
    }
    function GetWinningAddress() public view returns(address) {
        return(currentWinningAddress);
    }
    
    function GetStats() public view returns(uint, uint256, uint256) {
        return(totalTickets, amountPlayed, amountWon);
    }

     
    function GetBet(uint _betId) external view returns (
        uint number,             
        bool isWinner,           
        address player,          
        uint32 timestamp,        
        uint256 JackpotWon      
    ) {
        Bet storage _bet = bets[_betId];

        number = _bet.number;
        isWinner = _bet.isWinner;
        player = _bet.player;
        timestamp = _bet.timestamp;
        JackpotWon = _bet.JackpotWon;
    }

     
    function GetUserBets(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerBetsCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < bets.length; i++) {
          if (bets[i].player == _owner) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
     
    function GetLastBetUser(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerBetsCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < bets.length; i++) {
          if (bets[i].player == _owner) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
     
    function modifyRandomNumber2(uint _newRdNum) public onlyCeo {
        randomNumber2 = _newRdNum;
    }
    function modifyCeo(address _newCeo) public onlyCeo {
        require(msg.sender == ceoAddress);
        ceoAddress = _newCeo;
    }
    function modifyCfo(address _newCfo) public onlyCeo {
        require(msg.sender == ceoAddress);
        cfoAddress = _newCfo;
    }
}