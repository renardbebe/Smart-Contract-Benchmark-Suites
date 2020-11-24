 

pragma solidity ^0.4.17;

 
 
 
 
 

library SafeMath {
      function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
      }
      function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
      }
      function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
      }
      function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
      }
      function assert(bool assertion) internal {
        if (!assertion) {
          throw;
        }
      }
    }


contract Circleramide {
    using SafeMath for uint;
    
     
    event SendMessage(uint id, string message, address sender);
    event NewBlock(uint id);
    event Reward(uint blockID, address player, uint reward);
    event Withdraw(address player);
    
     modifier onlyOwner() {
        require(msg.sender == owner); _;
    }
    
     
    address owner;

    uint public totalBlocks = 0;
    uint public rewardBalance;

 
    uint private constant FIRST_ROW_BLOCKS_COUNT = 128;
    uint private constant MAXIMUM_ROWS_COUNT = FIRST_ROW_BLOCKS_COUNT - 1;
    uint private constant FIRST_BLOCK_PRICE = .005 ether;


    bool public isLive;

     
    uint public rewardsCount;
    
    uint private constant REWARDED_BLOCK = 100;
    uint private constant REWARDS_TOTAL = 49;  
    uint private constant REWARD_DIV = 120; 
    
     
    uint private constant REWARD_FEE_TOP = 70;
    uint private constant REWARD_FEE_DIV = 100;  
    
     
    uint private constant FEE_TOP = 2;
    uint private constant FEE_DIV = 100;  
    
      
    uint private constant NEXT_ROW_PROPORTION_TOP = 25;  
    uint private constant NEXT_ROW_PROPORTION_DIV = 100;  
 
    
    struct Block {
        uint x;
        uint y;
        string message;
    }
    
    mapping(address => uint) public balances;
    mapping (uint => mapping(uint => uint)) public blocksCoordinates;
    mapping (uint => address) public blocksOwners;
    mapping (uint => uint) public prices;
    mapping (uint => address) public rewards_id;
    mapping (uint => uint) public rewards_amount;
    mapping (uint => Block) public blocks;
    

    function Circleramide() {
        isLive = true;
        owner = msg.sender;
        prices[0] = FIRST_BLOCK_PRICE;
        
        totalBlocks = 1;
        calculatePrice(0);
        placeBlock(owner, 0, 0, 'First Block :)');
        sendMessage('Welcome to the Circleramide!');
    }

     
    function setBlock(uint x, uint y, string message) external payable {
        if(isLive) {
            address sender = msg.sender;
            
            uint bet = calculatePrice(y);
            uint senderBalance = balances[sender] + msg.value;
            
            require(bet <= senderBalance);
            
            if(checkBlockEmpty(x, y)) {
                uint fee = (bet * FEE_TOP)/FEE_DIV;
                uint jackpotFee = (fee * REWARD_FEE_TOP)/REWARD_FEE_DIV;
                uint amountForOwner = fee - jackpotFee;
                uint amountForBlock = bet - fee;
                
    
                if(x < FIRST_ROW_BLOCKS_COUNT - y) {
                   balances[owner] += amountForOwner;
                   rewardBalance += jackpotFee;
                   balances[sender] = senderBalance - bet;
                   
                   if(y == 0) {
                        uint firstBlockReward = (amountForBlock * REWARD_FEE_TOP)/REWARD_FEE_DIV;
                        rewardBalance += firstBlockReward;
                        balances[owner] += amountForBlock - firstBlockReward; 
                        placeBlock(sender, x, y, message);
                   } else {
                        placeToRow(sender, x, y, message, amountForBlock);
                   }
                } else {
                    throw;   
                }
            } else {
                throw;   
            }
        } else {
            throw;   
        }
     }
    

    
     
    function placeBlock(address sender, uint x, uint y, string message) private {
        blocksCoordinates[y][x] = totalBlocks; 
     
        blocks[totalBlocks] = Block(x, y, message);
        blocksOwners[totalBlocks] = sender;

        NewBlock(totalBlocks);
    

         
        if(totalBlocks % REWARDED_BLOCK == 0) {
            uint reward;
             
            if(rewardsCount == REWARDS_TOTAL) {
                isLive = false;  
                rewardsCount++;
                reward = rewardBalance;  
                rewardBalance = 0;
            } else {
                rewardsCount++;
                reward = calculateReward();
                rewardBalance = rewardBalance.sub(reward);
            }
            
            balances[sender] += reward;
            Reward(rewardsCount, sender, reward);
            rewards_id[rewardsCount-1] = sender;
            rewards_amount[rewardsCount-1] = reward;
        }
        totalBlocks++;
    }
    function placeToRow(address sender, uint x, uint y, string message, uint bet) private {
       uint parentY = y - 1;
                        
       uint parent1_id = blocksCoordinates[parentY][x];
       uint parent2_id = blocksCoordinates[parentY][x + 1];
       
       if(parent1_id != 0 && parent2_id != 0) {
            address owner_of_block1 = blocksOwners[parent1_id];
            address owner_of_block2 = blocksOwners[parent2_id];
            
            uint reward1 = bet/2;
            uint reward2 = bet - reward1;
            balances[owner_of_block1] += reward1;
            balances[owner_of_block2] += reward2;
            
            placeBlock(sender, x, y, message);

       } else {
           throw;
       }
    }
    
    function calculatePrice(uint y) private returns (uint) {
        uint nextY = y + 1;
        uint currentPrice = prices[y];
        if(prices[nextY] == 0) {
            prices[nextY] = currentPrice + (currentPrice * NEXT_ROW_PROPORTION_TOP)/NEXT_ROW_PROPORTION_DIV;
            return currentPrice;
        } else {
            return currentPrice;
        }
    }
    function withdrawBalance(uint amount) external {
        require(amount != 0);
        
         
        require(balances[msg.sender] >= amount);
        
         
        balances[msg.sender] = balances[msg.sender].sub(amount);
        
         
         
         
        msg.sender.transfer(amount);
        
        Withdraw(msg.sender);
    }
    
    
     
    function calculateReward() public constant returns (uint) {
        return (rewardBalance * rewardsCount) / REWARD_DIV;
    }
    function getBlockPrice(uint y)  constant returns (uint) {
        return prices[y];
    }
    function checkBlockEmpty(uint x, uint y) constant returns (bool) {
        return blocksCoordinates[y][x] == 0;
    }
    function Info() constant returns (uint tb, uint bc, uint fbp, uint rc, uint rb, uint rt, uint rf, uint rd, uint mc, uint rew) {
        tb = totalBlocks;
        bc = FIRST_ROW_BLOCKS_COUNT;
        fbp = FIRST_BLOCK_PRICE;
        rc = rewardsCount;
        rb = rewardBalance;
        rt = REWARDS_TOTAL;
        rf = REWARD_FEE_TOP;
        rd = REWARD_DIV;
        mc = messagesCount;
        rew = REWARDED_BLOCK;
    }
    function getBlock(uint id) public constant returns (uint i, uint x, uint y, address owmer, string message) {
        Block storage block = blocks[id];
        i = id;
        x = block.x;
        y = block.y;
        owner = blocksOwners[id];
        message = block.message;
    }
    function getRewards(uint c, uint o) public constant returns (uint cursor, uint offset, uint[] array) {
        uint n;
        uint[] memory arr = new uint[](o * 2);
        offset = o; cursor = c;
        uint l = offset + cursor;
        for(uint i = cursor; i<l; i++) {
            arr[n] = uint(rewards_id[i]);
            arr[n + 1] = rewards_amount[i];
            n += 2;
        }
        array = arr;
    }
    function getBlocks(uint c, uint o) public constant returns (uint cursor, uint offset, uint[] array) {
        uint n;
        uint[] memory arr = new uint[](o * 3);
        offset = o; cursor = c;
        uint l = offset + cursor;
        for(uint i = cursor; i<l; i++) {
            Block storage b = blocks[i+1];
            arr[n] = (b.x);
            arr[n + 1] = (b.y);
            arr[n + 2] = uint(blocksOwners[i+1]);
            n += 3;
        }
        array = arr;
    }
    function getPrices(uint c, uint o) public constant returns (uint cursor, uint offset, uint[] array) {
        uint n;
        uint[] memory arr = new uint[](o);
        offset = o;  cursor = c;
        uint l = offset + cursor;
        for(uint i = cursor; i<l; i++) {
            arr[n] = prices[i];
            n++;
        }
        array = arr;
    }
    
    
     
     
     
    
    struct Message {
        address sender;
        string message;
    }
    uint private messagesCount;
    mapping(address => string) public usernames;
    mapping(uint => Message) public messages;
    
    function sendMessage(string message) public returns (uint) {
        messages[messagesCount] = Message(msg.sender, message);
        SendMessage(messagesCount, message, msg.sender);
        messagesCount = messagesCount.add(1);
        return messagesCount;
    }
    function setUserName(string name) public returns (bool) {
        address sender = msg.sender;
        
        bytes memory username = bytes(usernames[sender]);
        if(username.length == 0) {
            usernames[sender] = name;
            return true;
        }
        return false;
    }
}