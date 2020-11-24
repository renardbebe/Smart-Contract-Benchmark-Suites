 

pragma solidity ^0.4.21;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract AudigentAudience is Ownable {
    struct Signature {
        address partner;
        address[] signatures;
    }

    mapping (uint256 => Signature) private _hashToSignature;
    mapping (address => address) private _signerToPartner;

    modifier onlyPartnerSigner(uint256 _hash) {
        require(_signerToPartner[msg.sender] == _hashToSignature[_hash].partner);
        _;
    }

    modifier onlySignerPartner(address _signer) {
        require(_signerToPartner[_signer] == msg.sender);
        _;
    }

    modifier onlyNewSigner(address _signer) {
        if (_signerToPartner[_signer] == msg.sender) {
            revert('Signer already assigned to this partner');
        }
        require(_signer != owner);
        require(_signerToPartner[_signer] != _signer);
        require(_signerToPartner[_signer] == address(0));
        _;
    }

    modifier onlyHashPartner(uint256 _hash) {
        require(_hashToSignature[_hash].partner == msg.sender);
        _;
    }

    function createHash(uint256 _hash, address _partner) public onlyOwner {
        if (_hashToSignature[_hash].partner != address(0)) {
            revert('Hash already exists');
        }
        _hashToSignature[_hash] = Signature(_partner, new address[](0));
    }

    function transferHashOwnership(uint256 _hash, address _newOwner) public onlyHashPartner(_hash) {
        require(_newOwner != address(0));
        _hashToSignature[_hash].partner = _newOwner;
    }

    function addSigner(address _signer) public onlyNewSigner(_signer) {
        _signerToPartner[_signer] = msg.sender;
    }

    function removeSigner(address _signer) public onlySignerPartner(_signer) {
        _signerToPartner[_signer] = address(0);
    }

    function signHash(uint256 _hash) public onlyPartnerSigner(_hash) {
        address[] memory signatures = _hashToSignature[_hash].signatures;

        bool alreadySigned = false;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == msg.sender) {
                alreadySigned = true;
                break;
            }
        }
        if (alreadySigned == true) {
            revert('Hash already signed');
        }

        _hashToSignature[_hash].signatures.push(msg.sender);
    }

    function isHashSigned(uint256 _hash) public view returns (bool isSigned) {
        return _hashToSignature[_hash].signatures.length > 0;
    }

    function getHashSignatures(uint256 _hash) public view returns (address[] signatures) {
        return _hashToSignature[_hash].signatures;
    }
}