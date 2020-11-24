 

pragma solidity ^0.4.24;


library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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



contract TimberCoin is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) private allowed;

    uint256 private totalSupply_ = 1750000 * 10**2;

    string public constant name = "TimberCoin";
    string public constant symbol = "TMB";
    uint8 public constant decimals = 2;


    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }



     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);

         
         
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }
}



contract CrowdsaleTMB is Ownable {
    using SafeMath for uint256;

    address public multisig;

    TimberCoin public token;

    uint rate = 100 * 10**2;

    bool public isPaused;

    constructor(address _TimberCoin) public {
        token = TimberCoin(_TimberCoin);
        multisig = 0xdB5964B7Fe29FFE675ce2e6C30cFbe8F8279E711;
    }

    function changeMultisig(address _newMultisig) external onlyOwner {
        require(_newMultisig != 0);
        multisig = _newMultisig;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() external onlyOwner {
        isPaused = false;
    }

    function getCurrentRate() internal view returns(uint) {
        if (block.timestamp < 1537747200) {
            revert();
        }   else if (block.timestamp < 1538352000) {
            return rate.add(rate.mul(7).div(10));
        }   else if (block.timestamp < 1538956800) {
            return rate.add(rate.mul(3).div(5));
        }   else if (block.timestamp < 1539561600) {
            return rate.add(rate.div(2));
        }   else if (block.timestamp < 1540166400) {
            return rate.add(rate.mul(2).div(5));
        }   else if (block.timestamp < 1540771200) {
            return rate.add(rate.mul(3).div(10));
        }   else if (block.timestamp < 1541030400) {
            return rate.add(rate.div(4));
        }   else if (block.timestamp < 1541635200) {
            return rate.add(rate.div(5));
        }   else if (block.timestamp < 1542240000) {
            return rate.add(rate.mul(3).div(20));
        }   else if (block.timestamp < 1542844800) {
            return rate.add(rate.div(10));
        }   else if (block.timestamp < 1543622400) {
            return rate.add(rate.div(20));
        }   else {
            return rate;
        }
    }

    function() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(msg.value >= 10000000000000000);

        uint256 amount = msg.value.mul(getCurrentRate()).div(1 ether);
        uint256 balance = token.balanceOf(this);

        if (amount > balance) {
            uint256 cash = balance.mul(1 ether).div(getCurrentRate());
            uint256 cashBack = msg.value.sub(cash);
            multisig.transfer(cash);
            msg.sender.transfer(cashBack);
            token.transfer(msg.sender, balance);
            return;
        }
        multisig.transfer(msg.value);
        token.transfer(msg.sender, amount);
    }

    function sendTokens(address _recipient, uint _amount) external onlyOwner {
        token.transfer(_recipient, _amount);
    }

    function finalizeICO(address _owner) external onlyOwner {
        require(_owner != address(0));
        uint balance = token.balanceOf(this);
        token.transfer(_owner, balance);
        isPaused = true;
    }

    function getMyBalanceTMB() external view returns(uint256) {
        return token.balanceOf(msg.sender);
    }
}