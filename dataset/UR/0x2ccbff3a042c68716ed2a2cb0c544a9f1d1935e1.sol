 

pragma solidity 0.4.18;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ApprovalContract is ERC20 {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowed;

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract MintableToken is ApprovalContract, Ownable {

    uint256 public hardCap;
    mapping(address => uint256) public balances;

    event Mint(address indexed to, uint256 amount);

    modifier canMint() {
        require(totalSupply == 0);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_amount < hardCap);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
}

 
contract Vesting is MintableToken {

    event VestingMemberAdded(address indexed _address, uint256 _amount, uint _start, uint _end);

    struct _Vesting {
        uint256 totalSum;      
        uint256 start;         
        uint256 end;           
        uint256 usedAmount;    
    }

    mapping (address => _Vesting ) public vestingMembers;

    function addVestingMember(
        address _address,
        uint256 _amount,
        uint256 _start,
        uint256 _end
    ) onlyOwner public returns (bool) {
        require(
            _address != address(0) &&
            _amount > 0 &&
            _start < _end &&
            vestingMembers[_address].totalSum == 0 &&
            balances[msg.sender] > _amount
        );

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        vestingMembers[_address].totalSum = _amount;     
        vestingMembers[_address].start = _start;         
        vestingMembers[_address].end = _end;             
        vestingMembers[_address].usedAmount = 0;         

        VestingMemberAdded(_address, _amount, _start, _end);

        return true;
    }

    function currentPart(address _address) private constant returns (uint256) {
        if (vestingMembers[_address].totalSum == 0 || block.number <= vestingMembers[_address].start) {
            return 0;
        }
        if (block.number >= vestingMembers[_address].end) {
            return vestingMembers[_address].totalSum.sub(vestingMembers[_address].usedAmount);
        }

        return vestingMembers[_address].totalSum
        .mul(block.number - vestingMembers[_address].start)
        .div(vestingMembers[_address].end - vestingMembers[_address].start)
        .sub(vestingMembers[_address].usedAmount);
    }

    function subFromBalance(address _address, uint256 _amount) private returns (uint256) {
        require(_address != address(0));

        if (vestingMembers[_address].totalSum == 0) {
            balances[_address] = balances[_address].sub(_amount);
            return balances[_address];
        }
        uint256 summary = balanceOf(_address);
        require(summary >= _amount);

        if (balances[_address] > _amount) {
            balances[_address] = balances[_address].sub(_amount);
        } else {
            uint256 part = currentPart(_address);
            if (block.number >= vestingMembers[_address].end) {
                vestingMembers[_address].totalSum = 0;           
                vestingMembers[_address].start = 0;              
                vestingMembers[_address].end = 0;                
                vestingMembers[_address].usedAmount = 0;         
            } else {
                vestingMembers[_address].usedAmount = vestingMembers[_address].usedAmount.add(part);
            }
            balances[_address] = balances[_address].add(part).sub(_amount);
        }

        return balances[_address];
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        if (vestingMembers[_owner].totalSum == 0) {
            return balances[_owner];
        } else {
            return balances[_owner].add(currentPart(_owner));
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));

        subFromBalance(msg.sender, _value);

        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        subFromBalance(_from, _value);

        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}


contract DMToken is Vesting {

    string public name = "DMarket Token";
    string public symbol = "DMT";
    uint256 public decimals = 8;

    function DMToken() public {
        hardCap = 15644283100000000;
    }

    function multiTransfer(address[] recipients, uint256[] amounts) public {
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }

    function multiVesting(
        address[] _address,
        uint256[] _amount,
        uint256[] _start,
        uint256[] _end
    ) public onlyOwner {
        require(
            _address.length == _amount.length &&
            _address.length == _start.length &&
            _address.length == _end.length
        );
        for (uint i = 0; i < _address.length; i++) {
            addVestingMember(_address[i], _amount[i], _start[i], _end[i]);
        }
    }
}