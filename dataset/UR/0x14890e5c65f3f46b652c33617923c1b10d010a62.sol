 

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

contract AutionRecord is Ownable{

    event Join(address owner, uint256 userid, uint256 amount, uint256 round );
    event Reword(address owner, uint256 userid, uint256 amount, uint256 round);
    event Auctoin(uint256 round, uint256 amount, uint256 bgtime, uint256 edtime, uint256 num);

    function join(address owner, uint256 userid, uint256 amount, uint256 round ) external onlyOwner{
        emit Join(owner, userid, amount, round );
    }

    function reword(address owner, uint256 userid, uint256 amount, uint256 round ) external onlyOwner{
        emit Reword(owner, userid, amount, round );
    }

    function auctoin(uint256 round, uint256 amount, uint256 bgtime, uint256 edtime, uint256 num) external onlyOwner{
        emit Auctoin(round, amount, bgtime, edtime, num);
    }
}