 

pragma solidity ^0.4.19;

	 
	 
	 
	 
	
contract CryptoSurprise
{
    using SetLibrary for SetLibrary.Set;
    
     
     
    
    uint256 constant public BAG_TRANSFER_FEE = 0.05 ether;
    uint256 constant public BAG_TRANSFER_MINIMUM_AMOUNT_OF_BUYS = 4;
    
    
     
     
    
    struct BagType
    {
         
        string name;
        
        uint256 startPrice;
        uint256 priceMultiplierPerBuy;  
        
        uint256 startCommission;  
        uint256 commissionIncrementPerBuy;
        uint256 maximumCommission;
        
        uint256 supplyHardCap;
        
         
        uint256 currentSupply;
    }
    
    struct Bag
    {
         
        uint256 bagTypeIndex;
        
         
        uint256 amountOfBuys;
        address owner;
        uint256 commission;  
        uint256 price;
        
        uint256 availableTimestamp;
    }
    
     
    address public owner;
    BagType[] public bagTypes;
    Bag[] public bags;
    
    mapping(address => uint256) public addressToTotalEtherSpent;
    mapping(address => uint256) public addressToTotalPurchasesMade;
    mapping(address => SetLibrary.Set) private ownerToBagIndices;
    address[] public allParticipants;
    
    
     
     
    
    function buyBag(uint256 _bagIndex) external payable
    {
         
        require(_bagIndex < bags.length);
        
         
        Bag storage bag = bags[_bagIndex];
        BagType storage bagType = bagTypes[bag.bagTypeIndex];
        
         
        require(now >= bag.availableTimestamp);
        
         
        require(msg.value >= bag.price);
        uint256 refund = msg.value - bag.price;
        
         
        address previousOwner = bag.owner;
        
         
        bag.owner = msg.sender;
        
         
        uint256 previousPrice = bag.price * 1000000 / bagType.priceMultiplierPerBuy;
        uint256 nextPrice = bag.price * bagType.priceMultiplierPerBuy / 1000000;
        
         
        uint256 previousOwnerReward;
        
         
        if (bag.amountOfBuys == 0)
        {
            previousOwnerReward = bag.price;
        }
        
         
        else
        {
            previousOwnerReward = bag.price * bag.commission / 1000000;
             
        }
        
         
        bag.price = nextPrice;
        
         
        bag.amountOfBuys++;
        
         
        if (bag.amountOfBuys > 1)
        {
             
            if (bag.commission < bagType.maximumCommission)
            {
                uint256 newCommission = bag.commission + bagType.commissionIncrementPerBuy;
                
                if (newCommission >= bagType.maximumCommission)
                {
                    bag.commission = bagType.maximumCommission;
                }
                else 
                {
                    bag.commission = newCommission;
                }
            }
        }
        
         
        if (addressToTotalPurchasesMade[msg.sender] == 0)
        {
            allParticipants.push(msg.sender);
        }
        addressToTotalEtherSpent[msg.sender] += msg.value;
        addressToTotalPurchasesMade[msg.sender]++;
        
         
         
         
        if (previousOwner != address(this))
        {
            previousOwner.transfer(previousOwnerReward);
        }
        
        if (refund > 0)
        {
            msg.sender.transfer(refund);
        }
    }
    
    function transferBag(address _newOwner, uint256 _bagIndex) public payable
    {
         
        require(msg.value == BAG_TRANSFER_FEE);
        
         
        _transferBag(msg.sender, _newOwner, _bagIndex);
    }
    
    
     
     
    
     
    function CryptoSurprise() public
    {
        owner = msg.sender;
        
        bagTypes.push(BagType({
            name: "Blue",
            
            startPrice: 0.04 ether,
            priceMultiplierPerBuy: 1300000,  
            
            startCommission: 850000,  
            commissionIncrementPerBuy: 5000,  
            maximumCommission: 900000,  
            
            supplyHardCap: 600,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Red",
            
            startPrice: 0.03 ether,
            priceMultiplierPerBuy: 1330000,  
            
            startCommission: 870000,  
            commissionIncrementPerBuy: 5000,  
            maximumCommission: 920000,  
            
            supplyHardCap: 300,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Green",
            
            startPrice: 0.02 ether,
            priceMultiplierPerBuy: 1360000,  
            
            startCommission: 890000,  
            commissionIncrementPerBuy: 5000,  
            maximumCommission: 940000,  
            
            supplyHardCap: 150,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Black",
            
            startPrice: 0.1 ether,
            priceMultiplierPerBuy: 1450000,  
            
            startCommission: 920000,  
            commissionIncrementPerBuy: 10000,  
            maximumCommission: 960000,  
            
            supplyHardCap: 50,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Pink",
            
            startPrice: 1 ether,
            priceMultiplierPerBuy: 1500000,  
            
            startCommission: 940000,  
            commissionIncrementPerBuy: 10000,  
            maximumCommission: 980000,  
            
            supplyHardCap: 10,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "White",
            
            startPrice: 10 ether,
            priceMultiplierPerBuy: 1500000,  
            
            startCommission: 970000,  
            commissionIncrementPerBuy: 10000,  
            maximumCommission: 990000,  
            
            supplyHardCap: 1,
            
            currentSupply: 0
        }));
    }
    
     
    function transferOwnership(address _newOwner) external
    {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    
     
    function () payable external
    {
        require(msg.sender == owner);
    }
    
     
     
    function withdrawEther(uint256 amount) external
    {
        require(msg.sender == owner);
        owner.transfer(amount);
    }
    
    function addBag(uint256 _bagTypeIndex) external
    {
        addBagAndGift(_bagTypeIndex, address(this));
    }
    function addBagDelayed(uint256 _bagTypeIndex, uint256 _delaySeconds) external
    {
        addBagAndGiftAtTime(_bagTypeIndex, address(this), now + _delaySeconds);
    }
    
    function addBagAndGift(uint256 _bagTypeIndex, address _firstOwner) public
    {
        addBagAndGiftAtTime(_bagTypeIndex, _firstOwner, now);
    }
    function addBagAndGiftAtTime(uint256 _bagTypeIndex, address _firstOwner, uint256 _timestamp) public
    {
        require(msg.sender == owner);
        
        require(_bagTypeIndex < bagTypes.length);
        
        BagType storage bagType = bagTypes[_bagTypeIndex];
        
        require(bagType.currentSupply < bagType.supplyHardCap);
        
        bags.push(Bag({
            bagTypeIndex: _bagTypeIndex,
            
            amountOfBuys: 0,
            owner: _firstOwner,
            commission: bagType.startCommission,
            price: bagType.startPrice,
            
            availableTimestamp: _timestamp
        }));
        
        bagType.currentSupply++;
    }
    

    
     
     
    
    function _transferBag(address _from, address _to, uint256 _bagIndex) internal
    {
         
        require(_bagIndex < bags.length);
        
         
        require(bags[_bagIndex].amountOfBuys >= BAG_TRANSFER_MINIMUM_AMOUNT_OF_BUYS);
        
         
        require(bags[_bagIndex].owner == _from);
        
         
        bags[_bagIndex].owner = _to;
        ownerToBagIndices[_from].remove(_bagIndex);
        ownerToBagIndices[_to].add(_bagIndex);
        
         
        Transfer(_from, _to, _bagIndex);
    }
    
    
     
     
    
    function amountOfBags() external view returns (uint256)
    {
        return bags.length;
    }
    function amountOfBagTypes() external view returns (uint256)
    {
        return bagTypes.length;
    }
    function amountOfParticipants() external view returns (uint256)
    {
        return allParticipants.length;
    }
    
    
     
     
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    
    function name() external pure returns (string)
    {
        return "Bags";
    }
    
    function symbol() external pure returns (string)
    {
        return "BAG";
    }
    
    function totalSupply() external view returns (uint256)
    {
        return bags.length;
    }
    
    function balanceOf(address _owner) external view returns (uint256)
    {
        return ownerToBagIndices[_owner].size();
    }
    
    function ownerOf(uint256 _bagIndex) external view returns (address)
    {
        require(_bagIndex < bags.length);
        
        return bags[_bagIndex].owner;
    }
    mapping(address => mapping(address => mapping(uint256 => bool))) private ownerToAddressToBagIndexAllowed;
    function approve(address _to, uint256 _bagIndex) external
    {
        require(_bagIndex < bags.length);
        
        require(msg.sender == bags[_bagIndex].owner);
        
        ownerToAddressToBagIndexAllowed[msg.sender][_to][_bagIndex] = true;
    }
    
    function takeOwnership(uint256 _bagIndex) external
    {
        require(_bagIndex < bags.length);
        
        address previousOwner = bags[_bagIndex].owner;
        
        require(ownerToAddressToBagIndexAllowed[previousOwner][msg.sender][_bagIndex] == true);
        
        ownerToAddressToBagIndexAllowed[previousOwner][msg.sender][_bagIndex] = false;
        
        _transferBag(previousOwner, msg.sender, _bagIndex);
    }
    
    function transfer(address _to, uint256 _bagIndex) external
    {
        transferBag(_to, _bagIndex);
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)
    {
        require(_index < ownerToBagIndices[_owner].size());
        
        return ownerToBagIndices[_owner].values[_index];
    }
}
 
library SetLibrary
{
    struct ArrayIndexAndExistsFlag
    {
        uint256 index;
        bool exists;
    }
    struct Set
    {
        mapping(uint256 => ArrayIndexAndExistsFlag) valuesMapping;
        uint256[] values;
    }
    function add(Set storage self, uint256 value) public returns (bool added)
    {
         
        if (self.valuesMapping[value].exists == true) return false;
        
         
        self.valuesMapping[value] = ArrayIndexAndExistsFlag({index: self.values.length, exists: true});
        
         
        self.values.push(value);
        
        return true;
    }
    function contains(Set storage self, uint256 value) public view returns (bool contained)
    {
        return self.valuesMapping[value].exists;
    }
    function remove(Set storage self, uint256 value) public returns (bool removed)
    {
         
        if (self.valuesMapping[value].exists == false) return false;
        
         
        self.valuesMapping[value].exists = false;
        
         
         
         
        if (self.valuesMapping[value].index < self.values.length-1)
        {
            uint256 valueToMove = self.values[self.values.length-1];
            uint256 indexToMoveItTo = self.valuesMapping[value].index;
            self.values[indexToMoveItTo] = valueToMove;
            self.valuesMapping[valueToMove].index = indexToMoveItTo;
        }
        
         
         
         
         
         
        
         
         
        self.values.length--;
        
         
         
        delete self.valuesMapping[value];
        
        return true;
    }
    function size(Set storage self) public view returns (uint256 amountOfValues)
    {
        return self.values.length;
    }
    
     
    function add(Set storage self, address value) public returns (bool added) { return add(self, uint256(value)); }
    function add(Set storage self, bytes32 value) public returns (bool added) { return add(self, uint256(value)); }
    function contains(Set storage self, address value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function contains(Set storage self, bytes32 value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function remove(Set storage self, address value) public returns (bool removed) { return remove(self, uint256(value)); }
    function remove(Set storage self, bytes32 value) public returns (bool removed) { return remove(self, uint256(value)); }
}