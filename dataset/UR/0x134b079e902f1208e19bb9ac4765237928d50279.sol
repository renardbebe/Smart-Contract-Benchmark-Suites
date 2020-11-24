 

pragma solidity 0.5.9;

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

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract TokenTimelock is Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ERC20 public token;

    struct User {
        uint deposit;
        uint balance;
        uint releaseTime;
        uint step;
    }

    mapping(address => User) public users;

    uint public releaseStep = 90 days;
    uint public releaseStepCount = 8;
    uint public releaseStepPercent = 12500;

    constructor(ERC20 _token) public {
        token = _token;
    }

    function addTokens(address _user, uint256 _value) onlyOwner external returns (bool) {
        require(_user != address(0));
        require(users[_user].deposit == 0);
        require(_value > 0);

        token.safeTransferFrom(msg.sender, address(this), _value);

        users[_user].deposit = _value;
        users[_user].balance = _value;
        users[_user].releaseTime = now + 720 days;
    }


    function getTokens() external {
        require(users[msg.sender].balance > 0);
        uint currentStep = getCurrentStep(msg.sender);
        require(currentStep > 0);
        require(currentStep > users[msg.sender].step);

        if (currentStep == releaseStepCount) {
            users[msg.sender].step = releaseStepCount;
            token.safeTransfer(msg.sender, users[msg.sender].balance);
            users[msg.sender].balance = 0;
        } else {
            uint p = releaseStepPercent * (currentStep - users[msg.sender].step);
            uint val = _valueFromPercent(users[msg.sender].deposit, p);

            if (users[msg.sender].balance >= val) {
                users[msg.sender].balance = users[msg.sender].balance.sub(val);
                token.safeTransfer(msg.sender, val);
            }

            users[msg.sender].step = currentStep;
        }

    }


    function getCurrentStep(address _user) public view returns (uint) {
        require(users[_user].deposit != 0);
        uint _id;
        
        if (users[_user].releaseTime >= now) {
            uint _count = (users[_user].releaseTime - now) / releaseStep;
            _count = _count == releaseStepCount ? _count : _count + 1;
            _id = releaseStepCount - _count;
        } else _id = releaseStepCount;

        return _id;
    }
    
 
     

     
    function _valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(100000);
        return (_amount);
    }

    function getUser(address _user) public view returns(uint, uint, uint, uint){
        return (users[_user].deposit, users[_user].balance, users[_user].step, users[_user].releaseTime);
    }
}