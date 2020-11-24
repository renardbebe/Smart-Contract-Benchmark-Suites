 

pragma solidity 0.4.24;

 
contract StakeToken
{
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract StakeDiceGame
{
     
    function () payable external
    {
        revert();
    }
    
     
     
    
    StakeDice public stakeDice;
    
     
     
     
     
    uint256 public winningChance;
    
     
     
     
     
    function multiplierOnWin() public view returns (uint256)
    {
        uint256 beforeHouseEdge = 10000;
        uint256 afterHouseEdge = beforeHouseEdge - stakeDice.houseEdge();
        return afterHouseEdge * 10000 / winningChance;
    }
    
    function maximumBet() public view returns (uint256)
    {
        uint256 availableTokens = stakeDice.stakeTokenContract().balanceOf(address(stakeDice));
        return availableTokens * 10000 / multiplierOnWin() / 5;
    }
    

    
     
     
    
     
     
    constructor(StakeDice _stakeDice, uint256 _winningChance) public
    {
         
        require(_winningChance > 0);
        require(_winningChance < 10000);
        require(_stakeDice != address(0x0));
        require(msg.sender == address(_stakeDice));
        
        stakeDice = _stakeDice;
        winningChance = _winningChance;
    }
    
     
    function setWinningChance(uint256 _newWinningChance) external
    {
        require(msg.sender == stakeDice.owner());
        require(_newWinningChance > 0);
        require(_newWinningChance < 10000);
        winningChance = _newWinningChance;
    }
    
     
     
    function withdrawStakeTokens(uint256 _amount, address _to) external
    {
        require(msg.sender == stakeDice.owner());
        require(_to != address(0x0));
        stakeDice.stakeTokenContract().transfer(_to, _amount);
    }
}


contract StakeDice
{
     
     
    
    StakeToken public stakeTokenContract;
    mapping(address => bool) public addressIsStakeDiceGameContract;
    StakeDiceGame[] public allGames;
    uint256 public houseEdge;
    uint256 public minimumBet;
    
     
     
    
    address[] public allPlayers;
    mapping(address => uint256) public playersToTotalBets;
    mapping(address => uint256[]) public playersToBetIndices;
    function playerAmountOfBets(address _player) external view returns (uint256)
    {
        return playersToBetIndices[_player].length;
    }
    
    function totalUniquePlayers() external view returns (uint256)
    {
        return allPlayers.length;
    }
    
     
     
    
     
    event BetPlaced(address indexed gambler, uint256 betIndex);
    event BetWon(address indexed gambler, uint256 betIndex);
    event BetLost(address indexed gambler, uint256 betIndex);
    event BetCanceled(address indexed gambler, uint256 betIndex);
    
    enum BetStatus
    {
        NON_EXISTANT,
        IN_PROGRESS,
        WON,
        LOST,
        CANCELED
    }
    
    struct Bet
    {
        address gambler;
        uint256 winningChance;
        uint256 betAmount;
        uint256 potentialRevenue;
        uint256 roll;
        BetStatus status;
    }
    
    Bet[] public bets;
    uint public betsLength = 0;
    mapping(bytes32 => uint256) public oraclizeQueryIdsToBetIndices;
    
    function betPlaced(address gameContract, uint256 _amount) external
    {
         
        require(addressIsStakeDiceGameContract[gameContract] == true);
        
          
        require(_amount >= minimumBet);
        require(_amount <= StakeDiceGame(gameContract).maximumBet());
        
         
        stakeTokenContract.transferFrom(msg.sender, this, _amount);
        
        
         
        uint256 potentialRevenue = StakeDiceGame(gameContract).multiplierOnWin() * _amount / 10000;
        
         
        emit BetPlaced(msg.sender, bets.length);
        playersToBetIndices[msg.sender].push(bets.length);
        bets.push(Bet({gambler: msg.sender, winningChance: StakeDiceGame(gameContract).winningChance(), betAmount: _amount, potentialRevenue: potentialRevenue, roll: 0, status: BetStatus.IN_PROGRESS}));
        betsLength +=1;
         
        if (playersToTotalBets[msg.sender] == 0)
        {
            allPlayers.push(msg.sender);
        }
        playersToTotalBets[msg.sender] += _amount;
         
        uint256 betIndex = betsLength;
        Bet storage bet = bets[betIndex];
        require(bet.status == BetStatus.IN_PROGRESS);
         
        uint randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%100);
       
         
        bet.roll = randomNumber;
        
         
        if (randomNumber < bet.winningChance/100)
        {
             
             
            if (stakeTokenContract.balanceOf(this) < bet.potentialRevenue)
            {
                _cancelBet(betIndex);
            }
            
             
            else
            {
                 
                bet.status = BetStatus.WON;
            
                 
                stakeTokenContract.transfer(bet.gambler, bet.potentialRevenue);
                
                 
                emit BetWon(bet.gambler, betIndex);
            }
        }
        else
        {
             
            bet.status = BetStatus.LOST;
            
             
             
            stakeTokenContract.transfer(bet.gambler, 1);  
            
             
            emit BetLost(bet.gambler, betIndex);
        }
    }
    
    function _cancelBet(uint256 _betIndex) private
    {
         
        require(bets[_betIndex].status == BetStatus.IN_PROGRESS);
        
         
        bets[_betIndex].status = BetStatus.CANCELED;
        
         
        stakeTokenContract.transfer(bets[_betIndex].gambler, bets[_betIndex].betAmount);
        
         
        emit BetCanceled(bets[_betIndex].gambler, _betIndex);
        
         
        playersToTotalBets[bets[_betIndex].gambler] -= bets[_betIndex].betAmount;
    }
    
    function amountOfGames() external view returns (uint256)
    {
        return allGames.length;
    }
    
    function amountOfBets() external view returns (uint256)
    {
        return bets.length-1;
    }
    
     
     
    
    address public owner;
    
     
    constructor(StakeToken _stakeTokenContract, uint256 _houseEdge, uint256 _minimumBet) public
    {
         
         
        bets.length = 1;
        
         
        owner = msg.sender;
        
         
        require(_houseEdge < 10000);
        require(_stakeTokenContract != address(0x0));
        
         
        stakeTokenContract = _stakeTokenContract;
        houseEdge = _houseEdge;
        minimumBet = _minimumBet;
    }
    
     
    function createDefaultGames() public
    {
        require(allGames.length == 0);
        
        addNewStakeDiceGame(500);  
        addNewStakeDiceGame(1000);  
        addNewStakeDiceGame(1500);  
        addNewStakeDiceGame(2000);  
        addNewStakeDiceGame(2500);  
        addNewStakeDiceGame(3000);  
        addNewStakeDiceGame(3500);  
        addNewStakeDiceGame(4000);  
        addNewStakeDiceGame(4500);  
        addNewStakeDiceGame(5000);  
        addNewStakeDiceGame(5500);  
        addNewStakeDiceGame(6000);  
        addNewStakeDiceGame(6500);  
        addNewStakeDiceGame(7000);  
        addNewStakeDiceGame(7500);  
        addNewStakeDiceGame(8000);  
        addNewStakeDiceGame(8500);  
        addNewStakeDiceGame(9000);  
        addNewStakeDiceGame(9500);  
    }
    
     
     
     
    function cancelBet(uint256 _betIndex) public
    {
        require(msg.sender == owner);
        
        _cancelBet(_betIndex);
    }
    
     
    function addNewStakeDiceGame(uint256 _winningChance) public
    {
        require(msg.sender == owner);
        
         
        StakeDiceGame newGame = new StakeDiceGame(this, _winningChance);
        
         
        addressIsStakeDiceGameContract[newGame] = true;
        allGames.push(newGame);
    }
    
     
    function setHouseEdge(uint256 _newHouseEdge) external
    {
        require(msg.sender == owner);
        require(_newHouseEdge < 10000);
        houseEdge = _newHouseEdge;
    }
    
     
     
     
    function setMinimumBet(uint256 _newMinimumBet) external
    {
        require(msg.sender == owner);
        minimumBet = _newMinimumBet;
    }
    
     
     
    function depositEther() payable external
    {
        require(msg.sender == owner);
    }
    function withdrawEther(uint256 _amount) payable external
    {
        require(msg.sender == owner);
        owner.transfer(_amount);
    }
    
     
    function transferOwnership(address _newOwner) external 
    {
        require(msg.sender == owner);
        require(_newOwner != 0x0);
        owner = _newOwner;
    }
    
     
    function withdrawStakeTokens(uint256 _amount) external
    {
        require(msg.sender == owner);
        stakeTokenContract.transfer(owner, _amount);
    }
    
     
    function () payable external
    {
        revert();
    }
    
}