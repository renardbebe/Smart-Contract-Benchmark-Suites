 

pragma solidity ^0.4.18;

contract EMPresale {
    
    bool inMaintainance;
    bool isRefundable;
    
     
    
    struct Player {
        uint32 id;   
        mapping(uint8 => uint8) bought;
        uint256 weiSpent;
        bool hasSpent;
    }
    
    struct Sale {
        uint8 bought;
        uint8 maxBought;
        uint32 cardTypeID;
        uint256 price;
        uint256 saleEndTime;
        
        bool isAirdrop;      
                             
                             
        uint256 nextMintTime;
        uint8 leftToMint;
    }
    
    address admin;
    address[] approverArr;  
    mapping(address => bool) approvers;
    
    address[] playerAddrs;       
    uint32[] playerRefCounts;    
    
    mapping(address => Player) players;
    mapping(uint8 => Sale) sales;    
    uint256 refPrize;
    
     
    
    function EMPresale() public {
        admin = msg.sender;
        approverArr.push(admin);
        approvers[admin] = true;
        
        playerAddrs.push(address(0));
        playerRefCounts.push(0);
    }
    
     
    
    function setSaleType_Presale(uint8 saleID, uint8 maxBought, uint32 cardTypeID, uint256 price, uint256 saleEndTime) external onlyAdmin {
        Sale storage sale = sales[saleID];
        
         
        sale.bought = 0;
        sale.maxBought = maxBought;
        sale.cardTypeID = cardTypeID;
        sale.price = price;
        sale.saleEndTime = saleEndTime;
        
         
        sale.isAirdrop = false;
    }
    
    function setSaleType_Airdrop(uint8 saleID, uint8 maxBought, uint32 cardTypeID, uint8 leftToMint, uint256 firstMintTime) external onlyAdmin {
        Sale storage sale = sales[saleID];
        
         
        sale.bought = 0;
        sale.maxBought = maxBought;
        sale.cardTypeID = cardTypeID;
        sale.price = 0;
        sale.saleEndTime = 2000000000;
        
         
        require(leftToMint >= maxBought);
        sale.isAirdrop = true;
        sale.nextMintTime = firstMintTime;
        sale.leftToMint = leftToMint - maxBought;
    }
    
    function stopSaleType(uint8 saleID) external onlyAdmin {
        delete sales[saleID].saleEndTime;
    }
    
    function redeemCards(address playerAddr, uint8 saleID) external onlyApprover returns(uint8) {
        Player storage player = players[playerAddr];
        uint8 owned = player.bought[saleID];
        player.bought[saleID] = 0;
        return owned;
    }
    
    function setRefundable(bool refundable) external onlyAdmin {
        isRefundable = refundable;
    }
    
    function refund() external {
        require(isRefundable);
        Player storage player = players[msg.sender];
        uint256 spent = player.weiSpent;
        player.weiSpent = 0;
        msg.sender.transfer(spent);
    }
    
     
    
    function buySaleNonReferral(uint8 saleID) external payable {
        buySale(saleID, address(0));
    }
    
    function buySaleReferred(uint8 saleID, address referral) external payable {
        buySale(saleID, referral);
    }
    
    function buySale(uint8 saleID, address referral) private {
        
        require(!inMaintainance);
        require(msg.sender != address(0));
        
         
        Sale storage sale = sales[saleID];
        require(sale.saleEndTime > now);
        
        bool isAirdrop = sale.isAirdrop;
        if(isAirdrop) {
             
            if(now >= sale.nextMintTime) {   
            
                sale.nextMintTime += ((now-sale.nextMintTime)/3600)*3600+3600;    
                if(sale.bought != 0) {
                    uint8 leftToMint = sale.leftToMint;
                    if(leftToMint < sale.bought) {  
                        sale.maxBought = sale.maxBought + leftToMint - sale.bought;
                        sale.leftToMint = 0;
                    } else
                        sale.leftToMint -= sale.bought;
                    sale.bought = 0;
                }
            }
        } else {
             
            require(msg.value >= sale.price);
        }

         
        require(sale.bought < sale.maxBought);
        sale.bought++;
        
        bool toRegisterPlayer = false;
        bool toRegisterReferral = false;
        
         
        Player storage player = players[msg.sender];
        if(player.id == 0)
            toRegisterPlayer = true;
            
         
        if(isAirdrop)
            require(player.bought[saleID] == 0);
        
         
        player.bought[saleID]++;
        if(!isAirdrop)   
            player.weiSpent += msg.value;
        
         
        if(!player.hasSpent) {
            player.hasSpent = true;
            if(referral != address(0) && referral != msg.sender) {
                Player storage referredPlayer = players[referral];
                if(referredPlayer.id == 0) {     
                    toRegisterReferral = true;
                } else {                         
                    playerRefCounts[referredPlayer.id]++;
                }
            }
        }
        
         
        if(toRegisterPlayer && toRegisterReferral) {
            uint256 length = (uint32)(playerAddrs.length);
            player.id = (uint32)(length);
            referredPlayer.id = (uint32)(length+1);
            playerAddrs.length = length+2;
            playerRefCounts.length = length+2;
            playerAddrs[length] = msg.sender;
            playerAddrs[length+1] = referral;
            playerRefCounts[length+1] = 1;
            
        } else if(toRegisterPlayer) {
            player.id = (uint32)(playerAddrs.length);
            playerAddrs.push(msg.sender);
            playerRefCounts.push(0);
            
        } else if(toRegisterReferral) {
            referredPlayer.id = (uint32)(playerAddrs.length);
            playerAddrs.push(referral);
            playerRefCounts.push(1);
        }
        
         
        refPrize += msg.value/40;     
    }
    
    function GetSaleInfo_Presale(uint8 saleID) external view returns (uint8, uint8, uint8, uint32, uint256, uint256) {
        uint8 playerOwned = 0;
        if(msg.sender != address(0))
            playerOwned = players[msg.sender].bought[saleID];
        
        Sale storage sale = sales[saleID];
        return (playerOwned, sale.bought, sale.maxBought, sale.cardTypeID, sale.price, sale.saleEndTime);
    }
    
    function GetSaleInfo_Airdrop(uint8 saleID) external view returns (uint8, uint8, uint8, uint32, uint256, uint8) {
        uint8 playerOwned = 0;
        if(msg.sender != address(0))
            playerOwned = players[msg.sender].bought[saleID];
        
        Sale storage sale = sales[saleID];
        uint8 bought = sale.bought;
        uint8 maxBought = sale.maxBought;
        uint256 nextMintTime = sale.nextMintTime;
        uint8 leftToMintResult = sale.leftToMint;
    
         
        if(now >= nextMintTime) {   
            nextMintTime += ((now-nextMintTime)/3600)*3600+3600;    
            if(bought != 0) {
                uint8 leftToMint = leftToMintResult;
                if(leftToMint < bought) {  
                    maxBought = maxBought + leftToMint - bought;
                    leftToMintResult = 0;
                } else
                    leftToMintResult -= bought;
                bought = 0;
            }
        }
        
        return (playerOwned, bought, maxBought, sale.cardTypeID, nextMintTime, leftToMintResult);
    }
    
    function GetReferralInfo() external view returns(uint256, uint32) {
        uint32 refCount = 0;
        uint32 id = players[msg.sender].id;
        if(id != 0)
            refCount = playerRefCounts[id];
        return (refPrize, refCount);
    }
    
    function GetPlayer_FromAddr(address playerAddr, uint8 saleID) external view returns(uint32, uint8, uint256, bool, uint32) {
        Player storage player = players[playerAddr];
        return (player.id, player.bought[saleID], player.weiSpent, player.hasSpent, playerRefCounts[player.id]);
    }
    
    function GetPlayer_FromID(uint32 id, uint8 saleID) external view returns(address, uint8, uint256, bool, uint32) {
        address playerAddr = playerAddrs[id];
        Player storage player = players[playerAddr];
        return (playerAddr, player.bought[saleID], player.weiSpent, player.hasSpent, playerRefCounts[id]);
    }
    
    function getAddressesCount() external view returns(uint) {
        return playerAddrs.length;
    }
    
    function getAddresses() external view returns(address[]) {
        return playerAddrs;
    }
    
    function getAddress(uint256 id) external view returns(address) {
        return playerAddrs[id];
    }
    
    function getReferralCounts() external view returns(uint32[]) {
        return playerRefCounts;
    }
    
    function getReferralCount(uint256 playerID) external view returns(uint32) {
        return playerRefCounts[playerID];
    }
    
    function GetNow() external view returns (uint256) {
        return now;
    }

     
    
    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function depositEtherBalance() external payable {
    }
    
    function withdrawEtherBalance(uint256 amt) external onlyAdmin {
        admin.transfer(amt);
    }
    
     
    
    function setMaintainance(bool maintaining) external onlyAdmin {
        inMaintainance = maintaining;
    }
    
    function isInMaintainance() external view returns(bool) {
        return inMaintainance;
    }
    
    function getApprovers() external view returns(address[]) {
        return approverArr;
    }
    
     
     
    function switchAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

     
     
    function addApprover(address newApprover) external onlyAdmin {
        require(!approvers[newApprover]);
        approvers[newApprover] = true;
        approverArr.push(newApprover);
    }

     
     
    function removeApprover(address oldApprover) external onlyAdmin {
        require(approvers[oldApprover]);
        delete approvers[oldApprover];
        
         
        uint256 length = approverArr.length;
        address swapAddr = approverArr[length - 1];
        for(uint8 i=0; i<length; i++) {
            if(approverArr[i] == oldApprover) {
                approverArr[i] = swapAddr;
                break;
            }
        }
        approverArr.length--;
    }
    
     
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier onlyApprover() {
        require(approvers[msg.sender]);
        _;
    }
}