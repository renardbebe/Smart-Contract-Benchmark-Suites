 

pragma solidity ^0.4.13;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who] - _value;
        totalSupply_ = totalSupply_ - _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
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
        uint allowanceBefore = allowed[msg.sender][_spender];
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
        assert(allowanceBefore <= allowed[msg.sender][_spender]);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

}

contract StandardBurnableToken is BurnableToken, StandardToken {

     
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
         
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _burn(_from, _value);
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
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

contract AnkhTokenDistributor is Ownable {
    AnkhToken public token;

    mapping(uint32 => bool) public processedTransactions;

    constructor(AnkhToken _token) public {
        token = _token == address(0x0) ? new AnkhToken() : _token;
    }

    function isTransactionSuccessful(uint32 id) external view returns (bool) {
        return processedTransactions[id];
    }

    modifier validateInput(uint32[] _payment_ids, address[] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length);
        require(_receivers.length == _payment_ids.length);

        _;
    }

    function transferTokenOwnership() external onlyOwner {
        token.transferOwnership(owner);
    }
}

contract AnkhTokenSender is AnkhTokenDistributor {
    constructor(AnkhToken _token) AnkhTokenDistributor(_token) public { }

    function bulkTransfer(uint32[] _payment_ids, address[] _receivers, uint256[] _amounts)
        external onlyOwner validateInput(_payment_ids, _receivers, _amounts) {

        for (uint i = 0; i < _receivers.length; i++) {
            if (!processedTransactions[_payment_ids[i]]) {
                processedTransactions[_payment_ids[i]] = true;

                token.transfer(_receivers[i], _amounts[i]);
            }
        }
    }

    function bulkTransferFrom(uint32[] _payment_ids, address _from, address[] _receivers, uint256[] _amounts)
        external onlyOwner validateInput(_payment_ids, _receivers, _amounts) {

        for (uint i = 0; i < _receivers.length; i++) {
            if (!processedTransactions[_payment_ids[i]]) {
                processedTransactions[_payment_ids[i]] = true;

                token.transferFrom(_from, _receivers[i], _amounts[i]);
            }
        }
    }

    function transferTokensToOwner() external onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);

        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_ + _amount;
        balances[_to] = balances[_to] + _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();

        return true;
    }
}

contract CappedToken is MintableToken {

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);

        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_ + _amount <= cap);
        require(totalSupply_ + _amount >= totalSupply_);

        return super.mint(_to, _amount);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused || msg.sender == owner);

        _;
    }

     
    modifier whenPaused() {
        require(paused || msg.sender == owner);

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

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract AnkhToken is StandardBurnableToken, CappedToken, DetailedERC20, PausableToken  {
    constructor() CappedToken(65*10**25) DetailedERC20("BeANKH token", "ANKH", 18) public {
    }
}