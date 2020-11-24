 

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


contract LinkedList {

    struct Element {
        uint previous;
        uint next;

        address data;
    }

    uint public size;
    uint public tail;
    uint public head;
    mapping(uint => Element) elements;
    mapping(address => uint) elementLocation;

    function addItem(address _newItem) public returns (bool) {
        Element memory elem = Element(0, 0, _newItem);

        if (size == 0) {
            head = 1;
        } else {
            elements[tail].next = tail + 1;
            elem.previous = tail;
        }

        elementLocation[_newItem] = tail + 1;
        elements[tail + 1] = elem;
        size++;
        tail++;
        return true;
    }

    function removeItem(address _item) public returns (bool) {
        uint key;
        if (elementLocation[_item] == 0) {
            return false;
        }else {
            key = elementLocation[_item];
        }

        if (size == 1) {
            tail = 0;
            head = 0;
        }else if (key == head) {
            head = elements[head].next;
        }else if (key == tail) {
            tail = elements[tail].previous;
            elements[tail].next = 0;
        }else {
            elements[key - 1].next = elements[key].next;
            elements[key + 1].previous = elements[key].previous;
        }

        size--;
        delete elements[key];
        elementLocation[_item] = 0;
        return true;
    }

    function getAllElements() constant public returns(address[]) {
        address[] memory tempElementArray = new address[](size);
        uint cnt = 0;
        uint currentElemId = head;
        while (cnt < size) {
            tempElementArray[cnt] = elements[currentElemId].data;
            currentElemId = elements[currentElemId].next;
            cnt += 1;
        }
        return tempElementArray;
    }

    function getElementAt(uint _index) constant public returns (address) {
        return elements[_index].data;
    }

    function getElementLocation(address _element) constant public returns (uint) {
        return elementLocation[_element];
    }

    function getNextElement(uint _currElementId) constant public returns (uint) {
        return elements[_currElementId].next;
    }
}

contract ICreditBIT{
    function claimGameReward(address _champion, uint _lockedTokenAmount, uint _lockTime) returns (uint error);
}

contract CreditGAME is Owned, SafeMath, LinkedList{
    
    mapping(address => bool) approvedGames;
    mapping(address => GameLock) gameLocks;
    mapping(address => bool) public isGameLocked;
    mapping(uint => address) public concludedGames;
    
    uint public amountLocked = 0;
    uint public concludedGameIndex = 0;
    
    struct GameLock{
        uint amount;
        uint lockDuration;
    }
    
    event LockParameters(address gameAddress, uint totalParticipationAmount, uint tokenLockDuration);
    event UnlockParameters(address gameAddress, uint totalParticipationAmount);
    event GameConcluded(address gameAddress);

     
    address public tokenAddress = 0xAef38fBFBF932D1AeF3B808Bc8fBd8Cd8E1f8BC5;
    
     
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }

     
    function addApprovedGame(address _gameAddress) onlyOwner public{
        approvedGames[_gameAddress] = true;
        addItem(_gameAddress);
    }
    
     
    function removeApprovedGame(address _gameAddress) onlyOwner public{
        approvedGames[_gameAddress] = false;
        removeItem(_gameAddress);
    }

     
    function removeFailedGame() public{
      require(approvedGames[msg.sender] == true);
      removeItem(msg.sender);
      approvedGames[msg.sender] = false;
      concludedGames[concludedGameIndex] = msg.sender; 
      concludedGameIndex++;
      emit GameConcluded(msg.sender);
    }
    
     
    function isGameApproved(address _gameAddress) view public returns(bool){
        if(approvedGames[_gameAddress] == true){
            return true;
        }else{
            return false;
        }
    }
    
     
    function createLock(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) public {
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == false);
        
         
        GameLock memory gameLock = GameLock(_totalParticipationAmount, block.number + _tokenLockDuration);
        gameLocks[msg.sender] = gameLock;
        isGameLocked[msg.sender] = true;
        amountLocked = safeAdd(amountLocked, _totalParticipationAmount);
        
         
        generateChampionTokens(_winner, _totalParticipationAmount, _tokenLockDuration);
        emit LockParameters(msg.sender, _totalParticipationAmount, block.number + _tokenLockDuration);
    }
    
     
    function generateChampionTokens(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) internal{
        ICreditBIT(tokenAddress).claimGameReward(_winner, _totalParticipationAmount, _tokenLockDuration);
    }
    
     
    function checkInternalBalance() public view returns(uint256 tokenBalance) {
        return IERC20Token(tokenAddress).balanceOf(address(this));
    }
    
     
    function removeLock() public{
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == true);
        require(checkIfLockCanBeRemoved(msg.sender) == true);
        GameLock memory gameLock = gameLocks[msg.sender];
        
         
        IERC20Token(tokenAddress).transfer(msg.sender, gameLock.amount);
        
        delete(gameLocks[msg.sender]);
        
         
        amountLocked = safeSub(amountLocked, gameLock.amount);
        
        isGameLocked[msg.sender] = false;
        emit UnlockParameters(msg.sender, gameLock.amount);
    }
    
     
    function cleanUp() public{
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == false);
        removeItem(msg.sender);
        
        approvedGames[msg.sender] = false;
        concludedGames[concludedGameIndex] = msg.sender; 
        concludedGameIndex++;
        emit GameConcluded(msg.sender);
    }

     
    function removeGameManually(address _gameAddress, address _tokenHolder) onlyOwner public{
      GameLock memory gameLock = gameLocks[_gameAddress];
       
      IERC20Token(tokenAddress).transfer(_tokenHolder, gameLock.amount);
       
      amountLocked = safeSub(amountLocked, gameLock.amount);
      delete(gameLocks[_gameAddress]);
      isGameLocked[_gameAddress] = false;
      removeItem(_gameAddress);
      approvedGames[_gameAddress] = false;
    }
    
     
    function getGameLock(address _gameAddress) public view returns(uint, uint){
        require(isGameLocked[_gameAddress] == true);
        GameLock memory gameLock = gameLocks[_gameAddress];
        return(gameLock.amount, gameLock.lockDuration);
    }

     
    function isGameLocked(address _gameAddress) public view returns(bool){
      if(isGameLocked[_gameAddress] == true){
        return true;
      }else{
        return false;
      }
    }
    
     
    function checkIfLockCanBeRemoved(address _gameAddress) public view returns(bool){
        require(approvedGames[_gameAddress] == true);
        require(isGameLocked[_gameAddress] == true);
        GameLock memory gameLock = gameLocks[_gameAddress];
        if(gameLock.lockDuration < block.number){
            return true;
        }else{
            return false;
        }
    }

     
    function killContract() onlyOwner public {
      selfdestruct(owner);
    }
}