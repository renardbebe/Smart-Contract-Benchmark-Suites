 

pragma solidity ^0.4.23;

 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
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


contract BatchTransferEther is Ownable {
    
    event LogTransfer(address indexed sender, address indexed receiver, uint256 amount);
    
    function batchTransferEther(address[] _addresses, uint _amoumt) public payable onlyOwner {
        require(_addresses.length != 0 && _amoumt != 0);
        uint checkAmount = msg.value / _addresses.length;
        require(_amoumt == checkAmount);
        
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0));
            _addresses[i].transfer(_amoumt);
            emit LogTransfer(msg.sender, _addresses[i], _amoumt);
        }
    }
}