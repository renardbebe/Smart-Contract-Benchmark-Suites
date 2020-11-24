 

pragma solidity 0.4.24;

 
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

 
contract Ownable {

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

     
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
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract Pausable is Ownable {
    
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract TokenRepository is Ownable {

    using SafeMath for uint256;

     
    string public name;

     
    string public symbol;

     
    uint256 public decimals;

     
    uint256 public totalSupply;

     
    mapping(address => uint256) public balances;

     
    mapping (address => mapping (address => uint256)) public allowed;

     
    function setName(string _name) public onlyOwner {
        name = _name;
    }

     
    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

     
    function setDecimals(uint256 _decimals) public onlyOwner {
        decimals = _decimals;
    }

     
    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }

     
    function setBalances(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = _value;
    }

     
    function setAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = _value;
    }

     
    function mintTokens(address _owner, uint256 _value) public onlyOwner {
        require(_value > totalSupply.add(_value), "");
        
        totalSupply = totalSupply.add(_value);
        setBalances(_owner, _value);
    }
    
     
    function burnTokens(uint256 _value) public onlyOwner {
        require(_value <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
    }

     
    function increaseBalance(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = balances[_owner].add(_value);
    }

     
    function increaseAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = allowed[_owner][_spender].add(_value);
    }

     
    function decreaseBalance(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = balances[_owner].sub(_value);
    }

     
    function decreaseAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = allowed[_owner][_spender].sub(_value);
    }

     
    function transferBalance(address _from, address _to, uint256 _value) public onlyOwner {
        decreaseBalance(_from, _value);
        increaseBalance(_to, _value);
    }
}


contract ERC223Receiver {
    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool);
}

 
contract ERC223Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

 
contract ERC223Token is ERC223Interface, Pausable {

    TokenRepository public tokenRepository;

     
    constructor() public {
        tokenRepository = new TokenRepository();
    }

     
    function name() public view returns (string) {
        return tokenRepository.name();
    }

     
    function symbol() public view returns (string) {
        return tokenRepository.symbol();
    }

     
    function decimals() public view returns (uint256) {
        return tokenRepository.decimals();
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenRepository.totalSupply();
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return tokenRepository.balances(_owner);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return tokenRepository.allowed(_owner, _spender);
    }

     
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        return transfer(_to, _value, new bytes(0));
    }

     
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

     
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
         
        if (!_transfer(_to, _value)) revert();  
        if (_isContract(_to)) return _contractFallback(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
        if (!_transferFrom(_from, _to, _value)) revert();  
        if (_isContract(_to)) return _contractFallback(_from, _to, _value, _data);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        tokenRepository.setAllowed(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        tokenRepository.increaseAllowed(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, tokenRepository.allowed(msg.sender, _spender));
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        uint256 oldValue = tokenRepository.allowed(msg.sender, _spender);
        if (_value >= oldValue) {
            tokenRepository.setAllowed(msg.sender, _spender, 0);
        } else {
            tokenRepository.decreaseAllowed(msg.sender, _spender, _value);
        }
        emit Approval(msg.sender, _spender, tokenRepository.allowed(msg.sender, _spender));
        return true;
    }

     
    function _transfer(address _to, uint256 _value) internal returns (bool) {
        require(_value <= tokenRepository.balances(msg.sender));
        require(_to != address(0));

        tokenRepository.transferBalance(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value <= tokenRepository.balances(_from));
        require(_value <= tokenRepository.allowed(_from, msg.sender));
        require(_to != address(0));

        tokenRepository.transferBalance(_from, _to, _value);
        tokenRepository.decreaseAllowed(_from, msg.sender, _value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function _contractFallback(address _from, address _to, uint _value, bytes _data) private returns (bool) {
        ERC223Receiver reciever = ERC223Receiver(_to);
        return reciever.tokenFallback(msg.sender, _from, _value, _data);
    }

     
    function _isContract(address _address) private view returns (bool) {
         
        uint length;
        assembly { length := extcodesize(_address) }
        return length > 0;
    }
}

contract NAi is ERC223Token {

    constructor() public {
        tokenRepository.setName("NAi");
        tokenRepository.setSymbol("NAi");
        tokenRepository.setDecimals(6);
        tokenRepository.setTotalSupply(20000000 * 10 ** uint(tokenRepository.decimals()));

        tokenRepository.setBalances(msg.sender, tokenRepository.totalSupply());
    }

     
    function storageOwner() public view returns(address) {
        return tokenRepository.owner();
    }
    
     
    function burnTokens(uint256 _value) public onlyOwner {
        tokenRepository.burnTokens(_value);
        emit Transfer(msg.sender, address(0), _value);
    }

     
    function transferStorageOwnership(address _newContract) public onlyOwner {
        tokenRepository.transferOwnership(_newContract);
    }

     
    function killContract() public onlyOwner {
        require(storageOwner() != address(this));
        selfdestruct(owner);
    }
}