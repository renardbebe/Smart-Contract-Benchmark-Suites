 

pragma solidity >=0.4.21 <0.6.0;

contract AlumniStoreContract {
    constructor() public { owner = msg.sender; }
    address payable owner;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    struct Alumni {
        address payable _address;
        bool _exists;
    }

    mapping(bytes32 => Alumni) alumni;

    function addStudent(bytes32 _blockchainCertificateHash, address payable _address) public onlyOwner returns (bool) {
        alumni[_blockchainCertificateHash]._address = _address;
        alumni[_blockchainCertificateHash]._exists = true;
        return true;
    }

    function getAlumniAddress(bytes32 _blockchainCertificateHash) public view returns (address payable _address) {
        return alumni[_blockchainCertificateHash]._address;
    }

    function removeCertificate(bytes32 _blockchainCertificateHash) public onlyOwner returns (bool) {
       delete(alumni[_blockchainCertificateHash]);
       return true;
    }

    function changeCertificateAddress(bytes32 _blockchainCertificateHash, address payable _newAddress) public onlyOwner returns (bool) {
        if (alumni[_blockchainCertificateHash]._exists) {
            alumni[_blockchainCertificateHash]._address = _newAddress;
            return true;
        } else return false;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}