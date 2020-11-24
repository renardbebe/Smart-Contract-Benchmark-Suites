 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract BanyanIncomeLockPosition is Ownable {

     
    uint64 public unlockBlock = 6269625;
     
    address public tokenAddress = 0x35a69642857083BA2F30bfaB735dacC7F0bac969;

    bytes4 public transferMethodId = bytes4(keccak256("transfer(address,uint256)"));

    function takeToken(address targetAddress, uint256 amount)
    public
    unlocked
    onlyOwner
    returns (bool)
    {
        return tokenAddress.call(transferMethodId, targetAddress, amount);
    }

    modifier unlocked() {
        require(block.number >= unlockBlock, "Not unlock yet.");
        _;
    }
}