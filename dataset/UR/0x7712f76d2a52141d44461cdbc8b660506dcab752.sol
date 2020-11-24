 

pragma solidity ^0.5.11;

 
 
 
 
 
 
 
 
 


 
library SafeMath256 {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


 
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
interface IAllocation {
    function reservedOf(address account) external view returns (uint256);
}


 
interface IVoken2 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mintWithAllocation(address account, uint256 amount, address allocationContract) external returns (bool);
}


 
contract Ownable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);


     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address currentOwner, address newOwner) {
        currentOwner = _owner;
        newOwner = _newOwner;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _newOwner = newOwner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner address");
        require(msg.sender != address(0), "Ownable: caller is the zero address");

        emit OwnershipAccepted(_owner, msg.sender);
        _owner = msg.sender;
        _newOwner = address(0);
    }

     
    function rescueTokens(address tokenAddr, address recipient, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Withdraw: recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }
}


 
contract VokenShareholders is Ownable, IAllocation {
    using SafeMath256 for uint256;
    using Roles for Roles.Role;

    IVoken2 private _VOKEN = IVoken2(0xFfFAb974088Bd5bF3d7E6F522e93Dd7861264cDB);
    Roles.Role private _proxies;

    uint256 private _ALLOCATION_TIMESTAMP = 1598918399;  
    uint256 private _ALLOCATION_INTERVAL = 1 days;
    uint256 private _ALLOCATION_STEPS = 60;

    uint256 private _page;
    uint256 private _weis;
    uint256 private _vokens;

    address[] private _shareholders;
    mapping (address => bool) private _isShareholder;

    mapping (address => uint256) private _withdrawPos;
    mapping (uint256 => address[]) private _pageShareholders;
    mapping (uint256 => mapping (address => bool)) private _isPageShareholder;

    mapping (uint256 => uint256) private _pageEndingBlock;
    mapping (uint256 => uint256) private _pageEthers;
    mapping (uint256 => uint256) private _pageVokens;
    mapping (uint256 => uint256) private _pageVokenSum;
    mapping (uint256 => mapping (address => uint256)) private _pageVokenHoldings;
    mapping (uint256 => mapping (address => uint256)) private _pageEtherDividends;

    mapping (address => uint256) private _allocations;

    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);
    event Dividend(address indexed account, uint256 amount, uint256 page);


     
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

     
    function isProxy(address account) public view returns (bool) {
        return _proxies.has(account);
    }

     
    function addProxy(address account) public onlyOwner {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

     
    function removeProxy(address account) public onlyOwner {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }

     
    function VOKEN() public view returns (IVoken2) {
        return _VOKEN;
    }

     
    function page() public view returns (uint256) {
        return _page;
    }

     
    function weis() public view returns (uint256) {
        return _weis;
    }

     
    function vokens() public view returns (uint256) {
        return _vokens;
    }

     
    function shareholders(uint256 pageNumber) public view returns (address[] memory) {
        if (pageNumber > 0) {
            return _pageShareholders[pageNumber];
        }

        return _shareholders;
    }

     
    function shareholdersCounter(uint256 pageNumber) public view returns (uint256) {
        if (pageNumber > 0) {
            return _pageShareholders[pageNumber].length;
        }

        return _shareholders.length;
    }

     
    function pageEther(uint256 pageNumber) public view returns (uint256) {
        return _pageEthers[pageNumber];
    }

     
    function pageEtherSum(uint256 pageNumber) public view returns (uint256) {
        uint256 __page = _pageNumber(pageNumber);
        uint256 __amount;

        for (uint256 i = 1; i <= __page; i++) {
            __amount = __amount.add(_pageEthers[i]);
        }

        return __amount;
    }

     
    function pageVoken(uint256 pageNumber) public view returns (uint256) {
        return _pageVokens[pageNumber];
    }

     
    function pageVokenSum(uint256 pageNumber) public view returns (uint256) {
        return _pageVokenSum[_pageNumber(pageNumber)];
    }

     
    function pageEndingBlock(uint256 pageNumber) public view returns (uint256) {
        return _pageEndingBlock[pageNumber];
    }

     
    function _pageNumber(uint256 pageNumber) internal view returns (uint256) {
        if (pageNumber > 0) {
            return pageNumber;
        }

        else {
            return _page;
        }
    }

     
    function vokenHolding(address account, uint256 pageNumber) public view returns (uint256) {
        uint256 __page;
        uint256 __amount;

        if (pageNumber > 0) {
            __page = pageNumber;
        }

        else {
            __page = _page;
        }

        for (uint256 i = 1; i <= __page; i++) {
            __amount = __amount.add(_pageVokenHoldings[i][account]);
        }

        return __amount;
    }

     
    function etherDividend(address account, uint256 pageNumber) public view returns (uint256 amount,
                                                                                     uint256 dividend,
                                                                                     uint256 remain) {
        if (pageNumber > 0) {
            amount = pageEther(pageNumber).mul(vokenHolding(account, pageNumber)).div(pageVokenSum(pageNumber));
            dividend = _pageEtherDividends[pageNumber][account];
        }

        else {
            for (uint256 i = 1; i <= _page; i++) {
                uint256 __pageEtherDividend = pageEther(i).mul(vokenHolding(account, i)).div(pageVokenSum(i));
                amount = amount.add(__pageEtherDividend);
                dividend = dividend.add(_pageEtherDividends[i][account]);
            }
        }

        remain = amount.sub(dividend);
    }

     
    function allocation(address account) public view returns (uint256) {
        return _allocations[account];
    }

     
    function reservedOf(address account) public view returns (uint256 reserved) {
        reserved = _allocations[account];

        if (now > _ALLOCATION_TIMESTAMP && reserved > 0) {
            uint256 __passed = now.sub(_ALLOCATION_TIMESTAMP).div(_ALLOCATION_INTERVAL).add(1);

            if (__passed > _ALLOCATION_STEPS) {
                reserved = 0;
            }
            else {
                reserved = reserved.sub(reserved.mul(__passed).div(_ALLOCATION_STEPS));
            }
        }
    }


     
    constructor () public {
        _page = 1;

        addProxy(msg.sender);
    }

     
    function () external payable {
         
        if (msg.value > 0) {
            _weis = _weis.add(msg.value);
            _pageEthers[_page] = _pageEthers[_page].add(msg.value);
        }

         
        else if (_isShareholder[msg.sender]) {
            uint256 __vokenHolding;

            for (uint256 i = 1; i <= _page.sub(1); i++) {
                __vokenHolding = __vokenHolding.add(_pageVokenHoldings[i][msg.sender]);

                if (_withdrawPos[msg.sender] < i) {
                    uint256 __etherAmount = _pageEthers[i].mul(__vokenHolding).div(_pageVokenSum[i]);

                    _withdrawPos[msg.sender] = i;
                    _pageEtherDividends[i][msg.sender] = __etherAmount;

                    msg.sender.transfer(__etherAmount);
                    emit Dividend(msg.sender, __etherAmount, i);
                }
            }
        }

        assert(true);
    }

     
    function endPage() public onlyProxy {
        require(_pageEthers[_page] > 0, "Ethers on current page is zero.");

        _pageEndingBlock[_page] = block.number;

        _page = _page.add(1);
        _pageVokenSum[_page] = _vokens;

        assert(true);
    }

     
    function pushShareholders(address[] memory accounts, uint256[] memory values) public onlyProxy {
        require(accounts.length == values.length, "Shareholders: batch length is not match");

        for (uint256 i = 0; i < accounts.length; i++) {
            address __account = accounts[i];
            uint256 __value = values[i];

            if (!_isShareholder[__account]) {
                _shareholders.push(__account);
                _isShareholder[__account] = true;
            }

            if (!_isPageShareholder[_page][__account]) {
                _pageShareholders[_page].push(__account);
                _isPageShareholder[_page][__account] = true;
            }

            _vokens = _vokens.add(__value);
            _pageVokens[_page] = _pageVokens[_page].add(__value);
            _pageVokenSum[_page] = _vokens;
            _pageVokenHoldings[_page][__account] = _pageVokenHoldings[_page][__account].add(__value);

            _allocations[__account] = _allocations[__account].add(__value);
            assert(_VOKEN.mintWithAllocation(__account, __value, address(this)));
        }

        assert(true);
    }
}