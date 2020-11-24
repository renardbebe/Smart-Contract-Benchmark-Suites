 

pragma solidity 0.4.18;

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

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Interface {
     
    function transfer(address _to, uint256 _value) returns (bool success);
     
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Distributor is Ownable {
    ERC20Interface token;

    function Distributor (address _tokenAddress) public {
        token = ERC20Interface(_tokenAddress);
    }

    function batchTransfer (address[] _to, uint256 _value) public onlyOwner {
        for (uint i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value);
        }
    }

}