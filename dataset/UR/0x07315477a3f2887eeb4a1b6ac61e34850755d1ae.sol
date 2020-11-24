 

 
 
 
 

contract Registrar {
    address public registrar;

     
    event Created(address indexed registrant, address registrar, bytes data);

     
    event Updated(address indexed registrant, address registrar, bytes data, bool active);

     
    event Error(uint code);

    struct Registrant {
        address addr;
        bytes data;
        bool active;
    }

    mapping(address => uint) public registrantIndex;
    Registrant[] public registrants;

     
    modifier noEther() {
        if (msg.value > 0) throw;
        _
    }

    modifier isRegistrar() {
      if (msg.sender != registrar) {
        Error(1);
        return;
      }
      else {
        _
      }
    }

     
    function Registrar() {
        registrar = msg.sender;
        registrants.length++;
    }

     
    function add(address _registrant, bytes _data) isRegistrar noEther returns (bool) {
        if (registrantIndex[_registrant] > 0) {
            Error(2);  
            return false;
        }
        uint pos = registrants.length++;
        registrants[pos] = Registrant(_registrant, _data, true);
        registrantIndex[_registrant] = pos;
        Created(_registrant, msg.sender, _data);
        return true;
    }

     
    function edit(address _registrant, bytes _data, bool _active) isRegistrar noEther returns (bool) {
        if (registrantIndex[_registrant] == 0) {
            Error(3);  
            return false;
        }
        Registrant registrant = registrants[registrantIndex[_registrant]];
        registrant.data = _data;
        registrant.active = _active;
        Updated(_registrant, msg.sender, _data, _active);
        return true;
    }

     
    function setNextRegistrar(address _registrar) isRegistrar noEther returns (bool) {
        registrar = _registrar;
        return true;
    }

     
    function isActiveRegistrant(address _registrant) constant returns (bool) {
        uint pos = registrantIndex[_registrant];
        return (pos > 0 && registrants[pos].active);
    }

     
    function getRegistrants() constant returns (address[]) {
        address[] memory result = new address[](registrants.length-1);
        for (uint j = 1; j < registrants.length; j++) {
            result[j-1] = registrants[j].addr;
        }
        return result;
    }

     
    function () noEther {}

     
    function discontinue() isRegistrar noEther {
      selfdestruct(msg.sender);
    }
}


contract Registry {
     
    address public registrarAddress;
     
    address public deployerAddress;

     
    event Created(bytes32[] ids, address indexed owner);

     
    event Updated(bytes32[] ids, address indexed owner, bool isValid);

     
    event Deleted(bytes32[] ids, address indexed owner);

     
    event Error(uint code, bytes32[] reference);

    struct Thing {
       
      bytes32[] identities;
       
      bytes32[] data;
       
      address ownerAddress;
       
      uint88 schemaIndex;
       
      bool isValid;
    }

     
    Thing[] public things;

     
    mapping(bytes32 => uint) public idToThing;

     
    bytes[] public schemas;

     
    modifier noEther() {
        if (msg.value > 0) throw;
        _
    }

     
    modifier isRegistrant() {
        Registrar registrar = Registrar(registrarAddress);
        if (registrar.isActiveRegistrant(msg.sender)) {
            _
        }
    }

     
    modifier isRegistrar() {
        Registrar registrar = Registrar(registrarAddress);
        if (registrar.registrar() == msg.sender) {
            _
        }
    }

     
    function Registry() {
         
        things.length++;
        schemas.length++;
        deployerAddress = msg.sender;
    }

     
    function _addIdentities(uint _thingIndex, bytes32[] _ids) internal returns(bool){
         
        if (false == _rewireIdentities(_ids, 0, _thingIndex, 0)) {
            return false;
        }

         
        if (things[_thingIndex].identities.length == 0) {
             
            things[_thingIndex].identities = _ids;
        }
        else {
             
             
            uint32 cell = uint32(things[_thingIndex].identities.length);
             
            things[_thingIndex].identities.length += _ids.length;
             
            for (uint32 k = 0; k < _ids.length; k++) {
                things[_thingIndex].identities[cell++] = _ids[k];
            }
        }
        return true;
    }

     
    function _rewireIdentities(bytes32[] _ids, uint _oldIndex, uint _newIndex, uint32 _idsForcedLength) internal returns(bool) {
         
        uint32 cell = 0;
         
        uint16 urnNamespaceLength;
         
        uint24 idLength;
         
        uint24 cellsPerId;
         
        bytes32 idHash;
         
        uint8 lastCellBytesCnt;
         
        uint32 idsLength = _idsForcedLength > 0 ? _idsForcedLength : uint32(_ids.length);

         
        if (idsLength == 0) {
            Error(5, _ids);
            return false;
        }

         
        while (cell < idsLength) {
             
             
            urnNamespaceLength = uint8(_ids[cell][0]);
             
            idLength =
                 
                uint16(_ids[cell + (urnNamespaceLength + 1) / 32][(urnNamespaceLength + 1) % 32]) * 2 ** 8 |
                 
                uint8(_ids[cell + (urnNamespaceLength + 2) / 32][(urnNamespaceLength + 2) % 32]);

             
            if (_oldIndex == 0 && (urnNamespaceLength == 0 || idLength == 0)) {
                 
                Error(7, _ids);

                 
                if (cell > 0 && _idsForcedLength == 0) {
                    _rewireIdentities(_ids, _newIndex, _oldIndex, cell);  
                }
                return false;
            }

             
            cellsPerId = (idLength + urnNamespaceLength + 3) / 32;
            if ((idLength + urnNamespaceLength + 3) % 32 != 0) {
                 
                cellsPerId++;
                 
                 
                if (_oldIndex == 0) {
                     
                    lastCellBytesCnt = uint8((idLength + urnNamespaceLength + 3) % 32);

                     
                    if (uint256(_ids[cell + cellsPerId - 1]) * (uint256(2) ** (lastCellBytesCnt * 8)) > 0) {   
                         
                        Error(8, _ids);
                         
                        if (cell > 0 && _idsForcedLength == 0) {
                            _rewireIdentities(_ids, _newIndex, _oldIndex, cell);  
                        }
                        return false;
                    }
                }
            }

             
            bytes32[] memory id = new bytes32[](cellsPerId);

            for (uint8 j = 0; j < cellsPerId; j++) {
                id[j] = _ids[cell++];
            }

             
            idHash = sha3(id);

             
            if (idToThing[idHash] == _oldIndex) {
                 
                idToThing[idHash] = _newIndex;
            } else {
                 
                Error(1, _ids);
                 
                if (cell - cellsPerId > 0 && _idsForcedLength == 0) {
                    _rewireIdentities(_ids, _newIndex, _oldIndex, cell - cellsPerId);  
                }
                return false;
            }
        }

        return true;
    }


     
     
     


     
    function configure(address _registrarAddress) noEther returns(bool) {
         
        bytes32[] memory ref = new bytes32[](1);
        ref[0] = bytes32(registrarAddress);

        if (msg.sender != deployerAddress) {
            Error(3, ref);
            return false;
        }

        if (registrarAddress != 0x0) {
            Error(9, ref);
            return false;
        }

        registrarAddress = _registrarAddress;
        return true;
    }

     
    function createThing(bytes32[] _ids, bytes32[] _data, uint88 _schemaIndex) isRegistrant returns(bool) {
         
        if (_data.length == 0) {
            Error(6, _ids);
            return false;
        }

        if (_schemaIndex >= schemas.length || _schemaIndex == 0) {
            Error(4, _ids);
            return false;
        }

         
         
         
        if (false == _rewireIdentities(_ids, 0, things.length, 0)) {
             
            return false;
        }

         
        things.length++;
         
         
        things[things.length - 1] = Thing(_ids, _data, msg.sender, _schemaIndex, true);

         
        Created(_ids, msg.sender);
        return true;
    }

     
    function createThings(bytes32[] _ids, uint16[] _idsPerThing, bytes32[] _data, uint16[] _dataLength, uint88 _schemaIndex) isRegistrant noEther  {
         
        uint16 idIndex = 0;
         
        uint16 dataIndex = 0;
         
        uint24 idCellsPerThing = 0;
         
        uint16 urnNamespaceLength;
         
        uint24 idLength;

         
        for (uint16 i = 0; i < _idsPerThing.length; i++) {
             
            idCellsPerThing = 0;
             
            for (uint16 j = 0; j < _idsPerThing[i]; j++) {
                urnNamespaceLength = uint8(_ids[idIndex + idCellsPerThing][0]);
                idLength =
                     
                    uint16(_ids[idIndex + idCellsPerThing + (urnNamespaceLength + 1) / 32][(urnNamespaceLength + 1) % 32]) * 2 ** 8 |
                     
                    uint8(_ids[idIndex + idCellsPerThing + (urnNamespaceLength + 2) / 32][(urnNamespaceLength + 2) % 32]);

                idCellsPerThing += (idLength + urnNamespaceLength + 3) / 32;
                if ((idLength + urnNamespaceLength + 3) % 32 != 0) {
                    idCellsPerThing++;
                }
            }

             
            bytes32[] memory ids = new bytes32[](idCellsPerThing);
             
            for (j = 0; j < idCellsPerThing; j++) {
                ids[j] = _ids[idIndex++];
            }

            bytes32[] memory data = new bytes32[](_dataLength[i]);
            for (j = 0; j < _dataLength[i]; j++) {
                data[j] = _data[dataIndex++];
            }

            createThing(ids, data, _schemaIndex);
        }
    }

     
    function addIdentities(bytes32[] _id, bytes32[] _newIds) isRegistrant noEther returns(bool) {
        var index = idToThing[sha3(_id)];

         
        if (index == 0) {
            Error(2, _id);
            return false;
        }

        if (_newIds.length == 0) {
            Error(5, _id);
            return false;
        }

        if (things[index].ownerAddress != 0x0 && things[index].ownerAddress != msg.sender) {
            Error(3, _id);
            return false;
        }

        if (_addIdentities(index, _newIds)) {
            Updated(_id, things[index].ownerAddress, things[index].isValid);
            return true;
        }
        return false;
    }

     
    function updateThingData(bytes32[] _id, bytes32[] _data, uint88 _schemaIndex) isRegistrant noEther returns(bool) {
        uint index = idToThing[sha3(_id)];

        if (index == 0) {
            Error(2, _id);
            return false;
        }

        if (things[index].ownerAddress != 0x0 && things[index].ownerAddress != msg.sender) {
            Error(3, _id);
            return false;
        }

        if (_schemaIndex > schemas.length || _schemaIndex == 0) {
            Error(4, _id);
            return false;
        }

        if (_data.length == 0) {
            Error(6, _id);
            return false;
        }

        things[index].schemaIndex = _schemaIndex;
        things[index].data = _data;
        Updated(_id, things[index].ownerAddress, things[index].isValid);
        return true;
    }

     
    function setThingValid(bytes32[] _id, bool _isValid) isRegistrant noEther returns(bool) {
        uint index = idToThing[sha3(_id)];

        if (index == 0) {
            Error(2, _id);
            return false;
        }

        if (things[index].ownerAddress != msg.sender) {
            Error(3, _id);
            return false;
        }

        things[index].isValid = _isValid;
         
        Updated(_id, things[index].ownerAddress, things[index].isValid);
        return true;
    }

     
    function deleteThing(bytes32[] _id) isRegistrant noEther returns(bool) {
        uint index = idToThing[sha3(_id)];

        if (index == 0) {
            Error(2, _id);
            return false;
        }

        if (things[index].ownerAddress != msg.sender) {
            Error(3, _id);
            return false;
        }

         
        if (false == _rewireIdentities(things[index].identities, index, 0, 0)) {
             
            return false;
        }

         
        if (index != things.length - 1) {
             
            if (false == _rewireIdentities(things[things.length - 1].identities, things.length - 1, index, 0)) {
                 
                _rewireIdentities(things[index].identities, 0, index, 0);  
                return false;
            }

             
            Deleted(things[index].identities, things[index].ownerAddress);

             
            things[index] = things[things.length - 1];
        }

         
        things.length--;

        return true;
    }

     
    function getSchemasLenght() constant returns(uint) {
        return schemas.length;
    }

     
    function getThing(bytes32[] _id) constant returns(bytes32[], bytes32[], uint88, bytes, address, bool) {
        var index = idToThing[sha3(_id)];
         
        if (index == 0) {
            Error(2, _id);
            return;
        }
        Thing thing = things[index];
        return (thing.identities, thing.data, thing.schemaIndex, schemas[thing.schemaIndex], thing.ownerAddress, thing.isValid);
    }

     

     
    function thingExist(bytes32[] _id) constant returns(bool) {
        return idToThing[sha3(_id)] > 0;
    }

     
    function createSchema(bytes _schema) isRegistrar noEther returns(uint) {
        uint pos = schemas.length++;
        schemas[pos] = _schema;
        return pos;
    }

     
    function () noEther {}


     
    function discontinue() isRegistrar noEther returns(bool) {
      selfdestruct(msg.sender);
      return true;
    }
}