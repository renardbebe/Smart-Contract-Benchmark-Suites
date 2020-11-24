 

pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) public;
}

contract EBAYCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x8c3bAfE5B6352B26567D0DF259a6E35D003b7420;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function EBAYCrowdsale() public {
        creator = msg.sender;
        startDate = 1528365600;
        endDate = 1533636000;
        price = 5000;
        tokenReward = Token(0x12110E20309491db874219613f597de587861b57);
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

    function sendToken(address _to, uint256 _value) isCreator public {
        tokenReward.transfer(_to, _value);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

    function () payable public {
        require(msg.value > 0);
        require(now > startDate);
        require(now < endDate);
	    uint amount = msg.value * price;

         
        if (now > startDate && now < startDate + 2 days) {
            amount += amount / 4;
        }
        
         
        if (now > startDate + 2 days && now < startDate + 9 days) {
            uint _amount = amount / 20;
            amount += _amount * 3;
        }

         
        if (now > startDate + 9 days && now < startDate + 23 days) {
            amount += amount / 10;
        }

        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}