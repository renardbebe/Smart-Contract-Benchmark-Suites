 

pragma solidity ^0.5.0;

library SafeMath {
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
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 
contract GetFOXToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
    uint256 private _weiRaised;
    
    uint256 private ONE_ETHER = 1 ether;
    uint256 private ONE_THOUSAND_ETHER = 1000 ether;
    uint256 private INITIAL_REWARD = 200000000000000;    

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (address payable wallet, IERC20 token) public {
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _wallet = wallet;
        _token = token;
    }

    function () external payable {
        buyTokens();
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens() public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);

         
        uint256 tokens = _getTokenAmount();

         
        _weiRaised = _weiRaised.add(weiAmount);

        _deliverTokens(msg.sender, tokens);
        emit TokensPurchased(msg.sender, msg.sender, weiAmount, tokens);
        
        _forwardFunds();
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount == ONE_ETHER, "Crowdsale: weiAmount must be 1 ether");
        require(_weiRaised < ONE_THOUSAND_ETHER, "Crowdsale: calculated ether greater than 1000");
        this;  
    }

    function _getTokenAmount() internal view returns (uint256) {
        uint256 reward = INITIAL_REWARD;
        
        if (_weiRaised > 0 && _weiRaised < ONE_THOUSAND_ETHER) {
            uint256 deduct = _weiRaised.div(ONE_ETHER).mul(100000000000);
            reward = INITIAL_REWARD.sub(deduct);
        }
        return reward;
    }
    
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }    

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}