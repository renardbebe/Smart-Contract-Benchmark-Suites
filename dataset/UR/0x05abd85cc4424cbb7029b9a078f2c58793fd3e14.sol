 

pragma solidity ^0.4.0;
contract WyoMesh {

    struct Device {
        string name;
        bool permissioned;
         
         
    }
    struct IPFS_Hash {
        string ipfs_hash;
        bool auditor_signed;  
    }

     

    address public auditor;
    mapping(address => Device) private devices;
    IPFS_Hash[] ipfs_hashes;
    uint hash_index;

     
    constructor(uint8 _maxHashes) public {
        auditor = msg.sender;
        ipfs_hashes.length = _maxHashes;
        devices[msg.sender].permissioned = true;
        hash_index = 0;
    }

     
     
    function addDevice(address toDevice) public returns(bool){
        if (msg.sender != auditor) return false;
        devices[toDevice].permissioned = true;
        return true;
    }


     
    function submitHash(string newIPFS_Hash) public returns(bool){
        if(!devices[msg.sender].permissioned || hash_index >= ipfs_hashes.length-1) return false;
        ipfs_hashes[hash_index].ipfs_hash = newIPFS_Hash;
        hash_index++;
        return true;
    }

     
    function getHash(uint8 index_) public returns(string){
        return ipfs_hashes[index_].ipfs_hash;
    }

     
    function signAudit(uint8 index_) public returns(bool){
      if(msg.sender != auditor) return false;
        ipfs_hashes[index_].auditor_signed = true;
        return true;
    }
}