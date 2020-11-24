 

pragma solidity ^0.4.16;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract IRideSale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0xBeDF65990326Ed2236C5A17432d9a30dbA3aBFEe;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor () public {
        creator = msg.sender;
        startDate = 1537027200;
        endDate = 1540656000;
        price = 2500;
        tokenReward = Token(0x69D94dC74dcDcCbadEc877454a40341Ecac34A7c);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setStartDate(uint256 _startDate) isCreator public {
        startDate = _startDate;      
    }

    function setEndtDate(uint256 _endDate) isCreator public {
        endDate = _endDate;      
    }
    
    function setPrice(uint256 _price) isCreator public {
        price = _price;      
    }

    function setToken(address _token) isCreator public {
        tokenReward = Token(_token);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 0);
        require(now > startDate);
        require(now < endDate);
	    uint256 amount = msg.value * price;
	    uint256 _amount = amount / 5;
        amount += _amount * 2;
        tokenReward.transferFrom(owner, msg.sender, amount);
        emit FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}