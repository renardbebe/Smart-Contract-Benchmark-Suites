 

pragma solidity ^0.4.24;

contract SimpleBanners {

    struct BannerOwnerStruct {
        address owner;
        uint balance;
        uint bidAmountPerDay;
        bytes32 dataCID;
        uint timestampTaken;
    }

    address owner;
    BannerOwnerStruct[2] banners;

    constructor() public {
        owner = msg.sender;
    }

    event BannerUpdate();

    function takeBanner(uint bannerId, uint bidAmountPerDay, bytes32 dataCID) public payable {

        if (msg.value == 0)
            revert("Requires some ETH");

        if (bidAmountPerDay < 10000000000000 wei)  
            revert("bid amount is below minimum");

         
        uint totalCost = calculateTotalCost(bannerId);
        uint totalValueRemaining = banners[bannerId].balance - totalCost;

         
        if (msg.value <= totalValueRemaining) {
             
            if (bidAmountPerDay < banners[bannerId].bidAmountPerDay * 2)
                revert("amount needs to be double existing bid");
            
            if (msg.value < bidAmountPerDay * 7)
                revert("requires at least 7 days to replace existing bid");
        }            

         
        owner.transfer(totalCost);
        banners[bannerId].owner.transfer(totalValueRemaining);

        banners[bannerId].owner = msg.sender;
        banners[bannerId].balance = msg.value;
        banners[bannerId].bidAmountPerDay = bidAmountPerDay;
        banners[bannerId].dataCID = dataCID;
        banners[bannerId].timestampTaken = block.timestamp;

        emit BannerUpdate();
    }

    function updateBannerContent(uint bannerId, bytes32 dataCID) public {
        if (banners[bannerId].owner != msg.sender)
            revert("Not owner");

        banners[bannerId].dataCID = dataCID;
        emit BannerUpdate();
    }

    function addFunds(uint bannerId) public payable{
        if (banners[bannerId].owner != msg.sender)
            revert("Not owner");

        uint totalCost = calculateTotalCost(bannerId);
        if (totalCost >= banners[bannerId].balance) {
             
            owner.transfer(banners[bannerId].balance);
            banners[bannerId].timestampTaken = block.timestamp;
            banners[bannerId].balance = msg.value;
            emit BannerUpdate();
        } else {
            banners[bannerId].balance += msg.value;
        }        
    }

     
    function getBannerDetails(uint bannerId) public view returns (address, uint, uint, bytes32, uint) {
        return (
            banners[bannerId].owner,
            banners[bannerId].balance,
            banners[bannerId].bidAmountPerDay,
            banners[bannerId].dataCID,
            banners[bannerId].timestampTaken
        );
    }

    function getRemainingBalance(uint bannerId) public view returns (uint remainingBalance) {
        uint totalCost = calculateTotalCost(bannerId);
        return banners[bannerId].balance - totalCost;
    }

    function calculateTotalCost(uint bannerId) internal view returns (uint) {
         
        uint totalSecondsPassed = block.timestamp - banners[bannerId].timestampTaken;
        uint totalCost = totalSecondsPassed * (banners[bannerId].bidAmountPerDay / 1 days);

         
        if (totalCost > banners[bannerId].balance)
            totalCost = banners[bannerId].balance;

        return totalCost;
    }

    function getActiveBanners() public view returns (bytes32, bytes32) {
        bytes32 b1;
        bytes32 b2;

        uint tCost = calculateTotalCost(0);
        if (tCost >= banners[0].balance)
            b1 = 0x00;
        else
            b1 = banners[0].dataCID;

        tCost = calculateTotalCost(1);
        if (tCost >= banners[1].balance)
            b2 = 0x00;
        else
            b2 = banners[1].dataCID;

        return (b1, b2);
    }

     
    function updateOwner(address newOwner) public {
        if (msg.sender != owner)
            revert("Not the owner");

        owner = newOwner;
    }

    function emergencyWithdraw() public {
        if (msg.sender != owner)
            revert("Not the owner");

        owner.transfer(address(this).balance);
    }

    function rejectBanner(uint bannerId) public {
        if (msg.sender != owner)
            revert("Not the owner");

         
        uint totalCost = calculateTotalCost(bannerId);
        owner.transfer(totalCost);
        banners[bannerId].owner.transfer(banners[bannerId].balance - totalCost);

        delete banners[bannerId];

        emit BannerUpdate();
    }
}