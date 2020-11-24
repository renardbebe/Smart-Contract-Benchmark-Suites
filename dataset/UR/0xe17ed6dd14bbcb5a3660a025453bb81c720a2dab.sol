 

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


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}


 
contract AirDrop is Ownable {
    using SafeMath for uint256;

     
    uint public airDropAmount;

     
    mapping ( address => bool ) public invalidAirDrop;

     
    bool public stop = false;

    ERC20BasicInterface public erc20;

    uint256 public startTime;
    uint256 public endTime;

     
    event LogAirDrop(address indexed receiver, uint amount);
    event LogStop();
    event LogStart();
    event LogWithdrawal(address indexed receiver, uint amount);

     
    function AirDrop(uint256 _startTime, uint256 _endTime, uint _airDropAmount, address _tokenAddress) public {
        require(_startTime >= now &&
            _endTime >= _startTime &&
            _airDropAmount > 0 &&
            _tokenAddress != address(0)
        );
        startTime = _startTime;
        endTime = _endTime;
        erc20 = ERC20BasicInterface(_tokenAddress);
        uint tokenDecimals = erc20.decimals();
        airDropAmount = _airDropAmount.mul(10 ** tokenDecimals);
    }

     
    function isValidAirDropForAll() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = erc20.balanceOf(this) >= airDropAmount;
        bool validPeriod = now >= startTime && now <= endTime;
        return validNotStop && validAmount && validPeriod;
    }

     
    function isValidAirDropForIndividual() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = erc20.balanceOf(this) >= airDropAmount;
        bool validPeriod = now >= startTime && now <= endTime;
        bool validAmountForIndividual = !invalidAirDrop[msg.sender];
        return validNotStop && validAmount && validPeriod && validAmountForIndividual;
    }

     
    function receiveAirDrop() public {
        require(isValidAirDropForIndividual());

         
        invalidAirDrop[msg.sender] = true;

         
        require(erc20.transfer(msg.sender, airDropAmount));

        LogAirDrop(msg.sender, airDropAmount);
    }

     
    function toggle() public onlyOwner {
        stop = !stop;

        if (stop) {
            LogStop();
        } else {
            LogStart();
        }
    }

     
    function withdraw(address _address) public onlyOwner {
        require(stop || now > endTime);
        require(_address != address(0));
        uint tokenBalanceOfContract = erc20.balanceOf(this);
        require(erc20.transfer(_address, tokenBalanceOfContract));
        LogWithdrawal(_address, tokenBalanceOfContract);
    }
}