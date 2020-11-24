 

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

contract AudigentSegment is Ownable {
    mapping (uint256 => address[]) private _hashToSignatures;
    mapping (address => address) private _signerToAgency;

    modifier onlyAlreadyExistingSigner(address _signer) {
        require(_signerToAgency[_signer] == msg.sender);
        _;
    }

    modifier onlyNewSigner(address _signer) {
        if (_signerToAgency[_signer] == msg.sender) {
            revert('Signer already assigned to this agency');
        }
        require(_signer != owner);
        require(_signerToAgency[_signer] != _signer);
        require(_signerToAgency[_signer] == address(0));
        _;
    }

    modifier onlyAssociatedSigner() {
        require(_signerToAgency[msg.sender] != address(0));
        _;
    }

    function createHash(uint256 _hash) public onlyOwner {
        if (_hashToSignatures[_hash].length > 0) {
            revert('Hash already exists');
        }
        _hashToSignatures[_hash] = new address[](0);
    }

    function addSigner(address _signer) public onlyNewSigner(_signer) {
        _signerToAgency[_signer] = msg.sender;
    }

    function removeSigner(address _signer) public onlyAlreadyExistingSigner(_signer) {
        _signerToAgency[_signer] = address(0);
    }

    function signHash(uint256 _hash) public onlyAssociatedSigner {
        address[] memory signatures = _hashToSignatures[_hash];

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

        _hashToSignatures[_hash].push(msg.sender);
    }

    function isHashSigned(uint256 _hash) public view returns (bool isSigned) {
        return _hashToSignatures[_hash].length > 0;
    }

    function getHashSignatures(uint256 _hash) public view returns (address[] signatures) {
        return _hashToSignatures[_hash];
    }
}