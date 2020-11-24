 

pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StorageBase is Ownable {

    function withdrawBalance() external onlyOwner returns (bool) {
         
         
        bool res = msg.sender.send(address(this).balance);
        return res;
    }
}

 
contract ActivityStorage is StorageBase {

    struct Activity {
         
        bool isPause;
         
        uint16 buyLimit;
         
        uint128 packPrice;
         
        uint64 startDate;
         
        uint64 endDate;
         
        mapping(uint16 => address) soldPackToAddress;
         
        mapping(address => uint16) addressBoughtCount;
    }

     
    mapping(uint16 => Activity) public activities;

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
    {
         
        require(activities[_activityId].buyLimit == 0);

        activities[_activityId] = Activity({
            isPause: false,
            buyLimit: _buyLimit,
            packPrice: _packPrice,
            startDate: _startDate,
            endDate: _endDate
        });
    }

    function sellPackToAddress(
        uint16 _activityId, 
        uint16 _packId, 
        address buyer
    ) 
        external 
        onlyOwner
    {
        Activity storage activity = activities[_activityId];
        activity.soldPackToAddress[_packId] = buyer;
        activity.addressBoughtCount[buyer]++;
    }

    function pauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = true;
    }

    function unpauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = false;
    }

    function deleteActivity(uint16 _activityId) external onlyOwner {
        delete activities[_activityId];
    }

    function getAddressBoughtCount(uint16 _activityId, address buyer) external view returns (uint16) {
        return activities[_activityId].addressBoughtCount[buyer];
    }

    function getBuyerAddress(uint16 _activityId, uint16 packId) external view returns (address) {
        return activities[_activityId].soldPackToAddress[packId];
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract HasNoContracts is Pausable {

    function reclaimContract(address _contractAddr) external onlyOwner whenPaused {
        Ownable contractInst = Ownable(_contractAddr);
        contractInst.transferOwnership(owner);
    }
}

contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract LogicBase is HasNoContracts {

     
     
     
    bytes4 constant InterfaceSignature_NFC = bytes4(0x9f40b779);

     
    ERC721 public nonFungibleContract;

     
    StorageBase public storageContract;

    function LogicBase(address _nftAddress, address _storageAddress) public {
         
        paused = true;

        setNFTAddress(_nftAddress);

        require(_storageAddress != address(0));
        storageContract = StorageBase(_storageAddress);
    }

     
     
     
    function destroy() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(owner);
    }

     
     
     
    function destroyAndSendToStorageOwner() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(storageOwner);
    }

     
    function unpause() public onlyOwner whenPaused {
         
        require(nonFungibleContract != address(0));
        require(storageContract != address(0));
         
        require(storageContract.owner() == address(this));

        super.unpause();
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0));
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_NFC));
        nonFungibleContract = candidateContract;
    }

     
    function withdrawBalance() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = nftAddress.send(address(this).balance);
        return res;
    }

    function withdrawBalanceFromStorageContract() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = storageContract.withdrawBalance();
        return res;
    }
}

contract ActivityCore is LogicBase {

    bool public isActivityCore = true;

    ActivityStorage activityStorage;

    event ActivityCreated(uint16 activityId);
    event ActivityBidSuccess(uint16 activityId, uint16 packId, address winner);

    function ActivityCore(address _nftAddress, address _storageAddress) 
        LogicBase(_nftAddress, _storageAddress) public {
            
        activityStorage = ActivityStorage(_storageAddress);
    }

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
        whenNotPaused
    {
        activityStorage.createActivity(_activityId, _buyLimit, _packPrice, _startDate, _endDate);

        emit ActivityCreated(_activityId);
    }

     
     
    function deleteActivity(
        uint16 _activityId
    )
        external 
        onlyOwner
        whenPaused
    {
        activityStorage.deleteActivity(_activityId);
    }

    function getActivity(
        uint16 _activityId
    ) 
        external 
        view  
        returns (
            bool isPause,
            uint16 buyLimit,
            uint128 packPrice,
            uint64 startDate,
            uint64 endDate
        )
    {
        return activityStorage.activities(_activityId);
    }
    
    function bid(uint16 _activityId, uint16 _packId)
        external
        payable
        whenNotPaused
    {
        bool isPause;
        uint16 buyLimit;
        uint128 packPrice;
        uint64 startDate;
        uint64 endDate;
        (isPause, buyLimit, packPrice, startDate, endDate) = activityStorage.activities(_activityId);
         
        require(!isPause);
         
        require(buyLimit > 0);
         
        require(msg.value >= packPrice);
         
        require(now >= startDate && now <= endDate);
         
        require(activityStorage.getBuyerAddress(_activityId, _packId) == address(0));
         
        require(activityStorage.getAddressBoughtCount(_activityId, msg.sender) < buyLimit);
         
        activityStorage.sellPackToAddress(_activityId, _packId, msg.sender);
         
        emit ActivityBidSuccess(_activityId, _packId, msg.sender);
    }
}