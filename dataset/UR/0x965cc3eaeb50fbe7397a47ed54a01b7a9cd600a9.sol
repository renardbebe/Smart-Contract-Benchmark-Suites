 

pragma solidity >=0.4.22 <0.6.0;

interface collectible {
    function transfer(address receiver, uint amount) external;
}

contract Swap {
    collectible public swapaddress;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public check;
    uint256 cancel = 0;
    uint256 count = 0;
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    constructor(
        address addressOfCollectibleUsedAsReward
    ) public {
        swapaddress = collectible(addressOfCollectibleUsedAsReward);
    }

    
    function () payable external {
        require(check[msg.sender] == false);
        if (count <= 10000000) {
        count += 1;
        msg.sender.send(msg.value);
        balanceOf[msg.sender] += 50000000;
        swapaddress.transfer(msg.sender, 50000000);
        check[msg.sender] = true;
        } else {
        require(cancel == 1);
        selfdestruct(swapaddress);
        }
    }

}