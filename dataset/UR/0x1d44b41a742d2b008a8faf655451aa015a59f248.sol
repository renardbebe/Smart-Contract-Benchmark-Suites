 

pragma solidity ^0.5.9;

 

 
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

 

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 


 
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

      

    function _changeBeneficiary(address _newBeneficiary) internal {
        _beneficiary = _newBeneficiary;
    }
}

 

 


contract BeneficiaryOperations {

    using SafeMath for uint256;

    using SafeMath for uint8;
     

    uint256 public beneficiariesGeneration;
    uint256 public howManyBeneficiariesDecide;
    address[] public beneficiaries;
    bytes32[] public allOperations;
    address internal insideCallSender;
    uint256 internal insideCallCount;
    

     
    mapping(address => uint8) public beneficiariesIndices;  
    mapping(bytes32 => uint) public allOperationsIndicies;
    

     
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

     
    mapping(bytes32 => uint8) internal  operationsByBeneficiaryIndex;
    mapping(uint8 => uint8) internal operationsCountByBeneficiaryIndex;
     

    event BeneficiaryshipTransferred(address[] previousbeneficiaries, uint howManyBeneficiariesDecide, address[] newBeneficiaries, uint newHowManybeneficiarysDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint beneficiariesCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint beneficiariesCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint beneficiariesCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint beneficiariesCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
    
     

    function isExistBeneficiary(address wallet) public view returns(bool) {
        return beneficiariesIndices[wallet] > 0;
    }


    function beneficiariesCount() public view returns(uint) {
        return beneficiaries.length;
    }

    function allOperationsCount() public view returns(uint) {
        return allOperations.length;
    }

     

    function _operationLimitByBeneficiaryIndex(uint8 beneficiaryIndex) internal view returns(bool) {
        return (operationsCountByBeneficiaryIndex[beneficiaryIndex] <= 3);
    }
    
    function _cancelAllPending() internal {
        for (uint i = 0; i < allOperations.length; i++) {
            delete(allOperationsIndicies[allOperations[i]]);
            delete(votesMaskByOperation[allOperations[i]]);
            delete(votesCountByOperation[allOperations[i]]);
             
            delete(operationsByBeneficiaryIndex[allOperations[i]]);
        }

        allOperations.length = 0;
         
        for (uint8 j = 0; j < beneficiaries.length; j++) {
            operationsCountByBeneficiaryIndex[j] = 0;
        }
    }


     

     
    modifier onlyAnyBeneficiary {
        if (checkHowManyBeneficiaries(1)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = 1;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlyManyBeneficiaries {
        if (checkHowManyBeneficiaries(howManyBeneficiariesDecide)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howManyBeneficiariesDecide;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlyAllBeneficiaries {
        if (checkHowManyBeneficiaries(beneficiaries.length)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = beneficiaries.length;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlySomeBeneficiaries(uint howMany) {
        require(howMany > 0, "onlySomeBeneficiaries: howMany argument is zero");
        require(howMany <= beneficiaries.length, "onlySomeBeneficiaries: howMany argument exceeds the number of Beneficiaries");
        
        if (checkHowManyBeneficiaries(howMany)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howMany;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     

    constructor() public {
        beneficiaries.push(msg.sender);
        beneficiariesIndices[msg.sender] = 1;
        howManyBeneficiariesDecide = 1;
    }

     

     
    function checkHowManyBeneficiaries(uint howMany) internal returns(bool) {
        if (insideCallSender == msg.sender) {
            require(howMany <= insideCallCount, "checkHowManyBeneficiaries: nested beneficiaries modifier check require more beneficiarys");
            return true;
        }
        
        
        require((isExistBeneficiary(msg.sender) && (beneficiariesIndices[msg.sender] <= beneficiaries.length)), "checkHowManyBeneficiaries: msg.sender is not an beneficiary");

        uint beneficiaryIndex = beneficiariesIndices[msg.sender].sub(1);
        
        bytes32 operation = keccak256(abi.encodePacked(msg.data, beneficiariesGeneration));

        require((votesMaskByOperation[operation] & (2 ** beneficiaryIndex)) == 0, "checkHowManyBeneficiaries: beneficiary already voted for the operation");
         
        require(_operationLimitByBeneficiaryIndex(uint8(beneficiaryIndex)), "checkHowManyBeneficiaries: operation limit is reached for this beneficiary");

        votesMaskByOperation[operation] |= (2 ** beneficiaryIndex);
        uint operationVotesCount = votesCountByOperation[operation].add(1);
        votesCountByOperation[operation] = operationVotesCount;

        if (operationVotesCount == 1) {
            allOperationsIndicies[operation] = allOperations.length;
            
            operationsByBeneficiaryIndex[operation] = uint8(beneficiaryIndex);
            
            operationsCountByBeneficiaryIndex[uint8(beneficiaryIndex)] = uint8(operationsCountByBeneficiaryIndex[uint8(beneficiaryIndex)].add(1));
            
            allOperations.push(operation);
            
            
            emit OperationCreated(operation, howMany, beneficiaries.length, msg.sender);
        }
        emit OperationUpvoted(operation, operationVotesCount, howMany, beneficiaries.length, msg.sender);

         
        if (votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, beneficiaries.length, msg.sender);
            return true;
        }

        return false;
    }

     
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) {  
            allOperations[index] = allOperations[allOperations.length.sub(1)];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length = allOperations.length.sub(1);

        uint8 beneficiaryIndex = uint8(operationsByBeneficiaryIndex[operation]);
        operationsCountByBeneficiaryIndex[beneficiaryIndex] = uint8(operationsCountByBeneficiaryIndex[beneficiaryIndex].sub(1));

        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
        delete operationsByBeneficiaryIndex[operation];
    }

     

     
    function cancelPending(bytes32 operation) public onlyAnyBeneficiary {

        require((isExistBeneficiary(msg.sender) && (beneficiariesIndices[msg.sender] <= beneficiaries.length)), "checkHowManyBeneficiaries: msg.sender is not an beneficiary");

        uint beneficiaryIndex = beneficiariesIndices[msg.sender].sub(1);
        require((votesMaskByOperation[operation] & (2 ** beneficiaryIndex)) != 0, "cancelPending: operation not found for this user");
        votesMaskByOperation[operation] &= ~(2 ** beneficiaryIndex);
        uint operationVotesCount = votesCountByOperation[operation].sub(1);
        votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, beneficiaries.length, msg.sender);
        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

     

    function cancelAllPending() public onlyManyBeneficiaries {
       _cancelAllPending();
    }



     

     
    function transferBeneficiaryShip(address[] memory newBeneficiaries) public {
        transferBeneficiaryShipWithHowMany(newBeneficiaries, newBeneficiaries.length);
    }

     
    function transferBeneficiaryShipWithHowMany(address[] memory newBeneficiaries, uint256 newHowManyBeneficiariesDecide) public onlyManyBeneficiaries {
        require(newBeneficiaries.length > 0, "transferBeneficiaryShipWithHowMany: beneficiaries array is empty");
        require(newBeneficiaries.length < 256, "transferBeneficiaryshipWithHowMany: beneficiaries count is greater then 255");
        require(newHowManyBeneficiariesDecide > 0, "transferBeneficiaryshipWithHowMany: newHowManybeneficiarysDecide equal to 0");
        require(newHowManyBeneficiariesDecide <= newBeneficiaries.length, "transferBeneficiaryShipWithHowMany: newHowManybeneficiarysDecide exceeds the number of beneficiarys");

         
        for (uint j = 0; j < beneficiaries.length; j++) {
            delete beneficiariesIndices[beneficiaries[j]];
        }
        for (uint i = 0; i < newBeneficiaries.length; i++) {
            require(newBeneficiaries[i] != address(0), "transferBeneficiaryShipWithHowMany: beneficiaries array contains zero");
            require(beneficiariesIndices[newBeneficiaries[i]] == 0, "transferBeneficiaryShipWithHowMany: beneficiaries array contains duplicates");
            beneficiariesIndices[newBeneficiaries[i]] = uint8(i.add(1));
        }
        
        emit BeneficiaryshipTransferred(beneficiaries, howManyBeneficiariesDecide, newBeneficiaries, newHowManyBeneficiariesDecide);
        beneficiaries = newBeneficiaries;
        howManyBeneficiariesDecide = newHowManyBeneficiariesDecide;

        _cancelAllPending();
       
        beneficiariesGeneration++;
    }
}

 

 


contract AkropolisTokenVesting is TokenVesting, BeneficiaryOperations {

    IERC20 private token;

    address private _pendingBeneficiary;

    event LogBeneficiaryTransferProposed(address _beneficiary);
    event LogBeneficiaryTransfered(address _beneficiary);

    constructor (IERC20 _token, uint256 _start, uint256 _cliffDuration, uint256 _duration) public 
        TokenVesting(msg.sender, _start, _cliffDuration, _duration, false) {
            token = _token;
        }

      

    function release() public {
        super.release(token);
    }


      
    function tokenAddress() public view returns (IERC20) {
        return token;
    }

     
     
    modifier onlyExistingBeneficiary(address _beneficiary) {
        require(isExistBeneficiary(_beneficiary), "address is not in beneficiary array");
        _;
    }

     

    modifier onlyPendingBeneficiary {
        require(msg.sender  == _pendingBeneficiary, "Unpermitted operation.");
        _;
    }

    function pendingBeneficiary() public view returns (address) {
        return _pendingBeneficiary;
    }

      
    function transferBeneficiaryShip(address[] memory _newBeneficiaries) public {
        super.transferBeneficiaryShip(_newBeneficiaries);
        _setPendingBeneficiary(beneficiaries[0]);
    }

      
    
    function transferBeneficiaryShipWithHowMany(address[] memory _newBeneficiaries, uint256 _newHowManyBeneficiariesDecide) public  {
        super.transferBeneficiaryShipWithHowMany(_newBeneficiaries, _newHowManyBeneficiariesDecide);
        _setPendingBeneficiary(beneficiaries[0]);
    }

     
    function changeBeneficiary(address _newBeneficiary) public onlyManyBeneficiaries {
        _setPendingBeneficiary(_newBeneficiary);
    }

     
    function claimBeneficiary() public onlyPendingBeneficiary {
        _changeBeneficiary(_pendingBeneficiary);
        emit LogBeneficiaryTransfered(_pendingBeneficiary);
        _pendingBeneficiary = address(0);
    }

     
     
    function _setPendingBeneficiary(address _newBeneficiary) internal onlyExistingBeneficiary(_newBeneficiary) {
        _pendingBeneficiary = _newBeneficiary;
        emit LogBeneficiaryTransferProposed(_newBeneficiary);
    }
}