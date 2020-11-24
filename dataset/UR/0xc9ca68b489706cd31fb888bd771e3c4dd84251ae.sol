 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
contract ProofBox is Ownable, Pausable {

    struct Device {
      uint index;
      address deviceOwner;
      address txOriginator;

    }

    mapping (bytes32 => Device) private deviceMap;
    mapping (address => bool) public authorized;
    bytes32[] public deviceIds;



    event deviceCreated(bytes32 indexed deviceId, address indexed deviceOwner);
    event txnCreated(bytes32 indexed deviceId, address indexed txnOriginator);
    event deviceProof(bytes32 indexed deviceId, address indexed deviceOwner);
    event deviceTransfer(bytes32 indexed deviceId, address indexed fromOwner, address indexed toOwner);
    event deviceMessage(bytes32 indexed deviceId, address indexed deviceOwner, address indexed txnOriginator, string messageToWrite);
    event deviceDestruct(bytes32 indexed deviceId, address indexed deviceOwner);
    event ipfsHashtoAddress(bytes32 indexed deviceId, address indexed ownerAddress, string ipfskey);



     
    function isDeviceId(bytes32 _deviceId)
       public
       view
       returns(bool isIndeed)
     {
       if(deviceIds.length == 0) return false;
       return (deviceIds[deviceMap[_deviceId].index] == _deviceId);
     }

     
    function getDeviceId(bytes32 _deviceId)
       public
       view
       deviceIdExist(_deviceId)
       returns(uint _index)
     {
       return deviceMap[_deviceId].index;
     }

      
      function getOwnerByDevice(bytes32 _deviceId)
           public
           view
           returns (address deviceOwner){

               return deviceMap[_deviceId].deviceOwner;

      }

       
      function getDevicesByOwner(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
              public
              view
              returns(bytes32[10] memory _deviceIds) {

          address signer = ecrecover(_message, _v, _r, _s);
          uint numDevices;
          bytes32[10] memory devicesByOwner;

          for(uint i = 0; i < deviceIds.length; i++) {

              if(addressEqual(deviceMap[deviceIds[i]].deviceOwner,signer)) {

                  devicesByOwner[numDevices] = deviceIds[i];
                  if (numDevices == 10) {
                    break;
                  }
                  numDevices++;

              }

          }

          return devicesByOwner;
      }

       
      function getDevicesByTxn(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
              public
              view
              returns(bytes32[10] memory _deviceIds) {

          address signer = ecrecover(_message, _v, _r, _s);
          uint numDevices;
          bytes32[10] memory devicesByTxOriginator;

          for(uint i = 0; i < deviceIds.length; i++) {

              if(addressEqual(deviceMap[deviceIds[i]].txOriginator,signer)) {

                  devicesByTxOriginator[numDevices] = deviceIds[i];
                  if (numDevices == 10) {
                    break;
                  }
                  numDevices++;

              }

          }

          return devicesByTxOriginator;
      }


      modifier deviceIdExist(bytes32 _deviceId){
          require(isDeviceId(_deviceId));
          _;
      }

      modifier deviceIdNotExist(bytes32 _deviceId){
          require(!isDeviceId(_deviceId));
          _;
      }

      modifier authorizedUser() {
          require(authorized[msg.sender] == true);
          _;
      }

      constructor() public {

          authorized[msg.sender]=true;
      }


     
    function registerProof (bytes32 _deviceId, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
         public
         whenNotPaused()
         authorizedUser()
         deviceIdNotExist(_deviceId)
         returns(uint index) {

            address signer = ecrecover(_message, _v, _r, _s);

            deviceMap[_deviceId].deviceOwner = signer;
            deviceMap[_deviceId].txOriginator = signer;
            deviceMap[_deviceId].index = deviceIds.push(_deviceId)-1;

            emit deviceCreated(_deviceId, signer);

            return deviceIds.length-1;

    }

     
    function destructProof(bytes32 _deviceId, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
            public
            whenNotPaused()
            authorizedUser()
            deviceIdExist(_deviceId)
            returns(bool success) {

                address signer = ecrecover(_message, _v, _r, _s);

                require(deviceMap[_deviceId].deviceOwner == signer);

                uint rowToDelete = deviceMap[_deviceId].index;
                bytes32 keyToMove = deviceIds[deviceIds.length-1];
                deviceIds[rowToDelete] = keyToMove;
                deviceMap[keyToMove].index = rowToDelete;
                deviceIds.length--;

                emit deviceDestruct(_deviceId, signer);
                return true;

    }

     
    function requestTransfer(bytes32 _deviceId, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
          public
          whenNotPaused()
          deviceIdExist(_deviceId)
          authorizedUser()
          returns(uint index) {

            address signer = ecrecover(_message, _v, _r, _s);

            deviceMap[_deviceId].txOriginator=signer;

            emit txnCreated(_deviceId, signer);

            return deviceMap[_deviceId].index;

    }

     
    function approveTransfer (bytes32 _deviceId, address newOwner, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
            public
            whenNotPaused()
            deviceIdExist(_deviceId)
            authorizedUser()
            returns(bool) {

                address signer = ecrecover(_message, _v, _r, _s);

                require(deviceMap[_deviceId].deviceOwner == signer);
                require(deviceMap[_deviceId].txOriginator == newOwner);

                deviceMap[_deviceId].deviceOwner=newOwner;

                emit deviceTransfer(_deviceId, signer, deviceMap[_deviceId].deviceOwner);

                return true;

    }

     
    function writeMessage (bytes32 _deviceId, string memory messageToWrite, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
            public
            whenNotPaused()
            deviceIdExist(_deviceId)
            authorizedUser()
            returns(bool) {
                address signer = ecrecover(_message, _v, _r, _s);
                require(deviceMap[_deviceId].deviceOwner == signer);
                emit deviceMessage(_deviceId, deviceMap[_deviceId].deviceOwner, signer, messageToWrite);

                return true;

    }

     
     function requestProof(bytes32 _deviceId, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
         public
         whenNotPaused()
         deviceIdExist(_deviceId)
         authorizedUser()
         returns(uint _index) {

             address signer = ecrecover(_message, _v, _r, _s);

             deviceMap[_deviceId].txOriginator=signer;

             emit txnCreated(_deviceId, signer);

             return deviceMap[_deviceId].index;
     }


      
     function approveProof(bytes32 _deviceId, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s)
             public
             whenNotPaused()
             deviceIdExist(_deviceId)
             authorizedUser()
             returns(bool) {

                  address signer = ecrecover(_message, _v, _r, _s);
                  deviceMap[_deviceId].txOriginator=signer;
                  require(deviceMap[_deviceId].deviceOwner == signer);

                  emit deviceProof(_deviceId, signer);
                  return true;
     }

      
     function emitipfskey(bytes32 _deviceId, address ownerAddress, string memory ipfskey)
              public
              whenNotPaused()
              deviceIdExist(_deviceId)
              authorizedUser() {
        emit ipfsHashtoAddress(_deviceId, ownerAddress, ipfskey);
    }

     
    function changeAuthStatus(address target, bool isAuthorized)
            public
            whenNotPaused()
            onlyOwner() {

              authorized[target] = isAuthorized;
    }

     
    function changeAuthStatuses(address[] memory targets, bool isAuthorized)
            public
            whenNotPaused()
            onlyOwner() {
              for (uint i = 0; i < targets.length; i++) {
                changeAuthStatus(targets[i], isAuthorized);
              }
    }

     

     

     
    function bytesEqual(bytes32 a, bytes32 b) private pure returns (bool) {
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
     }

    
   function addressEqual(address a, address b) private pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

}