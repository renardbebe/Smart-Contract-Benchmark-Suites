 

pragma solidity 0.5.9;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes calldata  _data) external;
}

 
contract WINSToken is Ownable {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               

     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
    uint public creationBlock;

     
    bool public transfersEnabled;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;
    Checkpoint[] totalSupplyHolders;
    mapping (address => bool) public holders;
    uint public minHolderAmount = 20000 ether;

     
     
     
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);


    modifier whenTransfersEnabled() {
        require(transfersEnabled);
        _;
    }

     
     
     


    constructor () public {
        name = "WINS LIVE";
        symbol = "WNL";
        decimals = 18;
        creationBlock = block.number;
        transfersEnabled = true;

         
        uint _amount = 77777777 * (10 ** uint256(decimals));
        updateValueAtNow(totalSupplyHistory, _amount);
        updateValueAtNow(balances[msg.sender], _amount);

        holders[msg.sender] = true;
        updateValueAtNow(totalSupplyHolders, _amount);
        emit Transfer(address(0), msg.sender, _amount);
    }


     
    function () external payable {}

     
     
     

     
     
     
     
    function transfer(address _to, uint256 _amount) whenTransfersEnabled external returns (bool) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) whenTransfersEnabled external returns (bool) {
         
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {

        if (_amount == 0) {
            emit Transfer(_from, _to, _amount);     
            return;
        }

         
        require((_to != address(0)) && (_to != address(this)));

         
         
        uint previousBalanceFrom = balanceOfAt(_from, block.number);

        require(previousBalanceFrom >= _amount);

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        uint previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        emit Transfer(_from, _to, _amount);


        uint curTotalSupplyHolders = totalSupplyHoldersAt(block.number);

        if (holders[_from]) {
            if (previousBalanceFrom - _amount < minHolderAmount) {
                delete holders[_from];
                require(curTotalSupplyHolders >= previousBalanceFrom);
                curTotalSupplyHolders = curTotalSupplyHolders - previousBalanceFrom;
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders);
            } else {
                require(curTotalSupplyHolders >= _amount);
                curTotalSupplyHolders = curTotalSupplyHolders - _amount;
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders);
            }
        }

        if (previousBalanceTo + _amount >= minHolderAmount) {
            if (holders[_to]) {
                require(curTotalSupplyHolders + _amount >= curTotalSupplyHolders);  
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders + _amount);
            }

            if (!holders[_to]) {
                holders[_to] = true;
                require(curTotalSupplyHolders + previousBalanceTo + _amount >= curTotalSupplyHolders);  
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders + previousBalanceTo + _amount);
            }
        }


    }

     
     
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) whenTransfersEnabled public returns (bool) {
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedAmount) external returns (bool) {
        require(allowed[msg.sender][_spender] + _addedAmount >= allowed[msg.sender][_spender]);  
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedAmount;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedAmount) external returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedAmount >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedAmount;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
     
     
     
     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() external view returns (uint) {
        return totalSupplyAt(block.number);
    }

    function currentTotalSupplyHolders() external view returns (uint) {
        return totalSupplyHoldersAt(block.number);
    }

     
     
     

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
             
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
             
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }


    function totalSupplyHoldersAt(uint _blockNumber) public view returns(uint) {
        if ((totalSupplyHolders.length == 0) || (totalSupplyHolders[0].fromBlock > _blockNumber)) {
            return 0;
             
        } else {
            return getValueAt(totalSupplyHolders, _blockNumber);
        }
    }

    function isHolder(address _holder) external view returns(bool) {
        return holders[_holder];
    }


    function destroyTokens(uint _amount) onlyOwner public returns (bool) {
        uint curTotalSupply = totalSupplyAt(block.number);
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOfAt(msg.sender, block.number);

        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[msg.sender], previousBalanceFrom - _amount);
        emit Transfer(msg.sender, address(0), _amount);

        uint curTotalSupplyHolders = totalSupplyHoldersAt(block.number);
        if (holders[msg.sender]) {
            if (previousBalanceFrom - _amount < minHolderAmount) {
                delete holders[msg.sender];
                require(curTotalSupplyHolders >= previousBalanceFrom);
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders - previousBalanceFrom);
            } else {
                require(curTotalSupplyHolders >= _amount);
                updateValueAtNow(totalSupplyHolders, curTotalSupplyHolders - _amount);
            }
        }
        return true;
    }


     
     
     


     
     
    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        transfersEnabled = _transfersEnabled;
    }

     
     
     

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0)
            || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
            newCheckPoint.fromBlock =  uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }


     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }



     
     
     

     
     
     
     
    function claimTokens(address payable _token) external onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        WINSToken token = WINSToken(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }


    function setMinHolderAmount(uint _minHolderAmount) external onlyOwner {
        minHolderAmount = _minHolderAmount;
    }
}


contract DividendManager is Ownable {
    using SafeMath for uint;

    event DividendDeposited(address indexed _depositor, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);
    event DividendClaimed(address indexed _claimer, uint256 _dividendIndex, uint256 _claim);
    event DividendRecycled(address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);

    WINSToken public token;

    uint256 public RECYCLE_TIME = 365 days;
    uint public minHolderAmount = 20000 ether;

    struct Dividend {
        uint256 blockNumber;
        uint256 timestamp;
        uint256 amount;
        uint256 claimedAmount;
        uint256 totalSupply;
        bool recycled;
        mapping (address => bool) claimed;
    }

    Dividend[] public dividends;

    mapping (address => uint256) dividendsClaimed;

    struct NotClaimed {
        uint listIndex;
        bool exists;
    }

    mapping (address => NotClaimed) public notClaimed;
    address[] public notClaimedList;

    modifier validDividendIndex(uint256 _dividendIndex) {
        require(_dividendIndex < dividends.length);
        _;
    }

    constructor(address payable _token) public {
        token = WINSToken(_token);
    }

    function depositDividend() payable public {
        uint256 currentSupply = token.totalSupplyHoldersAt(block.number);

        uint i;
        for( i = 0; i < notClaimedList.length; i++) {
            if (token.isHolder(notClaimedList[i])) {
                currentSupply = currentSupply.sub(token.balanceOf(notClaimedList[i]));
            }
        }

        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = SafeMath.sub(block.number, 1);
        dividends.push(
            Dividend(
                blockNumber,
                getNow(),
                msg.value,
                0,
                currentSupply,
                false
            )
        );
        emit DividendDeposited(msg.sender, blockNumber, msg.value, currentSupply, dividendIndex);
    }


    function claimDividend(uint256 _dividendIndex) public validDividendIndex(_dividendIndex)
    {
        require(!notClaimed[msg.sender].exists);

        Dividend storage dividend = dividends[_dividendIndex];

        require(dividend.claimed[msg.sender] == false);
        require(dividend.recycled == false);

        uint256 balance = token.balanceOfAt(msg.sender, dividend.blockNumber);
        require(balance >= minHolderAmount);

        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);
        dividend.claimed[msg.sender] = true;
        dividend.claimedAmount = SafeMath.add(dividend.claimedAmount, claim);

        if (claim > 0) {
            msg.sender.transfer(claim);
            emit DividendClaimed(msg.sender, _dividendIndex, claim);
        }
    }

    function claimDividendAll() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                dividendsClaimed[msg.sender] = SafeMath.add(i, 1);
                claimDividend(i);
            }
        }
    }

    function recycleDividend(uint256 _dividendIndex) public
    onlyOwner
    validDividendIndex(_dividendIndex)
    {
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.recycled == false);
        require(dividend.timestamp < SafeMath.sub(getNow(), RECYCLE_TIME));
        dividends[_dividendIndex].recycled = true;
        uint256 currentSupply = token.totalSupplyAt(block.number);
        uint256 remainingAmount = SafeMath.sub(dividend.amount, dividend.claimedAmount);
        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = SafeMath.sub(block.number, 1);
        dividends.push(
            Dividend(
                blockNumber,
                getNow(),
                remainingAmount,
                0,
                currentSupply,
                false
            )
        );
        emit DividendRecycled(msg.sender, blockNumber, remainingAmount, currentSupply, dividendIndex);
    }

     
    function getNow() internal view returns (uint256) {
        return now;
    }

    function dividendsCount() external view returns (uint) {
        return dividends.length;
    }


    function registerNotClaimed(address _notClaimed) onlyOwner public {
        require(_notClaimed != address(0));
        if (!notClaimed[_notClaimed].exists) {
            notClaimed[_notClaimed] = NotClaimed({
                listIndex: notClaimedList.length,
                exists: true
                });
            notClaimedList.push(_notClaimed);
        }
    }


    function unregisterNotClaimed(address _notClaimed) onlyOwner public {
        require(notClaimed[_notClaimed].exists && notClaimedList.length > 0);
        uint lastIdx = notClaimedList.length - 1;
        notClaimed[notClaimedList[lastIdx]].listIndex = notClaimed[_notClaimed].listIndex;
        notClaimedList[notClaimed[_notClaimed].listIndex] = notClaimedList[lastIdx];
        notClaimedList.length--;
        delete notClaimed[_notClaimed];
    }

     
     
     
     
    function claimTokens(address payable _token) external onlyOwner {
         
         
         
         

        WINSToken claimToken = WINSToken(_token);
        uint balance = claimToken.balanceOf(address(this));
        claimToken.transfer(owner, balance);
    }
}