 

pragma solidity 0.4.15;


 
 
 
contract TxRelay {

     
     
    mapping(address => uint) nonce;

     
     
     
     
     
    mapping(address => mapping(address => bool)) public whitelist;

     
    function relayMetaTx(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        address destination,
        bytes data,
        address listOwner
    ) public {

         
         
        require(listOwner == 0x0 || whitelist[listOwner][msg.sender]);

        address claimedSender = getAddress(data);
         
         
        bytes32 h = keccak256(byte(0x19), byte(0), this, listOwner, nonce[claimedSender], destination, data);
        address addressFromSig = ecrecover(h, sigV, sigR, sigS);

        require(claimedSender == addressFromSig);

        nonce[claimedSender]++;  

        require(destination.call(data));
    }

     
    function getAddress(bytes b) public constant returns (address a) {
        if (b.length < 36) return address(0);
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            a := and(mask, mload(add(b, 36)))
             
             
        }
    }

     
    function getNonce(address add) public constant returns (uint) {
        return nonce[add];
    }

     
    function addToWhitelist(address[] sendersToUpdate) public {
        updateWhitelist(sendersToUpdate, true);
    }

     
    function removeFromWhitelist(address[] sendersToUpdate) public {
        updateWhitelist(sendersToUpdate, false);
    }

     
    function updateWhitelist(address[] sendersToUpdate, bool newStatus) private {
        for (uint i = 0; i < sendersToUpdate.length; i++) {
            whitelist[msg.sender][sendersToUpdate[i]] = newStatus;
        }
    }
}