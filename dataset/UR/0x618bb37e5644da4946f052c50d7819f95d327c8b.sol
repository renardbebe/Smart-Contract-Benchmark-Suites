 

pragma solidity ^0.4.18;

 

contract BLAccess {

    address public mainAddress;  
    event UpdatedMainAccount(address _newMainAddress);

    function BLAccess() public {
        mainAddress = msg.sender;
    }

    modifier onlyPrimary() {
        require(msg.sender == mainAddress);
        _;
    }

     
    function setPrimaryAccount(address _newMainAddress) external onlyPrimary {
        require(_newMainAddress != address(0));
        mainAddress = _newMainAddress;
        UpdatedMainAccount(_newMainAddress);
    }

}

 

contract DataStorageInterface {
    function getUInt(bytes32 record) public constant returns (uint);
    function setUInt(bytes32 record, uint value) public;
    function getAdd(bytes32 record) public constant returns (address);
    function setAdd(bytes32 record, address value) public;
    function getBytes32(bytes32 record) public constant returns (bytes32);
    function setBytes32(bytes32 record, bytes32 value) public;
    function getBool(bytes32 record) public constant returns (bool);
    function setBool(bytes32 record, bool value) public;
    function withdraw(address beneficiary) public;
}

 

contract BLStorage is BLAccess {

    DataStorageInterface internal s;
    address public storageAddress;

    event StorageUpdated(address _newStorageAddress);

    function BLStorage() public {
        s = DataStorageInterface(mainAddress);
    }

     
    function setDataStorage(address newAddress) public onlyPrimary {
        s = DataStorageInterface(newAddress);
        storageAddress = newAddress;
        StorageUpdated(newAddress);
    }

    function getKey(uint x, uint y) internal pure returns(bytes32 key) {
        key = keccak256(x, ":", y);
    }
}


contract BLBalances is BLStorage {

    event WithdrawBalance(address indexed owner, uint amount);
    event AllowanceGranted(address indexed owner, uint _amount);
    event SentFeeToPlatform(uint amount);
    event SentAmountToOwner(uint amount, address indexed owner);

     
    function getBalance() public view returns (uint) {
        return s.getUInt(keccak256(msg.sender, "balance"));
    }

     
    function getAccountBalance(address _account) public view onlyPrimary returns (uint) {
        return s.getUInt(keccak256(_account, "balance"));
    }

    function getAccountAllowance(address _account) public view onlyPrimary returns (uint) {
        return s.getUInt(keccak256(_account, "promoAllowance"));
    }

    function getMyAllowance() public view returns (uint) {
        return s.getUInt(keccak256(msg.sender, "promoAllowance"));
    }

     
    function grantAllowance(address beneficiary, uint allowance) public onlyPrimary {
        uint existingAllowance = s.getUInt(keccak256(beneficiary, "promoAllowance"));
        existingAllowance += allowance;
        s.setUInt(keccak256(beneficiary, "promoAllowance"), existingAllowance);
        AllowanceGranted(beneficiary, allowance);
    }

     
    function withdraw() public {
        uint balance = s.getUInt(keccak256(msg.sender, "balance"));
        s.withdraw(msg.sender);
        WithdrawBalance(msg.sender, balance);
    }

     
    function rewardParties (address owner, uint feePercentage) internal {
        uint fee = msg.value * feePercentage / 100;
        rewardContract(fee);
        rewardPreviousOwner(owner, msg.value - fee);
    }

     
    function rewardContract (uint fee) internal {
        uint mainBalance = s.getUInt(keccak256(mainAddress, "balance"));
        mainBalance += fee;
        s.setUInt(keccak256(mainAddress, "balance"), mainBalance);
        SentFeeToPlatform(fee);
    }

     
    function rewardPreviousOwner (address owner, uint amount) internal {
        uint rewardBalance;
        if (owner == address(0)) {
            rewardBalance = s.getUInt(keccak256(mainAddress, "balance"));
            rewardBalance += amount;
            s.setUInt(keccak256(mainAddress, "balance"), rewardBalance);
            SentAmountToOwner(amount, mainAddress);
        } else {
            rewardBalance = s.getUInt(keccak256(owner, "balance"));
            rewardBalance += amount;
            s.setUInt(keccak256(owner, "balance"), rewardBalance);
            SentAmountToOwner(amount, owner);
        }
    }
}

contract BLBlocks is BLBalances {

    event CreatedBlock(
        uint x,
        uint y,
        uint price,
        address indexed owner,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL);

    event SetBlockForSale(
        uint x,
        uint y,
        uint price,
        address indexed owner);

    event UnsetBlockForSale(
        uint x,
        uint y,
        address indexed owner);

    event BoughtBlock(
        uint x,
        uint y,
        uint price,
        address indexed owner,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL);

    event SoldBlock(
        uint x,
        uint y,
        uint oldPrice,
        uint newPrice,
        uint feePercentage,
        address indexed owner);

    event UpdatedBlock(uint x,
        uint y,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL,
        address indexed owner);

     
    function createBlock(
        uint x,
        uint y,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL
    ) public payable {
        bytes32 key = getKey(x, y);
        uint initialPrice = s.getUInt("initialPrice");
        address owner = s.getAdd(keccak256(key, "owner"));
        uint allowance = s.getUInt(keccak256(msg.sender, "promoAllowance"));
        require(msg.value >= initialPrice || allowance > 0);
        require(owner == address(0));
        uint feePercentage = s.getUInt("buyOutFeePercentage");
        if (msg.value >= initialPrice) {
            rewardParties(owner, feePercentage);
            s.setUInt(keccak256(key, "price"), msg.value);
        } else {
            allowance--;
            s.setUInt(keccak256(msg.sender, "promoAllowance"), allowance);
            s.setUInt(keccak256(key, "price"), initialPrice);
        }
        s.setBytes32(keccak256(key, "name"), name);
        s.setBytes32(keccak256(key, "description"), description);
        s.setBytes32(keccak256(key, "url"), url);
        s.setBytes32(keccak256(key, "imageURL"), imageURL);
        s.setAdd(keccak256(key, "owner"), msg.sender);
        uint blockCount = s.getUInt("blockCount");
        blockCount++;
        s.setUInt("blockCount", blockCount);
        storageAddress.transfer(msg.value);
        CreatedBlock(x,
            y,
            msg.value,
            msg.sender,
            name,
            description,
            url,
            imageURL);
    }

     
    function getBlock (uint x, uint y) public view returns (
        uint price,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL,
        uint forSale,
        uint pricePerDay,
        address owner
    ) {
        bytes32 key = getKey(x, y);
        price = s.getUInt(keccak256(key, "price"));
        name = s.getBytes32(keccak256(key, "name"));
        description = s.getBytes32(keccak256(key, "description"));
        url = s.getBytes32(keccak256(key, "url"));
        imageURL = s.getBytes32(keccak256(key, "imageURL"));
        forSale = s.getUInt(keccak256(key, "forSale"));
        pricePerDay = s.getUInt(keccak256(key, "pricePerDay"));
        owner = s.getAdd(keccak256(key, "owner"));
    }

     
    function sellBlock(uint x, uint y, uint price) public {
        bytes32 key = getKey(x, y);
        uint basePrice = s.getUInt(keccak256(key, "price"));
        require(s.getAdd(keccak256(key, "owner")) == msg.sender);
        require(price < basePrice * 2);
        s.setUInt(keccak256(key, "forSale"), price);
        SetBlockForSale(x, y, price, msg.sender);
    }

     
    function cancelSellBlock(uint x, uint y) public {
        bytes32 key = getKey(x, y);
        require(s.getAdd(keccak256(key, "owner")) == msg.sender);
        s.setUInt(keccak256(key, "forSale"), 0);
        UnsetBlockForSale(x, y, msg.sender);
    }

     
    function buyBlock(
        uint x,
        uint y,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL
    ) public payable {
        bytes32 key = getKey(x, y);
        uint price = s.getUInt(keccak256(key, "price"));
        uint forSale = s.getUInt(keccak256(key, "forSale"));
        address owner = s.getAdd(keccak256(key, "owner"));
        require(owner != address(0));
        require((forSale > 0 && msg.value >= forSale) || msg.value >= price * 2);
        uint feePercentage = s.getUInt("buyOutFeePercentage");
        rewardParties(owner, feePercentage);
        s.setUInt(keccak256(key, "price"), msg.value);
        s.setBytes32(keccak256(key, "name"), name);
        s.setBytes32(keccak256(key, "description"), description);
        s.setBytes32(keccak256(key, "url"), url);
        s.setBytes32(keccak256(key, "imageURL"), imageURL);
        s.setAdd(keccak256(key, "owner"), msg.sender);
        s.setUInt(keccak256(key, "forSale"), 0);
        s.setUInt(keccak256(key, "pricePerDay"), 0);
        storageAddress.transfer(msg.value);
        BoughtBlock(x, y, msg.value, msg.sender,
            name, description, url, imageURL);
        SoldBlock(x, y, price, msg.value, feePercentage, owner);
    }

     
    function updateBlock(
        uint x,
        uint y,
        bytes32 name,
        bytes32 description,
        bytes32 url,
        bytes32 imageURL
    )  public {
        bytes32 key = getKey(x, y);
        address owner = s.getAdd(keccak256(key, "owner"));
        require(msg.sender == owner);
        s.setBytes32(keccak256(key, "name"), name);
        s.setBytes32(keccak256(key, "description"), description);
        s.setBytes32(keccak256(key, "url"), url);
        s.setBytes32(keccak256(key, "imageURL"), imageURL);
        UpdatedBlock(x, y, name, description, url, imageURL, msg.sender);
    }

}

contract BLTenancies is BLBlocks {

    event ToRent(
        uint x,
        uint y,
        uint pricePerDay,
        address indexed owner);

    event NotToRent(
        uint x,
        uint y,
        address indexed owner);

    event LeasedBlock(
        uint x,
        uint y,
        uint paid,
        uint expiry,
        bytes32 tenantName,
        bytes32 tenantDescription,
        bytes32 teantURL,
        bytes32 tenantImageURL,
        address indexed owner);

    event RentedBlock(
        uint x,
        uint y,
        uint paid,
        uint feePercentage,
        address indexed owner);

     
    function setForRent(
        uint x,
        uint y,
        uint pricePerDay
    ) public {
        bytes32 key = getKey(x, y);
        uint price = s.getUInt(keccak256(key, "price"));
        require(s.getAdd(keccak256(key, "owner")) == msg.sender);
        require(pricePerDay >= price / 10);
        s.setUInt(keccak256(key, "pricePerDay"), pricePerDay);
        ToRent(x, y, pricePerDay, msg.sender);
    }

     
    function cancelRent(
        uint x,
        uint y
    ) public {
        bytes32 key = getKey(x, y);
        address owner = s.getAdd(keccak256(key, "owner"));
        require(owner == msg.sender);
        s.setUInt(keccak256(key, "pricePerDay"), 0);
        NotToRent(x, y, msg.sender);
    }

     
    function leaseBlock(
        uint x,
        uint y,
        uint duration,
        bytes32 tenantName,
        bytes32 tenantDescription,
        bytes32 tenantURL,
        bytes32 tenantImageURL
    ) public payable {
        bytes32 key = getKey(x, y);
        uint pricePerDay = s.getUInt(keccak256(key, "pricePerDay"));
        require(pricePerDay > 0);
        require(msg.value >= pricePerDay * duration);
        require(now >= s.getUInt(keccak256(key, "expiry")));
        address owner = s.getAdd(keccak256(key, "owner"));
        uint feePercentage = s.getUInt("buyOutFeePercentage");
        rewardParties(owner, feePercentage);
        uint expiry = now + 86400 * duration;
        s.setUInt(keccak256(key, "expiry"), expiry);
        s.setBytes32(keccak256(key, "tenantName"), tenantName);
        s.setBytes32(keccak256(key, "tenantDescription"), tenantDescription);
        s.setBytes32(keccak256(key, "tenantURL"), tenantURL);
        s.setBytes32(keccak256(key, "tenantImageURL"), tenantImageURL);
        storageAddress.transfer(msg.value);
        RentedBlock(x, y, msg.value, feePercentage, owner);
        LeasedBlock(x, y, msg.value, expiry, tenantName, tenantDescription, tenantURL, tenantImageURL, msg.sender);
    }

     
    function getTenancy (uint x, uint y) public view returns (
        uint expiry,
        bytes32 tenantName,
        bytes32 tenantDescription,
        bytes32 tenantURL,
        bytes32 tenantImageURL
    ) {
        bytes32 key = getKey(x, y);
        expiry = s.getUInt(keccak256(key, "tenantExpiry"));
        tenantName = s.getBytes32(keccak256(key, "tenantName"));
        tenantDescription = s.getBytes32(keccak256(key, "tenantDescription"));
        tenantURL = s.getBytes32(keccak256(key, "tenantURL"));
        tenantImageURL = s.getBytes32(keccak256(key, "tenantImageURL"));
    }
}

 

contract BLMain is BLTenancies {

    event ChangedInitialPrice(uint price);
    event ChangedFeePercentage(uint fee);

     
    function totalSupply() public view returns (uint count) {
        count = s.getUInt("blockCount");
        return count;
    }

     
    function setInitialPrice(uint price) public onlyPrimary {
        s.setUInt("initialPrice", price);
        ChangedInitialPrice(price);
    }

     
    function setFeePercentage(uint feePercentage) public onlyPrimary {
        s.setUInt("buyOutFeePercentage", feePercentage);
        ChangedFeePercentage(feePercentage);
    }

     
    function getInitialPrice() public view returns (uint) {
        return s.getUInt("initialPrice");
    }

     
    function getFeePercentage() public view returns (uint) {
        return s.getUInt("buyOutFeePercentage");
    }
}