 

pragma solidity ^0.4.17;


 
library SafeMathForBoost {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}


contract Boost {
    using SafeMathForBoost for uint256;

    string public name = "Boost";          
    uint8 public decimals = 0;             
    string public symbol = "BST";          
    uint256 public totalSupply = 100000000;   

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
    struct  Checkpoint {

         
        uint256 fromBlock;

         
        uint256 value;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

     
    function Boost() public {
        balances[msg.sender].push(Checkpoint({
            fromBlock:block.number,
            value:totalSupply
        }));
    }

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {

         
        require((_to != 0) && (_to != address(this)) && (_amount != 0));

         
         
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        updateValueAtNow(balances[_from], previousBalanceFrom.sub(_amount));

         
         
        var previousBalanceTo = balanceOfAt(_to, block.number);
        updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));

         
        Transfer(_from, _to, _amount);

    }

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view  returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = block.number;
            newCheckPoint.value = _value;
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = _value;
        }
    }

     
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}


 
contract BoostContainer {
    using SafeMathForBoost for uint256;

     
    address public multiSigAddress;
    bool public paused = false;

     
    Boost public boost;

     
    InfoForDeposit[] public arrayInfoForDeposit;

     
    mapping(address => uint256) public mapCompletionNumberForWithdraw;

     
    event LogDepositForDividend(uint256 blockNumber, uint256 etherAountForDividend);
    event LogWithdrawal(address indexed tokenHolder, uint256 etherValue);
    event LogPause();
    event LogUnpause();

     
    struct InfoForDeposit {
        uint256 blockNumber;
        uint256 depositedEther;
    }

     
    modifier isNotCompletedForWithdrawal(address _address) {
        require(mapCompletionNumberForWithdraw[_address] != arrayInfoForDeposit.length);
        _;
    }

     
    modifier onlyMultiSig() {
        require(msg.sender == multiSigAddress);
        _;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
     
     
    function BoostContainer(address _boostAddress, address _multiSigAddress) public {
        boost = Boost(_boostAddress);
        multiSigAddress = _multiSigAddress;
    }

     
     
    function depositForDividend(uint256 _blockNumber) public payable onlyMultiSig whenNotPaused {
        require(msg.value > 0);

        arrayInfoForDeposit.push(InfoForDeposit({blockNumber:_blockNumber, depositedEther:msg.value}));

        LogDepositForDividend(_blockNumber, msg.value);
    }

     
    function withdraw() public isNotCompletedForWithdrawal(msg.sender) whenNotPaused {

         
        uint256 withdrawAmount = getWithdrawValue(msg.sender);

        require(withdrawAmount > 0);

         
        mapCompletionNumberForWithdraw[msg.sender] = arrayInfoForDeposit.length;

         
        msg.sender.transfer(withdrawAmount);

         
        LogWithdrawal(msg.sender, withdrawAmount);
    }

     
     
    function changeMultiSigAddress(address _address) public onlyMultiSig {
        require(_address != address(0));
        multiSigAddress = _address;
    }

     
     
    function getArrayInfoForDepositCount() public view returns (uint256 result) {
        return arrayInfoForDeposit.length;
    }

     
     
     
    function getWithdrawValue(address _address) public view returns (uint256 withdrawAmount) {
        uint256 validNumber = mapCompletionNumberForWithdraw[_address];
        uint256 blockNumber;
        uint256 depositedEther;
        uint256 tokenAmount;

        for (uint256 i = 0; i < arrayInfoForDeposit.length; i++) {
            if (i < validNumber) {
                continue;
            }

             
            blockNumber = arrayInfoForDeposit[i].blockNumber;
            depositedEther = arrayInfoForDeposit[i].depositedEther;

             
            tokenAmount = boost.balanceOfAt(_address, blockNumber);

             
            withdrawAmount = withdrawAmount.add(tokenAmount.mul(depositedEther).div(boost.totalSupply()));
        }
    }

     
    function destroy() public onlyMultiSig whenPaused {
        selfdestruct(multiSigAddress);
    }

     
    function pause() public onlyMultiSig whenNotPaused {
        paused = true;
        LogPause();
    }

     
    function unpause() public onlyMultiSig whenPaused {
        paused = false;
        LogUnpause();
    }

     
     
     
    function sendProfit(address _address, uint256 _amount) public isNotCompletedForWithdrawal(_address) onlyMultiSig whenPaused {
        require(_address != address(0));
        require(_amount > 0);

        mapCompletionNumberForWithdraw[_address] = arrayInfoForDeposit.length;

         
        _address.transfer(_amount);

         
        LogWithdrawal(_address, _amount);
    }
}