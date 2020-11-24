 

 

pragma solidity ^0.4.2;

contract MillionEther {

    address private admin;

     
    uint private numUsers = 0;
    struct User {
        address referal;
        uint8 handshakes;
        uint balance;
        uint32 activationTime;
        bool banned;
        uint userID;
        bool refunded;
        uint investments;
    }
    mapping(address => User) private users;
    mapping(uint => address) private userAddrs;

     
    uint16 private blocksSold = 0;
    uint private numNewStatus = 0;
    struct Block {
        address landlord;
        uint imageID;
        uint sellPrice;
    }
    Block[101][101] private blocks; 

     
    uint private numImages = 0;
    struct Image {
        uint8 fromX;
        uint8 fromY;
        uint8 toX;
        uint8 toY;
        string imageSourceUrl;
        string adUrl;
        string adText;
    }
    mapping(uint => Image) private images;

     
    uint public charityBalance = 0;
    address public charityAddress;
    uint8 private refund_percent = 0;
    uint private totalWeiInvested = 0;  
    bool private setting_stopped = false;
    bool private setting_refundMode = false;
    uint32 private setting_delay = 3600;
    uint private setting_imagePlacementPriceInWei = 0;

     
    event NewUser(uint ID, address newUser, address invitedBy, uint32 activationTime);
    event NewAreaStatus (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint price);
    event NewImage(uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText);


 

    function MillionEther () {
        admin = msg.sender;
        users[admin].referal = admin;
        users[admin].handshakes = 0;
        users[admin].activationTime = uint32(now);
        users[admin].userID = 0;
        userAddrs[0] = admin;
        userAddrs[numUsers] = admin;
    }


 

    modifier onlyAdmin {
        if (msg.sender != admin) throw;
        _;
    }

    modifier onlyWhenInvitedBy (address someUser) {
        if (users[msg.sender].referal != address(0x0)) throw;    
        if (users[someUser].referal == address(0x0)) throw;      
        if (now < users[someUser].activationTime) throw;         
        _;
    }

    modifier onlySignedIn {
        if (users[msg.sender].referal == address(0x0)) throw;    
        _;
    }

    modifier onlyForSale (uint8 _x, uint8 _y) {
        if (blocks[_x][_y].landlord != address(0x0) && blocks[_x][_y].sellPrice == 0) throw;
        _;
    }

    modifier onlyWithin100x100Area (uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) {
        if ((_fromX < 1) || (_fromY < 1)  || (_toX > 100) || (_toY > 100)) throw;
        _;
    }    

    modifier onlyByLandlord (uint8 _x, uint8 _y) {
        if (msg.sender != admin) {
            if (blocks[_x][_y].landlord != msg.sender) throw;
        }
        _;
    }

    modifier noBannedUsers {
        if (users[msg.sender].banned == true) throw;
        _;
    }

    modifier stopInEmergency { 
        if (msg.sender != admin) {
            if (setting_stopped) throw; 
        }
        _;
    }

    modifier onlyInRefundMode { 
        if (!setting_refundMode) throw;
        _;
    }


 

    function getActivationTime (uint _currentLevel, uint _setting_delay) private constant returns (uint32) {
        return uint32(now + _setting_delay * (2**(_currentLevel-1)));
    }

    function signIn (address referal) 
        public 
        stopInEmergency ()
        onlyWhenInvitedBy (referal) 
        returns (uint) 
    {
        numUsers++;
         
        uint8 currentLevel = users[referal].handshakes + 1;
        users[msg.sender].referal = referal;
        users[msg.sender].handshakes = currentLevel;
         
        users[msg.sender].activationTime = getActivationTime (currentLevel, setting_delay); 
        users[msg.sender].refunded = false;
        users[msg.sender].userID = numUsers;
        userAddrs[numUsers] = msg.sender;
        NewUser(numUsers, msg.sender, referal, users[msg.sender].activationTime);
        return numUsers;
    }


  

    function getBlockPrice (uint8 fromX, uint8 fromY, uint blocksSold) private constant returns (uint) {
        if (blocks[fromX][fromY].landlord == address(0x0)) { 
                 
                return 1 ether * (2 ** (blocksSold/1000));
            } else {
                 
                return blocks[fromX][fromY].sellPrice;
            }
        }

    function buyBlock (uint8 x, uint8 y) 
        private  
        onlyForSale (x, y) 
        returns (uint)
    {
        uint blockPrice;
        blockPrice = getBlockPrice(x, y, blocksSold);
         
        if (blocks[x][y].landlord == address(0x0)) {
            blocksSold += 1;  
            totalWeiInvested += blockPrice;
         
        } else {
            users[blocks[x][y].landlord].balance += blockPrice;  
        }
        blocks[x][y].landlord = msg.sender;
        return blockPrice;
    }

     
    function buyBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        public
        payable
        stopInEmergency ()
        onlySignedIn () 
        onlyWithin100x100Area (fromX, fromY, toX, toY)
        returns (uint) 
    {   
         
        if (users[msg.sender].balance + msg.value < users[msg.sender].balance) throw;  
        uint previousWeiInvested = totalWeiInvested;
        uint buyerBalance = users[msg.sender].balance + msg.value;

         
        uint purchasePrice;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                purchasePrice = buyBlock (ix,iy);
                if (buyerBalance < purchasePrice) throw;
                buyerBalance -= purchasePrice;
            }
        }
         
        users[msg.sender].balance = buyerBalance;
         
        users[msg.sender].investments += totalWeiInvested - previousWeiInvested;
         
        payOut (totalWeiInvested - previousWeiInvested, users[msg.sender].referal);
        numNewStatus += 1;
         
        NewAreaStatus (numNewStatus, fromX, fromY, toX, toY, 0);
        return purchasePrice;
    }


     
    function sellBlock (uint8 x, uint8 y, uint sellPrice) 
        private
        onlyByLandlord (x, y) 
    {
        blocks[x][y].sellPrice = sellPrice;
    }

     
    function sellBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockInWei) 
        public 
        stopInEmergency ()
        onlyWithin100x100Area (fromX, fromY, toX, toY) 
        returns (bool) 
    {
        if (priceForEachBlockInWei == 0) throw;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                sellBlock (ix, iy, priceForEachBlockInWei);
            }
        }
        numNewStatus += 1;
         
        NewAreaStatus (numNewStatus, fromX, fromY, toX, toY, priceForEachBlockInWei);
        return true;
    }


 
    
    function chargeForImagePlacement () private {
        if (users[msg.sender].balance + msg.value < users[msg.sender].balance) throw;  
        uint buyerBalance = users[msg.sender].balance + msg.value;
        if (buyerBalance < setting_imagePlacementPriceInWei) throw;
        buyerBalance -= setting_imagePlacementPriceInWei;
        users[admin].balance += setting_imagePlacementPriceInWei;
        users[msg.sender].balance = buyerBalance;
    }

     
    function assignImageID (uint8 x, uint8 y, uint _imageID) 
        private
        onlyByLandlord (x, y) 
    {
        blocks[x][y].imageID = _imageID;
    }

     
    function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 
        public 
        payable
        stopInEmergency ()
        noBannedUsers ()
        onlyWithin100x100Area (fromX, fromY, toX, toY)
        returns (uint) 
    {
        chargeForImagePlacement();
        numImages++;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                assignImageID (ix, iy, numImages);
            }
        }
        images[numImages].fromX = fromX;
        images[numImages].fromY = fromY;
        images[numImages].toX = toX;
        images[numImages].toY = toY;
        images[numImages].imageSourceUrl = imageSourceUrl;
        images[numImages].adUrl = adUrl;
        images[numImages].adText = adText;
        NewImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText);
        return numImages;
    }





 

     
    function payOut (uint _amount, address referal) private {
        address iUser = referal;
        address nextUser;
        uint totalPayed = 0;
        for (uint8 i = 1; i < 7; i++) {                  
            users[iUser].balance += _amount / (2**i);    
            totalPayed += _amount / (2**i);              
            if (iUser == admin) { break; }               
            nextUser = users[iUser].referal;
            iUser = nextUser;
        }
        goesToCharity(_amount - totalPayed);             
    }

     
    function goesToCharity (uint amount) private {
         
        if (charityAddress == address(0x0)) {
            charityBalance += amount;
        } else {
            users[charityAddress].balance += amount;
        }
    }

     
    function withdrawAll () 
        public
        stopInEmergency () 
    {
        uint withdrawAmount = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        if (!msg.sender.send(withdrawAmount)) {
            users[msg.sender].balance = withdrawAmount;
        }
    }


  

     
    function getUserInfo (address userAddress) public constant returns (
        address referal,
        uint8 handshakes,
        uint balance,
        uint32 activationTime,
        bool banned,
        uint userID,
        bool refunded,
        uint investments
    ) {
        referal = users[userAddress].referal; 
        handshakes = users[userAddress].handshakes; 
        balance = users[userAddress].balance; 
        activationTime = users[userAddress].activationTime; 
        banned = users[userAddress].banned; 
        userID = users[userAddress].userID;
        refunded = users[userAddress].refunded; 
        investments = users[userAddress].investments;
    }

    function getUserAddressByID (uint userID) 
        public constant returns (address userAddress) 
    {
        return userAddrs[userID];
    }
    
    function getMyInfo() 
        public constant returns(uint balance, uint32 activationTime) 
    {   
        return (users[msg.sender].balance, users[msg.sender].activationTime);
    }

     
    function getBlockInfo(uint8 x, uint8 y) 
        public constant returns (address landlord, uint imageID, uint sellPrice) 
    {
        return (blocks[x][y].landlord, blocks[x][y].imageID, blocks[x][y].sellPrice);
    }

    function getAreaPrice (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY)
        public
        constant
        onlyWithin100x100Area (fromX, fromY, toX, toY)
        returns (uint) 
    {
        uint blockPrice;
        uint totalPrice = 0;
        uint16 iblocksSold = blocksSold;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                blockPrice = getBlockPrice(ix,iy,iblocksSold);
                if (blocks[ix][iy].landlord == address(0x0)) { 
                        iblocksSold += 1; 
                    }
                if (blockPrice == 0) { 
                    return 0;  
                    } 
                totalPrice += blockPrice;
            }
        }
        return totalPrice;
    }

     
    function getImageInfo(uint imageID) 
        public constant returns (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText)
    {
        Image i = images[imageID];
        return (i.fromX, i.fromY, i.toX, i.toY, i.imageSourceUrl, i.adUrl, i.adText);
    }

     
    function getStateInfo () public constant returns (
        uint _numUsers, 
        uint16 _blocksSold, 
        uint _totalWeiInvested, 
        uint _numImages, 
        uint _setting_imagePlacementPriceInWei,
        uint _numNewStatus,
        uint32 _setting_delay
    ){
        return (numUsers, blocksSold, totalWeiInvested, numImages, setting_imagePlacementPriceInWei, numNewStatus, setting_delay);
    }


 

    function adminContractSecurity (address violator, bool banViolator, bool pauseContract, bool refundInvestments)
        public 
        onlyAdmin () 
    {
         
        if (violator != address(0x0)) {
            users[violator].banned = banViolator;
        }
         
        setting_stopped = pauseContract;

         
        if (refundInvestments) {
            setting_refundMode = refundInvestments;
            refund_percent = uint8((this.balance*100)/totalWeiInvested);
        }
    }

    function adminContractSettings (uint32 newDelayInSeconds, address newCharityAddress, uint newImagePlacementPriceInWei)
        public 
        onlyAdmin () 
    {   
         
        if (newDelayInSeconds > 0) setting_delay = newDelayInSeconds;
         
        if (newCharityAddress != address(0x0)) {
            if (users[newCharityAddress].referal == address(0x0)) throw;
            charityAddress = newCharityAddress;
            users[charityAddress].balance += charityBalance;
            charityBalance = 0;
        }
         
        setting_imagePlacementPriceInWei = newImagePlacementPriceInWei;
    }

     
    function emergencyRefund () 
        public
        onlyInRefundMode () 
    {
        if (!users[msg.sender].refunded) {
            uint totalInvested = users[msg.sender].investments;
            uint availableForRefund = (totalInvested*refund_percent)/100;
            users[msg.sender].investments -= availableForRefund;
            users[msg.sender].refunded = true;
            if (!msg.sender.send(availableForRefund)) {
                users[msg.sender].investments = totalInvested;
                users[msg.sender].refunded = false;
            }
        }
    }

    function () {
        throw;
    }

}