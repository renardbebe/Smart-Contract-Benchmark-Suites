 

pragma solidity ^0.4.24;

 

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

     
    constructor() public { owner = msg.sender; }

     
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

 

contract ZapCoordinatorInterface is Ownable {
	function addImmutableContract(string contractName, address newAddress) external;
	function updateContract(string contractName, address newAddress) external;
	function getContractName(uint index) public view returns (string);
	function getContract(string contractName) public view returns (address);
	function updateAllDependencies() external;
}

 

pragma solidity ^0.4.24;

contract Upgradable {

	address coordinatorAddr;
	ZapCoordinatorInterface coordinator;

	constructor(address c) public{
		coordinatorAddr = c;
		coordinator = ZapCoordinatorInterface(c);
	}

    function updateDependencies() external coordinatorOnly {
       _updateDependencies();
    }

    function _updateDependencies() internal;

    modifier coordinatorOnly() {
    	require(msg.sender == coordinatorAddr, "Error: Coordinator Only Function");
    	_;
    }
}

 

contract Destructible is Ownable {
	function selfDestruct() public onlyOwner {
		selfdestruct(owner);
	}
}

 

contract BondageInterface {
    function bond(address, bytes32, uint256) external returns(uint256);
    function unbond(address, bytes32, uint256) external returns (uint256);
    function delegateBond(address, address, bytes32, uint256) external returns(uint256);
    function escrowDots(address, address, bytes32, uint256) external returns (bool);
    function releaseDots(address, address, bytes32, uint256) external returns (bool);
    function returnDots(address, address, bytes32, uint256) external returns (bool success);
    function calcZapForDots(address, bytes32, uint256) external view returns (uint256);
    function currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function getDotsIssued(address, bytes32) public view returns (uint256);
    function getBoundDots(address, address, bytes32) public view returns (uint256);
    function getZapBound(address, bytes32) public view returns (uint256);
    function dotLimit( address, bytes32) public view returns (uint256);
}

 

contract ArbiterInterface {
    function initiateSubscription(address, bytes32, bytes32[], uint256, uint64) public;
    function getSubscription(address, address, bytes32) public view returns (uint64, uint96, uint96);
    function endSubscriptionProvider(address, bytes32) public;
    function endSubscriptionSubscriber(address, bytes32) public;
    function passParams(address receiver, bytes32 endpoint, bytes32[] params) public;
}

 

contract DatabaseInterface is Ownable {
	function setStorageContract(address _storageContract, bool _allowed) public;
	 
	function getBytes32(bytes32 key) external view returns(bytes32);
	function setBytes32(bytes32 key, bytes32 value) external;
	 
	function getNumber(bytes32 key) external view returns(uint256);
	function setNumber(bytes32 key, uint256 value) external;
	 
	function getBytes(bytes32 key) external view returns(bytes);
	function setBytes(bytes32 key, bytes value) external;
	 
	function getString(bytes32 key) external view returns(string);
	function setString(bytes32 key, string value) external;
	 
	function getBytesArray(bytes32 key) external view returns (bytes32[]);
	function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32);
	function getBytesArrayLength(bytes32 key) external view returns (uint256);
	function pushBytesArray(bytes32 key, bytes32 value) external;
	function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external;
	function setBytesArray(bytes32 key, bytes32[] value) external;
	 
	function getIntArray(bytes32 key) external view returns (int[]);
	function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int);
	function getIntArrayLength(bytes32 key) external view returns (uint256);
	function pushIntArray(bytes32 key, int value) external;
	function setIntArrayIndex(bytes32 key, uint256 index, int value) external;
	function setIntArray(bytes32 key, int[] value) external;
	 
	function getAddressArray(bytes32 key) external view returns (address[]);
	function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address);
	function getAddressArrayLength(bytes32 key) external view returns (uint256);
	function pushAddressArray(bytes32 key, address value) external;
	function setAddressArrayIndex(bytes32 key, uint256 index, address value) external;
	function setAddressArray(bytes32 key, address[] value) external;
}

 

 







contract Arbiter is Destructible, ArbiterInterface, Upgradable {
     
    event DataPurchase(
        address indexed provider,           
        address indexed subscriber,         
        uint256 publicKey,                  
        uint256 indexed amount,             
        bytes32[] endpointParams,           
        bytes32 endpoint                    
    );

     
    event DataSubscriptionEnd(
        address indexed provider,                       
        address indexed subscriber,                     
        SubscriptionTerminator indexed terminator       
    ); 

     
    event ParamsPassed(
        address indexed sender,
        address indexed receiver,
        bytes32 endpoint,
        bytes32[] params
    );

     
    enum SubscriptionTerminator { Provider, Subscriber }

    BondageInterface bondage;
    address public bondageAddress;

     
    DatabaseInterface public db;

    constructor(address c) Upgradable(c) public {
        _updateDependencies();
    }

    function _updateDependencies() internal {
        bondageAddress = coordinator.getContract("BONDAGE");
        bondage = BondageInterface(bondageAddress);

        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);
    }

     
     
     
     
    function passParams(address receiver, bytes32 endpoint, bytes32[] params) public {

        emit ParamsPassed(msg.sender, receiver, endpoint, params);    
    }

     
     
     
     
     
     
    function initiateSubscription(
        address providerAddress,    
        bytes32 endpoint,           
        bytes32[] endpointParams,   
        uint256 publicKey,          
        uint64 blocks               
    ) 
        public 
    {   
         
        require(blocks > 0, "Error: Must be at least one block");

         
        require(getDots(providerAddress, msg.sender, endpoint) == 0, "Error: Cannot reinstantiate a currently active contract");

         
        bondage.escrowDots(msg.sender, providerAddress, endpoint, blocks);
        
         
        setSubscription(
            providerAddress,
            msg.sender,
            endpoint,
            blocks,
            uint96(block.number),
            uint96(block.number) + uint96(blocks)
        );

        emit DataPurchase(
            providerAddress,
            msg.sender,
            publicKey,
            blocks,
            endpointParams,
            endpoint
        );
    }

     
    function getSubscription(address providerAddress, address subscriberAddress, bytes32 endpoint)
        public
        view
        returns (uint64 dots, uint96 blockStart, uint96 preBlockEnd)
    {
        return (
            getDots(providerAddress, subscriberAddress, endpoint),
            getBlockStart(providerAddress, subscriberAddress, endpoint),
            getPreBlockEnd(providerAddress, subscriberAddress, endpoint)
        );
    }

     
    function endSubscriptionProvider(        
        address subscriberAddress,
        bytes32 endpoint
    )
        public 
    {
         
        if (endSubscription(msg.sender, subscriberAddress, endpoint))
            emit DataSubscriptionEnd(
                msg.sender, 
                subscriberAddress, 
                SubscriptionTerminator.Provider
            );
    }

     
    function endSubscriptionSubscriber(
        address providerAddress,
        bytes32 endpoint
    )
        public 
    {
         
        if (endSubscription(providerAddress, msg.sender, endpoint))
            emit DataSubscriptionEnd(
                providerAddress,
                msg.sender,
                SubscriptionTerminator.Subscriber
            );
    }

     
    function endSubscription(        
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        private
        returns (bool)
    {   
         
        uint256 dots = getDots(providerAddress, subscriberAddress, endpoint);
        uint256 preblockend = getPreBlockEnd(providerAddress, subscriberAddress, endpoint);
         
        require(dots > 0, "Error: Subscriber must have a subscription");

        if (block.number < preblockend) {
             
            uint256 earnedDots = block.number - getBlockStart(providerAddress, subscriberAddress, endpoint);
            uint256 returnedDots = dots - earnedDots;

             
            bondage.releaseDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                earnedDots
            );
             
            bondage.returnDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                returnedDots
            );
        } else {
             
            bondage.releaseDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                dots
            );
        }
         
        deleteSubscription(providerAddress, subscriberAddress, endpoint);
        return true;
    }    


     

     
    function getDots(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint64)
    {
        return uint64(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots'))));
    }

     
    function getBlockStart(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint96)
    {
        return uint96(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart'))));
    }

     
    function getPreBlockEnd(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint96)
    {
        return uint96(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd'))));
    }

     

     
    function setSubscription(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint,
        uint64 dots,
        uint96 blockStart,
        uint96 preBlockEnd
    )
        private
    {
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots')), dots);
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart')), uint256(blockStart));
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd')), uint256(preBlockEnd));
    }

     

     
    function deleteSubscription(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        private
    {
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots')), 0);
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart')), uint256(0));
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd')), uint256(0));
    }
}

     