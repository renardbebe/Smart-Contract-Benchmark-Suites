 

pragma solidity ^0.5.1;

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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC20Interface {
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
}

contract ChainBot2000 is Ownable {
    
    using SafeMath for uint256;
    
    ERC20Interface DAIContract;
    mapping(bytes32 => uint) public deposits;
    
    event Deposit(address indexed _address, bytes32 indexed _steamid, uint indexed _amount);
    event Purchase(address indexed _address, uint indexed _amount);
    
    constructor(address _address) public {
        DAIContract = ERC20Interface(_address);
    }
    
    function updateBalance(bytes32 _steamid, uint _amount) external {
        assert(DAIContract.transferFrom(msg.sender, address(this), _amount));
        deposits[_steamid] = deposits[_steamid].add( _amount);
        emit Deposit(msg.sender, _steamid, _amount);
	}
	
	function purchase(address _address, uint _amount) external onlyOwner {
	    assert(DAIContract.transfer(_address, _amount));
	    emit Purchase(_address, _amount);
	}
    
}