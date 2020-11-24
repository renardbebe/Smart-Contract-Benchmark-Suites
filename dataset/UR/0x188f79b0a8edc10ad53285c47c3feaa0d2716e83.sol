 

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

 

contract Destructible is Ownable {
	function selfDestruct() public onlyOwner {
		selfdestruct(owner);
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

 

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    string public name;
    string public symbol;
    uint256 public decimals;
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract CurrentCostInterface {    
    function _currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function _dotLimit(address, bytes32) public view returns (uint256);
    function _costOfNDots(address, bytes32, uint256, uint256) public view returns (uint256);
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

 

contract Bondage is Destructible, BondageInterface, Upgradable {
    DatabaseInterface public db;

    event Bound(address indexed holder, address indexed oracle, bytes32 indexed endpoint, uint256 numZap, uint256 numDots);
    event Unbound(address indexed holder, address indexed oracle, bytes32 indexed endpoint, uint256 numDots);
    event Escrowed(address indexed holder, address indexed oracle, bytes32 indexed endpoint, uint256 numDots);
    event Released(address indexed holder, address indexed oracle, bytes32 indexed endpoint, uint256 numDots);
    event Returned(address indexed holder, address indexed oracle, bytes32 indexed endpoint, uint256 numDots);


    CurrentCostInterface currentCost;
    ERC20 token;

    address public arbiterAddress;
    address public dispatchAddress;

     
    modifier operatorOnly() {
        require(msg.sender == arbiterAddress || msg.sender == dispatchAddress, "Error: Operator Only Error");
        _;
    }

     
    constructor(address c) Upgradable(c) public {
        _updateDependencies();
    }

    function _updateDependencies() internal {
        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);
        arbiterAddress = coordinator.getContract("ARBITER");
        dispatchAddress = coordinator.getContract("DISPATCH");
        token = ERC20(coordinator.getContract("ZAP_TOKEN")); 
        currentCost = CurrentCostInterface(coordinator.getContract("CURRENT_COST")); 
    }

     
     
    function bond(address oracleAddress, bytes32 endpoint, uint256 numDots) external returns (uint256 bound) {
        bound = _bond(msg.sender, oracleAddress, endpoint, numDots);
        emit Bound(msg.sender, oracleAddress, endpoint, bound, numDots);
    }

     
    function unbond(address oracleAddress, bytes32 endpoint, uint256 numDots) external returns (uint256 unbound) {
        unbound = _unbond(msg.sender, oracleAddress, endpoint, numDots);
        emit Unbound(msg.sender, oracleAddress, endpoint, numDots);
    }        

     
     
    function delegateBond(address holderAddress, address oracleAddress, bytes32 endpoint, uint256 numDots) external returns (uint256 boundZap) {
        boundZap = _bond(holderAddress, oracleAddress, endpoint, numDots);
        emit Bound(holderAddress, oracleAddress, endpoint, boundZap, numDots);
    }

     
     
     
    function escrowDots(        
        address holderAddress,
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots
    )
        external
        operatorOnly        
        returns (bool success)
    {
        uint256 boundDots = getBoundDots(holderAddress, oracleAddress, endpoint);
        require(numDots <= boundDots, "Error: Not enough dots bound");
        updateEscrow(holderAddress, oracleAddress, endpoint, numDots, "add");
        updateBondValue(holderAddress, oracleAddress, endpoint, numDots, "sub");
        emit Escrowed(holderAddress, oracleAddress, endpoint, numDots);
        return true;
    }

     
     
     
     
    function releaseDots(
        address holderAddress,
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots
    )
        external
        operatorOnly 
        returns (bool success)
    {
        uint256 numEscrowed = getNumEscrow(holderAddress, oracleAddress, endpoint);
        require(numDots <= numEscrowed, "Error: Not enough dots Escrowed");
        updateEscrow(holderAddress, oracleAddress, endpoint, numDots, "sub");
        updateBondValue(oracleAddress, oracleAddress, endpoint, numDots, "add");
        emit Released(holderAddress, oracleAddress, endpoint, numDots);
        return true;
    }

     
     
     
     
    function returnDots(
        address holderAddress,
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots
    )
        external
        operatorOnly 
        returns (bool success)
    {
        uint256 numEscrowed = getNumEscrow(holderAddress, oracleAddress, endpoint);
        require(numDots <= numEscrowed, "Error: Not enough dots escrowed");
        updateEscrow(holderAddress, oracleAddress, endpoint, numDots, "sub");
        updateBondValue(holderAddress, oracleAddress, endpoint, numDots, "add");
        emit Returned(holderAddress, oracleAddress, endpoint, numDots);
        return true;
    }


     
     
    function calcZapForDots(
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots       
    ) 
        external
        view
        returns (uint256 numZap)
    {
        uint256 issued = getDotsIssued(oracleAddress, endpoint);
        return currentCost._costOfNDots(oracleAddress, endpoint, issued + 1, numDots - 1);
    }

     
     
     
     
    function currentCostOfDot(
        address oracleAddress,
        bytes32 endpoint,
        uint256 totalBound
    )
        public
        view
        returns (uint256 cost)
    {
        return currentCost._currentCostOfDot(oracleAddress, endpoint, totalBound);
    }

     
     
     
    function dotLimit(
        address oracleAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint256 limit)
    {
        return currentCost._dotLimit(oracleAddress, endpoint);
    }


     
    function getZapBound(address oracleAddress, bytes32 endpoint) public view returns (uint256) {
        return getNumZap(oracleAddress, endpoint);
    }

    function _bond(
        address holderAddress,
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots        
    )
        private
        returns (uint256) 
    {   

        address broker = getEndpointBroker(oracleAddress, endpoint);

        if( broker != address(0)){
            require(msg.sender == broker, "Error: Only the broker has access to this function");
        }

         
        uint256 issued = getDotsIssued(oracleAddress, endpoint);
        require(issued + numDots <= dotLimit(oracleAddress, endpoint), "Error: Dot limit exceeded");
        
        uint256 numZap = currentCost._costOfNDots(oracleAddress, endpoint, issued + 1, numDots - 1);

         
        require(token.transferFrom(msg.sender, this, numZap), "Error: User must have approved contract to transfer ZAP");

        if (!isProviderInitialized(holderAddress, oracleAddress)) {            
            setProviderInitialized(holderAddress, oracleAddress);
            addHolderOracle(holderAddress, oracleAddress);
        }

        updateBondValue(holderAddress, oracleAddress, endpoint, numDots, "add");        
        updateTotalIssued(oracleAddress, endpoint, numDots, "add");
        updateTotalBound(oracleAddress, endpoint, numZap, "add");

        return numZap;
    }

    function _unbond(        
        address holderAddress,
        address oracleAddress,
        bytes32 endpoint,
        uint256 numDots
    )
        private
        returns (uint256 numZap)
    {
        address broker = getEndpointBroker(oracleAddress, endpoint);

        if( broker != address(0)){
            require(msg.sender == broker, "Error: Only the broker has access to this function");
        }

         
        uint256 amountBound = getBoundDots(holderAddress, oracleAddress, endpoint);
        require(amountBound >= numDots, "Error: Not enough dots bonded");
        require(numDots > 0, "Error: Dots to unbond must be more than zero");

         
        uint256 issued = getDotsIssued(oracleAddress, endpoint);
        numZap = currentCost._costOfNDots(oracleAddress, endpoint, issued + 1 - numDots, numDots - 1);

         
        updateTotalBound(oracleAddress, endpoint, numZap, "sub");
        updateTotalIssued(oracleAddress, endpoint, numDots, "sub");
        updateBondValue(holderAddress, oracleAddress, endpoint, numDots, "sub");

         
        require(token.transfer(msg.sender, numZap), "Error: Transfer failed");

        return numZap;
    }

     
    function isProviderInitialized(address holderAddress, address oracleAddress) public view returns (bool) {
        return db.getNumber(keccak256(abi.encodePacked('holders', holderAddress, 'initialized', oracleAddress))) == 1 ? true : false;
    }

     
    function getEndpointBroker(address oracleAddress, bytes32 endpoint) public view returns (address) {
        return address(db.getBytes32(keccak256(abi.encodePacked('oracles', oracleAddress, endpoint, 'broker'))));
    }

    function getNumEscrow(address holderAddress, address oracleAddress, bytes32 endpoint) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('escrow', holderAddress, oracleAddress, endpoint)));
    }

    function getNumZap(address oracleAddress, bytes32 endpoint) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('totalBound', oracleAddress, endpoint)));
    }

    function getDotsIssued(address oracleAddress, bytes32 endpoint) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('totalIssued', oracleAddress, endpoint)));
    }

    function getBoundDots(address holderAddress, address oracleAddress, bytes32 endpoint) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked('holders', holderAddress, 'bonds', oracleAddress, endpoint)));
    }

    function getIndexSize(address holderAddress) external view returns (uint256) {
        return db.getAddressArrayLength(keccak256(abi.encodePacked('holders', holderAddress, 'oracleList')));
    }

    function getOracleAddress(address holderAddress, uint256 index) public view returns (address) {
        return db.getAddressArrayIndex(keccak256(abi.encodePacked('holders', holderAddress, 'oracleList')), index);
    }

     
    function addHolderOracle(address holderAddress, address oracleAddress) internal {
        db.pushAddressArray(keccak256(abi.encodePacked('holders', holderAddress, 'oracleList')), oracleAddress);
    }

    function setProviderInitialized(address holderAddress, address oracleAddress) internal {
        db.setNumber(keccak256(abi.encodePacked('holders', holderAddress, 'initialized', oracleAddress)), 1);
    }

    function updateEscrow(address holderAddress, address oracleAddress, bytes32 endpoint, uint256 numDots, bytes32 op) internal {
        uint256 newEscrow = db.getNumber(keccak256(abi.encodePacked('escrow', holderAddress, oracleAddress, endpoint)));

        if ( op == "sub" ) {
            newEscrow -= numDots;
        } else if ( op == "add" ) {
            newEscrow += numDots;
        }
        else {
            revert();
        }

        db.setNumber(keccak256(abi.encodePacked('escrow', holderAddress, oracleAddress, endpoint)), newEscrow);
    }

    function updateBondValue(address holderAddress, address oracleAddress, bytes32 endpoint, uint256 numDots, bytes32 op) internal {
        uint256 bondValue = db.getNumber(keccak256(abi.encodePacked('holders', holderAddress, 'bonds', oracleAddress, endpoint)));
        
        if (op == "sub") {
            bondValue -= numDots;
        } else if (op == "add") {
            bondValue += numDots;
        }

        db.setNumber(keccak256(abi.encodePacked('holders', holderAddress, 'bonds', oracleAddress, endpoint)), bondValue);
    }

    function updateTotalBound(address oracleAddress, bytes32 endpoint, uint256 numZap, bytes32 op) internal {
        uint256 totalBound = db.getNumber(keccak256(abi.encodePacked('totalBound', oracleAddress, endpoint)));
        
        if (op == "sub"){
            totalBound -= numZap;
        } else if (op == "add") {
            totalBound += numZap;
        }
        else {
            revert();
        }
        
        db.setNumber(keccak256(abi.encodePacked('totalBound', oracleAddress, endpoint)), totalBound);
    }

    function updateTotalIssued(address oracleAddress, bytes32 endpoint, uint256 numDots, bytes32 op) internal {
        uint256 totalIssued = db.getNumber(keccak256(abi.encodePacked('totalIssued', oracleAddress, endpoint)));
        
        if (op == "sub"){
            totalIssued -= numDots;
        } else if (op == "add") {
            totalIssued += numDots;
        }
        else {
            revert();
        }
    
        db.setNumber(keccak256(abi.encodePacked('totalIssued', oracleAddress, endpoint)), totalIssued);
    }
}

     