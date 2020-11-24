 

pragma solidity ^0.5.0;


 
contract Spawn {
  constructor(
    address logicContract,
    bytes memory initializationCalldata
  ) public payable {
     
    (bool ok, ) = logicContract.delegatecall(initializationCalldata);
    if (!ok) {
       
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    bytes memory runtimeCode = abi.encodePacked(
      bytes10(0x363d3d373d3d3d363d73),
      logicContract,
      bytes15(0x5af43d82803e903d91602b57fd5bf3)
    );

     
    assembly {
      return(add(0x20, runtimeCode), 45)  
    }
  }
}

 
contract Spawner {
   
  function _spawn(
    address logicContract,
    bytes memory initializationCalldata
  ) internal returns (address spawnedContract) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

     
    spawnedContract = _spawnCreate2(initCode);
  }

   
  function _computeNextAddress(
    address logicContract,
    bytes memory initializationCalldata
  ) internal view returns (address target) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

     
    (, target) = _getSaltAndTarget(initCode);
  }


   
  function _spawnCreate2(
    bytes memory initCode
  ) private returns (address spawnedContract) {
     
    (bytes32 salt, ) = _getSaltAndTarget(initCode);

    assembly {
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      spawnedContract := create2(              
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )

       
      if iszero(spawnedContract) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

   
  function _getSaltAndTarget(
    bytes memory initCode
  ) private view returns (bytes32 salt, address target) {
     
    bytes32 initCodeHash = keccak256(initCode);

     
    uint256 nonce = 0;

     
    uint256 codeSize;

    while (true) {
       
      salt = keccak256(abi.encodePacked(msg.sender, nonce));

      target = address(     
        uint160(                    
          uint256(                  
            keccak256(              
              abi.encodePacked(     
                bytes1(0xff),       
                address(this),      
                salt,               
                initCodeHash        
              )
            )
          )
        )
      );

       
      assembly { codeSize := extcodesize(target) }

       
      if (codeSize == 0) {
        break;
      }

       
      nonce++;
    }
  }
}


interface iRegistry {

    enum FactoryStatus { Unregistered, Registered, Retired }

    event FactoryAdded(address owner, address factory, uint256 factoryID, bytes extraData);
    event FactoryRetired(address owner, address factory, uint256 factoryID);
    event InstanceRegistered(address instance, uint256 instanceIndex, address indexed creator, address indexed factory, uint256 indexed factoryID);

     

    function addFactory(address factory, bytes calldata extraData ) external;
    function retireFactory(address factory) external;

     

    function getFactoryCount() external view returns (uint256 count);
    function getFactoryStatus(address factory) external view returns (FactoryStatus status);
    function getFactoryID(address factory) external view returns (uint16 factoryID);
    function getFactoryData(address factory) external view returns (bytes memory extraData);
    function getFactoryAddress(uint16 factoryID) external view returns (address factory);
    function getFactory(address factory) external view returns (FactoryStatus state, uint16 factoryID, bytes memory extraData);
    function getFactories() external view returns (address[] memory factories);
    function getPaginatedFactories(uint256 startIndex, uint256 endIndex) external view returns (address[] memory factories);

     

    function register(address instance, address creator, uint80 extraData) external;

     

    function getInstanceType() external view returns (bytes4 instanceType);
    function getInstanceCount() external view returns (uint256 count);
    function getInstance(uint256 index) external view returns (address instance);
    function getInstances() external view returns (address[] memory instances);
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
}



contract Metadata {

    bytes private _staticMetadata;
    bytes private _variableMetadata;

    event StaticMetadataSet(bytes staticMetadata);
    event VariableMetadataSet(bytes variableMetadata);

     

    function _setStaticMetadata(bytes memory staticMetadata) internal {
        require(_staticMetadata.length == 0, "static metadata cannot be changed");
        _staticMetadata = staticMetadata;
        emit StaticMetadataSet(staticMetadata);
    }

    function _setVariableMetadata(bytes memory variableMetadata) internal {
        _variableMetadata = variableMetadata;
        emit VariableMetadataSet(variableMetadata);
    }

     

    function getMetadata() public view returns (bytes memory staticMetadata, bytes memory variableMetadata) {
        staticMetadata = _staticMetadata;
        variableMetadata = _variableMetadata;
    }
}



contract Operated {

    address private _operator;
    bool private _status;

    event OperatorUpdated(address operator, bool status);

     

    function _setOperator(address operator) internal {
        require(_operator != operator, "cannot set same operator");
        _operator = operator;
        emit OperatorUpdated(operator, hasActiveOperator());
    }

    function _transferOperator(address operator) internal {
         
        require(_operator != address(0), "operator not set");
        _setOperator(operator);
    }

    function _renounceOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _operator = address(0);
        _status = false;
        emit OperatorUpdated(address(0), false);
    }

    function _activateOperator() internal {
        require(!hasActiveOperator(), "only when operator not active");
        _status = true;
        emit OperatorUpdated(_operator, true);
    }

    function _deactivateOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _status = false;
        emit OperatorUpdated(_operator, false);
    }

     

    function getOperator() public view returns (address operator) {
        operator = _operator;
    }

    function isOperator(address caller) public view returns (bool ok) {
        return (caller == getOperator());
    }

    function hasActiveOperator() public view returns (bool ok) {
        return _status;
    }

    function isActiveOperator(address caller) public view returns (bool ok) {
        return (isOperator(caller) && hasActiveOperator());
    }

}


 
 interface iFactory {

     event InstanceCreated(address indexed instance, address indexed creator, string initABI, bytes initData);

     function create(bytes calldata initData) external returns (address instance);
     function getInitdataABI() external view returns (string memory initABI);
     function getInstanceRegistry() external view returns (address instanceRegistry);
     function getTemplate() external view returns (address template);

     function getInstanceCreator(address instance) external view returns (address creator);
     function getInstanceType() external view returns (bytes4 instanceType);
     function getInstanceCount() external view returns (uint256 count);
     function getInstance(uint256 index) external view returns (address instance);
     function getInstances() external view returns (address[] memory instances);
     function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
 }



 
contract MultiHashWrapper {

     
    struct MultiHash {
        bytes32 hash;
        uint8 hashFunction;
        uint8 digestSize;
    }

     
    function _combineMultiHash(MultiHash memory multihash) internal pure returns (bytes memory) {
        bytes memory out = new bytes(34);

        out[0] = byte(multihash.hashFunction);
        out[1] = byte(multihash.digestSize);

        uint8 i;
        for (i = 0; i < 32; i++) {
          out[i+2] = multihash.hash[i];
        }

        return out;
    }

     
    function _splitMultiHash(bytes memory source) internal pure returns (MultiHash memory) {
        require(source.length == 34, "length of source must be 34");

        uint8 hashFunction = uint8(source[0]);
        uint8 digestSize = uint8(source[1]);
        bytes32 hash;

        assembly {
          hash := mload(add(source, 34))
        }

        return (MultiHash({
          hashFunction: hashFunction,
          digestSize: digestSize,
          hash: hash
        }));
    }
}




contract Factory is Spawner {

    address[] private _instances;
    mapping (address => address) private _instanceCreator;

     
    address private _templateContract;
    string private _initdataABI;
    address private _instanceRegistry;
    bytes4 private _instanceType;

    event InstanceCreated(address indexed instance, address indexed creator, bytes callData);

    function _initialize(address instanceRegistry, address templateContract, bytes4 instanceType, string memory initdataABI) internal {
         
        _instanceRegistry = instanceRegistry;
         
        _templateContract = templateContract;
         
        _initdataABI = initdataABI;
         
        require(instanceType == iRegistry(instanceRegistry).getInstanceType(), 'incorrect instance type');
         
        _instanceType = instanceType;
    }

     

    function _create(bytes memory callData) internal returns (address instance) {
         
        instance = Spawner._spawn(getTemplate(), callData);
         
        _instances.push(instance);
         
        _instanceCreator[instance] = msg.sender;
         
        iRegistry(getInstanceRegistry()).register(instance, msg.sender, uint64(0));
         
        emit InstanceCreated(instance, msg.sender, callData);
    }

    function getInstanceCreator(address instance) public view returns (address creator) {
        creator = _instanceCreator[instance];
    }

    function getInstanceType() public view returns (bytes4 instanceType) {
        instanceType = _instanceType;
    }

    function getInitdataABI() public view returns (string memory initdataABI) {
        initdataABI = _initdataABI;
    }

    function getInstanceRegistry() public view returns (address instanceRegistry) {
        instanceRegistry = _instanceRegistry;
    }

    function getTemplate() public view returns (address template) {
        template = _templateContract;
    }

    function getInstanceCount() public view returns (uint256 count) {
        count = _instances.length;
    }

    function getInstance(uint256 index) public view returns (address instance) {
        require(index < _instances.length, "index out of range");
        instance = _instances[index];
    }

    function getInstances() public view returns (address[] memory instances) {
        instances = _instances;
    }

     
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) public view returns (address[] memory instances) {
        require(startIndex < endIndex, "startIndex must be less than endIndex");
        require(endIndex <= _instances.length, "end index out of range");

         
        address[] memory range = new address[](endIndex - startIndex);

         
        for (uint256 i = startIndex; i < endIndex; i++) {
            range[i - startIndex] = _instances[i];
        }

         
        instances = range;
    }

}



contract Template {

    address private _factory;

     

    modifier initializeTemplate() {
         
        _factory = msg.sender;

         
        uint32 codeSize;
        assembly { codeSize := extcodesize(address) }
        require(codeSize == 0, "must be called within contract constructor");
        _;
    }

     

    function getCreator() public view returns (address creator) {
         
        creator = iFactory(_factory).getInstanceCreator(address(this));
    }

    function isCreator(address caller) public view returns (bool ok) {
        ok = (caller == getCreator());
    }

}



contract ProofHash is MultiHashWrapper {

    MultiHash private _proofHash;

    event ProofHashSet(address caller, bytes proofHash);

     

    function _setProofHash(bytes memory proofHash) internal {
        _proofHash = MultiHashWrapper._splitMultiHash(proofHash);
        emit ProofHashSet(msg.sender, proofHash);
    }

     

    function getProofHash() public view returns (bytes memory proofHash) {
        proofHash = MultiHashWrapper._combineMultiHash(_proofHash);
    }

}






contract Post is ProofHash, Operated, Metadata, Template {

    event Created(address operator, bytes proofHash, bytes staticMetadata, bytes variableMetadata);

    function initialize(
        address operator,
        bytes memory proofHash,
        bytes memory staticMetadata,
        bytes memory variableMetadata
    ) public initializeTemplate() {
         
        ProofHash._setProofHash(proofHash);

         
        if (operator != address(0)) {
            Operated._setOperator(operator);
            Operated._activateOperator();
        }

         
        Metadata._setStaticMetadata(staticMetadata);

         
        Metadata._setVariableMetadata(variableMetadata);

         
        emit Created(operator, proofHash, staticMetadata, variableMetadata);
    }

     

    function setVariableMetadata(bytes memory variableMetadata) public {
         
        require(Template.isCreator(msg.sender) || Operated.isActiveOperator(msg.sender), "only active operator or creator");

         
        Metadata._setVariableMetadata(variableMetadata);
    }

}




contract Post_Factory is Factory {

    constructor(address instanceRegistry) public {
         
        address templateContract = address(new Post());
         
        bytes4 instanceType = bytes4(keccak256(bytes('Post')));
         
        string memory initdataABI = '(address,bytes,bytes,bytes)';
         
        Factory._initialize(instanceRegistry, templateContract, instanceType, initdataABI);
    }

    event ExplicitInitData(address operator, bytes proofHash, bytes staticMetadata, bytes variableMetadata);

    function create(bytes memory callData) public returns (address instance) {
         
        instance = Factory._create(callData);
    }

    function createEncoded(bytes memory initdata) public returns (address instance) {
         
        (
            address operator,
            bytes memory proofHash,
            bytes memory staticMetadata,
            bytes memory variableMetadata
        ) = abi.decode(initdata, (address,bytes,bytes,bytes));

         
        instance = createExplicit(operator, proofHash, staticMetadata, variableMetadata);
    }

    function createExplicit(
        address operator,
        bytes memory proofHash,
        bytes memory staticMetadata,
        bytes memory variableMetadata
    ) public returns (address instance) {
         
        Post template;

         
        bytes memory callData = abi.encodeWithSelector(
            template.initialize.selector,  
            operator,
            proofHash,
            staticMetadata,
            variableMetadata
        );

         
        instance = Factory._create(callData);

         
        emit ExplicitInitData(operator, proofHash, staticMetadata, variableMetadata);
    }

}







contract Feed is Operated, Metadata, Template {

    address[] private _posts;
    address private _postRegistry;

    event PostCreated(address post, address postFactory, bytes initData);

    function initialize(
        address operator,
        address postRegistry,
        bytes memory feedStaticMetadata
    ) public initializeTemplate() {
         
        if (operator != address(0)) {
            Operated._setOperator(operator);
            Operated._activateOperator();
        }

         
        _postRegistry = postRegistry;

         
        Metadata._setStaticMetadata(feedStaticMetadata);
    }

     

    function createPost(address postFactory, bytes memory initData) public returns (address post) {
         
        require(Template.isCreator(msg.sender) || Operated.isActiveOperator(msg.sender), "only active operator or creator");

         
        require(
            iRegistry(_postRegistry).getFactoryStatus(postFactory) == iRegistry.FactoryStatus.Registered,
            "factory is not actively registered"
        );

         
        post = Post_Factory(postFactory).createEncoded(initData);

         
        _posts.push(post);

         
        emit PostCreated(post, postFactory, initData);
    }

    function setFeedVariableMetadata(bytes memory feedVariableMetadata) public {
         
        require(Template.isCreator(msg.sender) || Operated.isActiveOperator(msg.sender), "only active operator or creator");

        Metadata._setVariableMetadata(feedVariableMetadata);
    }

    function setPostVariableMetadata(address post, bytes memory postVariableMetadata) public {
         
        require(Template.isCreator(msg.sender) || Operated.isActiveOperator(msg.sender), "only active operator or creator");

        Post(post).setVariableMetadata(postVariableMetadata);
    }

     

    function getPosts() public view returns (address[] memory posts) {
        posts = _posts;
    }

    function getPostRegistry() public view returns (address postRegistry) {
        postRegistry = _postRegistry;
    }

}




contract Feed_Factory is Factory {

    constructor(address instanceRegistry) public {
         
        address templateContract = address(new Feed());
         
        bytes4 instanceType = bytes4(keccak256(bytes('Post')));
         
        string memory initdataABI = '(address,address,bytes)';
         
        Factory._initialize(instanceRegistry, templateContract, instanceType, initdataABI);
    }

    event ExplicitInitData(address operator, address postRegistry, bytes feedStaticMetadata);

    function create(bytes memory callData) public returns (address instance) {
         
        instance = Factory._create(callData);
    }

    function createEncoded(bytes memory initdata) public returns (address instance) {
         
        (
            address operator,
            address postRegistry,
            bytes memory feedStaticMetadata
        ) = abi.decode(initdata, (address,address,bytes));

         
        instance = createExplicit(operator, postRegistry, feedStaticMetadata);
    }

    function createExplicit(
        address operator,
        address postRegistry,
        bytes memory feedStaticMetadata
    ) public returns (address instance) {
         
        Feed template;

         
        bytes memory callData = abi.encodeWithSelector(
            template.initialize.selector,  
            operator,
            postRegistry,
            feedStaticMetadata
        );

         
        instance = Factory._create(callData);

         
        emit ExplicitInitData(operator, postRegistry, feedStaticMetadata);
    }

}