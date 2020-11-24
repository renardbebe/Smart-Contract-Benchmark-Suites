 

pragma solidity ^0.4.20;

 

contract Transfiere2018Asistencia {
    struct Organization {
        string codigo;
    }

    Organization[] internal availableOrgs;
    address public owner = msg.sender;

    function addOrg(string _codigo) public {
        require(msg.sender == owner);
        
        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                return;
            }
        }
        
        availableOrgs.push(Organization(_codigo));
    }

    function deleteOrg(string _codigo) public {
        require(msg.sender == owner);

        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                delete availableOrgs[i];
                availableOrgs.length--;
                return;
            }
        }
    }
    
    function checkCode(string _codigo) public view returns (string, string) {
        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                return (_codigo,"El código es válido.");
            }
        }
    
        return (_codigo,"El código no existe.");
    }
    
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}