 

pragma solidity 0.4.25;

 

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) external;
}

 
contract SNKToken is Ownable {

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

     
     
     
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);


    modifier whenTransfersEnabled() {
        require(transfersEnabled);
        _;
    }

     
     
     


    constructor () public {
        name = "SNK";
        symbol = "SNK";
        decimals = 18;
        creationBlock = block.number;
        transfersEnabled = true;

         
        uint _amount = 7000000 * (10 ** uint256(decimals));
        updateValueAtNow(totalSupplyHistory, _amount);
        updateValueAtNow(balances[msg.sender], _amount);
        emit Transfer(0, msg.sender, _amount);
    }


     
    function () public payable {}

     
     
     

     
     
     
     
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

         
        require((_to != 0) && (_to != address(this)));

         
         
        uint previousBalanceFrom = balanceOfAt(_from, block.number);

        require(previousBalanceFrom >= _amount);

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        uint previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        emit Transfer(_from, _to, _amount);

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

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() external view returns (uint) {
        return totalSupplyAt(block.number);
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



     
     
     

     
     
     
     
    function claimTokens(address _token) external onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        SNKToken token = SNKToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
}