 

 
 
 
 

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