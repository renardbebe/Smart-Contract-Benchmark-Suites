 

pragma solidity ^0.5.8;

library SafeMath {
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function _balanceOf(address owner) view internal returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes memory _data) public returns (bool);
}

contract ForeignToken {
    function balanceOf(address _owner) public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract WiseNetwork is ERC20, ERC20Detailed {
    uint256 public burned; 
	address payable public owner;

    string private constant NAME = "Wise Network";
    string private constant SYMBOL = "WISE";
    uint8 private constant DECIMALS = 18;
    uint256 private constant INITIAL_SUPPLY = 1 * 10**8 * 10**18;  
    
    event Donate(address indexed account, uint256 amount);
    event ApproveAndCall(address _sender,uint256 _value,bytes _extraData);
    event Transfer2Contract(address indexed from, address indexed to, uint256 value, bytes indexed data);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor () public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
        
        owner = msg.sender;
    }

    function burn(uint256 _value) public returns(bool) {
        burned = burned.add(_value);
        _burn(msg.sender, _value);
        return true;
    }
    
    function transferOwnership(address payable _account) onlyOwner public returns(bool){
        require(_account != address(0));

        owner = _account;
        return true;
    }
    
    function getTokenBalance(address tokenAddress, address who) public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw(uint256 _amount) onlyOwner public {
        require(_amount <= address(this).balance);
        
        uint256 etherBalance = _amount;
        owner.transfer(etherBalance);
    }
    
    function withdrawForeignTokens(address _tokenContract, uint256 _amount) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        
        require(_amount <= amount);
        
        (bool success,) = _tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", owner, _amount));
        require(success == true);
        
        return true;
    }
    
	function() external payable{
        emit Donate(msg.sender, msg.value);
    }
    
    function isContract(address _addr) internal view returns (bool) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        
        bytes memory empty;
        
        if(isContract(_to)) {
            return transferToContract(_to, _amount, empty);
        }else {
            _transfer(msg.sender, _to, _amount);
            return true;
        }
    }
    
     
    function transfer(address _to, uint256 _amount, bytes memory _data, string memory _custom_fallback) onlyPayloadSize(2 * 32) public returns (bool success) {
        
        require(msg.sender != _to);
        
        if(isContract(_to)) {

            _transfer(msg.sender, _to, _amount);

            ContractReceiver receiver = ContractReceiver(_to);

            (bool success1,) = address(receiver).call(abi.encodeWithSignature(_custom_fallback, msg.sender, _amount, _data));
            require(success1 == true);
            
            emit Transfer2Contract(msg.sender, _to, _amount, _data);
            return true;
        }
        else {
            _transfer(msg.sender, _to, _amount);
            return true;
        }
    }

     
    function transfer(address _to, uint256 _amount, bytes memory _data) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(msg.sender != _to);

        if(isContract(_to)) {
            return transferToContract(_to, _amount, _data);
        }
        else {
            _transfer(msg.sender, _to, _amount);
            return true;
        }
    }
    
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) payable public returns (bool) {
        
        approve(_spender, _value);
        
        (bool success1,) = msg.sender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", msg.sender, _value, this, _extraData));
        require(success1 == true);
        
        emit ApproveAndCall(_spender, _value, _extraData);
        
        return true;
    }
    
    function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool) {
        
        _transfer(msg.sender, _to, _value);
        
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        
        emit Transfer2Contract(msg.sender, _to, _value, _data);
        return true;
    }
    
}