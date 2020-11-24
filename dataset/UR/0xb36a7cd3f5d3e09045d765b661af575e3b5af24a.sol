 

pragma solidity ^0.4.24;

 

contract Vitaluck {
    
     
     
     

    address ownerAddress = 0x3dcd6f0d7860f93b8bb7d6dcb85346c814243d63;
    address cfoAddress = 0x5b665218efCE2a15BD64Bd1dE50a27286f456863;
    
    modifier onlyCeo() {
        require (msg.sender == ownerAddress);
        _;
    }
    
     
     
     
    
    event NewPress(address player, uint countPress, uint256 pricePaid, uint32 _timerEnd);

     
     
     

    uint countPresses;
    uint256 countInvestorDividends;

    uint amountPlayed;

    uint32 timerEnd;                                         
    uint32 timerInterval = 21600;                            

    address winningAddress;
    uint256 buttonBasePrice = 20000000000000000;               
    uint256 buttonPriceStep = 2000000000000000;
     
     
     
    struct Player {
        address playerAddress;                               
        uint countVTL;                                       
    }
    Player[] players;
    mapping (address => uint) public playersToId;       

     
     
     

     
    function() public payable {
         
        uint _countPress = msg.value / getButtonPrice();
        
         
        Press(_countPress, 0);
    }
        
     
    function FundContract() public payable {
        
    }
    
     
    function Press(uint _countPresses, uint _affId) public payable {
         
        require(_countPresses >= 1);
        
         
        require(msg.value >= buttonBasePrice);
        
         
        require(timerEnd > now);

         
        uint256 _buttonPrice = getButtonPrice();
        require(msg.value >= safeMultiply(_buttonPrice, _countPresses));

         
        timerEnd = uint32(now + timerInterval);
        winningAddress = msg.sender;

         
        uint256 TwoPercentCom = (msg.value / 100) * 2;
        uint256 TenPercentCom = msg.value / 10;
        uint256 FifteenPercentCom = (msg.value / 100) * 15;
        

         
        if(_affId > 0 && _affId < players.length) {
             
            players[_affId].playerAddress.transfer(TenPercentCom);
        }
         
        uint[] memory mainInvestors = GetMainInvestor();
        uint mainInvestor = mainInvestors[0];
        players[mainInvestor].playerAddress.transfer(FifteenPercentCom);
        countInvestorDividends = countInvestorDividends + FifteenPercentCom;
        
         
         
        for(uint i = 1; i < mainInvestors.length; i++) {
            if(mainInvestors[i] != 0) {
                uint _investorId = mainInvestors[i];
                players[_investorId].playerAddress.transfer(TwoPercentCom);
                countInvestorDividends = countInvestorDividends + TwoPercentCom;
            }
        }

         
        cfoAddress.transfer(FifteenPercentCom);

         
        if(playersToId[msg.sender] > 0) {
             
            players[playersToId[msg.sender]].countVTL = players[playersToId[msg.sender]].countVTL + _countPresses;
        } else {
             
            uint playerId = players.push(Player(msg.sender, _countPresses)) - 1;
            playersToId[msg.sender] = playerId;
        }

         
        emit NewPress(msg.sender, _countPresses, msg.value, timerEnd);
        
         
        countPresses = countPresses + _countPresses;
        amountPlayed = amountPlayed + msg.value;
    }

     
    function withdrawReward() public {
         
        require(timerEnd < now);
        require(winningAddress == msg.sender);
        
         
        winningAddress.transfer(address(this).balance);
    }
    
     
    function GetPlayer(uint _id) public view returns(address, uint) {
        return(players[_id].playerAddress, players[_id].countVTL);
    }
    
     
    function GetPlayerDetails(address _address) public view returns(uint, uint) {
        uint _playerId = playersToId[_address];
        uint _countVTL = 0;
        if(_playerId > 0) {
            _countVTL = players[_playerId].countVTL;
        }
        return(_playerId, _countVTL);
    }

     
    function GetMainInvestor() public view returns(uint[]) {
        uint depth = 10;
        bool[] memory _checkPlayerInRanking = new bool[] (players.length);
        
        uint[] memory curWinningVTLAmount = new uint[] (depth);
        uint[] memory curWinningPlayers = new uint[] (depth);
        
         
        for(uint j = 0; j < depth; j++) {
             
            curWinningVTLAmount[j] = 0;
            
             
            for (uint8 i = 0; i < players.length; i++) {
                 
                if(players[i].countVTL > curWinningVTLAmount[j] && _checkPlayerInRanking[i] != true) {
                    curWinningPlayers[j] = i;
                    curWinningVTLAmount[j] = players[i].countVTL;
                }
            }
             
            _checkPlayerInRanking[curWinningPlayers[j]] = true;
        }

         
        return(curWinningPlayers);
    }
    
     
    function GetCurrentNumbers() public view returns(uint, uint256, address, uint, uint256, uint256, uint256) {
        return(timerEnd, address(this).balance, winningAddress, countPresses, amountPlayed, getButtonPrice(), countInvestorDividends);
    }
    
     
    constructor() public onlyCeo {
        timerEnd = uint32(now + timerInterval);
        winningAddress = ownerAddress;
        
         
        uint playerId = players.push(Player(0x0, 0)) - 1;
        playersToId[msg.sender] = playerId;
    }
    
     
    function getButtonPrice() public view returns(uint256) {
         
        uint _multiplier = 0;
        if(countPresses > 100) {
            _multiplier = buttonPriceStep * (countPresses / 100);
        }
        
         
        uint256 _buttonPrice = buttonBasePrice + _multiplier;
        return(_buttonPrice);
        
    }
    
     
     
     

      
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }
    
}