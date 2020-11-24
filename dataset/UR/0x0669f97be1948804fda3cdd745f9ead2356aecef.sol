 

pragma solidity 0.5.12;

contract Owned {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        pendingOwner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == pendingOwner);
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
}

 
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

 
contract TimeLib {
    function getMonth(uint timestamp) public pure returns (uint month);
}

contract ERC20 is IERC20, Owned {
    using SafeMath for uint256;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (uint256 => bool) private fundF;

    string public name = "P2PGuru";
    string public symbol = "P2PG";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    uint256 internal nextQuarter = 1;
    
    address internal A;
    address internal B = 0xd85647bb4a3d9927d210E11cCB16198f676760E5;
    address internal C = 0xa16989E1Da366cBD7dbA477d4d4bAE64FF5D2aC8;
    address internal D = 0x0397C4cA1bA021150295A6FD211Ac5fAD4364207;
    address internal E = 0x89cdae2AED91190aEFBe45F5e89D511de70Abdb4;  
    address internal F = 0x1474e84ffd20277d043eb5F71E11e20D0be9598D;
    address internal G = 0xEC1558E2eEb5005e111dA667AD218b7f8De60029;
    address internal H = 0x3093a574B833Bb0209cF7d3127EB2C0D529EC053;
    address internal I = 0x90e20ac80483a81bbAA255a83E8eaaB08b3973Dc;
    address internal J = 0x0c47528CD8dD2E1bfc87C537923DF9bEFcF5911c;
    address internal K = 0x728b4e873A14c138d6632CB97d8224D941E5eA23;
    address internal L = 0xf5682F93efA570236858B7Cfb6E412B916fc3A05;
    address internal M = 0xAecF030FaB338950427A99Bf8639A6E286BcA8B2;

    constructor() public {
        _totalSupply = 268000000 * 1 ether;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
        A = owner;
        _transfer(A, B, 26800000 * 1 ether);  
        _transfer(A, C, 26800000 * 1 ether);  
        _transfer(A, D, 13400000 * 1 ether);  
        _transfer(A, E, 69680000 * 1 ether);  
    }
    
    modifier onlyGuruFund {
        require(msg.sender == E);
        _;
    }
    
    modifier exceptGuruFund {
        require(msg.sender != E);
        _;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public exceptGuruFund returns (bool success) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
        require(sender != address(0));
        require(recipient != address(0));
        require(balances[sender] >= amount);
        require(allowances[sender][msg.sender] >= amount);

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public exceptGuruFund returns (bool) {
        require(_spender != address(0));

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function tokensByPercentage(uint256 val, uint256 p) public pure returns (uint256) {
        return val.div(100).mul(p);
    }
    
    function getQuarter() internal view returns (uint256) {
        TimeLib tl = TimeLib(0x23d23d8F243e57d0b924bff3A3191078Af325101);
        return (tl.getMonth(now) - 1).div(3) + 1;
    }
        
    function sendDividendsFromE() public onlyGuruFund {
        uint256 currenQuarter = getQuarter();
        if (currenQuarter == nextQuarter) {
            if (nextQuarter == 4) {
                nextQuarter = 1;
            } else {
                nextQuarter = nextQuarter.add(1);
            }
            uint256 tokensToBurn = tokensByPercentage(balances[E], 10);  
            _burn(E, tokensToBurn);  
            uint256 tokensToSend = balances[E].div(2);  
            if (now > 1585699200) {  
                _transfer(E, G, tokensByPercentage(tokensToSend, 30));  
            }
            _transfer(E, H, tokensByPercentage(tokensToSend, 19));  
            _transfer(E, I, tokensByPercentage(tokensToSend, 18));  
            _transfer(E, J, tokensByPercentage(tokensToSend, 10));  
            _transfer(E, K, tokensByPercentage(tokensToSend, 10));  
            _transfer(E, L, tokensByPercentage(tokensToSend, 10));  
            _transfer(E, M, tokensByPercentage(tokensToSend, 3));  
        }
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        balances[account] = balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function sendTokensToF() public onlyOwner {
        uint256 tokensToSend;
        if (now > 1575158400 && now < 1577836800 && fundF[1575158400] == false) {  
            tokensToSend = 10505600 * 1 ether;
            fundF[1575158400] = true;
        } else if (now > 1577836800 && now < 1580515200 && fundF[1577836800] == false) {  
            tokensToSend = 9849000 * 1 ether;
            fundF[1577836800] = true;
        } else if (now > 1580515200 && now < 1583020800 && fundF[1580515200] == false) {  
            tokensToSend = 9192400 * 1 ether;
            fundF[1580515200] = true;
        } else if (now > 1583020800 && now < 1585699200 && fundF[1583020800] == false) {  
            tokensToSend = 8535800 * 1 ether;
            fundF[1583020800] = true;
        } else if (now > 1585699200 && now < 1588291200 && fundF[1585699200] == false) {  
            tokensToSend = 7879200 * 1 ether;
            fundF[1585699200] = true;
        } else if (now > 1588291200 && now < 1590969600 && fundF[1588291200] == false) {  
            tokensToSend = 7222600 * 1 ether;
            fundF[1588291200] = true;
        } else if (now > 1590969600 && now < 1593561600 && fundF[1590969600] == false) {  
            tokensToSend = 6566000 * 1 ether;
            fundF[1590969600] = true;
        } else if (now > 1593561600 && now < 1596240000 && fundF[1593561600] == false) {  
            tokensToSend = 5909400 * 1 ether;
            fundF[1593561600] = true;
        } else if (now > 1596240000 && now < 1598918400 && fundF[1596240000] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1596240000] = true;
        } else if (now > 1598918400 && now < 1601510400 && fundF[1598918400] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1598918400] = true;
        } else if (now > 1601510400 && now < 1604188800 && fundF[1601510400] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1601510400] = true;
        } else if (now > 1604188800 && now < 1606780800 && fundF[1604188800] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1604188800] = true;
        } else if (now > 1606780800 && now < 1609459200 && fundF[1606780800] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1606780800] = true;
        } else if (now > 1609459200 && now < 1612137600 && fundF[1609459200] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1609459200] = true;
        } else if (now > 1612137600 && now < 1614556800 && fundF[1612137600] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1612137600] = true;
        } else if (now > 1614556800 && now < 1617235200 && fundF[1614556800] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1614556800] = true;
        } else if (now > 1617235200 && now < 1619827200 && fundF[1617235200] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1617235200] = true;
        } else if (now > 1619827200 && now < 1622505600 && fundF[1619827200] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1619827200] = true;
        } else if (now > 1622505600 && now < 1625097600 && fundF[1622505600] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1622505600] = true;
        } else if (now > 1625097600 && now < 1627776000 && fundF[1625097600] == false) {  
            tokensToSend = 5252800 * 1 ether;
            fundF[1625097600] = true;
        } else if (now > 1627776000 && now < 1630454400 && fundF[1627776000] == false) {  
            tokensToSend = 2626400 * 1 ether;
            fundF[1627776000] = true;
        }
        _transfer(A, F, tokensToSend);
    }
}