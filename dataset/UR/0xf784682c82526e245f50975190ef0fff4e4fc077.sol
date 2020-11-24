 

pragma solidity 0.4.24;
 

contract Owned {
     
    address public owner = msg.sender;
     
    constructor(address _owner) public {
        if ( _owner == 0x00 ) {
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
contract TokenDB {}
contract Ico {}
 

contract Token is Owned {
     
    using SafeMath for uint256;
     
    string  public name = "Inlock token";
    string  public symbol = "ILK";
    uint8   public decimals = 8;
    uint256 public totalSupply = 44e16;
    address public libAddress;
    TokenDB public db;
    Ico public ico;
     
    constructor(address _owner, address _libAddress, address _dbAddress, address _icoAddress) Owned(_owner) public {
        libAddress = _libAddress;
        db = TokenDB(_dbAddress);
        ico = Ico(_icoAddress);
        emit Mint(_icoAddress, totalSupply);
    }
     
    function () public { revert(); }
     
    function changeLibAddress(address _libAddress) external forOwner {
        libAddress = _libAddress;
    }
    function changeDBAddress(address _dbAddress) external forOwner {
        db = TokenDB(_dbAddress);
    }
    function changeIcoAddress(address _icoAddress) external forOwner {
        ico = Ico(_icoAddress);
    }
    function approve(address _spender, uint256 _value) external returns (bool _success) {
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
    function transfer(address _to, uint256 _amount) external returns (bool _success) {
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
    function bulkTransfer(address[] _to, uint256[] _amount) external returns (bool _success) {
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
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success) {
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
     
    function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
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
    function balanceOf(address _owner) public view returns (uint256 _balance) {
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
}