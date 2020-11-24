 

pragma solidity ^0.4.17;

contract PyramidGame
{
     
     
    uint256 private constant BOTTOM_LAYER_BET_AMOUNT = 0.005 ether;
    uint256 private adminFeeDivisor;  
    
     
     
    address private administrator;
    
     
     
     
     
     
     
     
     
     
     
     
     
    mapping(uint32 => address) public coordinatesToAddresses;
    uint32[] public allBlockCoordinates;
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
     
    mapping(address => uint256) public addressesToTotalWeiPlaced;
    mapping(address => uint256) public addressBalances;
    
     
     
    function PyramidGame() public
    {
        administrator = msg.sender;
        adminFeeDivisor = 200;  
        
         
        addressesToChatMessagesLeft[administrator] += 5;
        
         
        coordinatesToAddresses[uint32(1 << 15) << 16] = msg.sender;
        allBlockCoordinates.push(uint32(1 << 15) << 16);
    }
    
     
     
    function getBetAmountAtLayer(uint16 y) public pure returns (uint256)
    {
         
        return BOTTOM_LAYER_BET_AMOUNT * (uint256(1) << y);
    }
    
    function isThereABlockAtCoordinates(uint16 x, uint16 y) public view returns (bool)
    {
        return coordinatesToAddresses[(uint32(x) << 16) | uint16(y)] != 0;
    }
    
    function getTotalAmountOfBlocks() public view returns (uint256)
    {
        return allBlockCoordinates.length;
    }
    
     
     
    function placeBlock(uint16 x, uint16 y) external payable
    {
         
        require(!isThereABlockAtCoordinates(x, y));
        
         
        addressBalances[msg.sender] += msg.value;
        
         
        uint256 betAmount = getBetAmountAtLayer(y);

         
        if (y == 0)
        {
             
            require(isThereABlockAtCoordinates(x-1, y) ||
                    isThereABlockAtCoordinates(x+1, y));
        }
        
         
        else
        {
             
            require(isThereABlockAtCoordinates(x  , y-1) &&
                    isThereABlockAtCoordinates(x+1, y-1));
        }
        
         
        addressBalances[msg.sender] -= betAmount;
        
         
        coordinatesToAddresses[(uint32(x) << 16) | y] = msg.sender;
        allBlockCoordinates.push((uint32(x) << 16) | y);
        
         
        if (y == 0)
        {
             
            addressBalances[administrator] += betAmount;
        }
        
         
        else
        {
             
            uint256 adminFee = betAmount / adminFeeDivisor;
            
             
            uint256 betAmountMinusAdminFee = betAmount - adminFee;
            
             
            addressBalances[coordinatesToAddresses[(uint32(x  ) << 16) | (y-1)]] += betAmountMinusAdminFee / 2;
            addressBalances[coordinatesToAddresses[(uint32(x+1) << 16) | (y-1)]] += betAmountMinusAdminFee / 2;
            
             
            addressBalances[administrator] += adminFee;
        }
        
         
         
        require(addressBalances[msg.sender] < (1 << 255));
        
         
        addressesToChatMessagesLeft[msg.sender] += uint32(1) << y;
        
         
        addressesToTotalWeiPlaced[msg.sender] += betAmount;
    }
    
     
     
    function withdrawBalance(uint256 amountToWithdraw) external
    {
        require(amountToWithdraw != 0);
        
         
        require(addressBalances[msg.sender] >= amountToWithdraw);
        
         
        addressBalances[msg.sender] -= amountToWithdraw;
        
         
         
         
        msg.sender.transfer(amountToWithdraw);
    }
    
     
     
    struct ChatMessage
    {
        address person;
        string message;
    }
    mapping(bytes32 => address) public usernamesToAddresses;
    mapping(address => bytes32) public addressesToUsernames;
    mapping(address => uint32) public addressesToChatMessagesLeft;
    ChatMessage[] public chatMessages;
    mapping(uint256 => bool) public censoredChatMessages;
    
     
     
    function registerUsername(bytes32 username) external
    {
         
        require(usernamesToAddresses[username] == 0);
        
         
        require(addressesToUsernames[msg.sender] == 0);
        
         
        usernamesToAddresses[username] = msg.sender;
        addressesToUsernames[msg.sender] = username;
    }
    
    function sendChatMessage(string message) external
    {
         
        require(addressesToChatMessagesLeft[msg.sender] >= 1);
        
         
        addressesToChatMessagesLeft[msg.sender]--;
        
         
        chatMessages.push(ChatMessage(msg.sender, message));
    }
    
    function getTotalAmountOfChatMessages() public view returns (uint256)
    {
        return chatMessages.length;
    }
    
    function getChatMessageAtIndex(uint256 index) public view returns (address, bytes32, string)
    {
        address person = chatMessages[index].person;
        bytes32 username = addressesToUsernames[person];
        return (person, username, chatMessages[index].message);
    }
    
     
     
    function censorChatMessage(uint256 chatMessageIndex) public
    {
        require(msg.sender == administrator);
        censoredChatMessages[chatMessageIndex] = true;
    }
    
     
     
    function transferOwnership(address newAdministrator) external
    {
        require(msg.sender == administrator);
        administrator = newAdministrator;
    }
    
    function setFeeDivisor(uint256 newFeeDivisor) external
    {
        require(msg.sender == administrator);
        require(newFeeDivisor >= 20);  
        adminFeeDivisor = newFeeDivisor;
    }
}