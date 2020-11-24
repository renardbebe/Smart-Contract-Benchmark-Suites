 

pragma solidity ^0.4.24;

 
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
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract BalanceVerifier {
    event BlockCreated(uint blockNumber, bytes32 rootHash, string ipfsHash);

     
    mapping (uint => bytes32) public blockHash;

     
    function onVerifySuccess(uint blockNumber, address account, uint balance) internal;

     
    function onCommit(uint blockNumber, bytes32 rootHash, string ipfsHash) internal;

     
    function commit(uint blockNumber, bytes32 rootHash, string ipfsHash) external {
        require(blockHash[blockNumber] == 0, "error_overwrite");
        string memory _hash = ipfsHash;
        onCommit(blockNumber, rootHash, _hash);
        blockHash[blockNumber] = rootHash;
        emit BlockCreated(blockNumber, rootHash, _hash);
    }

     
    function prove(uint blockNumber, address account, uint balance, bytes32[] memory proof) public {
        require(proofIsCorrect(blockNumber, account, balance, proof), "error_proof");
        onVerifySuccess(blockNumber, account, balance);
    }

     
    function proofIsCorrect(uint blockNumber, address account, uint balance, bytes32[] memory proof) public view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(account, balance));
        bytes32 rootHash = blockHash[blockNumber];
        require(rootHash != 0x0, "error_blockNotFound");
        return rootHash == calculateRootHash(hash, proof);
    }

     
    function calculateRootHash(bytes32 hash, bytes32[] memory others) public pure returns (bytes32 root) {
        root = hash;
        for (uint8 i = 0; i < others.length; i++) {
            bytes32 other = others[i];
            if (other == 0x0) continue;      
            if (root < other) {
                root = keccak256(abi.encodePacked(root, other));
            } else {
                root = keccak256(abi.encodePacked(other, root));
            }
        }
    }
}

 
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}




 
contract Monoplasma is BalanceVerifier, Ownable {
    using SafeMath for uint256;

    event OperatorChanged(address indexed newOperator);
    event AdminFeeChanged(uint adminFee);
     
    uint public blockFreezeSeconds;

     
    mapping (uint => uint) public blockTimestamp;

    address public operator;

     
    uint public adminFee;

    IERC20 public token;

    mapping (address => uint) public earnings;
    mapping (address => uint) public withdrawn;
    uint public totalWithdrawn;
    uint public totalProven;

    constructor(address tokenAddress, uint blockFreezePeriodSeconds, uint _adminFee) public {
        blockFreezeSeconds = blockFreezePeriodSeconds;
        token = IERC20(tokenAddress);
        operator = msg.sender;
        setAdminFee(_adminFee);
    }

    function setOperator(address newOperator) public onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

     
    function setAdminFee(uint _adminFee) public onlyOwner {
        require(adminFee <= 1 ether, "Admin fee cannot be greater than 1");
        adminFee = _adminFee;
        emit AdminFeeChanged(_adminFee);
    }

     
    function onCommit(uint blockNumber, bytes32, string) internal {
        require(msg.sender == operator, "error_notPermitted");
        blockTimestamp[blockNumber] = now;
    }

     
    function onVerifySuccess(uint blockNumber, address account, uint newEarnings) internal {
        uint blockFreezeStart = blockTimestamp[blockNumber];
        require(now > blockFreezeStart + blockFreezeSeconds, "error_frozen");
        require(earnings[account] < newEarnings, "error_oldEarnings");
        totalProven = totalProven.add(newEarnings).sub(earnings[account]);
        require(totalProven.sub(totalWithdrawn) <= token.balanceOf(this), "error_missingBalance");
        earnings[account] = newEarnings;
    }

     
    function withdrawAll(uint blockNumber, uint totalEarnings, bytes32[] proof) external {
        withdrawAllFor(msg.sender, blockNumber, totalEarnings, proof);
    }

     
    function withdrawAllFor(address recipient, uint blockNumber, uint totalEarnings, bytes32[] proof) public {
        prove(blockNumber, recipient, totalEarnings, proof);
        uint withdrawable = totalEarnings.sub(withdrawn[recipient]);
        withdrawTo(recipient, recipient, withdrawable);
    }

     
    function withdrawAllTo(address recipient, uint blockNumber, uint totalEarnings, bytes32[] proof) external {
        prove(blockNumber, msg.sender, totalEarnings, proof);
        uint withdrawable = totalEarnings.sub(withdrawn[msg.sender]);
        withdrawTo(recipient, msg.sender, withdrawable);
    }

     
    function withdraw(uint amount) public {
        withdrawTo(msg.sender, msg.sender, amount);
    }

     
    function withdrawFor(address recipient, uint amount) public {
        withdrawTo(recipient, recipient, amount);
    }

     
    function withdrawTo(address recipient, address account, uint amount) public {
        require(amount > 0, "error_zeroWithdraw");
        uint w = withdrawn[account].add(amount);
        require(w <= earnings[account], "error_overdraft");
        withdrawn[account] = w;
        totalWithdrawn = totalWithdrawn.add(amount);
        require(token.transfer(recipient, amount), "error_transfer");
    }
}


contract CommunityProduct is Monoplasma {

    string public joinPartStream;

    constructor(address operator, string joinPartStreamId, address tokenAddress, uint blockFreezePeriodSeconds, uint adminFeeFraction)
    Monoplasma(tokenAddress, blockFreezePeriodSeconds, adminFeeFraction) public {
        setOperator(operator);
        joinPartStream = joinPartStreamId;
    }
}