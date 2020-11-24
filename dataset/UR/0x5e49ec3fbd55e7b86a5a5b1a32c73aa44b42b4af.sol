 

pragma solidity ^0.4.3;

contract Avatars {
    
    uint avatarsCount = 0;

    struct Avatar {
        uint id;
        
          
        address owner;
        
          
        bytes32 shapes;
        
         
        bytes32 colorsPrimary;
        
         
        bytes32 colorsSecondary;
        
         
        bytes32 positions;
    }
    
    mapping(bytes32 => Avatar) avatars;
    
     
    function register(string shapes, string colorsPrimary, string colorsSecondary, string positions) returns (bytes32 avatarHash) {
        bytes32 shapesBytes = strToBytes(shapes);
        bytes32 colorsPrimaryBytes = strToBytes(colorsPrimary);
        bytes32 colorsSecondaryBytes = strToBytes(colorsSecondary);
        bytes32 positionsBytes = strToBytes(positions);

         
        bytes32 hash = sha3(shapes);

        Avatar memory existingAvatar = avatars[hash];
        if (existingAvatar.id != 0)
            throw;
        
        Avatar memory avatar = Avatar(++avatarsCount, msg.sender, 
            shapesBytes,
            colorsPrimaryBytes,
            colorsSecondaryBytes,
            positionsBytes);

        avatars[hash] = avatar;
        return hash;
    }
    
      
    function get(bytes32 avatarHash) constant returns (bytes32 shapes, bytes32 colorsPrimary, bytes32 colorsSecondary, bytes32 positions) {
        Avatar memory avatar = getAvatar(avatarHash);
        
        shapes = avatar.shapes;
        colorsPrimary = avatar.colorsPrimary;
        colorsSecondary = avatar.colorsSecondary;
        positions = avatar.positions;
    }
    
      
    function getOwner(bytes32 avatarHash) constant returns (address) {
        Avatar memory avatar = getAvatar(avatarHash);
        return avatar.owner;
    }
    
        
      
    function isExists(bytes32 avatarHash) constant returns (bool) {
        Avatar memory avatar = avatars[avatarHash];
        if (avatar.id == 0)
            return false;
            
        return true;
    }
    
      
    function getAvatar(bytes32 avatarHash) private constant returns (Avatar) {
        Avatar memory avatar = avatars[avatarHash];
        if (avatar.id == 0)
           throw;
           
        return avatar;
    }
    
     
    function strToBytes(string str) constant private returns (bytes32 ret) {
         
         
        
        assembly {
            ret := mload(add(str, 32))
        }
    } 
}