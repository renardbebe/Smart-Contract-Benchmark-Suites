 

pragma solidity ^0.4.24;

 

contract UnstoppablePyramid {
    
     
    address devAddress = 0x75E129b02D12ECa5A5D7548a5F75007f84387b8F;

     
    uint256 basePricePonzi = 50000000000000000;     

     
    uint256 totalAmountPlayed;
    uint256 totalCommissionSent;

    struct PonziFriend {
        address playerAddr;
        uint parent;
        uint256 amountPlayed;    
        uint256 amountEarned;    
    }
    PonziFriend[] ponziFriends;
    mapping (address => uint) public ponziFriendsToId;
    
     
    mapping (uint => uint) public ponziFriendToLevel1Ref;
    mapping (uint => uint) public ponziFriendToLevel2Ref;
    mapping (uint => uint) public ponziFriendToLevel3Ref;

     
    function newPonziFriend(uint _parentId) public payable isHuman() {
         
        uint256 com1percent = msg.value / 100;
        uint256 comLevel1 = com1percent * 50;  
        uint256 comLevel2 = com1percent * 35;  
        uint256 comLevel3 = com1percent * 15;  
    
        require(msg.value >= basePricePonzi);

         

         
        if(ponziFriends[_parentId].amountEarned < (ponziFriends[_parentId].amountPlayed * 5) && _parentId < ponziFriends.length) {
             
            ponziFriends[_parentId].playerAddr.transfer(comLevel1);

             
            ponziFriends[_parentId].amountEarned += comLevel1;
            
             
            ponziFriendToLevel1Ref[_parentId]++;
        } else {
             
            devAddress.transfer(comLevel1);
        }
        

         
        uint level2parent = ponziFriends[_parentId].parent;
        if(ponziFriends[level2parent].amountEarned < (ponziFriends[level2parent].amountPlayed *5 )) {
             
            ponziFriends[level2parent].playerAddr.transfer(comLevel2);

             
            ponziFriends[level2parent].amountEarned += comLevel2;
            
             
            ponziFriendToLevel2Ref[level2parent]++;
        } else {
             
            devAddress.transfer(comLevel2);
        }
        

         
        uint level3parent = ponziFriends[level2parent].parent;
        if(ponziFriends[level3parent].amountEarned < (ponziFriends[level3parent].amountPlayed * 5)) {
             
            ponziFriends[level3parent].playerAddr.transfer(comLevel3); 

             
            ponziFriends[level3parent].amountEarned += comLevel3;
            
             
            ponziFriendToLevel3Ref[level3parent]++;
        } else {
             
            devAddress.transfer(comLevel3);
        }

         

         

        if(ponziFriendsToId[msg.sender] > 0) {
             
            ponziFriends[ponziFriendsToId[msg.sender]].amountPlayed += msg.value;
        } else {
             
            uint pzfId = ponziFriends.push(PonziFriend(msg.sender, _parentId, msg.value, 0)) - 1;
            ponziFriendsToId[msg.sender] = pzfId;
        }

         

         
        totalAmountPlayed = totalAmountPlayed + msg.value;
        totalCommissionSent = totalCommissionSent + comLevel1 + comLevel2 + comLevel3;

    }

     
    constructor() public {
         
        uint pzfId = ponziFriends.push(PonziFriend(devAddress, 0, 1000000000000000000000000000, 0)) - 1;
        ponziFriendsToId[msg.sender] = pzfId;
    }

     
    function getPonziFriend(address _addr) public view returns(uint, uint, uint256, uint256, uint, uint, uint) {
        uint pzfId = ponziFriendsToId[_addr];
        if(pzfId == 0) {
            return(0, 0, 0, 0, 0, 0, 0);
        } else {
            return(pzfId, ponziFriends[pzfId].parent, ponziFriends[pzfId].amountPlayed, ponziFriends[pzfId].amountEarned, ponziFriendToLevel1Ref[pzfId], ponziFriendToLevel2Ref[pzfId], ponziFriendToLevel3Ref[pzfId]);
        }
    }

     
    function getStats() public view returns(uint, uint256, uint256) {
        return(ponziFriends.length, totalAmountPlayed, totalCommissionSent);
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    
}