 

pragma solidity ^0.4.23;

interface StorageInterface {
  function getTarget(bytes32 exec_id, bytes4 selector)
      external view returns (address implementation);
  function getIndex(bytes32 exec_id) external view returns (address index);
  function createInstance(address sender, bytes32 app_name, address provider, bytes32 registry_exec_id, bytes calldata)
      external payable returns (bytes32 instance_exec_id, bytes32 version);
  function createRegistry(address index, address implementation) external returns (bytes32 exec_id);
  function exec(address sender, bytes32 exec_id, bytes calldata)
      external payable returns (uint emitted, uint paid, uint stored);
}

interface RegistryInterface {
  function getLatestVersion(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name)
      external view returns (bytes32 latest_name);
  function getVersionImplementation(address stor_addr, bytes32 exec_id, address provider, bytes32 app_name, bytes32 version_name)
      external view returns (address index, bytes4[] selectors, address[] implementations);
}

contract ScriptExec {

   

  address public app_storage;
  address public provider;
  bytes32 public registry_exec_id;
  address public exec_admin;

   

  struct Instance {
    address current_provider;
    bytes32 current_registry_exec_id;
    bytes32 app_exec_id;
    bytes32 app_name;
    bytes32 version_name;
  }

   
  mapping (bytes32 => address) public deployed_by;
   
  mapping (bytes32 => Instance) public instance_info;
   
  mapping (address => Instance[]) public deployed_instances;
   
  mapping (bytes32 => bytes32[]) public app_instances;

   

  event AppInstanceCreated(address indexed creator, bytes32 indexed execution_id, bytes32 app_name, bytes32 version_name);
  event StorageException(bytes32 indexed execution_id, string message);

   
  modifier onlyAdmin() {
    require(msg.sender == exec_admin);
    _;
  }

   
  function () public payable { }

   
  function configure(address _exec_admin, address _app_storage, address _provider) public {
    require(app_storage == 0, "ScriptExec already configured");
    require(_app_storage != 0, 'Invalid input');
    exec_admin = _exec_admin;
    app_storage = _app_storage;
    provider = _provider;

    if (exec_admin == 0)
      exec_admin = msg.sender;
  }

   

  bytes4 internal constant EXEC_SEL = bytes4(keccak256('exec(address,bytes32,bytes)'));

   
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success);

  bytes4 internal constant ERR = bytes4(keccak256('Error(string)'));

   
  function getAction(uint _ptr) internal pure returns (bytes4 action) {
    assembly {
       
      action := and(mload(_ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }
  }

   
  function checkErrors(bytes32 _exec_id) internal {
     
    string memory message;
    bytes4 err_sel = ERR;
    assembly {
       
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, returndatasize)
      mstore(0x40, add(ptr, returndatasize))

       
      if eq(mload(ptr), and(err_sel, 0xffffffff00000000000000000000000000000000000000000000000000000000)) {
        message := add(0x24, ptr)
      }
    }
     
    if (bytes(message).length == 0)
      emit StorageException(_exec_id, "No error recieved");
    else
      emit StorageException(_exec_id, message);
  }

   
  function checkReturn() internal pure returns (bool success) {
    success = false;
    assembly {
       
      if eq(returndatasize, 0x60) {
         
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, returndatasize)
        if iszero(iszero(mload(ptr))) { success := 1 }
        if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
        if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
      }
    }
    return success;
  }

   

   
  function createAppInstance(bytes32 _app_name, bytes _init_calldata) external returns (bytes32 exec_id, bytes32 version) {
    require(_app_name != 0 && _init_calldata.length >= 4, 'invalid input');
    (exec_id, version) = StorageInterface(app_storage).createInstance(
      msg.sender, _app_name, provider, registry_exec_id, _init_calldata
    );
     
    deployed_by[exec_id] = msg.sender;
    app_instances[_app_name].push(exec_id);
    Instance memory inst = Instance(
      provider, registry_exec_id, exec_id, _app_name, version
    );
    instance_info[exec_id] = inst;
    deployed_instances[msg.sender].push(inst);
     
    emit AppInstanceCreated(msg.sender, exec_id, _app_name, version);
  }

   

   
  function setRegistryExecID(bytes32 _exec_id) public onlyAdmin() {
    registry_exec_id = _exec_id;
  }

   
  function setProvider(address _provider) public onlyAdmin() {
    provider = _provider;
  }

   
  function setAdmin(address _admin) public onlyAdmin() {
    require(_admin != 0);
    exec_admin = _admin;
  }

   

   
  function getInstances(bytes32 _app_name) public view returns (bytes32[] memory) {
    return app_instances[_app_name];
  }

   
  function getDeployedLength(address _deployer) public view returns (uint) {
    return deployed_instances[_deployer].length;
  }

   
  bytes4 internal constant REGISTER_APP_SEL = bytes4(keccak256('registerApp(bytes32,address,bytes4[],address[])'));

   
  function getRegistryImplementation() public view returns (address index, address implementation) {
    index = StorageInterface(app_storage).getIndex(registry_exec_id);
    implementation = StorageInterface(app_storage).getTarget(registry_exec_id, REGISTER_APP_SEL);
  }

   
  function getInstanceImplementation(bytes32 _exec_id) public view
  returns (address index, bytes4[] memory functions, address[] memory implementations) {
    Instance memory app = instance_info[_exec_id];
    index = StorageInterface(app_storage).getIndex(app.current_registry_exec_id);
    (index, functions, implementations) = RegistryInterface(index).getVersionImplementation(
      app_storage, app.current_registry_exec_id, app.current_provider, app.app_name, app.version_name
    );
  }
}

contract RegistryExec is ScriptExec {

  struct Registry {
    address index;
    address implementation;
  }

   
  mapping (bytes32 => Registry) public registry_instance_info;
   
  mapping (address => Registry[]) public deployed_registry_instances;

   

  event RegistryInstanceCreated(address indexed creator, bytes32 indexed execution_id, address index, address implementation);

   

  bytes4 internal constant EXEC_SEL = bytes4(keccak256('exec(address,bytes32,bytes)'));

   
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success) {
     
    bytes4 sel = getSelector(_calldata);
     
    require(
      sel != this.registerApp.selector &&
      sel != this.registerAppVersion.selector &&
      sel != UPDATE_INST_SEL &&
      sel != UPDATE_EXEC_SEL
    );

     
    if (address(app_storage).call.value(msg.value)(abi.encodeWithSelector(
      EXEC_SEL, msg.sender, _exec_id, _calldata
    )) == false) {
       
      checkErrors(_exec_id);
       
      address(msg.sender).transfer(address(this).balance);
      return false;
    }

     
    success = checkReturn();
     
    require(success, 'Execution failed');

     
    address(msg.sender).transfer(address(this).balance);
  }

   
  function getSelector(bytes memory _calldata) internal pure returns (bytes4 selector) {
    assembly {
      selector := and(
        mload(add(0x20, _calldata)),
        0xffffffff00000000000000000000000000000000000000000000000000000000
      )
    }
  }

   

   
  function createRegistryInstance(address _index, address _implementation) external onlyAdmin() returns (bytes32 exec_id) {
     
    require(_index != 0 && _implementation != 0, 'Invalid input');

     
    exec_id = StorageInterface(app_storage).createRegistry(_index, _implementation);

     
    require(exec_id != 0, 'Invalid response from storage');

     
    if (registry_exec_id == 0)
      registry_exec_id = exec_id;

     
    Registry memory reg = Registry(_index, _implementation);

     
    deployed_by[exec_id] = msg.sender;
    registry_instance_info[exec_id] = reg;
    deployed_registry_instances[msg.sender].push(reg);
     
    emit RegistryInstanceCreated(msg.sender, exec_id, _index, _implementation);
  }

   
  function registerApp(bytes32 _app_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
     
    require(_app_name != 0 && _index != 0, 'Invalid input');
    require(_selectors.length == _implementations.length && _selectors.length != 0, 'Invalid input');
     
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, 'Invalid state');

     
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

     
    require(emitted == 0 && paid == 0 && stored != 0, 'Invalid state change');
  }

   
  function registerAppVersion(bytes32 _app_name, bytes32 _version_name, address _index, bytes4[] _selectors, address[] _implementations) external onlyAdmin() {
     
    require(_app_name != 0 && _version_name != 0 && _index != 0, 'Invalid input');
    require(_selectors.length == _implementations.length && _selectors.length != 0, 'Invalid input');
     
    require(app_storage != 0 && registry_exec_id != 0 && provider != 0, 'Invalid state');

     
    uint emitted;
    uint paid;
    uint stored;
    (emitted, paid, stored) = StorageInterface(app_storage).exec(msg.sender, registry_exec_id, msg.data);

     
    require(emitted == 0 && paid == 0 && stored != 0, 'Invalid state change');
  }

   
  bytes4 internal constant UPDATE_INST_SEL = bytes4(keccak256('updateInstance(bytes32,bytes32,bytes32)'));

   
  function updateAppInstance(bytes32 _exec_id) external returns (bool success) {
     
    require(_exec_id != 0 && msg.sender == deployed_by[_exec_id], 'invalid sender or input');

     
    Instance memory inst = instance_info[_exec_id];

     
     
    if(address(app_storage).call(
      abi.encodeWithSelector(EXEC_SEL,             
        inst.current_provider,                     
        _exec_id,                                  
        abi.encodeWithSelector(UPDATE_INST_SEL,    
          inst.app_name,                           
          inst.version_name,                       
          inst.current_registry_exec_id            
        )
      )
    ) == false) {
       
      checkErrors(_exec_id);
      return false;
    }
     
    success = checkReturn();
     
    require(success, 'Execution failed');

     
     
    address registry_idx = StorageInterface(app_storage).getIndex(inst.current_registry_exec_id);
    bytes32 latest_version  = RegistryInterface(registry_idx).getLatestVersion(
      app_storage,
      inst.current_registry_exec_id,
      inst.current_provider,
      inst.app_name
    );
     
    require(latest_version != 0, 'invalid latest version');
     
    instance_info[_exec_id].version_name = latest_version;
  }

   
  bytes4 internal constant UPDATE_EXEC_SEL = bytes4(keccak256('updateExec(address)'));

   
  function updateAppExec(bytes32 _exec_id, address _new_exec_addr) external returns (bool success) {
     
    require(_exec_id != 0 && msg.sender == deployed_by[_exec_id] && address(this) != _new_exec_addr && _new_exec_addr != 0, 'invalid input');

     
     
    if(address(app_storage).call(
      abi.encodeWithSelector(EXEC_SEL,                             
        msg.sender,                                                
        _exec_id,                                                  
        abi.encodeWithSelector(UPDATE_EXEC_SEL, _new_exec_addr)    
      )
    ) == false) {
       
      checkErrors(_exec_id);
      return false;
    }
     
    success = checkReturn();
     
    require(success, 'Execution failed');
  }
}