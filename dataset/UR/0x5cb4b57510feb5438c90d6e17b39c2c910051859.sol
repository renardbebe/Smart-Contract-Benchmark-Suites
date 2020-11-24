 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity 0.5.10;


contract TokenSender {
     
    function distributeTokens(address[] memory _recipients, address _tokenAddress, uint256[] memory _amounts) public {
        require(_recipients.length > 0, "No recipients");
        require(_recipients.length == _amounts.length, "Must have same length");
        require(_tokenAddress != address(0), "Token address cannot be zero");

        IERC20 token = IERC20(_tokenAddress);
        for (uint i = 0; i < _recipients.length; i++) {
            require(token.transferFrom(msg.sender, _recipients[i], _amounts[i]), "Tokens failed to transfer from sender");
        }
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;




 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;




 
contract TokenVesting is Ownable {
     
     
     
     
     

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

     
    address private _beneficiary;

     
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    bool private _revocable;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

     
    constructor (address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
         
        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(duration > 0, "TokenVesting: duration is 0");
         
        require(start.add(duration) > block.timestamp, "TokenVesting: final time is before current time");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function cliff() public view returns (uint256) {
        return _cliff;
    }

     
    function start() public view returns (uint256) {
        return _start;
    }

     
    function duration() public view returns (uint256) {
        return _duration;
    }

     
    function revocable() public view returns (bool) {
        return _revocable;
    }

     
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

     
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

     
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

     
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

     
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

     
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}

 

pragma solidity 0.5.10;



 
contract TokenVestingFactory {
    event TokenVestingCreated(
        address vesting,
        address token,
        uint256 balance,
        address beneficiary,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    );

     
    function createVestingContracts(
        address token,
        address[] memory beneficiaries,
        uint256[] memory startTimes,
        uint256[] memory cliffDurations,
        uint256[] memory durations,
        uint256[] memory amounts
    ) public {
        require(token != address(0), "Token cannot be zero");
        require(beneficiaries.length > 0, "No beneficiaries");
        require(
            beneficiaries.length == startTimes.length &&
            startTimes.length == cliffDurations.length &&
            cliffDurations.length == durations.length &&
            durations.length == amounts.length,
            "All inputs must have the same length"
        );

        IERC20 erc20 = IERC20(token);

        bool revocable = false;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Beneficiary cannot be zero");
            TokenVesting vesting = new TokenVesting(
                beneficiaries[i],
                startTimes[i],
                cliffDurations[i],
                durations[i],
                revocable
            );

             
            require(erc20.transferFrom(msg.sender, address(this), amounts[i]), "Failed to transfer from Distribution");
            require(erc20.transfer(address(vesting), amounts[i]), "Token failed to transfer");

            emit TokenVestingCreated(address(vesting), token, amounts[i], beneficiaries[i], startTimes[i], cliffDurations[i], durations[i]);
        }
    }
}

 

pragma solidity 0.5.10;





contract TokenDistribution is Ownable {
    TokenSender public tokenSender;
    TokenVestingFactory public vestingFactory;

    constructor() public {
        tokenSender = new TokenSender();
        vestingFactory = new TokenVestingFactory();
    }

    function distributeDirect(
        address token,
        address[] memory directRecipients,
        uint256[] memory directAmounts
    ) public {
        require(msg.sender == owner(), "Only owner");

        IERC20 deployedToken = IERC20(token);

         
        uint256 balance = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(tokenSender), balance);

         
        tokenSender.distributeTokens(directRecipients, token, directAmounts);

         
        deployedToken.approve(address(tokenSender), 0);
    }

    function distributeVesting(
        address token,
        address[] memory vestingBeneficiaries,
        uint256[] memory vestingStartTimes,
        uint256[] memory vestingCliffDurations,
        uint256[] memory vestingDurations,
        uint256[] memory vestingAmounts
    ) public {
        require(msg.sender == owner(), "Only owner");

        IERC20 deployedToken = IERC20(token);

         
        uint256 balance = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(vestingFactory), balance);

         
        vestingFactory.createVestingContracts(
            token,
            vestingBeneficiaries,
            vestingStartTimes,
            vestingCliffDurations,
            vestingDurations,
            vestingAmounts
        );

         
        deployedToken.approve(address(vestingFactory), 0);
    }

    function withdraw(address token) public {
        require(msg.sender == owner(), "Only owner");

        IERC20 deployedToken = IERC20(token);

         
        uint256 newBalance = deployedToken.balanceOf(address(this));
        require(deployedToken.transfer(msg.sender, newBalance), "Token failed to transfer");
    }

     
    function distributeToken(
        address token,
        address[] memory vestingBeneficiaries,
        uint256[] memory vestingStartTimes,
        uint256[] memory vestingCliffDurations,
        uint256[] memory vestingDurations,
        uint256[] memory vestingAmounts,
        address[] memory directRecipients,
        uint256[] memory directAmounts
    ) public {
        require(msg.sender == owner(), "Only owner");

        IERC20 deployedToken = IERC20(token);
         
        uint256 senderBalance = deployedToken.balanceOf(msg.sender);
        deployedToken.transferFrom(msg.sender, address(this), senderBalance);

         
        uint256 balance = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(vestingFactory), balance);
        deployedToken.approve(address(tokenSender), balance);

         
        vestingFactory.createVestingContracts(
            token,
            vestingBeneficiaries,
            vestingStartTimes,
            vestingCliffDurations,
            vestingDurations,
            vestingAmounts
        );

         
        tokenSender.distributeTokens(directRecipients, token, directAmounts);

         
        uint256 newBalance = deployedToken.balanceOf(address(this));
        require(deployedToken.transfer(msg.sender, newBalance), "Token failed to transfer");
    }
}