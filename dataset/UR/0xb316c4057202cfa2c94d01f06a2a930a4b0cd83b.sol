 

 
pragma solidity 0.4.26;

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert( c >= a );
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a - b;
        assert( c <= a );
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a * b;
        assert( c == 0 || c / a == b );
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
    function pow(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a ** b;
        assert( c % a == 0 );
        return a ** b;
    }
}

 
pragma solidity 0.4.26;

contract Owned {
     
    address public owner = msg.sender;
     
    constructor(address _owner) public {
        if ( _owner == address(0x00000000000000000000000000000000000000) ) {
            _owner = msg.sender;
        }
        owner = _owner;
    }
     
    function replaceOwner(address _owner) external returns(bool) {
        require( isOwner() );
        owner = _owner;
        return true;
    }
     
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
     
    modifier forOwner {
        require( isOwner() );
        _;
    }
}

 
pragma solidity 0.4.26;

contract TokenDB is Owned {
     
    using SafeMath for uint256;
     
    struct balances_s {
        uint256 amount;
        bool valid;
    }
    struct vesting_s {
        uint256 amount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 claimedAmount;
        bool    valid;
    }
     
    mapping(address => mapping(address => uint256)) private allowance;
    mapping(address => balances_s) private balances;
    mapping(address => vesting_s) public vesting;
    uint256 public totalSupply;
    address public tokenAddress;
    address public oldDBAddress;
    uint256 public totalVesting;
     
    constructor(address _owner, address _tokenAddress, address _oldDBAddress) Owned(_owner) public {}
     
    function changeTokenAddress(address _tokenAddress) external forOwner {}
    function mint(address _to, uint256 _amount) external returns(bool _success) {}
    function transfer(address _from, address _to, uint256 _amount) external returns(bool _success) {}
    function bulkTransfer(address _from, address[] memory _to, uint256[] memory _amount) public returns(bool _success) {}
    function setAllowance(address _owner, address _spender, uint256 _amount) external returns(bool _success) {}
    function setVesting(address _owner, uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) external returns(bool _success) {}
     
    function getAllowance(address _owner, address _spender) public view returns(bool _success, uint256 _remaining) {}
    function getBalance(address _owner) public view returns(bool _success, uint256 _balance) {}
    function getTotalSupply() public view returns(bool _success, uint256 _totalSupply) {}
    function getTotalVesting() public view returns(bool _success, uint256 _totalVesting) {}
    function getVesting(address _owner) public view returns(bool _success, uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount, bool _valid) {}
     
    function _getBalance(address _owner) internal view returns(uint256 _balance) {}
    function _getTotalSupply() internal view returns(uint256 _totalSupply) {}
    function _getTotalVesting() internal view returns(uint256 _totalVesting) {}
}

 
pragma solidity 0.4.26;

contract Token is Owned {
     
    using SafeMath for uint256;
     
    string  public name = "Screenist Token";
    string  public symbol = "NIS";
    uint8   public decimals = 8;
    address public libAddress;
    address public freezeAdmin;
    address public vestingAdmin;
    TokenDB public db;
    bool    public underFreeze;
     
    constructor(address _owner, address _freezeAdmin, address _vestingAdmin, address _libAddress, address _dbAddress, bool _isLib) Owned(_owner) public {
        if ( ! _isLib ) {
            db = TokenDB(_dbAddress);
            libAddress = _libAddress;
            vestingAdmin = _vestingAdmin;
            freezeAdmin = _freezeAdmin;
            require( db.setAllowance(address(this), _owner, uint256(0)-1) );
            require( db.mint(address(this), 1.55e16) );
            emit Mint(address(this), 1.55e16);
        }
    }
     
    function () external payable {
        owner.transfer(msg.value);
    }
     
    function changeLibAddress(address _libAddress) public forOwner {
        libAddress = _libAddress;
    }
    function changeDBAddress(address _dbAddress) public forOwner {
        db = TokenDB(_dbAddress);
    }
    function setFreezeStatus(bool _newStatus) public forFreezeAdmin {
        underFreeze = _newStatus;
    }
    function approve(address _spender, uint256 _value) public returns (bool _success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function transfer(address _to, uint256 _amount) public isNotFrozen returns(bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function bulkTransfer(address[] memory _to, uint256[] memory _amount) public isNotFrozen returns(bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function transferFrom(address _from, address _to, uint256 _amount) public isNotFrozen returns (bool _success)  {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function setVesting(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock) public forVestingAdmin {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
    function claimVesting() public isNotFrozen {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0)
            }
        }
    }
     
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function balanceOf(address _owner) public constant returns (uint256 _balance) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function totalSupply() public constant returns (uint256 _totalSupply) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function getVesting(address _owner) public constant returns(uint256 _amount, uint256 _startBlock, uint256 _endBlock, uint256 _claimedAmount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x80)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x80)
            }
        }
    }
    function totalVesting() public constant returns(uint256 _amount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
    function calcVesting(address _owner) public constant returns(uint256 _reward) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x40)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                revert(0, 0)
            } default {
                return(m, 0x20)
            }
        }
    }
     
    event AllowanceUsed(address indexed _spender, address indexed _owner, uint256 indexed _value);
    event Mint(address indexed _addr, uint256 indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event VestingDefined(address _beneficiary, uint256 _amount, uint256 _startBlock, uint256 _endBlock);
    event VestingClaimed(address _beneficiary, uint256 _amount);
     
    modifier isNotFrozen {
        require( ! underFreeze );
        _;
    }
    modifier forOwner {
        require( isOwner() );
        _;
    }
    modifier forVestingAdmin {
        require( msg.sender == vestingAdmin );
        _;
    }
    modifier forFreezeAdmin {
        require( msg.sender == freezeAdmin );
        _;
    }
}