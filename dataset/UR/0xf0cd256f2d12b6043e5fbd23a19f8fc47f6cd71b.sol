 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;


contract Recovery is Ownable {
    uint256 public depositValue;

    mapping(uint256 => address[]) public votes;
    mapping(uint256 => mapping(address => bool)) public voted;

    event VotedForRecovery(uint256 indexed height, address voter);

    function setDeposit(uint256 DepositValue) public onlyOwner {
        depositValue = DepositValue;
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function voteForSkipBlock(uint256 height) public payable {
        require(msg.value >= depositValue);
        require(!voted[height][msg.sender]);

        votes[height].push(msg.sender);
        voted[height][msg.sender] = true;

        emit VotedForRecovery(height, msg.sender);
    }

    function numVotes(uint256 height) public view returns (uint256) {
        return votes[height].length;
    }
}