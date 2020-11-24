 

 

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

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

 

pragma solidity ^0.5.4;



 

contract Reputation is Ownable {

    uint8 public decimals = 18;              
     
    event Mint(address indexed _to, uint256 _amount);
     
    event Burn(address indexed _from, uint256 _amount);

       
       
       
    struct Checkpoint {

     
        uint128 fromBlock;

           
        uint128 value;
    }

       
       
       
    mapping (address => Checkpoint[]) balances;

       
    Checkpoint[] totalSupplyHistory;

     
    constructor(
    ) public
    {
    }

     
     
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

   
   
   
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

       
       
       
       
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

       
       
       
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

       
       
       
       
    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

       
       
       
       
    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

   
   
   

       
       
       
       
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

           
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

           
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

       
       
       
       
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value);  
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

 

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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

 

pragma solidity ^0.5.11;





 

contract DAOToken is ERC20, ERC20Burnable, Ownable {

    string public name;
    string public symbol;
     
    uint8 public constant decimals = 18;
    uint256 public cap;

     
    constructor(string memory _name, string memory _symbol, uint256 _cap)
    public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (cap > 0)
            require(totalSupply().add(_amount) <= cap);
        _mint(_to, _amount);
        return true;
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

 

 
pragma solidity ^0.5.11;



library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

         
         
        require((_value == 0) || (IERC20(_erc20Addr).allowance(address(this), _spender) == 0));

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}

 

pragma solidity ^0.5.11;







 
contract Avatar is Ownable {
    using SafeERC20 for address;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericCall(address indexed _contract, bytes _data, uint _value, bool _success);
    event SendEther(uint256 _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint256 _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint256 _value);
    event ExternalTokenApproval(address indexed _externalToken, address _spender, uint256 _value);
    event ReceiveEther(address indexed _sender, uint256 _value);
    event MetaData(string _metaData);

     
    constructor(string memory _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

     
    function() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

     
    function genericCall(address _contract, bytes memory _data, uint256 _value)
    public
    onlyOwner
    returns(bool success, bytes memory returnValue) {
       
        (success, returnValue) = _contract.call.value(_value)(_data);
        emit GenericCall(_contract, _data, _value, success);
    }

     
    function sendEther(uint256 _amountInWei, address payable _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransfer(_to, _value);
        emit ExternalTokenTransfer(address(_externalToken), _to, _value);
        return true;
    }

     
    function externalTokenTransferFrom(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(address(_externalToken), _from, _to, _value);
        return true;
    }

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeApprove(_spender, _value);
        emit ExternalTokenApproval(address(_externalToken), _spender, _value);
        return true;
    }

     
    function metaData(string memory _metaData) public onlyOwner returns(bool) {
        emit MetaData(_metaData);
        return true;
    }


}

 

pragma solidity ^0.5.11;


contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
     
    function when() public returns(CallPhase);
}

 

pragma solidity ^0.5.11;



 
interface ControllerInterface {

     
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    returns(bool);

     
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    returns(bool);

     
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    returns(bool);

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    returns(bool);

     
    function unregisterScheme(address _scheme, address _avatar)
    external
    returns(bool);

     
    function unregisterSelf(address _avatar) external returns(bool);

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external returns(bool);

     
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external  returns(bool);

   
    function upgradeController(address _newController, Avatar _avatar)
    external returns(bool);

     
    function genericCall(address _contract, bytes calldata _data, Avatar _avatar, uint256 _value)
    external
    returns(bool, bytes memory);

   
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external returns(bool);

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function metaData(string calldata _metaData, Avatar _avatar) external returns(bool);

     
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);

    function isSchemeRegistered( address _scheme, address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme, address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint, address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme, address _avatar) external view returns(bytes4);

     
    function globalConstraintsCount(address _avatar) external view returns(uint, uint);

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar) external view returns(bool);
}

 

pragma solidity ^0.5.11;

 


contract Agreement {

    bytes32 private agreementHash;

    modifier onlyAgree(bytes32 _agreementHash) {
        require(_agreementHash == agreementHash, "Sender must send the right agreementHash");
        _;
    }

     
    function getAgreementHash() external  view returns(bytes32)
    {
        return agreementHash;
    }

     
    function setAgreementHash(bytes32 _agreementHash) internal
    {
        require(agreementHash == bytes32(0), "Can not set agreement twice");
        agreementHash = _agreementHash;
    }


}

 

pragma solidity ^0.5.4;

 


library RealMath {

     
    uint256 constant private REAL_BITS = 256;

     
    uint256 constant private REAL_FBITS = 40;

     
    uint256 constant private REAL_ONE = uint256(1) << REAL_FBITS;

     
    function pow(uint256 realBase, uint256 exponent) internal pure returns (uint256) {

        uint256 tempRealBase = realBase;
        uint256 tempExponent = exponent;

         
        uint256 realResult = REAL_ONE;
        while (tempExponent != 0) {
             
            if ((tempExponent & 0x1) == 0x1) {
                 
                realResult = mul(realResult, tempRealBase);
            }
                 
            tempExponent = tempExponent >> 1;
            if (tempExponent != 0) {
                 
                tempRealBase = mul(tempRealBase, tempRealBase);
            }
        }

         
        return realResult;
    }

     
    function fraction(uint216 numerator, uint216 denominator) internal pure returns (uint256) {
        return div(uint256(numerator) * REAL_ONE, uint256(denominator) * REAL_ONE);
    }

     
    function mul(uint256 realA, uint256 realB) private pure returns (uint256) {
         
         
        uint256 res = realA * realB;
        require(res/realA == realB, "RealMath mul overflow");
        return (res >> REAL_FBITS);
    }

     
    function div(uint256 realNumerator, uint256 realDenominator) private pure returns (uint256) {
         
         
        return uint256((uint256(realNumerator) * REAL_ONE) / uint256(realDenominator));
    }

}

 

pragma solidity ^0.5.11;







 

contract ContinuousLocking4Reputation is Agreement {
    using SafeMath for uint256;
    using SafeERC20 for address;
    using RealMath for uint216;
    using RealMath for uint256;
    using Math for uint256;

    event Redeem(uint256 indexed _lockingId, address indexed _beneficiary, uint256 _amount, uint256 _batchIndex);
    event Release(uint256 indexed _lockingId, address indexed _beneficiary, uint256 _amount);
    event LockToken(address indexed _locker, uint256 indexed _lockingId, uint256 _amount, uint256 _period);
    event ExtendLocking(address indexed _locker, uint256 indexed _lockingId, uint256 _extendPeriod);

    struct Batch {
        uint256 totalScore;
         
        mapping(uint256=>uint) scores;
    }

    struct Lock {
        uint256 amount;
        uint256 lockingTime;
        uint256 period;
    }

     
    mapping(address => mapping(uint256=>Lock)) public lockers;
     
    mapping(uint256 => Batch) public batches;

    Avatar public avatar;
    uint256 public reputationRewardLeft;  
    uint256 public startTime;  
    uint256 public redeemEnableTime;
    uint256 public maxLockingBatches;
    uint256 public batchTime;  
    IERC20 public token;  
    uint256 public lockCounter;  
    uint256 public totalLockedLeft;  
    uint256 public repRewardConstA;
    uint256 public repRewardConstB;
    uint256 public batchesIndexCap;

    uint256 constant private REAL_FBITS = 40;
     

    uint256 constant private REAL_ONE = uint256(1) << REAL_FBITS;
    uint256 constant private BATCHES_INDEX_HARDCAP = 100;
    uint256 constant public MAX_LOCKING_BATCHES_HARDCAP = 24;

     
    function initialize(
        Avatar _avatar,
        uint256 _reputationReward,
        uint256 _startTime,
        uint256 _batchTime,
        uint256 _redeemEnableTime,
        uint256 _maxLockingBatches,
        uint256 _repRewardConstA,
        uint256 _repRewardConstB,
        uint256 _batchesIndexCap,
        IERC20 _token,
        bytes32 _agreementHash )
    external
    {
        require(avatar == Avatar(0), "can be called only one time");
        require(_avatar != Avatar(0), "avatar cannot be zero");
         
        require(_batchTime > 15, "batchTime should be > 15");
        require(_maxLockingBatches <= MAX_LOCKING_BATCHES_HARDCAP,
        "maxLockingBatches should be <= MAX_LOCKING_BATCHES_HARDCAP");
        require(_redeemEnableTime >= _startTime.add(_batchTime),
        "_redeemEnableTime >= _startTime+_batchTime");
        require(_batchesIndexCap <= BATCHES_INDEX_HARDCAP, "_batchesIndexCap > BATCHES_INDEX_HARDCAP");
        token = _token;
        avatar = _avatar;
        startTime = _startTime;
        reputationRewardLeft = _reputationReward;
        redeemEnableTime = _redeemEnableTime;
        maxLockingBatches = _maxLockingBatches;
        batchTime = _batchTime;
        require(_repRewardConstB < 1000, "_repRewardConstB should be < 1000");
        require(repRewardConstA < _reputationReward, "repRewardConstA should be < _reputationReward");
        repRewardConstA = toReal(uint216(_repRewardConstA));
        repRewardConstB = uint216(_repRewardConstB).fraction(uint216(1000));
        batchesIndexCap = _batchesIndexCap;
        super.setAgreementHash(_agreementHash);
    }

     
    function redeem(address _beneficiary, uint256 _lockingId) public returns(uint256 reputation) {
         
        require(now > redeemEnableTime, "now > redeemEnableTime");
        Lock storage locker = lockers[_beneficiary][_lockingId];
        require(locker.lockingTime != 0, "_lockingId does not exist");
        uint256 batchIndexToRedeemFrom = (locker.lockingTime - startTime) / batchTime;
         
        uint256 currentBatch = (now - startTime) / batchTime;
        uint256 lastBatchIndexToRedeem =  currentBatch.min(batchIndexToRedeemFrom.add(locker.period));
        for (batchIndexToRedeemFrom; batchIndexToRedeemFrom < lastBatchIndexToRedeem; batchIndexToRedeemFrom++) {
            Batch storage locking = batches[batchIndexToRedeemFrom];
            uint256 score = locking.scores[_lockingId];
            if (score > 0) {
                locking.scores[_lockingId] = 0;
                uint256 batchReputationReward = getRepRewardPerBatch(batchIndexToRedeemFrom);
                uint256 repRelation = mul(toReal(uint216(score)), batchReputationReward);
                uint256 redeemForBatch = div(repRelation, toReal(uint216(locking.totalScore)));
                reputation = reputation.add(redeemForBatch);
                emit Redeem(_lockingId, _beneficiary, uint256(fromReal(redeemForBatch)), batchIndexToRedeemFrom);
            }
        }
        reputation = uint256(fromReal(reputation));
        require(reputation > 0, "reputation to redeem is 0");
         
        reputationRewardLeft = reputationRewardLeft.sub(reputation);
        require(
        ControllerInterface(avatar.owner())
        .mintReputation(reputation, _beneficiary, address(avatar)), "mint reputation should succeed");
    }

     
    function lock(uint256 _amount, uint256 _period, uint256 _batchIndexToLockIn, bytes32 _agreementHash)
    public
    onlyAgree(_agreementHash)
    returns(uint256 lockingId)
    {
        require(_amount > 0, "_amount should be > 0");
         
        require(now >= startTime, "locking is not enabled yet (it starts at startTime)");
        require(_period <= maxLockingBatches, "_period exceed the maximum allowed");
        require(_period > 0, "_period must be > 0");
        require((_batchIndexToLockIn.add(_period)) <= batchesIndexCap,
        "_batchIndexToLockIn + _period exceed max allowed batches");
        lockCounter = lockCounter.add(1);
        lockingId = lockCounter;

        Lock storage locker = lockers[msg.sender][lockingId];
        locker.amount = _amount;
        locker.period = _period;
         
        locker.lockingTime = now;

        address(token).safeTransferFrom(msg.sender, address(this), _amount);
         
        uint256 batchIndexToLockIn = (now - startTime) / batchTime;
        require(batchIndexToLockIn == _batchIndexToLockIn,
        "_batchIndexToLockIn must be the one corresponding to the current one");
         
        for (uint256 p = 0; p < _period; p++) {
            Batch storage batch = batches[batchIndexToLockIn + p];
            uint256 score = (_period - p).mul(_amount);
            batch.totalScore = batch.totalScore.add(score);
            batch.scores[lockingId] = score;
        }

        totalLockedLeft = totalLockedLeft.add(_amount);
        emit LockToken(msg.sender, lockingId, _amount, _period);
    }

     
    function extendLocking(
        uint256 _extendPeriod,
        uint256 _batchIndexToLockIn,
        uint256 _lockingId,
        bytes32 _agreementHash)
    public
    onlyAgree(_agreementHash)
    {
        Lock storage locker = lockers[msg.sender][_lockingId];
        require(locker.lockingTime != 0, "_lockingId does not exist");
         
        uint256 remainBatches =
        ((locker.lockingTime.add(locker.period*batchTime).sub(startTime))/batchTime).sub(_batchIndexToLockIn);
        uint256 batchesCountFromCurrent = remainBatches.add(_extendPeriod);
        require(batchesCountFromCurrent <= maxLockingBatches, "locking period exceeds the maximum allowed");
        require(_extendPeriod > 0, "_extendPeriod must be > 0");
        require((_batchIndexToLockIn.add(batchesCountFromCurrent)) <= batchesIndexCap,
        "_extendPeriod exceed max allowed batches");
         
        uint256 batchIndexToLockIn = (now - startTime) / batchTime;
        require(batchIndexToLockIn == _batchIndexToLockIn, "locking is not active");
         
        for (uint256 p = 0; p < batchesCountFromCurrent; p++) {
            Batch storage batch = batches[batchIndexToLockIn + p];
            uint256 score = (batchesCountFromCurrent - p).mul(locker.amount);
            batch.totalScore = batch.totalScore.add(score).sub(batch.scores[_lockingId]);
            batch.scores[_lockingId] = score;
        }
        locker.period = locker.period.add(_extendPeriod);
        emit ExtendLocking(msg.sender, _lockingId, _extendPeriod);
    }

     
    function release(address _beneficiary, uint256 _lockingId) public returns(uint256 amount) {
        Lock storage locker = lockers[_beneficiary][_lockingId];
        require(locker.amount > 0, "no amount left to unlock");
        amount = locker.amount;
        locker.amount = 0;
         
        require(block.timestamp > locker.lockingTime.add(locker.period*batchTime),
        "locking period is still active");
        totalLockedLeft = totalLockedLeft.sub(amount);
        address(token).safeTransfer(_beneficiary, amount);
        emit Release(_lockingId, _beneficiary, amount);
    }

     
    function getRepRewardPerBatch(uint256  _batchIndex) public view returns(uint256 repReward) {
        if (_batchIndex <= batchesIndexCap) {
            repReward = mul(repRewardConstA, repRewardConstB.pow(_batchIndex));
        }
    }

     
    function getLockingIdScore(uint256  _batchIndex, uint256 _lockingId) public view returns(uint256) {
        return batches[_batchIndex].scores[_lockingId];
    }

     
    function mul(uint256 realA, uint256 realB) private pure returns (uint256) {
         
         
        uint256 res = realA * realB;
        require(res/realA == realB, "RealMath mul overflow");
        return (res >> REAL_FBITS);
    }

     
    function toReal(uint216 ipart) private pure returns (uint256) {
        return uint256(ipart) * REAL_ONE;
    }

     
    function fromReal(uint256 _realValue) private pure returns (uint216) {
        return uint216(_realValue / REAL_ONE);
    }

     
    function div(uint256 realNumerator, uint256 realDenominator) private pure returns (uint256) {
         
         
        return uint256((uint256(realNumerator) * REAL_ONE) / uint256(realDenominator));
    }

}