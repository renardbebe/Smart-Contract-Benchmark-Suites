 

pragma solidity 0.4.23;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
 
 
 
 
 

contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "ZGB";
    string public constant symbol = "ZGB";
    uint256 public constant decimals = 9;

     
    uint256 public constant TOKEN_UNIT = 10 ** uint256(decimals);

     
    uint256 public constant MAX_TOKEN_SUPPLY = 10000000000 * TOKEN_UNIT;

     
    uint256 public constant MAX_BATCH_SIZE = 400;

    address public assigner;     
    address public locker;       

    mapping(address => bool) public locked;         

    mapping(address => TxRecord[]) public txRecordPerAddress;

    mapping(address => uint) public chainStartIdxPerAddress;
    mapping(address => uint) public chainEndIdxPerAddress;

    struct TxRecord {
        uint amount;
        uint releaseTime;
        uint nextIdx;
        uint prevIdx;
    }

    event Lock(address indexed addr);
    event Unlock(address indexed addr);
    event Assign(address indexed to, uint256 amount);
    event LockerTransferred(address indexed previousLocker, address indexed newLocker);
    event AssignerTransferred(address indexed previousAssigner, address indexed newAssigner);

     
     
     
    constructor(address _assigner, address _locker) public {
        require(_assigner != address(0));
        require(_locker != address(0));

        assigner = _assigner;
        locker = _locker;

        balances[_assigner] = balances[_assigner].add(MAX_TOKEN_SUPPLY);
        recop(_assigner, MAX_TOKEN_SUPPLY, 0);
        
        totalSupply_ = MAX_TOKEN_SUPPLY;
    }

     
    modifier onlyAssigner() {
        require(msg.sender == assigner);
        _;
    }

     
    modifier onlyLocker() {
        require(msg.sender == locker);
        _;
    }


     
     
     
    function transferLocker(address _newLocker) external onlyOwner returns (bool) {
        require(_newLocker != address(0));

        emit LockerTransferred(locker, _newLocker);
        locker = _newLocker;
        return true;
    }

     
     
     
     
     
    function lockAddress(address _address) public onlyLocker returns (bool) {
        require(!locked[_address]);

        locked[_address] = true;
        emit Lock(_address);
        return true;
    }

     
     
     
     
    function unlockAddress(address _address) public onlyLocker returns (bool) {
        require(locked[_address]);

        locked[_address] = false;
        emit Unlock(_address);
        return true;
    }

     
     
     
    function lockInBatches(address[] _addresses) external onlyLocker returns (bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            lockAddress(_addresses[i]);
        }
        return true;
    }

     
     
     
    function unlockInBatches(address[] _addresses) external onlyLocker returns (bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            unlockAddress(_addresses[i]);
        }
        return true;
    }

     
     
     
    function isLocked(address _address) external view returns (bool) {
        return locked[_address];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return transferL(_to, _value, 0);
    }


    function transferL(address _to, uint256 _value, uint256 lTime) public returns (bool) {
        require(!locked[msg.sender]);
        require(_to != address(0));
        return transferFT(msg.sender, _to, _value, lTime);
    }

    function getamount(address addr, uint256 index) public view returns (uint) {
        return txRecordPerAddress[addr][index].amount;
    }

    function payop(address _from, uint needTakeout) private {
        for (uint idx = chainStartIdxPerAddress[_from]; true; idx = txRecordPerAddress[_from][idx].nextIdx) {
            TxRecord memory txRecord = txRecordPerAddress[_from][idx];
            if (now < txRecord.releaseTime)
                break;
            if (txRecord.amount <= needTakeout) {
                chainStartIdxPerAddress[_from] = txRecordPerAddress[_from][idx].nextIdx;
                delete txRecordPerAddress[_from][idx];
                needTakeout = needTakeout.sub(txRecord.amount);
            } else {
                txRecordPerAddress[_from][idx].amount = txRecordPerAddress[_from][idx].amount.sub(needTakeout);
                needTakeout = 0;
            }
            if (idx == chainEndIdxPerAddress[_from]) {
                break;
            }
        }
 
        require(needTakeout == 0);
    }

    function recop22(address _to){
        txRecordPerAddress[_to].push(TxRecord({amount : 100, releaseTime : now.add(0), nextIdx : 0, prevIdx : 0}));
        uint a = txRecordPerAddress[_to].length - 1;
    }

    function recop(address _to, uint256 _value, uint256 lTime) private {
        if (txRecordPerAddress[_to].length < 1) {
            txRecordPerAddress[_to].push(TxRecord({amount : _value, releaseTime : now.add(lTime), nextIdx : 0, prevIdx : 0}));
            chainStartIdxPerAddress[_to] = 0;
            chainEndIdxPerAddress[_to] = 0;
            return;
        }
        uint startIndex = chainStartIdxPerAddress[_to];
        if (lTime == 0 && txRecordPerAddress[_to][startIndex].releaseTime < now) {
            txRecordPerAddress[_to][startIndex].amount = txRecordPerAddress[_to][startIndex].amount.add(_value);
            return;
        }
        TxRecord memory utxo = TxRecord({amount : _value, releaseTime : now.add(lTime), nextIdx : 0, prevIdx : 0});
        for (uint idx = startIndex; true; idx = txRecordPerAddress[_to][idx].nextIdx) {
            if (utxo.releaseTime < txRecordPerAddress[_to][idx].releaseTime) {
                if (idx == chainEndIdxPerAddress[_to]) {
                    utxo.prevIdx = idx;
                    txRecordPerAddress[_to].push(utxo);
                    txRecordPerAddress[_to][idx].nextIdx = txRecordPerAddress[_to].length - 1;
                    chainEndIdxPerAddress[_to] = txRecordPerAddress[_to].length - 1;
                    return;
                } else if (utxo.releaseTime >= txRecordPerAddress[_to][txRecordPerAddress[_to][idx].nextIdx].releaseTime) {
                    utxo.prevIdx = idx;
                    utxo.nextIdx = txRecordPerAddress[_to][idx].nextIdx;
                    txRecordPerAddress[_to].push(utxo);
                    txRecordPerAddress[_to][idx].nextIdx = txRecordPerAddress[_to].length - 1;
                    txRecordPerAddress[_to][txRecordPerAddress[_to][idx].nextIdx].prevIdx  = txRecordPerAddress[_to].length - 1;
                    return;
                }
            } else {
                if (idx == startIndex) {
                    utxo.nextIdx = idx;
                    txRecordPerAddress[_to].push(utxo);
                    txRecordPerAddress[_to][idx].prevIdx = txRecordPerAddress[_to].length - 1;
                    chainStartIdxPerAddress[_to] = txRecordPerAddress[_to].length - 1;
                    return;
                }
            }
            if (idx == chainEndIdxPerAddress[_to]) {
                return;
            }
        }
    }

    function hp(address _to) private {
        uint len = txRecordPerAddress[_to].length;
        for (uint k = 2; k <= 5 && k <= len; k++) {
            uint index = len - k;
            if (now > txRecordPerAddress[_to][index].releaseTime) {
                txRecordPerAddress[_to][index].amount = txRecordPerAddress[_to][index].amount.add(txRecordPerAddress[_to][index + 1].amount);
                delete txRecordPerAddress[_to][index + 1];
                txRecordPerAddress[_to].length--;
            } else {
                break;
            }
        }
    }

    function transferFT(address _from, address _to, uint256 _value, uint256 lTime) private returns (bool) {
         
        payop(_from, _value);
        balances[_from] = balances[_from].sub(_value);

         
         

         
        recop(_to, _value, lTime);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function txRecordCount(address add) public view returns (uint){
        return txRecordPerAddress[add].length;
    }

    function getnow() public view returns (uint){
        return now;
    }

    function getChain(address add) public view returns (uint[]){
        uint[] a;
        for (uint idx = chainStartIdxPerAddress[add]; true; idx = txRecordPerAddress[add][idx].nextIdx) {
            a.push(txRecordPerAddress[add][idx].amount);
            if (idx == chainEndIdxPerAddress[add]) {
                break;
            }
        }
        return a;
    }


     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!locked[msg.sender]);
        require(!locked[_from]);
        require(_to != address(0));
        super.transferFrom(_from, _to, _value);
        return transferFT(_from, _to, _value, 0);
    }
}