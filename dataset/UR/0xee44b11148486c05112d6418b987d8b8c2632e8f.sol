 

pragma solidity ^0.4.19;

contract Spineth
{
     
    enum State
    {
        WaitingForPlayers,  
        WaitingForReveal,  
        Complete  
    }

     
    enum Event
    {
        Create,
        Cancel,
        Join,
        Reveal,
        Expire,
        Complete,
        Withdraw,
        StartReveal
    }
    
     
    struct GameInstance
    {
         
         
        address player1;
        address player2;
    
         
        uint betAmountInWei;
    
         
         
        uint wheelBetPlayer1;
        uint wheelBetPlayer2;
    
         
        uint wheelResult;
    
         
         
        uint expireTime;

         
        State state;

         
        bool withdrawnPlayer1;
        bool withdrawnPlayer2;
    }

     
    uint public constant WHEEL_SIZE = 19;
    
     
     
     
     
    uint public constant WIN_PERCENT_PER_DISTANCE = 10;

     
    uint public constant FEE_PERCENT = 2;

     
    uint public minBetWei = 1 finney;
    
     
    uint public maxBetWei = 10 ether;
    
     
     
    uint public maxRevealSeconds = 3600 * 24;

     
    address public authority;

     
     
    mapping(address => uint) private counterContext;

     
    mapping(uint => GameInstance) public gameContext;

     
    uint[] public openGames;

     
    mapping(address => uint[]) public playerActiveGames;
    mapping(address => uint[]) public playerCompleteGames;    

     
    event GameEvent(uint indexed gameId, address indexed player, Event indexed eventType);

     
    function Spineth() public
    {
         
         
         
        require((WHEEL_SIZE / 2) * WIN_PERCENT_PER_DISTANCE < 100);

        authority = msg.sender;
    }
    
     
     
    function changeAuthority(address newAuthority) public
    {
        require(msg.sender == authority);

        authority = newAuthority;
    }

     
     
    function changeBetLimits(uint minBet, uint maxBet) public
    {
        require(msg.sender == authority);
        require(maxBet >= minBet);

        minBetWei = minBet;
        maxBetWei = maxBet;
    }
    
     
    function arrayAdd(uint[] storage array, uint element) private
    {
        array.push(element);
    }

     
    function arrayRemove(uint[] storage array, uint element) private
    {
        for(uint i = 0; i < array.length; ++i)
        {
            if(array[i] == element)
            {
                array[i] = array[array.length - 1];
                delete array[array.length - 1];
                --array.length;
                break;
            }
        }
    }

     
    function getNextGameId(address player) public view
        returns (uint)
    {
        uint counter = counterContext[player];

         
         
         
         
        uint result = (uint(player) << 96) + counter;

         
        require((result >> 96) == uint(player));

        return result;
    }

     
     
     
    function createWheelBetHash(uint gameId, uint wheelBet, uint playerSecret) public pure
        returns (uint)
    {
        require(wheelBet < WHEEL_SIZE);
        return uint(keccak256(gameId, wheelBet, playerSecret));
    }
    
     
     
     
     
    function createGame(uint gameId, uint wheelPositionHash) public payable
    {
         
        require(getNextGameId(msg.sender) == gameId);

         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei == 0); 
        
         
        require(msg.value > 0);
        
         
         
        require(msg.value >= minBetWei && msg.value <= maxBetWei);

         
        counterContext[msg.sender] = counterContext[msg.sender] + 1;

         
         
        game.state = State.WaitingForPlayers;
        game.betAmountInWei = msg.value;
        game.player1 = msg.sender;
        game.wheelBetPlayer1 = wheelPositionHash;
        
         
        arrayAdd(openGames, gameId);
        arrayAdd(playerActiveGames[msg.sender], gameId);

         
        GameEvent(gameId, msg.sender, Event.Create);
    }
    
     
     
     
     
    function cancelGame(uint gameId) public
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 

         
        require(game.state == State.WaitingForPlayers);
        
         
        require(game.player1 == msg.sender);

         
         
        game.state = State.Complete;
        game.withdrawnPlayer1 = true;

         
        arrayRemove(openGames, gameId);
        arrayRemove(playerActiveGames[msg.sender], gameId);

         
        GameEvent(gameId, msg.sender, Event.Cancel);

         
        msg.sender.transfer(game.betAmountInWei);
    }

     
     
     
    function joinGame(uint gameId, uint wheelBet) public payable
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 
        
         
        require(game.state == State.WaitingForPlayers);
        
         
        require(game.player1 != msg.sender);
        
         
        require(game.player2 == 0);

         
        require(msg.value == game.betAmountInWei);

         
        require(wheelBet < WHEEL_SIZE);

         
         
        game.state = State.WaitingForReveal;
        game.player2 = msg.sender;
        game.wheelBetPlayer2 = wheelBet;
        game.expireTime = now + maxRevealSeconds;  

         
        arrayRemove(openGames, gameId);
        arrayAdd(playerActiveGames[msg.sender], gameId);

         
        GameEvent(gameId, msg.sender, Event.Join);

         
        GameEvent(gameId, game.player1, Event.StartReveal);
    }
    
     
     
     
     
    function expireGame(uint gameId) public
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 

         
        require(game.state == State.WaitingForReveal);
        
         
        require(now > game.expireTime);
        
         
        require(msg.sender == game.player2);

         
         
        game.wheelResult = game.wheelBetPlayer2;
        game.wheelBetPlayer1 = (game.wheelBetPlayer2 + (WHEEL_SIZE / 2)) % WHEEL_SIZE;
        
         
        game.state = State.Complete;

         
        GameEvent(gameId, game.player1, Event.Expire);
        GameEvent(gameId, game.player2, Event.Expire);
    }
    
     
     
    function revealBet(uint gameId, uint playerSecret) public
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 

         
        require(game.state == State.WaitingForReveal);

         
        require(game.player1 == msg.sender);

        uint i;  

         
         
         
        for(i = 0; i < WHEEL_SIZE; ++i)
        {
             
            if(createWheelBetHash(gameId, i, playerSecret) == game.wheelBetPlayer1)
            {
                 
                game.wheelBetPlayer1 = i;
                break;
            }
        }
        
         
         
        require(i < WHEEL_SIZE);
        
         
        GameEvent(gameId, msg.sender, Event.Reveal);

         
         
         
         
        uint256 hashResult = uint256(keccak256(gameId, now, game.wheelBetPlayer1, game.wheelBetPlayer2));
        uint32 randomSeed = uint32(hashResult >> 0)
                          ^ uint32(hashResult >> 32)
                          ^ uint32(hashResult >> 64)
                          ^ uint32(hashResult >> 96)
                          ^ uint32(hashResult >> 128)
                          ^ uint32(hashResult >> 160)
                          ^ uint32(hashResult >> 192)
                          ^ uint32(hashResult >> 224);

        uint32 randomNumber = randomSeed;
        uint32 randMax = 0xFFFFFFFF;  

         
        do
        {
            randomNumber ^= (randomNumber >> 11);
            randomNumber ^= (randomNumber << 7) & 0x9D2C5680;
            randomNumber ^= (randomNumber << 15) & 0xEFC60000;
            randomNumber ^= (randomNumber >> 18);
        }
         
         
         
         
        while(randomNumber >= (randMax - (randMax % WHEEL_SIZE)));

         
        game.wheelResult = randomNumber % WHEEL_SIZE;
        game.state = State.Complete;
        
         
        GameEvent(gameId, game.player1, Event.Complete);
        GameEvent(gameId, game.player2, Event.Complete);
    }

     
     
    function getWheelDistance(uint value1, uint value2) private pure
        returns (uint)
    {
         
        require(value1 < WHEEL_SIZE && value2 < WHEEL_SIZE);

         
        uint dist1 = (WHEEL_SIZE + value1 - value2) % WHEEL_SIZE;
        
         
        uint dist2 = WHEEL_SIZE - dist1;

         
        return (dist1 < dist2) ? dist1 : dist2;
    }

     
     
     
     
     
     
     
     
    function calculateEarnings(uint gameId) public view
        returns (uint feeWei, uint weiPlayer1, uint weiPlayer2)
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 

         
        require(game.state == State.Complete);
        
        uint distancePlayer1 = getWheelDistance(game.wheelBetPlayer1, game.wheelResult);
        uint distancePlayer2 = getWheelDistance(game.wheelBetPlayer2, game.wheelResult);

         
        feeWei = 0;
        weiPlayer1 = game.betAmountInWei;
        weiPlayer2 = game.betAmountInWei;

        uint winDist = 0;
        uint winWei = 0;
        
         
        if(distancePlayer1 < distancePlayer2)
        {
            winDist = distancePlayer2 - distancePlayer1;
            winWei = game.betAmountInWei * (winDist * WIN_PERCENT_PER_DISTANCE) / 100;

            feeWei = winWei * FEE_PERCENT / 100;
            weiPlayer1 += winWei - feeWei;
            weiPlayer2 -= winWei;
        }
         
        else if(distancePlayer2 < distancePlayer1)
        {
            winDist = distancePlayer1 - distancePlayer2;
            winWei = game.betAmountInWei * (winDist * WIN_PERCENT_PER_DISTANCE) / 100;

            feeWei = winWei * FEE_PERCENT / 100;
            weiPlayer2 += winWei - feeWei;
            weiPlayer1 -= winWei;
        }
         
    }
    
     
     
    function withdrawEarnings(uint gameId) public
    {
         
        GameInstance storage game = gameContext[gameId];
        require(game.betAmountInWei > 0); 

        require(game.state == State.Complete);
        
        var (feeWei, weiPlayer1, weiPlayer2) = calculateEarnings(gameId);

        bool payFee = false;
        uint withdrawAmount = 0;

        if(game.player1 == msg.sender)
        {
             
            require(game.withdrawnPlayer1 == false);
            
            game.withdrawnPlayer1 = true;  
            
             
            if(weiPlayer1 > weiPlayer2)
            {
                payFee = true;
            }
            
            withdrawAmount = weiPlayer1;
        }
        else if(game.player2 == msg.sender)
        {
             
            require(game.withdrawnPlayer2 == false);
            
            game.withdrawnPlayer2 = true;

             
            if(weiPlayer2 > weiPlayer1)
            {
                payFee = true;
            }
            
            withdrawAmount = weiPlayer2;
        }
        else
        {
             
            revert();
        }

         
        arrayRemove(playerActiveGames[msg.sender], gameId);
        arrayAdd(playerCompleteGames[msg.sender], gameId);

         
        GameEvent(gameId, msg.sender, Event.Withdraw);

         
        if(payFee == true)
        {
            authority.transfer(feeWei);
        }
    
         
        msg.sender.transfer(withdrawAmount);
    }
}