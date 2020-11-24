 

pragma solidity ^0.4.24;

 
 

interface contractInterface {
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external;
}

contract DualSig {
    address public directorA;
    address public directorB;
    address public proposalAuthor;
    address public proposalContract;
    address public proposalDestination;
    uint256 public proposalAmount;
    uint256 public proposalBlock;
    uint256 public proposalNonce;
    uint256 public overrideBlock;
    uint256 public transferSafety;

    event Proposal(uint256 _nonce, address _author, address _contract, uint256 _amount, address _destination, uint256 _timestamp);

    event Accept(uint256 _nonce);

    event NewDirectorA(address _director);

    event NewDirectorB(address _director);

    modifier onlyDirectors {
        require(msg.sender == directorA || msg.sender == directorB);
        _;
    }

    constructor() public {
        overrideBlock = (60*60*24*30)/15; 
        proposalNonce = 0;
        transferSafety = 1 ether;
        directorA = msg.sender;
        directorB = msg.sender;
        reset();
    }

    function () public payable {}

    function proposal(address proposalContractSet, uint256 proposalAmountSet, address proposalDestinationSet) public onlyDirectors {
        proposalNonce++;
        proposalAuthor = msg.sender;
        proposalContract = proposalContractSet;
        proposalAmount = proposalAmountSet;
        proposalDestination = proposalDestinationSet;
        proposalBlock = block.number + overrideBlock;
        emit Proposal(proposalNonce, proposalAuthor, proposalContract, proposalAmount, proposalDestination, proposalBlock);
    }

    function reset() public onlyDirectors {
        proposalNonce++;
        if (proposalNonce > 1000000) {
            proposalNonce = 0;
        }
        proposalAuthor = 0x0;
        proposalContract = 0x0;
        proposalAmount = 0;
        proposalDestination = 0x0;
        proposalBlock = 0;
    }

    function accept(uint256 acceptNonce) public onlyDirectors {
        require(proposalNonce == acceptNonce);
        require(proposalAmount > 0);
        require(proposalDestination != 0x0);
        require(proposalAuthor != msg.sender || block.number >= proposalBlock);

        address localContract = proposalContract;
        address localDestination = proposalDestination;
        uint256 localAmount = proposalAmount;
        reset();

        if (localContract==0x0) {
            require(localAmount <= address(this).balance);
            localDestination.transfer(localAmount);
        }
        else {
            contractInterface tokenContract = contractInterface(localContract);
            tokenContract.transfer(localDestination, localAmount);
        }
        emit Accept(acceptNonce);
    }

    function transferDirectorA(address newDirectorA) public payable {
        require(msg.sender==directorA);
        require(msg.value==transferSafety); 
        directorA.transfer(transferSafety); 
        reset();
        directorA = newDirectorA;
        emit NewDirectorA(directorA);
    }

    function transferDirectorB(address newDirectorB) public payable {
        require(msg.sender==directorB);
        require(msg.value==transferSafety); 
        directorB.transfer(transferSafety); 
        reset();
        directorB = newDirectorB;
        emit NewDirectorB(directorB);
    }
}