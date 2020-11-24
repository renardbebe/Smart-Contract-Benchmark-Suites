 

pragma solidity ^0.4.18;

contract ETHMap {

     
     
    uint initialZonePrice = 1000000000000000 wei;

     
    address contractOwner;

     
    mapping(address => uint) pendingWithdrawals;

     
    mapping(uint => Zone) zoneStructs;
    uint[] zoneList;

    struct Zone {
        uint id;
        address owner;
        uint sellPrice;
    }

     
    function ETHMap() public {
      contractOwner = msg.sender;
    }

    modifier onlyContractOwner()
    {
        
        require(msg.sender == contractOwner);
        _;
    }

    modifier onlyValidZone(uint zoneId)
    {
        
        require(zoneId >= 1 && zoneId <= 178);
        _;
    }

    modifier onlyZoneOwner(uint zoneId)
    {
        
        require(msg.sender == zoneStructs[zoneId].owner);
        _;
    }

    function buyZone(uint zoneId) public
      onlyValidZone(zoneId)
      payable
    returns (bool success)
    {
         
        if (zoneStructs[zoneId].owner != address(0)) {
          require(zoneStructs[zoneId].sellPrice != 0);
        }
         
        uint minPrice = (zoneStructs[zoneId].owner == address(0)) ? computeInitialPrice(zoneId) : zoneStructs[zoneId].sellPrice;
        require(msg.value >= minPrice);
         
        if (zoneStructs[zoneId].owner == address(0)) {
             
            pendingWithdrawals[contractOwner] += msg.value;
             
            zoneStructs[zoneId].id = zoneId;
        } else {
           
          uint256 contractOwnerCut = (msg.value * 200) / 10000;
          uint256 ownersShare = msg.value - contractOwnerCut;
           
          pendingWithdrawals[contractOwner] += contractOwnerCut;
           
          address ownerAddress = zoneStructs[zoneId].owner;
          pendingWithdrawals[ownerAddress] += ownersShare;
        }

        zoneStructs[zoneId].owner = msg.sender;
        zoneStructs[zoneId].sellPrice = 0;
        return true;
    }

     
    function sellZone(uint zoneId, uint amount) public
        onlyValidZone(zoneId)
        onlyZoneOwner(zoneId)
        returns (bool success) 
    {
        zoneStructs[zoneId].sellPrice = amount;
        return true;
    }

     
    function transferZone(uint zoneId, address recipient) public
        onlyValidZone(zoneId)
        onlyZoneOwner(zoneId)
        returns (bool success) 
    {
        zoneStructs[zoneId].owner = recipient;
        return true;
    }

     
    function computeInitialPrice(uint zoneId) public view
        onlyValidZone(zoneId)
        returns (uint price)
    {
        return initialZonePrice + ((zoneId - 1) * (initialZonePrice / 2));
    }

     
    function getZone(uint zoneId) public constant
        onlyValidZone(zoneId)
        returns(uint id, address owner, uint sellPrice)
    {
        return (
          zoneStructs[zoneId].id,
          zoneStructs[zoneId].owner,
          zoneStructs[zoneId].sellPrice
        );
    }

     
    function getBalance() public view
      returns (uint amount)
    {
        return pendingWithdrawals[msg.sender];
    }

     
    function withdraw() public
        returns (bool success) 
    {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
        return true;
    }

     
    function transferContractOwnership(address newOwner) public
        onlyContractOwner()
        returns (bool success) 
    {
        contractOwner = newOwner;
        return true;
    }

}