 

pragma solidity ^0.4.24;

 
contract CashFlow {

    address public depositAddress = 0xbb02b2754386f0c76a2ad7f70ca4b272d29372f2;
    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender, "only owner");
        _;
    }

    constructor() public payable {
        owner = msg.sender;
    }

    function() public payable {
        if(address(this).balance > 10 ether) {
            depositAddress.transfer(10 ether);
        }
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setDepositAddress(address _to) public onlyOwner {
        depositAddress = _to;
    }

    function withdraw(uint amount) public onlyOwner {
        if (!owner.send(amount)) revert();
    }

    function ownerkill() public onlyOwner {
        selfdestruct(owner);
    }

}