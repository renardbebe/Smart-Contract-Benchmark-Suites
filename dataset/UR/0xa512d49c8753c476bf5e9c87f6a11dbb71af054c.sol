 

pragma solidity ^0.5.0;

 
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

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HarukaTest01 is IERC20 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    using SafeMath for uint256;

    enum ReleaseType {
        Public,
        Private1,
        Private23,
        Foundation,
        Ecosystem,
        Team,
        Airdrop,
        Contributor
    }

     
    mapping (address => ReleaseType) private _accountType;

     
     
    mapping (address => uint256) private _totalBalance;
    mapping (address => uint256) private _spentBalance;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply = 10_000_000_000E18;

    string private _name = "Haruka Test Token #01";
    string private _symbol = "HARUKAT01";
    uint8 private _decimals = 18;

    address public owner;

     
     
    uint256 public reference_time = 2000000000;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;

         
        _totalBalance[owner] = _totalSupply;
        _accountType[owner] = ReleaseType.Private1;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        _allowed[_from][_to] = _allowed[_from][_to].sub(_value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(value <= balanceOf(from));
        require(to != address(0));

        _spentBalance[from] = _spentBalance[from].add(value);
        _totalBalance[to] = _totalBalance[to].add(value);
        emit Transfer(from, to, value);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
     
     
     
     
     
    function balanceOf(address _owner) public view returns (uint256) {
         
        ReleaseType _type = _accountType[_owner];
        uint256 balance = _totalBalance[_owner].sub(_spentBalance[_owner]);

         
         
        if (_owner == owner) {
            return balance;
        }

         
        uint256 elapsed = now - reference_time;
         
        if (elapsed < 0) {
            return 0;
        }
         
        if (elapsed >= 21 * 30 minutes) {
            return balance;
        }

         
        if (_type == ReleaseType.Public) {
             
            return balance;
        } else if (_type == ReleaseType.Private1) {
            if (elapsed < 3 * 30 minutes) {
                return 0;
            } else if (elapsed < 6 * 30 minutes) {
                return balance / 6;
            } else if (elapsed < 9 * 30 minutes) {
                return balance * 2 / 6;
            } else if (elapsed < 12 * 30 minutes) {
                return balance * 3 / 6;
            } else if (elapsed < 15 * 30 minutes) {
                return balance * 4 / 6;
            } else if (elapsed < 18 * 30 minutes) {
                return balance * 5 / 6;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Private23) {
            if (elapsed < 6 * 30 minutes) {
                return 0;
            } else if (elapsed < 9 * 30 minutes) {
                return balance / 4;
            } else if (elapsed < 12 * 30 minutes) {
                return balance * 2 / 4;
            } else if (elapsed < 15 * 30 minutes) {
                return balance * 3 / 4;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Foundation) {
            if (elapsed < 3 * 30 minutes) {
                return 0;
            } else if (elapsed < 6 * 30 minutes) {
                return balance * 3 / 20;
            } else if (elapsed < 9 * 30 minutes) {
                return balance * 6 / 20;
            } else if (elapsed < 12 * 30 minutes) {
                return balance * 9 / 20;
            } else if (elapsed < 15 * 30 minutes) {
                return balance * 12 / 20;
            } else if (elapsed < 18 * 30 minutes) {
                return balance * 15 / 20;
            } else if (elapsed < 21 * 30 minutes) {
                return balance * 18 / 20;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Ecosystem) {
            if (elapsed < 3 * 30 minutes) {
                return balance * 5 / 30;
            } else if (elapsed < 6 * 30 minutes) {
                return balance * 10 / 30;
            } else if (elapsed < 9 * 30 minutes) {
                return balance * 15 / 30;
            } else if (elapsed < 12 * 30 minutes) {
                return balance * 18 / 30;
            } else if (elapsed < 15 * 30 minutes) {
                return balance * 21 / 30;
            } else if (elapsed < 18 * 30 minutes) {
                return balance * 24 / 30;
            } else if (elapsed < 21 * 30 minutes) {
                return balance * 27 / 30;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Team) {
            if (elapsed < 12 * 30 minutes) {
                return 0;
            } else if (elapsed < 15 * 30 minutes) {
                return balance / 4;
            } else if (elapsed < 18 * 30 minutes) {
                return balance * 2 / 4;
            } else if (elapsed < 21 * 30 minutes) {
                return balance * 3 / 4;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Airdrop) {
            if (elapsed < 3 * 30 minutes) {
                return balance / 2;
            } else {
                return balance;
            }
        } else if (_type == ReleaseType.Contributor) {
            if (elapsed < 12 * 30 minutes) {
                return 0;
            } else if (elapsed < 15 * 30 minutes) {
                return balance / 4;
            } else if (elapsed < 18 * 30 minutes) {
                return balance * 2 / 4;
            } else if (elapsed < 21 * 30 minutes) {
                return balance * 3 / 4;
            } else {
                return balance;
            }
        }

         
        return 0;

    }

     
    function totalBalanceOf(address _owner) public view returns (uint256) {
        return _totalBalance[_owner].sub(_spentBalance[_owner]);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }

     
     
    function setReleaseType(address _target, ReleaseType _type) public onlyOwner {
        require(_target != address(0));
        _accountType[_target] = _type;
    }

     
     
    function setReferenceTime(uint256 newTime) public onlyOwner {
        reference_time = newTime;
    }

     
     
    function ownerTransfer(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}