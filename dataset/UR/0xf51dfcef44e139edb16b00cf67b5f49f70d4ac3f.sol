 

pragma solidity ^0.4.18;

 

contract MyCryptoBuilding {

    address ownerAddress = 0x9aFbaA3003D9e75C35FdE2D1fd283b13d3335f00;
    
    modifier onlyOwner() {
        require (msg.sender == ownerAddress);
        _;
    }

    address buildingOwnerAddress;
    uint256 buildingPrice;
    
    struct Appartement {
        address ownerAddress;
        uint256 curPrice;
    }
    Appartement[] appartments;

     
    function purchaseBuilding() public payable {
        require(msg.value == buildingPrice);

         
        uint256 commission2percent = ((msg.value / 100)*2);
        uint256 commission5percent = ((msg.value / 10)/2);

         
        uint256 commissionOwner = msg.value - (commission5percent * 3);  
        buildingOwnerAddress.transfer(commissionOwner);

         
        for (uint8 i = 0; i < 5; i++) {
            appartments[i].ownerAddress.transfer(commission2percent);
        }

         
        ownerAddress.transfer(commission5percent);  

         
        buildingOwnerAddress = msg.sender;
        buildingPrice = buildingPrice + (buildingPrice / 2);
    }

     
    function purchaseAppartment(uint _appartmentId) public payable {
        require(msg.value == appartments[_appartmentId].curPrice);

         
        uint256 commission10percent = (msg.value / 10);
        uint256 commission5percent = ((msg.value / 10)/2);

         
        uint256 commissionOwner = msg.value - (commission5percent + commission10percent);  
        appartments[_appartmentId].ownerAddress.transfer(commissionOwner);

         
        buildingOwnerAddress.transfer(commission10percent);

         
        ownerAddress.transfer(commission5percent);  

         
        appartments[_appartmentId].ownerAddress = msg.sender;
        appartments[_appartmentId].curPrice = appartments[_appartmentId].curPrice + (appartments[_appartmentId].curPrice / 2);
    }
    
    
     
    function getAppartment(uint _appartmentId) public view returns (
        address ownerAddress,
        uint256 curPrice
    ) {
        Appartement storage _appartment = appartments[_appartmentId];

        ownerAddress = _appartment.ownerAddress;
        curPrice = _appartment.curPrice;
    }
    function getBuilding() public view returns (
        address ownerAddress,
        uint256 curPrice
    ) {
        ownerAddress = buildingOwnerAddress;
        curPrice = buildingPrice;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function InitiateGame() public onlyOwner {
        buildingOwnerAddress = ownerAddress;
        buildingPrice = 225000000000000000;
        appartments.push(Appartement(ownerAddress, 75000000000000000));
        appartments.push(Appartement(ownerAddress, 75000000000000000));
        appartments.push(Appartement(ownerAddress, 75000000000000000));
        appartments.push(Appartement(ownerAddress, 75000000000000000));
        appartments.push(Appartement(ownerAddress, 75000000000000000));

    }
}