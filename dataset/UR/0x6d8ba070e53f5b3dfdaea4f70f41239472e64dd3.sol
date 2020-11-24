 

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
    address _tokenAddress = 0x1604d5a2590b585e38b55dd09594b1e01bab8729;
    uint _value = 100e3;

    function Distributor () public {
        token = ERC20Interface(_tokenAddress);
    }

    function () public payable {}

    function batchTransfer (address[] _to) public onlyOwner {
        for (uint i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value);
        }
    }

    function withdrawToken(address _to, uint _amt) public onlyOwner {
        token.transfer(_to, _amt);
    }

}