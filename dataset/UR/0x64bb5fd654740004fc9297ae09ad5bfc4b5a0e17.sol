 

 

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

 

pragma solidity ^0.4.24;


contract FactoryTokenInterface is Ownable {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function mint(address _to, uint256 _amount) public returns (bool);
    function burnFrom(address _from, uint256 _value) public;
}

 

pragma solidity ^0.4.24;


contract TokenFactoryInterface {
    function create(string _name, string _symbol) public returns (FactoryTokenInterface);
}

 

pragma solidity ^0.4.24;


contract ZapCoordinatorInterface is Ownable {
    function addImmutableContract(string contractName, address newAddress) external;
    function updateContract(string contractName, address newAddress) external;
    function getContractName(uint index) public view returns (string);
    function getContract(string contractName) public view returns (address);
    function updateAllDependencies() external;
}

 

pragma solidity ^0.4.24;

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

 

pragma solidity ^0.4.24;

contract CurrentCostInterface {
    function _currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function _dotLimit(address, bytes32) public view returns (uint256);
    function _costOfNDots(address, bytes32, uint256, uint256) public view returns (uint256);
}

 

pragma solidity ^0.4.24;

contract RegistryInterface {
    function initiateProvider(uint256, bytes32) public returns (bool);
    function initiateProviderCurve(bytes32, int256[], address) public returns (bool);
    function setEndpointParams(bytes32, bytes32[]) public;
    function getEndpointParams(address, bytes32) public view returns (bytes32[]);
    function getProviderPublicKey(address) public view returns (uint256);
    function getProviderTitle(address) public view returns (bytes32);
    function setProviderParameter(bytes32, bytes) public;
    function setProviderTitle(bytes32) public;
    function clearEndpoint(bytes32) public;
    function getProviderParameter(address, bytes32) public view returns (bytes);
    function getAllProviderParams(address) public view returns (bytes32[]);
    function getProviderCurveLength(address, bytes32) public view returns (uint256);
    function getProviderCurve(address, bytes32) public view returns (int[]);
    function isProviderInitiated(address) public view returns (bool);
    function getAllOracles() external view returns (address[]);
    function getProviderEndpoints(address) public view returns (bytes32[]);
    function getEndpointBroker(address, bytes32) public view returns (address);
}

 

 

contract SampleContest is Ownable {

    CurrentCostInterface currentCost;
    FactoryTokenInterface public reserveToken;
    ZapCoordinatorInterface public coord;
    TokenFactoryInterface public tokenFactory;
    BondageInterface bondage;

    enum ContestStatus { 
        Uninitialized,     
        Initialized,       
        ReadyToSettle,     
        Judged,            
        Settled            
    }

    address public oracle;     
    bytes32 public winner;     
    uint256 public winValue;   
    ContestStatus public status;  

    mapping(bytes32 => address) public curves;  
    bytes32[] public curves_list;  

    mapping(address => uint8) public redeemed;  
    address[] public redeemed_list;
    
    event DotTokenCreated(address tokenAddress);
    event Bonded(bytes32 indexed endpoint, uint256 indexed numDots, address indexed sender); 
    event Unbonded(bytes32 indexed endpoint, uint256 indexed numDots, address indexed sender);

    event Initialized(address indexed oracle);
    event Closed();
    event Judged(bytes32 winner);
    event Settled(uint256 winValue, uint256 winTokens); 
    event Reset();

    constructor(
        address coordinator, 
        address factory,
        uint256 providerPubKey,
        bytes32 providerTitle 
    ){
        coord = ZapCoordinatorInterface(coordinator); 
        reserveToken = FactoryTokenInterface(coord.getContract("ZAP_TOKEN"));
         
        reserveToken.approve(coord.getContract("BONDAGE"), ~uint256(0));
        tokenFactory = TokenFactoryInterface(factory);

        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        registry.initiateProvider(providerPubKey, providerTitle);
        status = ContestStatus.Uninitialized;
    }

 
 
    function initializeContest(
        address oracleAddress
    ) onlyOwner public {
        require( status == ContestStatus.Uninitialized, "Contest already initialized");
        oracle = oracleAddress;
        status = ContestStatus.Initialized;
        emit Initialized(oracle);
    }

    function close() onlyOwner {
        status = ContestStatus.ReadyToSettle; 
        emit Closed();
    }

    function judge(bytes32 endpoint) {
        require( status == ContestStatus.ReadyToSettle, "not closed" );
        require( msg.sender == oracle, "not oracle");
        winner = endpoint;
        status = ContestStatus.Judged;
        emit Judged(winner);
    }

    function settle() {
        require( status == ContestStatus.Judged, "winner not determined");

        bondage = BondageInterface(coord.getContract("BONDAGE"));
        uint256 dots;
        for( uint256 i = 0; i < curves_list.length; i++) {

            if(curves_list[i] != winner) {
                dots =  bondage.getDotsIssued(address(this), curves_list[i]);  
                if( dots > 0) {
                    bondage.unbond(address(this), curves_list[i], dots);                 
                }  
            }
        } 

         
        uint256 numWin =  bondage.getDotsIssued(address(this), winner);  
         
        winValue = reserveToken.balanceOf(address(this)) / numWin;
        status = ContestStatus.Settled;
        emit Settled(winValue, numWin);
    }


     
    function reset() public {
        require(status == ContestStatus.Settled, "contest not settled");
        require(msg.sender == oracle);
        
        delete redeemed_list;
        delete curves_list;
        status = ContestStatus.Initialized; 
        emit Reset();
    }

 

    function initializeCurve(
        bytes32 endpoint, 
        bytes32 symbol, 
        int256[] curve
    ) public returns(address) {
        
        require(curves[endpoint] == 0, "Curve endpoint already exists or used in the past. Please choose new");
        
        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        require(registry.isProviderInitiated(address(this)), "Provider not intiialized");

        registry.initiateProviderCurve(endpoint, curve, address(this));
        curves[endpoint] = newToken(bytes32ToString(endpoint), bytes32ToString(symbol));
        curves_list.push(endpoint);        
        registry.setProviderParameter(endpoint, toBytes(curves[endpoint]));
        
        DotTokenCreated(curves[endpoint]);
        return curves[endpoint];
    }

     
    function bond(bytes32 endpoint, uint numDots) public  {

        require( status == ContestStatus.Initialized, " contest not live"); 

        bondage = BondageInterface(coord.getContract("BONDAGE"));
        uint256 issued = bondage.getDotsIssued(address(this), endpoint);

        CurrentCostInterface cost = CurrentCostInterface(coord.getContract("CURRENT_COST"));
        uint256 numReserve = cost._costOfNDots(address(this), endpoint, issued + 1, numDots - 1);

        require(
            reserveToken.transferFrom(msg.sender, address(this), numReserve),
            "insufficient accepted token numDots approved for transfer"
        );

        reserveToken.approve(address(bondage), numReserve);
        bondage.bond(address(this), endpoint, numDots);
        FactoryTokenInterface(curves[endpoint]).mint(msg.sender, numDots);
        emit Bonded(endpoint, numDots, msg.sender);
    }

     
    function unbond(bytes32 endpoint, uint numDots) public {

        require( status == ContestStatus.Settled, " contest not settled"); 
        require(redeemed[msg.sender] == 0, "already redeeemed");
        require(winner==endpoint, "only winners can unbond"); 

        bondage = BondageInterface(coord.getContract("BONDAGE"));
        uint issued = bondage.getDotsIssued(address(this), winner);

        currentCost = CurrentCostInterface(coord.getContract("CURRENT_COST"));
        uint reserveCost = currentCost._costOfNDots(address(this), winner, issued + 1 - numDots, numDots - 1);
         
        bondage.unbond(address(this), winner, numDots);

         
        FactoryTokenInterface curveToken = FactoryTokenInterface(curves[winner]);

        uint reward = winValue * FactoryTokenInterface(getTokenAddress(winner)).balanceOf(msg.sender);
        
         
        curveToken.burnFrom(msg.sender, numDots);

        reserveToken.transfer(msg.sender, reward);
        redeemed[msg.sender] = 1;

        emit Unbonded(winner, numDots, msg.sender);
    }

    function newToken(
        string name,
        string symbol
    ) 
        public
        returns (address tokenAddress) 
    {
        FactoryTokenInterface token = tokenFactory.create(name, symbol);
        tokenAddress = address(token);
        return tokenAddress;
    }

    function getTokenAddress(bytes32 endpoint) public view returns(address) {
        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        return bytesToAddr(registry.getProviderParameter(address(this), endpoint));
    }

     
    function toBytes(address x) public pure returns (bytes b) {
        b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    }

     
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        bytesString = abi.encodePacked(x);
        return string(bytesString);
    }

     
    function bytesToAddr (bytes b) public pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
}