 

pragma solidity 0.5.8;

 

 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract Verification is Ownable {
     
    struct Certificate {
        uint256 time;
        bytes32 pdfHash;
        bytes32 originHash;
    }

     
    mapping(bytes32 => bytes32[]) public versions;

     
    event CertificateCreated(bytes32 indexed _pdfHash, bytes32 indexed _originHash, address indexed _sender, uint256 _time);
    event CertificateUpdated(bytes32 indexed _pdfHash, bytes32 indexed _originHash, address indexed _sender, uint256 _time);

     
    function createCert(bytes32 _pdfHash) public onlyOwner returns (bool) {
        require(_pdfHash != bytes32(0));

         
        require(versions[_pdfHash].length == 0);

        versions[_pdfHash].push(_pdfHash);
        emit CertificateCreated(_pdfHash, _pdfHash, msg.sender, block.timestamp);
        return true;
    }

     
    function updateCert(bytes32 _pdfHash, bytes32 _newPdfHash) public onlyOwner returns (bool) {
        require(_pdfHash != bytes32(0));
        require(_newPdfHash != bytes32(0));
        require(versions[_pdfHash].length != 0);
        versions[_pdfHash].push(_newPdfHash);
        emit CertificateUpdated(_newPdfHash, _pdfHash, msg.sender, block.timestamp);
        return true;
    }

     
    function viewRecord(bytes32 _originHash) public view returns (bytes32[] memory copy) {
        require(_originHash != bytes32(0));
        copy = versions[_originHash];
    }
}