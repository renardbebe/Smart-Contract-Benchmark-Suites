 

 

pragma solidity ^0.5.5;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract RewardsAirdropper is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public credits;

    uint256 public pricePerTx = 0.01 ether;

    function transfer(address _token, address[] memory _addresses, uint256[] memory _values) payable public returns (bool) {
        require(_addresses.length == _values.length, "Address array and values array must be same length");

        require(credits[msg.sender] > 0 || msg.value >= pricePerTx, "Must have credit or min value");

        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");

            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
        }

        if (credits[msg.sender] > 0) {
            credits[msg.sender] = credits[msg.sender].sub(1);
        }
        else {
            address(this).transfer(msg.value);
        }

        return true;
    }

    
    function () external payable {}

    function moveEther(address payable _account) onlyOwner public returns (bool)  {
        _account.transfer(address(this).balance);
        return true;
    }

    function moveTokens(address _token, address _account) public onlyOwner returns (bool) {
        IERC20(_token).transfer(_account, IERC20(_token).balanceOf(address(this)));
        return true;
    }

    function addCredit(address _to, uint256 _amount) public onlyOwner returns (bool) {
        credits[_to] = credits[_to].add(_amount);
        return true;
    }

    function setPricePerTx( uint256 _pricePerTxt) public onlyOwner returns (bool) {
        pricePerTx = _pricePerTxt;
        return true;
    }
}