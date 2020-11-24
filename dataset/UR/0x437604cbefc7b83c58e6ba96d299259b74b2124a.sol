 

pragma solidity 0.4.21;

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

     
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;
    address public ICO;  
    address public DAO;  

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setDAO(address _DAO) onlyMasters public {
        DAO = _DAO;
    }

    function setICO(address _ICO) onlyMasters public {
        ICO = _ICO;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO);
        _;
    }

    modifier onlyMasters() {
        require(msg.sender == ICO || msg.sender == owner || msg.sender == DAO);
        _;
    }
}


contract hasHolders {
    mapping(address => uint) private holdersId;
     
    mapping(uint => address) public holders;
    uint public holdersCount = 0;

    event AddHolder(address indexed holder, uint index);
    event DelHolder(address indexed holder);
    event UpdHolder(address indexed holder, uint index);

     
    function _addHolder(address _holder) internal returns (bool) {
        if (holdersId[_holder] == 0) {
            holdersId[_holder] = ++holdersCount;
            holders[holdersCount] = _holder;
            emit AddHolder(_holder, holdersCount);
            return true;
        }
        return false;
    }

     
    function _delHolder(address _holder) internal returns (bool){
        uint id = holdersId[_holder];
        if (id != 0 && holdersCount > 0) {
             
            holders[id] = holders[holdersCount];
             
            delete holdersId[_holder];
             
            delete holders[holdersCount--];
            emit DelHolder(_holder);
            emit UpdHolder(holders[id], id);
            return true;
        }
        return false;
    }
}

contract Force is Ownable, hasHolders {
    using SafeMath for uint;
    string public name = "Force";
    string public symbol = "4TH";
    uint8 public decimals = 0;
    uint public totalSupply = 100000000;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;

    string public information;  

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Mint(address indexed _to, uint _amount);

    function Force() public {
        balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
        _addHolder(this);
    }

     
    function setInformation(string _information) external onlyMasters {
        information = _information;
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns (bool){
        require(_to != address(0));
        require(_value > 0);
        require(balances[_from] >= _value);

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        _addHolder(_to);
        if (balances[_from] == 0) {
            _delHolder(_from);
        }
        return true;
    }

     
    function serviceTransfer(address _from, address _to, uint _value) external onlyMasters returns (bool success) {
        return _transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }
     
    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require(_value <= allowed[_from][_to]);
        allowed[_from][_to] = allowed[_from][_to].sub(_value);
        return _transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) external returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function mint(address _to, uint _amount) external onlyDAO returns (bool) {
        require(_amount > 0);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function() external {}

}