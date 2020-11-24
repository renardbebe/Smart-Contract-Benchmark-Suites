 

pragma solidity 0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid owner");
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);  
        owner = newOwner;
    }
}


 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract EyeToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct Frozen {
        bool frozen;
        uint until;
    }

    string public name = "EYE Token";
    string public symbol = "EYE";
    uint8 public decimals = 18;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => Frozen) public frozenAccounts;
    uint256 internal totalSupplyTokens;
    bool internal isICO;
    address public wallet;

    function EyeToken() public Ownable() {
        wallet = msg.sender;
        isICO = true;
        totalSupplyTokens = 10000000000 * 10 ** uint256(decimals);
        balances[wallet] = totalSupplyTokens;
    }

     
    function finalizeICO() public onlyOwner {
        isICO = false;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupplyTokens;
    }

     
    function freeze(address _account) public onlyOwner {
        freeze(_account, 0);
    }

     
    function freeze(address _account, uint _until) public onlyOwner {
        if (_until == 0 || (_until != 0 && _until > now)) {
            frozenAccounts[_account] = Frozen(true, _until);
        }
    }

     
    function unfreeze(address _account) public onlyOwner {
        if (frozenAccounts[_account].frozen) {
            delete frozenAccounts[_account];
        }
    }

     
    modifier allowTransfer(address _from) {
        require(!isICO, "ICO phase");
        if (frozenAccounts[_from].frozen) {
            require(frozenAccounts[_from].until != 0 && frozenAccounts[_from].until < now, "Frozen account");
            delete frozenAccounts[_from];
        }
        _;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result = _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value); 
        return result;
    }

     
    function transferICO(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(isICO, "Not ICO phase");
        require(_to != address(0), "Zero address 'To'");
        require(_value <= balances[wallet], "Not enought balance");
        balances[wallet] = balances[wallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(wallet, _to, _value);  
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public allowTransfer(_from) returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Not enought allowance");
        bool result = _transfer(_from, _to, _value);
        if (result) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);  
        }
        return result;
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

     
    function _transfer(address _from, address _to, uint256 _value) internal allowTransfer(_from) returns (bool) {
        require(_to != address(0), "Zero address 'To'");
        require(_from != address(0), "Zero address 'From'");
        require(_value <= balances[_from], "Not enought balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }
}