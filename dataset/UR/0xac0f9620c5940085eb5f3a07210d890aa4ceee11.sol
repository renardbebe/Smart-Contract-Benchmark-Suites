 

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

 

contract Client1 {
     
     
     
    function callback(uint256 id, string response1) external;
}
contract Client2 {
     
     
     
     
    function callback(uint256 id, string response1, string response2) external;
}
contract Client3 {
     
     
     
     
     
    function callback(uint256 id, string response1, string response2, string response3) external;
}
contract Client4 {
     
     
     
     
     
     
    function callback(uint256 id, string response1, string response2, string response3, string response4) external;
}

contract ClientBytes32Array {
     
     
     
    function callback(uint256 id, bytes32[] response) external;
}

contract ClientIntArray{
     
     
     
    function callback(uint256 id, int[] response) external;
}

 

contract OnChainProvider {
     
     
     
     
     
    function receive(uint256 id, string userQuery, bytes32 endpoint, bytes32[] endpointParams, bool onchainSubscriber) external;
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

 

interface DispatchInterface {
    function query(address, string, bytes32, bytes32[]) external returns (uint256);
    function respond1(uint256, string) external returns (bool);
    function respond2(uint256, string, string) external returns (bool);
    function respond3(uint256, string, string, string) external returns (bool);
    function respond4(uint256, string, string, string, string) external returns (bool);
    function respondBytes32Array(uint256, bytes32[]) external returns (bool);
    function respondIntArray(uint256,int[] ) external returns (bool);
    function cancelQuery(uint256) external;
    function getProvider(uint256 id) public view returns (address);
    function getSubscriber(uint256 id) public view returns (address);
    function getEndpoint(uint256 id) public view returns (bytes32);
    function getStatus(uint256 id) public view returns (uint256);
    function getCancel(uint256 id) public view returns (uint256);
    function getUserQuery(uint256 id) public view returns (string);
    function getSubscriberOnchain(uint256 id) public view returns (bool);
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

 

 








contract Dispatch is Destructible, DispatchInterface, Upgradable { 

    enum Status { Pending, Fulfilled, Canceled }

     
    event Incoming(
        uint256 indexed id,
        address indexed provider,
        address indexed subscriber,
        string query,
        bytes32 endpoint,
        bytes32[] endpointParams,
        bool onchainSubscriber
    );

    event FulfillQuery(
        address indexed subscriber,
        address indexed provider,
        bytes32 indexed endpoint
    );

    event OffchainResponse(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        bytes32[] response
    );

    event OffchainResponseInt(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        int[] response
    );

    event OffchainResult1(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        string response1
    );

    event OffchainResult2(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        string response1,
        string response2
    );

    event OffchainResult3(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        string response1,
        string response2,
        string response3
    );

    event OffchainResult4(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider,
        string response1,
        string response2,
        string response3,
        string response4
    );

    event CanceledRequest(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider
    );

    event RevertCancelation(
        uint256 indexed id,
        address indexed subscriber,
        address indexed provider
    );

    BondageInterface public bondage;
    address public bondageAddress;

    DatabaseInterface public db;

    constructor(address c) Upgradable(c) public {
         
    }

    function _updateDependencies() internal {
        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);

        bondageAddress = coordinator.getContract("BONDAGE");
        bondage = BondageInterface(bondageAddress);
    }

     
     
    function query(
        address provider,            
        string userQuery,            
        bytes32 endpoint,            
        bytes32[] endpointParams    
        )
        external
        returns (uint256 id)
    {
        uint256 dots = bondage.getBoundDots(msg.sender, provider, endpoint);
        bool onchainProvider = isContract(provider);
        bool onchainSubscriber = isContract(msg.sender);
        if(dots >= 1) {
             
            bondage.escrowDots(msg.sender, provider, endpoint, 1);

            id = uint256(keccak256(abi.encodePacked(block.number, now, userQuery, msg.sender, provider)));

            createQuery(id, provider, msg.sender, endpoint, userQuery, onchainSubscriber);
            if(onchainProvider) {
                OnChainProvider(provider).receive(id, userQuery, endpoint, endpointParams, onchainSubscriber); 
            } else{
                emit Incoming(id, provider, msg.sender, userQuery, endpoint, endpointParams, onchainSubscriber);
            }
        } else {  
            revert("Subscriber does not have any dots.");
        }
    }

     
     
    function fulfillQuery(uint256 id) private returns (bool) {
        Status status = Status(getStatus(id));

        require(status != Status.Fulfilled, "Error: Status already fulfilled");

        address subscriber = getSubscriber(id);
        address provider = getProvider(id);
        bytes32 endpoint = getEndpoint(id);
        
        if ( status == Status.Canceled ) {
            uint256 canceled = getCancel(id);

             
             
            require(block.number == canceled, "Error: Cancel ignored");

             
            setCanceled(id, false);

             
            bondage.escrowDots(subscriber, provider, endpoint, 1);

             
            emit RevertCancelation(id, subscriber, provider);
        }

        setFulfilled(id);

        bondage.releaseDots(subscriber, provider, endpoint, 1);

        emit FulfillQuery(subscriber, provider, endpoint);

        return true;
    }

     
     
    function cancelQuery(uint256 id) external {
        address subscriber = getSubscriber(id);
        address provider = getProvider(id);
        bytes32 endpoint = getEndpoint(id);

        require(subscriber == msg.sender, "Error: Wrong subscriber");
        require(Status(getStatus(id)) == Status.Pending, "Error: Query is not pending");

         
        setCanceled(id, true);

         
        bondage.returnDots(subscriber, provider, endpoint, 1);

         
        emit CanceledRequest(id, getSubscriber(id), getProvider(id));
    }

     
    function respondBytes32Array(
        uint256 id,
        bytes32[] response
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();
        if(getSubscriberOnchain(id)) {
            ClientBytes32Array(getSubscriber(id)).callback(id, response);
        }
        else {
            emit OffchainResponse(id, getSubscriber(id), msg.sender, response);
        }
        return true;
    }

     
    function respondIntArray(
        uint256 id,
        int[] response
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();
        if(getSubscriberOnchain(id)) {
            ClientIntArray(getSubscriber(id)).callback(id, response);
        }
        else {
            emit OffchainResponseInt(id, getSubscriber(id), msg.sender, response);
        }
        return true;
    }


     
    function respond1(
        uint256 id,
        string response
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();

        if(getSubscriberOnchain(id)) {
            Client1(getSubscriber(id)).callback(id, response);
        }
        else {
            emit OffchainResult1(id, getSubscriber(id), msg.sender, response);
        }
        return true;
    }

     
    function respond2(
        uint256 id,
        string response1,
        string response2
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();

        if(getSubscriberOnchain(id)) {
            Client2(getSubscriber(id)).callback(id, response1, response2);
        }
        else {
            emit OffchainResult2(id, getSubscriber(id), msg.sender, response1, response2);
        }

        return true;
    }

     
    function respond3(
        uint256 id,
        string response1,
        string response2,
        string response3
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();

        if(getSubscriberOnchain(id)) {
            Client3(getSubscriber(id)).callback(id, response1, response2, response3);
        }
        else {
            emit OffchainResult3(id, getSubscriber(id), msg.sender, response1, response2, response3);
        }

        return true;
    }

     
    function respond4(
        uint256 id,
        string response1,
        string response2,
        string response3,
        string response4
    )
        external
        returns (bool)
    {
        if (getProvider(id) != msg.sender || !fulfillQuery(id))
            revert();

        if(getSubscriberOnchain(id)) {
            Client4(getSubscriber(id)).callback(id, response1, response2, response3, response4);
        }
        else {
            emit OffchainResult4(id, getSubscriber(id), msg.sender, response1, response2, response3, response4);
        }

        return true;
    }

     

     
     
    function getProvider(uint256 id) public view returns (address) {
        return address(db.getNumber(keccak256(abi.encodePacked('queries', id, 'provider'))));
    }

     
     
    function getSubscriber(uint256 id) public view returns (address) {
        return address(db.getNumber(keccak256(abi.encodePacked('queries', id, 'subscriber'))));
    }

     
     
    function getEndpoint(uint256 id) public view returns (bytes32) {
        return db.getBytes32(keccak256(abi.encodePacked('queries', id, 'endpoint')));
    }

     
     
    function getStatus(uint256 id) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('queries', id, 'status')));
    }

     
     
    function getCancel(uint256 id) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('queries', id, 'cancelBlock')));
    }

     
     
    function getUserQuery(uint256 id) public view returns (string) {
        return db.getString(keccak256(abi.encodePacked('queries', id, 'userQuery')));
    }

     
     
    function getSubscriberOnchain(uint256 id) public view returns (bool) {
        uint res = db.getNumber(keccak256(abi.encodePacked('queries', id, 'onchainSubscriber')));
        return res == 1 ? true : false;
    }
 
     
    function createQuery(
        uint256 id,
        address provider,
        address subscriber,
        bytes32 endpoint,
        string userQuery,
        bool onchainSubscriber
    ) 
        private
    {
        db.setNumber(keccak256(abi.encodePacked('queries', id, 'provider')), uint256(provider));
        db.setNumber(keccak256(abi.encodePacked('queries', id, 'subscriber')), uint256(subscriber));
        db.setBytes32(keccak256(abi.encodePacked('queries', id, 'endpoint')), endpoint);
        db.setString(keccak256(abi.encodePacked('queries', id, 'userQuery')), userQuery);
        db.setNumber(keccak256(abi.encodePacked('queries', id, 'status')), uint256(Status.Pending));
        db.setNumber(keccak256(abi.encodePacked('queries', id, 'onchainSubscriber')), onchainSubscriber ? 1 : 0);
    }

    function setFulfilled(uint256 id) private {
        db.setNumber(keccak256(abi.encodePacked('queries', id, 'status')), uint256(Status.Fulfilled));
    }

    function setCanceled(uint256 id, bool canceled) private {
        if ( canceled ) {
            db.setNumber(keccak256(abi.encodePacked('queries', id, 'cancelBlock')), block.number);
            db.setNumber(keccak256(abi.encodePacked('queries', id, 'status')), uint256(Status.Canceled));
        }
        else {
            db.setNumber(keccak256(abi.encodePacked('queries', id, 'cancelBlock')), 0);
            db.setNumber(keccak256(abi.encodePacked('queries', id, 'status')), uint256(Status.Pending));            
        }
    }

    function isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

  

 