 

pragma solidity >=0.4.22 <0.6.0;

interface collectible {
    function transfer(address receiver, uint amount) external;
}

contract Swap {
    address public beneficiary;
    uint public amountRaised;
    uint public price;
    bool contractover = false;
    collectible public swapaddress;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public check;
    uint256 counter = 0;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    constructor(
        address SendTo,
        uint etherCostOfEachCollectible,
        address addressOfCollectibleUsedAsReward
    ) public {
        beneficiary = SendTo;
        price = etherCostOfEachCollectible * 1 szabo;
        swapaddress = collectible(addressOfCollectibleUsedAsReward);
    }
 

    
    function () payable external {
        require(check[msg.sender] == false);
        require(msg.value < 1000000000000000001 wei);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        
        
        uint second = price;
        uint third = price;
        
        if (counter <= 6000) {
        counter += 1;
        swapaddress.transfer(msg.sender, 5000000);
        msg.sender.send(msg.value);
        } else if (amountRaised <= 8000 ether) {
        amountRaised += amount;
        uint secondvalue = second / 5;
        swapaddress.transfer(msg.sender, amount / secondvalue);
        } else {
        amountRaised += amount;
        uint thirdvalue = third / 3;
        swapaddress.transfer(msg.sender, amount / thirdvalue);
        }
        
        beneficiary.send(msg.value);
        emit FundTransfer(msg.sender, amount, true);
        check[msg.sender] = true;
    }

}