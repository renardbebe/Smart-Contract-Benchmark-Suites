 

pragma solidity ^0.4.18;

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

interface token {
    function transfer(address receiver, uint amount) external;
    function burn(uint256 _value) external returns (bool success);
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
}

contract HACHIKOCrowdsale is Ownable {
    
    using SafeMath for uint256;
    
    uint256 public constant EXCHANGE_RATE = 200;
    uint256 public constant START = 1537538400;  



    uint256 availableTokens;
    address addressToSendEthereum;
    
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

     
    constructor(
        address addressOfTokenUsedAsReward,
        address _addressToSendEthereum
    ) public {
        availableTokens = 5000000 * 10 ** 18;
        addressToSendEthereum = _addressToSendEthereum;
        deadline = START + 42 days;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () public payable {
        require(now < deadline && now >= START);
        uint256 amount = msg.value;
        uint256 tokens = amount * EXCHANGE_RATE;
        uint256 bonus = getBonus(tokens);
        tokens = tokens.add(bonus);
        balanceOf[msg.sender] += tokens;
        amountRaised += tokens;
        availableTokens -= tokens;
        tokenReward.transfer(msg.sender, tokens);
        addressToSendEthereum.transfer(amount);
    }
    
    
    function getBonus(uint256 _tokens) public constant returns (uint256) {

        require(_tokens > 0);
        
        if (START <= now && now < START + 1 days) {

            return _tokens.mul(30).div(100);  

        } else if (START <= now && now < START + 1 weeks) {

            return _tokens.div(4);  

        } else if (START + 1 weeks <= now && now < START + 2 weeks) {

            return _tokens.div(5);  

        } else if (START + 2 weeks <= now && now < START + 3 weeks) {

            return _tokens.mul(15).div(100);  

        } else if (START + 3 weeks <= now && now < START + 4 weeks) {

            return _tokens.div(10);  

        } else if (START + 4 weeks <= now && now < START + 5 weeks) {

            return _tokens.div(20);  

        } else {

            return 0;

        }
    }

    modifier afterDeadline() { 
        require(now >= deadline);
        _; 
    }
    
    function sellForOtherCoins(address _address,uint amount)  public payable onlyOwner
    {
        uint256 tokens = amount;
        uint256 bonus = getBonus(tokens);
        tokens = tokens.add(bonus);
        availableTokens -= tokens;
        tokenReward.transfer(_address, tokens);
    }
    
    function burnAfterIco() public onlyOwner returns (bool success){
        uint256 balance = availableTokens;
        tokenReward.burn(balance);
        availableTokens = 0;
        return true;
    }

    function tokensAvailable() public constant returns (uint256) {
        return availableTokens;
    }

}