 

pragma solidity >=0.5.3<0.6.0;

 
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

 
interface ERC20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

 
contract Staking {
    struct PendingDeposit {
        address depositor;
        uint256 amount;
    }

    address public _owner;
    address public _authorizedNewOwner;
    address public _tokenAddress;

    address public _withdrawalPublisher;
    address public _fallbackPublisher;
    uint256 public _fallbackWithdrawalDelaySeconds = 1 weeks;

     
    uint256 public _immediatelyWithdrawableLimit = 100_000 * (10**18);
    address public _immediatelyWithdrawableLimitPublisher;

    uint256 public _depositNonce = 0;
    mapping(uint256 => PendingDeposit) public _nonceToPendingDeposit;

    uint256 public _maxWithdrawalRootNonce = 0;
    mapping(bytes32 => uint256) public _withdrawalRootToNonce;
    mapping(address => uint256) public _addressToWithdrawalNonce;
    mapping(address => uint256) public _addressToCumulativeAmountWithdrawn;

    bytes32 public _fallbackRoot;
    uint256 public _fallbackMaxDepositIncluded = 0;
    uint256 public _fallbackSetDate = 2**200;

    event WithdrawalRootHashAddition(
        bytes32 indexed rootHash,
        uint256 indexed nonce
    );

    event WithdrawalRootHashRemoval(
        bytes32 indexed rootHash,
        uint256 indexed nonce
    );

    event FallbackRootHashSet(
        bytes32 indexed rootHash,
        uint256 indexed maxDepositNonceIncluded,
        uint256 setDate
    );

    event Deposit(
        address indexed depositor,
        uint256 indexed amount,
        uint256 indexed nonce
    );

    event Withdrawal(
        address indexed toAddress,
        uint256 indexed amount,
        uint256 indexed rootNonce,
        uint256 authorizedAccountNonce
    );

    event FallbackWithdrawal(
        address indexed toAddress,
        uint256 indexed amount
    );

    event PendingDepositRefund(
        address indexed depositorAddress,
        uint256 indexed amount,
        uint256 indexed nonce
    );

    event RenounceWithdrawalAuthorization(
        address indexed forAddress
    );

    event FallbackWithdrawalDelayUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event FallbackMechanismDateReset(
        uint256 indexed newDate
    );

    event ImmediatelyWithdrawableLimitUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event OwnershipTransferAuthorization(
        address indexed authorizedAddress
    );

    event OwnerUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event FallbackPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event WithdrawalPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event ImmediatelyWithdrawableLimitPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    constructor(
        address tokenAddress,
        address fallbackPublisher,
        address withdrawalPublisher,
        address immediatelyWithdrawableLimitPublisher
    ) public {
        _owner = msg.sender;
        _fallbackPublisher = fallbackPublisher;
        _withdrawalPublisher = withdrawalPublisher;
        _immediatelyWithdrawableLimitPublisher = immediatelyWithdrawableLimitPublisher;
        _tokenAddress = tokenAddress;
    }

     

     
    function deposit(uint256 amount) external returns(uint256) {
        require(
            amount > 0,
            "Cannot deposit 0"
        );

        _depositNonce = SafeMath.add(_depositNonce, 1);
        _nonceToPendingDeposit[_depositNonce].depositor = msg.sender;
        _nonceToPendingDeposit[_depositNonce].amount = amount;

        emit Deposit(
            msg.sender,
            amount,
            _depositNonce
        );

        bool transferred = ERC20Token(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(transferred, "Transfer failed");
        
        return _depositNonce;
    }

     
    function renounceWithdrawalAuthorization(address forAddress) external {
        require(
            msg.sender == _owner ||
            msg.sender == _withdrawalPublisher ||
            msg.sender == forAddress,
            "Only the owner, withdrawal publisher, and address in question can renounce a withdrawal authorization"
        );
        require(
            _addressToWithdrawalNonce[forAddress] < _maxWithdrawalRootNonce,
            "Address nonce indicates there are no funds withdrawable"
        );
        _addressToWithdrawalNonce[forAddress] = _maxWithdrawalRootNonce;
        emit RenounceWithdrawalAuthorization(forAddress);
    }

     
    function withdraw(
        address toAddress,
        uint256 amount,
        uint256 maxAuthorizedAccountNonce,
        bytes32[] calldata merkleProof
    ) external {
        require(
            msg.sender == _owner || msg.sender == toAddress,
            "Only the owner or recipient can execute a withdrawal"
        );

        require(
            _addressToWithdrawalNonce[toAddress] <= maxAuthorizedAccountNonce,
            "Account nonce in contract exceeds provided max authorized withdrawal nonce for this account"
        );

        require(
            amount <= _immediatelyWithdrawableLimit,
            "Withdrawal would push contract over its immediately withdrawable limit"
        );

        bytes32 leafDataHash = keccak256(abi.encodePacked(
            toAddress,
            amount,
            maxAuthorizedAccountNonce
        ));

        bytes32 calculatedRoot = calculateMerkleRoot(merkleProof, leafDataHash);
        uint256 withdrawalPermissionRootNonce = _withdrawalRootToNonce[calculatedRoot];

        require(
            withdrawalPermissionRootNonce > 0,
            "Root hash unauthorized");
        require(
            withdrawalPermissionRootNonce > maxAuthorizedAccountNonce,
            "Encoded nonce not greater than max last authorized nonce for this account"
        );

        _immediatelyWithdrawableLimit -= amount;  
        _addressToWithdrawalNonce[toAddress] = withdrawalPermissionRootNonce;
        _addressToCumulativeAmountWithdrawn[toAddress] = SafeMath.add(amount, _addressToCumulativeAmountWithdrawn[toAddress]);

        emit Withdrawal(
            toAddress,
            amount,
            withdrawalPermissionRootNonce,
            maxAuthorizedAccountNonce
        );

        bool transferred = ERC20Token(_tokenAddress).transfer(
            toAddress,
            amount
        );

        require(transferred, "Transfer failed");
    }

     
    function withdrawFallback(
        address toAddress,
        uint256 maxCumulativeAmountWithdrawn,
        bytes32[] calldata merkleProof
    ) external {
        require(
            msg.sender == _owner || msg.sender == toAddress,
            "Only the owner or recipient can execute a fallback withdrawal"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) <= block.timestamp,
            "Fallback withdrawal period is not active"
        );
        require(
            _addressToCumulativeAmountWithdrawn[toAddress] < maxCumulativeAmountWithdrawn,
            "Withdrawal not permitted when amount withdrawn is at lifetime withdrawal limit"
        );

        bytes32 msgHash = keccak256(abi.encodePacked(
            toAddress,
            maxCumulativeAmountWithdrawn
        ));

        bytes32 calculatedRoot = calculateMerkleRoot(merkleProof, msgHash);
        require(
            _fallbackRoot == calculatedRoot,
            "Root hash unauthorized"
        );

         
        _addressToWithdrawalNonce[toAddress] = _maxWithdrawalRootNonce;

         
        uint256 withdrawalAmount = maxCumulativeAmountWithdrawn - _addressToCumulativeAmountWithdrawn[toAddress];
        _addressToCumulativeAmountWithdrawn[toAddress] = maxCumulativeAmountWithdrawn;
        
        emit FallbackWithdrawal(
            toAddress,
            withdrawalAmount
        );

        bool transferred = ERC20Token(_tokenAddress).transfer(
            toAddress,
            withdrawalAmount
        );

        require(transferred, "Transfer failed");
    }

     
    function refundPendingDeposit(uint256 depositNonce) external {
        address depositor = _nonceToPendingDeposit[depositNonce].depositor;
        require(
            msg.sender == _owner || msg.sender == depositor,
            "Only the owner or depositor can initiate the refund of a pending deposit"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) <= block.timestamp,
            "Fallback withdrawal period is not active, so refunds are not permitted"
        );
        uint256 amount = _nonceToPendingDeposit[depositNonce].amount;
        require(
            depositNonce > _fallbackMaxDepositIncluded &&
            amount > 0,
            "There is no pending deposit for the specified nonce"
        );
        delete _nonceToPendingDeposit[depositNonce];

        emit PendingDepositRefund(depositor, amount, depositNonce);

        bool transferred = ERC20Token(_tokenAddress).transfer(
            depositor,
            amount
        );
        require(transferred, "Transfer failed");
    }

     

     
    function authorizeOwnershipTransfer(address authorizedAddress) external {
        require(
            msg.sender == _owner,
            "Only the owner can authorize a new address to become owner"
        );

        _authorizedNewOwner = authorizedAddress;

        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }

     
    function assumeOwnership() external {
        require(
            msg.sender == _authorizedNewOwner,
            "Only the authorized new owner can accept ownership"
        );
        address oldValue = _owner;
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);

        emit OwnerUpdate(oldValue, _owner);
    }

     
    function setWithdrawalPublisher(address newWithdrawalPublisher) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the withdrawal publisher address"
        );
        address oldValue = _withdrawalPublisher;
        _withdrawalPublisher = newWithdrawalPublisher;

        emit WithdrawalPublisherUpdate(oldValue, _withdrawalPublisher);
    }

     
    function setFallbackPublisher(address newFallbackPublisher) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the fallback publisher address"
        );
        address oldValue = _fallbackPublisher;
        _fallbackPublisher = newFallbackPublisher;

        emit FallbackPublisherUpdate(oldValue, _fallbackPublisher);
    }

     
    function setImmediatelyWithdrawableLimitPublisher(
      address newImmediatelyWithdrawableLimitPublisher
    ) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the immediately withdrawable limit publisher address"
        );
        address oldValue = _immediatelyWithdrawableLimitPublisher;
        _immediatelyWithdrawableLimitPublisher = newImmediatelyWithdrawableLimitPublisher;

        emit ImmediatelyWithdrawableLimitPublisherUpdate(
          oldValue,
          _immediatelyWithdrawableLimitPublisher
        );
    }

     
    function modifyImmediatelyWithdrawableLimit(int256 amount) external {
        require(
            msg.sender == _owner || msg.sender == _immediatelyWithdrawableLimitPublisher,
            "Only the immediately withdrawable limit publisher and owner can modify the immediately withdrawable limit"
        );
        uint256 oldLimit = _immediatelyWithdrawableLimit;

        if (amount < 0) {
            uint256 unsignedAmount = uint256(-amount);
            _immediatelyWithdrawableLimit = SafeMath.sub(_immediatelyWithdrawableLimit, unsignedAmount);
        } else {
            uint256 unsignedAmount = uint256(amount);
            _immediatelyWithdrawableLimit = SafeMath.add(_immediatelyWithdrawableLimit, unsignedAmount);
        }

        emit ImmediatelyWithdrawableLimitUpdate(oldLimit, _immediatelyWithdrawableLimit);
    }

     
    function setFallbackWithdrawalDelay(uint256 newFallbackDelaySeconds) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the fallback withdrawal delay"
        );
        require(
            newFallbackDelaySeconds != 0,
            "New fallback delay may not be 0"
        );

        uint256 oldDelay = _fallbackWithdrawalDelaySeconds;
        _fallbackWithdrawalDelaySeconds = newFallbackDelaySeconds;

        emit FallbackWithdrawalDelayUpdate(oldDelay, newFallbackDelaySeconds);
    }

     
    function addWithdrawalRoot(
        bytes32 root,
        uint256 nonce,
        bytes32[] calldata replacedRoots
    ) external {
        require(
            msg.sender == _owner || msg.sender == _withdrawalPublisher,
            "Only the owner and withdrawal publisher can add and replace withdrawal root hashes"
        );
        require(
            root != 0,
            "Added root may not be 0"
        );
        require(
             
            _maxWithdrawalRootNonce + 1 == nonce,
            "Nonce must be exactly max nonce + 1"
        );
        require(
            _withdrawalRootToNonce[root] == 0,
            "Root already exists and is associated with a different nonce"
        );

        _withdrawalRootToNonce[root] = nonce;
        _maxWithdrawalRootNonce = nonce;

        emit WithdrawalRootHashAddition(root, nonce);

        for (uint256 i = 0; i < replacedRoots.length; i++) {
            deleteWithdrawalRoot(replacedRoots[i]);
        }
    }

     
    function removeWithdrawalRoots(bytes32[] calldata roots) external {
        require(
            msg.sender == _owner || msg.sender == _withdrawalPublisher,
            "Only the owner and withdrawal publisher can remove withdrawal root hashes"
        );

        for (uint256 i = 0; i < roots.length; i++) {
            deleteWithdrawalRoot(roots[i]);
        }
    }

     
    function resetFallbackMechanismDate() external {
        require(
            msg.sender == _owner || msg.sender == _fallbackPublisher,
            "Only the owner and fallback publisher can reset fallback mechanism date"
        );

        _fallbackSetDate = block.timestamp;

        emit FallbackMechanismDateReset(_fallbackSetDate);
    }

     
    function setFallbackRoot(bytes32 root, uint256 maxDepositIncluded) external {
        require(
            msg.sender == _owner || msg.sender == _fallbackPublisher,
            "Only the owner and fallback publisher can set the fallback root hash"
        );
        require(
            root != 0,
            "New root may not be 0"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) > block.timestamp,
            "Cannot set fallback root while fallback mechanism is active"
        );
        require(
            maxDepositIncluded >= _fallbackMaxDepositIncluded,
            "Max deposit included must remain the same or increase"
        );
        require(
            maxDepositIncluded <= _depositNonce,
            "Cannot invalidate future deposits"
        );

        _fallbackRoot = root;
        _fallbackMaxDepositIncluded = maxDepositIncluded;
        _fallbackSetDate = block.timestamp;

        emit FallbackRootHashSet(
            root,
            _fallbackMaxDepositIncluded,
            block.timestamp
        );
    }

     
    function deleteWithdrawalRoot(bytes32 root) private {
        uint256 nonce = _withdrawalRootToNonce[root];

        require(
            nonce > 0,
            "Root hash not set"
        );

        delete _withdrawalRootToNonce[root];

        emit WithdrawalRootHashRemoval(root, nonce);
    }

     
    function calculateMerkleRoot(
        bytes32[] memory merkleProof,
        bytes32 leafHash
    ) private pure returns (bytes32) {
        bytes32 computedHash = leafHash;

        for (uint256 i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(
                    computedHash,
                    proofElement
                ));
            } else {
                computedHash = keccak256(abi.encodePacked(
                    proofElement,
                    computedHash
                ));
            }
        }

        return computedHash;
    }
}