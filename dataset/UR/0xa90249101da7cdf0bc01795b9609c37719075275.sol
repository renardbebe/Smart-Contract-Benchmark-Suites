 

pragma solidity ^0.5.2;

 

contract UpsweepV1 {

    uint public elapsed;
    uint public timeout;
    uint public lastId;
    uint public counter;
    bool public closed;
    
    struct Player {
        bool revealOnce;
        bool claimed;
        bool gotHonour;
        uint8 i;
        bytes32 commit;
    }

    mapping(uint => mapping (address => Player)) public player;
    mapping(uint => uint8[20]) public balancesById;   
    mapping(uint => uint8[20]) public bottleneckById;
    
    address payable public owner = msg.sender;
    uint public ticketPrice = 100000000000000000;
    
    mapping(uint => uint) public honour;
    
    event FirstBlock(uint);
    event LastBlock(uint);
    event Join(uint);
    event Reveal(uint seat, uint indexed gameId);
    event NewId(uint);
    
    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    }
    
    modifier circleIsPrivate(bool _closed) {
        require(
            _closed == true,
            "Game is in progress."
        );
        _;
    }
    
    modifier circleIsPublic(bool _closed) {
        require(
            _closed == false,
            "Next game has not started."
        );
        _;
    } 
    
    modifier onlyAfter(uint _time) {
        require(
            block.number > _time,
            "Function called too early."
        );
        _;
    }
    
    modifier onlyBefore(uint _time) {
        require(
            block.number <= _time,
            "Function called too late."
        );
        _;
    }
    
    modifier ticketIsAffordable(uint _amount) {
        require(
            msg.value >= _amount,
            "Not enough Ether provided."
        );
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value - _amount);
    }
    
     
    function join(bytes32 _hash)
        public
        payable
        circleIsPublic(closed)
        ticketIsAffordable(ticketPrice)
        returns (uint gameId)
    {
         
        require(
            counter < 40,       
            "Game is full."
        );            
        
         
        if (counter == 0) {
            elapsed = block.number;
            emit FirstBlock(block.number);
        }

        player[lastId][msg.sender].commit = _hash;
        
         
         
        if (counter == 39) {       
            closed = true;
            uint temp = sub(block.number,elapsed);
            timeout = add(temp,block.number);
            emit LastBlock(timeout);
        } 
        
        counter++;

        emit Join(counter);
        return lastId;
    }
   
      
    function abandon()
        public
        circleIsPublic(closed)
        returns (bool success)
    {
        bytes32 commit = player[lastId][msg.sender].commit;
        require(
            commit != 0,
            "Player was not in the game."
        );
        
        player[lastId][msg.sender].commit = 0;
        counter --;
        if (counter == 0) {
            elapsed = 0;
            emit FirstBlock(0);
        }    
        emit Join(counter);
        msg.sender.transfer(ticketPrice);
        return true;
    }     
     
    function reveal(
        uint8 i, 
        string memory passphrase 
    )
        public 
        circleIsPrivate(closed)
        onlyBefore(timeout)
        returns (bool success)
    {
        bool status = player[lastId][msg.sender].revealOnce;
        require(
            status == false,
            "Player already revealed."
        );
        
        bytes32 commit = player[lastId][msg.sender].commit;
 
         
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender,i,passphrase)
        );
            
        require(
            hash == commit,
            "Hashes don't match."
        );
        
        player[lastId][msg.sender].revealOnce = true;
        player[lastId][msg.sender].i = i;
        
         
        balancesById[lastId][i] ++;
         
        bottleneckById[lastId][i] ++;
        
        counter--;
         
        if (counter == 0) {
            timeout = 0;
            updateBalances();
        }
        
        emit Reveal(i,lastId);
        return true;
    }
  
     
    function updateBalances()
        public
        circleIsPrivate(closed)
        onlyAfter(timeout)
        returns (bool success)
    {
         
        for (uint8 i = 0; i < 20; i++) {
            if (balancesById[lastId][i] == 0) { 
                 
                uint j = i + 1;
                for (uint8 a = 0; a < 19; a++) {   
                    if (j == 20) j = 0;
                    if (j == 19) {       
                        if (balancesById[lastId][0] > 0) {
                            uint8 temp = balancesById[lastId][19];
                            balancesById[lastId][19] = 0;
                            balancesById[lastId][0] += temp;  
                            j = 0; 
                        } else {
                            j = 1;
                        }
                    } else {            
                        if (balancesById[lastId][j + 1] > 0) { 
                            uint8 temp = balancesById[lastId][j];
                            balancesById[lastId][j] = 0;
                            balancesById[lastId][j + 1] += temp; 
                            j += 1; 
                        } else { 
                            j += 2; 
                        }
                    }
                }
                 
                break;
            }
        }
         
        closed = false;
        if (timeout > 0) timeout = 0;
        elapsed = 0;
         
         
        if (counter > 0) {
            uint total = mul(counter, ticketPrice);
            uint among = sub(40,counter);
            honour[lastId] = div(total,among);
            counter = 0;
        } 
        lastId ++;
        emit NewId(lastId);
        return true;
    }
    
     
    function withdraw(uint gameId) 
        public
        returns (bool success)
    {
        bool status = player[gameId][msg.sender].revealOnce;
        require(
            status == true,
            "Player has not revealed."
        );
        
        bool claim = player[gameId][msg.sender].claimed;
        require(
            claim == false,
            "Player already claimed."
        );
        
        uint8 index = player[gameId][msg.sender].i;
        require(
            balancesById[gameId][index] > 0,
            "Player didn't won."
        );
        
        player[gameId][msg.sender].claimed = true;
        
        uint temp = uint(balancesById[gameId][index]);
        uint among = uint(bottleneckById[gameId][index]);
        uint total = mul(temp, ticketPrice);
        uint payout = div(total, among);
        
        msg.sender.transfer(payout);   
        
        return true;
    }   
    
    function microTip()
        public
        payable
        returns (bool success)
    {
        owner.transfer(msg.value);
        return true;
    }
    
    function changeOwner(address payable _newOwner)
        public
        onlyBy(owner)
        returns (bool success)
    {
        owner = _newOwner;
        return true;
    }
    
    function getHonour(uint _gameId)
        public
        returns (bool success)
    {
        bool status = player[_gameId][msg.sender].gotHonour;
        require(
            status == false,
            "Player already claimed honour."
        );
        bool revealed = player[_gameId][msg.sender].revealOnce;
        require(
            revealed == true,
            "Player has not revealed."
        );
        player[_gameId][msg.sender].gotHonour = true;
        msg.sender.transfer(honour[_gameId]);
        return true;
    }
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }


}