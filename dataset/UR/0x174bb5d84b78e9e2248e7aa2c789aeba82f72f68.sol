 

pragma solidity ^0.4.21;

contract SafeMath {
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}
contract Owned {
    address public owner;
    address public newOwner;

    function Owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}
contract IERC20Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CreditGAMEInterface {
    function isGameApproved(address _gameAddress) view public returns(bool);
    function createLock(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) public;
    function removeFailedGame() public;
    function removeLock() public;
    function cleanUp() public;
    function checkIfLockCanBeRemoved(address _gameAddress) public view returns(bool);
}


contract LuckyTree is Owned, SafeMath{
    
    uint public leafPrice;
    uint public gameStart;
    uint public gameDuration;
    uint public tokenLockDuration;
    uint public totalParticipationAmount;
    uint public totalLockedAmount;
    uint public numberOfLeafs;
    uint public participantIndex;
    bool public fundsTransfered;
    address public winner;
    mapping(uint => address) public participants;
    mapping(uint => uint) public participationAmount;
    mapping(address => bool) public hasParticipated;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint) public participantIndexes;
    mapping(uint => address) public leafOwners;
    
    event GameWinner(address winner);
    event GameEnded(uint block);
    event GameStarted(uint block);
    event GameFailed(uint block);
    event GameLocked(uint block);
    event GameUnlocked(uint block);
    
    enum state{
        pending,
        running,
        paused,
        finished,
        closed,
        claimed
    }
    
    state public gameState;
    
     
    address public tokenAddress = 0xfc6b46d20584a7f736c0d9084ab8b1a8e8c01a38;
    address public creditGameAddress = 0x7f135d5d5c1d2d44cf6abb7d09735466ba474799;

     
    function LuckyTree(
        uint _leafPrice,
        uint _gameStart,
        uint _gameDuration,
        uint _tokenLockDuration) public{
        
        leafPrice = _leafPrice;
        gameStart = _gameStart;
        gameDuration = _gameDuration;
        tokenLockDuration = _tokenLockDuration;
        
        gameState = state.pending;
        totalParticipationAmount = 0;
        numberOfLeafs = 0;
        participantIndex = 0;
        fundsTransfered = false;
        winner = 0x0;
    }
    
     
    function random() internal view returns(uint){
        return uint(keccak256(block.number, block.difficulty, numberOfLeafs));
    }
    
     
    function setTokenAddress(address _tokenAddress) public onlyOwner{
        tokenAddress = _tokenAddress;
    }
    
     
    function setCreditGameAddress(address _creditGameAddress) public onlyOwner{
        creditGameAddress = _creditGameAddress;
    }
    
     
    function pickWinner() internal{
        if(numberOfLeafs > 0){
            if(participantIndex == 1){
                 
                IERC20Token(tokenAddress).transfer(leafOwners[0], totalParticipationAmount);
                hasWithdrawn[leafOwners[0]] = true;
                CreditGAMEInterface(creditGameAddress).removeFailedGame();
                emit GameFailed(block.number);
            }else{
                uint leafOwnerIndex = random() % numberOfLeafs;
                winner = leafOwners[leafOwnerIndex];
                emit GameWinner(winner);
                lockFunds(winner);
                
            }
        }
        gameState = state.closed;
    }
    
     
    function lockFunds(address _winner) internal{
        require(totalParticipationAmount != 0);
         
        IERC20Token(tokenAddress).transfer(creditGameAddress, totalParticipationAmount);
        CreditGAMEInterface(creditGameAddress).createLock(_winner, totalParticipationAmount, tokenLockDuration);
        totalLockedAmount = totalParticipationAmount;
        emit GameLocked(block.number);
    }
    
     
    function manualLockFunds() public onlyOwner{
        require(totalParticipationAmount != 0);
        require(CreditGAMEInterface(creditGameAddress).isGameApproved(address(this)) == true);
        require(gameState == state.closed);
         
        pickWinner();
    }
    
     
    function closeGame() public onlyOwner{
        gameState = state.closed;
    }
    
     
    function unlockFunds() public {
        require(gameState == state.closed);
        require(hasParticipated[msg.sender] == true);
        require(hasWithdrawn[msg.sender] == false);
        
        if(fundsTransfered == false){
            require(CreditGAMEInterface(creditGameAddress).checkIfLockCanBeRemoved(address(this)) == true);
            CreditGAMEInterface(creditGameAddress).removeLock();
            fundsTransfered = true;
            emit GameUnlocked(block.number);
        }
        
        hasWithdrawn[msg.sender] = true;
        uint index = participantIndexes[msg.sender];
        uint amount = participationAmount[index];
        IERC20Token(tokenAddress).transfer(msg.sender, amount);
        totalLockedAmount = IERC20Token(tokenAddress).balanceOf(address(this));
        if(totalLockedAmount == 0){
            gameState = state.claimed;
            CreditGAMEInterface(creditGameAddress).cleanUp();
        }
    }
    
     
    function checkInternalBalance() public view returns(uint256 tokenBalance) {
        return IERC20Token(tokenAddress).balanceOf(address(this));
    }
    
     
    function receiveApproval(address _from, uint256 _value, address _to, bytes _extraData) public {
        require(_to == tokenAddress);
        require(_value == leafPrice);
        require(gameState != state.closed);
         
        require(CreditGAMEInterface(creditGameAddress).isGameApproved(address(this)) == true);

        uint tokensToTake = processTransaction(_from, _value);
        IERC20Token(tokenAddress).transferFrom(_from, address(this), tokensToTake);
    }

     
    function processTransaction(address _from, uint _value) internal returns (uint) {
        require(gameStart <= block.number);
        
        uint valueToProcess = 0;
        
        if(gameStart <= block.number && gameDuration >= block.number){
            if(gameState != state.running){
                gameState = state.running;
                emit GameStarted(block.number);
            }
             
            leafOwners[numberOfLeafs] = _from;
            numberOfLeafs++;
            totalParticipationAmount += _value;
            
             
            if(hasParticipated[_from] == false){
                hasParticipated[_from] = true;
                
                participants[participantIndex] = _from;
                participationAmount[participantIndex] = _value;
                participantIndexes[_from] = participantIndex;
                participantIndex++;
            }else{
                uint index = participantIndexes[_from];
                participationAmount[index] = participationAmount[index] + _value;
            }
            
            valueToProcess = _value;
            return valueToProcess;
         
        }else if(gameDuration < block.number){
            gameState = state.finished;
            pickWinner();
            return valueToProcess;
        }
    }

     
    function getVariablesForDapp() public view returns(uint, uint, uint, uint, uint, uint, state){
      return(leafPrice, gameStart, gameDuration, tokenLockDuration, totalParticipationAmount, numberOfLeafs, gameState);
    }

     
    function manuallyProcessTransaction(address _from, uint _value) onlyOwner public {
        require(_value == leafPrice);
        require(IERC20Token(tokenAddress).balanceOf(address(this)) >= _value + totalParticipationAmount);

        if(gameState == state.running && block.number < gameDuration){
            uint tokensToTake = processTransaction(_from, _value);
            IERC20Token(tokenAddress).transferFrom(_from, address(this), tokensToTake);
        }

    }

     
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        require(_tokenAddress != tokenAddress);
        IERC20Token(_tokenAddress).transfer(_to, _amount);
    }

     
    function killContract() onlyOwner public {
      selfdestruct(owner);
    }
}