 

pragma solidity ^0.5.11;


 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}


 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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



 
contract Catalizr is Ownable {

    mapping(bytes32 => bytes32) public operations;

     
    function storeDocumentProof(bytes32 _mixedHash, bytes32 _hashDocument) public onlyOwner{
        operations[_mixedHash] = _hashDocument;
    }

     
    function storeDocumentsProofs(bytes32[] memory _mixedHashes, bytes32[] memory _hashDocuments) public onlyOwner{
       for(uint i = 0; i < _mixedHashes.length; i++) {
        operations[_mixedHashes[i]] = _hashDocuments[i];
        }
    }

     
    function getDocumentHashbyMixedHash(bytes32 _mixedHash) public view returns (bytes32) {
        return (operations[_mixedHash]);
    }

}