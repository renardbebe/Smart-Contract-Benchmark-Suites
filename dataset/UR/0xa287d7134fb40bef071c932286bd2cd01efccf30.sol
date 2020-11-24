 

pragma solidity ^0.4.23;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Hub is Ownable{
    address public tokenAddress;
    address public profileAddress;
    address public holdingAddress;
    address public readingAddress;
    address public approvalAddress;

    address public profileStorageAddress;
    address public holdingStorageAddress;
    address public readingStorageAddress;

    event ContractsChanged();

    function setTokenAddress(address newTokenAddress)
    public onlyOwner {
        tokenAddress = newTokenAddress;
        emit ContractsChanged();
    }

    function setProfileAddress(address newProfileAddress)
    public onlyOwner {
        profileAddress = newProfileAddress;
        emit ContractsChanged();
    }

    function setHoldingAddress(address newHoldingAddress)
    public onlyOwner {
        holdingAddress = newHoldingAddress;
        emit ContractsChanged();
    }

    function setReadingAddress(address newReadingAddress)
    public onlyOwner {
        readingAddress = newReadingAddress;
        emit ContractsChanged();
    }

    function setApprovalAddress(address newApprovalAddress)
    public onlyOwner {
        approvalAddress = newApprovalAddress;
        emit ContractsChanged();
    }


    function setProfileStorageAddress(address newpPofileStorageAddress)
    public onlyOwner {
        profileStorageAddress = newpPofileStorageAddress;
        emit ContractsChanged();
    }

    function setHoldingStorageAddress(address newHoldingStorageAddress)
    public onlyOwner {
        holdingStorageAddress = newHoldingStorageAddress;
        emit ContractsChanged();
    }
    
    function setReadingStorageAddress(address newReadingStorageAddress)
    public onlyOwner {
        readingStorageAddress = newReadingStorageAddress;
        emit ContractsChanged();
    }

    function isContract(address sender) 
    public view returns (bool) {
        if(sender == owner ||
           sender == tokenAddress ||
           sender == profileAddress ||
           sender == holdingAddress ||
           sender == readingAddress ||
           sender == approvalAddress ||
           sender == profileStorageAddress ||
           sender == holdingStorageAddress ||
           sender == readingStorageAddress) {
            return true;
        }
        return false;
    }
}