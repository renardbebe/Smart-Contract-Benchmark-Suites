 

 

pragma solidity ^0.4.25;

contract ALTESFINANCEGROUP {

    struct Investor
    {
        uint amount;  
        uint dateUpdate;  
        uint dateEnd;
        address refer;  
        bool active;  
        bool typePlan;
    }

    uint256 constant private MINIMUM_INVEST = 0.6 ether;  
    uint256 constant private MINIMUM_PAYMENT = 0.01 ether;  
    uint constant private PERCENT_FOR_ADMIN = 10;  
    uint constant private PERCENT_FOR_REFER = 5;  
    uint constant private PROFIT_PERIOD = 86400;  
    address constant private ADMIN_ADDRESS = 0x2803Ef1dFF52D6bEDE1B2714A8Dd4EA82B8aE733;  

    mapping(address => Investor) investors;  

    event Transfer (address indexed _to, uint256 indexed _amount);

    constructor () public {
    }

     
    function getPercent(Investor investor) private pure returns (uint256) {
        uint256 amount = investor.amount;

        if (amount >= 0.60 ether && amount <= 5.99 ether) {
            return 150;
        } else if (amount >= 29 ether && amount <= 58.99 ether) {
            return 175;
        } else if (amount >= 119 ether && amount <= 298.99 ether) {
            return 200;
        } else if (amount >= 6 ether && amount <= 28.99 ether) {
            return 38189;
        } else if (amount >= 59.99 ether && amount <= 118.99 ether) {
            return 28318;
        } else if (amount >=  299.99 ether && amount <= 600 ether) {
            return 18113;
        }
        return 0;
    }

    function getDate(Investor investor) private view returns (uint256) {
        uint256 amount = investor.amount;
        if (amount >= 0.60 ether && amount <= 5.99 ether) {
            return PROFIT_PERIOD * 120 + now;
        } else if (amount >= 29 ether && amount <= 58.99 ether) {
            return PROFIT_PERIOD * 150 + now;
        } else if (amount >= 119 ether && amount <= 298.99 ether) {
            return PROFIT_PERIOD * 180 + now;
        } else if (amount >= 6 ether && amount <= 28.99 ether) {
            return PROFIT_PERIOD * 90 + now;
        } else if (amount >= 59.99 ether && amount <= 118.99 ether) {
            return PROFIT_PERIOD * 60 + now;
        } else if (amount >=  299.99 ether && amount <= 600 ether) {
            return PROFIT_PERIOD * 30 + now;
        }
        return 0;
    }

    function getTypePlan(Investor investor) private pure returns (bool) {
        uint256 amount = investor.amount;
        if (amount >= 0.60 ether && amount <= 5.99 ether) {
            return false;
        } else if (amount >= 29 ether && amount <= 58.99 ether) {
            return false;
        } else if (amount >= 119 ether && amount <= 298.99 ether) {
            return false;
        } else if (amount >= 6 ether && amount <= 28.99 ether) {
            return true;
        } else if (amount >= 59.99 ether && amount <= 118.99 ether) {
            return true;
        } else if (amount >=  299.99 ether && amount <= 600 ether) {
            return true;
        }
        return false;
    }

     
    function getFeeForAdmin(uint256 amount) private pure returns (uint256) {
        return amount * PERCENT_FOR_ADMIN / 100;
    }

     
    function getFeeForRefer(uint256 amount) private pure returns (uint256) {
        return amount * PERCENT_FOR_REFER / 100;
    }

     
    function getRefer(bytes bys) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getProfit(Investor investor) private view returns (uint256) {
        uint256 amountProfit = 0;
        if (!investor.typePlan) {
            if (now >= investor.dateEnd) {
                amountProfit = investor.amount * getPercent(investor) * (investor.dateEnd - investor.dateUpdate) / (PROFIT_PERIOD * 10000);
            } else {
                amountProfit = investor.amount * getPercent(investor) * (now - investor.dateUpdate) / (PROFIT_PERIOD * 10000);
            }
        } else {
            amountProfit = investor.amount / 10000 * getPercent(investor);
        }
        return amountProfit;
    }


     
    function() external payable {
        uint256 amount = msg.value;
         
        address userAddress = msg.sender;
         
        address referAddress = getRefer(msg.data);
         

        require(amount == 0 || amount >= MINIMUM_INVEST, "Min Amount for investing is MINIMUM_INVEST.");

         
        if (amount == 0 && investors[userAddress].active) {
             
            require(!investors[userAddress].typePlan && now <= investors[userAddress].dateEnd, 'the Deposit is not finished');

            uint256 amountProfit = getProfit(investors[userAddress]);
            require(amountProfit > MINIMUM_PAYMENT, 'amountProfit must be > MINIMUM_PAYMENT');

            if (now >= investors[userAddress].dateEnd) {
                investors[userAddress].active = false;
            }

            investors[userAddress].dateUpdate = now;

            userAddress.transfer(amountProfit);
            emit Transfer(userAddress, amountProfit);

        } else if (amount >= MINIMUM_INVEST && !investors[userAddress].active) { 
             
            ADMIN_ADDRESS.transfer(getFeeForAdmin(amount));
            emit Transfer(ADMIN_ADDRESS, getFeeForAdmin(amount));

            investors[userAddress].active = true;
            investors[userAddress].dateUpdate = now;
            investors[userAddress].amount = amount;
            investors[userAddress].dateEnd = getDate(investors[userAddress]);
            investors[userAddress].typePlan = getTypePlan(investors[userAddress]);


             
            if (investors[referAddress].active && referAddress != address(0)) {
                investors[userAddress].refer = referAddress;
            }

             
            if (investors[userAddress].refer != address(0)) {
                investors[userAddress].refer.transfer(getFeeForRefer(amount));
                emit Transfer(investors[userAddress].refer, getFeeForRefer(amount));
            }
        }
    }

     
    function showDeposit(address _deposit) public view returns (uint256) {
        return investors[_deposit].amount;
    }

     
    function showLastChange(address _deposit) public view returns (uint256) {
        return investors[_deposit].dateUpdate;
    }

     
    function showUnpayedPercent(address _deposit) public view returns (uint256) {
        uint256 amount = getProfit(investors[_deposit]);
        return amount;
    }


}