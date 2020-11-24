 

pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) public;
}

contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
}

contract IQNSecondPreICO is Ownable {
    
    uint256 public constant EXCHANGE_RATE = 550;
    uint256 public constant START = 1515402000;  



    uint256 availableTokens;
    address addressToSendEthereum;
    address addressToSendTokenAfterIco;
    
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;

     
    function IQNSecondPreICO (
        address addressOfTokenUsedAsReward,
        address _addressToSendEthereum,
        address _addressToSendTokenAfterIco
    ) public {
        availableTokens = 800000 * 10 ** 18;
        addressToSendEthereum = _addressToSendEthereum;
        addressToSendTokenAfterIco = _addressToSendTokenAfterIco;
        deadline = START + 7 days;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () public payable {
        require(now < deadline && now >= START);
        require(msg.value >= 1 ether);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        availableTokens -= amount;
        tokenReward.transfer(msg.sender, amount * EXCHANGE_RATE);
        addressToSendEthereum.transfer(amount);
    }

    modifier afterDeadline() { 
        require(now >= deadline);
        _; 
    }

    function sendAfterIco(uint amount)  public payable onlyOwner afterDeadline
    {
        tokenReward.transfer(addressToSendTokenAfterIco, amount);
    }
    
    function sellForBitcoin(address _address,uint amount)  public payable onlyOwner
    {
        tokenReward.transfer(_address, amount);
    }

    function tokensAvailable() public constant returns (uint256) {
        return availableTokens;
    }

}