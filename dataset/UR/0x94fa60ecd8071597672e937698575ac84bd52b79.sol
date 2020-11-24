 

 
 
 pragma solidity ^0.4.18;

 

 

 
contract IOwned {
    function owner() public constant returns (address) {}
    function transferOwnership(address _newOwner) public;
} 

contract Owned is IOwned {
    address public owner;        

    function Owned() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        owner = _newOwner;
    }
}
 
 

 

 
contract CustomTrancheWallet is Owned {

    IERC20Token public token;
    address public beneficiary;
    uint256 public initialFunds;  
    bool public locked;  
    uint256[] public unlockDates;
    uint256[] public unlockAmounts;
    uint256 public alreadyWithdrawn;  

    function CustomTrancheWallet(
        IERC20Token _token, 
        address _beneficiary, 
        uint256[] _unlockDates, 
        uint256[] _unlockAmounts
    ) 
    public 
    {
        token = _token;
        beneficiary = _beneficiary;
        unlockDates = _unlockDates;
        unlockAmounts = _unlockAmounts;

        require(paramsValid());
    }

     
    function unlocksCount() public constant returns(uint256) {
        return unlockDates.length;
    }

     
    function getAvailableAmount() public constant returns(uint256) {
        if (!locked) {
            return token.balanceOf(this);
        } else {
            return amountToWithdrawOnDate(now) - alreadyWithdrawn;
        }
    }    

     
    function amountToWithdrawOnDate(uint256 currentDate) public constant returns (uint256) {
        for (uint256 i = unlockDates.length; i != 0; --i) {
            if (currentDate > unlockDates[i - 1]) {
                return unlockAmounts[i - 1];
            }
        }
        return 0;
    }

     
    function paramsValid() public constant returns (bool) {        
        if (unlockDates.length == 0 || unlockDates.length != unlockAmounts.length) {
            return false;
        }        

        for (uint256 i = 0; i < unlockAmounts.length - 1; ++i) {
            if (unlockAmounts[i] >= unlockAmounts[i + 1]) {
                return false;
            }
            if (unlockDates[i] >= unlockDates[i + 1]) {
                return false;
            }
        }
        return true;
    }

     
    function sendToBeneficiary() public {
        uint256 amount = getAvailableAmount();
        alreadyWithdrawn += amount;
        require(token.transfer(beneficiary, amount));
    }

     
    function lock() public ownerOnly {
        require(!locked);
        require(token.balanceOf(this) == unlockAmounts[unlockAmounts.length - 1]);

        locked = true;
    }

     
    function setParams(        
        uint256[] _unlockDates, 
        uint256[] _unlockAmounts
    ) 
    public 
    ownerOnly 
    {
        require(!locked);        

        unlockDates = _unlockDates;
        unlockAmounts = _unlockAmounts;

        require(paramsValid());
    }    

     
    function setBeneficiary(address _beneficiary) public ownerOnly {
        beneficiary = _beneficiary;
    }
}