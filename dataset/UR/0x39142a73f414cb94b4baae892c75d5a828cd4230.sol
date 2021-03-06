 

pragma solidity ^0.4.18;

 
 
 

contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }

        _;
    }

     
     
    function transferOwnership(address _newOwnerCandidate) onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() {
        if (msg.sender == newOwnerCandidate) {
            owner = newOwnerCandidate;
            newOwnerCandidate = address(0);

            OwnershipTransferred(owner, newOwnerCandidate);
        }
    }
}

interface token {
    function transfer(address _to, uint256 _amount);
}
 
contract Crowdsale is Ownable {
    
    address public beneficiary = msg.sender;
    token public epm;
    
    uint256 public constant EXCHANGE_RATE = 25000;  
    uint256 public constant DURATION = 71 days;
    uint256 public startTime = 0;
    uint256 public endTime = 0;
    
    uint public amount = 0;

    mapping(address => uint256) public balanceOf;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

     
     
    function Crowdsale() {
        epm = token(0xc5594d84B996A68326d89FB35E4B89b3323ef37d);
        startTime = now;
        endTime = startTime + DURATION;
    }

     
     
    function () payable onlyDuringSale() {
        uint SenderAmount = msg.value;
        balanceOf[msg.sender] += SenderAmount;
        amount = amount + SenderAmount;
        epm.transfer(msg.sender, SenderAmount * EXCHANGE_RATE);
        FundTransfer(msg.sender,  SenderAmount * EXCHANGE_RATE, true);
    }

  
    modifier onlyDuringSale() {
        if (now < startTime || now >= endTime) {
            throw;
        }

        _;
    }
    
    function Withdrawal() onlyOwner {
            if (amount > 0) {
                    if (beneficiary.send(amount)) {
                        FundTransfer(msg.sender, amount, false);
                        amount = 0;
                    } else {
                        balanceOf[beneficiary] = amount;
                }
            }

    }
}