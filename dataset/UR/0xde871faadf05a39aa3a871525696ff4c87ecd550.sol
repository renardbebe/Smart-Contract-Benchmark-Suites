 

pragma solidity ^0.4.18;

 
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract UniversalCoin is BurnableToken, Ownable {

    string constant public name = "UniversalCoin";
    string constant public symbol = "UNV";
    uint256 constant public decimals = 6;
    uint256 constant public airdropReserve = 2400000000E6;  
    uint256 constant public pool = 32000000000E6;

    function UniversalCoin(address uniFoundation) public {
        totalSupply = 40000000000E6;  
        balances[uniFoundation] = 5600000000E6;  
        balances[owner] = pool + airdropReserve;  
    }

}

contract UniversalManager is Ownable {
    using SafeMath for uint256;

    uint256 public constant ADDRESS_LIMIT = 300;
    uint256 public constant TRANSFERS_PER_TRANSACTION = 150;

    uint256 public airdrop;
    UniversalCoin public token;

    uint256 private currentPool = 0;
    uint256 private index = 0;
    uint256 private airdropIndex = 0;
    address[] private participants;
    address[] private airdropParticipants;

    function UniversalManager(address uniFoundation) public {
        token = new UniversalCoin(uniFoundation);
        airdrop = token.airdropReserve().div(3);
    }

     
    function setCurrentWeekPool(uint256 _currentPool) public onlyOwner {
        require(_currentPool > 0);
        currentPool = _currentPool;
    }

     
    function addParticipants(address[] _participants) external onlyOwner {
        require(_participants.length != 0 && _participants.length <= ADDRESS_LIMIT);
        participants = _participants;
    }

     
    function addAirdropParticipants(address[] _airdropParticipants) public onlyOwner {
        require(_airdropParticipants.length != 0 && _airdropParticipants.length <= ADDRESS_LIMIT);
        airdropParticipants = _airdropParticipants;
    }

     
    function transfer(uint256 _amount) public onlyOwner {
        uint256 max;
        uint256 length = participants.length;
        if ((index + TRANSFERS_PER_TRANSACTION) >= length) {
            max = length;
        } else {
            max = index + TRANSFERS_PER_TRANSACTION;
        }
        for (uint i = index; i < max; i++) {
            token.transfer(participants[i], _amount);
        }
        if (max >= length) {
            index = 0;
        } else {
            index += TRANSFERS_PER_TRANSACTION;
        }
    }

     
    function transferAidrop() public onlyOwner {
        uint256 max;
        uint256 length = airdropParticipants.length;
        if ((airdropIndex + TRANSFERS_PER_TRANSACTION) >= length) {
            max = length;
        } else {
            max = airdropIndex + TRANSFERS_PER_TRANSACTION;
        }
        uint256 share;
        for (uint i = airdropIndex; i < max; i++) {
            share = (airdrop.mul(token.balanceOf(airdropParticipants[i]))).div(token.totalSupply());
            if (share == 0) {
                continue;
            }
            token.transfer(airdropParticipants[i], share);
        }
        if (max >= length) {
            airdropIndex = 0;
        } else {
            airdropIndex += TRANSFERS_PER_TRANSACTION;
        }
    }
}